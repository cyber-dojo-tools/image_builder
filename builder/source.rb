require_relative 'failed'
require_relative 'json_parse'

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

  def start_point_dir?
    Dir.exist? start_point_dir
  end

  def start_point_dir
    dir + '/start_point'
  end

  def start_point_visible_files
    # start-point has already been verified
    files = {}
    manifest['visible_filenames'].each do |filename|
      path = start_point_dir + '/' + filename
      files[filename] = IO.read(path)
    end
    files
  end

  def start_point_runner_choice
    manifest['runner_choice']
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def image_name
    image_name_filename = docker_dir + '/image_name.json'

    either_or = [
      "#{image_name_filename} must exist",
      'or',
      "#{manifest_filename} must exist"
    ]

    image_name_exist = File.exist? image_name_filename
    manifest_exist = File.exist? manifest_filename

    if !image_name_exist && !manifest_exist
      failed either_or + [ 'neither do.' ]
    end
    if image_name_exist && manifest_exist
      failed either_or + [ 'but not both.' ]
    end

    if image_name_exist
      filename = image_name_filename
    end
    if manifest_exist
      filename = manifest_filename
    end

    json_parse(filename)['image_name']
  end

  private

  include Failed
  include JsonParse

  def manifest_filename
    start_point_dir + '/manifest.json'
  end

  def manifest
    json_parse(manifest_filename)
  end

end
