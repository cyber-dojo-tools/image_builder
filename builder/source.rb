require_relative 'assert_system'
require_relative 'json_parse'
require_relative 'print_to'

class Source

  def initialize(src_dir)
    @src_dir = src_dir
  end

  def image_name
    image_name_filename = src_dir + '/docker/image_name.json'
    manifest_filename   = src_dir + '/start_point/manifest.json'
    image_name_content = read_nil(image_name_filename)
    manifest_content   = read_nil(manifest_filename)

    either_or = [
      "#{image_name_filename} must exist",
      'or',
      "#{manifest_filename} must exist"
    ]

    image_name = !image_name_content.nil?
    manifest = !manifest_content.nil?

    if !image_name && !manifest
      failed either_or + [ 'neither do.' ]
    end
    if image_name && manifest
      failed either_or + [ 'but not both.' ]
    end
    if image_name
      filename = image_name_filename
      content = image_name_content
    end
    if manifest
      filename = manifest_filename
      content = manifest_content
    end

    json_parse(filename, content)['image_name']
  end

  private

  include AssertSystem # failed
  include JsonParse
  include PrintTo

  def read_nil(filename)
    File.exists?(filename) ? IO.read(filename) : nil
  end

end
