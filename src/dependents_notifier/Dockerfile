FROM cyberdojo/ruby-base
LABEL maintainer=jon@jaggersoft.com

COPY src_dir.rb /app
COPY travis.rb  /app
COPY trigger.sh /app

ENTRYPOINT [ "ruby", "/app/src_dir.rb" ]
