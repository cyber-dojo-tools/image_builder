#!/usr/bin/env ruby

# each triple is
#   [ name of repo which builds a language+TF docker image,
#     name of docker image it is built FROM,
#     name of docker image it builds
#   ]

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
