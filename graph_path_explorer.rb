require 'rubygems'
require 'json/ext'

class GraphPathExplorer    
  # Read in a specification from a file
  def initialize(file)
    @all_edge_names = []
    @edges = {}
    @edge_name_graph = {}
    @final_edge_names = []
    @paths = nil
    @error_paths = nil
    
    # Get the JSON from the file and parse it
    data = ""
    File.open(file, "r") do |infile|
      while (line = infile.gets) 
        data += line
      end
    end
    specification = JSON.parse(data)
    
    @start = specification["start"]
    
    # Fill the graph description, with an additional "Start" state
    start = { "name" => "Start", "from" => nil, "to" => @start }
    specification["edges"].push(start)
    specification["edges"].each do |current|
      @edges[current["name"]] = current
      @all_edge_names.push current["name"]
      @final_edge_names.push current["name"] if specification["end"].include? current["to"]
      @edge_name_graph[current["name"]] = []
      specification["edges"].each do |edge|
        @edge_name_graph[current["name"]].push edge["name"] if current["to"].eql? edge["from"]
      end
    end
  end
  
  # Return valid paths, generating if necessary
  def valid_paths
    unless @paths
      @paths = []
      stack = []
      visited_paths = {}
      stack.push "Start"
      until stack.empty?
        edge_name = stack.last
        if @final_edge_names.include? edge_name and @paths.length > 0
          stack.pop
        else
          has_new_child_path = false
          @edge_name_graph[edge_name].each do |next_name|
            unless stack.include? next_name
              stack.push next_name
              hash = stack.join ","
              if visited_paths[hash]
                stack.pop
              else
                @paths.push snapshot(stack)
                visited_paths[hash] = true
                has_new_child_path = true
                break
              end
            end
          end
          stack.pop unless has_new_child_path
        end
      end
      @paths = @paths.find_all do |path| @final_edge_names.include? path.last end
      @paths = @paths.collect do |path| 
        path.collect do |edge_name| @edges[edge_name] end
      end
    end
    @paths
  end
  
  # Return error paths, generating paths and error paths if necessary
  def error_paths
    valid_paths unless @paths
    unless @error_paths
      @error_paths = []
      
      # Begin with transitions that don't begin at start node
      @all_edge_names.each do |edge_name|
        unless @edges[edge_name]["from"].eql? @start or edge_name.eql? "Start"
          @error_paths.push [edge_name]
        end
      end
      
      # Explore all possible error paths off subpaths of valid paths
      stack = []
      visited_paths = {}
      
      path_names = []
      @paths.each do |path|
        (1..(path.length)).each do |n|
          subpath = path.first(n).collect do |edge| edge["name"] end
          action = subpath.last       
          illegal_actions = @all_edge_names.find_all do |item| !@edge_name_graph[action].include? item end
          illegal_actions.each do |illegal_action|
            error_path = subpath + [illegal_action]
            key = error_path.join(",")
            unless visited_paths[key]
              visited_paths[key] = true
              @error_paths.push snapshot(error_path)
            end
          end
        end
      end
      @error_paths = @error_paths.collect do |path| 
        path.collect do |name| @edges[name] end
      end
    end
    @error_paths
  end  
  
  private
  
  # Deep array copy
  def snapshot(path) 
    ret = []
    path.each do |item| ret.push item end
    ret
  end
end












