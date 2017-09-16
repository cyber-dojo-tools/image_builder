require 'json'

module JsonParse

  def json_parse(filename, content)
    begin
      JSON.parse(content)
    rescue JSON::ParserError
      failed "error parsing JSON file:#{filename}"
    end
  end

end
