require_relative 'assert_system'
require_relative 'banner'
require_relative 'dir_get_args'
require_relative 'dockerhub'
require_relative 'json_parse'
require_relative 'print_to'

class Travis

  def initialize
    args = dir_get_args(ENV['SRC_DIR'])
    @image_name = args[:image_name]
    @from = args[:from]
    @test_framework = args[:test_framework]
  end

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

  def push_image_to_dockerhub
    DockerHub.new.push(image_name)
  end

  def trigger_dependents
    banner {
      repos = dependent_repos
      print_to STDOUT, "dependent repos: #{repos.size}"
      trigger(repos)
    }
  end

  private

  include AssertSystem
  include Banner
  include DirGetArgs
  include JsonParse
  include PrintTo

  def triple
    {
      "from" => from,
      "image_name" => image_name,
      "test_framework" => test_framework?
    }
  end

  def image_name
    @image_name
  end

  def from
    @from
  end

  def test_framework?
    @test_framework
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def validated?
    found = triples.find { |_,tri| tri['image_name'] == image_name }
    if found.nil?
      return false
    end
    triple = found[1]
    triple['from'] == from && triple['test_framework'] == test_framework?
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def triples
    @triples ||= curled_triples
  end

  def curled_triples
    assert_system "curl --silent -O #{triples_url}"
    json_parse(triples_filename, IO.read("./#{triples_filename}"))
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
    if repos.size == 0
      return
    end
    token = get_token
    repos.each do |repo_name|
      puts "  #{cdl}/#{repo_name}"
      output = assert_backtick "./app/trigger.sh #{token} #{cdl} #{repo_name}"
      print_to STDOUT, output
      print_to STDOUT, "\n", '- - - - - - - - -'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def get_token
    assert_system "travis login --skip-completion-check --github-token ${GITHUB_TOKEN}"
    begin
      token = assert_backtick('travis token --org').strip
    ensure
      assert_system 'travis logout'
    end
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