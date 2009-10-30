require File.dirname(__FILE__) + "/../graph_path_explorer.rb"

def generate_valid_path(path) 
  puts ""
  names = path.collect do |transition| transition["name"] end
  puts "public void test#{names.to_s}() throws Exception {"
  path.each do |transition|    
    puts "\t#{transition["name"].downcase}Product(null);" unless transition["name"].eql? "Start"
    puts "\tverify(\"#{transition["to"]}\");"
  end
  puts "}"
end

def generate_invalid_path(path)
  puts ""
  names = path.collect do |transition| transition["name"] end
  puts "public void test#{names.to_s}() throws Exception {"
  (0..(path.length - 2)).each do |index|
    transition = path[index]
    puts "\t#{transition["name"].downcase}Product(null);" unless transition["name"].eql? "Start"
    puts "\tverify(\"#{transition["to"]}\");"
  end
  transition = path.last
  puts "\t#{transition["name"].downcase}Product(Exception.class);" unless transition["name"].eql? "Start"
  puts "\tverify(\"#{transition["to"]}\");"
  puts "}"
end

explorer = GraphPathExplorer.new("lending_borrowed.json")

puts "// VALID PATHS"

explorer.valid_paths.each do |path| 
  # We cannot programmatically call expire
  generate_valid_path(path) unless path.find do |transition| transition["name"].eql? "Expire" end
end

puts "// INVALID PATHS"

explorer.invalid_paths.each do |path| 
  # We cannot programmatically call expire
  generate_invalid_path(path) unless path.find do |transition| transition["name"].eql? "Expire" end
end

puts "#{explorer.valid_paths.length} valid paths and #{explorer.invalid_paths.length} invalid paths"