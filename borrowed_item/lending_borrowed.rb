require File.dirname(__FILE__) + "/../graph_path_explorer.rb"

explorer = GraphPathExplorer.new("lending_borrowed.json")
paths = explorer.valid_paths

puts "VALID"

paths.each do |path|
  names = path.collect do |transition| transition["name"] end
  puts names.to_json
end

puts "INVALID"

invalid_paths = explorer.invalid_paths
invalid_paths.each do |path|
  names = path.collect do |transition| transition["name"] end
  puts names.to_json
end

puts "#{paths.length} valid paths and #{invalid_paths.length} invalid paths"