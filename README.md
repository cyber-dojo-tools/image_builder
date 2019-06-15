# image_builder

[build_test_push_notify.sh](https://github.com/cyber-dojo-languages/image_builder/blob/master/build_test_push_notify.sh)
is the script (containing docker commands) which all the
[cyber-dojo-languages github organization](https://github.com/cyber-dojo-languages)
repos curl and then run as the only command in their CI script.

There are two kinds of repos in the cyber-dojo-languages github organization:
- language repos
- testFramework repos

- - - -

# language repos
Contain a docker/Dockerfile which installs a base language.
The image_builder attempts to build the docker image.
If successful and the run is not via a CI cron-job it
1. pushes the image to the
[cyberdojofoundation](https://hub.docker.com/u/cyberdojofoundation/)
dockerhub
2. triggers all dependent github repos.
See [example](https://github.com/cyber-dojo-languages/python).

- - - -

# testFramework repos
Contain a docker/Dockerfile which installs a test-framework.
Also contains start_point/files for the test-framework.
The image_builder attempts to build and test the docker image.
If successful, and the run is not via a CI cron-job it
1. pushes the image to the
[cyberdojofoundation](https://hub.docker.com/u/cyberdojofoundation/)
dockerhub
2. triggers all dependent github repos.
See [example](https://github.com/cyber-dojo-languages/python-pytest).

The tests
- Verify the start_point can be created using the command `cyber-dojo start-point create name --dir=REPO_DIR`
- WIP: Verify the start_point files untweaked test-run traffic-light is red
- WIP: Verify the start_point files tweaked to green test-run traffic-light is green
- WIP: Verify the start_point files tweaked to amber test-run traffic-light is amber

- - - -

# augmented Dockerfile
You must use image_builder to create images from the Dockerfiles.
The Dockerfiles **cannot** be used to build a (working) docker image with a
raw `docker build` command. This is because image_builder augments the
Dockerfiles to fulfil several [runner](https://github.com/cyber-dojo/runner)
requirements:
- it adds Linux user called sandbox
- it adds a Linux group called sandbox
- on Alpine it installs bash so every cyber-dojo.sh runs in the same shell
- on Alpine it installs coreutils so file stamp granularity is in microseconds
- on Alpine it installs file to allow (file --mime-encoding ${filename})
- on Alpine it updates tar to support the --touch option

- - - -

Note: There is a circular dependency which can occasionally bite you.
Suppose image_builder is building the cyberdojofoundation/gcc-assert image.
It will generate traffic-lights by running start-point files against
a container run from that image using the cyberdojo/runner service.
Now, cyberdojo/runner has its own tests which rely on start-point test-data
from a few language+testFrameworks, one of which is gcc-assert, which is,
of course, built by image_builder.

- - - -

![cyber-dojo.org home page](https://github.com/cyber-dojo/cyber-dojo/blob/master/shared/home_page_snapshot.png)
