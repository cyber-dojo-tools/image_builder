require_relative 'http_service'

class RunnerServiceStatefull

  def kata_new(image_name, kata_id)
    args  = [image_name, kata_id]
    post(__method__, *args)
  end

  def avatar_new(image_name, kata_id, avatar_name, starting_files)
    args  = [image_name, kata_id]
    args += [avatar_name, starting_files]
    post(__method__, *args)
  end

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    args  = [image_name, kata_id]
    args += [avatar_name]
    args += [deleted_filenames, changed_files]
    args += [max_seconds]
    post(__method__, *args)
  end

  def avatar_old(image_name, kata_id, avatar_name)
    args  = [image_name, kata_id]
    args += [avatar_name]
    post(__method__, *args)
  end

  def kata_old(image_name, kata_id)
    args  = [image_name, kata_id]
    post(__method__, *args)
  end

  private

  include HttpService

  def hostname
    'runner'
  end

  def port
    '4557'
  end

end
