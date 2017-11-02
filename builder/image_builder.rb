require_relative 'all_avatars_names'
require_relative 'assert_system'
require_relative 'banner'
require 'securerandom'
require 'tmpdir'

class ImageBuilder

  def initialize(dir_name)
    @dir_name = dir_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def build_image(image_name)
    # This builds the supplied Dockerfile and then
    # runs another generated Dockerfile to add group/users.
    # Is it better to do it the other way round?
    # It would mean the users were available in the supplied Dockerfile
    #
    # This could be necessary.
    # eg, the javascript-cucumber Dockerfile created a symlink for
    # all the avatar users.
    banner {
      uuid = SecureRandom.hex[0..10].downcase
      temp_image_name = "imagebuilder/tmp_#{uuid}"
      assert_system "cd #{dir_name} && docker build --no-cache --tag #{temp_image_name} ."

      Dir.mktmpdir('image_builder') do |tmp_dir|
        docker_filename = "#{tmp_dir}/Dockerfile"
        File.open(docker_filename, 'w') { |fd|
          fd.write(add_users_dockerfile(temp_image_name))
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
    print_image_OS(image_name)
  end

  private

  attr_reader :dir_name

  include AssertSystem
  include Banner

  # - - - - - - - - - - - - - - - - -

  def add_users_dockerfile(temp_image_name)
    os = get_os(temp_image_name)
    lined "FROM #{temp_image_name}",
          '',
          add_cyberdojo_group_command(os),
          remove_alpine_squid_webproxy_user_command(os),
          add_avatar_users_command(os)
  end

  # - - - - - - - - - - - - - - - - -

  def add_cyberdojo_group_command(os)
    # Must be idempotent because Dockerfile could be based
    # on a docker-image which already has been through this.
    case os
    when :Alpine
      sh_splice "RUN if [ ! $(getent group #{group_name}) ]; then",
                "      addgroup -g #{group_id} #{group_name};",
                '    fi'
    when :Ubuntu
      sh_splice "RUN if [ ! $(getent group #{group_name}) ]; then",
                "      addgroup --gid #{group_id} #{group_name};",
                '    fi'
    end
  end

  def group_name
    'cyber-dojo'
  end

  def group_id
    5000
  end

  # - - - - - - - - - - - - - - - - -

  def remove_alpine_squid_webproxy_user_command(os)
    # Alpine linux has an unneeded existing web-proxy
    # user called squid which is one of the avatars!
    # Be very careful about removing this squid user because
    # we could be running FROM a docker-image which has already
    # been through the image-builder processing, in which case
    # it will already have _our_ squid user.
    grep_passwd = 'cat /etc/passwd | grep -q'
    squid_id = user_id('squid')
    squid_exists = "(#{grep_passwd} squid:x:)"
    not_our_squid = "!(#{grep_passwd} squid:x:#{squid_id}:#{group_id})"
    os == :Alpine ?
      "RUN (#{squid_exists} && #{not_our_squid} && (deluser squid)) || true" :
      ''
  end

  # - - - - - - - - - - - - - - - - -

  def add_avatar_users_command(os)
    # Must be idempotent because Dockerfile could be based
    # on a docker-image which already has been through this.
    add_avatar_users_command =
      all_avatars_names.collect { |name|
        add_avatar_user_command(os, name)
      }.join(' && ')
    # Fail fast if avatar users have already been added
    zebra_uid = user_id('zebra')
    sh_splice "RUN (cat /etc/passwd | grep -q zebra:x:#{zebra_uid}) ||",
              "    (#{add_avatar_users_command})"
  end

  def add_avatar_user_command(os, name)
    case os
    when :Alpine
      spaced '(',
        'adduser',
        '-D',               # no password
        "-G #{group_name}",
        "-h #{home_dir(name)}",
        "-s '/bin/sh'",     # shell
        "-u #{user_id(name)}",
        name,
      ')'
    when :Ubuntu
      spaced '(',
        'adduser',
        '--disabled-password',
        '--gecos ""', # don't ask for details
        "--ingroup #{group_name}",
        "--home #{home_dir(name)}",
        "--uid #{user_id(name)}",
        name,
      ')'
    end
  end

  def home_dir(avatar_name)
    "/home/#{avatar_name}"
  end

  def user_id(avatar_name)
    40000 + all_avatars_names.index(avatar_name)
  end

  include AllAvatarsNames

  # - - - - - - - - - - - - - - - - -

  def print_image_OS(image_name)
    banner {
      puts get_os(image_name).to_s + " image built OK"
    }
  end

  def get_os(image_name)
    cmd = "docker run --rm -it #{image_name} sh -c 'cat /etc/issue'"
    etc_issue = assert_backtick cmd
    if etc_issue.include? 'Alpine'
      return :Alpine
    end
    if etc_issue.include? 'Ubuntu'
      return :Ubuntu
    end
  end

  # - - - - - - - - - - - - - - - - -

  def sh_splice(*lines)
    lines.join(space + '\\' + "\n")
  end

  def lined(*lines)
    lines.join("\n")
  end

  def spaced(*words)
    words.join(space)
  end

  def space
    ' '
  end

end