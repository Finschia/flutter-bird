import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:html' as html;

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nonce/nonce.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../model/account.dart';
import '../model/wallet_provider.dart';

/// Manages the authentication process and communication with crypto wallets
abstract class AuthenticationService {
  Future<void> initialize();

  List<WalletProvider> get availableWallets;

  Account? get authenticatedAccount;

  String get operatingChainName;

  bool get isOnOperatingChain;

  bool get isAuthenticated;

  bool get isConnected;

  String? get webQrData;

  WalletProvider? get lastUsedWallet;
  Future<void> requestAuthentication({WalletProvider? walletProvider});
  Future<void> unauthenticate();
}

class AuthenticationServiceImpl implements AuthenticationService {
  final int operatingChain;
  final Function() onAuthStatusChanged;
  WalletProvider? _lastUsedWallet;

  String projectId = dotenv.env['WALLET_CONNECT_PROJECT_ID'] ?? '';

  AuthenticationServiceImpl({
    required this.operatingChain,
    required this.onAuthStatusChanged,
  });

  List<WalletProvider> _availableWallets = [];
  Web3App? _connector;
  bool _isInitialized = false;

  @override
  List<WalletProvider> get availableWallets => _availableWallets;

  @override
  Account? get authenticatedAccount => _authenticatedAccount;
  Account? _authenticatedAccount;

  @override
  String get operatingChainName => operatingChain == 1001 ? 'Klaytn Testnet' : 'Chain $operatingChain';

  @override
  bool get isOnOperatingChain => currentChain == operatingChain;

  @override
  bool get isAuthenticated => isConnected && authenticatedAccount != null;

  // The data to display in a QR Code for connections on Desktop / Browser.
  @override
  String? webQrData;

  WalletProvider? get lastUsedWallet => _lastUsedWallet;

  SessionData? get currentSession => _connector?.sessions.getAll().firstOrNull;
  bool get isConnected => currentSession != null;

  int? get currentChain => int.tryParse(currentSession?.namespaces['eip155']?.accounts.first.split(':')[1] ?? '');

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    
    await _createConnector();
    await _clearSessions();
    await _loadWallets();
    
    _isInitialized = true;
  }

  // Update to support WalletConnect v2
  Future<void> _loadWallets() async {
    try {
      final response = await http.get(
        Uri.parse('https://explorer-api.walletconnect.com/v3/wallets?projectId=${projectId}&entries=5&page=1'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> walletsData = responseData['listings'];

        _availableWallets = walletsData.entries.map<WalletProvider?>((entry) {
          try {
            return WalletProvider.fromJson(entry.value);
          } catch (e, stackTrace) {
            print('Error creating WalletProvider from data: ${entry.value}');
            print('Error: $e');
            print('Stack trace: $stackTrace');
            return null;
          }
        }).where((wallet) => wallet != null).cast<WalletProvider>().toList();

        final miniWalletProvider = WalletProvider(
            id: '',
            name: 'Mini Wallet',
            imageId: '',
            imageUrl: ImageUrls(
                sm: 'https://walletconnect-app-demo.vercel.app/wallet.png',
                md: 'https://walletconnect-app-demo.vercel.app/wallet.png',
                lg: 'https://walletconnect-app-demo.vercel.app/wallet.png'),
            chains: ['eip155:1'],
            versions: [],
            sdks: [],
            appUrls: AppUrls(),
            mobile: MobileInfo(
                native: null,
                universal: 'https://liff.line.me/2005811776-v1GJy55G'),
            desktop: DesktopInfo());
        _availableWallets.insert(0, miniWalletProvider);
      } else {
        throw Exception('Failed to load wallets: ${response.statusCode}');
      }
    } catch (e) {
      log('Error loading wallets: $e');
    }
  }

  @override
  Future<void> requestAuthentication({WalletProvider? walletProvider}) async {
    await _updateConnectionStatus();
    // Create fresh connector
    await _createConnector(walletProvider: walletProvider);

    _lastUsedWallet = walletProvider;

    if (!isConnected) {
      try {
        ConnectResponse resp = await _connector!.connect(
          requiredNamespaces: {
            'eip155': RequiredNamespace(
              chains: ['eip155:$operatingChain'],
              methods: ['personal_sign', 'eth_sendTransaction'],
              events: [],
            ),
          },
        );

        Uri? uri = resp.uri;
        if (uri != null) {
          // Web
          if (kIsWeb) {
            webQrData = uri.toString();
            onAuthStatusChanged();
            _launchWallet(wallet: walletProvider, uri: uri.toString());
          // Native
          } else {
            _launchWallet(wallet: walletProvider, uri: uri.toString());
          }
        }

        await resp.session.future;
        onAuthStatusChanged();
      } catch (e) {
        log('Error during connect: $e', name: 'AuthenticationService');
      }
    }
  }

  Future<bool> verifySignature() async {
    if (currentChain == null || !isOnOperatingChain) return false;

    String? address = currentSession?.namespaces['eip155']?.accounts.first.split(':').last;
    if (address == null) return false;

    return _verifySignature(walletProvider: _lastUsedWallet, address: address);
  }
  
  // To maintain consistency during testing, delete the session before opening the app each time.
  // These(_clearSessions, _updateConnectionStatus) may not be necessary for user convenience.
  Future<void> _clearSessions() async {
    if (_connector != null) {
      final sessions = _connector!.sessions.getAll();
      for (var session in sessions) {
        await _connector!.disconnectSession(
          topic: session.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
        );
      }
    }
  }

  Future<String?> sendTransaction({
    required String topic,
    required int chainId,
    required Map<String, String> txParams,
  }) async {
    try {
      final dynamic txHash = await _connector!.request(
        topic: topic,
        chainId: 'eip155:$chainId',
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [txParams],
        ),
      );

      if (txHash is String) {
        return txHash;
      } else {
        print('Unexpected response type: ${txHash.runtimeType}');
        return null;
      }
    } catch (e) {
      print('Error sending transaction: $e');
      return null;
    }
  }

  Future<void> _updateConnectionStatus() async {
    final sessions = _connector?.sessions.getAll();
  }

  Future<bool> _verifySignature({WalletProvider? walletProvider, String? address}) async {
    if (address == null || currentChain == null || !isOnOperatingChain) return false;

    await Future.delayed(const Duration(seconds: 1));	
    _launchWallet(wallet: walletProvider, uri: 'wc:${currentSession!.topic}@2?relay-protocol=irn&symKey=${currentSession!.relay.protocol}');

    String nonce = Nonce.generate(32, math.Random.secure());
    String messageText = 'Please sign this message to authenticate with Flutter Bird.\nChallenge: $nonce';
    final String signature = await _connector!.request(
      topic: currentSession!.topic,
      chainId: 'eip155:$currentChain',
      request: SessionRequestParams(
        method: 'personal_sign',
        params: [messageText, address],
      ),
    );

    // Check if signature is valid by recovering the exact address from message and signature
    String recoveredAddress = EthSigUtil.recoverPersonalSignature(
        signature: signature, message: Uint8List.fromList(utf8.encode(messageText)));

    // if initial address and recovered address are identical the message has been signed with the correct private key
    bool isAuthenticated = recoveredAddress.toLowerCase() == address.toLowerCase();

    // Set authenticated account
    _authenticatedAccount = isAuthenticated ? Account(address: recoveredAddress, chainId: currentChain!) : null;

    return isAuthenticated;
  }

  @override
  Future<void> unauthenticate() async {
    if (currentSession != null) {
      await _connector?.disconnectSession(topic: currentSession!.topic, reason: Errors.getSdkError(Errors.USER_DISCONNECTED));
    }
    _authenticatedAccount = null;
    _connector = null;
    webQrData = null;
  }

  Future<void> _createConnector({WalletProvider? walletProvider}) async {
    try {
      _connector = await Web3App.createInstance(
        projectId: projectId,
        metadata: const PairingMetadata(
          name: 'Flutter Bird',
          description: 'WalletConnect Developer App',
          url: 'https://dynamic-tartufo-87d5f8.netlify.app', // FIXME: real url
          icons: [
            'https://raw.githubusercontent.com/Tonnanto/flutter-bird/v1.0/flutter_bird_app/assets/icon.png',
          ],
        ),
      );

      _connector?.onSessionConnect.subscribe((SessionConnect? session) async {
        log('connected: ' + session.toString(), name: 'AuthenticationService');
        String? address = session?.session.namespaces['eip155']?.accounts.first.split(':').last;
        webQrData = null;
        final authenticated = await _verifySignature(walletProvider: walletProvider, address: address);
        if (authenticated) log('authenticated successfully: ' + session.toString(), name: 'AuthenticationService');
        onAuthStatusChanged();
      });
      _connector?.onSessionUpdate.subscribe((SessionUpdate? payload) async {
        log('session_update: ' + payload.toString(), name: 'AuthenticationService');
        webQrData = null;
        onAuthStatusChanged();
      });
      _connector?.onSessionDelete.subscribe((SessionDelete? session) {
        log('disconnect: ' + session.toString(), name: 'AuthenticationService');
        webQrData = null;
        _authenticatedAccount = null;
        onAuthStatusChanged();
      });
    } catch (e) {
      log('Error during connector creation: $e', name: 'AuthenticationService');
    }
  }

  Future<void> _launchWallet({
    WalletProvider? wallet,
    required String uri,
  }) async {
    if (wallet == null) {
      print('Error: Wallet is null');
      return;
    }

    // This process is for Mini Wallet. Mini Wallet Browser gives link of this app a 'is_line' variable, so app can detect opening this in Mini Wallet.
    final isLine = Uri.parse(html.window.location.href).queryParameters['is_line'] != null;
    if (wallet.name == 'Mini Wallet' && isLine) {
      html.window.parent?.postMessage({'type': 'display_uri', 'data': uri}, "*", []);
      return;
    }

    if (wallet.mobile.native != null) {
      await launchUrl(
        _convertToWcUri(appLink: wallet.mobile.native!, wcUri: uri),
      );
    } else if (wallet.mobile.universal != null && await canLaunchUrl(Uri.parse(wallet.mobile.universal!))) {
      await launchUrl(
        _convertToWcUri(appLink: wallet.mobile.universal!, wcUri: uri),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (Platform.isIOS && wallet.appUrls.ios != null) {
        await launchUrl(Uri.parse(wallet.appUrls.ios!));
      } else if (Platform.isAndroid && wallet.appUrls.android != null) {
        await launchUrl(Uri.parse(wallet.appUrls.android!));
      }
    }

  }

  Uri _convertToWcUri({
    required String appLink,
    required String wcUri,
  }) {
    // avoid generating invalid link like 'metamask:///wc?..', 'https://metamask.app.link//wc?...'
    if (appLink[appLink.length - 1] == '/') {
      appLink = appLink.substring(0, appLink.length - 1);
    }
    return Uri.parse('$appLink/wc?uri=${Uri.encodeComponent(wcUri)}');
  }
}
