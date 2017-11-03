FROM  openjdk:8-jdk-alpine
LABEL maintainer=jon@jaggersoft.com

# fail the build if version number changes
RUN javac -version 2>&1 | grep -q 1.8
