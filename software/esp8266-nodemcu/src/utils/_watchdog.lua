local a = {};

function a:init()
  self.fileCounter = "_watchdog.counter";
end

function a:setFile(filename)
  self.fileCounter = filename;
end

function a:reset()
  file.open(fileCounter, "w+");
  file.write("0");
  file.close();
end

function a:getCounter()
  local f = file.open(self.fileCounter, "r");
  if(not f) then
    file.close();
    log.log("WATCHDOG -- Creating '" .. fileCounter .. "' with '0' - " .. fileCounter);
    a.reset();
    f = file.open(self.fileCounter, "r");
  end
  local watchdogCounter = file.read();
  file.close();
  return tonumber(watchdogCounter);
end

function a:increment()
  local counter = a.getCounter();
  file.open(self.fileCounter, "w+");
  counter = counter + 1;
  file.write(counter .. "");
  file.close();
end

function a:isTriggered(counter)
  return a:getCounter() >= counter;
end

return a;
