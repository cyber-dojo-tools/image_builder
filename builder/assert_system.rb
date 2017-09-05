
module AssertSystem

  def assert_system(command)
    system command
    status = $?.exitstatus
    unless status == success
      failed command, "exit_status == #{status}"
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

  # - - - - - - - - - - - - - - - - -

  def failed(*lines)
    print_to STDERR, *(['FAILED'] + lines.flatten)
    exit 1
  end

  def print_to(stream, *lines)
    lines.each { |line| stream.puts '# ' + line }
  end

  def success
    0
  end

end
