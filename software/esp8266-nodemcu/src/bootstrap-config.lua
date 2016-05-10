--heap 1700
dofile("bootstrap-log.lua");

_b_log.log("CONFIG -- Setup configuration...");

local bconfig = {
  device_name = "Ronda.io",
  app_info_url = "http://tracker.stutzthings.com/tracker/devices/hw1.0/app-info",
  wifi_captive_ssid = "Configuracao-Ronda.io-" .. node.chipid(),
  wifi_captive_browser_title = "Configuracao da Rede Wifi",
  wifi_captive_title = "Digite o nome da sua rede Wifi e a senha para que este dispositivo possa conectar-se a internet",
  wifi_captive_message = "Esse dispositivo precisara conectar-se a internet. Digite aqui o nome da rede wifi e a senha para que ele utilizara para comunicar-se com a nuvem Ronda.io",
  app_contents_file = "app.lua",
  app_info_file = "app.info"
}

_b_log.log("CONFIG -- " .. bconfig.app_info_url);

return bconfig;
