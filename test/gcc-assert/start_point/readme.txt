
gcc-assert's manifest.json specifies
   "runner_choice":"stateful"

This is currently important for the cyberdojo/web tests which
rely on having two start-point languages, one using a stateless
runner, and one using a stateful runner.

gcc-assert is the one using the stateful runner.