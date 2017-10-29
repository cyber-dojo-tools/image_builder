require_relative 'json_parse'

module DirGetArgs

  include JsonParse

  def dir_get_args(src_dir)
    args = []
    args << (image_name_filename = src_dir + '/docker/image_name.json')
    args << (manifest_filename   = src_dir + '/start_point/manifest.json')
    args << (image_name_file = read_nil(image_name_filename))
    args << (manifest_file   = read_nil(manifest_filename))
    {
      image_name:get_image_name(args)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def read_nil(filename)
    File.exists?(filename) ? IO.read(filename) : nil
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def get_image_name(args)
    image_name_filename = args[0]
    manifest_filename   = args[1]
    image_name_content  = args[2]
    manifest_content    = args[3]

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

end
