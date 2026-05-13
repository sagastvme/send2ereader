# node 20 is lts at the time of writing
FROM node:lts-slim

# Create app directory
WORKDIR /usr/src/app

# Install required system tools (Debian slim needs python3-venv for pipx)
RUN apt-get update && apt-get install -y \
    wget \
    pipx \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Download and install kepubify based on CPU architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
        wget -O /usr/local/bin/kepubify https://github.com/pgaskin/kepubify/releases/download/v4.0.4/kepubify-linux-arm64; \
    else \
        wget -O /usr/local/bin/kepubify https://github.com/pgaskin/kepubify/releases/download/v4.0.4/kepubify-linux-64bit; \
    fi && \
    chmod +x /usr/local/bin/kepubify

# Download and install kindlegen (Only supports x86_64 environments)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        dpkg --add-architecture i386 && \
        apt-get update && apt-get install -y libc6:i386 && \
        rm -rf /var/lib/apt/lists/* && \
        wget https://github.com/zzet/fp-docker/raw/f2b41fb0af6bb903afd0e429d5487acc62cb9df8/kindlegen_linux_2.6_i386_v2_9.tar.gz && \
        echo "9828db5a2c8970d487ada2caa91a3b6403210d5d183a7e3849b1b206ff042296 kindlegen_linux_2.6_i386_v2_9.tar.gz" | sha256sum -c && \
        mkdir kindlegen && \
        tar xvf kindlegen_linux_2.6_i386_v2_9.tar.gz --directory kindlegen && \
        cp kindlegen/kindlegen /usr/local/bin/kindlegen && \
        chmod +x /usr/local/bin/kindlegen && \
        rm -rf kindlegen; \
    else \
        echo "Skipping kindlegen installation: Not supported on ARM architecture."; \
    fi

ENV PATH="$PATH:/root/.local/bin"

# Install pdfCropMargins using pre-built wheels
RUN pipx install pdfCropMargins

# Copy files needed by npm install
COPY package*.json ./

# Install app dependencies
RUN npm install --omit=dev

# Copy the rest of the app files (see .dockerignore)
COPY . ./

# Create uploads directory if it doesn't exist
RUN mkdir uploads

EXPOSE 3001
CMD [ "npm", "start" ]