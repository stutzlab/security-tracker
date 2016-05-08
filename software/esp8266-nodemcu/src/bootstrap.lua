dofile("bootstrap_log.lua");--2100

local b = {};

local b.utils = dofile("bootstrap_utils.lua");--3000
local b.config = dofile("bootstrap_config.lua");--1700
local b.watchdog = dofile("util-watchdog.lua");--5800

_b_log.log("===========================================");
_b_log.log(">>>>> " .. _bootstrap_config.device-name .. " <<<<<");
_b_log.log("App URL: " .. _bootstrap_config.app-update_info-url);
_b_log.log("Boot reason: " .. node.bootreason());
_b_log.log("===========================================");
_b_log.log("");


function b.startup(callback)

  if(b.watchdog.isTriggered(2)) then
    _b_log.log("BOOTSTRAP -- Watchdog triggered. Activating captive portal. counter=" .. b.watchdog.getCounter());
    local rebootLoopDetected = b.watchdog.isTriggered(20);

    local captiveTimeout = 10000;
    if(rebootLoopDetected) then
      _b_log.log("BOOTSTRAP -- Reboot loop detected. Won't start App until internet connection is detected.");
      captiveTimeout = 0;
    end

    local captive = dofile("util_captive.lua");--14216
    captive.start(captive.wifiLoginRequestHandler, captiveTimeout, function(event)

      if(event=="wifi_connect") then
      elseif(event=="captive_timeout")
        _b_log.log("BOOTSTRAP -- Captive portal timeout");
        captive.stop();
        captive = nil;--dealocate

        startApp(callback);

      elseif(event=="internet_detected")
        _b_log.log("BOOTSTRAP -- Internet connection detected");
        captive.stop();
        captive = nil;--dealocate

        updateApp(callback);
      end
    end);

  else
    startApp(callback);
  end
end


function b.updateApp(callback)
  local appupdate = dofile("bootstrap_app-update.lua");--8800
  appupdate.checkForUpdates(b.config, b.utils, function(result)
    appupdate = nil;--dealocate

    if(result=="app-updated") then
      _b_log.log("BOOTSTRAP - Restarting unit to activate new app version");
      b.watchdog.reset();
      node.restart();

    elseif(result=="app-update-error")
      _b_log.log("BOOTSTRAP - Update error. Skipping.");
      b.startApp(callback);

    elseif(result=="app-up-to-date")
      _b_log.log("BOOTSTRAP - App is up-to-date");
      b.watchdog.reset();
      b.startApp(callback);
    end

  end);
end

function b.startApp(callback)
  callback();
end
