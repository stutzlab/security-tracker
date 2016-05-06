print(">>> StutzThings <<<");
print("Enter 'x' to skip Bootstraper");

local runBootstrap = true;

uart.setup(0,9600,8,0,1,0);
uart.on("data", 0, function(data)
  if(data == "x" or data == "X") then
    runBootstrap = false;
  end
end);

tmr.register(0, 1000, tmr.ALARM_SINGLE, function()
  --unregister callback
  uart.on("data");

  if(runBootstrap) then
    print("Running bootstrap...");
    dofile("bootstrap.lua");
  else
    print("Skipping bootstrap.");
  end
end)

tmr.start(0);
