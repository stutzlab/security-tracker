dofile("bootstrap-log.lua");--2100

local a = {};

function a.startCaptive(callback)

  _b_log.log("BOOTSTRAP -- Activating captive portal");
  local rebootLoopDetected = dofile("util-watchdog.lua").isTriggered(20);

  local captiveTimeout = 10000;
  if(rebootLoopDetected) then
    _b_log.log("BOOTSTRAP -- Reboot loop detected. Won't start App until internet connection is detected.");
    captiveTimeout = 0;--no timeout
  end

  local captive = dofile("util-captive.lua");
  _b_log.log("captive module loaded. Starting it. heap=" .. node.heap());
  captive.start(dofile("bootstrap-config.lua").wifi_captive_ssid, captive.wifiLoginRequestHandler, captiveTimeout, callback);

end

return a;
