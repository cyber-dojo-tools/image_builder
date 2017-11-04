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
    puts cmd
    assert_system cmd
    puts 'OK'
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
    # The name of the env-var holding the dockerhub username.
    # In bash, $DOCKER_USERNAME is the username.
    # In Ruby, ENV['DOCKER_USERNAME'] is the username.
    'DOCKER_USERNAME'
    # Should be DOCKERHUB_USERNAME but too late to
    # change it on all the cyber-dojo-languages org repos.
  end

  def password
    # The name of the env-var holding the dockerhub password.
    # In bash, $DOCKER_PASSWORD is the password.
    # In Ruby, ENV['DOCKER_PASSWORD'] is the password.
    'DOCKER_PASSWORD'
    # Should be DOCKERHUB_PASSWORD but too late to
    # change it on all the cyber-dojo-languages org repos.
  end

end