FROM  docker:latest
LABEL maintainer=jon@jaggersoft.com

RUN apk update \
 && apk upgrade

# image_builder is written in ruby
#   it curls the cyber-dojo script which in turn requires bash.
RUN apk add \
  ruby-dev ruby libffi-dev ruby-bundler curl bash

# image_builder's inner_main.rb uses travis CLI
#   which is installed as part of the travis gem
RUN apk --update add --virtual build-dependencies build-base \
  && bundle config --global silence_root_warning 1 \
  && gem install travis -v 1.8.8 --no-rdoc --no-ri \
  && apk del build-dependencies \
  && rm -vrf /var/cache/apk/*

COPY * /app/
