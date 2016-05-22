
local a = {};

function a:init()
  self.vendor = dofile("!vendor.lua");
  self.constants = dofile("!constants.lua");
end

--callback - app-file-error", "app-startup-success", "app-startup-error"
function a:startApp(callback)

  self.logger:log("START_APP -- Starting App...");

  local fc = file.open(APP_FILE, "r");
  file.close();
  local fi = file.open(INFO_FILE, "r");
  file.close();

  if(fc and fi) then
    self.logger:log("RUNNER -- App files found");

    local info = self:getAppInfoFromFile();

    self.logger:log("RUNNER -- Checking app integrity...");
    local fh = crypto.toHex(crypto.fhash("sha1", config.app-contents_file));

    if(fh == info.hash) then
      self.logger:log("RUNNER -- App file hash matches app info. hash=" .. fh);

      self.logger:log("RUNNER -- Incrementing watchdog counter");
      startapp.watchdog.increment();

      self.logger:log("RUNNER --");
      self.logger:log("===========================================");
      self.logger:log("  STARTING APP '" .. info.name .. "'...");
      self.logger:log("      version = " .. info.version);
      self.logger:log("         file = " .. config.app-contents_file);
      self.logger:log("         hash = " .. info.hash);
      self.logger:log("===========================================");
      self.logger:log("");

      --free mem before loading App
      startapp.utils = nil;--dealocate
      startapp.watchdog = nil;--dealocate

      a:loadAppFromFile();

    else
      self.logger:log("RUNNER -- App file hash doesn't match app info. App won't run. Activating captive portal.");
      callback("app-file-error");
    end

  else
    self.logger:log("RUNNER -- File '".. config.app-contents_file .."' or '".. config.app-info_file .."' not found.");
    callback("app-file-error");
  end
end

function loadAppFromFile()
  --load App from file
  self.logger:log("RUNNER -- Loading App file. heap=" .. node.heap());
  local status, app = pcall(dofile(config.app-contents_file));
  if(status) then
    self.logger:log("RUNNER -- App loaded SUCCESSFULLY. heap=" .. node.heap());
    _app = app;

    -- startup App
    if(_app ~= nil and _app.getInfo ~= nil) then
      print("RUNNER -- App info: " .. _app.getInfo());
    end

    if(_app.startup ~= nil) then
      local status, err = pcall(_app.startup);
      if(status) then
        self.logger:log("RUNNER -- App startup() call was SUCCESSFUL. heap=" .. node.heap());
        callback("app-startup-success");
      else
        self.logger:log("RUNNER -- App startup() call was UNSUCCESSFUL. heap=" .. node.heap() ..  "; err=" .. err);
        callback("app-startup-error");
      end
    else
      self.logger:log("RUNNER -- App didn't implement 'startup()' method");
      callback("app-startup-error");
    end

  else
    self.logger:log("RUNNER -- Failed to load App file. heap=" .. node.heap() .. "; err=" .. app);
    callback("app-file-error");
  end
end

return a;
