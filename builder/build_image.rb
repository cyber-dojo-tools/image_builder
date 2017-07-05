#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'dependencies'
require_relative 'dockerhub'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def running_on_travis?
  ENV['TRAVIS'] == 'true'
end

def push?
  ARGV.include?('--push=true') || running_on_travis?
end

=begin
if running_on_travis?
  repo_triples = get_repo_triples
  puts "<repo_triples>"
  puts repo_triples.inspect
  puts "</repo_triples>"
else
  puts "<dir_triples>"
  puts dir_dependencies.inspect
  puts "</dir_triples>"
end
=end

src_dir = ENV['SRC_DIR']
args = dir_dependencies[src_dir]

if !running_on_travis?
  graph = dependency_graph(src_dir, dir_dependencies)
  puts JSON.pretty_generate(graph)
end

Dockerhub.login if push?
builder = ImageBuilder.new(src_dir, args)
builder.build_and_test_image
Dockerhub.push(builder.image_name) if push?
