--TIMERS: 0 - tracker
--        1 - uploader

global APP_FILE_CONFIG = "app_config";
global _app_config;
global _app_lastGPSSampleGGA;
global _app_lastGPSSampleRMC;

function _app_startTracking()
  __log("APP_TRACKING -- START TRACKING");

  _app_config = _app_loadConfig();

  --read GPS data
  uart.setup(0,4800,8,0,1,0);
  uart.on("data", "\n", function(data)
    --select nmea records to be processed (RMC e GGA)
    if(strsub(k,1,6) == "$GPGGA") then
      _app_lastGPSSampleGGA = data;
    elseif(strsub(k,1,6) == "$GPRMC") then
      _app_lastGPSSampleRMC = data;
    end
  end, 0);

  --record last GGA/RMC sample to disk in a configurable frequency
  file.open();
  PAREI AQUI
  tmr.register(0, 60000/config.samples-per-minute, tmr.ALARM_AUTO, function()

  end);
  tmr.start(0);

end

function _app_stopTracking()
  tmr.unregister(0);
end

function _app_loadConfig()
  local fo = file.open(APP_FILE_CONFIG, "r");
  if(fo) then
    __log("APP_TRACKING -- Opened config file successfuly");
    _app_config = cjson.decode(file.read());
  else
    __log("APP_TRACKING -- Failed to open App config file. Using defaults");
    _app_config = {
      samples-per-minute = 60;
    };
  end

  return _app_config;
end
