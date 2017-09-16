
module Banner

  def banner
    title = caller_locations(1,1)[0].label
    line = '-' * 42
    print_to STDOUT, '', line, title
    yield
    print_to STDOUT, line
  end

end
