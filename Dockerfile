# Set up build1
FROM node:lts@sha256:2b85f4981f92ee034b51a3c8bb22dbb451d650d5c12b6439a169f8adc750e4b6 AS build

WORKDIR /usr/src

COPY . ./

RUN npm ci --no-optional \
 && npm run compile \
 && rm -rf node_modules .git

# Set up runtime
FROM atomist/skill:node14

# trivy
ENV TRIVY_VERSION 0.19.2
RUN apt-get update && apt-get install -y \
    wget=1.21-1ubuntu3 \
 && wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.deb \
 && dpkg -i trivy_${TRIVY_VERSION}_Linux-64bit.deb \
 && apt-get remove -y wget \
 && apt-get autoremove -y \
 && apt-get clean -y \
 && rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# skopeo
RUN apt-get update && apt-get install -y \
    skopeo=1.2.1+dfsg1-1 \
 && apt-get clean -y \
 && rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# container-diff
RUN apt-get update && apt-get install -y \
    curl=7.74.0-1ubuntu2.1 \
 && curl -LO https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64 \
 && chmod +x container-diff-linux-amd64 \
 && mv container-diff-linux-amd64 /usr/local/bin/container-diff \
 && apt-get remove -y curl \
 && apt-get autoremove -y \
 && apt-get clean -y \
 && rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# unzip
RUN apt-get update && apt-get install -y \
    unzip=6.0-26ubuntu1 \
 && apt-get clean -y \
 && rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR "/skill"

COPY package.json package-lock.json ./

RUN npm ci --no-optional \
 && npm cache clean --force

COPY --from=build /usr/src/ .

ENTRYPOINT ["node", "--no-deprecation", "--no-warnings", "--expose_gc", "--optimize_for_size", "--max-old-space-size=4096", "--always_compact", "/skill/node_modules/.bin/atm-skill"]
CMD ["run"]
