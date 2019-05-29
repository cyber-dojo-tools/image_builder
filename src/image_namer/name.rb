
# Writes the image_name associated with a start-points' dir.

require 'json'

def test_framework_filename
  '/data/start_point/manifest.json'
end

def base_language_filename
  '/data/docker/image_name.json'
end

if File.exist?(test_framework_filename)
  filename = test_framework_filename
else
  filename = base_language_filename
end

content = IO.read(filename)
puts JSON.parse(content)['image_name']
