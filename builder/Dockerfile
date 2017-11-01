FROM  docker:latest
LABEL maintainer=jon@jaggersoft.com

# image_builder is written in ruby
# it curls the cyber-dojo script which in turn requires bash.

RUN apk update \
 && apk upgrade \
 && apk add \
      ruby-dev ruby libffi-dev ruby-bundler curl bash

# travis.rb uses the travis CLI which is
# installed as part of the travis gem
RUN apk --update add --virtual build-dependencies build-base \
  && bundle config --global silence_root_warning 1 \
  && gem install travis -v 1.8.8 --no-rdoc --no-ri \
  && apk del build-dependencies \
  && rm -vrf /var/cache/apk/*

COPY * /app/
