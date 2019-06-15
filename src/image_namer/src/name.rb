
# SRC_DIR has been volume-mounted to /data
# Writes the image_name associated with SRC_DIR
# For a base-language this is the image_name property of
# /data/docker/image_name.json
# For a test-framework this is the image_name property of
# /data/start_point/image_name.json

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
