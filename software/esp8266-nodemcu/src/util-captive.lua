--heap 14216
log.log("captive module started loading. heap=" .. node.heap());

if(log == nil) then
    log = dofile("util-log.lua");
end


local captive = {};

local active = false;

local wifiStaStatusTxt = "No Info";
local wifiStaStatus = "-1";
local networksJson = "{'status':'pending'}";

local srv = nil;

--requestHandler(httpStatus, contentType, responseBody)
--timeoutMillis 0-no timeout
--listener(eventName) - "internet_detected", "wifi_connected", "captive_timeout", other specified by custom requestHandlers
function captive.start(requestHandler, timeoutMillis, listener)
  log.log("CAPTIVE -- Starting captive portal");

  local reqHandler = requestHandler;
  local reqListener = listener;

  if(not active) then
    active = true;

    --STARTING WIFI AP
    log.log("CAPTIVE -- Starting Wifi AP");
    wifi.setmode(wifi.STATIONAP);

    local _bootstrap_captive_ip = {
     ip = "10.10.10.10",
     netmask = "255.255.255.0",
     gateway = "10.10.10.10"
    }
    wifi.ap.setip(_bootstrap_cfg);


    local _bootstrap_captive_wifi = {
     ssid = _bootstrap_config.wifi_captive_ssid
    --   pwd = "12345678"
    }
    wifi.ap.config(_bootstrap_captive_wifi);

    dhcp_config ={};
    dhcp_config.start = "10.10.10.1";
    wifi.ap.dhcp.config(dhcp_config);
    wifi.ap.dhcp.start();

    --WIFI STATION STATUS
    wifi.sta.eventMonReg(wifi.STA_IDLE, function(prev)
       wifiStaStatusTxt = "Idle";
       wifiStaStatus = "" .. wifi.STA_IDLE;
    end)
    wifi.sta.eventMonReg(wifi.STA_CONNECTING, function(prev)
       wifiStaStatusTxt = "Connecting";
       wifiStaStatus = "" .. wifi.STA_CONNECTING;
    end)
    wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function(prev)
       wifiStaStatusTxt = "Wrong password";
       wifiStaStatus = "" .. wifi.STA_WRONGPWD;
       wifi.sta.eventMonStop();
    end)
    wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function(prev)
       wifiStaStatusTxt = "Network not found";
       wifiStaStatus = "" .. wifi.STA_APNOTFOUND;
       wifi.sta.eventMonStop();
    end)
    wifi.sta.eventMonReg(wifi.STA_FAIL, function(prev)
       wifiStaStatusTxt = "Fail";
       wifiStaStatus = "" .. wifi.STA_FAIL;
       wifi.sta.eventMonStop();
    end)
    wifi.sta.eventMonReg(wifi.STA_GOTIP, function(prev)
       wifiStaStatusTxt = "Got IP";
       wifiStaStatus = "" .. wifi.STA_GOTIP;
       wifi.sta.eventMonStop();
       log.log("Connected to AP successfuly");
    end)

    captive.setupServer(requestHandler, listener);

  else
    log.log("CAPTIVE -- Captive portal already activated. Skipping.");
  end
end

function captive.setupServer(requestHandler, listener)
  if(srv ~= nil) then
    log.log("CAPTIVE -- Closing previous HTTP server");
    srv.close();
  end

  --STARTING REST APIS
  log.log("CAPTIVE -- Starting HTTP server");
  srv = net.createServer(net.TCP);
  srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
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

        requestHandler(path, params, function(httpStatus, contentType, responseBody, event)
          client:send("HTTP/1.0 " .. httpStatus .. "\r\nContent-Type: " .. contentType .. "\r\nCache-Control: private, no-store\r\n\r\n");
          client:send(responseBody);
          client:close();
          collectgarbage();
          if(event ~= nil) then
            listener(event);
          end
        end)
     end)
  end)
end

function captive.stop()
  log.log("CAPTIVE -- Stopping captive portal");
  if(srv ~= nil) then
    srv.close();
  end
end


--callback(httpStatus, responseMimeType, bodyContents, event)
function captive.wifiLoginRequestHandler(path, params, callback)
  local buf = "";
  local mimeType = "application/json";
  local httpStatus = "200 OK";
  local event = nil;

  --LOGIN PAGE
  if(path == "" or path == "/") then
     log.log("Showing ssid/password page");
     buf = buf.."<html><head><title>" .. _bootstrap_config.wifi_captive_browser_title .. "</title></head>";
     buf = buf.."<body>";
     buf = buf.."<h2>" .. _bootstrap_config.wifi_captive_title .. "</h2>";
     buf = buf.."<div>" .. _bootstrap_config.wifi_captive_message .. "</div>";
     buf = buf.."<form action=\"/\" method=\"get\">";
     buf = buf.."<input type=\"hidden\" name=\"action\" value=\"login\" />";
     buf = buf.."<p>Rede Wifi: <input type=\"text\" name=\"ssid\" /></p>";
     buf = buf.."<p>Senha: <input type=\"text\" name=\"pass\" /></p>";
     buf = buf.."<input type=\"submit\" value=\"Enviar\">";
     buf = buf.."</form>";
     buf = buf.."</body></html>";
     mimeType = "text/html";

     startNetworkScan();

  --PROCESS STATUS REQUEST
  elseif(params.action == "status") then
     log.log("Wifi status: " .. wifiStaStatusTxt);
     if(wifi.sta.getip() ~= nil) then
        log.log("station ip: " .. wifi.sta.getip());
        buf = buf.."{'status':'" .. wifiStaStatus .. "','message':'" .. wifiStaStatusTxt .. "','ip':'" .. wifi.sta.getip() .. "'}";
     else
        log.log("Could not get ip");
        buf = buf.."{'status':'" .. wifiStaStatus .. "','message':'" .. wifiStaStatusTxt .. "'}";
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
        local status, err = pcall(wifi.sta.connect);
        if(status) then
           buf = buf.."{'result':'OK','message':'SSID and PASSWORD processed'}";
           event = "wifi_connect";
        else
           log.log("Exception while calling wifi.sta.connect(). err=" .. err);
           buf = buf.."{'result':'ERROR','message':'" .. err .. "'}";
        end
     else
        buf = buf.."{'result':'ERROR','message':'Both \'ssid\' and \'pass\' parameters must be set'}";
     end

  else
     buf = buf.."{'result':'ERROR','message':'Invalid action'}";
     httpStatus = "400 Bad Request";
  end

  callback(httpStatus, mimeType, buf, event);
end

function captive.startNetworkScan()
   log.log("Scan available wifi networks");
   networksJson = "{'networks':[";
   function listap(t)
     for k,v in pairs(t) do
        print(k.." : "..v);
        networksJson = networksJson .. "{'" .. k .. "':'" .. v .. "'}";
     end
     networksJson = networksJson.."],'status':'fetched'}";
     print(networksJson);
   end
   wifi.sta.getap(listap);
end

function captive.isConnectedToInternet(isSsl, host, port, callback)
  local socket = net.createConnection(net.TCP, isSsl);

  --success verification
  socket:on("connection", function(sck, c)
    log.log("CAPTIVE -- Socket connection successful to " .. host .. ":" .. port);
    callback(true);
    tmr.unregister(6);
  end);

  --timeout verification
  tmr.register(6, 3000, tmr.ALARM_SINGLE, function()
    log.log("CAPTIVE -- Socket connection unsuccessful (timeout 3s) to " .. host .. ":" .. port);
    callback(false);
    socket.close();
  end)
  tmr.start(6)

  socket:connect(port, host);
end

log.log("captive module loaded. heap=" .. node.heap());

return captive;
