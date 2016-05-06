
global _app_config;

--load app config from disk
_app_config = _app_loadConfigFromDisk();

events.registerListener("internet-connectivity", function(accessible)

  --FIXME create locking between http.get for app config and upload
  if(accessible) then
    --get app config from server
    __log("APP_CONFIG -- Getting configuration from server. app_uid=" .. registration.app_uid);
    http.get(APP_URL_APPS .. "/" .. registration.app_uid .. "/config", nil, function(code, data)
      if (code == 200) then
        __log("APP_CONFIG -- App config downloaded. config=" .. data);
        _app_config = cjson.decode(data);
        _app_writeConfigToDisk(_app_config);
      else
        __log("APP_CONFIG -- Error getting app config. code=" .. code .. "; response=" .. data);
      end
    end)
  end

end)



function _app_writeConfigToDisk(appConfig)
  local fo = file.open(APP_FILE_CONFIG, "w+");
  if(fo) then
    __log("APP_CONFIG -- Opened app file config for writing");
    file.write(cjson.encode(appConfig));
  else
    __log("APP_CONFIG -- Failed to write app config to disk");
  end
  file.close();
end

function _app_loadConfigFromDisk()
  local fo = file.open(APP_FILE_CONFIG, "r");
  if(fo) then
    __log("APP_CONFIG -- Opened app config file successfuly");
    _app_config = cjson.decode(file.read());
  else
    __log("APP_CONFIG -- Failed to open App config file. Using defaults");
    _app_config = {
      samples-per-minute = 60;
    };
  end
  file.close();
  return _app_config;
end

function _app_getAppConfig()
  if(_app_config == nil) then
    __log("APP_CONFIG -- Loading app config from disk");
    return _app_loadConfigFromDisk();
  else
    __log("APP_CONFIG -- Returning previous loaded config");
    return _app_config;
  end
end
