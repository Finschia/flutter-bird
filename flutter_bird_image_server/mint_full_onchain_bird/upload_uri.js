const Web3 = require('web3');
const { splitData } = require('../lib/split_data');

async function uploadUri(flutterBirdSkins, tokenId, uri, splitSize, account) {
  const data = Buffer.from(uri);
  const chunkValues = splitData(data, splitSize, 5);
  console.log('chunk count:', chunkValues.length);
  for (let i = 0; i < chunkValues.length; i++) {
    const values = chunkValues[i];
    const gasEstimate = await flutterBirdSkins.methods.appendUri(tokenId, values).estimateGas({
      from: account,
    });
    const tx = await flutterBirdSkins.methods.appendUri(tokenId, values)
      .send( {
        from: account,
        gas: Math.floor(gasEstimate * 1.2)
       });
    console.log(`appendUri tx: ${tx.transactionHash}`);
  }
}

module.exports = {
  uploadUri
};
