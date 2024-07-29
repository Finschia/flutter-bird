FROM node:18

WORKDIR /app/flutter_bird_skins

RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g node-gyp
RUN npm install -g truffle

COPY ./flutter_bird_skins/package*.json ./
RUN npm install

COPY ./flutter_bird_skins .

CMD ["sh", "-c", "truffle develop"]
