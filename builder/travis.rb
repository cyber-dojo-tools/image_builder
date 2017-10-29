require_relative 'assert_system'
require_relative 'banner'
require_relative 'dockerhub'
require_relative 'json_parse'
require_relative 'print_to'

class Travis

  def initialize(source)
    @source = source
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
      print_to STDOUT, "number of dependent repos: #{repos.size}"
      trigger(repos)
    }
  end

  private

  attr_reader :source

  include AssertSystem
  include Banner
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
    source.image_name
  end

  def from
    # all repos on Travis have a /docker/Dockerfile
    # base language repos obviously
    # test-framework repos for adding in the red-amber-green regex file.
    docker_filename = source.docker_dir + '/Dockerfile'
    dockerfile = IO.read(docker_filename)
    lines = dockerfile.split("\n")
    from_line = lines.find { |line| line.start_with? 'FROM' }
    from_line.split[1].strip
  end

  def test_framework?
    source.start_point_dir?
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