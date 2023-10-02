# BUILD STAGE
FROM registry.hub.docker.com/library/node:20.7.0-bullseye as build

ENV BUILD_DIR /tmp/build
ENV NODE_ENV production
ENV NODE_OPTIONS --openssl-legacy-provider

ENV ARCHIVE_DIR /tmp/archive
ENV ARCHIVE_PREPARE_DIR cncjs_prepare
ENV ARCHIVE_BUILD_DIR cncjs_build
ENV ARCHIVE_NAME cncjs.tar.gz

ARG CACHEBUST=1

# ORIG: use original releases https://github.com/cncjs/cncjs
# CUSTOM: use custom repo branch https://github.com/MXPicture/cncjs
ARG MODE=ORIG

RUN apt update && apt install -y python3 g++ make

# download latest version
RUN mkdir -p "$BUILD_DIR" \
  && mkdir -p "$ARCHIVE_DIR/$ARCHIVE_PREPARE_DIR"

RUN if [ "$MODE" = "CUSTOM" ] ; \
    then $(git ls-remote --refs https://github.com/MXPicture/docker-cncjs | cut -f 2 | cut -d "/" -f 3 | awk -F'[v]' '/^v[0-9]+\.[0-9]+\.[0-9]+$/ {print $2}' | awk -F'[/.]' '{print $1+1000 "." $2+1000 "." $3+1000}' | sort -r | awk -F'[/.]' '{print "https://github.com/MXPicture/docker-cncjs/raw/v" $1-1000 "." $2-1000 "." $3-1000 "/v" $1-1000 "." $2-1000 "." $3-1000 ".tar.gz"}' | head -n 1 | /usr/bin/xargs wget -O "$ARCHIVE_DIR/$ARCHIVE_NAME") ; \
    else $(git ls-remote --tags https://github.com/cncjs/cncjs | cut -f 2 | cut -d "/" -f 3 | awk -F'[v]' '/^v[0-9]+\.[0-9]+\.[0-9]+$/ {print $2}' | awk -F'[/.]' '{print $1+1000 "." $2+1000 "." $3+1000}' | sort -r | awk -F'[/.]' '{print "https://github.com/cncjs/cncjs/archive/refs/tags/v" $1-1000 "." $2-1000 "." $3-1000 ".tar.gz"}' | head -n 1 | /usr/bin/xargs wget -O "$ARCHIVE_DIR/$ARCHIVE_NAME") ; \
  fi

# build dist
RUN tar -xvzf "$ARCHIVE_DIR/$ARCHIVE_NAME" --directory "$ARCHIVE_DIR/$ARCHIVE_PREPARE_DIR" \
  && mv "$ARCHIVE_DIR/$ARCHIVE_PREPARE_DIR/$(ls --color=none $ARCHIVE_DIR/$ARCHIVE_PREPARE_DIR)" "$ARCHIVE_DIR/$ARCHIVE_BUILD_DIR" \
  && cd "$ARCHIVE_DIR/$ARCHIVE_BUILD_DIR" \
  && yarn install \
  && npx update-browserslist-db@latest \
  && yarn build-prod \
  && mv "$ARCHIVE_DIR/$ARCHIVE_BUILD_DIR/dist/cncjs" "$BUILD_DIR/cncjs" \
  && mv "$ARCHIVE_DIR/$ARCHIVE_BUILD_DIR/entrypoint" "$BUILD_DIR/cncjs/"

WORKDIR $BUILD_DIR/cncjs
RUN yarn --production

# FINAL STAGE
FROM registry.hub.docker.com/library/node:20.7.0-bullseye-slim

ENV ESPLINK=0.0.0.0:23

RUN apt update && apt install -y udev socat && apt clean

VOLUME /config
COPY cncjs.json /config/cncjs.json
COPY --from=build /tmp/build/cncjs /opt/cncjs

WORKDIR /opt/cncjs
EXPOSE 80
CMD /opt/cncjs/entrypoint -H 0.0.0.0 -p 80 -c /config/cncjs.json