#FROM cyberdojo/ruby
#using sinatra for now, ruby has no JSON gem

FROM cyberdojo/sinatra
MAINTAINER Jon Jagger <jon@jaggersoft.com>

COPY * /app/
