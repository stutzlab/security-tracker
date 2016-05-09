if(log == nil) then
    log = dofile("util-log.lua");
end

local function start(wifi_ssid)

  log.log("CAPTIVE -- Starting captive portal");

  --STARTING WIFI AP
  log.log("CAPTIVE -- Starting Wifi AP");
  wifi.setmode(wifi.STATIONAP);

  local _bootstrap_captive_ip = {
   ip = "10.10.10.10",
   netmask = "255.255.255.0",
   gateway = "10.10.10.10"
  }
  wifi.ap.setip(_bootstrap_captive_ip);


  local _bootstrap_captive_wifi = {
   ssid = wifi_ssid
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
end

return start;
