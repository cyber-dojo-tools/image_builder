require_relative 'assert_system'

class DockerHub

  def initialize
    unless ENV.has_key? dockerhub_username_env_var_name
      failed "#{dockerhub_username_env_var_name} env-var not set"
    end
    unless ENV.has_key? dockerhub_password_env_var_name
      failed "#{dockerhub_password_env_var_name} env-var not set"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def push(image_name)
    ok docker_login
    begin
      ok "docker push #{image_name}"
    ensure
      ok 'docker logout'
    end
  end

  private

  include AssertSystem

  def ok(cmd)
    print_to STDOUT, cmd
    assert_system cmd
    print_to STDOUT, 'OK'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def docker_login
    [ "echo $#{dockerhub_password_env_var_name} |",
      'docker login',
        "--username #{ENV[dockerhub_username_env_var_name]}",
        "--password-stdin"
    ].join(' ')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def dockerhub_username_env_var_name
    # should be DOCKERHUB_USERNAME but too late
    # to change it on all the cyber-dojo-languages repos
    'DOCKER_USERNAME'
  end

  def dockerhub_password_env_var_name
    # should be DOCKERHUB_PASSWORD but too late
    # to change it on all the cyber-dojo-languages repos
    'DOCKER_PASSWORD'
  end

end