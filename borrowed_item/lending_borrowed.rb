require File.dirname(__FILE__) + "/../graph_path_explorer"

$current_user = :none

# Set up
def generate_setup
  puts "public void setUp() {"
  puts "\ttry {"
  puts "\t\tLockerService.resetLocker();"
  puts "\t\tlender = randomAccount();"
  puts "\t\tlendee = randomAccount();"
  puts "\t\tcreateAccount(lender, null);"
  puts "\t\tcreateAccount(lendee, null);"
  puts "\t\tlenderDevice = randomDeviceId();"
  puts "\t\tlendeeDevice = randomDeviceId();"
	puts "\t\tDeviceService.register(lender.getEmail(), lender.getPassword(), randomDeviceId(), DEVICE_NAME, null, null);"
	puts "\t\tcreateCreditCard(randomCreditCard(), null);"
	puts "\t\tupdateCreditCardBillingAddress(randomBillingAddress(), null);"
	puts "\t\tStoreService.purchaseProduct(StoreService.getProduct(\"9781602150591\"));"
	puts "\t\tLockerService.synchronize();"
	puts "\t\tproduct = LockerService.getContent(\"9781602150591\");"
	puts "\t\tassertTrue(product != null);"
	puts "\t\tassertTrue(LockerService.getProductState(product) != null);"
	puts "\t\tLockerService.resetLocker();"
  puts "\t\tProxyFactory.getDefaultProxy().clearCookies();"
  puts "\t} catch (Exception e) {"
  puts "\t\t e.printStackTrace(); assertTrue(false);"
  puts "\t}"
  puts "}"
end

# Each path
def generate_test(path) 
  title = path.collect do |edge| edge["name"] end.join("")
  puts "public void test#{title}() throws Exception {"
  puts "\tSystem.out.println(\"Testing #{title}\");"
  path.each_index do |i|
    if i > 0
      previous = path[i-1]
      current = path[i]
      
      legal = previous["to"].eql? current["from"]
      if legal 
        code_to_transition(current, "null")
        code_to_verify(current["to"]) 
      else
        code_to_transition(current, "WebserviceException.class")
        code_to_verify(previous["to"])
      end
    end
  end
  puts "}"
  puts
end

#TODO switching lender versus lendee
def code_to_transition(edge, expected)
  code = case edge["name"]    
    when "Offer" then 
      switch_user(:lender) + 
      "\tlendProduct(product, lendee.getEmail(), #{expected});\n" 
    when "Return" then 
      switch_user(:lendee) +
      "\treturnLend(product, #{expected});"
    when /Accept/ then 
      switch_user(:lendee) +
      "\tdecideLend(product, true, #{expected});"
    when /Reject/ then 
      switch_user(:lendee) +
      "\tdecideLend(product, false, #{expected});"
    when "View" then 
      switch_user(:lendee) +
      "\tviewLend(product, #{expected});"
    when /Purchase/ then 
      switch_user(:lendee) +
      "\tpurchaseProduct(product, #{expected});"
    when "Start" then ""
    else 
      puts "No expiration yet! #{edge["name"]}"
      Process.exit(-1)
  end
  puts "\t#{log($current_user.to_s + " " + edge["name"])}"
  puts code
  puts "\tLockerService.synchronize();"
end

def code_to_verify(state)
  code = case state
    when "None" then
      switch_user(:lendee) +
      "\t#{log("Should be ABSENT")}\n" + 
      "\tassertTrue(LockerService.getContent(product.getEan()) == null);\n"
    when "PendingBorrowed" then
      switch_user(:lendee) +
      "\t#{log("Should be PENDING_BORROW")}\n" +
      "\tSystem.out.println(\"Current state is \" + LockerService.getProductState(product).getLendingState());\n" +
      "\tassertTrue(LockerService.getProductState(product).getLendingState().equals(LendingState.PENDING_BORROW));\n"
    when "Accepted" then
      switch_user(:lendee) +
      "\t#{log("Should be BORROWED")}\n" +
      "\tSystem.out.println(\"Current state is \" + LockerService.getProductState(product).getLendingState());\n" +
      "\tassertTrue(LockerService.getProductState(product).getLendingState().equals(LendingState.BORROWED));\n"
    when "PendingViewed" then
      switch_user(:lendee) +
      "\t#{log("Should be PENDING_VIEWED")}\n" +
      "\tSystem.out.println(\"Current state is \" + LockerService.getProductState(product).getLendingState());\n" +
      "\tassertTrue(LockerService.getProductState(product).getLendingState().equals(LendingState.PENDING_VIEWED));\n"
    when "Expired" then
      switch_user(:lendee) +
      "\t#{log("Should be EXPIRED")}\n" +
      "\tSystem.out.println(\"Current state is \" + LockerService.getProductState(product).getLendingState());\n" +
      "\tassertTrue(LockerService.getProductState(product).getLendingState().equals(LendingState.EXPIRED));\n"
    when "Returned" then
      switch_user(:lendee) +
      "\t#{log("Should be RETURNED")}\n" +
      "\tSystem.out.println(\"Current state is \" + LockerService.getProductState(product).getLendingState());\n" +
      "\tassertTrue(LockerService.getProductState(product).getLendingState().equals(LendingState.RETURNED));\n"
    else # Deleted
      switch_user(:lendee) +
      "\t#{log("Should be ABSENT")}\n" +
      "\tassertTrue(LockerService.getContent(product.getEan()) == null);\n"
  end
  puts code
end

def switch_user(user) 
  retval = ""
#  unless $current_user.eql? user
#    $current_user = user
    retval = "\t#{log("Switching to #{user.to_s}")}\n" + 
    "\tLockerService.resetLocker();\n" +
    "\tProxyFactory.getDefaultProxy().clearCookies();\n" +
    "\tDeviceService.register(#{user.to_s}.getEmail(), #{user.to_s}.getPassword(), #{user.to_s}Device, DEVICE_NAME, null, null);\n" +
    "\tLockerService.synchronize();\n"
#  end
  retval
end

def log(message)
  "System.out.println(\"#{message}\");"  
end

graph = GraphPathExplorer.new("lending_borrowed.json");
generate_setup
graph.valid_paths.each do |path| 
  unless path.find do |edge| /Expire/.match edge["name"] end
    generate_test path
  end
end
puts "#{graph.valid_paths.length} valid paths."

#graph.error_paths.each do |path|
#  unless path.find do |edge| /Expire/.match edge["name"] end
#    generate_test path
#  end
#end