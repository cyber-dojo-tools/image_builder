require_relative 'assert_system'
require_relative 'banner'
require_relative 'print_to'

class StartPoint

  def initialize(src_dir)
    @src_dir = src_dir
  end

  def exist?
    Dir.exist? src_dir
  end

  # - - - - - - - - - - - - - - - - -

  def test_create
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
