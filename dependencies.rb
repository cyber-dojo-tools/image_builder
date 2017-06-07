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
# These are for images which are, or helps to create,
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


def dependencies
  cdl = 'https://github.com/cyber-dojo-languages'
  [

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Alpine 3.4
    [ "#{cdl}/alpine-language-base-3.4",
      'alpine:3.4',
      'cyberdojofoundation/alpine-language_base:3.4'
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Chapel

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Elixir

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Ubuntu-14-04
    [ "#{cdl}/ubuntu-build-essential-14.04",
      'ubuntu:14.04',
      'cyberdojofoundation/ubuntu-build-essential:14.04'
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Elm
    [ "#{cdl}/elm-0.18.0",
      'cyberdojofoundation/ubuntu-build-essential:14.04',
      'cyberdojofoundation/elm:0.18.0'
    ],
    [ "#{cdl}/elm-test",
      'cyberdojofoundation/elm:0.18.0',
      'cyberdojofoundation/elm_test'
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Haskell
    [ "#{cdl}/haskell-7.6.3",
      'cyberdojofoundation/ubuntu-build-essential:14.04',
      'cyberdojofoundation/haskell:7.6.3'
    ],
    [ "#{cdl}/haskell-hunit",
      'cyberdojofoundation/haskell:7.6.3',
      'cyberdojofoundation/haskell_hunit'
    ],
  ]
end
