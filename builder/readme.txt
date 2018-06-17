At the moment builder creates an intermediate Dockerfile which
inserts commands to add users/packages/dirs to fulfil runner
dependencies.

The design is more complicated than it should be.
One problem is lack of visibility. You never get to see
the intermediate Dockerfile.

It needs to be made more visible.

One idea is to create a script called satisfy_runner_requirements.sh
and the Dockerfile is tweaked to insert commands to run this script.
This script could be curl'd from a known place (runner?) to avoid
duplication.

Another idea is to create a new Dockerfile with the new commands
inserted and to save that to a new Dockerfile and then use that
modified Dockerfile. I prefer this. It makes the modified Dockerfile
visible, part of git history, and it contain a big banner at the top
saying it is a generated file.

