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

  def build_image(from, image_name)
    # Attempt to create a docker image named image_name
    # from the Dockerfile in dir_name, except that it
    # inserts RUN commands to
    #   o) adds a group called cyber-dojo
    #   o) adds a user for each of the 64 avatars
    #
    # Question: Should these extra RUN commands happen
    #           before or after the commands inside the
    #           Dockerfile?
    # Answer: Before.
    # Reason: It allows the supplied Dockerfile to
    #         contain commands related to the users.
    #         For example, javascript-cucumber
    #         creates a node_modules dir symlink
    #         for all 64 avatar users.
    banner {
      temp_image_name = "imagebuilder_temp_#{uuid}"
      add_users(from, temp_image_name)
      replace_from(temp_image_name, image_name)
    }
    print_image_OS(image_name)
    show_avatar_users(image_name)
  end

  private

  attr_reader :dir_name

  include AssertSystem
  include Banner

  # - - - - - - - - - - - - - - - - -

  def add_users(from, temp_image_name)
    Dir.mktmpdir('image_builder') do |tmp_dir|
      docker_filename = "#{tmp_dir}/Dockerfile"
      File.open(docker_filename, 'w') { |fd|
        fd.write(add_users_dockerfile(from))
      }
      assert_system [
        'docker build',
          '--no-cache',
          "--file #{docker_filename}",
          "--tag #{temp_image_name}",
          tmp_dir
      ].join(space)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def replace_from(temp_image_name, image_name)
    # Need to change FROM in Dockerfile to temp_image_name.
    # An in-place change would alter the original file if
    # SRC_DIR was a read-write volume-mount. I'd much prefer
    # to volume-mount SRC_DIR read-only. Options?
    # Can you create a mutated Dockerfile in tmp/ and use that?
    # Not if you name the mutated Dockerfile in the [docker build]
    # command it won't be within the build context.
    # But you can get the Dockerfile from a stdin-pipe.
    # See https://github.com/docker/docker.github.io/issues/3538
    # It's not documented yet. And I can rely on it since this
    # [docker build] command is itself running inside the
    # image_builder docker image!

    Dir.mktmpdir('image_builder') do |tmp_dir|
      filename = "#{dir_name}/Dockerfile"
      # Logically, here I should be able to run sed directly on
      # [filename] and then pipe the result into [docker build].
      # However, sometimes you get an _old_ version of the file.
      # There appears to be a docker-related caching error on
      # the src_dir_container. Hence the copy and the uuid.

      content = IO.read(filename)
      tmp_dockerfile = "#{tmp_dir}/Dockerfile_#{uuid}"
      IO.write(tmp_dockerfile, content)
      assert_system [
        'sed -E',
        "'s/^FROM.*$/FROM #{temp_image_name}/'",
        tmp_dockerfile,
        '|',
        'docker build',
        '--no-cache',
        "--tag #{image_name}",
        '--file -', # Dockerfile from stdin
        dir_name
      ].join(space)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def add_users_dockerfile(from)
    os = get_os(from)
    lined "FROM #{from}",
          '',
          add_cyberdojo_group_command(os),
          remove_alpine_squid_webproxy_user_command(os),
          add_avatar_users_command(os)
  end

  # - - - - - - - - - - - - - - - - -

  def add_cyberdojo_group_command(os)
    # Must be idempotent because Dockerfile could be
    # based on a docker-image which already has been
    # through image-builder processing
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
    # Alpine linux has an (unneeded by me) existing web-proxy
    # user called squid which is one of the avatars!
    # Being very careful about removing this squid user because
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
    # Must be idempotent because Dockerfile could be
    # based on a docker-image which already has been
    # through image-builder processing
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
      puts '# ' + get_os(image_name).to_s + " image built OK"
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

  def show_avatar_users(image_name)
    banner {
      %w( alligator squid zebra ).each do |avatar|
        uid = get_uid(image_name, avatar)
        gid = get_gid(image_name, avatar)
        puts "# #{uid}:#{gid} == uid:gid(#{avatar})"
      end
    }
  end

  def get_uid(image_name, avatar_name)
    get_id(image_name, avatar_name, 'u')
  end

  def get_gid(image_name, avatar_name)
    get_id(image_name, avatar_name, 'g')
  end

  def get_id(image_name, avatar_name, option)
    id_cmd = [
      'docker run',
      '--rm',
      '-it',
      image_name,
      "id -#{option} #{avatar_name}"
    ].join(' ')
    assert_backtick(id_cmd).strip
  end

  # - - - - - - - - - - - - - - - - -

  def uuid
    SecureRandom.hex[0..10].downcase
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