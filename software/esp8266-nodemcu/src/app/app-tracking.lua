dofile("app-log.lua");

local a = {};

local utils = dofile("app-utils.lua");

local FILE_CONFIG = "app-config";
local FILE_NMEA_PREFIX = "app-nmea-";

local NMEA_SAMPLES_PER_FILE = 800;
local NMEA_BYTES_PER_SAMPLE = 70;
local NMEA_STORAGE_BYTES_FREE = NMEA_BYTES_PER_SAMPLE * NMEA_SAMPLES_PER_FILE * 3;
local NMEA_RECORD_INTERVAL_MILLIS_WHEN_STOPPED = 1000 * 60 * 20;--20 minutes

local skipRecordsWhenStopped = 0;
local skippedRecordCountWhenStopped = 0;

local nmeaFileCount = 0;
local currentNmeaFilename = nil;

local lastGPSSampleGGA;
local lastGPSSampleRMC;
local recordGGA = true;

function a.startTracking()
  log.log("app-TRACKING -- START TRACKING");

  --get next filecounter
  local fc = file.list();
  for k,v in pairs(fc) do
    if(strsub(k,1,strlen(FILE_NMEA_PREFIX)) == FILE_NMEA_PREFIX) then
      local fn = stringSplit(k, "-");
      if(fn[2] ~= nil and fn[2] > nmeaFileCount) then
        nmeaFileCount = fn[2];
      end
    end
  end
  nmeaFileCount = nmeaFileCount + 1;
  log.log("TRACKING -- filecounter = " .. nmeaFileCount);

  --read GPS data
  uart.setup(0,4800,8,0,1,0);
  uart.on("data", "\n", function(data)
    --select nmea records to be processed (RMC e GGA)
    if(strsub(k,1,6) == "$GPGGA") then
      lastGPSSampleGGA = data;
    elseif(strsub(k,1,6) == "$GPRMC") then
      lastGPSSampleRMC = data;
    end
  end, 0);

  --Enable GPS communications to uart RX (set GPIO0 to HIGH)
  gpio.mode(3, gpio.OUTPUT);
  gpio.write(3, gpio.HIGH);

  --record last GGA/RMC sample to disk at a configurable frequency
  skipRecordsWhenStopped = NMEA_RECORD_INTERVAL_MILLIS_WHEN_STOPPED/(60000/config.samples-per-minute);
  tmr.register(0, 60000/config.samples-per-minute, tmr.ALARM_AUTO, function()
    if(lastGPSSampleRMC == nil) then return;
    local sample = lastGPSSampleRMC;
    if(recordGGA) then
      sample = lastGPSSampleGGA;
    end
    --if device is stopped, record only one sample at each 20min
    local nmea = utils.stringSplit(lastGPSSampleRMC, ",");
    local speedKnots = utils.stringSplit(nmea[8], ".")[1];
    dofile("app-tracking-record.lua").recordNmeaSample(sample);
    recordGGA = not recordGGA;
  end);
  tmr.start(0);
end

function stopTracking()
  tmr.unregister(0);
end

return a;
