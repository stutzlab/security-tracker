dofile("boot-log.lua");

local b = {};

--APP INFO FILE
--global boot-app-info = {
--  name = "undefined",
--  version = "undefined",
--  hash = "AAA",
--  contents-ssl = false,
--  contents-host = "tracker.stutzthings.com",
--  contents-port = 80,
--  contents-path = "/tracker/devices/hw1.0/app-contents",
--  contents-size = 72434,
--  sanity = "OK"
--};

function b:init()
  self.APP_FILE = "app.lua",
  self.INFO_FILE = "app.info"
  self.REGISTRATION_FILE = "registration.json"
  self.URL_DEVICES = "http://tracker.stutzthings.com/tracker/devices/";


  self.watchdog = requireModule("util-watchdog.lua");
  self.logger = requireModule("util-log.lua");
  self.captive = requireModule("util-captive.lua");
  self.connectivity = requireModule("util-connectivity.lua");

  self.vendor = dofile("vendor.lua");
end

function b:startup(callback)

  local registration = self:getRegistration();

  self.logger:log("");
  self.logger:log("===========================================");
  self.logger:log("**** Starting " .. self.vendor.device_name .. " ****");
  self.logger:log("Default App URL: " .. self.vendor.app_default_info_url);
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

function b.verifyRegistration(callback)
  self.connectivity:isGoogleReacheable(6, 1000, function(internetDetected)
    self:checkDeviceRegistration(internetDetected, function(validRegistration)

      --device connected to Internet
      if(internetDetected) then

        if(validRegistration) then
          self.logger:log("APP -- Device is connected to the Internet and has a valid registration");
          self:tryUpdateAndStartApp();

        else
          self.logger:log("APP -- Device is connected to the Internet and needs registration. Starting captive portal.");

          self.logger:log("REGISTRATION -- Initiating captive portal for device registration");
          self.captive:start(
                self.regCaptiveHandler,
                10000,
                callback)

            if(event == "registration-ok") then
              self.logger:log("REGISTRATION -- Device registration successful");
              self:tryUpdateAndStartApp();

            elseif(event == "registration-timeout") then
              self.logger:log("REGISTRATION -- Device registration timeout. Incrementing watchdog and rebooting unit");
              self.watchdog:increment();
              node.reboot();
            end
          end);
        end

      else
        if(validRegistration) then
          self.logger:log("REGISTRATION -- Device has account registration but is not connected to Internet");
          self:startApp(callback);

        else
          self.logger:log("REGISTRATION -- Device is NOT connected to the Internet and needs registration. Incrementing watchdog and rebooting unit.");
          self.watchdog:increment();
          node.reboot();
        end
      end

    end)
  end)

end

function b:tryUpdateAndStartApp()
    local registration = self:getRegistration();

    local appInfoUrl = registration.app_custom_info_url;
    if(appInfoUrl == nil) then
      log.log("BOOT -- Using default info url for app update. ");
      appInfoUrl = self.vendor.app_default_info_url;
    else
      log.log("BOOT -- Using custom info url for app update");
    end

    log.log("BOOT -- Updating app. appInfoUrl=" .. appInfoUrl);

    self:updateApp(appInfoUrl, function(result)
      if(result=="app-updated") then
        self.logger:log("boot - Restarting unit to activate new app version");
        dofile("util-watchdog.lua").reset();
        node.restart();

      elseif(result=="app-update-error") then
        self.logger:log("boot - Update error. Skipping.");
        self:startApp(callback);

      elseif(result=="app-up-to-date") then
        self.logger:log("boot - App is up-to-date");
        self.watchdog:reset();
        self:startApp(callback);
      end
    end);
  end
end

--start captive portal for getting account credentials
function b:regCaptiveHandler(path, params, responseCallback)
  local buf = "";
  local mimeType = "application/json";
  local httpStatus = "200 OK";
  local event = nil;

  if(path == "" or path == "/") then
    mimeType = "text/html";
    file.open("app-reg-captive.html", "r");
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

            log.log("REGISTRATION -- Device registration successful. response=" .. data);
            local response = cjson.decode(data);
            local registration = {
              app_uid = response.app_uid,
              account_id = response.account_id,
              access_token = response.access_token,
              refresh_token = response.refresh_token
            }

            local fo = file.open(self.REGISTRATION_FILE, "w+");
            if(fo) then
              if(file.write(cjson.encode(registration))) then
                log.log("REGISTRATION -- Registration data written to disk. Registration successful.");
                buf = "{'result':'OK','message':'Registration created on cloud server and written to disk. Success!'}";
                httpStatus = "201 Created";
                event = "registration-ok";

              else
                log.log("REGISTRATION -- Registration data could not be written to disk. Registration failed.");
                buf = "{'result':'ERROR','message':'Registration data could not be written to disk. Registration failed.'}";
                httpStatus = "500 Internal Server Error";
              end
            else
              log.log("REGISTRATION -- Could not open registration file for writing. Registration failed.");
              buf = "{'result':'ERROR','message':'Could not open registration file for writing. Registration failed.'}";
              httpStatus = "500 Internal Server Error";
            end
            file.close();

          else
            log.log("REGISTRATION -- App registration failed. code=" .. code .. "; data=" .. data);
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

function b:getAppInfoFromFile()
  local f = file.open("app.info", "r");
  if(f) then
    local _contents = file.read();
    file.close();
    return cjson.decode(_contents);
  else
    self.logger:log("BOOT -- File 'app.info' not found");
    return nil;
  end
end

function b:getConfig()
  dofile("device-config");
  if(file.open("registration")) then
    bconfig.app_custom_info_url = file.read();
  end
  file.close();
  self.logger:log("CONFIG -- " .. bconfig.app_info_url);
    end
end

function b:startCaptive(callback)
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

--listener results: "app-update-error", "app-up-to-date", "app-updated"
function b:updateApp(appInfoUrl, listener)
  self.logger:log("UPDATE -- Initiating App update process...");
  self.logger:log("UPDATE -- Trying to connect to Ronda.io server");
  http.get(appInfoUrl, nil, function(code, data)
    if (code < 0) then
      self.logger:log("UPDATE -- Error during app info download. code=" .. code);
      if(not file.exists()) then
        self.logger:log("app-UPDATE -- No App installed yet.");
      end
      listener("app-update-error");

    else
      self.logger:log("UPDATE -- App info downloaded. data=" .. data);

      --VALIDATE DOWNLOADED APP INFO
      local appinfo_remote = cjson.decode(data);
      if(appinfo_remote.sanity == "OK" and appinfo_remote.name ~= nil
          and appinfo_remote.version ~= nil and appinfo_remote.hash ~= nil) then
          self.logger:log("app-UPDATE -- App info sanity check OK");

          local appinfo_local = self:getAppInfoFromFile();

          --Verify if local file info contents matches remote (no need to update app)
          local downloadNewApp = false;
          if(appinfo_local ~= nil) then
            if(appinfo_local.name == appinfo_remote.name and
               appinfo_local.version == appinfo_remote.version) then
              self.logger:log("UPDATE -- Local/Remote app version matches. No need to update. name=" .. _app-info_local.name .. "; version=" .. _app-info_local.version);
              listener("app-up-to-date");
            else
              downloadNewApp = true;
            end

          else
            self.logger:log("UPDATE -- Could not find local app file info. Continuing update.");
            downloadNewApp = true;
          end

          if(downloadNewApp) then
            dofile("boot-appupdate-dl.lua")(_app-info_remote);
          end

      else
        self.logger:log("UPDATE -- Downloaded app info sanity check NOT OK. Aborting update.");
        listener("app-update-error");
      end

    end
  end)

end

--callback - app-file-error", "app-startup-success", "app-startup-error"
function b:startApp(callback)

  self.logger:log("START_APP -- Starting App...");

  local fc = file.open(APP_FILE, "r");
  file.close();
  local fi = file.open(INFO_FILE, "r");
  file.close();

  if(fc and fi) then
    self.logger:log("START_APP -- App files found");

    local info = dofile("boot-utils.lua").getAppInfoFromFile();

    self.logger:log("START_APP -- Checking app integrity...");
    local fh = crypto.toHex(crypto.fhash("sha1", config.app-contents_file));

    if(fh == info.hash) then
      self.logger:log("START_APP -- App file hash matches app info. hash=" .. fh);

      self.logger:log("START_APP -- Incrementing watchdog counter");
      startapp.watchdog.increment();

      self.logger:log("START_APP --");
      self.logger:log("===========================================");
      self.logger:log("  STARTING APP '" .. info.name .. "'...");
      self.logger:log("      version = " .. info.version);
      self.logger:log("         file = " .. config.app-contents_file);
      self.logger:log("         hash = " .. info.hash);
      self.logger:log("===========================================");
      self.logger:log("");

      --free mem before loading App
      startapp.utils = nil;--dealocate
      startapp.watchdog = nil;--dealocate

      --load App from file
      self.logger:log("START_APP -- Loading App file. heap=" .. node.heap());
      local status, app = pcall(dofile(config.app-contents_file));
      if(status) then
        self.logger:log("START_APP -- App loaded SUCCESSFULLY. heap=" .. node.heap());
        _app = app;

        -- startup App
        if(_app.startup ~= nil) then
          local status, err = pcall(_app.startup);
          if(status) then
            self.logger:log("START_APP -- App startup() call was SUCCESSFUL. heap=" .. node.heap());
            callback("app-startup-success");
          else
            self.logger:log("START_APP -- App startup() call was UNSUCCESSFUL. heap=" .. node.heap() ..  "; err=" .. err);
            callback("app-startup-error");
          end
        else
          self.logger:log("START_APP -- App didn't implement 'startup()' method");
          callback("app-startup-error");
        end

      else
        self.logger:log("START_APP -- Failed to load App file. heap=" .. node.heap() .. "; err=" .. app);
        callback("app-file-error");
      end

    else
      self.logger:log("START_APP -- App file hash doesn't match app info. App won't run. Activating captive portal.");
      callback("app-file-error");
    end

  else
    self.logger:log("START_APP -- File '".. config.app-contents_file .."' or '".. config.app-info_file .."' not found.");
    callback("app-file-error");
  end
end

function b.checkDeviceRegistration(checkOnline, callback)

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

function b:getRegistration()
  if(file.open(self.REGISTRATION_FILE, "r")) then
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

function b:startApp(callback)
  callback();
end

function b:downloadApp(appinfo_remote)

  self.logger:log("app-UPDATE -- Checking if there is enough disk space for downloading the new App version... contents-size=" .. _app-info_remote.contents-size);
  local remaining, used, total = file.fsinfo();
  self.logger:log("app-UPDATE -- Filesystem status: remaining=" .. remaining .. "; used=" .. used .. "; total=" .. total);

  if(remaining > appinfo_remote.contents_size) then
    self.logger:log("app-UPDATE -- There is enough disk. Proceding with update...");
  else
    self.logger:log("app-UPDATE -- Insufficient disk detected. Performing a factory reset to cleanup space...");
    self:performFactoryReset();
  end

  self.logger:log("app-UPDATE -- Downloading App contents and saving to disk...");

  --Download contents to a temp file
  local appContentsTemp = APP_FILE .. ".tmp"
  file.open(appContentsTemp, "w+");

  --Download file contents using raw TCP in order to stream the received bytes
  --directly to the disk. http module would put all data in memory, causing
  --out-of-memory exceptions for Apps larger than available memory
  local conn = net.createConnection(net.TCP, appinfo_remote.contents_ssl);
  conn:on("receive", function(sck, c)
    file.write(c);
    --FIXME: skip http header. verify available storage
  end);

  conn:on("disconnection", function(sck, c)
    file.close();
    self.logger:log("UPDATE -- Finished downloading new app contents to temp file. Checking it.");
    local newFileHash = crypto.toHex(crypto.fhash(appContentsTemp));

    if(newFileHash == _app-info_remote.hash) then
      self.logger:log("UPDATE -- Downloaded file contents hash is OK");

      self.logger:log("UPDATE -- Removing current app info and app contents");
      file.remove(self.INFO_FILE);
      file.remove(self.APP_FILE);

      self.logger:log("UPDATE - Replacing app info with new version");
      file.open(cself.INFO_FILE, "w+");
      file.write(cjson.encode(appinfo_remote));
      file.close();

      self.logger:log("UPDATE - Replacing app contents with new version");
      file.rename(appContentsTemp, self.APP_FILE);

      listener("app-updated");

    else
      self.logger:log("UPDATE -- Downloaded file contents hash is NOT OK. expected=" .. _appinfo_remote.hash .. "; actual=" .. newFileHash);
      --TODO: delete temp file?
      listener("app-update-error");
    end

  end);

  conn:on("connection", function(sck, c)
    -- Wait for connection before sending.
    sck:send("GET ".. appinfo_remote.contents-path .." HTTP/1.1\r\nHost: " .. _appinfo_remote.contents_host .. "\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n");
  end)

  conn:connect(appinfo_remote.contents-port, appinfo_remote.contents-host);
end

function b.performFactoryReset()
  self.logger:log("UTILS -- Reseting device to factory state...");
  local fl = file.list();
  for k,v in pairs(fl) do
    if(strsub(k,1,4) ~= "boot") then
      self.logger:log("UTILS -- Removing file " .. k .. "; size=" .. v);
      file.remove(k);
    end
  end
  watchdog.reset();
  self.logger:log("UTILS -- Factory reset done. All non boot files were removed (including App package and data).");
end

self.logger:log("boot module loaded. heap=" .. node.heap());

return b;
