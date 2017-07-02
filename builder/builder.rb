require_relative 'runner_service_statefull'
require_relative 'runner_service_stateless'
require 'json'

class Builder

  def initialize(src_dir, args)
    @src_dir = src_dir
    @image_name = args['image_name']
    @test_framework_repo = args['test_framework_repo']
  end

  attr_reader :src_dir, :image_name

  def build_and_test_image
    banner('=', src_dir)
    build_the_image
    if test_framework_repo?
      check_images_red_amber_green_lambda_file
      check_start_point_can_be_created
      check_start_point_src_is_red_using_runner_stateless
      check_start_point_src_is_red_using_runner_statefull
      check_amber_green_filesets
    end
  end

  private

  def build_the_image
    banner
    assert_system "cd #{src_dir}/docker && docker build --tag #{image_name} ."
  end

  # - - - - - - - - - - - - - - - - -

  def test_framework_repo?
    @test_framework_repo
  end

  # - - - - - - - - - - - - - - - - -

  def check_images_red_amber_green_lambda_file
    banner
    sss = { 'stdout' => 'sdd', 'stderr' => 'sdsd', 'status' => 42 }
    assert_rag(:amber, sss, "#{rag_filename} sanity check")
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_can_be_created
    # TODO: Try the curl several times before failing?
    banner
    script = 'cyber-dojo'
    url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
    assert_system "curl --silent -O #{url}"
    assert_system "chmod +x #{script}"
    name = 'start-point-create-check'
    system "./#{script} start-point rm #{name} 2>&1 > /dev/null"
    assert_system "./#{script} start-point create #{name} --dir=#{src_dir}"
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_is_red_using_runner_stateless
    banner
    runner = RunnerServiceStateless.new
    sss = runner.run(image_name, kata_id, avatar_name, start_point_visible_files, max_seconds)
    assert_rag(:red, sss, "dir == #{start_point_dir}")
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_is_red_using_runner_statefull
    banner
    runner = RunnerServiceStatefull.new
    runner.kata_new(image_name, kata_id)
    runner.avatar_new(image_name, kata_id, avatar_name, start_point_visible_files)
    sss = runner.run(image_name, kata_id, avatar_name, deleted_filenames=[], changed_files={}, max_seconds)
    runner.avatar_old(image_name, kata_id, avatar_name)
    runner.kata_old(image_name, kata_id)
    assert_rag(:red, sss, "dir == #{start_point_dir}")
  end

  # - - - - - - - - - - - - - - - - -

  def check_amber_green_filesets
    banner
    # If /6 * 9/ can be found in the start-point then
    #   check that /6 * 7/ is green
    #   check that /6 * 9sdsd/ is amber

    # If traffic_lights/ sub-dirs exist, test them too
    #   ... assume they contain complete filesets?

    # If /6 * 9/ can't be found and no traffic_lights/ sub-dirs exist
    # then treat that as an error?
  end

  # - - - - - - - - - - - - - - - - -

  def assert_rag(expected_colour, sss, diagnostic)
    actual_colour = call_rag_lambda(sss)
    unless expected_colour == actual_colour
      failed [ diagnostic,
        "expected_colour == #{expected_colour}",
        "  actual_colour == #{actual_colour}",
        "stdout == #{sss['stdout']}",
        "stderr == #{sss['stderr']}",
        "status == #{sss['status']}"
      ]
    end
  end

  # - - - - - - - - - - - - - - - - -

  def call_rag_lambda(sss)
    # TODO: improve diagnostics if cat/eval/call fails
    cat_rag_filename = "docker run --rm -it #{image_name} cat #{rag_filename}"
    src = assert_backtick cat_rag_filename
    fn = eval(src)
    fn.call(sss['stdout'], sss['stderr'], sss['status'])
  end

  # - - - - - - - - - - - - - - - - -

  def start_point_visible_files
    # start-point has already been verified
    manifest = JSON.parse(IO.read(start_point_dir + '/manifest.json'))
    visible_files = {}
    manifest['visible_filenames'].each do |filename|
      visible_files[filename] = IO.read(start_point_dir + '/' + filename)
    end
    visible_files
  end

  def test_framework_repo_marker_file
    "#{start_point_dir}/manifest.json"
  end

  def start_point_dir
    src_dir + '/start_point'
  end

  # - - - - - - - - - - - - - - - - -

  def banner(ch = '-', title = caller_locations(1,1)[0].label)
    line = ch * 42
    print([ '', line, title, ], STDOUT)
  end

  # - - - - - - - - - - - - - - - - -

  def assert_system(command)
    system command
    status = $?.exitstatus
    unless status == success
      failed [ command, "exit_status == #{status}" ]
    end
  end

  def assert_backtick(command)
    output = `#{command}`
    status = $?.exitstatus
    unless status == success
      failed [ command, "exit_status == #{status}", output ]
    end
    output
  end

  # - - - - - - - - - - - - - - - - -

  def failed(lines)
    log(['FAILED'] + lines)
    exit 1
  end

  def log(lines)
    print(lines, STDERR)
  end

  def print(lines, stream)
    lines.each { |line| stream.puts line }
  end

  # - - - - - - - - - - - - - - - - -

  def success
    0
  end

  def rag_filename
    '/usr/local/bin/red_amber_green.rb'
  end

  # - - - - - - - - - - - - - - - - -

  def kata_id
    '6F4F4E4759'
  end

  def avatar_name
    'salmon'
  end

  def max_seconds
    10
  end

end