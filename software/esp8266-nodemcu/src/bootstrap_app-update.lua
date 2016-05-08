--heap 8800
dofile("bootstrap_log.lua");

local appupdate = {};

local BOOTSTRAP_FILE_APP_CONTENTS_TEMP = "app.lua.downloaded";

--global bootstrap_app_info = {
--  name = "undefined",
--  version = "undefined",
--  hash = "AAA",
--  contents-ssl = false,
--  contents-host = "tracker.stutzthings.com",
--  contents-port = 80,
--  contents-path = "/tracker/devices/hw1.0/app_contents",
--  contents-size = 72434,
--  sanity = "OK"
--};

--listener results: "app-update-error", "app-up-to-date", "app-updated"
function appupdate.checkForUpdates(config, utils, listener)
  _b_log.log("APP_UPDATE -- Initiating App update process...");
  _b_log.log("APP_UPDATE -- Trying to connect to Ronda.io server");
  http.get(config.app-update_info-url, nil, function(code, data)
    if (code < 0) then
      _b_log.log("APP_UPDATE -- Error during app info download. code=" .. code);
      if(not file.exists()) then
        _b_log.log("APP_UPDATE -- No App installed yet.");
      end
      listener("app-update-error");

    else
      _b_log.log("APP_UPDATE -- App info downloaded. data=" .. data);

      --VALIDATE DOWNLOADED APP INFO
      local _app_info_remote = cjson.decode(data);
      if(_app_info_remote.sanity == "OK" and _app_info_remote.name ~= nil
          and _app_info_remote.version ~= nil and _app_info_remote.hash ~= nil) then
          _b_log.log("APP_UPDATE -- App info sanity check OK");

          local _app_info_local = utils.getAppInfoFromFile();

          --Verify if local file info contents matches remote (no need to update app)
          local downloadNewApp = false;
          if(_app_info_local ~= nil) then
            if(_app_info_local.name == _app_info_remote.name and
               _app_info_local.version == _app_info_remote.version) then
              _b_log.log("APP_UPDATE -- Local/Remote app version matches. No need to update. name=" .. _app_info_local.name .. "; version=" .. _app_info_local.version);
              listener("app-up-to-date");
            else
              downloadNewApp = true;
            end

          else
            _b_log.log("APP_UPDATE -- Could not find local app file info. Continuing update.");
            downloadNewApp = true;
          end

          if(downloadNewApp) then
            _b_log.log("APP_UPDATE -- Checking if there is enough disk space for downloading the new App version... contents-size=" .. _app_info_remote.contents-size);
            local remaining, used, total = file.fsinfo();
            _b_log.log("APP_UPDATE -- Filesystem status: remaining=" .. remaining .. "; used=" .. used .. "; total=" .. total);

            if(remaining > _app_info_remote.contents-size) then
              _b_log.log("APP_UPDATE -- There is enough disk. Proceding with update...");
            else
              _b_log.log("APP_UPDATE -- Insufficient disk detected. Performing a factory reset to cleanup space...");
              utils.performFactoryReset();
            end

            _b_log.log("APP_UPDATE -- Downloading App contents and saving to disk...");

            --Download contents to a temp file
            file.open(BOOTSTRAP_FILE_APP_CONTENTS_TEMP, "w+");

            --Download file contents using raw TCP in order to stream the received bytes
            --directly to the disk. http module would put all data in memory, causing
            --out-of-memory exceptions for Apps larger than available memory
            local conn = net.createConnection(net.TCP, _app_info_remote.contents-ssl);
            conn:on("receive", function(sck, c)
              file.write(c);
              --FIXME: skip http header. verify available storage
            end);

            conn:on("disconnection", function(sck, c)
              file.close();
              _b_log.log("APP_UPDATE -- Finished downloading new app contents to temp file. Checking it.");
              local newFileHash = crypto.toHex(crypto.fhash(appupdate.BOOTSTRAP_FILE_APP_CONTENTS_TEMP));

              if(newFileHash == _app_info_remote.hash) then
                _b_log.log("APP_UPDATE -- Downloaded file contents hash is OK");

                _b_log.log("APP_UPDATE -- Removing current app info and app contents");
                file.remove(utils.BOOTSTRAP_FILE_APP_INFO);
                file.remove(utils.BOOTSTRAP_FILE_APP_CONTENTS);

                _b_log.log("APP_UPDATE - Replacing app info with new version");
                file.open(utils.BOOTSTRAP_FILE_APP_INFO, "w+");
                file.write(cjson.encode(_app_info_remote));
                file.close();

                _b_log.log("APP_UPDATE - Replacing app contents with new version");
                file.rename(appupdate.BOOTSTRAP_FILE_APP_CONTENTS_TEMP, utils.BOOTSTRAP_FILE_APP_CONTENTS);

                listener("app-updated");

              else
                _b_log.log("APP_UPDATE -- Downloaded file contents hash is NOT OK. expected=" .. _app_info_remote.hash .. "; actual=" .. newFileHash);
                --TODO: delete temp file?
                listener("app-update-error");
              end

            end);

            conn:on("connection", function(sck, c)
              -- Wait for connection before sending.
              sck:send("GET ".. _app_info_remote.contents-path .." HTTP/1.1\r\nHost: " .. _app_info_remote.contents-host .. "\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n");
            end)

            conn:connect(_app_info_remote.contents-port, _app_info_remote.contents-host);
          end

      else
        _b_log.log("APP_UPDATE -- Downloaded app info sanity check NOT OK. Aborting update.");
        listener("app-update-error");
      end

    end
  end)

end

_b_log.log("app-update module loaded. heap=" .. node.heap());

return appupdate;
