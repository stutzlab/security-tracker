--TIMERS: 0 - tracker sampler
--        1 - connectivity loop
--        2 - connectivity timeout
--        3 - registration
--        4 - upload

global events = dofile("util-eventlistener.lua");

dofile("util-events.lua");
dofile("util-lock.lua");
dofile("app-connectivity");
dofile("util-storage.lua");
dofile("app-utils.lua");
dofile("app-registration.lua");
dofile("app-tracking.lua");
dofile("app-upload.lua");

function startup()
  __log("APP -- Starting Tracker App");
  _app_startTracking();
end

function shutdown()
  __log("APP -- Shutting down Tracker App");
end
