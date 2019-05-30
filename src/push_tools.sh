#!/bin/bash
set -e

docker push cyberdojo/dockerfile_augmenter
docker push cyberdojo/image_namer
docker push cyberdojo/dependents_notifier
