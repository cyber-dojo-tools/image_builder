require_relative 'json_parse'

module DirGetArgs

  include JsonParse

  def dir_get_args(dir)
    get_args(dir) { |filename| read_nil(filename) }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def get_args(base)
    docker_filename = base + '/docker/Dockerfile'
    dockerfile = yield(docker_filename)
    if dockerfile.nil?
      return nil
    end
    args = []
    args << (image_name_filename = base + '/docker/image_name.json')
    args << (manifest_filename   = base + '/start_point/manifest.json')
    args << (image_name_file = yield(image_name_filename))
    args << (manifest_file   = yield(manifest_filename))
    {
      from:get_FROM(dockerfile),
      image_name:get_image_name(args),
      test_framework:get_test_framework(manifest_file)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def read_nil(filename)
    File.exists?(filename) ? IO.read(filename) : nil
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def get_FROM(dockerfile)
    lines = dockerfile.split("\n")
    from_line = lines.find { |line| line.start_with? 'FROM' }
    from_line.split[1].strip
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

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def get_test_framework(file)
    !file.nil?
  end

end
