
local a = {};

function a:init()
  self.vendor = dofile("!vendor.lua");
  self.constants = dofile("!constants.lua");
end

-- APP UPDATE AND RUN

function a:tryUpdateAndStartApp(callback)
  local registration = self:getRegistration();

  local appInfoUrl = registration.desired_app_info_url;
  if(appInfoUrl == nil) then
    self.logger:log("BOOT -- Using default info url for app update. ");
    appInfoUrl = self.vendor.default_app_info_url;
  else
    self.logger:log("BOOT -- Using custom info url for app update");
  end

  self.logger:log("BOOT -- Updating app. appInfoUrl=" .. appInfoUrl);

  self:updateApp(appInfoUrl, function(result)
    if(result=="app-updated") then
      self.logger:log("boot - Restarting unit to activate new app version");
      self.watchdog:reset();
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

--listener results: "app-update-error", "app-up-to-date", "app-updated"
function a:updateApp(appInfoUrl, listener)
  self.logger:log("UPDATE -- Initiating App update...");
  http.get(appInfoUrl, nil, function(code, data)
    if (code < 0) then
      self.logger:log("UPDATE -- Error during app info download. code=" .. code);
      listener("app-update-error");

    else
      self.logger:log("UPDATE -- App info downloaded. data=" .. data);

      --VALIDATE DOWNLOADED APP INFO
      local appinfo_remote = cjson.decode(data);
      if(appinfo_remote.contents_size > 0 and appinfo_remote.name ~= nil
          and appinfo_remote.version ~= nil and appinfo_remote.contents_hash ~= nil) then
          self.logger:log("UPDATE -- App info sanity OK");

          local appinfo_local = self:getAppInfoFromFile();

          --Verify if local file info contents matches remote (no need to update app)
          local downloadNewApp = false;
          if(appinfo_local ~= nil) then
            if(appinfo_local.name == appinfo_remote.name and
               appinfo_local.version == appinfo_remote.version) then
              self.logger:log("UPDATE -- App up-to-date. name=" .. appinfo_local.name .. "; version=" .. appinfo_local.version);
              listener("app-up-to-date");
            else
              downloadNewApp = true;
            end

          else
            self.logger:log("UPDATE -- Could not find local app file info");
            downloadNewApp = true;
          end

          if(downloadNewApp) then
            self:downloadAppFromSrv(appinfo_remote, listener);
          end

      else
        self.logger:log("UPDATE -- Downloaded app info sanity check NOT OK");
        listener("app-update-error");
      end

    end
  end)
end

function a:downloadAppFromSrv(appinfo, listener)

  self.logger:log("app-UPDATE -- Checking if there is enough disk space for downloading the new App version... contents-size=" .. _app-info_remote.contents-size);
  local remaining, used, total = file.fsinfo();
  self.logger:log("app-UPDATE -- Filesystem status: remaining=" .. remaining .. "; used=" .. used .. "; total=" .. total);

  if(remaining > appinfo.contents_size) then
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
  local conn = net.createConnection(net.TCP, appinfo.contents_ssl);
  conn:on("receive", function(sck, c)
    file.write(c);
    --FIXME: skip http header. verify available storage
  end);

  conn:on("disconnection", function(sck, c)
    self:downloadAppDisc(sck, listener);
  end);

  conn:on("connection", function(sck, c)
    -- Wait for connection before sending.
    sck:send("GET ".. appinfo_remote.contents-path .." HTTP/1.1\r\nHost: " .. _appinfo_remote.contents_host .. "\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n");
  end)

  conn:connect(appinfo.contents-port, appinfo.contents-host);
end

function a:downloadAppDisc(sck, listener)
  file.close();
  self.logger:log("UPDATE -- Finished downloading new app contents to temp file. Checking it.");
  local newFileHash = crypto.toHex(crypto.fhash(appContentsTemp));

  if(newFileHash == appinfo.hash) then
    self.logger:log("UPDATE -- Downloaded file contents hash is OK");
    self.logger:log("UPDATE -- Removing current app info and app contents");
    file.remove(self.INFO_FILE);
    file.remove(self.APP_FILE);
    self.logger:log("UPDATE - Replacing app info with new version");
    file.open(cself.INFO_FILE, "w+");
    file.write(cjson.encode(appinfo));
    file.close();

    self.logger:log("UPDATE - Replacing app contents with new version");
    file.rename(appContentsTemp, self.APP_FILE);

    listener("app-updated");

  else
    self.logger:log("UPDATE -- Downloaded file contents hash is NOT OK. expected=" .. _appinfo_remote.hash .. "; actual=" .. newFileHash);
    --TODO: delete temp file?
    listener("app-update-error");
  end
end

return a;
