# WIP
require_relative 'assert_system'
require_relative 'docker_dir'
require_relative 'failed'
require_relative 'start_point_dir'
require_relative 'travis'

class SourceDir

  def initialize(dir_name)
    unless Dir.exist? dir_name
      failed "#{dir_name} does not exist"
    end
    set_dir_name(dir_name)
    set_docker_dirs
    set_start_point_dirs
  end

  # - - - - - - - - - - - - - - - - -

  def check_all
    # Also, the starter will run a cron-job every 24 hours
    # which will do a [docker pull] of all the images, and for
    # any newly pulled image it will extract the start-points
    # (which will be embedded inside the image). We want genuinely
    # new images to be pulled, but not images which were
    # 'recreated' in a Travis cron-job, simply to verify they
    # still pass their tests.
    # Also, java-junit (for example) could be running on Travis because
    # its base language (java) ran on Travis. And the java Travis run could
    # also be running for both reasons... an actual git change or a cron-run.
    # I'm assuming that TRAVIS_EVENT_TYPE==api for a triggered Travis run.
    # So, a base language Travis run must only trigger its dependent repos
    # if it is being run as a NON-cron-job.

    puts "ENV['TRAVIS_EVENT_TYPE']==:#{ENV['TRAVIS_EVENT_TYPE']}:"

    if on_cdl_travis? && !travis_cron_job?
      # assert docker_dirs.size == 1
      # assert [0,1].include? start_point_dirs.size
      triple = {
          'from'           => docker_dir.image_FROM,
          'image_name'     => image_name,
          'test_framework' => !start_point_dirs[0].nil?
        }
      travis = Travis.new(triple)
      travis.validate_triple
      travis.push_image_to_dockerhub
      travis.trigger_dependents
    end
  end

  private

  include AssertSystem

  def set_dir_name(dir_name)
    @dir_name = dir_name
  end

  attr_reader :dir_name

  # - - - - - - - - - - - - - - - - -

  def set_docker_dirs
    @docker_dirs = Dir["#{dir_name}/**/Dockerfile"].map { |path|
      DockerDir.new(File.dirname(path))
    }
  end

  attr_reader :docker_dirs

  # - - - - - - - - - - - - - - - - -

  def set_start_point_dirs
    @start_point_dirs = Dir["#{dir_name}/**/manifest.json"].map { |path|
      StartPointDir.new(File.dirname(path))
    }
  end

  attr_reader :start_point_dirs

  # - - - - - - - - - - - - - - - - -

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

end
