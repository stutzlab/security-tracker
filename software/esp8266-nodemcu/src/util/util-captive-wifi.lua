if(log == nil) then
    log = dofile("util-log.lua");
end

local a = {};

--callback(httpStatus, responseMimeType, bodyContents, event)
function a.wifiLoginRequestHandler(path, params, callback)
  log.log("CAPTIVE -- Handling request path=" .. path);
  for k,v in pairs(params) do
    log.log("CAPTIVE -- " .. k .. "=" .. v);
  end

  local buf = "";
  local mimeType = "application/json";
  local httpStatus = "200 OK";
  local serveFile = false;
  local event = nil;

  --LOGIN PAGE
  if((path == "" or path == "/") and params.action == nil) then
     log.log("CAPTIVE -- Showing ssid/password page.");
     buf = "captive-wifi.html";
     serveFile = true;
     mimeType = "text/html";
     a.startNetworkScan();

  --PROCESS STATUS REQUEST
  elseif(params.action == "status") then
     log.log("Wifi status: " .. wifiStatus.txt);
     if(wifi.sta.getip() ~= nil) then
        log.log("station ip: " .. wifi.sta.getip());
        buf = buf.."{'status':'" .. wifiStatus.status .. "','message':'" .. wifiStatus.txt .. "','ip':'" .. wifi.sta.getip() .. "'}";
     else
        log.log("Could not get ip");
        buf = buf.."{'status':'" .. wifiStatus.status .. "','message':'" .. wifiStatus.txt .. "'}";
     end

  --PROCESS START NETWORKS SCAN
  elseif(params.action == "scan") then
     log.log("START NETWORK SCAN");
     startNetworkScan();
     buf = buf .. "{'result':'OK','message':'Scan started. Call action *list* to get results'}";

  --PROCESS GET NETWORKS REQUEST
  elseif(params.action == "list") then
     log.log("GET SCAN RESULTS");
     buf = buf .. networksJson;

  --PROCESS SSID/PASSWORD
  elseif(params.action == "login") then
     wifi.sta.eventMonStart()
     log.log("Processing ssid/password");
     if(params.ssid ~= nil and params.pass ~=nil) then
        log.log("SSID: " .. params.ssid);
        log.log("PASS: " .. params.pass);
        wifi.sta.config(params.ssid,params.pass,1);--auto reconnect
--        local status, err = pcall(wifi.sta.config, params.ssid,params.pass,1);--auto reconnect
local status = true;
        if(not status) then
           log.log("Exception while calling wifi.sta.config(). err=" .. err);
           buf = buf.."{'result':'ERROR','message':'" .. err .. "'}";
           httpStatus = "400 Bad Request";
        else
          local status, err = pcall(wifi.sta.connect);
          if(status) then
             buf = buf.."{'result':'OK','message':'SSID and PASSWORD processed'}";
             event = "wifi_connect";
          else
             log.log("Exception while calling wifi.sta.connect(). err=" .. err);
             buf = buf.."{'result':'ERROR','message':'" .. err .. "'}";
             httpStatus = "400 Bad Request";
          end
        end
     else
        buf = buf.."{'result':'ERROR','message':'Both \'ssid\' and \'pass\' parameters must be set'}";
        httpStatus = "400 Bad Request";
     end

  else
     buf = buf.."{'result':'ERROR','message':'Invalid action'}";
     httpStatus = "400 Bad Request";
  end
  if(serveFile) then
    log.log("CAPTIVE -- Serving contents from file");
  else
    log.log("CAPTIVE -- Sending raw response contents. length=" .. string.len(buf));
  end
  callback(httpStatus, mimeType, buf, event, serveFile);
end

local networksJson = "{'status':'pending'}";
function a.startNetworkScan()
   log.log("CAPTIVE -- Scan available wifi networks");
   networksJson = "{'networks':[";
   function listap(t)
     for k,v in pairs(t) do
        --print(k.." : "..v);
        networksJson = networksJson .. "{'" .. k .. "':'" .. v .. "'}";
     end
     networksJson = networksJson.."],'status':'fetched'}";
     log.log("CAPTIVE -- Available networks: " .. networksJson);
   end
   wifi.sta.getap(listap);
end

return a;
