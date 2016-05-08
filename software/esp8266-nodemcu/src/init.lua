--TIMER 6 - CAPTIVE PORTAL TIMEOUT
--TIMER 5 - INTERNET CONNECTION DETECTOR

print(">>> StutzThings <<<");
print("Enter 'x' to skip Bootstraper");

--global variable containing the launched App
_app = nil;

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
    local bootstrap = dofile("bootstrap.lua");

    bootstrap.startup(function()
      bootstrap = nil;--dealocate

      print("Starting App...");
      local startapp = dofile("bootstrap_start-app.lua");--4500
      startApp(function(result)
        startpapp = nil;--dealocate
        print("App startup status: " .. result);
      end);

      if(_app.getInfo ~= nil) then
        print("App info: " .. _app.getInfo());
      end

    end);

  else
    print("Skipping bootstrap.");
  end
end)

tmr.start(0);


-- PUBLIC FUNCTIONS (functions that can be invoked by apps)
function resetWatchdog()
  local watchdog = dofile("util-watchdog.lua");--5800
  watchdog.reset();
  watchdog = nil;--dealocate
end

function incrementWatchdog()
  local watchdog = dofile("util-watchdog.lua");--5800
  watchdog.increment();
  watchdog = nil;--dealocate
end
