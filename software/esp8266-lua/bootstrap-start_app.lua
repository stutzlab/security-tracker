global BOOTSTRAP_FILE_APP_CONTENTS = "app.lua";
global BOOTSTRAP_FILE_APP_INFO = "app.info";

function bootstrap_startApp()

  print("START_APP -- Starting App...");

  local fc = file.open(BOOTSTRAP_FILE_APP_CONTENTS, "r");
  file.close();
  local fi = file.open(BOOTSTRAP_FILE_APP_INFO, "r");
  file.close();

  if(fc and fi) then
    print("START_APP -- App files found");

    local f = file.open(BOOTSTRAP_FILE_APP_INFO, "r");
    local _contents = file.read();
    file.close();
    local _app_info = cjson.decode(_contents);

    print("START_APP -- Checking app integrity...");
    local fh = crypto.toHex(crypto.fhash("sha1", BOOTSTRAP_FILE_APP_CONTENTS));

    if(fh == _app_info_hash) then
      print("START_APP -- File hash matches app info. hash=" .. fh);

      print("START_APP -- Incrementing watchdog counter");
      _bootstrap_incrementWatchDogCounter();

      print("");
      print("===========================================");
      print("START_APP -- Starting app version " .. _app_info.version);
      print("===========================================");
      print("");
      dofile("app.lua");

    else
      print("START_APP -- Local file hash doesn't match app info. App won't run. Activating captive portal.");
      _bootstrap_activateCaptivePortal();
    end

  else
    print("START_APP -- File '".. BOOTSTRAP_FILE_APP_CONTENTS .."' or '".. BOOTSTRAP_FILE_APP_INFO .."' not found. App won't run. Activating captive portal");
    _bootstrap_activateCaptivePortal();
  end

end
