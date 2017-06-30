require_relative 'runner_service_statefull'
require_relative 'runner_service_stateless'
require 'json'

class Builder

  def initialize(src_dir, args)
    @src_dir = src_dir
    @image_name = args['image_name']
  end

  attr_reader :src_dir, :image_name

  def build_the_image
    banner_begin
    assert_system "cd #{src_dir}/docker && docker build --tag #{image_name} ."
    banner_end
  end

  # - - - - - - - - - - - - - - - - -

  def test_framework_repo?
    File.exists? test_framework_repo_marker_file
  end

  # - - - - - - - - - - - - - - - - -

  def check_images_red_amber_green_lambda_file
    banner_begin
    sss = { 'stdout' => 'sdd', 'stderr' => 'sdsd', 'status' => 42 }
    assert_rag(:amber, sss, "#{rag_filename} sanity check")
    banner_end
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_can_be_created
    # TODO: Try the curl several times before failing?
    banner_begin
    script = 'cyber-dojo'
    url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
    assert_system "curl -O #{url}"
    assert_system "chmod +x #{script}"
    name = 'start-point-create-check'
    system "./#{script} start-point rm #{name} 2>&1 > /dev/null"
    assert_system "./#{script} start-point create #{name} --dir=#{src_dir}"
    banner_end
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_is_red_using_runner_stateless
    banner_begin
    runner = RunnerServiceStateless.new
    sss = runner.run(image_name, kata_id, avatar_name, start_point_visible_files, max_seconds)
    assert_rag(:red, sss, "dir == #{start_point_dir}")
    banner_end
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_is_red_using_runner_statefull
    banner_begin
    runner = RunnerServiceStatefull.new
    runner.kata_new(image_name, kata_id)
    runner.avatar_new(image_name, kata_id, avatar_name, start_point_visible_files)
    sss = runner.run(image_name, kata_id, avatar_name, deleted_filenames=[], changed_files={}, max_seconds)
    runner.avatar_old(image_name, kata_id, avatar_name)
    runner.kata_old(image_name, kata_id)
    assert_rag(:red, sss, "dir == #{start_point_dir}")
    banner_end
  end

  # - - - - - - - - - - - - - - - - -

  def check_amber_green_filesets
    banner_begin
    # If /6 * 9/ can be found in the start-point then
    #   check that /6 * 7/ is green
    #   check that /6 * 9sdsd/ is amber

    # If traffic_lights/ sub-dirs exist, test them too
    #   ... assume they contain complete filesets?

    # If /6 * 9/ can't be found and no traffic_lights/ sub-dirs exist
    # then treat that as an error?
    banner_end
  end

  private

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

  def banner_begin
    title = caller_locations(1,1)[0].label
    print([ '', banner_line, title, ], STDOUT)
  end

  def banner_end
    print([ 'OK', banner_line ], STDOUT)
  end

  def banner_line
    '-' * 42
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