FROM  cyberdojo/docker-base
LABEL maintainer=jon@jaggersoft.com

# image_builder is written in ruby
# it curls the cyber-dojo script which in turn requires bash.

RUN apk update \
 && apk upgrade \
 && apk add \
      ruby \
      libffi-dev \
      curl

# travis.rb uses the travis CLI which is
# installed as part of the travis gem
RUN apk --update add --virtual build-dependencies build-base \
  && bundle config --global silence_root_warning 1 \
  && gem install travis --no-rdoc --no-ri \
  && apk del build-dependencies \
  && rm -vrf /var/cache/apk/*

COPY * /app/
