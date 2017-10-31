#!/usr/bin/env ruby

require_relative 'start_point'

start_point = StartPoint.new(ENV['SRC_DIR'])
start_point.assert_create
start_point.check_all

