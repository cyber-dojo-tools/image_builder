require_relative 'image_builder'
require_relative 'json_parse'
require_relative 'source'

class SourceDocker

  def initialize(src_dir)
    @src_dir = src_dir
  end

  def dir?
    Dir.exist? dir
  end

  def build_image(name)
    name ||= json_parse(dir + '/image_name.json')['image_name']
    source = Source.new(@src_dir)
    builder = ImageBuilder.new(source)
    builder.build_image(name)
  end

  def from
    lines = dockerfile.split("\n")
    from_line = lines.find { |line| line.start_with? 'FROM' }
    from_line.split[1].strip
  end

  private

  include JsonParse

  def dir
    @src_dir + '/docker'
  end

  def dockerfile
    IO.read(dir + '/Dockerfile')
  end

end
