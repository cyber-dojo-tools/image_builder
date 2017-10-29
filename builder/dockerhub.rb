require_relative 'assert_system'
require_relative 'banner'

class DockerHub

  def push(image_name)
    login
    begin
      banner {
        print_to STDOUT, "pushing #{image_name} to dockerhub"
        #assert_system "docker push #{image_name}"
      }
    ensure
      logout
    end
  end

  private

  include AssertSystem
  include Banner

  def login
    banner {
      unless ENV.has_key? dockerhub_username
        failed "#{dockerhub_username} env-var not set"
      end
      unless ENV.has_key? dockerhub_password
        failed "#{dockerhub_password} env-var not set"
      end
      output = `#{docker_login_cmd}`
      status = $?.exitstatus
      unless status == success
        failed [
          '[docker login] failed',
          "exit_status == #{status}",
          output
        ]
      end
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def logout
    banner {
      assert_system 'docker logout'
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def docker_login_cmd
    [ 'echo $DOCKER_PASSWORD |',
      'docker login',
        "--username #{ENV[dockerhub_username]}",
        "--password-stdin"
    ].join(' ')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def dockerhub_username
    # should be DOCKERHUB_USERNAME but too late
    # to change it on all the cyber-dojo-languages repos
    'DOCKER_USERNAME'
  end

  def dockerhub_password
    # should be DOCKERHUB_PASSWORD but too late
    # to change it on all the cyber-dojo-languages repos
    'DOCKER_PASSWORD'
  end

end