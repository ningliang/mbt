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

def arr_equals(arr1, arr2) 
  return false unless arr1.length == arr2.length
  equals = true
  arr1.each_index do |i|
    equals = equals && (arr1[i] == arr2[i])
    break unless equals
  end
  equals
end

def path_exists(path_array, path)
  found = path_array.find do |existing_path| arr_equals(existing_path, path) end
  !found.nil?
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
edges = {}
stack = []
paths = []

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
        if path_exists(paths, stack)
          stack.pop
        else
          paths.push snapshot(stack)
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

puts edge_name_graph.to_json

# Print out all paths
paths.each do |path|
  path_string = path.join ","
  puts path_string
end

puts "#{paths.length} paths found."