# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Each hash key is the name of dir/repo which holds
# a cyber-dojo language image.
#
# Each hash value is
# {
#   from: ==> name of docker image it is built FROM,
#   image_name: ==> name of docker image it builds,
#   test_framework: ==> whether a start_point/ dir exists
# }
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test_framework==false
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# A base image which to build FROM
# Their image names typically do have version numbers, eg:
#   cyberdojofoundation/elm:0.18.0
#   cyberdojofoundation/haskell:7.6.3
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# test_framework==true
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Some dirs/repos are for images which do include a test framework.
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
# start-points usually don't have to also be updated.
# - - - - - - - - - - - - - - - - - - - - - - - - - - -