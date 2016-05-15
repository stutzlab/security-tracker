local a = {};

function a:init()
  self.vendor = dofile("!vendor.lua");
  self.constants = dofile("!constants.lua");

  self.updater = requireModule("!updater.lua");
  self.watchdog = requireModule("_watchdog.lua");
  self.logger = requireModule("_log.lua");
  self.captive = requireModule("_captive.lua");
  self.connectivity = requireModule("_connectivity.lua");
end

-- WIFI, REGISTRATION AND SANITY CHECKS

function a:startup(callback)

  local registration = self:getRegistration();

  self.logger:log("");
  self.logger:log("===========================================");
  self.logger:log("**** Starting " .. self.vendor.device_name .. " ****");
  self.logger:log("Default App URL: " .. self.vendor.default_app_info_url);
  if(registration ~= nil) then
    if(registration.account_id ~= nil) then
      self.logger:log("Device registered to " .. registration.account_id);
    end
    if(registration.custom_app_info_url ~= nil) then
      self.logger:log("Custom App URL: " .. registration.custom_app_info_url);
    end
  else
    self.logger:log("Device not registered yet");
  end
  self.logger:log("Boot reason: " .. node.bootreason());
  self.logger:log("===========================================");
  self.logger:log("");

  if(self:getAppInfoFromFile() == nil) then
    self.logger:log("BOOT -- App info file not found. Incrementing watchdog to force captive portal.");
    self.watchdog.increment();
    self.watchdog:increment();
    self.watchdog:increment();
  end

  if(self.watchdog:isTriggered(2)) then
    self:startCaptive(function()
      self:verifyRegistration(callback);
    end);

  else
    self:verifyRegistration(callback);
  end
end

function a:verifyRegistration(callback)
  self.connectivity:isGoogleReacheable(6, 1000, function(internetDetected)
    self:checkDeviceRegistration(internetDetected, function(validRegistration)

      --device connected to Internet
      if(internetDetected) then

        if(validRegistration) then
          self.logger:log("APP -- Device is connected to the Internet and has a valid registration");
          self.updater:tryUpdateAndStartApp();

        else
          self.logger:log("APP -- Device is connected to the Internet and needs registration. Starting captive portal.");

          self.logger:log("REGISTRATION -- Initiating captive portal for device registration");
          self.captive:start(self.regCaptiveHandler, 10000, function()

            if(event == "registration-ok") then
              self.logger:log("REGISTRATION -- Device registration successful");
              self.updater:tryUpdateAndStartApp(callback);

            elseif(event == "registration-timeout") then
              self.logger:log("REGISTRATION -- Device registration timeout. Incrementing watchdog and rebooting unit");
              self.watchdog:increment();
              node.reboot();
            end
          end)
        end

      else
        if(validRegistration) then
          self.logger:log("REGISTRATION -- Device has account registration but is not connected to Internet");
          self.runner:startApp(callback);

        else
          self.logger:log("REGISTRATION -- Device is NOT connected to the Internet and needs registration. Incrementing watchdog and rebooting unit.");
          self.watchdog:increment();
          node.reboot();
        end
      end

    end)
  end)
end

function a:checkDeviceRegistration(checkOnline, callback)

  self.logger:log("REGISTRATION -- Verifying Device registration");

  local registration = self:getRegistration();
  if(registration ~= nil)  then
    self.logger:log("REGISTRATION -- Registration file found");

    if(checkOnline) then

      self.logger:log("REGISTRATION -- Verifying registration status on server. app-uid=" .. registration.app-uid);
      http.get(app-URL_APPS .. "/" .. registration.app-uid, nil, function(code, data)
        if (code == 404) then
          self.logger:log("REGISTRATION -- app-uid not found. app-uid=" .. registration.app-uid);
          callback(false);

        elseif (code == 200) then
          self.logger:log("REGISTRATION -- app-uid found. response=" .. registrationResponse);
          local registrationResponse = cjson.decode(data);

          if(registrationResponse.status == "active" and registrationResponse.account_id) then
            self.logger:log("REGISTRATION -- Device registration is VALID");
            self.logger:log("REGISTRATION -- Sending device status to server");
            local remaining, used, total = file.fsinfo();
            local appStatus = {
              node_bootreason = node.bootreason(),
              node_heap = node.heap(),
              boot_watchdogcounter = self.watchdog:getCounter(),
              fsinfo_remaining = remaining,
              fsinfo_used = used,
              fsinfo_total = total
            };
            http.put(app-URL_APPS .. "/" .. registration.app-uid .. "/status",
              "Content-Type: application/json\r\n",
              cjson.encode(appStatus), function(code, data)
                if (code == 200) then
                  self.logger:log("REGISTRATION -- App status POST successful.");
                else
                  self.logger:log("REGISTRATION -- App status POST failed. code=" .. code);
                end
                callback(true);
            end);
          else
            self.logger:log("REGISTRATION -- App registration is INVALID");
            callback(false);
          end

        else
          self.logger:log("REGISTRATION -- Error getting app-uid info. Trusting configuration data from disk without verifying on cloud. code=" .. code .. "; response=" .. registrationResponse);
          callback(true);
        end

      end);

    else
      self.logger:log("REGISTRATION -- Configuration file found. Skipping online check.");
      callback(true);
    end

  else
    self.logger:log("REGISTRATION -- Registration file not found");
    callback(false);
  end

end

function a:getRegistration()
  if(file.open(self.constants.REGISTRATION_FILE, "r")) then
    local rj = file.read();
    local registration = cjson.decode(rj);
    file.close();
    self.logger:log("BOOT -- Registration file found");
    return registration;
  else
    self.logger:log("BOOT -- Registration file not found");
    return nil;
  end
end

function a:startCaptive(callback)
  self.logger:log("BOOT -- Activating captive portal");
  local rebootLoopDetected = self.watchdog:isTriggered(20);

  local captiveTimeout = 10000;
  if(rebootLoopDetected) then
    self.logger:log("BOOT -- Reboot loop detected. Won't start App until internet connection is detected.");
    captiveTimeout = 0;--no timeout
  end

  self.logger:log("About to start captive portal. heap=" .. node.heap());
  self.captive:start(
    self.vendor.wifi_captive_ssid,
    self.captive.wifiLoginRequestHandler,
    captiveTimeout, function(callback)
      if(event=="wifi_connect") then
        self.logger:log("BOOT -- Wifi connected");

      elseif(event=="captive_timeout") then
        self.logger:log("BOOT -- Captive portal timeout");
      end

      --stop captive portal
      self.captive:stop();
      collectgarbage();
      self.logger:log("BOOT -- Captive portal stopped");
    end);
end

--start captive portal for getting account credentials
function a:regCaptiveHandler(path, params, responseCallback)
  local buf = "";
  local mimeType = "application/json";
  local httpStatus = "200 OK";
  local event = nil;

  if(path == "" or path == "/") then
    mimeType = "text/html";
    file.open("util-captive-wifi.html", "r");
    buf = file.read();
    file.close();
    responseCallback(httpStatus, mimeType, buf, event);

  elseif(path == "/register") then
    if(params.username and params.password) then

      --register new app instance
      http.post(URL_DEVICES,
        "Content-Type: application/json\r\n",
        cjson.encode({account_id=params.username, account_password=params.password, hw_id=node.chipid()}),
        function(code, data)
          if (code == 201) then

            self.logger:log("REGISTRATION -- Device registration successful. response=" .. data);
            local response = cjson.decode(data);
            local registration = {
              app_uid = response.app_uid,
              account_id = response.account_id,
              access_token = response.access_token,
              refresh_token = response.refresh_token
            }

            local fo = file.open(self.constants.REGISTRATION_FILE, "w+");
            if(fo) then
              if(file.write(cjson.encode(registration))) then
                self.logger:log("REGISTRATION -- Registration data written to disk. Registration successful.");
                buf = "{'result':'OK','message':'Registration created on cloud server and written to disk. Success!'}";
                httpStatus = "201 Created";
                event = "registration-ok";

              else
                self.logger:log("REGISTRATION -- Registration data could not be written to disk. Registration failed.");
                buf = "{'result':'ERROR','message':'Registration data could not be written to disk. Registration failed.'}";
                httpStatus = "500 Internal Server Error";
              end
            else
              self.logger:log("REGISTRATION -- Could not open registration file for writing. Registration failed.");
              buf = "{'result':'ERROR','message':'Could not open registration file for writing. Registration failed.'}";
              httpStatus = "500 Internal Server Error";
            end
            file.close();

          else
            self.logger:log("REGISTRATION -- App registration failed. code=" .. code .. "; data=" .. data);
            buf = "{'result':'ERROR','message':'App registration on cloud server failed. remote server code=" .. code .. "; server response data=" .. data .. "'}";
            httpStatus = "400 Bad Request";
          end
      end);

    else
      buf = "{'result':'ERROR','message':'Registration need username and password'}";
      httpStatus = "400 Bad Request";
    end

  else
    buf = "{'result':'ERROR','message':'Resource not found'}";
    httpStatus = "404 Not Found";
  end

  responseCallback(httpStatus, mimeType, buf, event);
end

function a:performFactoryReset()
  self.logger:log("BOOT -- Reseting device to factory state...");
  local fl = file.list();
  for k,v in pairs(fl) do
    if(strsub(k,1,1) ~= "!" and strsub(k,1,1) ~= "_") then
      self.logger:log("BOOT -- Removing file " .. k .. "; size=" .. v);
      file.remove(k);
    end
  end
  watchdog.reset();
  self.logger:log("BOOT -- Factory reset done. All non boot files were removed (including App package and data).");
end


function a:getAppInfoFromFile()
  if(file.open("app.info", "r")) then
    local _contents = file.read();
    file.close();
    return cjson.decode(_contents);
  else
    self.logger:log("BOOT -- File 'app.info' not found");
    return nil;
  end
end

function a:startApp(callback)
  callback();
end

self.logger:log("Boot module loaded. heap=" .. node.heap());

return a;
