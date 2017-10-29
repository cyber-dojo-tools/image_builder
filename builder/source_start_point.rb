require_relative 'json_parse'

class SourceStartPoint

  def initialize(src_dir)
    @src_dir = src_dir
  end

  def dir?
    Dir.exist? dir
  end

  def dir
    @src_dir + '/start_point'
  end

  def manifest_filename
    dir + '/manifest.json'
  end

  def visible_files
    # start-point has already been verified
    files = {}
    manifest['visible_filenames'].each do |filename|
      files[filename] = IO.read(dir + '/' + filename)
    end
    files
  end

  def runner_choice
    manifest['runner_choice']
  end

  private

  include JsonParse

  def manifest
    json_parse(manifest_filename)
  end

end
