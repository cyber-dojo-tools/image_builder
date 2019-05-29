FROM cyberdojo/docker-base
LABEL maintainer=jon@jaggersoft.com

RUN apk update \
 && apk upgrade \
 && apk add \
      libffi-dev \
      curl

# travis.rb uses the travis CLI which is
# installed as part of the travis gem

RUN apk --update add --virtual build-dependencies build-base \
  && bundle config --global silence_root_warning 1 \
  && gem install travis --no-rdoc --no-ri \
  && apk del build-dependencies \
  && rm -vrf /var/cache/apk/*

COPY .  /app

ENTRYPOINT [ "ruby", "/app/notify.rb" ]
