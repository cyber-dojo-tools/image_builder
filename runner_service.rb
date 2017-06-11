require_relative 'http_service'

class RunnerService

  def run(image_name, kata_id, avatar_name, visible_files, max_seconds)
    args = [image_name, kata_id, avatar_name]
    args += [visible_files, max_seconds]
    post(__method__, *args)
  end

  private

  include HttpService
  def hostname; 'runner_stateless'; end
  def port; '4597'; end

end
