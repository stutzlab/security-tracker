dofile("bootstrap-log.lua");

local startapp = {};

--local utils = dofile("bootstrap-utils.lua");--3000
local watchdog = dofile("util-watchdog.lua");--5800
local config = dofile("bootstrap-config.lua");

--callback - app-file-error", "app-startup-success", "app-startup-error"
function startapp.startApp(callback)

  _b_log.log("START_APP -- Starting App...");

  local fc = file.open(config.app-contents_file, "r");
  file.close();
  local fi = file.open(config.app-info_file, "r");
  file.close();

  if(fc and fi) then
    _b_log.log("START_APP -- App files found");

    local info = dofile("bootstrap-utils.lua").getAppInfoFromFile();

    _b_log.log("START_APP -- Checking app integrity...");
    local fh = crypto.toHex(crypto.fhash("sha1", config.app-contents_file));

    if(fh == info.hash) then
      _b_log.log("START_APP -- App file hash matches app info. hash=" .. fh);

      _b_log.log("START_APP -- Incrementing watchdog counter");
      startapp.watchdog.increment();

      _b_log.log("START_APP --");
      _b_log.log("===========================================");
      _b_log.log("  STARTING APP '" .. info.name .. "'...");
      _b_log.log("      version = " .. info.version);
      _b_log.log("         file = " .. config.app-contents_file);
      _b_log.log("         hash = " .. info.hash);
      _b_log.log("===========================================");
      _b_log.log("");

      --free mem before loading App
      startapp.utils = nil;--dealocate
      startapp.watchdog = nil;--dealocate

      --load App from file
      _b_log.log("START_APP -- Loading App file. heap=" .. node.heap());
      local status, app = pcall(dofile(config.app-contents_file));
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
    _b_log.log("START_APP -- File '".. config.app-contents_file .."' or '".. config.app-info_file .."' not found.");
    callback("app-file-error");
  end

  startapp.utils = nil;--dealocate
  startapp.watchdog = nil;--dealocate

end

_b_log.log("start-app module loaded. heap=" .. node.heap());

return startapp;
