require_relative 'runner_service_statefull'
require_relative 'runner_service_stateless'
require 'json'

class ImageBuilder

  def initialize(src_dir, args)
    @src_dir = src_dir
    @args = args
  end

  attr_reader :src_dir

  def image_name
    @args[:image_name]
  end

  def build_and_test_image
    banner('=', src_dir)
    #check_start_point_can_be_created if test_framework?
    build_the_image
    if test_framework?
      check_images_red_amber_green_lambda_file
      #unless runner_statefull_only?
        check_start_point_src_red_green_amber_using_runner_stateless
      #end
      check_start_point_src_red_green_amber_using_runner_statefull
    end
  end

  private

  def statefull_runner_only?
    options
  end

  def build_the_image
    banner
    assert_system "cd #{src_dir}/docker && docker build --tag #{image_name} ."
  end

  # - - - - - - - - - - - - - - - - -

  def test_framework?
    @args[:test_framework]
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
    system "./#{script} start-point rm #{name} &> /dev/null"
    assert_system "./#{script} start-point create #{name} --dir=#{src_dir}"
  end

  # - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_red_green_amber_using_runner_stateless
    banner
    assert_time_run_stateless(:red)
    assert_time_run_stateless(:amber)
    assert_time_run_stateless(:green)
  end

  def assert_time_run_stateless(colour)
    runner = RunnerServiceStateless.new
    method = (colour.to_s + '_files').to_sym
    start_files = start_point_visible_files
    files = self.send(method, start_files)
    args = [image_name]
    args << kata_id
    args << 'salmon'
    args << files
    args << (max_seconds=10)
    took,sss = timed_run { runner.run(*args) }
    assert_rag(colour, sss, "dir == #{start_point_dir}")
    puts "#{colour}: OK (~#{took} seconds)"
  end

  def red_files(start_files)
    start_files
  end

  def amber_files(start_files)
    filename,from,to = filename_from_to(:amber, start_files)
    content = start_files[filename]
    start_files[filename] = content.sub(from, to)
    start_files
  end

  def green_files(start_files)
    filename,from,to = filename_from_to(:green, start_files)
    content = start_files[filename]
    start_files[filename] = content.sub(from, to)
    start_files
  end

  # - - - - - - - - - - - - - - - - -
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
    start_files = start_point_visible_files
    begin
      runner.avatar_new(image_name, kata_id, avatar_name, start_files)
      method = (colour.to_s + '_changed_files').to_sym
      changed_files = self.send(method, start_files)
      args = [image_name]
      args << kata_id
      args << avatar_name
      args << (deleted_filenames=[])
      args << changed_files
      args << (max_seconds=10)
      took,sss = timed_run { runner.run(*args) }
      assert_rag(colour, sss, "dir == #{start_point_dir}")
      puts "#{colour}: OK (~#{took} seconds)"
    ensure
      runner.avatar_old(image_name, kata_id, avatar_name)
    end
  end

  def red_changed_files(_)
    {}
  end

  def green_changed_files(start_files)
    filename,from,to = filename_from_to(:green, start_files)
    { filename => start_files[filename].sub(from, to) }
  end

  def amber_changed_files(start_files)
    filename,from,to = filename_from_to(:amber, start_files)
    { filename => start_files[filename].sub(from, to) }
  end

  # - - - - - - - - - - - - - - - - -

  def filename_from_to(colour, start_files)
    args = options[colour.to_s]
    unless args.nil?
      return args['filename'],args['from'],args['to']
    end
    if colour == :amber
      from,to = '6 * 9','6 * 9sdsd'
      filename = filename_6_times_9(start_files, from)
    end
    if colour == :green
      from,to = '6 * 9','6 * 7'
      filename = filename_6_times_9(start_files, from)
    end
    return filename,from,to
  end

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

  def filename_6_times_9(visible_files, pattern)
    filenames = visible_files.select { |filename,content| content.include? pattern }
    if filenames == []
      failed [ "no '#{pattern}' file found" ]
    end
    if filenames.length > 1
      failed [ "multiple '#{pattern}' files " + filenames.inspect ]
    end
    filenames.keys[0]
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

  def start_point_dir
    src_dir + '/start_point'
  end

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