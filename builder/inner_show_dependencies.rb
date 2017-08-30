#!/usr/bin/env ruby

require_relative 'dependencies'

#puts '-' * 42
#puts 'gathering_dependencies'
dependencies = get_dependencies
#puts
puts JSON.pretty_generate(dependencies)
#puts
#puts "#{dependencies.size} repos gathered"
#puts
#graph = dependency_graph(dependencies)
#puts
#puts JSON.pretty_generate(graph)
