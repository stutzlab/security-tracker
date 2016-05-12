--heap 1700
dofile("bootstrap-log.lua");

_b_log.log("CONFIG -- Setup configuration...");

local bconfig = {
  device_name = "Ronda.io",
  app_info_url = "http://tracker.stutzthings.com/tracker/devices/hw1.0/app-info",
  wifi_captive_ssid = "Configuracao-Ronda.io-" .. node.chipid(),
  app_contents_file = "app.lua",
  app_info_file = "app.info"
}

_b_log.log("CONFIG -- " .. bconfig.app_info_url);

return bconfig;
