
# Writes the image_name associated with a start-points' dir.

require 'json'

def test_framework_filename
  '/data/start_point/manifest.json'
end

def base_language_filename
  '/data/docker/image_name.json'
end

def name_from(filename)
  content = IO.read(filename)
  JSON.parse(content)['image_name']
end

if File.exist?(test_framework_filename)
  puts name_from(test_framework_filename)
else
  puts name_from(base_language_filename)
end
