#!/usr/bin/env ruby

require_relative 'assert_system'
require_relative 'dir_get_args'
require_relative 'dockerhub'
require_relative 'image_builder'

class InnerMain

  def initialize
    @src_dir = ENV['SRC_DIR']
    @args = dir_get_args(@src_dir)
  end

  def run
    validate_image_data_triple
    Dockerhub.login
    builder = ImageBuilder.new(@src_dir, @args)
    builder.build_and_test_image
    Dockerhub.push_image(image_name)
    Dockerhub.logout
    trigger_dependent_repos
  end

  private

  include AssertSystem
  include DirGetArgs

  def validate_image_data_triple
    banner
    if validated?
      print_to STDOUT, triple.inspect, 'OK'
    else
      print_to STDERR, triple_diagnostic(triples_url)
      if running_on_travis?
        exit false
      end
    end
  end

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

  # - - - - - - - - - - - - - - - - -

  def validated?
    triple = triples.find { |_,args| args['image_name'] == image_name }
    if triple.nil?
      return false
    end
    triple = triple[1]
    triple['from'] == from && triple['test_framework'] == test_framework?
  end

  def triples
    @triples ||= curled_triples
  end

  def curled_triples
    assert_system "curl --silent -O #{triples_url}"
    JSON.parse(IO.read("./#{triples_filename}"))
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

  # - - - - - - - - - - - - - - - - -

  def trigger_dependent_repos
    banner
    if running_on_travis?
      assert_system "travis login --no-interactive --github-token ${GITHUB_TOKEN}"
      token = assert_backtick('travis token --org').strip
    else
      print_to STDOUT, 'skipped (not running on Travis)'
    end
    repos = dependent_repos
    print_to STDOUT, "dependent repos: #{repos.size}"
    repos.each do |repo_name|
      puts "  #{cdl}/#{repo_name}"
      if running_on_travis?
        assert_system "./app/trigger.sh #{token} #{cdl} #{repo_name}"
      end
    end
    banner_end
  end

  def dependent_repos
    triples.keys.select { |key| triples[key]['from'] == image_name }
  end

  def cdl
    'cyber-dojo-languages'
  end

  # - - - - - - - - - - - - - - - - -

  def banner
    title = caller_locations(1,1)[0].label
    print_to STDOUT, '', banner_line, title
  end

  def banner_end
    print_to STDOUT, 'OK', banner_line
  end

  def banner_line
    '-' * 42
  end

  # - - - - - - - - - - - - - - - - -

  def running_on_travis?
    ENV['TRAVIS'] == 'true'
  end

end

InnerMain.new.run
