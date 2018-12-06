require_relative 'http_json_service'

class RunnerService

  def initialize
    @hostname = 'runner'
    @port = 4597
  end

  attr_reader :hostname, :port

  def run_cyber_dojo_sh(image_name, id, files, max_seconds)
    post(__method__, image_name, id, files, max_seconds)
  end

  private

  include HttpJsonService

end
