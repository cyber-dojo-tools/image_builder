require_relative 'assert_system'
require_relative 'banner'
require_relative 'print_to'

class Dockerhub

  def login
    banner {
      if dockerhub_username == ''
        failed "#{dockerhub_username_env_var} env-var not set"
      elsif dockerhub_password == ''
        failed "#{dockerhub_password_env_var} env-var not set"
      else
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
      end
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def push_image(image_name)
    banner {
      print_to STDOUT, "pushing #{image_name}"
      assert_system "docker push #{image_name}"
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def logout
    banner {
      assert_system 'docker logout'
    }
  end

  private

  include AssertSystem
  include Banner
  include PrintTo

  def docker_login_cmd(username, password)
    [ 'docker login',
        "--username #{username}",
        "--password #{password}"
    ].join(' ')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

end