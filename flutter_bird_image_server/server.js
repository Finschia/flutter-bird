const express = require('express');
const cors = require('cors');
const { mintRandomSkin } = require("./create_birds/create_data");

const app = express();

app.use(cors({
  origin: '*',
  credentials: true,
  optionsSuccessStatus: 200
}));

app.get('/api/image/:tokenId', async (req, res) => {
  try {
    const tokenId = req.params.tokenId;
    const dataUrl = await mintRandomSkin(tokenId);
    res.json({ imageDataUrl: dataUrl });
  } catch(e) {
    console.error('Error in /api/image/:tokenId route:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is running' });
});

if (process.env.NODE_ENV !== 'production') {
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });
}

module.exports = app;
