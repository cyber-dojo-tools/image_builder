require_relative 'all_avatars_names'
require_relative 'assert_system'
require_relative 'runner_service_statefull'
require_relative 'runner_service_stateless'
require 'securerandom'
require 'tmpdir'
require 'json'

class ImageBuilder

  def initialize(src_dir, args)
    @src_dir = src_dir
    @args = args
  end

  def build_and_test_image
    if test_framework?
      check_start_point_can_be_created
    end
    build_the_image
    print_image_info
    if test_framework?
      check_start_point_src_red_green_amber_using_runner_stateless
      check_start_point_src_red_green_amber_using_runner_statefull
    end
  end

  private

  include AssertSystem

  # - - - - - - - - - - - - - - - - -

  def check_start_point_can_be_created
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

  def build_the_image
    banner
    uuid = SecureRandom.hex[0..10].downcase
    temp_image_name = "imagebuilder/tmp_#{uuid}"
    assert_system "cd #{src_dir}/docker && docker build --tag #{temp_image_name} ."

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
  end

  # - - - - - - - - - - - - - - - - -

  def print_image_info
    banner
    index = image_name.index(':')
    if index.nil?
      name = image_name
      tag = 'latest'
    else
      name = image_name[0..index-1]
      version = image_name[index+1..-1]
    end
    spaces = '\\s+'
    assert_system "docker images | grep -E '#{name}#{spaces}#{tag}'"
    cat_etc_issue = [
      'docker run --rm -it',
      image_name,
      "sh -c 'cat /etc/issue'"
    ].join(space)
    assert_system cat_etc_issue
  end

  # - - - - - - - - - - - - - - - - -

  def make_users_dockerfile(image_name)
    cmd = "docker run --rm -it #{image_name} sh -c 'cat /etc/issue'"
    etc_issue = assert_backtick cmd
    if etc_issue.include? 'Alpine'
      return alpine_make_users_dockerfile(image_name)
    end
    if etc_issue.include? 'Ubuntu'
      return ubuntu_make_users_dockerfile(image_name)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def alpine_make_users_dockerfile(image_name)
    dockerfile = [
      "FROM #{image_name}",
      '',
      'RUN if [ ! $(getent group cyber-dojo) ]; then \\',
      "      addgroup -g #{cyber_dojo_gid} cyber-dojo; \\",
      '    fi',
    ].join("\n")
    dockerfile += "\n"
    # Alpine linux has an unneeded existing web-proxy user
    # called squid which is one of the avatars!
    dockerfile += 'RUN (deluser squid 2> /dev/null || true)'
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

  def ubuntu_make_users_dockerfile(image_name)
    dockerfile = [
      "FROM #{image_name}",
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
    banner
    if manifest['runner_choice'] == 'stateful'
      print_to STDOUT, "manifest.json ==> 'runner_choice':'stateful'"
      print_to STDOUT, 'skipping'
    else
      assert_timed_run_stateless(:red)
      assert_timed_run_stateless(:green)
      assert_timed_run_stateless(:amber)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def assert_timed_run_stateless(colour)
    runner = RunnerServiceStateless.new
    args = [image_name]
    args << kata_id
    args << 'salmon'
    args << all_files(colour)
    args << (max_seconds=10)
    took,sss = timed { runner.run(*args) }
    assert_rag(colour, sss, "dir == #{start_point_dir}")
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

  def check_start_point_src_red_green_amber_using_runner_statefull
    banner
    if manifest['runner_choice'] == 'stateless'
      print_to STDOUT, "manifest.json ==> 'runner_choice':'stateless'"
      print_to STDOUT, 'skipping'
    else
      in_kata {
        as_avatar { |name|
          # do amber last to prevent amber-test-run state
          # changes 'leaking' into green-test run
          assert_timed_run_statefull(name, :red)
          assert_timed_run_statefull(name, :green)
          assert_timed_run_statefull(name, :amber)
        }
      }
    end
  end

  # - - - - - - - - - - - - - - - - -

  def in_kata
    @runner = RunnerServiceStatefull.new
    @runner.kata_new(image_name, kata_id)
    begin
      yield
    ensure
      @runner.kata_old(image_name, kata_id)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def as_avatar
    avatar_name = 'rhino'
    @runner.avatar_new(image_name, kata_id, avatar_name, start_files)
    begin
      yield avatar_name
    ensure
      @runner.avatar_old(image_name, kata_id, avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def assert_timed_run_statefull(avatar_name, colour)
    args = [image_name]
    args << kata_id
    args << avatar_name
    args << (deleted_filenames=[])
    args << changed_files(colour)
    args << (max_seconds=10)
    took,sss = timed { @runner.run(*args) }
    assert_rag(colour, sss, "dir == #{start_point_dir}")
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
    # the .sub() call must be on the start_file and not the
    # current file (in the container) because a previous
    # stateful test-run could have edited the file.
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
    # TODO : >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # TODO: improve diagnostics of failed json parse
    # TODO : >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    options_file = start_point_dir + '/options.json'
    if File.exists? options_file
      JSON.parse(IO.read(options_file))
    else
      {}
    end
  end

  # - - - - - - - - - - - - - - - - -

  def manifest
    # TODO : >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # TODO: improve diagnostics of failed IO.read or json parse
    # TODO : >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    manifest_file = start_point_dir + '/manifest.json'
    JSON.parse(IO.read(manifest_file))
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
    # TODO : >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # TODO: improve diagnostics if cat/eval/call fails
    # TODO : >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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

  # - - - - - - - - - - - - - - - - -

  def banner
    line = '-' * 42
    title = caller_locations(1,1)[0].label
    print_to STDOUT, '', line, title
  end

  # - - - - - - - - - - - - - - - - -
  # data triple

  def from
    @args[:from]
  end

  def image_name
    @args[:image_name]
  end

  def test_framework?
    @args[:test_framework]
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

  def space
    ' '
  end

end