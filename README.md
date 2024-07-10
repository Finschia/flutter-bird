

![Flutter Bird Cover](media/cover.png)

# Flutter Bird (Prototype)

**TL;DR** A decentralized Flappy Bird clone making use of NFTs.

Flutter Bird imitates the minigame ["Flappy Bird"](https://en.wikipedia.org/wiki/Flappy_Bird) which domitated the AppStores in 2014.
On top of that Flutter Bird adds one basic feature to the original game: The ability to play with alternative skins.
These skins are realised as NFTs on the Ethereum Blockchain.
The Purpose of Flutter Bird is to demonstrate the processes of an Ethereum Authentication and Authorization with NFTs within a Flutter Application.
Flutter Bird has been developed as part of my bachelor thesis.

#### Flutter Application (*Flappy Bird App*)
The Frontend Application is built with Flutter.
The Game Logic as well as Authentication and Authorization processes are implemented in this application.
The Flutter Application is referred to as *Flutter Bird App*.
It runs on iOS, Android and the Web.

#### NFT-Collection (*Flappy Bird Skins*)
The NFT-Collection consists of 1000 Image Files that each represent a different skin for flutter bird.
These images are stored in the IPFS and ownership is managed with an ERC-721 Smart Contract.
The Smart Contract  is referred to as *Flutter Bird Skins*.
It has been deployed on the Ethereum Testnet "Goerli".
*Flutter Bird Skins* can be found on [Etherscan](https://goerli.etherscan.io/token/0x387f544e4c3b2351d015df57c30831ad58d6c798) and on [OpenSea](https://testnets.opensea.io/collection/flutterbirdskins).

## Authors

- [@Tonnanto](https://www.github.com/Tonnanto)


## Features

- Flappy Bird Clone
  - Play Flappy Bird
  - Track your Highscore
- Authenticate using a Crypto Wallet and your Ethereum Account
- Use your *Flutter Bird Skin NFTs* to play the game


## Tech Stack

**Client:** [Flutter](https://flutter.dev/) application for iOS, Android and Web

**Blockchain:** Ethereum ([Goerli Testnet](https://goerli.net/))

**Smart Contract Standard:** [ERC-721](https://ethereum.org/en/developers/docs/standards/tokens/erc-721/)

**Node Provider:** [Alchemy Supernode](https://www.alchemy.com/supernode)

**Storage:** [IPFS](https://ipfs.tech/)


## Demo

![Flutter Bird Demo](media/demo.gif)


## Build and Run Locally (Flutter App)

### Prerequisites:
- [Install Flutter](https://docs.flutter.dev/get-started/install)
- Setup your own [Alchemy Supernode](https://www.alchemy.com/supernode) (free plan)

### Steps:

1. Clone project

```bash
git clone https://github.com/Tonnanto/flutter-bird
```


2. Create `secrets.dart` file at `flutter_bird_app/lib/secrets.dart`.
3. Add the following contents to the file and insert your alchemy api key:

```
const alchemyApiKey = "YOUR_ALCHEMY_API_KEY";
```

4. Go to apps directory

```bash
cd flutter-bird/flutter_bird_app
```

5. Install dependencies

```bash
flutter pub get
```

6. Run app on an available device.  
   Hint: Use an IDE to comfortably connect real mobile devices or mobile simulators. Browsers should be available by default.

```bash
flutter install
```

### Troubleshooting:
```bash
flutter doctor
```
```bash
flutter analyze
```
More info [here](https://docs.flutter.dev/reference/flutter-cli)


## Mint Skin-NFT

In order to use a Flutter Bird Skin in the game you need to mint one first.

### Prerequisites:
- Set up an Account on the Goerli-Blockchain (Use MetaMask for example).
- Deposit some free GTH in your Account with a Faucet (0.01 GTH + Gas per Skin).

### Steps:

1. Visit the [contracts page](https://goerli.etherscan.io/address/0x387f544e4c3b2351d015df57c30831ad58d6c798#readContract) on etherscan.

2. Find a skin that has not been minted by entering values between 0 and 999 in the [`ownerOf`](https://goerli.etherscan.io/address/0x387f544e4c3b2351d015df57c30831ad58d6c798#readContract#F8) function.
   If it returns an error, the skin has not been minted, and you can proceed to the next step.
   If no skin is available, you have to buy one on a secondary market like [OpenSea](https://testnets.opensea.io/collection/flutterbirdskins).

3. Go to [Write Contract](https://goerli.etherscan.io/address/0x387f544e4c3b2351d015df57c30831ad58d6c798#writeContract)

4. Click "Connect to Web3" and connect your wallet.

5. Use the [`mintSkin`](https://goerli.etherscan.io/address/0x387f544e4c3b2351d015df57c30831ad58d6c798#writeContract#F2) function and enter 0.01 as the `payableAmount`, and the token ID from step 2 as the `newTokenId`

6. Click "Write" and confirm and sign the transaction with your wallet.

7. Once the transaction is successful, you have successfully minted a skin that you can use in the Flutter Bird App.


## For Klaytn testnet
- Create .env file in flutter_bird_skins and set PRIVATE_KEY, API_URL
- API_URL refer to [ChainList](https://chainlist.org/chain/1001).

**./flutter_bird_skins/.env**

```
PRIVATE_KEY=XXXXX
API_URL=https://XXXX
```

- Build docker compose
```
% docker-compose up --build
```

- Open other terminal and Run deploy
```
% docker-compose exec truffle sh
# truffle deploy --network baobab

Compiling your contracts...
===========================
✓ Fetching solc version list from solc-bin. Attempt #1
✓ Downloading compiler. Attempt #1.
> Everything is up to date, there is nothing to compile.


Starting migrations...
======================
> Network name:    'baobab'
> Network id:      1001
> Block gas limit: 999999999999 (0xe8d4a50fff)


1_initial_migration.js
======================

   Replacing 'FlutterBirdSkins'
   ----------------------------
   > transaction hash:    0xcfe48dd339af389ed2dd85e2b94ac53fb64c9874fb2980b7e59e55aa2ec58eb9
   > Blocks: 0            Seconds: 0
   > contract address:    0xAca84dc56A05bbC7a335a74d9e13C91dfA2Ea16D
   > block number:        158855531
   > block timestamp:     1720436952
   > account:             0xeB022B68B17Ec89e539C6F5BD740c648c013D9e0
   > balance:             59.645653649985826146
   > gas used:            4724618 (0x48178a)
   > gas price:           25.000000001 gwei
   > value sent:          0 ETH
   > total cost:          0.118115450004724618 ETH

   > Saving artifacts
   -------------------------------------
   > Total cost:     0.118115450004724618 ETH

Summary
=======
> Total deployments:   1
> Final cost:          0.118115450004724618 ETH
```

## Access via LINE
The LINE Messenger API allows us to receive URLs via LINE.

![image](https://github.com/Finschia/flutter-bird/assets/55307968/b4f6ac13-f167-4090-b4c2-0e4294845608)
