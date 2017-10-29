require 'json'
require_relative 'failed'

module JsonParse

  def json_parse(filename, content)
    begin
      JSON.parse(content)
    rescue JSON::ParserError
      failed "error parsing JSON file:#{filename}"
    end
  end

  include Failed

end
