log.log("APP_REGISTRATION -- Checking App registration...");

global APP_FILE_REGISTRATION = "app_registration";
global APP_URL_APPS = "http://tracker.stutzthings.com/tracker/devices/apps";

global registrationCounter = 0;
global _app_registration = nil;

log.log("APP_REGISTRATION -- Registering registration timer loop");
tmr.register(3, 5000, tmr.ALARM_AUTO,
  lock("internet", function(callback)
    _app_checkAppRegistration(callback);
  end);
end);

events.registerListener("internet-connectivity", function(accessible)
  if(accessible) then
    tmr.start(3);
  else
    tmr.stop(3);
  end
end);

function _app_checkAppRegistration(callback)

  log.log("APP_REGISTRATION -- Verifying App registration");

  local rf = file.open(APP_FILE_REGISTRATION, "r");
  if(rf) then
    log.log("APP_REGISTRATION -- Registration file found");
    local registration = cjson.decode(file.read());

    log.log("APP_REGISTRATION -- Verifying registration status on server. app_uid=" .. registration.app_uid);
    http.get(APP_URL_APPS .. "/" .. registration.app_uid, nil, function(code, data)
      if (code == 404) then
        log.log("APP_REGISTRATION -- app_uid not found. app_uid=" .. registration.app_uid);
        _app_startAppRegistration();
        _app_registration = nil;
        callback();

      elseif (code == 200) then
        log.log("APP_REGISTRATION -- app_uid found. response=" .. registrationResponse);
        local registrationResponse = cjson.decode(data);

        if(registrationResponse.status == "active" and registrationResponse.account_id) then
          log.log("APP_REGISTRATION -- App registration is VALID");
          _app_registration = registration;
        else
          log.log("APP_REGISTRATION -- App registration is INVALID");
          _app_startAppRegistration();
          _app_registration = nil;
        end

        log.log("APP_UPLOAD -- Sending app status to server");
        local uploadStatus = _app_getUploadStatus();
        local remaining, used, total = file.fsinfo();
        local appStatus = {
          node_bootreason = node.bootreason(),
          node_heap = node.heap(),
          bootstrap_watchdogcounter = bootstrap_getWatchDogCounter(),
          bootstrap_captiveportal_active = bootstrap_isCaptivePortalActive(),
          fsinfo_remaining = remaining,
          fsinfo_used = used,
          fsinfo_total = total,
          upload_pendingFiles = uploadStatus.pendingFiles,
          upload_pendingBytes = uploadStatus.pendingBytes
        };
        http.put(APP_URL_APPS .. "/" .. registration.app_uid .. "/status",
          "Content-Type: application/json\r\n",
          cjson.encode(appStatus), function(code, data)
            if (code == 200) then
              log.log("APP_UPLOAD -- App status POST successful.");
            else
              log.log("APP_UPLOAD -- App status POST failed. code=" .. code);
            end
            callback();
        end);

      else
        log.log("APP_REGISTRATION -- Error getting app_uid info. Trusting configuration data from disk without verifying on cloud. code=" .. code .. "; response=" .. registrationResponse);
        _app_registration = registration;
        callback();
      end

    end);

  else
    log.log("APP-REGISTRATION -- Registration file not found");
    _app_startAppRegistration();
    _app_registration = nil;
    callback();
  end

end


function _app_startAppRegistration()
  log.log("APP-REGISTRATION -- Initiating captive portal for App registration");
  bootstrap_activateCaptivePortal(_app_appRegistrationRequestHandler);
end


--start captive portal for getting account credentials
function _app_appRegistrationRequestHandler(path, params, responseCallback)
  local buf = "";
  local mimeType = "application/json";
  local httpStatus = "200 OK";

  if(path == "" or path == "/") then
    mimeType = "text/html";
    buf = buf .. "<html><body>REGISTRATION PAGE HERE!</body></html>";
    responseCallback(httpStatus, mimeType, buf);

  elseif(path == "/register") then
    if(params.username and params.password) then

      --register new app instance
      http.post(APP_URL_APPS,
        "Content-Type: application/json\r\n",
        cjson.encode({account_id=params.username, account_password=params.password, hw_id=node.chipid()}),
        function(code, data)
          if (code == 201) then

            log.log("APP_REGISTRATION -- App registration successful. response=" .. data);
            local response = cjson.decode(data);
            local registration = {
              app_uid = response.app_uid,
              account_id = response.account_id
              access_token = response.access_token,
              refresh_token = response.refresh_token
            }

            local fo = file.open(APP_FILE_REGISTRATION, "w+");
            if(fo) then
              if(file.write(cjson.encode(registration))) then
                log.log("APP_REGISTRATION -- Registration data written to disk. Registration successful.");
                buf = "{'result':'OK','message':'Registration created on cloud server and written to disk. Success!'}";
                httpStatus = "201 Created";

              else
                log.log("APP_REGISTRATION -- Registration data could not be written to disk. Registration failed.");
                buf = "{'result':'ERROR','message':'Registration data could not be written to disk. Registration failed.'}";
                httpStatus = "500 Internal Server Error";
              end
            else
              log.log("APP_REGISTRATION -- Could not open registration file for writing. Registration failed.");
              buf = "{'result':'ERROR','message':'Could not open registration file for writing. Registration failed.'}";
              httpStatus = "500 Internal Server Error";
            end
            file.close();

          else
            log.log("APP_REGISTRATION -- App registration failed. code=" .. code .. "; data=" .. data);
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

  responseCallback(httpStatus, mimeType, buf);
end

function _app_getRegistration()
  return _app_registration;
end
