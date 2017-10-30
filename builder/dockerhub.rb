require_relative 'assert_system'

class DockerHub

  def initialize
    unless ENV.has_key? dockerhub_username
      failed "#{dockerhub_username} env-var not set"
    end
    unless ENV.has_key? dockerhub_password
      failed "#{dockerhub_password} env-var not set"
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