
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

def dependencies
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
