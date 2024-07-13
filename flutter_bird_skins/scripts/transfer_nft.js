require('dotenv').config();
const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");

const Web3 = require('web3');
const fs = require('fs');

const providerUrl = process.env.API_URL;
const privateKey = process.env.PRIVATE_KEY;
const contractAddress = process.env.CONTRACT_ADDRESS;

const [,, recipientAddress, tokenId] = process.argv;

if (!recipientAddress || !tokenId) {
    console.error('Usage: node transfer_nft.js <recipient_address> <token_id>');
    process.exit(1);
}

const provider = new HDWalletProvider({
  privateKeys: [privateKey],
  providerOrUrl: providerUrl
});

const web3 = new Web3(provider);

const contractJson = JSON.parse(fs.readFileSync('./build/contracts/FlutterBirdSkins.json', 'utf8'));
const contractABI = contractJson.abi;

const flutterBirdSkins = new web3.eth.Contract(contractABI, contractAddress);

async function transferNFT(recipientAddress, tokenId) {
    try {
        const accounts = await web3.eth.getAccounts();
        const senderAccount = accounts[0];

        console.log(`Sender address: ${senderAccount}`);
        console.log(`Recipient address: ${recipientAddress}`);
        console.log(`Token ID: ${tokenId}`);

        const gasEstimate = await flutterBirdSkins.methods.transferFrom(senderAccount, recipientAddress, tokenId).estimateGas({
            from: senderAccount
        });

        const tx = await flutterBirdSkins.methods.transferFrom(senderAccount, recipientAddress, tokenId).send({
            from: senderAccount,
            gas: Math.round(gasEstimate * 1.2)
        });

        console.log(`NFT (Token ID: ${tokenId}) successfully transferred`);
        console.log(`Transaction Hash: ${tx.transactionHash}`);
    } catch (error) {
        console.error('Error transferring NFT:', error);
    } finally {
        provider.engine.stop();
    }
}

transferNFT(recipientAddress, tokenId);
