print("Running boot... heap=" .. node.heap());

local boot = requireModule("boot.lua");
boot.init();

local boot = requireModule("boot-startapp.lua");

boot.startup(function()
  collectgarbage();
  print("Starting App... heap=" .. node.heap());
  dofile("boot-startapp.lua").startApp(function(result)
    collectgarbage();
    print("App startup status: " .. result .. "; heap=" .. node.heap());
    if(_app ~= nil and _app.getInfo ~= nil) then
      print("App info: " .. _app.getInfo());
    end
  end);

end);
