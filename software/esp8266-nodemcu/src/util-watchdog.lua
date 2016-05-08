--heap 5800
if(log == nil) then
    log = dofile("util-log.lua");
end

local watchdogutils = {};

local watchdogCounter = 0;
local fileCounter = "_watchdog.counter";

function watchdogutils.setFile(filename)
  fileCounter = filename;
  init();
end

function watchdogutils.reset()
  file.open(fileCounter, "w+");
  file.write("0");
  file.close();
end

function watchdogutils.getCounter()
  local f = file.open(fileCounter, "r");
  if(not f) then
    file.close();
    log.log("WATCHDOG -- Creating '" .. fileCounter .. "' with '0' - " .. fileCounter);
    watchdogutils.reset();
    f = file.open(fileCounter, "r");
  end
  local watchdogCounter = file.read();
  file.close();
  return tonumber(watchdogCounter);
end

function watchdogutils.increment()
  local counter = watchdogutils.getCounter();
  file.open(fileCounter, "w+");
  counter = counter + 1;
  file.write(counter .. "");
  file.close();
end

function watchdogutils.isTriggered(counter)
  return watchdogutils.getCounter() >= counter;
end

function init()
  watchdogCounter = watchdogutils.getCounter();
  log.log("WATCHDOG -- Watchdog counter = " .. watchdogCounter .. " - " .. fileCounter);
end

init();

return watchdogutils;
