dofile("bootstrap-log.lua");--2100

local b = {};

function b.startup(callback)

  local config = dofile("bootstrap-config.lua");
  _b_log.log("");
  _b_log.log("===========================================");
  _b_log.log("**** Starting " .. dofile("bootstrap-config.lua").device_name .. " ****");
  if(config.app_custom_info_url == nil) then
    _b_log.log("App default URL: " .. config.app_default_info_url);
  else
    _b_log.log("App custom URL: " .. config.app_custom_info_url);
  end
  _b_log.log("App default URL: " .. dofile("bootstrap-config.lua").app_default_info_url);
  _b_log.log("Boot reason: " .. node.bootreason());
  _b_log.log("===========================================");
  _b_log.log("");
  config = nil;

  local watchdog = dofile("util-watchdog.lua");

  if(dofile("bootstrap-utils.lua").getAppInfoFromFile() == nil) then
      _b_log.log("BOOTSTRAP -- App file not found. Incrementing watchdog to force captive portal.");
      watchdog.increment();
      watchdog.increment();
      watchdog.increment();
  end

  if(watchdog.isTriggered(2)) then
    dofile("bootstrap-captive.lua").startCaptive(function(event)

      if(event=="wifi_connect") then
        _b_log.log("BOOTSTRAP -- Wifi connected");

      elseif(event=="captive_timeout") then
        _b_log.log("BOOTSTRAP -- Captive portal timeout");
      end

      --stop captive portal
      captive.stop();
      captive = nil;--dealocate
      collectgarbage();

      b.verifyRegistrationAndStartApp(callback);
    end);

  else
    b.verifyRegistrationAndStartApp(callback);
  end
end

function b.verifyRegistrationAndStartApp()
  dofile("util-connectivity.lua").isGoogleReacheable(6, 1000, function(internetDetected)
    dofile("bootstrap-registration.lua").checkAppRegistration(function(validRegistration)

      --device connected to Internet
      if(internetDetected) then

        if(validRegistration) then
          log.log("APP -- Device is connected to the Internet and has a valid registration");
          b.tryUpdateAndStartApp();

        else
          log.log("APP -- Device is connected to the Internet and needs registration. Starting captive portal.");

          dofile("bootstrap-registration.lua").startAppRegistration(function(event)

            if(event == "registration-ok") then
              log.log("REGISTRATION -- App registration successful");
              b.tryUpdateAndStartApp();

            elseif(event == "registration-timeout") then
              log.log("REGISTRATION -- App registration timeout. Incrementing watchdog and rebooting unit");
              dofile("util-watchdog.lua").increment();
              node.reboot();
            end
          end);
        end

      else

        if(validRegistration) then
          log.log("APP -- Device has account registration but is not connected to Internet");
          b.startApp(callback);

        else
          log.log("APP -- Device is NOT connected to the Internet and needs registration. Incrementing watchdog and rebooting unit.");
          dofile("util-watchdog.lua").increment();
          node.reboot();

        end
      end
      
    end)
  end)

end

function b.tryUpdateAndStartApp()
  local registration = dofile("bootstrap-registration.lua").getRegistration();
  if(registration == nil) then
    log.log("BOOTSTRAP -- Registration not found. Strange. Rebooting unit.");
    dofile("util-watchdog.lua").increment();
    node.reboot();
  else
    b.updateApp(registration, callback);
  end
end

function b.updateApp(registration, callback)

  local appInfoUrl = registration.app_custom_info_url;
  if(appInfoUrl == nil) then
    log.log("BOOTSTRAP -- Using default info url for app update. ");
    appInfoUrl = registration.app_default_info_url;
  else
    log.log("BOOTSTRAP -- Using custom info url for app update");
  end
  log.log("BOOTSTRAP -- Updating app. appInfoUrl=" .. appInfoUrl);


  dofile("bootstrap-appupdate.lua").checkForUpdates(appInfoUrl, function(result)

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

_b_log.log("Bootstrap module loaded. heap=" .. node.heap());

return b;
