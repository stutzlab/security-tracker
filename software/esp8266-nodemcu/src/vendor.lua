return {
  device_name = "StutzTracker",
  app_default_info_url = "http://tracker.stutzthings.com/tracker/devices/hw1.0/app-default-info",
--  app_custom_info_url = "http://tracker.stutzthings.com/tracker/devices/hw1.0/app-ronda-info",
  wifi_captive_ssid = "Configuracao-StutzTracker-" .. node.chipid()
}
