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
    print_to STDOUT, 'docker login'
    login
    print_to STDOUT, 'OK'
    begin
      docker_push = "docker push #{image_name}"
      print_to STDOUT, docker_push
      assert_system docker_push
      print_to STDOUT, 'OK'
    ensure
      print_to STDOUT, 'docker logout'
      logout
      print_to STDOUT, 'OK'
    end
  end

  private

  include AssertSystem

  def login
    output = `#{docker_login_cmd}`
    status = $?.exitstatus
    unless status == success
      failed [
        '[docker login] failed',
        "exit_status == #{status}",
        output
      ]
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def logout
    assert_system 'docker logout'
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