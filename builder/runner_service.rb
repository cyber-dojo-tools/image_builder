require_relative 'http_json_service'

class RunnerService

  def initialize(hostname, port)
    @hostname = hostname
    @port = port
  end

  attr_reader :hostname, :port

  def kata_new(image_name, kata_id)
    args  = [image_name, kata_id]
    post(__method__, *args)
  end

  def avatar_new(image_name, kata_id, avatar_name, starting_files)
    args  = [image_name, kata_id]
    args += [avatar_name, starting_files]
    post(__method__, *args)
  end

  def run_cyber_dojo_sh(image_name, kata_id, avatar_name,
    new_files, deleted_files, unchanged_files, changed_files,
    max_seconds)
    args  = [image_name, kata_id, avatar_name]
    args += [new_files, deleted_files, unchanged_files, changed_files]
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

end
