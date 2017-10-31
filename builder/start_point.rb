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

  private

  attr_reader :src_dir

  include AssertSystem
  include Banner
  include PrintTo

end
