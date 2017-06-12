
def assert_system(command)
  system command
  status = $?.exitstatus
  unless status == success
    failed [ command, "exit_status == #{status}" ]
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def assert_backtick(command)
  output = `#{command}`
  status = $?.exitstatus
  unless status == success
    failed [ command, "exit_status == #{status}", output ]
  end
  output
end
