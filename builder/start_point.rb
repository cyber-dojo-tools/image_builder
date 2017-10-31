require_relative 'assert_system'
require_relative 'banner'
require_relative 'docker_dir'
require_relative 'failed'
require_relative 'print_to'
require_relative 'start_point_dir'

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
      system "./#{script} start-point rm #{name} &> /dev/null"
      assert_system "./#{script} start-point create #{name} --dir=#{src_dir}"
      print_to STDOUT, 'start point can be created'
    }
  end

  # - - - - - - - - - - - - - - - - -

  def dirs
    # TODO: need to check that a named docker-image is
    # used in at least one manifest.json file.
    # TODO: If there is only one docker_dir and one start_point_dir
    # then the start-point dir's manifest determines the image_name
    # and the docker_dir does not need an image_name.json file.
    # Otherwise it does.
    return docker_dirs, start_point_dirs
  end

  private

  attr_reader :src_dir

  include AssertSystem
  include Banner
  include PrintTo

  def docker_dirs
    Dir["#{src_dir}/**/Dockerfile"].map { |path|
      DockerDir.new(File.dirname(path))
    }
  end

  # - - - - - - - - - - - - - - - - -

  def start_point_dirs
    Dir["#{src_dir}/**/manifest.json"].map { |path|
      StartPointDir.new(File.dirname(path))
    }
  end

end
