import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bird/controller/authentication_service.dart';
import 'package:flutter_bird/controller/authorization_service.dart';
import 'package:flutter_bird/controller/mint_nft_service.dart';
import 'package:flutter_bird/config.dart';
import 'package:flutter/services.dart';

import '../model/account.dart';
import '../model/skin.dart';
import '../model/wallet_provider.dart';

class FlutterBirdController extends ChangeNotifier {
  late final AuthenticationService _authenticationService;
  late final AuthorizationService _authorizationService;
  late final NFTMinterService _nftMinterService;

  // Authentication state
  List<WalletProvider> get availableWallets => _authenticationService.availableWallets;

  Account? get authenticatedAccount => _authenticationService.authenticatedAccount;

  bool get isOnOperatingChain => _authenticationService.isOnOperatingChain;

  String get operatingChainName => _authenticationService.operatingChainName;

  bool get isAuthenticated => _authenticationService.isAuthenticated;

  bool get isConnected => _authenticationService.isConnected;

  NFTMinterService get nftMinterService => _nftMinterService;

  WalletProvider? get lastUsedWallet => (_authenticationService as AuthenticationServiceImpl).lastUsedWallet;

  String? get currentAddressShort =>
      authenticatedAccount?.address != null
          ? '${authenticatedAccount!.address.substring(0, 8)}...${authenticatedAccount!.address.substring(36)}'
          : null;

  String? get webQrData => _authenticationService.webQrData;
  bool _loadingSkins = false;

  // Authorization state
  List<Skin>? skins;
  String? skinOwnerAddress;

  // Error handling
  String? lastError;

  Future<void> init(bool isInLiff) async {
    try {
      // Setting Up Web3 Connection
      const String skinContractAddress = flutterBirdSkinsContractAddress;
      String rpcUrl = klaytnBaobabProviderUrl;

      _authenticationService = AuthenticationServiceImpl(
          isInLiff: isInLiff,
          operatingChain: chainId,
          onAuthStatusChanged: () async {
            notifyListeners();
            authorizeUser();
          });
      
      await (_authenticationService as AuthenticationServiceImpl).initialize(isInLiff);
      _authorizationService = AuthorizationServiceImpl(contractAddress: skinContractAddress, rpcUrl: rpcUrl);

      final String abiJsonString = await rootBundle.loadString('assets/FlutterBirdSkins.json');
      _nftMinterService = NFTMinterService(rpcUrl, flutterBirdSkinsContractAddress, abiJsonString, _authenticationService as AuthenticationServiceImpl);
      
    } catch (e) {
      lastError = 'Initialization error: $e';
      printDebugInfo('Initialization error: $e');
      notifyListeners();
    }
  }

  Future<void> mintNft() async {
    await _nftMinterService.mintRandomSkin();
  }

  Future<void> verifySignature() async {
    try {
      bool result = await (_authenticationService as AuthenticationServiceImpl).verifySignature();
      if (result) {
        await authorizeUser();
      }
      notifyListeners();
    } catch (e) {
      lastError = 'Signature verification error: $e';
      printDebugInfo('Signature verification error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> requestAuthentication({WalletProvider? walletProvider}) async {
    try {
      await _authenticationService.requestAuthentication(walletProvider: walletProvider);
    } catch (e) {
      lastError = 'Authentication error: $e';
      printDebugInfo('Authentication error: $e');
      notifyListeners();
    }
  }

  void unauthenticate() {
    try {
      _authenticationService.unauthenticate();
      notifyListeners();
    } catch (e) {
      lastError = 'Unauthentication error: $e';
      printDebugInfo('Unauthentication error: $e');
      notifyListeners();
    }
  }

  /// Loads a users owned skins
  Future<void> authorizeUser({bool forceReload = false}) async {
    try {
      // Reload skins only if address changed
      if (!_loadingSkins && (forceReload || skinOwnerAddress != authenticatedAccount?.address)) {
        _loadingSkins = true;
        await _authorizationService.authorizeUser(authenticatedAccount?.address, onSkinsUpdated: (skins) {
          skins?.sort(
            (a, b) => a.tokenId.compareTo(b.tokenId),
          );
          this.skins = skins;
          notifyListeners();
        });
        skinOwnerAddress = authenticatedAccount?.address;
        _loadingSkins = false;
        notifyListeners();
      }
    } catch (e) {
      lastError = 'Authorization error: $e';
      printDebugInfo('Authorization error: $e');
      notifyListeners();
    }
  }

  void printDebugInfo(String message) {
    print('FlutterBirdController: $message');
    print('isAuthenticated: $isAuthenticated');
    print('isOnOperatingChain: $isOnOperatingChain');
    print('authenticatedAccount: ${authenticatedAccount?.address}');
    print('availableWallets: ${availableWallets.length}');
    print('webQrData: $webQrData');
  }
}
