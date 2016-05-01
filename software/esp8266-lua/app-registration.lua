__log("APP_REGISTRATION -- Checking App registration...");

global APP_FILE_REGISTRATION = "app_registration";
global APP_URL_APPS = "http://tracker.stutzthings.com/tracker/devices/apps";

global _app_registration = nil;

--callback(registrationInfo)
function _app_checkAppRegistration(callback)

  __log("APP_REGISTRATION -- Verifying App registration");

  local rf = file.open(APP_FILE_REGISTRATION, "r");
  if(rf) then
    __log("APP_REGISTRATION -- Registration file found");
    local registration = cjson.decode(file.read());

    __log("APP_REGISTRATION -- Verifying registration status on server. app_uid=" .. registration.app_uid);
    http.get(APP_URL_APPS .. "/" .. registration.app_uid, nil, function(code, data)
      if (code == 404) then
        __log("APP_REGISTRATION -- app_uid not found. app_uid=" .. registration.app_uid);
        _app_startAppRegistration();
        callback(nil);

      elseif (code == 200) then
        __log("APP_REGISTRATION -- app_uid found. response=" .. registrationResponse);
        local registrationResponse = cjson.decode(data);

        if(registrationResponse.status == "active" and registrationResponse.account_id) then
          __log("APP_REGISTRATION -- App registration is VALID");
          callback(registration);
        else
          __log("APP_REGISTRATION -- App registration is INVALID");
          _app_startAppRegistration();
          callback(nil);
        end

      else
        __log("APP_REGISTRATION -- Error getting app_uid info. code=" .. code .. "; response=" .. registrationResponse);
        callback(registration);
      end
    end);

  else
    __log("APP-REGISTRATION -- Registration file not found");
    _app_startAppRegistration();
    callback(nil);
  end

end


function _app_startAppRegistration()
  __log("APP-REGISTRATION -- Initiating captive portal for App registration");
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
        cjson.encode({account_id=params.username, account_password=params.password}),
        function(code, data)
          if (code == 201) then

            __log("APP_REGISTRATION -- App registration successful. response=" .. data);
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
                __log("APP_REGISTRATION -- Registration data written to disk. Registration successful.");
                buf = "{'result':'OK','message':'Registration created on cloud server and written to disk. Success!'}";
                httpStatus = "201 Created";

                --verify registration
                _app_checkAppRegistration(function(registration)
                  if(registration ~= nil) then
                    _app_startTracking(registration);
                  end
                end);

              else
                __log("APP_REGISTRATION -- Registration data could not be written to disk. Registration failed.");
                buf = "{'result':'ERROR','message':'Registration data could not be written to disk. Registration failed.'}";
                httpStatus = "500 Internal Server Error";
              end
            else
              __log("APP_REGISTRATION -- Could not open registration file for writing. Registration failed.");
              buf = "{'result':'ERROR','message':'Could not open registration file for writing. Registration failed.'}";
              httpStatus = "500 Internal Server Error";
            end
            file.close();

          else
            __log("APP_REGISTRATION -- App registration failed. code=" .. code .. "; data=" .. data);
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
