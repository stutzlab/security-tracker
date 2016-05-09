print("Running bootstrap... heap=" .. node.heap());
dofile("bootstrap.lua").startup(function()  
  collectgarbage();
  print("Starting App... heap=" .. node.heap());
  --4500
  dofile("bootstrap_start-app.lua").startApp(function(result)
    collectgarbage();
    print("App startup status: " .. result .. "; heap=" .. node.heap());
    if(_app ~= nil and _app.getInfo ~= nil) then
      print("App info: " .. _app.getInfo());
    end
  end);

end);
