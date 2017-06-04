
if [ ! -e ./tests/elm-stuff ]; then
  mkdir ./tests/elm-stuff
  cp -r /tmp/tests/elm-stuff/* ./tests/elm-stuff
fi

elm-test
