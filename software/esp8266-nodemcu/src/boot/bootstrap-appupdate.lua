--heap 8800
dofile("boot-log.lua");

local appupdate = {};

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

--listener results: "app-update-error", "app-up-to-date", "app-updated"
function appupdate.checkForUpdates(appInfoUrl, listener)
  _b_log.log("UPDATE -- Initiating App update process...");
  _b_log.log("UPDATE -- Trying to connect to Ronda.io server");
  http.get(appInfoUrl, nil, function(code, data)
    if (code < 0) then
      _b_log.log("UPDATE -- Error during app info download. code=" .. code);
      if(not file.exists()) then
        _b_log.log("app-UPDATE -- No App installed yet.");
      end
      listener("app-update-error");

    else
      _b_log.log("UPDATE -- App info downloaded. data=" .. data);

      --VALIDATE DOWNLOADED APP INFO
      local _app-info_remote = cjson.decode(data);
      if(_app-info_remote.sanity == "OK" and _app-info_remote.name ~= nil
          and _app-info_remote.version ~= nil and _app-info_remote.hash ~= nil) then
          _b_log.log("app-UPDATE -- App info sanity check OK");

          local _app-info_local = dofile("boot-utils.lua").getAppInfoFromFile();

          --Verify if local file info contents matches remote (no need to update app)
          local downloadNewApp = false;
          if(_app-info_local ~= nil) then
            if(_app-info_local.name == _app-info_remote.name and
               _app-info_local.version == _app-info_remote.version) then
              _b_log.log("UPDATE -- Local/Remote app version matches. No need to update. name=" .. _app-info_local.name .. "; version=" .. _app-info_local.version);
              listener("app-up-to-date");
            else
              downloadNewApp = true;
            end

          else
            _b_log.log("UPDATE -- Could not find local app file info. Continuing update.");
            downloadNewApp = true;
          end

          if(downloadNewApp) then
            dofile("boot-appupdate-dl.lua")(_app-info_remote);
          end

      else
        _b_log.log("UPDATE -- Downloaded app info sanity check NOT OK. Aborting update.");
        listener("app-update-error");
      end

    end
  end)

end

_b_log.log("app-update module loaded. heap=" .. node.heap());

return appupdate;
