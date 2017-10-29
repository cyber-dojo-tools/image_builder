require_relative 'failed'
require_relative 'json_parse'
require_relative 'source_start_point'

class Source

  def initialize(src_dir)
    @src_dir = src_dir
  end

  def dir
    @src_dir
  end

  def docker_dir?
    Dir.exist? docker_dir
  end

  def docker_dir
    dir + '/docker'
  end

  def dockerfile
    IO.read(docker_dir + '/Dockerfile')
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def start_point
    SourceStartPoint.new(@src_dir)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def image_name
    image_name_filename = docker_dir + '/image_name.json'

    either_or = [
      "#{image_name_filename} must exist",
      'or',
      "#{start_point.manifest_filename} must exist"
    ]

    image_name_exist = File.exist? image_name_filename

    if !image_name_exist && !start_point.manifest_filename?
      failed either_or + [ 'neither do.' ]
    end
    if image_name_exist && start_point.manifest_filename?
      failed either_or + [ 'but not both.' ]
    end

    if image_name_exist
      json_parse(image_name_filename)['image_name']
    else
      start_point.image_name
    end
  end

  private

  include Failed
  include JsonParse

end
