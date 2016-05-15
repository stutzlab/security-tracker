return {
  device_name = "StutzTracker",
  registration_url = "http://resources/stutzthings.com/devices/tracker",
  app_default_info_url = "http://resources.stutzthings.com/hw/tracker/tracker-1.1.appinfo",
  wifi_captive_ssid = "Configuracao-StutzTracker-" .. node.chipid()
}
