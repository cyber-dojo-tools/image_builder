require 'json'

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Each hash key is the name of dir/repo which holds
# a cyber-dojo language image.
#
# Each hash value is
# {
#   from:  ==> name of docker image it is built FROM,
#   image_name: ==> name of docker image it builds,
#   test_framework: ==> whether there is a start_point
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
# start-points do not have to also be updated.
# - - - - - - - - - - - - - - - - - - - - - - - - - - -

def get_dependencies
  ENV['TRAVIS'] == 'true' ? repo_dependencies : dir_dependencies
end

def dependency_graph(dependencies)
  if running_on_travis?
    key = ENV['TRAVIS_REPO_SLUG'].split('/')[1]
  else
    key = ENV['SRC_DIR']
  end
  root = dependencies[key].clone
  fill_dependency_graph(root, dependencies.clone)
  root
end

def fill_dependency_graph(root, dependencies)
  root[:children] = {}
  dependencies.each do |dir,entry|
    if root[:image_name] == entry[:from]
      fill_dependency_graph(root[:children][dir] = entry.clone, dependencies)
    end
  end
end

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# dir
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def dir_dependencies
  # I should be able to use Dir.glob() but I can't get it to work.
  triples = {}
  src_dir = ENV['SRC_DIR']
  base_dir = File.expand_path("#{src_dir}/..", '/')
  Dir.entries(base_dir).each do |entry|
    dir = base_dir + '/' + entry
    args = dir_get_args(dir)
    triples[dir] = args unless args.nil?
  end
  triples
end

def read_nil(filename)
  File.exists?(filename) ? IO.read(filename) : nil
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def dir_get_args(dir)
  docker_filename = dir + '/docker/Dockerfile'
  dockerfile = read_nil(docker_filename)
  return nil if dockerfile.nil?
  args = []
  args << (image_name_filename = dir + '/docker/image_name.json')
  args << (manifest_filename   = dir + '/start_point/manifest.json')
  args << (image_name_file = read_nil(image_name_filename))
  args << (manifest_file   = read_nil(manifest_filename))
  {
    from:get_FROM(dockerfile),
    image_name:get_image_name(args),
    test_framework:get_test_framework(manifest_file)
  }
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

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# repo

def repo_dependencies
  triples = {}
  base_url = 'https://raw.githubusercontent.com/cyber-dojo-languages'
  get_repo_names.each do |repo_name|
    # eg repo_name = 'gplusplus-catch'
    url = base_url + '/' + repo_name + '/' + 'master/docker/Dockerfile'
    dockerfile = curl_nil(url)
    unless dockerfile.nil?
      print '.'
      triple = {}
      triple[:from] = get_FROM(dockerfile)
      set_image_name_repo(triple, base_url + '/' + repo_name + '/master')
      triples[repo_name] = triple
    end
  end
  triples
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def get_repo_names
  # https://developer.github.com/v3/repos/#list-organization-repositories
  # important to use GITHUB_TOKEN in an authenticated request
  # so the github rate-limit is 5000 requests per hour. Non
  # authenticated rate-limit is only 60 requests per hour.
  github_token = ENV['GITHUB_TOKEN']
  if github_token.nil? || github_token == ''
    failed [ 'GITHUB_TOKEN env-var not set' ]
  end
  org_url = 'https://api.github.com/orgs/cyber-dojo-languages'
  command = [
    'curl',
    '--silent',
    "--user 'travisuser:#{github_token}'",
    "--header 'Accept: application/vnd.github.v3.full+json'",
    org_url + '/repos?per_page=1000'
  ].join(' ')
  response = `#{command}`
  json = JSON.parse(response)
  json.collect { |repo| repo['name'] }
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def set_image_name_repo(triple, repo_url)
  language_filename = repo_url + '/docker/image_name.json'
  test_framework_filename = repo_url + '/start_point/manifest.json'

  language_file = curl_nil(language_filename)
  test_framework_file = curl_nil(test_framework_filename)

  set_image_name_test_framework(triple, {
    language_filename:language_filename,
    test_framework_filename:test_framework_filename,
    language_file:language_file,
    test_framework_file:test_framework_file
  })
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def set_image_name_test_framework(triple, args)
  either_or = [
    "#{args[:language_filename]} must exist",
    'or',
    "#{args[:test_framework_filename]} must exist"
  ]

  language = !args[:language_file].nil?
  test_framework = !args[:test_framework_file].nil?

  if !language && !test_framework
    failed either_or + [ 'neither do.' ]
  end
  if language && test_framework
    failed either_or + [ 'but not both.' ]
  end
  if language
    file = args[:language_file]
  end
  if test_framework
    file = args[:test_framework_file]
  end
  triple[:image_name] = JSON.parse(file)['image_name']
  triple[:test_framework] = test_framework
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def curl_nil(url)
  command = [ 'curl', '--silent', '--fail', url ].join(' ')
  file = `#{command}`
  $?.exitstatus == 0 ? file : nil
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

