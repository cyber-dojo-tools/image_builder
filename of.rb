#!/usr/bin/env ruby

# each triples is
#   [ repo-name,
#     name of image it is built FROM,
#     name of image it builds
#   ]

images = [
  [ 'https://github.com/cyber-dojo-languages/elm-test',
    'cyberdojofoundation/elm-0.18.0',
    'cyberdojofoundation/elm_test'
  ],
  [ 'https://github.com/cyber-dojo-languages/haskell-hunit',
    'cyberdojofoundation/haskell-7.6.3',
    'cyberdojofoundation/haskell_hunit'
  ]
]


puts ARGV[0]
puts images