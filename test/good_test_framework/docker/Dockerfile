FROM       cyberdojofoundation/elm-0.18.0
MAINTAINER Jon Jagger <jon@jaggersoft.com>

RUN npm install -g elm-test

COPY tests/Main.elm  /tmp/tests/Main.elm
COPY tests/Tests.elm  /tmp/tests/Tests.elm
COPY tests/elm-package.json  /tmp/tests/elm-package.json

WORKDIR /tmp
# Running elm-test populates /tmp/tests/elm-stuff/*
# which needs to be copied into each avatar's
# sandbox folder
RUN elm-test

COPY red_amber_green.rb /usr/local/bin
