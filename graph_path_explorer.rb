require 'rubygems'
require 'json/ext'

# TODO handle cycles
class GraphPathExplorer
  START = "Start"
  START_NODE = "Start"
  
  def initialize(file) 
    # Start, ends, results
    @start = nil
    @ends = nil
    @valid_paths = nil
    @invalid_paths = nil
        
    # Graph table (node -> [{name: edge_name, state: destination}])
    @transitions = {}
    @invalid_transitions = {}
    
    # Get the JSON from the file and parse it
    data = ""
    File.open(file, "r") do |infile|
      while (line = infile.gets) 
        data += line 
      end
    end
    specification = JSON.parse(data)
    
    @ends = specification["end"]
    @start = specification["start"]
    
    # Fill the graph description
    start = { "name" => START, "transitions" => [{"from" => START_NODE, "to" => @start }] }
    specification["edges"].push(start)
    specification["edges"].each do |current|
      name = current["name"]
      current["transitions"].each do |transition|
        from = transition["from"]
        to = transition["to"]
        @transitions[from] = [] unless @transitions[from]
        @transitions[from].push({ "name" => name, "to" => to })
      end
    end
    
    # Fill invalid transitions
    @transitions.keys.each do |node|
      @invalid_transitions[node] = []
      specification["edges"].each do |current|
        legal = false
        name = current["name"]
        current["transitions"].each do |transition|
          legal = true if transition["from"].eql? node
        end
        @invalid_transitions[node].push(edge(name, node, node)) unless legal
      end
    end
  end
  
  def valid_paths
    unless @valid_paths
      @valid_paths = []   # Saved paths
      stack = []    # Exploration stack
      node = nil    # Current node
      visited = {}
      
      # Take the first path
      node = @start
      stack.push( edge(START, nil, node) )
      visited[stack.to_json] = true
      
      until stack.empty?
        new_path = false
        if @transitions.has_key?(node)
          for transition in @transitions[node]
            # Save info
            name = transition["name"]
            to = transition["to"]
            from = node
            
            stack.push(edge(name, from, to))
            if visited.has_key?(stack.to_json)
              stack.pop
            else
              visited[stack.to_json] = true
              new_path = true
              node = to 
              @valid_paths.push(snapshot(stack))
              break
            end
          end
        end
        
        unless new_path
          old_edge = stack.pop
          node = old_edge["from"]
        end
      end
      
      @valid_paths = @valid_paths.find_all do |path|
        transition = path.last
        @ends.include? transition["to"]
      end      
    end
    @valid_paths
  end
  
  def invalid_paths
    unless @invalid_paths
      @invalid_paths = []
      visited = {}
      
      # For each subpath starting at beginning
      valid_paths.each do |path|
        for length in 1..(path.length)
          subarray = path[0, length]
          state = subarray.last["to"]
          
          # For each illegal transition from the last state
          if @invalid_transitions.has_key? state
            for transition in @invalid_transitions[state]
              new_subpath = snapshot(subarray)
              new_subpath.push(transition)
              
              # If new, save it and mark it visited
              unless visited.has_key? new_subpath.to_json
                visited[new_subpath.to_json] = true
                @invalid_paths.push(new_subpath)
              end
            end
          end          
        end
      end
      
      @invalid_paths = @invalid_paths.find_all do |path|
        path.last["name"] != START
      end
    end
    @invalid_paths
  end
  
  # Deep array copy
  def snapshot(path) 
    ret = []
    path.each do |item| ret.push item end
    ret
  end
  
  # Construct an edge
  def edge(name, from, to) 
    {"name" => name, "from" => from, "to" => to}
  end
end










