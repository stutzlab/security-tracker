--TIMERS: 0 - tracker sampler
--        1 - connectivity loop
--        2 - connectivity timeout
--        3 - registration
--        4 - upload

events = dofile("util-events.lua");
dofile("app-connectivity");
dofile("app-utils.lua");
dofile("app-registration.lua");
dofile("app-tracking.lua");
dofile("app-upload.lua");

function startup()
  log.log("APP -- Starting Tracker App");
  _app_startTracking();
end

function shutdown()
  log.log("APP -- Shutting down Tracker App");
end
