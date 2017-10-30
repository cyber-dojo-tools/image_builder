require_relative 'assert_system'
require_relative 'banner'
require_relative 'dockerhub'
require_relative 'json_parse'
require_relative 'print_to'

class Travis

  def initialize(triple)
    @triple = triple
    validate_image_data_triple
  end

  def push_image_to_dockerhub
    DockerHub.new.push(image_name)
  end

  def trigger_dependents
    banner {
      repos = dependent_repos
      print_to STDOUT, "number of dependent repos: #{repos.size}"
      trigger(repos)
    }
  end

  private

  attr_reader :triple

  include AssertSystem
  include Banner
  include JsonParse
  include PrintTo

  def validate_image_data_triple
    banner {
      if validated?
        print_to STDOUT, triple.inspect
      else
        print_to STDERR, *triple_diagnostic
        exit false
      end
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def image_name
    triple['image_name']
  end

  def from
    triple['from']
  end

  def test_framework?
    triple['test_framework']
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def validated?
    found = triples.find { |_,tri| tri['image_name'] == image_name }
    if found.nil?
      return false
    end
    found[1]['from'] == from && found[1]['test_framework'] == test_framework?
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def triples
    @triples ||= curled_triples
  end

  def curled_triples
    assert_system "curl --silent -O #{triples_url}"
    json_parse('./' + triples_filename)
  end

  def triples_url
    "https://raw.githubusercontent.com/cyber-dojo-languages/images_info/master/#{triples_filename}"
  end

  def triples_filename
    'images_info.json'
  end

  def triple_diagnostic
    [ '',
      triples_url,
      'does not contain an entry for:',
      '',
      "#{quoted('...dir...')}: {",
      "  #{quoted('from')}: #{quoted(from)},",
      "  #{quoted('image_name')}: #{quoted(image_name)},",
      "  #{quoted('test_framework')}: #{quoted(test_framework?)}",
      '},',
      ''
    ]
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def trigger(repos)
    repos.each do |repo_name|
      puts "  #{cdl}/#{repo_name}"
      output = assert_backtick "./app/trigger.sh #{token} #{cdl} #{repo_name}"
      print_to STDOUT, output
      print_to STDOUT, "\n", '- - - - - - - - -'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def token
    @token ||= get_token
  end

  def get_token
    login
    begin
      token = assert_backtick('travis token --org').strip
    ensure
      logout
    end
  end

  def login
    assert_system "travis login --skip-completion-check --github-token ${GITHUB_TOKEN}"
  end

  def logout
    assert_system 'travis logout'
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def dependent_repos
    triples.keys.select { |key| triples[key]['from'] == image_name }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def quoted(s)
    '"' + s.to_s + '"'
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def cdl
    'cyber-dojo-languages'
  end

end