print("=======================================");
print("Booting StutzThings device");
print("reason=" .. node.bootreason());
print("=======================================");
print("");
dofile("bootstrap_config.lua");
dofile("bootstrap_utils.lua");
dofile("bootstrap_captive.lua");
dofile("bootstrap_watchdog.lua");
dofile("bootstrap_app-update.lua");
dofile("bootstrap_start-app.lua");

_bootstrap_startApp();
_bootstrap_checkForUpdates();


-- PUBLIC FUNCTIONS (functions that can be invoked by apps)

function bootstrap_activateCaptivePortal()
  _bootstrap_activateCaptivePortal();
end

function bootstrap_isCaptivePortalActive()
  return bootstrap_captive_activated;
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
