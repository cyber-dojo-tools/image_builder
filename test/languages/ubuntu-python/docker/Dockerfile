FROM  cyberdojofoundation/ubuntu-build-essential:17.04
LABEL maintainer=jon@jaggersoft.com

RUN apt-get update

RUN apt-get install --yes \
  python3.6 \
  python3-pip

RUN pip3 install --upgrade numpy scipy panda datetime pep8
RUN ln -s /usr/bin/python3.6 /usr/bin/python
