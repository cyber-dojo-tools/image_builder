require_relative 'assert_system'
require_relative 'banner'
require_relative 'failed'
require 'securerandom'
require 'tmpdir'

class ImageBuilder

  def initialize(dir_name)
    @dir_name = dir_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def build_image(from, image_name)
    # Attempts to create a docker image named image_name
    # from the Dockerfile in dir_name, except that it
    # top-inserts commands to fulfil runner requirements.
    os = checked_image_os(from)
    banner {
      temp_image_name = "imagebuilder_temp_#{uuid}"
      build_intermediate_image(from, os, temp_image_name)
      begin
        build_final_image(temp_image_name, image_name)
        puts "# #{os} based image built OK"
      ensure
        assert_system "docker rmi #{temp_image_name}"
      end
    }
    show_sandbox_user(image_name)
  end

  private

  attr_reader :dir_name

  include AssertSystem
  include Banner
  include Failed

  # - - - - - - - - - - - - - - - - -

  def build_intermediate_image(from, os, temp_image_name)
    Dir.mktmpdir('image_builder') do |tmp_dir|
      File.open("#{tmp_dir}/#{create_text_file_tar_list_filename}", 'w') { |fd|
        fd.write(create_tar_list_script)
      }
      docker_filename = "#{tmp_dir}/Dockerfile"
      File.open(docker_filename, 'w') { |fd|
        fd.write(intermediate_dockerfile(from, os))
      }
      assert_system [
        'docker build',
          "--file #{docker_filename}",
          "--tag #{temp_image_name}",
          tmp_dir
      ].join(space)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def create_text_file_tar_list_filename
    'create_text_file_tar_list.sh'
  end

  # - - - - - - - - - - - - - - - - -

  def create_tar_list_script
    # runner's rely on this script being inside the
    # test-framework image at /usr/local/bin/create_tar_list.sh
    # which they call to tar-pipe files out of the container
    <<~SHELL.strip
      # o) ensure there is no tar-list file at the start
      # o) for all files in avatars sandbox dir (recursively)
      #    if the file is not a binary file
      #    then append the filename to the tar-list
      rm -f ${TAR_LIST} | true
      find ${CYBER_DOJO_SANDBOX} -type f -exec sh -c '
        for filename do
          if file --mime-encoding ${filename} | grep -qv "${filename}:\\sbinary"; then
            echo ${filename} >> ${TAR_LIST}
          fi
          if [ $(stat -c%s "${filename}") -eq 0 ]; then
            # handle empty files which file reports are binary
            echo ${filename} >> ${TAR_LIST}
          fi
          if [ $(stat -c%s "${filename}") -eq 1 ]; then
            # handle file with one char which file reports are binary!
            echo ${filename} >> ${TAR_LIST}
          fi
        done' sh {} +
    SHELL
  end

  # - - - - - - - - - - - - - - - - -

  def intermediate_dockerfile(from, os)
    filename = create_text_file_tar_list_filename
    # These commands must happen before the commands inside the
    # real Dockerfile so the real Dockerfile can contain commands
    # related to the users. For example, javascript-cucumber creates a
    # node_modules dir symlink for all 64 avatar users.
    "FROM #{from}" + "\n" +
    RUN_add_sandbox_group(os) + "\n" +
    RUN_add_sandbox_user(os) + "\n" +
    RUN_install_runner_dependencies(os) + "\n" +
    "COPY #{filename} /usr/local/bin" + "\n" +
    "RUN chmod +x /usr/local/bin/#{filename}"
  end

  # - - - - - - - - - - - - - - - - -

  def build_final_image(temp_image_name, image_name)
    # Need to change FROM in Dockerfile to temp_image_name.
    # An in-place change would alter the original file if
    # SRC_DIR was a read-write volume-mount. I'd much prefer
    # to volume-mount SRC_DIR read-only. Options?
    # Can you create a mutated Dockerfile in tmp/ and use that?
    # Not if you name the mutated Dockerfile in the [docker build]
    # command since it won't be within the build context.
    # But you can get the Dockerfile from a stdin-pipe.
    # See https://github.com/docker/docker.github.io/issues/3538
    # It's not documented yet. And I can rely on it since this
    # [docker build] command is itself running inside the
    # image_builder docker image!
    Dir.mktmpdir('image_builder') do |tmp_dir|
      filename = "#{dir_name}/Dockerfile"
      # Logically, here I should be able to run sed directly on
      # [filename] and then pipe the result into [docker build].
      # However, sometimes you get an _old_ version of the file!
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
        "--tag #{image_name}",
        '--file -', # Dockerfile from stdin
        dir_name
      ].join(space)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def RUN_install_runner_dependencies(os)
    # Adds packages/dirs required by the runner service.
    lined RUN_install_coreutils(os),
          RUN_install_bash(os),
          RUN_install_tar(os),
          RUN_install_file(os),
          RUN_install_sudo(os)
  end

  # - - - - - - - - - - - - - - - - -

  def RUN_install_coreutils(os)
    # On default Alpine date-time file-stamps are stored
    # to a one second granularity. In other words, the
    # microseconds are always zero. Viz
    #   $ docker run --rm -it alpine:latest sh
    #   > echo 'hello' > hello.txt
    #   > stat -c "%y%" hello.txt
    #     2017-11-09 20:09:22.000000000
    #
    # This matters in a stateful runner since the
    # cyber-dojo.sh file could be executing an incremental
    # make (for example). Viz
    #   $ docker run --rm -it alpine:latest sh
    #   > apk add --update coreutils
    #   > echo 'hello' > hello.txt
    #   > stat -c "%y%" hello.txt
    #     2017-11-09 20:11:09.376824357 +0000
    apk_install(os, 'coreutils')
  end

  # - - - - - - - - - - - - - - - - -

  def RUN_install_bash(os)
    # On Alpine install bash so runners can reply on
    # all containers having bash.
    apk_install(os, 'bash')
  end

  # - - - - - - - - - - - - - - - - -

  def RUN_install_tar(os)
    # Each runner docker-tar-pipes text files into the
    # test-framework container. The runner's tar-pipe uses
    # the --touch option to set the date-time stamps
    # on the files once they have been copied _into_ the
    # test-framework container. The default Alpine tar
    # does not support the --touch option hence the update.
    apk_install(os, 'tar')
  end

  # - - - - - - - - - - - - - - - - -

  def RUN_install_file(os)
    # Each runner docker-tar-pipes text files out of the
    # test-framework container. It does this using
    # $ file --mime-encoding ${filename}
    case os
    when :Alpine
      apk_install(os, 'file')
    when :Debian,:Ubuntu
      apt_get_install(os, 'file')
    end
  end

  # - - - - - - - - - - - - - - - - -

  def RUN_install_sudo(os)
    case  os
    when :Alpine
      apk_install(os, 'sudo')
    when :Debian,:Ubuntu
      apt_get_install(os, 'sudo')
    end
  end

  # - - - - - - - - - - - - - - - - -

  def apk_install(os, package)
    command = "RUN apk add --update #{package}"
    os == :Alpine ? command : ''
  end

  # - - - - - - - - - - - - - - - - -

  def apt_get_install(os, package)
    command = "RUN apt-get update && apt-get install --yes #{package}"
    os != :Alpine ? command : ''
  end

  # - - - - - - - - - - - - - - - - -

  def RUN_add_sandbox_group(os)
    # Must be idempotent because Dockerfile could be
    # based on a docker-image which _already_ has been
    # through image-builder processing
    name = 'sandbox'
    gid = '51966'
    option = case os
    when :Alpine         then '-g'
    when :Debian,:Ubuntu then '--gid'
    end
    group_exists = "getent group #{name}"
    add_group = "addgroup #{option} #{gid} #{name}"
    "RUN (#{group_exists}) || (#{add_group})"
  end

  # - - - - - - - - - - - - - - - - -

  def RUN_add_sandbox_user(os)
    # Must be idempotent because Dockerfile could be
    # based on a docker-image which _already_ has been
    # through image-builder processing
    home_dir = '/home/sandbox'
    name = 'sandbox'
    shell = '/bin/bash'
    uid = '41966'
    options = case os
    when :Alpine then [
        '-D',                # --disabled-password
        '-g ""',             # --gecos
        "-h #{home_dir}",    # --home
        "-G #{name}",        # --ingroup
        "-s #{shell}",       # --shell
        "-u #{uid}"          # --uid
      ].join(' ')
    when :Ubuntu, :Debian then [
        '--disabled-password',
        '--gecos ""',
        "--home #{home_dir}",
        "--ingroup #{name}",
        "--shell #{shell}",
        "--uid #{uid}"
      ].join(' ')
    end
    user_exists = "grep -q #{name}:x:#{uid} /etc/passwd"
    add_user = "adduser #{options} #{name}"
    "RUN (#{user_exists}) || (#{add_user})"
  end

  # - - - - - - - - - - - - - - - - -

  def checked_image_os(image_name)
    banner {
      cmd = "docker run --rm -i #{image_name} sh -c 'cat /etc/issue'"
      etc_issue = assert_backtick cmd
      if etc_issue.include? 'Alpine'
        puts "# #{image_name} is based on Alpine: OK"
        return :Alpine
      end
      if etc_issue.include? 'Ubuntu'
        puts "# #{image_name} is based on Ubuntu: OK"
        return :Ubuntu
      end
      if etc_issue.include? 'Debian'
        puts "# #{image_name} is based on Debian: OK"
        return :Debian
      end
      failed [
        "#{image_name} is not based on Alpine/Ubuntu/Debian"
      ]
    }
  end

  # - - - - - - - - - - - - - - - - -

  def show_sandbox_user(image_name)
    banner {
      uid = get_uid(image_name, 'sandbox')
      gid = get_gid(image_name, 'sandbox')
      puts "# #{uid}:#{gid} == uid:gid(sandbox)"
    }
  end

  # - - - - - - - - - - - - - - - - -

  def get_uid(image_name, avatar_name)
    get_id(image_name, avatar_name, 'u')
  end

  # - - - - - - - - - - - - - - - - -

  def get_gid(image_name, avatar_name)
    get_id(image_name, avatar_name, 'g')
  end

  # - - - - - - - - - - - - - - - - -

  def get_id(image_name, avatar_name, option)
    id_cmd = [
      'docker run',
      '--rm',
      '-i',
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