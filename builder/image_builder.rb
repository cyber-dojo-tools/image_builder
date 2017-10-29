require_relative 'all_avatars_names'
require_relative 'assert_system'
require_relative 'banner'
require_relative 'source'
require_relative 'json_parse'
require_relative 'print_to'
require_relative 'runner_service_stateful'
require_relative 'runner_service_stateless'
require 'securerandom'
require 'tmpdir'

class ImageBuilder

  def initialize
    @src_dir = ENV['SRC_DIR']
    @image_name = Source.new(@src_dir).image_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def build_image
    banner {
      uuid = SecureRandom.hex[0..10].downcase
      temp_image_name = "imagebuilder/tmp_#{uuid}"
      assert_system "cd #{src_dir}/docker && docker build --no-cache --tag #{temp_image_name} ."

      Dir.mktmpdir('image_builder') do |tmp_dir|
        docker_filename = "#{tmp_dir}/Dockerfile"
        File.open(docker_filename, 'w') { |fd|
          fd.write(make_users_dockerfile(temp_image_name))
        }
        assert_system [
          'docker build',
            "--file #{docker_filename}",
            "--tag #{image_name}",
            tmp_dir
        ].join(' ')
      end

      assert_system "docker rmi #{temp_image_name}"
    }
    print_image_OS
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def create_start_point
    banner {
      script = 'cyber-dojo'
      url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
      assert_system "curl --silent -O #{url}"
      assert_system "chmod +x #{script}"
      name = 'start-point-create-check'
      system "./#{script} start-point rm #{name} &> /dev/null"
      assert_system "./#{script} start-point create #{name} --dir=#{src_dir}"
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def test_red_amber_green
    case manifest['runner_choice']
    when 'stateless'
      check_start_point_src_red_green_amber_using_runner_stateless
    when 'stateful'
      check_start_point_src_red_green_amber_using_runner_stateful
    end
  end

  private

  attr_reader :image_name

  include AssertSystem
  include Banner
  include JsonParse
  include PrintTo

  # - - - - - - - - - - - - - - - - -

  def print_image_OS
    banner {
      index = image_name.index(':')
      if index.nil?
        name = image_name
        tag = 'latest'
      else
        name = image_name[0..index-1]
        version = image_name[index+1..-1]
      end
      spaces = '\\s+'
      assert_backtick "docker images | grep -E '#{name}#{spaces}#{tag}'"
      cat_etc_issue = [
        'docker run --rm -it',
        image_name,
        "sh -c 'cat /etc/issue'",
        '| head -1'
      ].join(space)
      assert_system cat_etc_issue
    }
  end

  # - - - - - - - - - - - - - - - - -

  def make_users_dockerfile(temp_image_name)
    cmd = "docker run --rm -it #{temp_image_name} sh -c 'cat /etc/issue'"
    etc_issue = assert_backtick cmd
    if etc_issue.include? 'Alpine'
      return alpine_make_users_dockerfile(temp_image_name)
    end
    if etc_issue.include? 'Ubuntu'
      return ubuntu_make_users_dockerfile(temp_image_name)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def alpine_make_users_dockerfile(temp_image_name)
    dockerfile = [
      "FROM #{temp_image_name}",
      '',
      'RUN if [ ! $(getent group cyber-dojo) ]; then \\',
      "      addgroup -g #{cyber_dojo_gid} cyber-dojo; \\",
      '    fi',
    ].join("\n")
    dockerfile += "\n"

    add_user_commands = []
    all_avatars_names.each do |avatar_name|
      uid = user_id(avatar_name)
      add_user_command = [
        '(',
        'adduser',
        '-D',                      # no password
        '-G cyber-dojo',           # group
        "-h /home/#{avatar_name}", # home-dir
        "-s '/bin/sh'",            # shell
        "-u #{uid}",
        avatar_name,
        ')'
      ].join(space)
      add_user_commands << add_user_command
    end
    # Fail fast if avatar users have already been added
    dockerfile += 'RUN (cat /etc/passwd | grep -q zebra:x:40063) || '
    dockerfile + "(#{add_user_commands.join(' && ')})"
  end

  # - - - - - - - - - - - - - - - - -

  def ubuntu_make_users_dockerfile(temp_image_name)
    dockerfile = [
      "FROM #{temp_image_name}",
      '',
      'RUN if [ ! $(getent group cyber-dojo) ]; then \\',
      "      addgroup --gid #{cyber_dojo_gid} cyber-dojo; \\",
      '    fi',
    ].join("\n")
    dockerfile += "\n"
    add_user_commands = []
    all_avatars_names.each do |avatar_name|
      uid = user_id(avatar_name)
      add_user_command = [
        '(',
        'adduser',
        '--disabled-password',
        '--gecos ""', # don't ask for details
        '--ingroup cyber-dojo',
        "--home /home/#{avatar_name}",
        "--uid #{uid}",
        avatar_name,
        ')'
      ].join(space)
      add_user_commands << add_user_command
    end
    # Fail fast if avatar users have already been added
    dockerfile += 'RUN (cat /etc/passwd | grep -q zebra:x:40063) || '
    dockerfile + "     (#{add_user_commands.join(' && ')})"
  end

  # - - - - - - - - - - - - - - - - -

  def cyber_dojo_gid
    5000
  end

  def user_id(avatar_name)
    40000 + all_avatars_names.index(avatar_name)
  end

  include AllAvatarsNames

  # - - - - - - - - - - - - - - - - -

  def check_start_point_src_red_green_amber_using_runner_stateless
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

  def check_start_point_src_red_green_amber_using_runner_stateful
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
      yield avatar_name
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
    return filename, start_files[filename].sub(was,now)
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
    filename = start_point_dir + '/options.json'
    if File.exists? filename
      content = IO.read(filename)
      json_parse(filename, content)
    else
      {}
    end
  end

  # - - - - - - - - - - - - - - - - -

  def manifest
    filename = start_point_dir + '/manifest.json'
    content = IO.read(filename)
    json_parse(filename, content)
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

  # - - - - - - - - - - - - - - - - -

  def start_point_dir
    src_dir + '/start_point'
  end

  def src_dir
    @src_dir
  end

  def rag_filename
    '/usr/local/bin/red_amber_green.rb'
  end

  def kata_id
    '6F4F4E4759'
  end

  def avatar_name
    'rhino'
  end

  def space
    ' '
  end

end