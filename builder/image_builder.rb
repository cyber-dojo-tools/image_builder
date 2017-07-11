require_relative 'runner_service_statefull'
require_relative 'runner_service_stateless'
require 'json'

class ImageBuilder

  def initialize(src_dir, args)
    @src_dir = src_dir
    @args = args
  end

  def build_and_test_image
    banner('=', src_dir)
    if test_framework?
      check_start_point_can_be_created
    end
    build_the_image
    if test_framework?
      check_images_red_amber_green_lambda_file
      check_start_point_src_red_green_amber_using_runner_stateless
      check_start_point_src_red_green_amber_using_runner_statefull
    end
    image_name
  end

  private

  def image_name
    @args[:image_name]
  end

  # - - - - - - - - - - - - - - - - -

  def build_the_image
    banner
    assert_system "cd #{src_dir}/docker && docker build --tag #{image_name} ."
  end

  # - - - - - - - - - - - - - - - - -

  def test_framework?
    @args[:test_framework]
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
    system "./#{script} start-point rm #{name} &> /dev/null"
    assert_system "./#{script} start-point create #{name} --dir=#{src_dir}"
  end

  # - - - - - - - - - - - - - - - - -

  def check_images_red_amber_green_lambda_file
    banner
    sss = { 'stdout' => 'sdd', 'stderr' => 'sdsd', 'status' => 42 }
    assert_rag(:amber, sss, "#{rag_filename} sanity check")
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_red_green_amber_using_runner_stateless
    banner
    if options['runner_statefull_only']
      puts "skipped: options['runner_statefull_only']"
      return
    end
    assert_timed_run_stateless(:red)
    assert_timed_run_stateless(:amber)
    assert_timed_run_stateless(:green)
  end

  def assert_timed_run_stateless(colour)
    runner = RunnerServiceStateless.new
    args = [image_name]
    args << kata_id
    args << 'salmon'
    args << all_files(colour)
    args << (max_seconds=10)
    took,sss = timed_run { runner.run(*args) }
    assert_rag(colour, sss, "dir == #{start_point_dir}")
    puts "#{colour}: OK (~#{took} seconds)"
  end

  def all_files(colour)
    files = start_files
    return files if colour == :red
    filename,content = edited_file(colour)
    files[filename] = content
    files
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_red_green_amber_using_runner_statefull
    banner
    runner = RunnerServiceStatefull.new
    runner.kata_new(image_name, kata_id)
    begin
      assert_timed_run_statefull(:red  , runner, 'rhino')
      assert_timed_run_statefull(:amber, runner, 'antelope')
      assert_timed_run_statefull(:green, runner, 'gopher')
    ensure
      runner.kata_old(image_name, kata_id)
    end
  end

  def assert_timed_run_statefull(colour, runner, avatar_name)
    begin
      runner.avatar_new(image_name, kata_id, avatar_name, start_files)
      args = [image_name]
      args << kata_id
      args << avatar_name
      args << (deleted_filenames=[])
      args << changed_files(colour)
      args << (max_seconds=10)
      took,sss = timed_run { runner.run(*args) }
      assert_rag(colour, sss, "dir == #{start_point_dir}")
      puts "#{colour}: OK (~#{took} seconds)"
    ensure
      runner.avatar_old(image_name, kata_id, avatar_name)
    end
  end

  def changed_files(colour)
    return {} if colour == :red
    filename,content = edited_file(colour)
    { filename => content }
  end

  # - - - - - - - - - - - - - - - - -

  def edited_file(colour)
    args = options[colour.to_s]
    if !args.nil?
      filename = args['filename']
      from = args['from']
      to = args['to']
    elsif colour == :amber
      from = '6 * 9'
      to = '6 * 9sdsd'
      filename = filename_6_times_9(from)
    elsif colour == :green
      from = '6 * 9'
      to = '6 * 7'
      filename = filename_6_times_9(from)
    end
    return filename, start_files[filename].sub(from,to)
  end

  # - - - - - - - - - - - - - - - - -

  def filename_6_times_9(from)
    filenames = start_files.select { |_,content| content.include? from }
    if filenames == []
      failed [ "no '#{from}' file found" ]
    end
    if filenames.length > 1
      failed [ "multiple '#{from}' files " + filenames.inspect ]
    end
    filenames.keys[0]
  end

  # - - - - - - - - - - - - - - - - -

  def options
    # TODO: add handling of failed json parse
    options_file = start_point_dir + '/options.json'
    if File.exists? options_file
      JSON.parse(IO.read(options_file))
    else
      {}
    end
  end

  # - - - - - - - - - - - - - - - - -

  def timed_run
    started = Time.now
    sss = yield
    stopped = Time.now
    took = (stopped - started).round(2)
    return took,sss
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

  def start_files
    # start-point has already been verified
    manifest_filename = start_point_dir + '/manifest.json'
    manifest = IO.read(manifest_filename)
    manifest = JSON.parse(manifest)
    files = {}
    manifest['visible_filenames'].each do |filename|
      path = start_point_dir + '/' + filename
      files[filename] = IO.read(path)
    end
    files
  end

  def start_point_dir
    src_dir + '/start_point'
  end

  attr_reader :src_dir

  # - - - - - - - - - - - - - - - - -

  def banner(ch = '-', title = caller_locations(1,1)[0].label)
    line = ch * 42
    print_to([ '', line, title], STDOUT)
  end

  # - - - - - - - - - - - - - - - - -

  def assert_system(command)
    system command
    status = $?.exitstatus
    unless status == success
      failed command, "exit_status == #{status}"
    end
  end

  def assert_backtick(command)
    output = `#{command}`
    status = $?.exitstatus
    unless status == success
      failed command, "exit_status == #{status}", output
    end
    output
  end

  # - - - - - - - - - - - - - - - - -

  def failed(*lines)
    log ['FAILED'] + lines
    exit 1
  end

  def log(lines)
    print_to(lines, STDERR)
  end

  def print_to(lines, stream)
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

end