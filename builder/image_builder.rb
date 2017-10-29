require_relative 'all_avatars_names'
require_relative 'assert_system'
require_relative 'banner'
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
      assert_system "cd #{source.docker_dir} && docker build --no-cache --tag #{temp_image_name} ."

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

  private

  attr_reader :source

  include AssertSystem
  include Banner

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

  def image_name
    source.image_name
  end

  def space
    ' '
  end

end