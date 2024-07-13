const { createCanvas, loadImage } = require("canvas");
const path = require('path');

const imageSize = {
    width: 750,
    height: 750
};

async function generateImage(tokenId, bird, head, eyes, mouth, neck) {
    const canvas = createCanvas(imageSize.width, imageSize.height);
    const context = canvas.getContext("2d");

    const baseUrl = process.env.VERCEL_URL 
        ? `https://${process.env.VERCEL_URL}` 
        : 'http://localhost:3000';

    const loadLayerImage = async (directory, filename) => {
        if (filename && filename !== "") {
            const imagePath = path.join(__dirname, '..', 'public', 'input', 'layers', directory, `${filename}.png`);
            console.log('Loading image from:', imagePath);
            return await loadImage(imagePath);
        }
        return null;
    };

    // Draw bird first
    const birdImage = await loadLayerImage('bird', bird);
    context.drawImage(birdImage, 0, 0, imageSize.width, imageSize.height);

    // Draw neck
    const neckImage = await loadLayerImage('neck', neck);
    if (neckImage) {
        context.drawImage(neckImage, 0, 0, imageSize.width, imageSize.height);
    }

    // Draw mouth
    const mouthImage = await loadLayerImage('mouth', mouth);
    if (mouthImage) {
        context.drawImage(mouthImage, 0, 0, imageSize.width, imageSize.height);
    }

    // Draw eyes
    const eyesImage = await loadLayerImage('eyes', eyes);
    context.drawImage(eyesImage, 0, 0, imageSize.width, imageSize.height);

    // Draw head
    const headImage = await loadLayerImage('head', head);
    if (headImage) {
        context.drawImage(headImage, 0, 0, imageSize.width, imageSize.height);
    }

    // Convert canvas to data URL
    return canvas.toDataURL("image/png");
}

module.exports = { generateImage };
