#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'dependencies'
require_relative 'dockerhub'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# TODO:
# Running Travis
# Send POST to trigger immediate dependents.
#
# Running locally
# 1) SRC_DIR/.. already has dirs populated
# 2) harvest dependencies from that
# 3) create graph from SRC_DIR and dependencies
# 4) chain-build

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
#puts
#puts JSON.pretty_generate(dependencies)

puts
puts "#{dependencies.size} repos gathered"
puts

graph = dependency_graph(key, dependencies)
puts
puts JSON.pretty_generate(graph)

Dockerhub.login if push?

args = dependencies[key]
builder = ImageBuilder.new(key, args)
builder.build_and_test_image

Dockerhub.push(builder.image_name) if push?
