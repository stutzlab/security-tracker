__log("WATCHDOG -- Checking watchdog counter...");

global WATCHDOG_FILE_COUNTER = "bootstrap_watchdog.counter";

local watchdogCounter = _bootstrap_getWatchDogCounter();
__log("WATCHDOG -- Watchdog counter = " .. watchdogCounter);

function _bootstrap_resetWatchDogCounter() then
  file.open(WATCHDOG_FILE_COUNTER, "w+");
  file.write("0");
  file.close();
end

function _bootstrap_incrementWatchDogCounter() then
  local counter = _bootstrap_getWatchDogCounter();
  file.open(WATCHDOG_FILE_COUNTER, "w+");
  counter = counter + 1;
  file.write(counter);
  file.close();
end

function _bootstrap_isWatchDogTriggered(counter)
  return _bootstrap_getWatchDogCounter() > counter;
end

function _bootstrap_getWatchDogCounter() then
  local f = file.open(WATCHDOG_FILE_COUNTER, "r");
  if(not f) then
    file.close();
    __log("WATCHDOG -- Creating '" .. WATCHDOG_FILE_COUNTER .. "' with '0'");
    _bootstrap_resetWatchDogCounter();
    f = file.open(WATCHDOG_FILE_COUNTER, "r");
  end
  local watchdogCounter = file.read();
  file.close();
  return watchdogCounter;
end
