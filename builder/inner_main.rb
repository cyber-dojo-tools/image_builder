#!/usr/bin/env ruby

require_relative 'assert_system'
require_relative 'banner'
require_relative 'dir_get_args'
require_relative 'dockerhub'
require_relative 'image_builder'
require_relative 'json_parse'
require_relative 'print_to'

class InnerMain

  def initialize
    @src_dir = ENV['SRC_DIR']
    @args = dir_get_args(@src_dir)
  end

  def run
    t1 = Time.now
    if running_on_travis?
      validate_image_data_triple
      dockerhub_login
    end
    builder = ImageBuilder.new(@src_dir, @args)
    builder.build_and_test_image_start_point
    if running_on_travis?
      dockerhub_push_image(image_name)
      dockerhub_logout
      trigger_dependent_repos
    end
    t2 = Time.now
    print_date_time_duration(t1, t2)
  end

  private

  include AssertSystem
  include Banner
  include DirGetArgs
  include Dockerhub
  include JsonParse
  include PrintTo

  def print_date_time_duration(t1, t2)
    banner {
      assert_system 'date'
      hms = Time.at(t2 - t1).utc.strftime("%H:%M:%S")
      print_to STDOUT, "took #{hms}"
    }
  end

  def validate_image_data_triple
    banner {
      if validated?
        print_to STDOUT, triple.inspect
      else
        print_to STDERR, *triple_diagnostic(triples_url)
        exit false
      end
    }
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
    banner {
      repos = dependent_repos
      print_to STDOUT, "dependent repos: #{repos.size}"
      travis_trigger(repos)
    }
  end

  def travis_trigger(repos)
    if repos.size == 0
      return
    end
    assert_system "travis login --skip-completion-check --github-token ${GITHUB_TOKEN}"
    token = assert_backtick('travis token --org').strip
    assert_system 'travis logout'
    repos.each do |repo_name|
      puts "  #{cdl}/#{repo_name}"
      output = assert_backtick "./app/trigger.sh #{token} #{cdl} #{repo_name}"
      print_to STDOUT, output
      print_to STDOUT, "\n", '- - - - - - - - -'
    end
  end

  def dependent_repos
    triples.keys.select { |key| triples[key]['from'] == image_name }
  end

  def cdl
    'cyber-dojo-languages'
  end

  # - - - - - - - - - - - - - - - - -

  def running_on_travis?
    # return false if we are running image_builder's tests
    ENV['TRAVIS'] == 'true' &&
      ENV['TRAVIS_REPO_SLUG'] != 'cyber-dojo-languages/image_builder'
  end

end

InnerMain.new.run
