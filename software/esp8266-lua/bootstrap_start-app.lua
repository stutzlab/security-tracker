
function _bootstrap_startApp()

  print("START_APP -- Starting App...");

  local fc = file.open(BOOTSTRAP_FILE_APP_CONTENTS, "r");
  file.close();
  local fi = file.open(BOOTSTRAP_FILE_APP_INFO, "r");
  file.close();

  if(fc and fi) then
    print("START_APP -- App files found");

    local _app_info = _utils_getAppInfoFromFile();

    print("START_APP -- Checking app integrity...");
    local fh = crypto.toHex(crypto.fhash("sha1", BOOTSTRAP_FILE_APP_CONTENTS));

    if(fh == _app_info.hash) then
      print("START_APP -- App file hash matches app info. hash=" .. fh);

      print("START_APP -- Incrementing watchdog counter");
      _bootstrap_incrementWatchDogCounter();

      print("START_APP --");
      print("===========================================");
      print("  STARTING APP '" .. _app_info.name .. "'...");
      print("      version = " .. _app_info.version);
      print("         file = " .. BOOTSTRAP_FILE_APP_CONTENTS);
      print("         hash = " .. _app_info.hash);
      print("===========================================");
      print("");
      dofile(BOOTSTRAP_FILE_APP_CONTENTS);

    else
      print("START_APP -- App file hash doesn't match app info. App won't run. Activating captive portal.");
      _bootstrap_activateCaptivePortal();
    end

  else
    print("START_APP -- File '".. BOOTSTRAP_FILE_APP_CONTENTS .."' or '".. BOOTSTRAP_FILE_APP_INFO .."' not found. App won't run. Activating captive portal");
    _bootstrap_activateCaptivePortal();
  end

end
