dofile("app-log.lua");

local a = {};

local registrationFile = nil;
local url_apps = nil;

function a.setup(_registrationFile, _url_apps)
  registrationFile = _registrationFile;
  url_apps = _url_apps;
end

--start captive portal for getting account credentials
function a.appRegistrationRequestHandler(path, params, responseCallback)
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
      http.post(url_apps,
        "Content-Type: application/json\r\n",
        cjson.encode({account_id=params.username, account_password=params.password, hw_id=node.chipid()}),
        function(code, data)
          if (code == 201) then

            log.log("REGISTRATION -- App registration successful. response=" .. data);
            local response = cjson.decode(data);
            local registration = {
              app_uid = response.app_uid,
              account_id = response.account_id,
              access_token = response.access_token,
              refresh_token = response.refresh_token
            }

            local fo = file.open(registrationFile, "w+");
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

return a;
