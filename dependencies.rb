#!/usr/bin/env ruby

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Each triple is
#   [ 1.name of repo which builds a docker image,
#     2.name of docker image it is built FROM,
#     3.name of docker image it builds
#   ]
#
# 1. repo-name
#    I'd like the repo-name to be named, eg,
#    "#{cdl}/alpine-language-base:3.4
#    but github does not allow a colon in the repo name
#    so I'm using
#    "#{cdl}/alpine-language-base-3.4
#
# 2. FROM-name
#    As it appears in the Dockerfile
#
# 3. image-name
#    As it appears in the relevant json file.
#
# Each github repo (1st entry in the triple) has a travis script
# which first checks its actual dependency (from the source)
# exactly match its entry in these dependencies.

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# language triples
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Some triples are for images which are, or help to create,
# base language repos which do not include a test framework.
# Their image names have version numbers, for example:
#   cyberdojofoundation/elm:0.18.0
#   cyberdojofoundation/haskell:7.6.3

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test triples
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Some triples are for images which do include a test
# framwork. They may also have their own image too
# but some do not as they use another test framework's.
# Their image names do not have version numbers, for example:
#   cyberdojofoundation/elm_test
#   cyberdojofoundation/haskell_hunit

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# version numbers
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The idea is that when a test-framework's docker image is
# successfully updated to a new version of its base language
# (or a newer version of the test framework) then its  docker
# image-name does not change. This decouples such changes
# from the start-points which do not have to also be updated.


def cdl
  'https://github.com/cyber-dojo-languages'
end

def dependencies
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
      "#{cdf}/swift:3.1",
      "#{cdf}/swift_swordfish"
    ]

  ]
end
