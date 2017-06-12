require_relative 'http_service'

class RunnerServiceStateless

  def run(image_name, kata_id, avatar_name, visible_files, max_seconds)
    args  = [image_name, kata_id]
    args += [avatar_name]
    args += [visible_files]
    args += [max_seconds]
    post(__method__, *args)
  end

  private

  attr_reader :image_name, :kata_id

  include HttpService
  def hostname; 'runner_stateless'; end
  def port; '4597'; end

end
