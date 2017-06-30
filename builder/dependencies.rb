require 'json'

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Each triple is
#   [ 1. name of repo which builds a docker image,
#     2. name of docker image it is built FROM,
#     3. name of docker image it builds
#   ]
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# language triples
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Some triples are for images which are, or help to create,
# base language repos which do not include a test framework.
# Their image names do have version numbers, eg:
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

# TODO: get this information dynamically
# TODO: if running locally, use glob of SRC_DIR/..
# TODO: if running on Travis, use github api to curl list orgs repos
#
# $ readonly URL=https://api.github.com/orgs/cyber-dojo-languages/repos
# $ curl -i ${URL}
#
# Response has a json body
# [
#   { "id": 91954027, "name": "elm-test", ... },
#   { "id": 91954655, "name": "haskell-hunit", ... },
#   ...
# ]
#
# Then will need to try and get 3 files per repo
#    o) docker/Dockerfile
#    o) docker/image_name.json
#    o) start_point/manifest.json
#
# This will probably quickly hit the github rate-limit of 60 per hour
# for non-authenticated access. To increase the rate-limit to 5000
# I need to authenticate
#
# # curl -i -u "user:token" ${URL}
# $ readonly URL=https://api.github.com/orgs/cyber-dojo-languages/repos
# $ curl -i -u "travisuser:${GITHUB_TOKEN}" ${URL}
#
# where the Travis repo for cyber-dojo-languages/image_builder
# will need to store GITHUB_TOKEN as a secure environment-variable
# which will need to be passed into the docker-compose run.


def local_dependencies
  # I should be able to use Dir.glob() here but doesn't seem to work?!
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

def dependencies
  return local_dependencies if !running_on_travis?
  cdl = 'https://github.com/cyber-dojo-languages'
  cdf = 'cyberdojofoundation'
  [

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Alpine 3.4
    [ "#{cdl}/alpine-language-base-3.4",
      'alpine:3.4',
      "#{cdf}/alpine-language_base:3.4"
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Chapel
    [ "#{cdl}/chapel-1.15.0",
      "#{cdf}/alpine_language_base:3.4",
      "#{cdf}/chapel:1.15.0"
    ],
    [ "#{cdl}/chapel-assert",
      "#{cdf}/chapel:1.15.0",
      "#{cdf}/chapel_assert"
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Elixir
    [ "#{cdl}/elixir-1.2.5",
      "#{cdf}/alpine_language_base:3.4",
      "#{cdf}/elixir:1.2.5"
    ],
    [ "#{cdl}/elixir-exunit",
      "#{cdf}/elixir:1.2.5",
      "#{cdf}/elixir_exunit"
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Ubuntu-14-04
    [ "#{cdl}/ubuntu-build-essential-14.04",
      'ubuntu:14.04',
      "#{cdf}/ubuntu-build-essential:14.04"
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Elm
    [ "#{cdl}/elm-0.18.0",
      "#{cdf}/ubuntu-build-essential:14.04",
      "#{cdf}/elm:0.18.0"
    ],
    [ "#{cdl}/elm-test",
      "#{cdf}/elm:0.18.0",
      "#{cdf}/elm_test"
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Haskell
    [ "#{cdl}/haskell-7.6.3",
      "#{cdf}/ubuntu-build-essential:14.04",
      "#{cdf}/haskell:7.6.3"
    ],
    [ "#{cdl}/haskell-hunit",
      "#{cdf}/haskell:7.6.3",
      "#{cdf}/haskell_hunit"
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Swift
    [ "#{cdl}/swift-3.1",
      "#{cdf}/ubuntu-build-essential:14.04",
      "#{cdf}/swift:3.1"
    ],
    [ "#{cdl}/swift-xctest",
      "#{cdf}/swift:3.1",
      "#{cdf}/swift_xctest"
    ],
    [ "#{cdl}/swift-swordfish",
      "#{cdf}/swift_xctest",
      "#{cdf}/swift_swordfish"
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Ubuntu-17-04

    [ "#{cdl}/ubuntu-build-essential-17.04",
      "ubuntu:17.04",
      "#{cdf}/ubuntu-build-essential:17.04"
    ],
    [ "#{cdl}/gplusplus-7.1",
      "#{cdf}/ubuntu-build-essential:17.04",
      "#{cdf}/gplusplus:7.1"
    ],
    [ "#{cdl}/gplusplus-assert",
      "#{cdf}/gplusplus:7.1",
      "#{cdf}/gpp_assert"
    ],
    [ "#{cdl}/gplusplus-catch",
      "#{cdf}/gplusplus:7.1",
      "#{cdf}/gpp_catch"
    ]

  ]
end
