require_relative 'failed'

module AssertSystem

  def assert_system(command)
    system command
    status = $?.exitstatus
    unless status == success
      failed "exit_status == #{status}"
    end
  end

  def assert_backtick(command)
    output = `#{command}`
    status = $?.exitstatus
    unless status == success
      failed command, "exit_status == #{status}", output
    end
    output
  end

  def success
    0
  end

  include Failed
end
