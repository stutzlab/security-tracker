global BOOTSTRAP_FILE_APP_CONTENTS = "app.lua";
global BOOTSTRAP_FILE_APP_INFO = "app.info";

local logs = {};

function __log(message)
  print(message);
  --limit message logs in memory
  if(#logs>10) then
    table.remove(logs, 1);
  end
  logs[#logs+1] = message
end

function _bootstrap_getLogs()
  return logs;
end

function _utils_getAppInfoFromFile()
  local f = file.open(BOOTSTRAP_FILE_APP_INFO, "r");
  if(f) then
    local _contents = file.read();
    file.close();
    return cjson.decode(_contents);
  else
    __log("UTILS -- File '" .. BOOTSTRAP_FILE_APP_INFO .. "' not found");
    return nil;
  end
end

function _bootstrap_performFactoryReset()
  __log("UTILS -- Reseting device to factory state...");
  local fl = file.list();
  for k,v in pairs(fl) do
    if(strsub(k,1,9) == "bootstrap") then
      __log("UTILS -- Removing file " .. k .. "; size=" .. v);
      file.remove(k);
    end
  end
  _bootstrap_resetWatchDogCounter();
  __log("UTILS -- Factory reset done. All non bootstrap files were removed (including App package and data).");
end

function _bootstrap_isConnectedToInternet(callback)
  local socket = net.createConnection(net.TCP, _app_info_remote.contents-ssl);

  --success verification
  socket:on("connection", function(sck, c)
    __log("UTILS -- Socket connection successful to " .. _app_info_remote.contents-host .. ":" .. _app_info_remote.contents-port);
    callback(true);
    tmr.unregister(6);
  end);

  --timeout verification
  tmr.register(6, 3000, tmr.ALARM_SINGLE, function()
    __log("UTILS -- Socket connection unsuccessful (timeout 3s) to " .. _app_info_remote.contents-host .. ":" .. _app_info_remote.contents-port);
    callback(false);
    socket.close();
  end)
  tmr.start(6)

  socket:connect(_app_info_remote.contents-port, _app_info_remote.contents-host);
end
