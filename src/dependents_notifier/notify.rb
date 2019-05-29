
# Main entry point for cyberdojo/dependents_notifier docker image.
# The start-point dir has been volume mounted to /data

require_relative 'travis'
require 'json'

def on_cdl_travis?
  on_travis? &&
    github_org == 'cyber-dojo-languages' &&
      repo_name != 'image_builder'
end

def on_travis?
  ENV['TRAVIS'] == 'true'
end

def travis_cron_job?
  ENV['TRAVIS_EVENT_TYPE'] == 'cron'
end

def repo_slug
  # org-name/repo-name
  ENV['TRAVIS_REPO_SLUG']
end

def github_org
  repo_slug.split('/')[0]
end

def repo_name
  repo_slug.split('/')[1]
end

# - - - - - - - - - - - - - - - - - - -

def dockerfile
  $dockerfile ||= IO.read('/data/docker/Dockerfile')
end

# - - - - - - - - - - - - - - - - -

def from
  from_line = dockerfile.lines.find { |line| line.start_with?('FROM') }
  from_line.split[1]
end

# - - - - - - - - - - - - - - - - - - -

def test_framework?
  File.exist?(test_framework_filename)
end

def test_framework_filename
  '/data/start_point/manifest.json'
end

def base_language_filename
  '/data/docker/image_name.json'
end

def image_name
  if test_framework?
    filename = test_framework_filename
  else
    filename = base_language_filename
  end
  content = IO.read(filename)
  JSON.parse(content)['image_name']
end

# - - - - - - - - - - - - - - - - - - -

if on_cdl_travis? && !travis_cron_job?
  triple = {
    'from'           => from,
    'image_name'     => image_name,
    'test_framework' => test_framework?.to_s
  }
  travis = Travis.new(triple)
  travis.validate_triple
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end

puts "Hello from notify.rb"
