
module Banner

  def banner
    title = caller_locations(1,1)[0].label
    print_to STDOUT, '', banner_line, title
    yield
    print_to STDOUT, banner_line
  end

  def banner_line
    '-' * 42
  end

end
