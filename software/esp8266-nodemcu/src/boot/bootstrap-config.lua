--heap 1700
dofile("bootstrap-log.lua");

_b_log.log("CONFIG -- Setup configuration...");

local bconfig = {
  device_name = "StutzTracker",
  app_default_info_url = "http://tracker.stutzthings.com/tracker/devices/hw1.0/app-default-info",
--  app_custom_info_url = "http://tracker.stutzthings.com/tracker/devices/hw1.0/app-ronda-info",
  wifi_captive_ssid = "Config-StutzTracker-" .. node.chipid(),
  app_contents_file = "app.lua",
  app_info_file = "app.info"
}

if(file.open("app_custom_info_url")) then
  bconfig.app_custom_info_url = file.read();
end
file.close();

_b_log.log("CONFIG -- default=" .. bconfig.app_default_info_url);

return bconfig;