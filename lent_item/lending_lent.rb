require File.dirname(__FILE__) + "/../graph_path_explorer"

graph = GraphPathExplorer.new("lending_lent.json");
graph.valid_paths.each do |path|
  path_names = path.collect do |edge| edge["name"] end
  puts path_names.to_json
end
puts "#{graph.valid_paths.length} valid paths."

graph.error_paths.each do |path|
  path_names = path.collect do |edge| edge["name"] end
  puts path_names.to_json
end
puts "#{graph.error_paths.length} error paths."