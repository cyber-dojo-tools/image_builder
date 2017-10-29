require_relative 'print_to'

module Failed

  def failed(*lines)
    print_to STDERR, *(['FAILED'] + lines.flatten)
    exit 1
  end

  include PrintTo

end
