require('dotenv').config();
const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");

const Web3 = require('web3');
const fs = require('fs');

const { createUri } = require('./create_uri');
const { uploadUri } = require('./upload_uri');

const contractJson = JSON.parse(fs.readFileSync('./build/contracts/FlutterBirdSkins.json', 'utf8'));
const contractABI = contractJson.abi;
const contractAddress = process.env.CONTRACT_ADDRESS;

const privateKey = process.env.PRIVATE_KEY;
const provider = new HDWalletProvider(privateKey, 'https://public-en-baobab.klaytn.net');
const web3 = new Web3(provider);

const flutterBirdSkins = new web3.eth.Contract(contractABI, contractAddress);

/**
 * This function mints a random Flutter Bird Skin
 */
async function mintRandomSkin() {
    const splitSize = 24544;

    console.log('Minting a random Flutter Bird Skin on contract:', contractAddress);

    // Get minted status list of all tokens
    const mintedStatusList = await flutterBirdSkins.methods.getMintedTokenList().call();
    // Get random unminted token
    const unmintedTokenId = getUnmintedTokenId(mintedStatusList);

    if (unmintedTokenId === undefined) {
        console.log("No unminted token available. All tokenIds have been minted.");
        return;
    }

    const tokenInfo = {
        filePath: `./output/images/1.png`,  // FIXME: val
        unmintedTokenId,
        name: `Flutter Bird - ${unmintedTokenId}`,
        description: 'NFT Flutter Bird',
    };

    // createUri
    const uri = createUri(tokenInfo, false);

    try {
        const accounts = await web3.eth.getAccounts();
        console.log("accounts[0]: " + accounts[0]);
    
        // uploadUri
        await uploadUri(flutterBirdSkins, unmintedTokenId, uri, splitSize, accounts[0]);
    
        const gasEstimate = await flutterBirdSkins.methods.mintSkin(unmintedTokenId).estimateGas({
            from: accounts[0],
            value: ethToWei(1)
        });
    
        // mint
        const tx = await flutterBirdSkins.methods.mintSkin(unmintedTokenId).send({
            from: accounts[0],
            value: ethToWei(1),
            gas: Math.floor(gasEstimate * 1.2)
        });

        console.log("Minting successful\nToken ID of new Skin: " + unmintedTokenId);
        console.log("Transaction hash:", tx.transactionHash);    
    } catch (error) {
        console.error('Error minting NFT:', error);
    } finally {
        provider.engine.stop();
    }
}

/**
 * Converts eth to wei
 */
function ethToWei(ethValue) {
    return web3.utils.toWei(ethValue.toString(), 'ether');
}

/**
 *
 * @param mintedStatusList array of boolean values whether the skin at that index has been minted
 * @returns int a random tokenId of an unminted token
 */
function getUnmintedTokenId(mintedStatusList) {
    let tokenIds = [];
    for (let i = 0; i < mintedStatusList.length; i++) {
        if (!mintedStatusList[i]) {
            tokenIds.push(i);
        }
    }
    return tokenIds[Math.floor(Math.random() * tokenIds.length)];
}

mintRandomSkin().catch(console.error);
