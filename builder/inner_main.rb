#!/usr/bin/env ruby

require_relative 'src_dir'

src_dir = SourceDir.new(ENV['SRC_DIR'])
if src_dir.start_point?
  #src_dir.assert_create_start_point
end
src_dir.check_all
