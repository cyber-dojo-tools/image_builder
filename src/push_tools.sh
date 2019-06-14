#!/bin/bash
set -e

docker push cyberdojofoundation/dockerfile_augmenter
docker push cyberdojofoundation/image_namer
docker push cyberdojofoundation/dependents_notifier
