require 'json'

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Each triple is
#   [ 1. name of dir/repo which holds a cyber-dojo language image,
#     2. name of docker image it is built FROM,
#     3. name of docker image it builds
#   ]
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# language triples
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Some triples are for images which are (or help to create)
# base languages which do not include a test framework.
# Their image names typically do have version numbers, eg:
#   cyberdojofoundation/elm:0.18.0
#   cyberdojofoundation/haskell:7.6.3
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test triples
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Some triples are for images which do include a test framework.
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

def dependencies
  # I should be able to use Dir.glob() but I can't get it to work.
  triples = {}
  base_dir = File.expand_path("#{ENV['SRC_DIR']}/..", '/')
  Dir.entries(base_dir).each do |entry|
    dockerfile = base_dir + '/' + entry + '/docker/Dockerfile'
    if File.exists?(dockerfile)
      lines = IO.read(dockerfile).split("\n")
      from_line = lines.find { |line| line.start_with? 'FROM' }
      from = from_line.split[1].strip
      image_name = get_image_name(base_dir + '/' + entry)
      triples[base_dir + '/' + entry] = {
        'from' => from,
        'image_name' => get_image_name(base_dir + '/' + entry)
      }
    end
  end
  triples
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def get_image_name(dir)
  language_marker_file = dir + '/docker/image_name.json'
  test_framework_marker_file = dir + '/start_point/manifest.json'

  either_or = [
    "#{language_marker_file} must exist",
    'or',
    "#{test_framework_marker_file} must exist"
  ]

  is_language_dir = File.exists? language_marker_file
  is_test_framework_dir = File.exists? test_framework_marker_file

  if !is_language_dir && !is_test_framework_dir
    failed either_or + [ 'neither do.' ]
  end
  if is_language_dir && is_test_framework_dir
    failed either_or + [ 'but not both.' ]
  end
  if is_language_dir
    file = language_marker_file
  end
  if is_test_framework_dir
    file = test_framework_marker_file
  end
  JSON.parse(IO.read(file))['image_name']
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def failed(lines)
  log(['FAILED'] + lines)
  exit 1
end

def log(lines)
  print(lines, STDERR)
end

def print(lines, stream)
  lines.each { |line| stream.puts line }
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def get_repo_triples
  #TODO: get o) docker/image_name.json
  #TODO: get o) start_point/manifest.json
  #TODO: get image_name from one
  triples = {}
  base_url = 'https://raw.githubusercontent.com/cyber-dojo-languages'
  get_repo_names.each do |repo_name|
    # eg repo_name = 'gplusplus-catch'
    url = base_url + '/' + repo_name + '/' + 'master/docker/Dockerfile'
    command = [ 'curl', '--silent', '--fail', url ].join(' ')
    dockerfile = `#{command}`
    if $?.success?
      lines = dockerfile.split("\n")
      from_line = lines.find { |line| line.start_with? 'FROM' }
      from = from_line.split[1].strip
      triples[repo_name] = {
        'from' => from
      }
    end
  end
  triples
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def get_repo_names
  # important to use GITHUB_TOKEN in an authenticated request
  # so the github rate-limit is 5000 requests per hour. Non
  # authenticated rate-limit is only 60 requests per hour.
  org_url = 'https://api.github.com/orgs/cyber-dojo-languages'
  # TODO: verify GITHUB_TOKEN env-var is set
  github_token = ENV['GITHUB_TOKEN']
  command = [
    'curl',
    '--silent',
    "--user 'travisuser:#{github_token}'",
    "--header 'Accept: application/vnd.github.v3.full+json'",
    org_url + '/repos'
  ].join(' ')
  response = `#{command}`
  json = JSON.parse(response)
  json.collect { |repo| repo['name'] }
end

