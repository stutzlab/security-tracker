--heap 3000
dofile("bootstrap_log.lua");

local butils = {};

butils.BOOTSTRAP_FILE_APP_CONTENTS = "app.lua";
butils.BOOTSTRAP_FILE_APP_INFO = "app.info";

function butils.getAppInfoFromFile()
  local f = file.open(butils.BOOTSTRAP_FILE_APP_INFO, "r");
  if(f) then
    local _contents = file.read();
    file.close();
    return cjson.decode(_contents);
  else
    _b_log.log("UTILS -- File '" .. butils.BOOTSTRAP_FILE_APP_INFO .. "' not found");
    return nil;
  end
end

function butils.performFactoryReset(watchdog)
  _b_log.log("UTILS -- Reseting device to factory state...");
  local fl = file.list();
  for k,v in pairs(fl) do
    if(strsub(k,1,9) ~= "bootstrap") then
      _b_log.log("UTILS -- Removing file " .. k .. "; size=" .. v);
      file.remove(k);
    end
  end
  watchdog.reset();
  _b_log.log("UTILS -- Factory reset done. All non bootstrap files were removed (including App package and data).");
end

_b_log.log("bootstrap_utils module loaded. heap=" .. node.heap());

return butils;
