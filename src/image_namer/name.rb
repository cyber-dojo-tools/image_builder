
# Writes the image_name associated with a
# start-points' /docker dir.

require 'json'

# TODO: if /start_point/docker/start_point/manifest.json
# exists then use that.

content = IO.read('/data/docker/image_name.json')
json = JSON.parse(content)
puts json['image_name']
