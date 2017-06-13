
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
