global bootstrap_captive_activated;
bootstrap_captive_activated = false;

wifiStaStatusTxt = "No Info";
wifiStaStatus = "-1";
networksJson = "{'status':'pending'}";

function _bootstrap_activateCaptivePortal()
  if(not bootstrap_captive_activated) then
    bootstrap_captive_activated = true;

    print("CAPTIVE -- ACTIVATING CAPTIVE PORTAL");

    --STARTING WIFI AP
    print("CAPTIVE -- Starting Wifi AP");
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
    print("CAPTIVE -- Starting REST APIs");

    srv = net.createServer(net.TCP);
    srv:listen(80,function(conn)
      conn:on("receive", function(client,request)
          local buf = "";
          local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
          if(method == nil) then
              _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
          end
          local showIndex = true;
          local _GET = {};
          if (vars ~= nil) then
              for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                  _GET[k] = v;
                  showIndex = false;
              end
          end

          --LOGIN PAGE
          if(showIndex) then
             print("Showing ssid/password page");
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

             startNetworkScan();

          --PROCESS STATUS REQUEST
          elseif(_GET.action == "status") then
             print("Wifi status: " .. wifiStaStatusTxt);
             if(wifi.sta.getip() ~= nil) then
                print("station ip: " .. wifi.sta.getip());
                buf = buf.."{'status':'" .. wifiStaStatus .. "','message':'" .. wifiStaStatusTxt .. "','ip':'" .. wifi.sta.getip() .. "'}";
             else
                print("Could not get ip");
                buf = buf.."{'status':'" .. wifiStaStatus .. "','message':'" .. wifiStaStatusTxt .. "'}";
             end
    --           if(_GET.login == "ON1")then
    --                 gpio.write(led1, gpio.HIGH);
    --           end

          --PROCESS START NETWORKS SCAN
          elseif(_GET.action == "scan") then
             print("START NETWORK SCAN");
             startNetworkScan();
             buf = buf .. "{'result':'OK','message':'Scan started. Call action *list* to get results'}";

          --PROCESS GET NETWORKS REQUEST
          elseif(_GET.action == "list") then
             print("GET SCAN RESULTS");
             buf = buf .. networksJson;

          --PROCESS SSID/PASSWORD
          elseif(_GET.action == "login") then
             wifi.sta.eventMonStart()
             print("Processing ssid/password");
             if(_GET.ssid ~= nil and _GET.pass ~=nil) then
                print("SSID: " .. _GET.ssid);
                print("PASS: " .. _GET.pass);
                wifi.sta.config(_GET.ssid,_GET.pass,1);--auto reconnect
                local status, err = pcall(wifi.sta.connect);
                if(status) then
                   buf = buf.."{'result':'OK','message':'SSID and PASSWORD processed'}";
                else
                   print("Exception while calling wifi.sta.connect(). err=" .. err);
                   buf = buf.."{'result':'ERROR','message':'" .. err .. "'}";
                end
             else
                buf = buf.."{'result':'ERROR','message':'Both \'ssid\' and \'pass\' parameters must be set'}";
             end

          else
             buf = buf.."{'result':'ERROR','message':'Invalid action'}";

          end

          client:send(buf);
          client:close();
          collectgarbage();
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
       print("Connected to AP successfuly");
    end)
  else
    print("Captive portal already activated. Won't activate it again.");
  end
end

function startNetworkScan()
   print("Scan available wifi networks");
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
