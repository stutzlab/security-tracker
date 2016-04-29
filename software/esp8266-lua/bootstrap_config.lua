print("CONFIG -- Setup configuration...");

global _bootstrap_config;

_bootstrap_config = {
  app-update_info-url = "http://tracker.stutzthings.com/tracker/app-update/hw1.0/info",
  wifi_captive_ssid = "Configuracao-Dispositivo-" .. node.chipid(),
  wifi_captive_browser_title = "Configuração da Rede Wifi",
  wifi_captive_title = "Digite o nome da sua rede Wifi e a senha",
  wifi_captive_message = "Esse dispositivo precisará conectar-se à internet. Digite aqui o nome da rede wifi e a senha para que ele utilizará para comunicar-se com a nuvem Ronda.io"
}

print("CONFIG -- " .. _bootstrap_config);
