require_relative 'assert_system'

class DockerHub

  def initialize
    assert_env_var_for username
    assert_env_var_for password
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

  def assert_env_var_for(name)
    unless ENV.has_key? name
      failed "#{name} env-var not set"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ok(cmd)
    print_to STDOUT, cmd
    assert_system cmd
    print_to STDOUT, 'OK'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def docker_login
    [ "echo $#{password} |",
      'docker login',
        "--username #{ENV[username]}",
        "--password-stdin"
    ].join(' ')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def username
    # should be DOCKERHUB_USERNAME but too late
    # to change it on all the cyber-dojo-languages repos
    'DOCKER_USERNAME'
  end

  def password
    # should be DOCKERHUB_PASSWORD but too late
    # to change it on all the cyber-dojo-languages repos
    'DOCKER_PASSWORD'
  end

end