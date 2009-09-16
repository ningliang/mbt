# TODO error paths - generate from valid paths
# TODO canonical output (CSV)

require 'rubygems'
require 'json/ext'

# Utility

def print_usage
  puts "usage: ruby test_gen.rb <file_name>"
  puts "edge labels must be unique"
end

def snapshot(arr) 
  ret = []
  arr.each do |item|
    ret.push item end
  ret
end

# Load file and graphs

file = ARGV[0]
unless file
  print_usage
  exit
end

data = ""
File.open(file, "r") do |infile|
  while (line = infile.gets)
    data += line
  end
end

# State variables
specification = JSON.parse(data)

edge_name_graph = {}
final_edge_names = []
all_edge_names = []
edges = {}

stack = []
paths = []
error_paths = []

visited_paths = {}
visited_error_paths = {}

# Process specification
start = {
  "name" => "Start",
  "from" => nil,
  "to" => specification["start"]
}
specification["edges"].push(start)
specification["edges"].each do |current|
  # Put the edges into a dictionary for easy access
  edges[current["name"]] = current
  all_edge_names.push current["name"]
  
  # Get the final edges
  if specification["end"].include? current["to"]
    final_edge_names.push current["name"]
  end
  
  # Construct the edge graph
  edge_name_graph[current["name"]] = []
  specification["edges"].each do |edge|   
    if current["to"].eql? edge["from"]
      edge_name_graph[current["name"]].push edge["name"]
    end
  end
end

# Grab all non cyclic paths ending with a edge passing into final
stack.push start["name"]
until stack.empty?
  edge_name = stack.last
  if final_edge_names.include? edge_name and paths.length > 0
    stack.pop
  else
    has_new_child_path = false  
    edge_name_graph[edge_name].each do |next_name|
      unless stack.include? next_name
        stack.push next_name
        hash = stack.join ","
        if visited_paths[hash]
          stack.pop
        else
          paths.push snapshot(stack)
          visited_paths[hash] = true
          has_new_child_path = true
          break;
        end
      end
    end
    stack.pop unless has_new_child_path
  end
end

# Prune the paths for complete paths only
paths = paths.find_all do |path|
  final_edge_names.include? path.last
end

# Generate error paths
paths.each do |path|
  (1..(path.length)).each do |n|
    # Get the last action in this success chain
    subpath = path.first(n)
    action = subpath.last
    
    # For all illegal actions, generate a path and add if new
    illegal_actions = all_edge_names.delete_if do |item| edge_name_graph[action].include? item end
    illegal_actions.delete "Start"
    illegal_actions.each do |illegal_action|
      new_subpath = subpath.push illegal_action
      unless visited_error_paths[new_subpath.join(",")] 
        visited_error_paths[new_subpath.join(",")] = true
        error_paths.push snapshot(new_subpath)
      end
    end
  end
end

puts
puts "VALID PATHS"

# Print out all paths
paths.each do |path|
  puts path.join(",")
end
puts "#{paths.length} paths found."

puts
puts "INVALID PATHS"

# Print out all error paths
error_paths.each do |error_path|
  puts error_path.join(",")
end
puts "#{error_paths.length} invalid paths."

