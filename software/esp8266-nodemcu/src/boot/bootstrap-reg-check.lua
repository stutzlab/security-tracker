dofile("app-log.lua");

local a = {};

function a.checkAppRegistration(registrationFile, checkOnline, callback)

  log.log("REGISTRATION -- Verifying App registration");

  local rf = file.open(registrationFile, "r");
  if(rf) then
    log.log("REGISTRATION -- Registration file found");
    local registration = cjson.decode(file.read());

    if(checkOnline) then

      log.log("REGISTRATION -- Verifying registration status on server. app-uid=" .. registration.app-uid);
      http.get(app-URL_APPS .. "/" .. registration.app-uid, nil, function(code, data)
        if (code == 404) then
          log.log("REGISTRATION -- app-uid not found. app-uid=" .. registration.app-uid);
          callback(false);

        elseif (code == 200) then
          log.log("REGISTRATION -- app-uid found. response=" .. registrationResponse);
          local registrationResponse = cjson.decode(data);

          if(registrationResponse.status == "active" and registrationResponse.account_id) then
            log.log("REGISTRATION -- App registration is VALID");
            log.log("REGISTRATION -- Sending app status to server");
            local remaining, used, total = file.fsinfo();
            local appStatus = {
              node_bootreason = node.bootreason(),
              node_heap = node.heap(),
              bootstrap-watchdogcounter = dofile("util-watchdog.lua").getCounter(),
              fsinfo_remaining = remaining,
              fsinfo_used = used,
              fsinfo_total = total,
              upload_pendingFiles = _app_uploadStatus.pendingFiles,
              upload_pendingBytes = _app_uploadStatus.pendingBytes
            };
            http.put(app-URL_APPS .. "/" .. registration.app-uid .. "/status",
              "Content-Type: application/json\r\n",
              cjson.encode(appStatus), function(code, data)
                if (code == 200) then
                  log.log("REGISTRATION -- App status POST successful.");
                else
                  log.log("REGISTRATION -- App status POST failed. code=" .. code);
                end
                callback(true);
            end);
          else
            log.log("REGISTRATION -- App registration is INVALID");
            callback(false);
          end

        else
          log.log("REGISTRATION -- Error getting app-uid info. Trusting configuration data from disk without verifying on cloud. code=" .. code .. "; response=" .. registrationResponse);
          callback(true);
        end

      end);

    else
      log.log("REGISTRATION -- Configuration file found. Skipping online check.");
      callback(true);
    end

  else
    log.log("REGISTRATION -- Registration file not found");
    callback(false);
  end

end

return a;
