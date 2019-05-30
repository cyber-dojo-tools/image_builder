
module PrintTo

  def print_to(stream, *lines)
    lines.each { |line| stream.puts '# ' + line }
    stream.flush
  end

end
