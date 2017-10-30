require_relative 'image_builder'
require_relative 'json_parse'
require_relative 'source'

class SourceDocker

  def initialize
    @src_dir = ENV['SRC_DIR']
  end

  def dir?
    Dir.exist? dir
  end

  def build_image(name)
    name ||= json_parse(dir + '/image_name.json')['image_name']
    source = Source.new(@src_dir)
    builder = ImageBuilder.new(source)
    builder.build_image
  end

  private

  include JsonParse

  def dir
    @src_dir + '/docker'
  end

end
