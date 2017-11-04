
module Banner

  def banner
    title = caller_locations(1,1)[0].label
    line = '-' * 42
    puts ''
    puts line
    puts title
    yield
    puts line
  end

end
