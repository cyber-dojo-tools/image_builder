require_relative 'assert_system'
require_relative 'banner'
require_relative 'dockerhub'
require_relative 'dir_get_args'
require_relative 'json_parse'
require_relative 'print_to'

class Travis

  def initialize
    @args = dir_get_args(ENV['SRC_DIR'])
  end

  def validate_image_data_triple
    if !running_on_travis?
      return
    end
    banner {
      if validated?
        print_to STDOUT, triple.inspect
      else
        print_to STDERR, *triple_diagnostic(triples_url)
        exit false
      end
    }
  end

  private

  include AssertSystem
  include Banner
  include DirGetArgs
  include Dockerhub
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
    @args[:image_name]
  end

  def from
    @args[:from]
  end

  def test_framework?
    @args[:test_framework]
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def validated?
    triple = triples.find { |_,args| args['image_name'] == image_name }
    if triple.nil?
      return false
    end
    triple = triple[1]
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

  def triple_diagnostic(url)
    [ '',
      url,
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

  def quoted(s)
    '"' + s.to_s + '"'
  end

  # - - - - - - - - - - - - - - - - - - - - -

  def running_on_travis?
    # return false if we are running image_builder's tests
    ENV['TRAVIS'] == 'true' &&
      ENV['TRAVIS_REPO_SLUG'] != 'cyber-dojo-languages/image_builder'
  end

end