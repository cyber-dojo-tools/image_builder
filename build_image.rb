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

def base_language_repo?
  File.exists?('/docker/image_name.sh') &&
  !Dir.exists?('/start_point')
end

def language_plus_test_repo?
  !File.exists?('/docker/image_name.sh') &&
  Dir.exists?('/start_point')
end

def image_name
  if base_language_repo?
    lines = IO.read('/docker/image_name.sh').split("\n")
    line = lines.find { |line| line.start_with? 'image_name=' }
    return line.split('=')[1].strip
  end
  if language_plus_test_repo?
    manifest = JSON.parse(IO.read('/start_point/manifest.json'))
    return manifest['image_name']
  end
  return nil
end

# 1st step. Verify dependency settings

status = dependencies.include?([ repo_name, from, image_name ])
unless status
  lines = [
    'ERROR: cannot find dependency entry for',
    "  repo_name:#{repo_name}",
    "  from:#{from}",
    "  image_name:#{image_name}"
  ]
  lines.each { |line| STDERR.puts line }
  exit status
end



