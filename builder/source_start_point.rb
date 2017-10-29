require_relative 'assert_system'
require_relative 'banner'
require_relative 'failed'
require_relative 'json_parse'
require_relative 'print_to'
require_relative 'runner_service_stateful'
require_relative 'runner_service_stateless'

class SourceStartPoint

  def initialize(src_dir)
    @src_dir = src_dir
  end

  def dir?
    Dir.exist? dir
  end

  def manifest_filename?
    File.exist? manifest_filename
  end

  def manifest_filename
    dir + '/manifest.json'
  end

  def image_name
    manifest['image_name']
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
      assert_system "./#{script} start-point create #{name} --dir=#{@src_dir}"
      print_to STDOUT, 'start point can be created'
    }
  end

  # - - - - - - - - - - - - - - - - -

  def test_red_amber_green
    case runner_choice
    when 'stateless'
      check_red_green_amber_using_runner_stateless
    when 'stateful'
      check_red_green_amber_using_runner_stateful
    end
  end

  private

  include AssertSystem
  include Banner
  include Failed
  include JsonParse
  include PrintTo

  def dir
    @src_dir + '/start_point'
  end

  def manifest
    @manifest ||= read_manifest
  end

  def read_manifest
    json_parse(manifest_filename)
  end

  def runner_choice
    manifest['runner_choice']
  end

  # - - - - - - - - - - - - - - - - -

  def start_files
    visible_files
  end

  def visible_files
    # start-point has already been verified
    files = {}
    manifest['visible_filenames'].each do |filename|
      files[filename] = IO.read(dir + '/' + filename)
    end
    files
  end

  # - - - - - - - - - - - - - - - - -

  def check_red_green_amber_using_runner_stateless
    banner {
      assert_timed_run_stateless(:red)
      assert_timed_run_stateless(:green)
      assert_timed_run_stateless(:amber)
    }
  end

  # - - - - - - - - - - - - - - - - -

  def assert_timed_run_stateless(colour)
    runner = RunnerServiceStateless.new
    args = [image_name]
    args << kata_id
    args << avatar_name
    args << all_files(colour)
    args << (max_seconds=10)
    took,sss = timed { runner.run(*args) }
    assert_rag(colour, sss)
    print_to STDOUT, "#{colour}: OK (~#{took} seconds)"
  end

  # - - - - - - - - - - - - - - - - -

  def all_files(colour)
    files = start_files
    if colour != :red
      filename,content = edited_file(colour)
      files[filename] = content
    end
    files
  end

  # - - - - - - - - - - - - - - - - -

  def check_red_green_amber_using_runner_stateful
    banner {
      in_kata {
        as_avatar {
          # the tar-pipe in the runner's stores file date-stamps
          # to second granularity, the microseconds are always zero.
          # This matters in a stateless runner since the cyber-dojo.sh
          # file could be executing make (for example).
          # This is very unlikely to matter for a browser test-event
          # but it is quite likely to matter here since
          # we are not doing a full browser round-trip we are calling
          # directly into the runner service, and this is a stateful
          # runner which is quite likely to be optimized for speed.
          # Hence the sleeps.
          assert_timed_run_stateful(:red)
          sleep(1.5)
          assert_timed_run_stateful(:green)
          sleep(1.5)
          assert_timed_run_stateful(:amber)
          # do amber last to prevent amber-test-run state
          # changes 'leaking' into green-test run
        }
      }
    }
  end

  # - - - - - - - - - - - - - - - - -

  def in_kata
    @runner = RunnerServiceStateful.new
    @runner.kata_new(image_name, kata_id)
    begin
      yield
    ensure
      @runner.kata_old(image_name, kata_id)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def as_avatar
    @runner.avatar_new(image_name, kata_id, avatar_name, start_files)
    begin
      yield
    ensure
      @runner.avatar_old(image_name, kata_id, avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def assert_timed_run_stateful(colour)
    args = [image_name]
    args << kata_id
    args << avatar_name
    args << (deleted_filenames=[])
    args << changed_files(colour)
    args << (max_seconds=10)
    took,sss = timed { @runner.run(*args) }
    assert_rag(colour, sss)
    print_to STDOUT, "#{colour}: OK (~#{took} seconds)"
  end

  # - - - - - - - - - - - - - - - - -

  def changed_files(colour)
    if colour == :red
      {}
    else
      filename,content = edited_file(colour)
      { filename => content }
    end
  end

  # - - - - - - - - - - - - - - - - -

  def edited_file(colour)
    args = options[colour.to_s]
    if !args.nil?
      filename = args['filename']
      was = args['from']
      now = args['to']
    elsif colour == :amber
      was = '6 * 9'
      now = '6 * 9sdsd'
      filename = filename_6_times_9(was)
    elsif colour == :green
      was = '6 * 9'
      now = '6 * 7'
      filename = filename_6_times_9(was)
    end
    # the .sub() call must be on the start_file and not the
    # current file (in the container) because a previous
    # stateful test-run could have edited the file.
    return filename, start_files[filename].sub(was, now)
  end

  # - - - - - - - - - - - - - - - - -

  def filename_6_times_9(text)
    filenames = start_files.select { |_,content| content.include? text }
    if filenames == {}
      failed [ "no '#{text}' file found" ]
    end
    if filenames.length > 1
      failed [ "multiple '#{text}' files " + filenames.inspect ]
    end
    filenames.keys[0]
  end

  # - - - - - - - - - - - - - - - - -

  def options
    filename = dir + '/options.json'
    File.exist?(filename) ? json_parse(filename) : {}
  end

  # - - - - - - - - - - - - - - - - -

  def timed
    started = Time.now
    result = yield
    stopped = Time.now
    took = (stopped - started).round(2)
    return took,result
  end

  # - - - - - - - - - - - - - - - - -

  def assert_rag(expected_colour, sss)
    actual_colour = sss['colour']
    unless expected_colour.to_s == actual_colour
      failed [
        "expected_colour == #{expected_colour}",
        "  actual_colour == #{actual_colour}",
        '',
        "arguments passed to #{rag_filename} (inside #{image_name}):",
        "  status == #{sss['status']}",
        "  stdout == #{sss['stdout']}",
        "  stderr == #{sss['stderr']}",
      ]
    end
  end

  # - - - - - - - - - - - - - - - - -

  def kata_id
    '6F4F4E4759'
  end

  def avatar_name
    'rhino'
  end

end
