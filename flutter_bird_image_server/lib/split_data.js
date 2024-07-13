const { chunk } = require('lodash');

function splitData(data, splitSize, chunkSize) {
  const splitCount = Math.ceil(data.length / splitSize);
  const splitedData = Array.from({ length: splitCount }, (_, i) => 
    data.subarray(i * splitSize, (i + 1) * splitSize)
  );
  return chunk(splitedData, chunkSize);
}

module.exports = {
  splitData
};
