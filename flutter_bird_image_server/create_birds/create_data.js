const { generateImage } = require("./generate_image");
const { generateMetadata } = require("./generate_metadata");

async function mintRandomSkin(tokenId) {
    try {
        const skinMetadata = generateMetadata(tokenId);

        const dataUrl = await generateImage(
            tokenId,
            skinMetadata.attributes[0]['value'],
            skinMetadata.attributes[1]['value'],
            skinMetadata.attributes[2]['value'],
            skinMetadata.attributes[3]['value'],
            skinMetadata.attributes[4]['value'],
        );
        return dataUrl;
    } catch (e) {
        console.error('Error in mintRandomSkin:', e);
        throw e;
    }
}

module.exports = { mintRandomSkin };
