require_relative 'assert_system'
require_relative 'banner'
require_relative 'docker_dir'
require_relative 'failed'
require_relative 'print_to'
require_relative 'start_point_dir'
require_relative 'travis'

class StartPoint

  def initialize(src_dir)
    unless Dir.exist? src_dir
      failed "#{src_dir} does not exist"
    end
    @src_dir = src_dir
  end

  # - - - - - - - - - - - - - - - - -

  def assert_create
    banner {
      script = 'cyber-dojo'
      url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
      assert_system "curl --silent -O #{url}"
      assert_system "chmod +x #{script}"
      name = 'start-point-create-check'
      remove_cmd = "./#{script} start-point rm     #{name} &> /dev/null"
      create_cmd = "./#{script} start-point create #{name} --dir=#{src_dir}"
      system remove_cmd
      assert_system create_cmd
      assert_system remove_cmd
      print_to STDOUT, 'start point can be created'
    }
  end

  # - - - - - - - - - - - - - - - - -

  def check_all

    # TODO: need to check that a named docker-image is
    # used in at least one manifest.json file.

    # TODO: If there is only one docker_dir and one start_point_dir
    # then the start-point dir's manifest determines the image_name
    # and the docker_dir does not need an image_name.json file.
    # Otherwise it does.

    docker_dirs = get_docker_dirs
    start_point_dirs = get_start_point_dirs

    docker_dir = docker_dirs[0]
    start_point_dir = start_point_dirs[0]

    image_name = nil
    if start_point_dir
      image_name = start_point_dir.image_name
    end
    if docker_dir
      image_name = docker_dir.build_image(image_name)
    end
    if start_point_dir
      start_point_dir.test_run
    end

    if on_travis? &&
        github_org == 'cyber-dojo-languages' &&
          repo_name != 'image_builder' &&
            docker_dir

      # assert start_point_dirs.size == 1
      triple = {
          'from'           => docker_dir.image_FROM,
          'image_name'     => image_name,
          'test_framework' => !start_point_dir.nil?
        }
      travis = Travis.new(triple)
      travis.validate_triple
      travis.push_image_to_dockerhub
      travis.trigger_dependents
    end
  end

  private

  attr_reader :src_dir

  include AssertSystem
  include Banner
  include PrintTo

  def get_docker_dirs
    Dir["#{src_dir}/**/Dockerfile"].map { |path|
      DockerDir.new(File.dirname(path))
    }
  end

  # - - - - - - - - - - - - - - - - -

  def get_start_point_dirs
    Dir["#{src_dir}/**/manifest.json"].map { |path|
      StartPointDir.new(File.dirname(path))
    }
  end

  # - - - - - - - - - - - - - - - - -

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
