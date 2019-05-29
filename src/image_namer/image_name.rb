
# Writes the image_name associated with a
# start-points' /docker dir.

require 'json'

content = IO.read('/start_point/docker/image_name.json')
json = JSON.parse(content)
puts json['image_name']
