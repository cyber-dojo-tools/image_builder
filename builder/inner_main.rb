#!/usr/bin/env ruby

require_relative 'assert_system'
require_relative 'dir_get_args'
require_relative 'dockerhub'
require_relative 'image_builder'

class InnerMain

  def initialize
    @src_dir = ENV['SRC_DIR']
    @args = dir_get_args(@src_dir)
    validate_my_data
  end

  def run
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

  def image_name
    @args[:image_name]
  end

  def from
    @args[:from]
  end

  def test_framework?
    @args[:test_framework]
  end

  def running_on_travis?
    ENV['TRAVIS'] == 'true'
  end

  def validate_my_data
    # TODO: Try the curl several times before failing?
    filename = 'images_info.json'
    url = "https://raw.githubusercontent.com/cyber-dojo-languages/images_info/master/#{filename}"
    assert_system "curl --silent -O #{url}"
    triples = JSON.parse(IO.read("./#{filename}"))
    triple = triples.find { |_,args| args['image_name'] == image_name }
    if triple.nil?
      failed bad_triple_diagnostic(url)
    end
    triple = triple[1]
    unless triple['from'] == from && triple['test_framework'] == test_framework?
      failed bad_triple_diagnostic(url)
    end
  end

  # - - - - - - - - - - - - - - - - -

  def bad_triple_diagnostic(url)
    [ url,
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

end

# - - - - - - - - - - - - - - - - -

InnerMain.new.run
