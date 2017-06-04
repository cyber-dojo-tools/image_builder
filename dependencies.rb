#!/usr/bin/env ruby

# each triple is
#   [ name of repo which builds a language+TF docker image,
#     name of docker image it is built FROM,
#     name of docker image it builds
#   ]

def dependencies
  [
    [
      'https://github.com/cyber-dojo-languages/elm',
      'cyberdojofoundation/build-essential',
      'cyberdojofoundation/elm-0.18.0'
    ],
    [ 'https://github.com/cyber-dojo-languages/elm-test',
      'cyberdojofoundation/elm-0.18.0',
      'cyberdojofoundation/elm_test'
    ],
    [ 'https://github.com/cyber-dojo-languages/haskell-hunit',
      'cyberdojofoundation/haskell-7.6.3',
      'cyberdojofoundation/haskell_hunit'
    ]
  ]
end
