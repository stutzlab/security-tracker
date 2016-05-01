--TODOOOO!

__log("APP_TRACKING -- Getting configuration from server. app_uid=" .. registration.app_uid);
http.get(APP_URL_APPS .. "/" .. registration.app_uid .. "/config", nil, function(code, data)
  if (code == 200) then
    __log("APP_TRACKING -- App config downloaded. config=" .. data);
    local appConfig = cjson.decode(data);

  else
    __log("APP_REGISTRATION -- Error getting app config. code=" .. code .. "; response=" .. data);
  end
end)
