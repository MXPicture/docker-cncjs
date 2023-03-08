FROM registry.hub.docker.com/library/node:19.7.0-bullseye as build
RUN apt update && apt install -y python3 g++ make
#RUN npm config rm proxy 
#RUN npm config rm https-proxy --tried removing npm proxy
#RUN npm install --unsafe-perm -g cncjs@1.10.1
RUN npm install -g cncjs@1.10.1

FROM registry.hub.docker.com/library/node:19.7.0-bullseye-slim
COPY --from=build /usr/local /usr/local
RUN apt update && apt install -y udev socat && apt clean

ENV ESPLINK=0.0.0.0:23
VOLUME /config
COPY cncjs.json /config/cncjs.json

EXPOSE 80
CMD /usr/local/bin/cncjs -H 0.0.0.0 -p 80 -c /config/cncjs.json