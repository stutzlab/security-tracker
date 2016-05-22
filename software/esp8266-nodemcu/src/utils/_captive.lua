
local a = {};

function a:init()
  self.logger = requireModule("_log.lua");
  self.filedrain = requireModule("_filedrain.lua");
  self.active = false;
  self.wifiStatus = {
    txt = "No Info",
    status = "-1"
  }
  self.networksJson = "{'status':'pending'}";
  --globals
  self.drainPage = 0;
  self.drainFile = "";
  self.drainHasMore = false;
  self.srv = nil;
end

--requestHandler(httpStatus, contentType, responseBody)
--timeoutMillis 0-no timeout
--listener(eventName) - "internet_detected", "wifi_connected", "captive_timeout", other specified by custom requestHandlers
function a:start(wifi_captive_ssid, requestHandler, timeoutMillis, listener)
  if(not self.active) then
    self.active = true;
    self.logger:log("CAPTIVE -- Starting captive portal. ssid=" .. wifi_captive_ssid);
    a:apstart(wifi_captive_ssid);
    a:startRestServer(requestHandler, listener);
  else
    self.logger:log("CAPTIVE -- Captive portal already activated. Skipping.");
  end
end

function a:stop()
  log.log("CAPTIVE -- Stopping captive portal");
  if(srv ~= nil) then
    srv.close();
  end
  active = false;
end

function a:apstart(wifi_ssid)

  self.logger:log("CAPTIVE -- Starting captive portal");

  --STARTING WIFI AP
  log.log("CAPTIVE -- Starting Wifi AP");
  wifi.setmode(wifi.STATIONAP);

  local captive_ip = {
   ip = "10.10.10.10",
   netmask = "255.255.255.0",
   gateway = "10.10.10.10"
  }
  wifi.ap.setip(captive_ip);

  local captive_wifi = {
   ssid = wifi_ssid
  --   pwd = "12345678"
  }
  wifi.ap.config(captive_wifi);

  dhcp_config ={};
  dhcp_config.start = "10.10.10.1";
  wifi.ap.dhcp.config(dhcp_config);
  wifi.ap.dhcp.start();

  a:registerStaStatus();
end

function a:registerStaStatus()
  --WIFI STATION STATUS
  wifi.sta.eventMonReg(wifi.STA_IDLE, function(prev)
     wifiStatus.txt = "Idle";
     wifiStatus.status = wifi.STA_IDLE;
  end)
  wifi.sta.eventMonReg(wifi.STA_CONNECTING, function(prev)
     wifiStatus.txt = "Connecting";
     wifiStatus.status = wifi.STA_CONNECTING;
  end)
  wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function(prev)
     wifiStatus.txt = "Wrong password";
     wifiStatus.status = wifi.STA_WRONGPWD;
     wifi.sta.eventMonStop();
  end)
  wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function(prev)
     wifiStatus.txt = "Network not found";
     wifiStatus.status = wifi.STA_APNOTFOUND;
     wifi.sta.eventMonStop();
  end)
  wifi.sta.eventMonReg(wifi.STA_FAIL, function(prev)
     wifiStatus.txt = "Fail";
     wifiStatus.status = wifi.STA_FAIL;
     wifi.sta.eventMonStop();
  end)
  wifi.sta.eventMonReg(wifi.STA_GOTIP, function(prev)
     wifiStatus.txt = "Got IP";
     wifiStatus.status = wifi.STA_GOTIP;
     wifi.sta.eventMonStop();
     log.log("Connected to AP successfuly");
  end)
end

function a:startRestServer(requestHandler, listener)

  self.logger:log("Setup HTTP server");

  if(srv ~= nil) then
    self.logger:log("Clos exist HTTP serv");
    srv.close();
  end

  --STARTING REST APIS
  self.logger:log("Start HTTP serv");
  srv = net.createServer(net.TCP);
  srv:listen(80,function(conn)
    conn:on("receive", function(sck,request)
      a:onRestReceive(sck, request);
    end)
    conn:on("sent", function(sck, c)
       self.logger:log("Data sent");
       if(drainHasMore) then
         self.logger:log("Drain more. heap=" .. node.heap());
         dofile("util-filedrain.lua").drainFileToSocket(drainFile, sck, drainPage+1);
       else
         sck:close();
         collectgarbage();
         log.log("Finished");
       end
     end)
  end)
end

function a:onRestReceive(sck, request)
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil) then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local params = {};
        if (vars ~= nil) then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                params[k] = v;
            end
        end

        self.logger:log("Call req handler. path=" .. path .. "; paramscount=" .. #params .. "; heap=" .. node.heap());
        collectgarbage();
        requestHandler(path, params, function(httpStatus, contentType, bodyContents, event, serveFile)
          log.log("Res status=" .. httpStatus .. "; mimeType=" .. contentType .. "; body=" .. bodyContents);
          drainHasMore = true;
          a:restResponse(httpStatus, contentType, bodyContents, event, serveFile);
        end)
end

function a:restResponse(httpStatus, contentType, bodyContents, event, serveFile)
  self.logger:log("CAPTIVE -- Sending response to client. httpStatus=" .. httpStatus);
  local contentLength = 0;
  if(serveFile) then
     self.logger:log("CAPTIVE -- Serving file " .. bodyContents);
     local fileSize = file.list()[bodyContents];
     contentLength = fileSize;
  else
     self.logger:log("CAPTIVE -- Sending body contents. size=" .. string.len(bodyContents));
     contentLength = string.len(bodyContents);
  end

  local headers = "HTTP/1.0 " .. httpStatus .. "\r\n";
  headers = headers .. "Content-Type: " .. contentType .. "\r\n";
  headers = headers .. "Content-Length: " .. contentLength .. "\r\n";
  headers = headers .. "Cache-Control: private, no-store, no-cache\r\n\r\n";

  if(serveFile) then
    self.logger:log("CAPTIVE -- Copying file contents to socket output. filename=" .. bodyContents .. "; contentLength=" .. contentLength);
    self.filedrain:drainFileToSocket(bodyContents, sck, 0, headers);
  else
    drainHasMore = false;
    sck:send(headers .. bodyContents);
  end

  if(event ~= nil and listener ~= nil) then
    listener(event);
  end
end

--callback(httpStatus, responseMimeType, bodyContents, event)
function a:wifiLoginHandler(path, params, callback)
  log.log("CAPTIVE -- Handling path=" .. path);
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
     log.log("CAPTIVE -- ssid/password page.");
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
     buf = buf .. "{'result':'OK','message':'scan-started'}";

  --PROCESS GET NETWORKS REQUEST
  elseif(params.action == "list") then
     log.log("GET SCAN RESULTS");
     buf = buf .. networksJson;

  --PROCESS SSID/PASSWORD
  elseif(params.action == "login") then
    buf, httpStatus = a:processLogin(params);
  else
     buf = buf.."{'result':'ERROR','message':'invalid-action'}";
     httpStatus = "400 Bad Request";
  end
  if(serveFile) then
    self.logger:log("CAPTIVE -- Serving contents from file");
  else
    self.logger:log("CAPTIVE -- Sending raw contents. length=" .. string.len(buf));
  end
  callback(httpStatus, mimeType, buf, event, serveFile);
end

function a:processLogin(params)
     wifi.sta.eventMonStart();
     self.logger:log("Processing ssid/password");
     if(params.ssid ~= nil and params.pass ~=nil) then
        self.logger:log("SSID: " .. params.ssid);
        self.logger:log("PASS: " .. params.pass);
        wifi.sta.config(params.ssid,params.pass,1);--auto reconnect
        local status, err = pcall(wifi.sta.config, params.ssid,params.pass,1);--auto reconnect
        if(not status) then
           log.log("Exception on wifi.sta.config(). err=" .. err);
           return "{'result':'ERROR','message':'" .. err .. "'}", 
                  "400 Bad Request";
        else
          local status, err = pcall(wifi.sta.connect);
          if(status) then
             return "{'result':'OK','message':'ssid-pass-processed'}",
                    "wifi_connect";
          else
             log.log("Exception while calling wifi.sta.connect(). err=" .. err);
             return "{'result':'ERROR','message':'" .. err .. "'}",
                    "400 Bad Request";
          end
        end
     else
        return "{'result':'ERROR','message':'need-ssid-and-pass'}",
               "400 Bad Request";
     end
end

function a:startNetworkScan()
  self.logger:log("CAPTIVE -- Scan available wifi networks");
  networksJson = "{'networks':[";
  function listap(t)
   for k,v in pairs(t) do
      --print(k.." : "..v);
      networksJson = networksJson .. "{'" .. k .. "':'" .. v .. "'}";
   end
   networksJson = networksJson.."],'status':'fetched'}";
   self.logger:log("CAPTIVE -- Available networks: " .. networksJson);
  end
  wifi.sta.getap(listap);
end

return a;
