# Build stage for Navtech.
FROM alpine

RUN adduser -S navtech
RUN apk --no-cache add build-base
RUN apk --no-cache add git
RUN apk --no-cache add nodejs
RUN apk --no-cache add nodejs-npm
RUN apk --no-cache add python
RUN apk --no-cache add su-exec

ENV NAVTECH_PREFIX=navtech
ENV NAVTECH_BRANCH=host-patch

## Need to update npm.
RUN npm cache clean --force
RUN npx npm@5.6 i -g npm@latest

WORKDIR /opt
RUN git clone -b ${NAVTECH_BRANCH} https://github.com/navcoin/navtech.git ${NAVTECH_PREFIX}
WORKDIR /opt/${NAVTECH_PREFIX}
RUN rm -rf node_modules
RUN npm install
RUN mkdir keys keys/private keys/public

COPY docker-entrypoint.sh /entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
