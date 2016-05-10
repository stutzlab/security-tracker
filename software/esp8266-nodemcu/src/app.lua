dofile("app-log.lua");

local a = {};

--TIMERS: 0 - tracker sampler
--        1 - internet connectivity
--        2 - registration and upload

local events = dofile("util-events.lua");
local connectivity = dofile("app-connectivity");
local utils = dofile("app-utils.lua");
--local registration = dofile("app-registration.lua");
local tracking = dofile("app-tracking.lua");
local upload = dofile("app-upload.lua");

local internetTaskCounter = 0;

function a.startup()
  log.log("APP -- Starting Tracker App");

  --try to upload gps data and app status continuously when Internet is available
  tmr.register(2, 2000, tmr.ALARM_MANUAL, function()
    dofile("util-connectivity.lua").isGoogleReacheable(1, 3000, function(isReacheable)
      dofile("app-registration.lua").checkAppRegistration(function(valid)

        --device connected to Internet
        if(isReacheable) then
          if(valid) then
            log.log("APP -- Device is connected to the Internet and has a valid registration");
            dofile("app-upload.lua").uploadDataToServer();
            tmr.start(2);
          else
            log.log("APP -- Device is connected to the Internet and needs registration. Starting captive portal.");
            dofile("app-registration.lua").startAppRegistration(function(event)
              if(event == "registration-ok") then
                log.log("REGISTRATION -- App registration successful");
              elseif(event == "registration-timeout") then
                log.log("REGISTRATION -- App registration timedout");
              end
              tmr.start(2);
            end);
          end

        --device not connected to Internet
        else
          log.log("APP -- Device is NOT connected to the Internet");
          if(not valid) then
            log.log("APP -- Registration not found. Incrementing watchdog and rebooting unit.");
            dofile("util-watchdog.lua").increment();
            node.reboot();
          else
            log.log("APP -- Device not connected to Internet but Registration found. Continuing.");
            tmr.start(2);
          end
        end
      end)

    end);
  end)
  tmr.start(2);

  --start recording gps samples
  tracking.start();
end

function a.shutdown()
  log.log("APP -- Shutting down Tracker App");
end

return a;
