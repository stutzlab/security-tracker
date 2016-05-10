dofile("bootstrap-log.lua");--2100

local b = {};

function b.startup(callback)

  _b_log.log("");
  _b_log.log("===========================================");
  _b_log.log("**** Starting " .. dofile("bootstrap-config.lua").device_name .. " ****");
  _b_log.log("App URL: " .. dofile("bootstrap-config.lua").app_info_url);
  _b_log.log("Boot reason: " .. node.bootreason());
  _b_log.log("===========================================");
  _b_log.log("");

  local watchdog = dofile("util-watchdog.lua");--5800

  if(dofile("bootstrap-utils.lua").getAppInfoFromFile() == nil) then
      _b_log.log("BOOTSTRAP -- App file not found. Incrementing watchdog to force captive portal.");
      watchdog.increment();
      watchdog.increment();
      watchdog.increment();
  end

  if(watchdog.isTriggered(2)) then
    dofile("bootstrap-captive.lua").startCaptive();
  else
    b.startApp(callback);
  end
end


function b.updateApp(callback)
  local appupdate = dofile("bootstrap-appupdate.lua");--8800
  appupdate.checkForUpdates(function(result)
    appupdate = nil;--dealocate

    if(result=="app-updated") then
      _b_log.log("BOOTSTRAP - Restarting unit to activate new app version");
      dofile("util-watchdog.lua").reset();
      node.restart();

    elseif(result=="app-update-error") then
      _b_log.log("BOOTSTRAP - Update error. Skipping.");
      b.startApp(callback);

    elseif(result=="app-up-to-date") then
      _b_log.log("BOOTSTRAP - App is up-to-date");
      dofile("util-watchdog.lua").reset();
      b.startApp(callback);
    end

  end);
end

function b.startApp(callback)
  callback();
end

_b_log.log("bootstrap module loaded. heap=" .. node.heap());

return b;
