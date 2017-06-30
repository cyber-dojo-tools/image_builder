require_relative 'runner_service_statefull'
require_relative 'runner_service_stateless'
require 'json'

class Builder

  def initialize(src_dir)
    @src_dir = src_dir
  end

  def check_required_files_exist
    banner_begin
    if !docker_image_src?
      failed [ "#{docker_marker_file} must exist" ]
    end
    either_or = [
      "#{language_repo_marker_file} must exist",
      'or',
      "#{test_framework_repo_marker_file} must exist"
    ]
    if !language_repo? && !test_framework_repo?
      failed either_or + [ 'neither do.' ]
    end
    if language_repo? && test_framework_repo?
      failed either_or + [ 'but not both.' ]
    end
    banner_end
  end

  # - - - - - - - - - - - - - - - - -

  def image_name
    # As it appears in the relevant json file.
    filename = language_repo_marker_file if language_repo?
    filename = test_framework_repo_marker_file if test_framework_repo?
    json_image_name(filename)
  end

  def build_the_image
    banner_begin
    assert_system "cd #{docker_dir} && docker build --tag #{image_name} ."
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
    name = 'checking'
    assert_system "./#{script} start-point create #{name} --dir=#{src_dir}"
    # TODO: ensure always removed
    assert_system "./#{script} start-point rm #{name}"
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

  attr_reader :src_dir

  def json_image_name(filename)
    # TODO: better diagnostics on failure
    manifest = IO.read(filename)
    json = JSON.parse(manifest)
    json['image_name']
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

  def call_rag_lambda(sss)
    # TODO: improve diagnostics if cat/eval/call fails
    cat_rag_filename = "docker run --rm -it #{image_name} cat #{rag_filename}"
    src = assert_backtick cat_rag_filename
    fn = eval(src)
    fn.call(sss['stdout'], sss['stderr'], sss['status'])
  end

  # - - - - - - - - - - - - - - - - -

  def docker_image_src?
    File.exists? docker_marker_file
  end

  def docker_marker_file
    "#{docker_dir}/Dockerfile"
  end

  def docker_dir
    src_dir + '/docker'
  end

  # - - - - - - - - - - - - - - - - -

  def language_repo?
    File.exists? language_repo_marker_file
  end

  def language_repo_marker_file
    "#{docker_dir}/image_name.json"
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

  def quoted(s)
    '"' + s + '"'
  end

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