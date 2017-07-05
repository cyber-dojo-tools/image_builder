#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'dependencies'
require_relative 'dockerhub'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# TODO: This is inefficient.
# It would be better if I gathered all the dependencies
# and then, if running on Travis, I git cloned _all_
# the repos in the graphs into SRC_DIR
# and then proceeded as if running locally.

def running_on_travis?
  ENV['TRAVIS'] == 'true'
end

def key
  if running_on_travis?
    ENV['TRAVIS_REPO_SLUG'].split('/')[1]
  else
    ENV['SRC_DIR']
  end
end

def push?
  ARGV.include?('--push=true') || running_on_travis?
end

puts '-' * 42
puts 'gathering_dependencies'
dependencies = get_dependencies
puts
puts JSON.pretty_generate(dependencies)

graph = dependency_graph(key, dependencies)
puts
puts JSON.pretty_generate(graph)

Dockerhub.login if push?

args = dependencies[key]
builder = ImageBuilder.new(key, args)
builder.build_and_test_image

Dockerhub.push(builder.image_name) if push?
