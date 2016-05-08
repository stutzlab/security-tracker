dofile("bootstrap_log.lua");

local startapp = {};

local utils = dofile("bootstrap_utils.lua");--3000
local watchdog = dofile("util-watchdog.lua");--5800

--callback - app-file-error", "app-startup-success", "app-startup-error"
function startapp.startApp(callback)

  _b_log.log("START_APP -- Starting App...");

  local fileAppContents = utils.BOOTSTRAP_FILE_APP_CONTENTS;
  local fileAppInfo = utils.BOOTSTRAP_FILE_APP_INFO;

  local fc = file.open(fileAppContents, "r");
  file.close();
  local fi = file.open(fileAppInfo, "r");
  file.close();

  if(fc and fi) then
    _b_log.log("START_APP -- App files found");

    local _app_info = utils.getAppInfoFromFile();

    _b_log.log("START_APP -- Checking app integrity...");
    local fh = crypto.toHex(crypto.fhash("sha1", fileAppContents));

    if(fh == _app_info.hash) then
      _b_log.log("START_APP -- App file hash matches app info. hash=" .. fh);

      _b_log.log("START_APP -- Incrementing watchdog counter");
      startapp.watchdog.increment();

      _b_log.log("START_APP --");
      _b_log.log("===========================================");
      _b_log.log("  STARTING APP '" .. _app_info.name .. "'...");
      _b_log.log("      version = " .. _app_info.version);
      _b_log.log("         file = " .. fileAppContents);
      _b_log.log("         hash = " .. _app_info.hash);
      _b_log.log("===========================================");
      _b_log.log("");

      --free mem before loading App
      startapp.utils = nil;--dealocate
      startapp.watchdog = nil;--dealocate

      --load App from file
      _b_log.log("START_APP -- Loading App file. heap=" .. node.heap());
      local status, app = pcall(dofile(fileAppContents));
      if(status) then
        _b_log.log("START_APP -- App loaded SUCCESSFULLY. heap=" .. node.heap());
        _app = app;

        -- startup App
        if(_app.startup ~= nil) then
          local status, err = pcall(_app.startup);
          if(status) then
            _b_log.log("START_APP -- App startup() call was SUCCESSFUL. heap=" .. node.heap());
            callback("app-startup-success");
          else
            _b_log.log("START_APP -- App startup() call was UNSUCCESSFUL. heap=" .. node.heap() ..  "; err=" .. err);
            callback("app-startup-error");
          end
        else
          _b_log.log("START_APP -- App didn't implement 'startup()' method");
          callback("app-startup-error");
        end

      else
        _b_log.log("START_APP -- Failed to load App file. heap=" .. node.heap() .. "; err=" .. app);
        callback("app-file-error");
      end

    else
      _b_log.log("START_APP -- App file hash doesn't match app info. App won't run. Activating captive portal.");
      callback("app-file-error");
    end

  else
    _b_log.log("START_APP -- File '".. fileAppContents .."' or '".. fileAppInfo .."' not found.");
    callback("app-file-error");
  end

  startapp.utils = nil;--dealocate
  startapp.watchdog = nil;--dealocate

end

_b_log.log("start-app module loaded. heap=" .. node.heap());

return startapp;