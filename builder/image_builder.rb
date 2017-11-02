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
    # This adds the cyber-dojo group and the 64 avatar
    # user to the created docker image.
    #
    # Question: should this extra processing happen
    #           before or after the commands inside the
    #           supplied Dockerfile?
    #
    # Answer: before.
    #
    # Reason: It allows the supplied Dockerfile to
    #         contain commands related to the users.
    #         For example, javascript-cucumber
    #         creates a node_modules dir symlink
    #         for all 64 avatar users.

    banner {
      uuid = SecureRandom.hex[0..10].downcase
      temp_image_name = "imagebuilder_temp_#{uuid}"

      Dir.mktmpdir('image_builder') do |tmp_dir|
        docker_filename = "#{tmp_dir}/Dockerfile"
        File.open(docker_filename, 'w') { |fd|
          fd.write(add_users_dockerfile(from))
        }
        assert_system [
          'docker build',
            "--file #{docker_filename}",
            "--tag #{temp_image_name}",
            tmp_dir
        ].join(space)
      end

      # Need to change FROM in dockerfile with temp_image_name.
      # An in-place change will alter the original file since
      # SRC_DIR is a volume-mount which does not create copies.
      # I'd much prefer to volume-mount read-only.
      #
      # Options?
      # 1. Can I create a mutated Dockerfile in tmp/ and use that?
      # No, because the Dockerfile must be within the build context.
      #
      # 2. Can you pipe stdin as the Dockerfile?
      # Possibly, but it is a recent feature.
      # https://github.com/docker/docker.github.io/issues/3538
      # Not even documented yet. Can I depend on that. No.
      #
      # 3. Create another Dockerfile next to it.
      # This is the least bad so I am reluctantly
      # do a read-write volume-mount of SRC_DIR in docker-compose.yml

      dockerfile = "#{dir_name}/Dockerfile"
      temp_dockerfile = dockerfile + ".#{temp_image_name}"

      sed_cmd = [
        'sed -E ',
        "'s/FROM.*$/FROM #{temp_image_name}/'",
        dockerfile,
        '>',
        temp_dockerfile
      ].join(space)

      assert_system sed_cmd
      begin
        assert_system [
          'docker build',
          '--no-cache',
          "--tag #{image_name}",
          "--file #{temp_dockerfile}",
          dir_name
        ].join(space)
      ensure
        assert_system "rm #{temp_dockerfile}"
        assert_system "docker rmi #{temp_image_name}"
      end
    }
    print_image_OS(image_name)
  end

  private

  attr_reader :dir_name

  include AssertSystem
  include Banner

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