require_relative 'banner'
require_relative 'failed'
require_relative 'json_parse'
require_relative 'runner_service'

class StartPointDir

  def initialize(dir_name)
    @dir_name = dir_name
  end

  # - - - - - - - - - - - - - - - - -

  def image_name
    manifest['image_name']
  end

  # - - - - - - - - - - - - - - - - -

  def test_run
    # TODO: check the image_name has the
    # 64 avatars users inside it.
    # TODO: check the image_name has the
    # #{rag_filename} inside it.
    hhg = options? || filename_6_times_9?
    # TODO: If being run on a cyber-dojo-langauges
    # repo then check it _HAS_ got 6*9 content
    # Is it best to do this in Travis run?
    # Ensure start-point stuff goes into its own org.
    if hhg
      test_6_times_9_red_amber_green
    else
      test_any_colour
    end
  end

  private

  attr_reader :dir_name

  include Banner
  include Failed
  include JsonParse

  def test_any_colour
    banner {
      puts 'TODO'
    }
  end

  # - - - - - - - - - - - - - - - - -

  def test_6_times_9_red_amber_green
    case runner_choice
    when 'stateless'
      @runner = RunnerService.new('runner-stateless', '4597')
    when 'stateful'
      @runner = RunnerService.new('runner_stateful', '4557')
    #when 'processful'
      #@runner = RunnerService.new('runner_processful', '4547')
    end
    check_red_amber_green
  end

  # - - - - - - - - - - - - - - - - -

  def check_red_amber_green
    banner {
      in_kata {
        as_avatar {
          puts "# using #{@runner.hostname}, max_seconds=#{max_seconds}"
          assert_timed_run(:red)
          assert_timed_run(:amber)
          assert_timed_run(:green)
        }
      }
    }
  end

  # - - - - - - - - - - - - - - - - -

  def assert_timed_run(colour)
    args = [image_name]
    args << kata_id
    args << avatar_name
    args << (new_files = {})
    args << (deleted_files = {})
    args << unchanged_files(colour)
    args << changed_files(colour)
    args << max_seconds
    took,sss = timed { @runner.run_cyber_dojo_sh(*args) }
    assert_rag(colour, sss)
    puts "# #{colour}: OK (~#{took} seconds)"
  end

  # - - - - - - - - - - - - - - - - -

  def in_kata
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

  def unchanged_files(colour)
    files = start_files
    if colour != :red
      filename,_ = edited_file(colour)
      files.delete(filename)
    end
    files
  end

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
    from = args['from']
    to = args['to']
    filename = args['filename'] || filename_6_times_9(from)

    src = start_files[filename]
    if src.nil?
      failed [ "'#{filename}' is not a visible file" ]
    end

    unless src.include?(from)
      failed [ "'#{filename}' does not include '#{from}'"]
    end

    # the .sub() call must be on the start_files and not the
    # current file (in the container) because a previous
    # stateful test-run could have edited the file.
    return filename, src.sub(from, to)
  end

  # - - - - - - - - - - - - - - - - -

  def options?
    File.exist? options_filename
  end

  def options
    options? ? json_parse(options_filename) : {
      'amber' => from_to('6 * 9', '6 * 9sdsd'),
      'green' => from_to('6 * 9', '6 * 7')
    }
  end

  def options_filename
    dir_name + '/options.json'
  end

  def from_to(from, to)
    { 'from' => from, 'to' => to }
  end

  def filename_6_times_9?
    filenames = start_files.select { |_,content| content.include? '6 * 9' }
    filenames.size == 1
  end

  def filename_6_times_9(text)
    filenames = start_files.select { |_,content| content.include? text }
    if filenames == {}
      failed [ "no '#{text}' file found" ]
    end
    if filenames.size > 1
      failed [ "multiple '#{text}' files " + filenames.inspect ]
    end
    filenames.keys[0]
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

  def start_files
    files = {}
    manifest['visible_filenames'].each do |filename|
      files[filename] = IO.read(dir_name + '/' + filename)
    end
    files
  end

  def runner_choice
    manifest['runner_choice']
  end

  def max_seconds
    manifest['max_seconds'] || 10
  end

  def manifest
    @manifest ||= read_manifest
  end

  def read_manifest
    json_parse(dir_name + '/manifest.json')
  end

  # - - - - - - - - - - - - - - - - -

  def rag_filename
    '/usr/local/bin/red_amber_green.rb'
  end

  # - - - - - - - - - - - - - - - - -

  def kata_id
    '6F4F4E4759'
  end

  def avatar_name
    'squid'
  end

end
