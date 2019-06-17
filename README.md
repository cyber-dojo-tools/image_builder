# image_builder

[build_test_push_notify.sh](https://github.com/cyber-dojo-languages/image_builder/blob/master/build_test_push_notify.sh) is the script (containing docker commands) which all the
[cyber-dojo-languages](https://github.com/cyber-dojo-languages) repos
run in their .circleci/config.yml

There are two kinds of repos in the cyber-dojo-languages github organization:
- baseLanguage repos
- testFramework repos

- - - -

# baseLanguage repos
For example, [python](https://github.com/cyber-dojo-languages/python).
- contain a docker/Dockerfile which installs a base language.
- attempts to build the docker image, taking its name from the file docker/image_name.json
- if successful:
  - pushes the docker image to [cyberdojofoundation](https://hub.docker.com/u/cyberdojofoundation/) on dockerhub
  - triggers the workflow for all CircleCI projects (eg python-pytest) whose Dockerfile's FROM matches the image name.

- - - -

# testFramework repos
For example, [python-pytest](https://github.com/cyber-dojo-languages/python-pytest).
- contain a docker/Dockerfile which installs a test-framework.
- contain start_point/files for the test-framework.
- attempts to build the docker image, taking its name from the file start_point/manifest.json,
with the docker/Dockerfile [augmented](https://github.com/cyber-dojo-languages/image_dockerfile_augmenter) to fulfil the [runner's](https://github.com/cyber-dojo/runner) requirements.
- if successful:
  - pushes the docker image to [cyberdojofoundation](https://hub.docker.com/u/cyberdojofoundation/) on dockerhub

The tests
- Verify the start_point can be created using the command:
  - `cyber-dojo start-point create name --languages ${REPO_URL}`
- WIP: Verify the start_point files untweaked test-run traffic-light is red
- WIP: Verify the start_point files tweaked to green test-run traffic-light is green
- WIP: Verify the start_point files tweaked to amber test-run traffic-light is amber

- - - -

# augmented Dockerfile
Un-augmented Dockerfiles **cannot** be used to build a (working) docker image with a
 `docker build` command. This is because [runner](https://github.com/cyber-dojo/runner) has several
requirements:
- all OS's need a Linux user called sandbox
- all OS's need a Linux group called sandbox
- Alpine needs `bash` to ensure every `cyber-dojo.sh` runs in the same shell
- Alpine needs `coreutils` so file stamp granularity is in microseconds
- Alpine needs `file` to check if a file is binary or text (--mime-encoding)
- Alpine needs `tar` to support the `--touch` option

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
