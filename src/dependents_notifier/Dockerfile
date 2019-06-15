FROM cyberdojo/ruby-base
LABEL maintainer=jon@jaggersoft.com

RUN apk update \
 && apk upgrade \
 && apk add \
      curl

COPY .  /app

ENTRYPOINT [ "ruby", "/app/src/notify.rb" ]
