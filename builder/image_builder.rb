require_relative 'runner_service_statefull'
require_relative 'runner_service_stateless'
require 'json'

class ImageBuilder

  def initialize(key, args)
    @key = key
    @image_name = args['image_name']
    @test_framework = args['test_framework']
    @cloned = false
  end

  attr_reader :image_name

  def build_and_test_image
    banner('=', src_dir)
    build_the_image
    if test_framework?
      check_images_red_amber_green_lambda_file
      check_start_point_can_be_created
      check_start_point_src_red_green_amber_using_runner_stateless
      check_start_point_src_red_green_amber_using_runner_statefull
    end
  end

  private

  def build_the_image
    banner
    assert_system "cd #{src_dir}/docker && docker build --tag #{image_name} ."
  end

  # - - - - - - - - - - - - - - - - -

  def test_framework?
    @test_framework
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
    if on_travis?
      url = 'https://github.com/cyber-dojo-languages/' + @key
      assert_system "./#{script} start-point create #{name} --git=#{url}"
    else
      assert_system "./#{script} start-point create #{name} --dir=#{src_dir}"
    end
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_red_green_amber_using_runner_stateless
    banner
    took,sss = timed_run_stateless(red_files)
    assert_rag(:red, sss, "dir == #{start_point_dir}")
    puts "red: OK (~#{took} seconds)"
    took,sss = timed_run_stateless(green_files)
    assert_rag(:green, sss, "dir == #{start_point_dir}")
    puts "green: OK (~#{took} seconds)"
    took,sss = timed_run_stateless(amber_files)
    assert_rag(:amber, sss, "dir == #{start_point_dir}")
    puts "amber: OK (~#{took} seconds)"
  end

  def red_files
    start_point_visible_files
  end

  def green_files
    from = '6 * 9'
    to = '6 * 7'
    visible_files = red_files
    filename = filename_6_times_9(visible_files, from)
    content = visible_files[filename]
    visible_files[filename] = content.sub(from, to)
    visible_files
  end

  def amber_files
    from = '6 * 9'
    to = '6 * 9sdsd'
    visible_files = red_files
    filename = filename_6_times_9(visible_files, from)
    content = visible_files[filename]
    visible_files[filename] = content.sub(from, to)
    visible_files
  end

  def timed_run_stateless(visible_files)
    runner = RunnerServiceStateless.new
    t1 = Time.now
    sss = runner.run(image_name, kata_id, avatar_name, visible_files, max_seconds)
    t2 = Time.now
    took = ((t2 - t1) / 3).round(2)
    return took,sss
  end

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_red_green_amber_using_runner_statefull
    banner
    runner = RunnerServiceStatefull.new
    visible_files = start_point_visible_files
    runner.kata_new(image_name, kata_id)
    runner.avatar_new(image_name, kata_id, avatar_name, visible_files)
    begin
      # red
      took, sss = timed_run_statefull(runner, changed_files={})
      assert_rag(:red, sss, "dir == #{start_point_dir}")
      puts "red: OK (~#{took} seconds)"
      # green
      pattern = '6 * 9'
      filename = filename_6_times_9(visible_files, pattern)
      content = visible_files[filename]
      changed_files = { filename => content.sub(pattern, '6 * 7') }
      took, sss = timed_run_statefull(runner, changed_files)
      assert_rag(:green, sss, "dir == #{start_point_dir}")
      puts "green: OK (~#{took} seconds)"
      changed_files = { filename => content.sub(pattern, '6 * 9sdsd') }
      took, sss = timed_run_statefull(runner, changed_files)
      assert_rag(:amber, sss, "dir == #{start_point_dir}")
      puts "amber: OK (~#{took} seconds)"
    ensure
      runner.avatar_old(image_name, kata_id, avatar_name)
      runner.kata_old(image_name, kata_id)
    end
  end

  def timed_run_statefull(runner, changed_files)
    t1 = Time.now
    sss = runner.run(image_name, kata_id, avatar_name, deleted_filenames=[], changed_files, max_seconds)
    t2 = Time.now
    took = ((t2 - t1) / 3).round(2)
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

  def on_travis?
    ENV['TRAVIS'] == 'true'
  end

  def src_dir
    if ENV['TRAVIS'] != 'true'
      @key # running locally
    else
      unless @cloned
        url = 'https://github.com/cyber-dojo-languages/' + @key
        assert_system "cd /tmp && mkdir -p cyber-dojo"
        assert_system "cd /tmp/cyber-dojo && git clone #{url}"
        @cloned = true
      end
      '/tmp/cyber-dojo/' + @key
    end
  end

  # - - - - - - - - - - - - - - - - -

  def banner(ch = '-', title = caller_locations(1,1)[0].label)
    line = ch * 42
    print_to([ '', line, title, ], STDOUT)
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

  def avatar_name
    'salmon'
  end

  def max_seconds
    10
  end

end