require_relative 'all_avatars_names'
require_relative 'assert_system'
require_relative 'banner'
require_relative 'json_parse'
require_relative 'runner_service_stateful'
require_relative 'runner_service_stateless'
require 'securerandom'
require 'tmpdir'

class ImageBuilder

  def initialize(source)
    @source = source
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def build_image
    banner {
      uuid = SecureRandom.hex[0..10].downcase
      temp_image_name = "imagebuilder/tmp_#{uuid}"
      assert_system "cd #{docker_dir} && docker build --no-cache --tag #{temp_image_name} ."

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

=begin
  def create_start_point
    banner {
      script = 'cyber-dojo'
      url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
      assert_system "curl --silent -O #{url}"
      assert_system "chmod +x #{script}"
      name = 'start-point-create-check'
      system "./#{script} start-point rm #{name} &> /dev/null"
      assert_system "./#{script} start-point create #{name} --dir=#{source.dir}"
      print_to STDOUT, 'start point can be created'
    }
  end
=end

  private

  attr_reader :source

  include AssertSystem
  include Banner
  include JsonParse

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

  def start_files
    source.start_point.visible_files
  end

  def image_name
    source.image_name
  end

  def docker_dir
    source.docker_dir
  end

  def start_point_dir
    source.start_point.dir
  end

  # - - - - - - - - - - - - - - - - -

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