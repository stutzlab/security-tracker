dofile("bootstrap-log.lua");--2100

local a = {};

function a.startCaptive()

  _b_log.log("BOOTSTRAP -- Activating captive portal");
  local rebootLoopDetected = dofile("util-watchdog.lua").isTriggered(20);

  local captiveTimeout = 10000;
  if(rebootLoopDetected) then
    _b_log.log("BOOTSTRAP -- Reboot loop detected. Won't start App until internet connection is detected.");
    captiveTimeout = 0;
  end

  local captive = dofile("util-captive.lua");
  _b_log.log("captive module loaded. Starting it. heap=" .. node.heap());
  captive.start(captive.wifiLoginRequestHandler, captiveTimeout, function(event)

    if(event=="wifi_connect") then
    elseif(event=="captive_timeout") then
      _b_log.log("BOOTSTRAP -- Captive portal timeout");
      captive.stop();
      captive = nil;--dealocate
      collectgarbage();

      b.startApp(callback);

    elseif(event=="internet_detected") then
      _b_log.log("BOOTSTRAP -- Internet connection detected");
      captive.stop();
      captive = nil;--dealocate
      collectgarbage();

      b.updateApp(callback);
    end
  end);

end

return a;
