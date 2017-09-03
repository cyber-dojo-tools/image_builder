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
    unless validated?
      print_to STDERR, triple_diagnostic(triples_url)
      if running_on_travis?
        exit false
      end
    end

    if running_on_travis?
      Dockerhub.login
    end

    builder = ImageBuilder.new(@src_dir, @args)
    builder.build_and_test_image

    if running_on_travis?
      Dockerhub.push(image_name)
      # Send POST to trigger immediate dependents.
      # Probably will involve installing npm and then
      # curling the trigger.js file used in cyber-dojo repos.
    end
  end

  private

  include AssertSystem
  include DirGetArgs

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
    triple['from'] == 'X'+from && triple['test_framework'] == test_framework?
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

  # - - - - - - - - - - - - - - - - -

  def triple_diagnostic(url)
    lines = [ '' ]
    if running_on_travis?
      lines << 'NOT doing dockerhub login/push or github triggers because'
    end
    lines << [ url,
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

  def running_on_travis?
    ENV['TRAVIS'] == 'true'
  end

end

# - - - - - - - - - - - - - - - - -

InnerMain.new.run
