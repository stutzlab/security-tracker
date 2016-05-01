dofile("bootstrap_config.lua");
__log("===========================================");
__log(">>>>> " .. _bootstrap_config.device-name .. " <<<<<");
__log("App URL: " .. _bootstrap_config.app-update_info-url);
__log("Boot reason: " .. node.bootreason());
__log("===========================================");
__log("");
dofile("bootstrap_utils.lua");
dofile("bootstrap_captive.lua");
dofile("bootstrap_watchdog.lua");
dofile("bootstrap_app-update.lua");
dofile("bootstrap_start-app.lua");

_bootstrap_checkForUpdates();

if(_bootstrap_isWatchDogTriggered(2)) then
  __log("WATCHDOG -- DETECTED DANGEROUS STATUS. ACTIVATING CAPTIVE PORTAL. COUNTER = " .. bootstrap_getWatchDogCounter());
  bootstrap_activateCaptivePortal(_bootstrap_wifiLoginRequestHandler);
end

if(_bootstrap_isWatchDogTriggered(20)) then
  __log("WATCHDOG -- DETECTED APP REBOOT LOOP. APPLICATION WON'T BE LOADED UNTIL CAPTIVE PORTAL CONFIG IS DONE. COUNTER = " .. bootstrap_getWatchDogCounter());
else
  _bootstrap_startApp();
end



-- PUBLIC FUNCTIONS (functions that can be invoked by apps)

function bootstrap_isConnectedToInternet(callback)
  _bootstrap_isConnectedToInternet(callback);
end

function bootstrap_getLogs()
  return _bootstrap_getLogs();
end

function bootstrap_activateCaptivePortal(requestHandler)
  _bootstrap_activateCaptivePortal(requestHandler);
end

function bootstrap_isCaptivePortalActive()
  return _bootstrap_captive_activated;
end

function bootstrap_checkForUpdates()
  _bootstrap_checkForUpdates();
end

function bootstrap_resetWatchDog()
  _bootstrap_resetWatchDogCounter();
end

function bootstrap_forceCaptivePortal()
  _bootstrap_incrementWatchDogCounter();
  _bootstrap_incrementWatchDogCounter();
  _bootstrap_incrementWatchDogCounter();
  _bootstrap_incrementWatchDogCounter();
  bootstrap_activateCaptivePortal();
end
