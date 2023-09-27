# BUILD STAGE
FROM debian:bullseye as build-stage

ENV BUILD_DIR /tmp/build
ENV NVM_DIR /root/.nvm
ENV NODE_VERSION v18.18.0
ENV NODE_ENV production
ENV NODE_PATH $NVM_DIR/$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

ENV ARCHIVE_DIR /tmp/archive
ENV ARCHIVE_PREPARE_DIR cncjs_prepare
ENV ARCHIVE_BUILD_DIR cncjs_build
ENV ARCHIVE_NAME cncjs.tar.gz

ARG CACHEBUST=1

RUN apt-get update -y && apt-get install -y -q --no-install-recommends \
  apt-utils \
  build-essential \
  ca-certificates \
  python3 \
  python3-pip \
  curl \
  git \
  udev \
  wget

RUN git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" \
  && cd "$NVM_DIR" \
  && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` \
  && . "$NVM_DIR/nvm.sh" \
  && nvm install "$NODE_VERSION" \
  && nvm alias default "$NODE_VERSION" \
  && nvm use --delete-prefix default

RUN npm install -g yarn

# download latest version
RUN mkdir -p "$BUILD_DIR" \
  && mkdir -p "$ARCHIVE_DIR" \
  && mkdir -p "$ARCHIVE_DIR/$ARCHIVE_PREPARE_DIR" \
  && git ls-remote --tags https://github.com/cncjs/cncjs | cut -f 2 | cut -d "/" -f 3 | awk -F'[v]' '/^v[0-9]+\.[0-9]+\.[0-9]+$/ {print $2}' | awk -F'[/.]' '{print $1+1000 "." $2+1000 "." $3+1000}' | sort -r | awk -F'[/.]' '{print "https://github.com/cncjs/cncjs/archive/refs/tags/v" $1-1000 "." $2-1000 "." $3-1000 ".tar.gz"}' | head -n 1 | /usr/bin/xargs wget -O "$ARCHIVE_DIR/$ARCHIVE_NAME" \
# todo add additional widgets and features
# build dist
  && tar -xvzf "$ARCHIVE_DIR/$ARCHIVE_NAME" --directory "$ARCHIVE_DIR/$ARCHIVE_PREPARE_DIR" \
  && mv "$ARCHIVE_DIR/$ARCHIVE_PREPARE_DIR/$(ls --color=none $ARCHIVE_DIR/$ARCHIVE_PREPARE_DIR)" "$ARCHIVE_DIR/$ARCHIVE_BUILD_DIR" \
  && cd "$ARCHIVE_DIR/$ARCHIVE_BUILD_DIR" \
  && yarn install \
  && yarn build-prod \
  && mv "$ARCHIVE_DIR/$ARCHIVE_BUILD_DIR/dist/cncjs" "$BUILD_DIR/cncjs" \
  && mv "$ARCHIVE_DIR/$ARCHIVE_BUILD_DIR/entrypoint" "$BUILD_DIR/cncjs/"

WORKDIR $BUILD_DIR/cncjs
RUN npm install -g npm@latest && npm install -g yarn && yarn --production

# FINAL STAGE
FROM debian:bullseye

ENV ESPLINK=0.0.0.0:23
ENV NVM_DIR /root/.nvm
ENV NODE_VERSION v18.18.0
ENV NODE_ENV production
ENV NODE_PATH $NVM_DIR/$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

RUN apt-get update -y && apt-get install -y -q --no-install-recommends \
  apt-utils \
  ca-certificates \
  udev

VOLUME /config
COPY cncjs.json /config/cncjs.json
COPY --from=build-stage /root/.nvm $NVM_DIR
COPY --from=build-stage /tmp/build/cncjs /opt/cncjs

WORKDIR /opt/cncjs
EXPOSE 80
CMD /opt/cncjs/entrypoint -H 0.0.0.0 -p 80:8000 -c /config/cncjs.json
# todo replace entrypoint by starting cncjs via node --> I hope it'll work ... maybe 'node /path/to/server-cli -H 0.0.0.0 -p 80:8000 -c /config/cncjs.json'

# EXPOSE 8000
# ENTRYPOINT ["/opt/cncjs/entrypoint"]