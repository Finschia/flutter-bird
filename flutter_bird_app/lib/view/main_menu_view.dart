import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bird/view/authentication_popup.dart';
import 'package:provider/provider.dart';

import '../controller/flutter_bird_controller.dart';
import '../controller/persistence/persistence_service.dart';
import '../controller/authentication_service.dart';
import '../controller/mint_nft_service.dart';
import '../config.dart';
import '../extensions.dart';
import 'game_view.dart';
import 'widgets/background.dart';
import 'widgets/bird.dart';
import 'widgets/flappy_text.dart';

class MainMenuView extends StatefulWidget {
  const MainMenuView({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MainMenuView> createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView> with AutomaticKeepAliveClientMixin {
  bool playing = false;
  bool _isOverlayVisible = false;

  int lastScore = 0;
  int? highScore;

  late Size worldDimensions;
  late double birdSize;

  final PageController birdSelectorController = PageController(viewportFraction: 0.3);
  List<Bird> birds = [
    const Bird(),
  ];
  late int selectedBird = 0;
  double? scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    PersistenceService.instance.getHighScore().then((value) => setState(() {
          if (value != null) highScore = value;
        }));
  }

  _startGame() {
    HapticFeedback.lightImpact();

    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => GameView(
          bird: birds[selectedBird],
          birdSize: birdSize,
          worldDimensions: worldDimensions,
          onGameOver: (score) {
            lastScore = score;
            if (score > (highScore ?? 0)) {
              PersistenceService.instance.saveHighScore(score);
              highScore = score;
            }
            setState(() {});
          }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Size screenDimensions = MediaQuery.of(context).size;
    double maxWidth = screenDimensions.height * 3 / 4 / 1.3;
    worldDimensions = Size(min(maxWidth, screenDimensions.width), screenDimensions.height * 3 / 4);
    birdSize = worldDimensions.height / 8;

    try {
      return Scaffold(
        body: Consumer<FlutterBirdController>(builder: (context, web3Service, child) {
          web3Service.authorizeUser();
          if (web3Service.skins != null) {
            birds = [
              const Bird(),
              ...web3Service.skins!.map((e) => Bird(
                    skin: e,
                  ))
            ];
            if (web3Service.skins!.length < selectedBird) {
              selectedBird = web3Service.skins!.length;
            }
          } else {
            selectedBird = 0;
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Stack(alignment: Alignment.center, children: [
                const Background(),
                _buildBirdSelector(web3Service),
                _buildMenu(web3Service),
                _buildAuthenticationView(web3Service),
                if (_isOverlayVisible) _buildOverlayMenu(web3Service),
              ]),
            ),
          );
        }),
      );
    } catch (e, stackTrace) {
      print("Error in MainMenuView: $e");
      print("StackTrace: $stackTrace");
      return Scaffold(
        body: Center(
          child: Text("An error occurred. Please try again."),
        ),
      );
    }
  }

  Widget _buildMenu(FlutterBirdController web3Service) => Column(
        children: [
          Expanded(
              flex: 3,
              child: Column(
                children: [
                  const Spacer(
                    flex: 1,
                  ),
                  _buildTitle(),
                  if (lastScore != 0)
                    const SizedBox(
                      height: 24,
                    ),
                  if (lastScore != 0)
                    FlappyText(
                      text: '$lastScore',
                    ),
                  const Spacer(
                    flex: 4,
                  ),
                  _buildPlayButton(),
                  const SizedBox(
                    height: 24,
                  ),
                  if (highScore != null)
                    FlappyText(
                      fontSize: 32,
                      strokeWidth: 2.8,
                      text: 'High Score $highScore',
                    ),
                  const Spacer(
                    flex: 1,
                  ),
                ],
              )),
          Expanded(
            flex: 1,
            child: SizedBox(),
          )
        ],
      );

  Widget _buildTitle() => const FlappyText(
        fontSize: 72,
        text: 'FlutterBird',
      );

  Widget _buildPlayButton() => GestureDetector(
        onTap: _startGame,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white, boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            )
          ]),
          height: 60.0,
          width: 100.0,
          child: const Center(
            child: Icon(
              Icons.play_arrow_rounded,
              size: 50,
              color: Colors.green,
            ),
          ),
        ),
      );

  Widget _buildBirdSelector(FlutterBirdController web3Service) => Column(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  height: birdSize * 1.5,
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: (notification) {
                      setState(() {
                        scrollPosition = birdSelectorController.page;
                      });
                      return true;
                    },
                    child: PageView.builder(
                      controller: birdSelectorController,
                      scrollBehavior: const AppScrollBehavior(),
                      onPageChanged: (page) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          selectedBird = page;
                        });
                      },
                      itemCount: (web3Service.skins?.length ?? 0) + 1,
                      itemBuilder: (context, index) {
                        double scale = 1;
                        if (scrollPosition != null) {
                          scale = max(
                              scale, (1.5 - (index - scrollPosition!).abs()) + birdSelectorController.viewportFraction);
                        }

                        Bird bird;
                        if (index == 0) {
                          bird = const Bird();
                        } else {
                          bird = Bird(
                            skin: web3Service.skins![index - 1],
                          );
                        }

                        return GestureDetector(
                            onTap: () {
                              birdSelectorController.animateToPage(index,
                                  duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
                            },
                            child: Center(
                                child: SizedBox(
                              height: birdSize * scale,
                              width: birdSize * scale,
                              child: bird,
                            )));
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  birds[selectedBird].name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ],
            ),
          ),
          const Spacer()
        ],
      );

  Widget _buildAuthenticationView(FlutterBirdController web3Service) {
    return Positioned(
      bottom: 20,
      right: 32,
      child: GestureDetector(
        onTap: _toggleOverlay,
        child: Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              )
            ],
          ),
          child: const Icon(Icons.menu, color: Colors.black),
        ),
      ),
    );
  }

  void _toggleOverlay() {
    setState(() {
      _isOverlayVisible = !_isOverlayVisible;
    });
  }

  Widget _buildOverlayMenu(FlutterBirdController web3Service) {
    if (!_isOverlayVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleOverlay,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWalletConnectButton(web3Service),
                  const SizedBox(height: 16),
                  _buildMintButton(web3Service),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletConnectButton(FlutterBirdController web3Service) {
    String statusText = web3Service.isAuthenticated
        ? (web3Service.isOnOperatingChain ? 'Wallet Connected' : 'Wrong Chain')
        : 'Connect Wallet';

    return ElevatedButton(
      onPressed: _showAuthenticationPopUp,
      child: Text(statusText),
    );
  }

  Widget _buildMintButton(FlutterBirdController web3Service) {
    return ElevatedButton(
      onPressed: web3Service.isAuthenticated && web3Service.isOnOperatingChain
          ? () => _mintNFT(web3Service)
          : null,
      child: const Text('Mint Bird'),
    );
  }

  Future<void> _mintNFT(FlutterBirdController web3Service) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minting process started. Please check your wallet for confirmation.')),
      );

      int newTokenId = await web3Service.nftMinterService.mintRandomSkin();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NFT #$newTokenId minted successfully!')),
      );

      await web3Service.authorizeUser(forceReload: true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error minting NFT: $e')),
      );
    }
  }

  _showAuthenticationPopUp() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return const AuthenticationPopup();
      },
      transitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ));
  }

  @override
  bool get wantKeepAlive => true;
}
