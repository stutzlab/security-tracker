dofile("app-utils.lua");
dofile("app-registration.lua");
dofile("app-tracking.lua");
dofile("app-upload.lua");

function startup()
  __log("APP -- Starting Tracker App");

  _app_checkAppRegistration(function(registration)
    _app_startTracking(registration);
  end);

end

function shutdown()
  __log("APP -- Shutting down Tracker App");
end
