#!/usr/bin/env ruby

require_relative 'dependencies'
require 'json'

def repo_name
  ARGV[0]
end

def from
  dockerfile = IO.read('/docker/Dockerfile')
  lines = dockerfile.split("\n")
  from_line = lines.find { |line| line.start_with? 'FROM' }
  from_line.split[1].strip
end

def image_name
  manifest = JSON.parse(IO.read('/start_point/manifest.json'))
  manifest['image_name']
end

status = dependencies.include?([ repo_name, from, image_name ])
unless status
  lines = [
    'ERROR: cannot find dependency entry for',
    "  repo_name:#{repo_name}",
    "  from:#{from}",
    "  image_name:#{image_name}"
  ]
  lines.each { |line| STDERR.puts line }
end

exit status