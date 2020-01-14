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
- contain a docker/Dockerfile.base which installs a base language.
- attempts to build the docker image, taking its name from the file docker/image_name.json
- if successful:
  - pushes the docker image to [cyberdojofoundation](https://hub.docker.com/u/cyberdojofoundation/) on dockerhub
  - triggers the workflow for all CircleCI projects (eg python-pytest) whose Dockerfile's FROM matches the image name.

- - - -

# testFramework repos
For example, [python-pytest](https://github.com/cyber-dojo-languages/python-pytest).
- contain a docker/Dockerfile.base which installs a test-framework.
- contain start_point/files for the test-framework.
- attempts to build the docker image, taking its name from the file start_point/manifest.json,
with docker/Dockerfile.base [augmented](https://github.com/cyber-dojo-languages/image_dockerfile_augmenter) to fulfil the [runner's](https://github.com/cyber-dojo/runner) requirements.
- Verifies the start_point files, untweaked, give a red traffic-light
- Verifies the start_point files, tweaked to green, give a green traffic-light
- Verifies the start_point files, tweaked to amber, give an amber traffic-light
- if successful:
  - pushes the docker image to [cyberdojofoundation](https://hub.docker.com/u/cyberdojofoundation/) on dockerhub

- - - -

# augmented Dockerfile
Un-augmented Dockerfiles **cannot** be used to build a (working) docker image with a
 `docker build` command. This is because [runner](https://github.com/cyber-dojo/runner) has several
requirements. All OS's need:
- a Linux user called `sandbox`.
- a Linux group called `sandbox`.
- a `/home/sandbox/` dir for the sandbox user's home dir.
- `bash` to ensure every `cyber-dojo.sh` runs in the same shell.
- `file` to check if a file is binary or text (--mime-encoding).
- `tar` with the `--touch` option.
- `truncate` to truncate large files.
- file stamp granularity in microseconds (`coreutils` on Alpine).

- - - -

Note: There is a circular dependency which can occasionally bite you.
Suppose image_builder is building the cyberdojofoundation/gcc-assert image.
It will generate traffic-lights by running start-point files against
a container run from that image using the cyberdojo/runner service.
Now, cyberdojo/runner has its own tests which rely on start-points
from a few language+testFrameworks, one of which is gcc-assert, which is,
of course, built by image_builder.

- - - -

![cyber-dojo.org home page](https://github.com/cyber-dojo/cyber-dojo/blob/master/shared/home_page_snapshot.png)
