--heap 5800
if(log == nil) then
    log = dofile("util-log.lua");
end

local a = {};

local watchdogCounter = 0;
local fileCounter = "_watchdog.counter";

function a.setFile(filename)
  fileCounter = filename;
  init();
end

function a.reset()
  file.open(fileCounter, "w+");
  file.write("0");
  file.close();
end

function a.getCounter()
  local f = file.open(fileCounter, "r");
  if(not f) then
    file.close();
    log.log("WATCHDOG -- Creating '" .. fileCounter .. "' with '0' - " .. fileCounter);
    a.reset();
    f = file.open(fileCounter, "r");
  end
  local watchdogCounter = file.read();
  file.close();
  return tonumber(watchdogCounter);
end

function a.increment()
  local counter = a.getCounter();
  file.open(fileCounter, "w+");
  counter = counter + 1;
  file.write(counter .. "");
  file.close();
end

function a.isTriggered(counter)
  return a.getCounter() >= counter;
end

log.log("watchdog module loaded. heap=" .. node.heap());

return a;
