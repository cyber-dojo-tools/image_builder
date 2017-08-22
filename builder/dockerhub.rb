
# Code to push a successfully built and tested
# language/testFramework docker image to dockerhub.

class Dockerhub

  def self.login
    banner 'dockerhub_login'
    if dockerhub_username == ''
      failed [ "#{dockerhub_username_env_var} env-var not set" ]
    end
    if dockerhub_password == ''
      failed [ "#{dockerhub_password_env_var} env-var not set" ]
    end
    # careful not to show password if command fails
    output = `#{docker_login_cmd(dockerhub_username, dockerhub_password)}`
    status = $?.exitstatus
    unless status == success
      failed [
        "#{docker_login_cmd('[secure]','[secure]')}",
        "exit_status == #{status}",
        output
      ]
    end
    banner_end
  end

  def self.push(image_name)
    banner 'dockerhub_push'
    print([ "pushing #{image_name}" ], STDOUT)
    assert_system "docker push #{image_name}"
    assert_system 'docker logout'
    banner_end
  end

  private

  class << self

    def docker_login_cmd(username, password)
      # TODO: Try this several times before failing?
      [ 'docker login',
          "--username #{username}",
          "--password #{password}"
      ].join(' ')
    end

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def success; 0; end

    def dockerhub_username_env_var
      # should be DOCKERHUB_USERNAME but too late
      # to change it on all the cyber-dojo-languages repos
      'DOCKER_USERNAME'
    end

    def dockerhub_password_env_var
      # should be DOCKERHUB_PASSWORD but too late
      # to change it on all the cyber-dojo-languages repos
      'DOCKER_PASSWORD'
    end

    def dockerhub_username
      ENV[dockerhub_username_env_var]
    end

    def dockerhub_password
      ENV[dockerhub_password_env_var]
    end

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def banner(title)
      print([ '', banner_line, title, ], STDOUT)
    end

    def banner_end
      print([ 'OK', banner_line ], STDOUT)
    end

    def banner_line
      '-' * 42
    end

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def assert_system(command)
      system command
      status = $?.exitstatus
      unless status == success
        failed [ command, "exit_status == #{status}" ]
      end
    end

    def failed(lines)
      log(['FAILED'] + lines)
      exit 1
    end

    def log(lines)
      print(lines, STDERR)
    end

    def print(lines, stream)
      lines.each { |line| stream.puts line }
    end

  end

end