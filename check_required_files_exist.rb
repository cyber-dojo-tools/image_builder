
def check_required_files_exist
  banner __method__.to_s

  if !docker_image_src?
    failed [ "#{docker_marker_file} must exist" ]
  end
  either_or = [
    "#{language_repo_marker_file} must exist",
    'or',
    "#{test_framework_repo_marker_file} must exist"
  ]
  if !language_repo? && !test_framework_repo?
    failed either_or + [ 'neither do.' ]
  end
  if language_repo? && test_framework_repo?
    failed either_or + [ 'but not both.' ]
  end

=begin
  # ? do red/amber/green test dynamically using s/6 * 9/6 * 7/
  if test_framework_repo?
    required_dirs = [
      "#{outputs_dir}/red",
      "#{outputs_dir}/amber",
      "#{outputs_dir}/green",
      "#{traffic_lights_dir}/amber",
      "#{traffic_lights_dir}/green",
    ]
    missing_dirs = required_dirs.select { |dir| !Dir.exists? dir }
    missing_dirs.each do |dir|
      failed [ "no #{dir}/ dir" ]
    end
    unless missing_dirs == []
      exit fail
    end
  end
=end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def docker_marker_file
  "#{docker_dir}/Dockerfile"
end

def docker_image_src?
  File.exists? docker_marker_file
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def language_repo_marker_file
  "#{docker_dir}/image_name.json"
end

def language_repo?
  File.exists? language_repo_marker_file
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def test_framework_repo_marker_file
  "#{start_point_dir}/manifest.json"
end


def test_framework_repo?
  File.exists? test_framework_repo_marker_file
end
