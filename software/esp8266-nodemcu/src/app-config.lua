
global _app-config = {};

--load app config from disk
_app-config = _app-loadConfigFromDisk();

events.registerListener("internet-connectivity", function(accessible)

  --FIXME create locking between http.get for app config and upload
  if(accessible) then
    --get app config from server
    log.log("app-CONFIG -- Getting configuration from server. app-uid=" .. registration.app-uid);
    http.get(app-URL_APPS .. "/" .. registration.app-uid .. "/config", nil, function(code, data)
      if (code == 200) then
        log.log("app-CONFIG -- App config downloaded. config=" .. data);
        _app-config = cjson.decode(data);
        _app-writeConfigToDisk(_app-config);
      else
        log.log("app-CONFIG -- Error getting app config. code=" .. code .. "; response=" .. data);
      end
    end)
  end

end)

function _app-writeConfigToDisk(appConfig)
  local fo = file.open(app-FILE_CONFIG, "w+");
  if(fo) then
    log.log("app-CONFIG -- Opened app file config for writing");
    file.write(cjson.encode(appConfig));
  else
    log.log("app-CONFIG -- Failed to write app config to disk");
  end
  file.close();
end

function _app-loadConfigFromDisk()
  local fo = file.open(app-FILE_CONFIG, "r");
  if(fo) then
    log.log("app-CONFIG -- Opened app config file successfuly");
    _app-config = cjson.decode(file.read());
  else
    log.log("app-CONFIG -- Failed to open App config file. Using defaults");
    _app-config = {
      samples-per-minute = 60;
    };
  end
  file.close();
  return _app-config;
end

function _app-getAppConfig()
  if(_app-config == nil) then
    log.log("app-CONFIG -- Loading app config from disk");
    return _app-loadConfigFromDisk();
  else
    log.log("app-CONFIG -- Returning previous loaded config");
    return _app-config;
  end
end
