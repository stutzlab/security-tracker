_b_log.log("captive module loaded. Starting it. heap=" .. node.heap());
dofile("util-captive.lua").start(captive.wifiLoginRequestHandler, captiveTimeout, function(event)

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
