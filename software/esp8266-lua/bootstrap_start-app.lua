global loadedApp = nil;

function _bootstrap_startApp()

  __log("START_APP -- Starting App...");

  local fc = file.open(BOOTSTRAP_FILE_APP_CONTENTS, "r");
  file.close();
  local fi = file.open(BOOTSTRAP_FILE_APP_INFO, "r");
  file.close();

  if(fc and fi) then
    __log("START_APP -- App files found");

    local _app_info = _bootstrap_getAppInfoFromFile();

    __log("START_APP -- Checking app integrity...");
    local fh = crypto.toHex(crypto.fhash("sha1", BOOTSTRAP_FILE_APP_CONTENTS));

    if(fh == _app_info.hash) then
      __log("START_APP -- App file hash matches app info. hash=" .. fh);

      __log("START_APP -- Incrementing watchdog counter");
      _bootstrap_incrementWatchDogCounter();

      __log("START_APP --");
      __log("===========================================");
      __log("  STARTING APP '" .. _app_info.name .. "'...");
      __log("      version = " .. _app_info.version);
      __log("         file = " .. BOOTSTRAP_FILE_APP_CONTENTS);
      __log("         hash = " .. _app_info.hash);
      __log("===========================================");
      __log("");

      --load App from file
      local App = assert(loadfile(BOOTSTRAP_FILE_APP_CONTENTS));
      local status, app = pcall(App);
      if(status) then
        __log("START_APP -- App file loaded SUCCESSFULLY");
        loadedApp = app;

        -- startup App
        if(loadedApp.startup ~= nil) then
          local status, err = pcall(loadedApp.startup);
          if(status) then
            __log("START_APP -- App startup() call was SUCCESSFUL");
          else
            __log("START_APP -- App startup() call was UNSUCCESSFUL. err=" .. err);
          end
        else
          __log("START_APP -- App didn't implement 'startup()' method");
        end

      else
        __log("START_APP -- Failed to load App file. err=" .. app);
      end

    else
      __log("START_APP -- App file hash doesn't match app info. App won't run. Activating captive portal.");
      _bootstrap_activateCaptivePortal();
    end

  else
    __log("START_APP -- File '".. BOOTSTRAP_FILE_APP_CONTENTS .."' or '".. BOOTSTRAP_FILE_APP_INFO .."' not found. App won't run. Activating captive portal");
    _bootstrap_activateCaptivePortal();
  end

end
