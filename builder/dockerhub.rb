require_relative 'assert_system'

class DockerHub

  def initialize
    assert_env_var username
    assert_env_var password
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

  def assert_env_var(name)
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
        '--username', ENV[username],
        '--password-stdin'
    ].join(' ')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def username
    # The name of the environment variable holding the username.
    # Viz, in bash, $DOCKER_USERNAME is the username.
    # Viz, in Ruby, ENV['DOCKER_USERNAME'] is the username.
    'DOCKER_USERNAME'
    # Should be DOCKERHUB_USERNAME but too late to
    # change it on all the cyber-dojo-languages repos.
  end

  def password
    # The name of the environment variable holding the password.
    # Viz, in bash, $DOCKER_PASSWORD is the password.
    # Viz, in Ruby, ENV['DOCKER_PASSWORD'] is the password.
    'DOCKER_PASSWORD'
    # Should be DOCKERHUB_PASSWORD but too late to
    # change it on all the cyber-dojo-languages repos.
  end

end