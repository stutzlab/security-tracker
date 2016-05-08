dofile("bootstrap_log.lua");--2100

local b = {};

local utils = dofile("bootstrap_utils.lua");--3000
local config = dofile("bootstrap_config.lua");--1700
local watchdog = dofile("util-watchdog.lua");--5800

function b.startup(callback)

  _b_log.log("");
  _b_log.log("===========================================");
  _b_log.log("**** Starting " .. config.device_name .. " ****");
  _b_log.log("App URL: " .. config.app_info_url);
  _b_log.log("Boot reason: " .. node.bootreason());
  _b_log.log("===========================================");
  _b_log.log("");

  if(utils.getAppInfoFromFile() == nil) then
      _b_log.log("BOOTSTRAP -- App file not found. Incrementing watchdog to force captive portal.");
      watchdog.increment();
      watchdog.increment();
      watchdog.increment();
  end

  if(watchdog.isTriggered(2)) then
    _b_log.log("BOOTSTRAP -- Watchdog triggered. Activating captive portal. counter=" .. watchdog.getCounter());
    local rebootLoopDetected = watchdog.isTriggered(20);

    local captiveTimeout = 10000;
    if(rebootLoopDetected) then
      _b_log.log("BOOTSTRAP -- Reboot loop detected. Won't start App until internet connection is detected.");
      captiveTimeout = 0;
    end

    _b_log.log("Preparing to load util-captive. heap=" .. node.heap());
    parei aqui...
    watchdog = nil;--dealocate
    utils = nil;--dealocate
    config = nil;--dealocate
    
    _b_log.log("About to load util-captive. heap=" .. node.heap());
    local captive = dofile("util-captive.lua");--14216
    captive.start(captive.wifiLoginRequestHandler, captiveTimeout, function(event)

      if(event=="wifi_connect") then
      elseif(event=="captive_timeout") then
        _b_log.log("BOOTSTRAP -- Captive portal timeout");
        captive.stop();
        captive = nil;--dealocate

        b.startApp(callback);

      elseif(event=="internet_detected") then
        _b_log.log("BOOTSTRAP -- Internet connection detected");
        captive.stop();
        captive = nil;--dealocate

        b.updateApp(callback);
      end
    end);

  else
    b.startApp(callback);
  end
end


function b.updateApp(callback)
  local appupdate = dofile("bootstrap_app-update.lua");--8800
  appupdate.checkForUpdates(b.config, b.utils, function(result)
    appupdate = nil;--dealocate

    if(result=="app-updated") then
      _b_log.log("BOOTSTRAP - Restarting unit to activate new app version");
      watchdog.reset();
      node.restart();

    elseif(result=="app-update-error") then
      _b_log.log("BOOTSTRAP - Update error. Skipping.");
      b.startApp(callback);

    elseif(result=="app-up-to-date") then
      _b_log.log("BOOTSTRAP - App is up-to-date");
      watchdog.reset();
      b.startApp(callback);
    end

  end);
end

function b.startApp(callback)
  callback();
end

_b_log.log("bootstrap module loaded. heap=" .. node.heap());

return b;
