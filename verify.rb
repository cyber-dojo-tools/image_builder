#!/usr/bin/env ruby

require_relative 'dependencies'

# This will take input naming a repo claims its current data is
# and outputs whether that data agrees with the dependencies.

puts "verify"
puts '~~~~~~~'
puts ARGV[0]
puts '~~~~~~~'
puts dependencies