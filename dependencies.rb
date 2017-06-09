#!/usr/bin/env ruby

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Each triple is
#   [ 1.name of repo which builds a docker image,
#     2.name of docker image it is built FROM,
#     3.name of docker image it builds
#   ]

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1. repo-name
#    I'd like the repo-name to be named, eg,
#    "#{cdl}/alpine-language-base:3.4
#    but github does not allow a colon in the repo name
#    so I'm using
#    "#{cdl}/alpine-language-base-3.4
#
# 2. FROM-name
#    This is exactly as it appears in the Dockerfile
#    This does use a :version-number
#
# 3. image-name
#    This also does use a :version-number

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# There are two kinds of triples:
#
# base-entries
# - - - - - - -
# These are for images which are, or help to create,
# base language repos which do not include a test
# framework. These DO have version numbers.
# Examples
#   cyberdojofoundation/elm:0.18.0
#   cyberdojofoundation/haskell:7.6.3
#
# language-entries
# - - - - - - - - -
# These are for images which do include a test
# framwork. These do NOT have version numbers.
# Examples
#   cyberdojofoundation/elm_test
#   cyberdojofoundation/haskell_hunit
# - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
  ]
end
