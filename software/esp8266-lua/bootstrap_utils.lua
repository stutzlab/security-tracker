global BOOTSTRAP_FILE_APP_CONTENTS = "app.lua";
global BOOTSTRAP_FILE_APP_INFO = "app.info";

function _utils_getAppInfoFromFile()
  local f = file.open(BOOTSTRAP_FILE_APP_INFO, "r");
  if(f) then
    local _contents = file.read();
    file.close();
    return cjson.decode(_contents);
  else
    print("UTILS -- File '" .. BOOTSTRAP_FILE_APP_INFO .. "' not found");
    return nil;
  end
end
