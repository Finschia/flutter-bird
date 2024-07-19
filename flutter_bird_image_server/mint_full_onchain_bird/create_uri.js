const { readFileSync } = require('fs');

function createUri({ name, description, filePath }, urlEncode) {
  const fileContent = readFileSync(filePath);
  const fileSize = fileContent.length.toLocaleString() + ' bytes';
  const fileContentBase64 = fileContent.toString('base64');
  const json = JSON.stringify({
    name,
    description,
    attributes: [{ trait_type: 'File size', value: fileSize }],
    image: 'data:image/png;base64,' + fileContentBase64,
  });
  if (urlEncode) {
    console.log('data:application/json,' + encodeURIComponent(json));
    return 'data:application/json,' + encodeURIComponent(json);
  } else {
    console.log('data:application/json,' + json);
    return 'data:application/json,' + json;
  }
}

module.exports = {
  createUri
};
