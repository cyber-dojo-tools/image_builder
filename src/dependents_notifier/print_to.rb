
module PrintTo

  def print_to(stream, *lines)
    lines.each { |line| stream.puts '# ' + line }
  end

end
