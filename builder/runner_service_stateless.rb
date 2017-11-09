require_relative 'http_json_service'

class RunnerServiceStateless

  def kata_new(image_name, kata_id)
    args  = [image_name, kata_id]
    post(__method__, *args)
  end

  def avatar_new(image_name, kata_id, avatar_name, starting_files)
    args  = [image_name, kata_id]
    args += [avatar_name, starting_files]
    post(__method__, *args)
  end

  def run(image_name, kata_id, avatar_name, visible_files, max_seconds)
    args  = [image_name, kata_id]
    args += [avatar_name]
    args += [visible_files]
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

  include HttpJsonService

  def hostname
    'runner_stateless'
  end

  def port
    '4597'
  end

end
