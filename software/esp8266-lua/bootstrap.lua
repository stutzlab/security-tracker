dofile("bootstrap-config.lua");

-- CAPTIVE PORTAL
dofile("bootstrap-captive.lua");


-- WATCHDOG
dofile("bootstrap-watchdog.lua");


-- APP STARTUP
dofile("bootstrap-start_app.lua");


-- APP UPDATE
dofile("bootstrap-app_update.lua");


-- PUBLIC FUNCTIONS
function bootstrap_activateCaptivePortal()
  _bootstrap_activateCaptivePortal();
end

function bootstrap_resetWatchDog()
  _bootstrap_resetWatchDogCounter();
end
