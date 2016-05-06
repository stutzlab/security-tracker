global _bootstrap_captive_activated = false;

wifiStaStatusTxt = "No Info";
wifiStaStatus = "-1";
networksJson = "{'status':'pending'}";

--requestHandler(httpStatus, contentType, responseBody)
function _bootstrap_activateCaptivePortal(requestHandler)
  if(not _bootstrap_captive_activated) then
    _bootstrap_captive_activated = true;

    __log("CAPTIVE -- ACTIVATING CAPTIVE PORTAL");

    --STARTING WIFI AP
    __log("CAPTIVE -- Starting Wifi AP");
    wifi.setmode(wifi.STATIONAP);

    local _bootstrap_captive_ip;

    _bootstrap_captive_ip = {
     ip = "10.10.10.10",
     netmask = "255.255.255.0",
     gateway = "10.10.10.10"
    }
    wifi.ap.setip(_bootstrap_cfg);


    local _bootstrap_captive_wifi;

    _bootstrap_captive_wifi = {
     ssid = _bootstrap_config.wifi_captive_ssid
    --   pwd = "12345678"
    }
    wifi.ap.config(_bootstrap_captive_wifi);

    dhcp_config ={};
    dhcp_config.start = "10.10.10.1";
    wifi.ap.dhcp.config(dhcp_config);
    wifi.ap.dhcp.start();

    --STARTING REST APIS
    __log("CAPTIVE -- Starting REST APIs");

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

          requestHandler(path, params, function(httpCode, responseBody)
            client:send("HTTP/1.0 " .. httpStatus .. "\r\nContent-Type: " .. contentType .. "\r\nCache-Control: private, no-store\r\n\r\n");
            client:send(responseBody);
            client:close();
            collectgarbage();
          end)
       end)
    end)

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
       __log("Connected to AP successfuly");
    end)
  else
    __log("Captive portal already activated. Won't activate it again.");
  end
end



function _bootstrap_wifiLoginRequestHandler(path, params, callback)
  local buf = "";
  local mimeType = "application/json";
  local httpStatus = "200 OK";

  --LOGIN PAGE
  if(path == "" or path == "/") then
     __log("Showing ssid/password page");
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
     __log("Wifi status: " .. wifiStaStatusTxt);
     if(wifi.sta.getip() ~= nil) then
        __log("station ip: " .. wifi.sta.getip());
        buf = buf.."{'status':'" .. wifiStaStatus .. "','message':'" .. wifiStaStatusTxt .. "','ip':'" .. wifi.sta.getip() .. "'}";
     else
        __log("Could not get ip");
        buf = buf.."{'status':'" .. wifiStaStatus .. "','message':'" .. wifiStaStatusTxt .. "'}";
     end
--           if(_GET.login == "ON1")then
--                 gpio.write(led1, gpio.HIGH);
--           end

  --PROCESS START NETWORKS SCAN
  elseif(params.action == "scan") then
     __log("START NETWORK SCAN");
     startNetworkScan();
     buf = buf .. "{'result':'OK','message':'Scan started. Call action *list* to get results'}";

  --PROCESS GET NETWORKS REQUEST
  elseif(params.action == "list") then
     __log("GET SCAN RESULTS");
     buf = buf .. networksJson;

  --PROCESS SSID/PASSWORD
  elseif(params.action == "login") then
     wifi.sta.eventMonStart()
     __log("Processing ssid/password");
     if(params.ssid ~= nil and params.pass ~=nil) then
        __log("SSID: " .. params.ssid);
        __log("PASS: " .. params.pass);
        wifi.sta.config(params.ssid,params.pass,1);--auto reconnect
        local status, err = pcall(wifi.sta.connect);
        if(status) then
           buf = buf.."{'result':'OK','message':'SSID and PASSWORD processed'}";
           client:send(buf);
           client:close();
           bootstrap_resetWatchDog();
           __log("!!!! APP_UPDATE - Restarting unit to activate configuration !!!!");
           node.reboot();
        else
           __log("Exception while calling wifi.sta.connect(). err=" .. err);
           buf = buf.."{'result':'ERROR','message':'" .. err .. "'}";
        end
     else
        buf = buf.."{'result':'ERROR','message':'Both \'ssid\' and \'pass\' parameters must be set'}";
     end

  else
     buf = buf.."{'result':'ERROR','message':'Invalid action'}";
     httpStatus = "400 Bad Request";
  end

  callback(httpStatus, mimeType, buf);
end

function startNetworkScan()
   __log("Scan available wifi networks");
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
