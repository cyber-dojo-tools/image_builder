FROM  cyberdojofoundation/java:image_builder_test
LABEL maintainer=jon@jaggersoft.com

COPY /jars/* /junit/
ENV CLASSPATH=/junit/

COPY red_amber_green.rb /usr/local/bin
