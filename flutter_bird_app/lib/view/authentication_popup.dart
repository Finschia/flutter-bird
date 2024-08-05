import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../controller/flutter_bird_controller.dart';
import '../model/wallet_provider.dart';

class AuthenticationPopup extends StatefulWidget {
  const AuthenticationPopup({Key? key}) : super(key: key);

  @override
  State<AuthenticationPopup> createState() => _AuthenticationPopupState();
}

class _AuthenticationPopupState extends State<AuthenticationPopup> {
  String? uri;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
  }

  void _setErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  bool _isMobileWeb() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('mobile') ||
        userAgent.contains('android') ||
        userAgent.contains('ios');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlutterBirdController>(
      builder: (context, flutterBirdController, child) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _buildBackground(),
            _buildBody(flutterBirdController),
            if (errorMessage != null) _buildErrorOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(errorMessage ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    errorMessage = null;
                  });
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FlutterBirdController flutterBirdController) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Container(
            constraints: BoxConstraints(
              minHeight: 240,
              maxWidth: 340,
              maxHeight: MediaQuery.of(context).size.height - 160,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: flutterBirdController.isAuthenticated
                ? _buildAuthenticatedView(flutterBirdController)
                : _buildUnauthenticatedView(flutterBirdController),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedView(FlutterBirdController flutterBirdController) {
    if (kIsWeb && flutterBirdController.webQrData == null) {
      // Generates QR Data
      flutterBirdController.requestAuthentication();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAuthenticationStatusView(flutterBirdController),
        if (!flutterBirdController.isConnected && _isMobileWeb())
          Flexible(
              child: _buildWalletSelector(flutterBirdController),
            ),
        if (flutterBirdController.webQrData != null && !_isMobileWeb())
          _buildQRView(flutterBirdController.webQrData!)
      ],
    );
  }

  Widget _buildAuthenticatedView(FlutterBirdController flutterBirdController) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildAuthenticationStatusView(flutterBirdController),
      _buildConnectButton(flutterBirdController),
    ],
  );

  Widget _buildAuthenticationStatusView(FlutterBirdController flutterBirdController) {
    String statusText = 'Not Authenticated';
    if (flutterBirdController.isAuthenticated) {
      statusText = flutterBirdController.isOnOperatingChain ? 'Authenticated' : '\nAuthenticated on wrong chain';
    }
    return Column(
      children: [
        Text(
          'Status: $statusText',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (!flutterBirdController.isOnOperatingChain)
          const SizedBox(height: 16,),
        if (!flutterBirdController.isOnOperatingChain)
          Text(
            'Connect a wallet on ${flutterBirdController.operatingChainName}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        if (flutterBirdController.isAuthenticated)
          const SizedBox(height: 16,),
        if (flutterBirdController.isAuthenticated)
          Text(
            'Wallet address:\n' + (flutterBirdController.authenticatedAccount?.address ?? ''),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        if (flutterBirdController.isConnected && !flutterBirdController.isAuthenticated)
          Column(
            children: [
              const SizedBox(height: 16),
              Text(
                "Please sign to authenticate your wallet.",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await flutterBirdController.verifySignature();
                  } catch (e) {
                    _setErrorMessage('Error during signature verification: $e');
                  }
                },
                child: Text('Sign Message'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildConnectButton(FlutterBirdController flutterBirdController) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: flutterBirdController.isAuthenticated ? Colors.redAccent : Colors.green,
      ),
      onPressed: () async {
        if (flutterBirdController.isAuthenticated) {
          flutterBirdController.unauthenticate();
        } else {
          flutterBirdController.requestAuthentication();
        }
      },
      child: SizedBox(
        height: 40,
        child: Center(
          child: Text(
            flutterBirdController.isAuthenticated ? 'Disconnect' : 'Connect',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      )
    );
  }

  Widget _buildWalletSelector(FlutterBirdController flutterBirdController) {
    if (flutterBirdController.availableWallets.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      itemCount: flutterBirdController.availableWallets.length,
      itemBuilder: (BuildContext context, int index) {
        WalletProvider wallet = flutterBirdController.availableWallets[index];
        return ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  wallet.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: wallet.imageUrl.sm == '' ? Container() : Image.network(wallet.imageUrl.sm),
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            try {
              flutterBirdController.requestAuthentication(walletProvider: wallet);
            } catch (e) {
              _setErrorMessage('Error connecting to wallet: $e');
            }
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 4),
    );
  }

  Widget _buildQRView(String data) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 200.0,
    );
  }

  Widget _buildBackground() => Positioned.fill(
    child: GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Container(
        color: Colors.black54,
      ),
    ),
  );
}
