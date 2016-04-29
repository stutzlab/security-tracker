print("CONFIG -- Setup configuration...");

global _bootstrap_config;

_bootstrap_config = {
   ota_host = "tracker.stutzthings.com",
   ota_port = "80",
   ota_path-info = "/tracker/ota/hw1.0/info",
   ota_path-contents = "/tracker/ota/hw1.0/contents",
   wifi_captive_ssid = "Configuracao-Dispositivo-" .. node.chipid(),
   wifi_captive_browser_title = "Configuração da Rede Wifi",
   wifi_captive_title = "Digite o nome da sua rede Wifi e a senha",
   wifi_captive_message = "Esse dispositivo precisará conectar-se à internet"
}

print("CONFIG -- " .. _bootstrap_config);
