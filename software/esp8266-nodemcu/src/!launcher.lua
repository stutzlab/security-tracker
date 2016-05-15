print("Running boot... heap=" .. node.heap());

dofile("_flashmod.lua");
local boot = requireModule("!boot.lua");
--local boot = requireModule("boot-startapp.lua");

boot.startup(function()
  collectgarbage();
  print("Starting App... heap=" .. node.heap());
  local runner = requireModule("!runner.lua");
  runner.startApp(function(result)
    collectgarbage();
    print("App startup status: " .. result .. "; heap=" .. node.heap());
  end);
end);
