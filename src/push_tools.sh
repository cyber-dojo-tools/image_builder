#!/bin/bash

push_tools()
{
  docker push cyberdojo/dockerfile_augmenter
  docker push cyberdojo/image_namer
  docker push cyberdojo/dependents_notifier
}

push_tools
