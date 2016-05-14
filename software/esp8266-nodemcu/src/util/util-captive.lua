if(log == nil) then
    log = dofile("util-log.lua");
end

log.log("captive module started loading. heap=" .. node.heap());

local captive = {};

local active = false;

wifiStatus = {
  txt = "No Info",
  status = "-1"
}

local srv = nil;

--requestHandler(httpStatus, contentType, responseBody)
--timeoutMillis 0-no timeout
--listener(eventName) - "internet_detected", "wifi_connected", "captive_timeout", other specified by custom requestHandlers
function captive.start(wifi_captive_ssid, requestHandler, timeoutMillis, listener)
  if(not active) then
    active = true;
    log.log("CAPTIVE -- Starting captive portal. ssid=" .. wifi_captive_ssid);
    dofile("util-captive-apstart.lua").apstart(wifi_captive_ssid);
    captive.setupServer(requestHandler, listener);
  else
    log.log("CAPTIVE -- Captive portal already activated. Skipping.");
  end
end

function captive.setupServer(requestHandler, listener)
  srv = dofile("util-captive-server.lua").setupServer(requestHandler, listener, srv);
end

function captive.stop()
  log.log("CAPTIVE -- Stopping captive portal");
  if(srv ~= nil) then
    srv.close();
  end
  active = false;
end

--callback(httpStatus, responseMimeType, bodyContents, event)
function captive.wifiLoginRequestHandler(path, params, callback)
  dofile("util-captive-wifi.lua").wifiLoginRequestHandler(path, params, callback);
end

log.log("captive module loaded. heap=" .. node.heap());

return captive;
