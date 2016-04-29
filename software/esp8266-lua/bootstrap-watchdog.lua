print("WATCHDOG -- Checking watchdog counter...");

global WATCHDOG_FILE_COUNTER = "bootstrap_watchdog.counter";

local watchdogCounter = bootstrap_getWatchDogCounter();
print("WATCHDOG -- Watchdog counter = " .. watchdogCounter);

if(watchdogCounter > 3) then
  print("WATCHDOG -- DETECTED FAULT. ACTIVATING CAPTIVE PORTAL. COUNTER = " .. watchdogCounter);
  bootstrap_activateCaptivePortal();
end


function _bootstrap_resetWatchDogCounter() then
  file.open(WATCHDOG_FILE_COUNTER, "w+");
  file.write("0");
  file.close();
end

function _bootstrap_incrementWatchDogCounter() then
  local counter = bootstrap_getWatchDogCounter();
  file.open(WATCHDOG_FILE_COUNTER, "w+");
  counter = counter + 1;
  file.write(counter);
  file.close();
end

function bootstrap_getWatchDogCounter() then
  local f = file.open(WATCHDOG_FILE_COUNTER, "r");
  if(not f) then
    file.close();
    print("WATCHDOG -- Creating '" .. WATCHDOG_FILE_COUNTER .. "' with '0'");
    _bootstrap_resetWatchDogCounter();
    f = file.open(WATCHDOG_FILE_COUNTER, "r");
  end
  local watchdogCounter = file.read();
  file.close();
  return watchdogCounter;
end
