FROM  cyberdojo/docker-base
LABEL maintainer=jon@jaggersoft.com

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# install ruby
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

RUN apk --update --no-cache add \
    openssl ca-certificates \
    ruby ruby-io-console ruby-irb ruby-bigdecimal \
    tzdata

# - - - - - - - - - - - - - - - - - - - - - -
# install glibc on Alpine
# - - - - - - - - - - - - - - - - - - - - - -

RUN apk add --no-cache curl openssl ca-certificates

RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
 && GLIBC_VERSION='2.28-r0' \
 && curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
 && curl -Lo glibc.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC_VERSION/glibc-$GLIBC_VERSION.apk \
 && curl -Lo glibc-bin.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/$GLIBC_VERSION/glibc-bin-$GLIBC_VERSION.apk \
 && apk update \
 && apk add glibc.apk glibc-bin.apk \
 && rm -rf /var/cache/apk/* \
 && rm glibc.apk glibc-bin.apk

# - - - - - - - - - - - - - - - - - - - - - -
# install docker-compose
# - - - - - - - - - - - - - - - - - - - - - -

ARG DOCKER_COMPOSE_VERSION=1.22.0
ARG DOCKER_COMPOSE_BINARY=/usr/bin/docker-compose
RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > ${DOCKER_COMPOSE_BINARY}
RUN chmod +x ${DOCKER_COMPOSE_BINARY}

# smoke-test it installed
RUN docker-compose --version

COPY * /app/
