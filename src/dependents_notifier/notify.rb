
# Main entry point for cyberdojo/dependents_notifier docker image.
# The start-point dir has been volume mounted to /data

# require_relative 'travis'

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

if false && on_cdl_travis? && !travis_cron_job?
  # assert docker_dirs.size == 1
  # assert [0,1].include? start_point_dirs.size
  triple = {
      'from'           => docker_dir.image_FROM,     # <<< TODO
      'image_name'     => image_name,                # <<< TODO
      'test_framework' => !start_point_dirs[0].nil?  # <<< TODO
    }
  travis = Travis.new(triple)
  travis.validate_triple
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end


puts "Hello from notify.rb"
