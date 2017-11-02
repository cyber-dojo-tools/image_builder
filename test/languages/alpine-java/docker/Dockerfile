FROM  openjdk:8-jdk-alpine
LABEL maintainer=jon@jaggersoft.com

# fail the build if version number changes
RUN javac -version 2>&1 | grep -q 1.8

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# install tini (for pid 1 zombie reaping)
RUN apk add --update --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ tini
ENTRYPOINT [ "/sbin/tini", "--" ]
