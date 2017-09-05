FROM  cyberdojofoundation/ubuntu-build-essential:17.04
LABEL maintainer=jon@jaggersoft.com

RUN apt-get update

# https://github.com/travis-ci/travis.rb#installation
RUN apt-get install --yes \
  ruby-full

RUN gem install travis -v 1.8.8 --no-rdoc --no-ri

# install docker
ARG DOCKER_ENGINE_VERSION=1.12.3

RUN apt-get install --yes curl
RUN curl -OL https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_ENGINE_VERSION}.tgz
RUN tar -xvzf docker-${DOCKER_ENGINE_VERSION}.tgz
RUN mv docker/* /usr/bin/
RUN rmdir docker
RUN rm docker-${DOCKER_ENGINE_VERSION}.tgz

COPY * /app/

