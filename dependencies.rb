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
    # Ubuntu-14-04
    [ "#{cdl}/ubuntu-14-04-build-essential",
      'ubuntu:14.04',
      'cyberdojofoundation/ubuntu-14-04-build-essential'
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Elm
    [ "#{cdl}/elm",
      'cyberdojofoundation/build-essential',
      'cyberdojofoundation/elm-0.18.0'
    ],
    [ "#{cdl}/elm-test",
      'cyberdojofoundation/elm-0.18.0',
      'cyberdojofoundation/elm_test'
    ],

    # - - - - - - - - - - - - - - - - - - - - - - - - -
    # Haskell
    [ "#{cdl}/haskell",
      'cyberdojofoundation/build-essential',
      'cyberdojofoundation/haskell-7.6.3'
    ],
    [ "#{cdl}/haskell-hunit",
      'cyberdojofoundation/haskell-7.6.3',
      'cyberdojofoundation/haskell_hunit'
    ],
  ]
end
