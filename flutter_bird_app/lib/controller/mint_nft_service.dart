import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import './authentication_service.dart';
import 'package:web3dart/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NFTMinterService {
  final Web3Client _client;
  final EthereumAddress _contractAddress;
  final DeployedContract _contract;
  final AuthenticationServiceImpl _authService;

  String key = dotenv.env['PRIVATE_KEY'] ?? ''; 

  NFTMinterService(String rpcUrl, String contractAddress, String abiJsonString, AuthenticationServiceImpl _authService)
      : _client = Web3Client(rpcUrl, http.Client()),
        _authService = _authService,
        _contractAddress = EthereumAddress.fromHex(contractAddress),
        _contract = _createContract(contractAddress, abiJsonString);

  static DeployedContract _createContract(String contractAddress, String abiJsonString) {
    try {
      final abiJson = jsonDecode(abiJsonString);
      final abiList = abiJson['abi'] as List<dynamic>;
      return DeployedContract(
        ContractAbi.fromJson(jsonEncode(abiList), 'FlutterBirdSkins'),
        EthereumAddress.fromHex(contractAddress),
      );
    } catch (e) {
      throw Exception('Failed to create contract: $e\nABI JSON: $abiJsonString');
    }
  }

  Future<int> mintRandomSkin() async {
    if (!_authService.isAuthenticated || !_authService.isOnOperatingChain) {
      throw Exception('Wallet not connected or on wrong chain');
    }

    final session = _authService.currentSession;
    if (session == null) {
      throw Exception('No active WalletConnect session');
    }

    try {
      // Get minted status list
      final mintedStatusList = await _client.call(
        contract: _contract,
        function: _contract.function('getMintedTokenList'),
        params: [],
      );

      final unmintedTokenId = _getUnmintedTokenId(mintedStatusList[0]);

      if (unmintedTokenId == null) {
        throw Exception("No unminted token available. All tokenIds have been minted.");
      }

      // Create and upload URI
      await _createAndUploadUri(unmintedTokenId);

      // Prepare transaction data
      final function = _contract.function('mintSkin');
      final data = function.encodeCall([BigInt.from(unmintedTokenId)]);

      final sender = EthereumAddress.fromHex(_authService.authenticatedAccount!.address);
      final gasEstimate = (await _client.estimateGas(
        sender: sender,
        to: _contractAddress,
        data: data,
        value: EtherAmount.fromInt(EtherUnit.ether, 1),
      ) * BigInt.from(110)) ~/ BigInt.from(100);

      final gasPrice = await _client.getGasPrice();
      final nonce = await _client.getTransactionCount(sender);

      final chainId = _authService.operatingChain;

      final totalCost = gasEstimate * gasPrice.getInWei + BigInt.from(10).pow(18);

      final balance = await _client.getBalance(sender);
      if (balance.getInWei < totalCost) {
        throw Exception('Insufficient balance. Required: ${totalCost}, Available: ${balance.getInWei}');
      }

      final gasLimit = gasEstimate * BigInt.from(2);
      final txParams = {
        'from': sender.hexEip55,
        'to': _contractAddress.hexEip55,
        'data': '0x${bytesToHex(data)}',
        'value': '0x${BigInt.from(10).pow(18).toRadixString(16)}', // 1 ETH
        'gasPrice': '0x${gasPrice.getInWei.toRadixString(16)}',
        'gasLimit': '0x${gasLimit.toRadixString(16)}',
        'nonce': '0x${nonce.toRadixString(16)}',
      };


      final txHash = await _authService.sendTransaction(
        topic: session.topic,
        chainId: chainId,
        txParams: txParams,
      );

      if (txHash == null) {
        throw Exception('Failed to send transaction');
      }

      return unmintedTokenId;

    } catch (e) {
      print('Error minting NFT: $e');
      rethrow;
    }
  }

  Future<String> _createAndUploadUri(int tokenId) async {
    print('Create And Upload uri NFT # $tokenId');
    final String imageUrl = 'https://flutter-bird-image-server.vercel.app';
    final String name = 'Flutter Bird - $tokenId';
    final String description = 'NFT Flutter Bird';

    try {
      final uri = await _createUri(
        name: name,
        description: description,
        imageServerUrl: imageUrl,
        tokenId: tokenId,
      );

      await _uploadUri(
        BigInt.from(tokenId),
        uri,
      );

      return uri;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }


  Future<String> _createUri({
    required String name,
    required String description,
    required String imageServerUrl,
    required int tokenId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$imageServerUrl/api/image/$tokenId'),
        headers: {
          'Access-Control-Allow-Origin': '*',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      final String imageDataUrl = responseData['imageDataUrl'];

      final json = jsonEncode({
        'name': name,
        'description': description,
        'image': imageDataUrl,
      }).trim();

      return 'data:application/json,${Uri.encodeFull(json)}';
    } catch (e) {
      print('Error creating URI: $e');
      rethrow;
    }
  }

  Future<void> _uploadUri(BigInt tokenId, String uri) async {
    final data = Uint8List.fromList(utf8.encode(uri));
    final function = _contract.function('appendUri');

    Uint8List encodedCall = function.encodeCall([tokenId, [data]]);

    try {
      final privateKey = EthPrivateKey.fromHex(key);
      final sender = await privateKey.address;

      final gasEstimate = await _client.estimateGas(
        sender: sender,
        to: _contractAddress,
        data: encodedCall,
      );

      final gasPrice = await _client.getGasPrice();
      final nonce = await _client.getTransactionCount(sender);
      final chainId = _authService.operatingChain;

      final tx = Transaction(
        to: _contractAddress,
        from: sender,
        nonce: nonce,
        gasPrice: gasPrice,
        maxGas: gasEstimate.toInt(),
        data: encodedCall,
      );

      final signedTx = await _client.signTransaction(privateKey, tx, chainId: chainId);
      final txResult = await _client.sendRawTransaction(signedTx);

      print('Transaction hash: $txResult');
    } catch (e) {
      print('Error sending transaction: $e');
      rethrow;
    }

  }

  int? _getUnmintedTokenId(List<dynamic> mintedStatusList) {
    final unmintedTokenIds = List<int>.generate(
      mintedStatusList.length,
      (i) => i,
    ).where((i) => !mintedStatusList[i]).toList();

    if (unmintedTokenIds.isEmpty) return null;

    return unmintedTokenIds[Random().nextInt(unmintedTokenIds.length)];
  }

  String _bytesToHex(Uint8List bytes) {
    return '0x' + bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  void dispose() {
    _client.dispose();
  }
}
