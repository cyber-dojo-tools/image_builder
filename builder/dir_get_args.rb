require 'json'

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Each hash key is the name of dir/repo which holds
# a cyber-dojo language image.
#
# Each hash value is
# {
#   from: ==> name of docker image it is built FROM,
#   image_name: ==> name of docker image it builds,
#   test_framework: ==> whether a start_point/ dir exists
# }
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test_framework==false
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# A base image which to build FROM
# Their image names typically do have version numbers, eg:
#   cyberdojofoundation/elm:0.18.0
#   cyberdojofoundation/haskell:7.6.3
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test_framework==true
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Some dirs/repos are for images which do include a test framework.
# Their image names do not have version numbers, eg:
#   cyberdojofoundation/elm_test
#   cyberdojofoundation/haskell_hunit
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# version numbers
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The idea is that when a test-framework's docker image is
# successfully updated to a new version of its base language
# (or a newer version of the test framework) then its docker
# image-name does not change. This decoupling means the
# start-points usually don't have to also be updated.
# - - - - - - - - - - - - - - - - - - - - - - - - - - -

def dir_get_args(dir)
  get_args(dir) { |filename| read_nil(filename) }
end

def get_args(base)
  docker_filename = base + '/docker/Dockerfile'
  dockerfile = yield(docker_filename)
  if dockerfile.nil?
    return nil
  end
  args = []
  args << (image_name_filename = base + '/docker/image_name.json')
  args << (manifest_filename   = base + '/start_point/manifest.json')
  args << (image_name_file = yield(image_name_filename))
  args << (manifest_file   = yield(manifest_filename))
  {
    from:get_FROM(dockerfile),
    image_name:get_image_name(args),
    test_framework:get_test_framework(manifest_file)
  }
end

def read_nil(filename)
  File.exists?(filename) ? IO.read(filename) : nil
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def get_FROM(dockerfile)
  lines = dockerfile.split("\n")
  from_line = lines.find { |line| line.start_with? 'FROM' }
  from_line.split[1].strip
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def get_image_name(args)
  image_name_filename = args[0]
  manifest_filename   = args[1]
  image_name_file     = args[2]
  manifest_file       = args[3]

  either_or = [
    "#{image_name_filename} must exist",
    'or',
    "#{manifest_filename} must exist"
  ]

  image_name = !image_name_file.nil?
  manifest = !manifest_file.nil?

  if !image_name && !manifest
    failed either_or + [ 'neither do.' ]
  end
  if image_name && manifest
    failed either_or + [ 'but not both.' ]
  end
  if image_name
    file = image_name_file
  end
  if manifest
    file = manifest_file
  end
  JSON.parse(file)['image_name']
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def get_test_framework(file)
  !file.nil?
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def failed(lines)
  log(['FAILED'] + lines)
  exit 1
end

def log(lines)
  print_to(lines, STDERR)
end

def print_to(lines, stream)
  lines.each { |line| stream.puts line }
end
