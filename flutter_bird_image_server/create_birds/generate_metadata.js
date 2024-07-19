const crypto = require('crypto');
const traits = require("../input/traits.json");

function getRandomWeightedTrait(traitList, guaranteed = false, rng) {
    let totalWeight = traitList.reduce((sum, trait) => {
        if (!guaranteed || (trait.name !== "none" && trait.name !== "default")) {
            return sum + trait.weight;
        }
        return sum;
    }, 0);

    let randomNumber = rng() * totalWeight;
    
    for (const trait of traitList) {
        if (guaranteed && (trait.name === "none" || trait.name === "default")) {
            continue;
        }
        
        randomNumber -= trait.weight;
        if (randomNumber <= 0) {
            return trait.name === "none" ? "" : trait.name;
        }
    }
    
    return "";
}

function generateMetadata(tokenId) {
    console.log('Creating metadata for skin ' + tokenId);

    const seed = crypto.createHash('sha256').update(tokenId.toString()).digest('hex');
    const rng = require('seedrandom')(seed);

    const skinTemplate = require('../input/metadata_template.json');
    const skinMetadata = JSON.parse(JSON.stringify(skinTemplate));

    const birdList = traits.bird;
    const headList = traits.head;
    const eyesList = traits.eyes;
    const mouthList = traits.mouth;
    const neckList = traits.neck;

    let guaranteedTrait = Math.floor(rng() * 5) - 1;
    const randomBird = getRandomWeightedTrait(birdList, false, rng);
    if (randomBird === 'default') guaranteedTrait = Math.floor(rng() * 4);

    let guaranteedNotTrait = Math.floor(rng() * 6);
    if (guaranteedTrait === guaranteedNotTrait) guaranteedNotTrait = -1;

    const randomHead = guaranteedNotTrait === 0 ? "" : getRandomWeightedTrait(headList, guaranteedTrait === 0, rng);
    const randomEyes = guaranteedNotTrait === 1 ? "default" : getRandomWeightedTrait(eyesList, guaranteedTrait === 1, rng);
    const randomMouth = guaranteedNotTrait === 2 ? "" : getRandomWeightedTrait(mouthList, guaranteedTrait === 2, rng);
    const randomNeck = guaranteedNotTrait === 3 ? "" : getRandomWeightedTrait(neckList, guaranteedTrait === 3, rng);

    skinMetadata.name = 'Flutter Bird #' + tokenId.toString();
    skinMetadata.attributes[0].value = randomBird.toLowerCase();
    skinMetadata.attributes[1].value = randomHead.toLowerCase();
    skinMetadata.attributes[2].value = randomEyes.toLowerCase();
    skinMetadata.attributes[3].value = randomMouth.toLowerCase();
    skinMetadata.attributes[4].value = randomNeck.toLowerCase();

    console.log('Generated metadata:', JSON.stringify(skinMetadata, null, 2));
    return skinMetadata;
}

module.exports = { generateMetadata };
