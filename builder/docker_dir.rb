require_relative 'image_builder'
require_relative 'json_parse'

class DockerDir

  def initialize(dir_name)
    @dir_name = dir_name
  end

  # - - - - - - - - - - - - - - - - -

  def build_image(name)
    name ||= image_name
    builder = ImageBuilder.new(dir_name)
    builder.build_image(name)
    name
  end

  # - - - - - - - - - - - - - - - - -

  def image_FROM
    lines = dockerfile.split("\n")
    from_line = lines.find { |line| line.start_with? 'FROM' }
    from_line.split[1].strip
  end

  private

  attr_reader :dir_name

  include JsonParse

  def dockerfile
    IO.read(dir_name + '/Dockerfile')
  end

  def image_name
    json_parse(dir_name + '/image_name.json')['image_name']
  end

end
