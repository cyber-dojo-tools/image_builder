FROM  cyberdojofoundation/gcc-alpine:5.3.0
LABEL maintainer=jon@jaggersoft.com

RUN apk update \
 && apk upgrade

# image_builder is written in ruby
#   it curls the cyber-dojo script which in turn requires bash.
# image_builder's inner_main.rb uses travis CLI
#   which is installed as part of the travis gem
RUN apk add \
  ruby-dev ruby libffi-dev curl bash \
  && gem install travis -v 1.8.8 --no-rdoc --no-ri

# image_builder builds docker images
ARG DOCKER_ENGINE_VERSION=1.12.3

RUN curl -OL https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_ENGINE_VERSION}.tgz \
 && tar -xvzf docker-${DOCKER_ENGINE_VERSION}.tgz \
 && mv docker/* /usr/bin/ \
 && rmdir docker \
 && rm docker-${DOCKER_ENGINE_VERSION}.tgz

COPY * /app/

