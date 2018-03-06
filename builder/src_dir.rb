require_relative 'assert_system'
require_relative 'banner'
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

  def start_point?
    File.exist? dir_name + '/start_point_type.json'
  end

  def assert_create_start_point
    banner {
      script = 'cyber-dojo'
      url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
      assert_system "curl --silent -O #{url}"
      assert_system "chmod +x #{script}"
      name = 'start-point-create-check'
      remove_cmd = "./#{script} start-point rm     #{name} &> /dev/null"
      create_cmd = "./#{script} start-point create #{name} --dir=#{dir_name}"
      system remove_cmd
      assert_system create_cmd
      assert_system remove_cmd
      puts '# start point can be created'
    }
  end

  # - - - - - - - - - - - - - - - - -

  def check_all
    if docker_dirs.size == 1
      docker_dir = docker_dirs[0]
      case start_point_dirs.size
      when 0
        # language-base
        image_name = docker_dir.build_image(nil)
      when 1
        # test-framework
        image_name = start_point_dirs[0].image_name
        docker_dir.build_image(image_name)
        start_point_dirs[0].test_run
      else
        puts "docker_dirs.size == 1, start_point_dirs.size > 1 =={TODO:?custom?}"
      end

      if on_cdl_travis?
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
    else
      puts "docker_dirs.size == #{docker_dirs.size} -> else{TODO:?custom?}"
      # TODO: check that a named docker-image is
      # used in at least one start-point-dir's manifest.json file
      # or that there are no start-point-dirs.
      # TODO:
      # If the start-point-dirs all share the same image-name then if
      # there is one docker-dir, the docker-dir uses this image-name
    end
  end

  private

  include AssertSystem
  include Banner

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

  def github_org
    repo_slug.split('/')[0]
  end

  def repo_name
    repo_slug.split('/')[1]
  end

  def repo_slug
    # org-name/repo-name
    ENV['TRAVIS_REPO_SLUG']
  end

end
