
global APP_FILE_CONFIG = "app_config";
global APP_FILE_NMEA_PREFIX = "app_nmea-";

global NMEA_SAMPLES_PER_FILE = 800;
global NMEA_BYTES_PER_SAMPLE = 70;
global NMEA_STORAGE_BYTES_FREE = NMEA_BYTES_PER_SAMPLE * NMEA_SAMPLES_PER_FILE * 3;
global NMEA_RECORD_INTERVAL_MILLIS_WHEN_STOPPED = 1000 * 60 * 20;--20 minutes

global _app_skipRecordsWhenStopped = 0;
global _app_skippedRecordCountWhenStopped = 0;

--adjust according to available ram memmory
global NMEA_MAX_MEMORY_SAMPLES = 10;
global _app_nmeaMemSamples = {};

global _app_nmeaSampleCount = 0;
global _app_nmeaFileCount = 0;
global _app_currentNmeaFilename = nil;

global _app_lastGPSSampleGGA;
global _app_lastGPSSampleRMC;
global _app_recordGGA = true;

function init()
  --get next filecounter
  local fc = file.list();
  for k,v in pairs(fc) do
    if(strsub(k,1,strlen(APP_FILE_NMEA_PREFIX)) == APP_FILE_NMEA_PREFIX) then
      local fn = _app_stringSplit(k, "-");
      if(fn[2] ~= nil and fn[2] > _app_nmeaFileCount) then
        _app_nmeaFileCount = fn[2];
      end
    end
  end
  _app_nmeaFileCount = _app_nmeaFileCount + 1;
  log.log("APP_TRACKING -- filecounter = " .. _app_nmeaFileCount);

end


function _app_startTracking()
  log.log("APP_TRACKING -- START TRACKING");

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
  --Enable GPS communications to uart RX (set GPIO0 to HIGH)
  gpio.mode(3, gpio.OUTPUT);
  gpio.write(3, gpio.HIGH);

  --record last GGA/RMC sample to disk at a configurable frequency
  _app_skipRecordsWhenStopped = NMEA_RECORD_INTERVAL_MILLIS_WHEN_STOPPED/(60000/_app_config.samples-per-minute);
  tmr.register(0, 60000/_app_config.samples-per-minute, tmr.ALARM_AUTO, function()

    --if device is stopped, record only one sample at each 20min
    local nmea = _app_stringSplit(_app_lastGPSSampleRMC, ",");
    local speedKnots = _app_stringSplit(nmea[8], ".")[1];
    local stoppedMode = (speedKnots <= 2);

    if(stoppedMode) then -- speed <= 2 knots
      log.log("APP_TRACKING -- Device is stopped. Record frequency is reduced. recordIntervalMillis=" .. NMEA_RECORD_INTERVAL_MILLIS_WHEN_STOPPED .. "; speedKnots=" .. speedKnots);
      if(_app_skippedRecordCountWhenStopped < _app_skipRecordsWhenStopped) then
        _app_skippedRecordCountWhenStopped = _app_skippedRecordCountWhenStopped + 1;
        return;
      else
        _app_skippedRecordCountWhenStopped = 0;
      end
    end

    --record either RMC OR GGA at each time
    local nmeaSample = _app_lastGPSSampleRMC;
    if(_app_recordGGA) then
      nmeaSample = _app_lastGPSSampleGGA;
    end
    _app_recordGGA = not _app_recordGGA;

    --record sample
    _app_recordSample(nmeaSample, stoppedMode);

    _app_nmeaSampleCount = _app_nmeaSampleCount + 1;
  end);
  tmr.start(0);
end

function _app_recordSample(nmeaSample, forceFlush)
  _app_nmeaMemSamples[#_app_nmeaMemSamples + 1] = nmeaSample;

  --flush memory samples to disk
  if(forceFlush or #_app_nmeaMemSamples > NMEA_MAX_MEMORY_SAMPLES) then
    if(_app_flushSamplesToDisk(_app_nmeaMemSamples)) then
      log.log("APP_TRACKING -- Samples flushed to disk. nsamples=" .. #_app_nmeaMemSamples);
    else
      log.log("APP_TRACKING -- Samples could not be flushed to disk. Lost samples=" .. #_app_nmeaMemSamples);
    end
    _app_nmeaMemSamples = {};
  end
end

function _app_flushSamplesToDisk(nmeaSamples)
  --TODO Verify if there will be a problem during removal while an open file for writing exists
  if(freeupStorage()) then
    log.log("APP_TRACKING -- Starting captive portal because storage is low (seems like there is no internet connection for flushing files to the cloud for a long time)");
    bootstrap_forceCaptivePortalWifi();
  end

  local filename = _app_getNmeaFilename();
  local fo = file.open(filename, "a+");
  if(fo) then
    log.log("APP_TRACKING -- Opened file for flushing memory samples to disk. filename=" .. filename .. "; numberSamples=" .. #nmeaSamples);
    for i=1, #nmeaSamples do
      --TODO write or writeLine?
      file.write(nmeaSamples[i]);
    end
    file.close();
    return true;
  else
    log.log("APP_TRACKING -- Error during file opening for nmea recording. filename=" .. filename .. "; numberSamples=" .. #nmeaSamples);
    file.close();
    return false;
  end
end

function _app_getNmeaFilename()
  --change nmea file used for recording samples
  if(_app_nmeaSampleCount >= NMEA_SAMPLES_PER_FILE) then
    log.log("APP_TRACKING -- Allocating new file for nmea recording. samples=" .. _app_nmeaSampleCount);
    --nmea file counter
    _app_nmeaSampleCount = 0;
    _app_nmeaFileCount = _app_nmeaFileCount + 1;
    if(_app_nmeaFileCount >= 9999999) then
      log.log("APP_TRACKING -- Reseted file counter. Strange...");
      _app_nmeaFileCount = 1;
    end
  end

  _app_currentNmeaFilename = APP_FILE_NMEA_PREFIX .. _app_nmeaFileCount;
  return _app_currentNmeaFilename;
end

function _app_stopTracking()
  tmr.unregister(0);
  file.close();
end

function _app_getCurrentNmeaFilename()
  return _app_currentNmeaFilename;
end

init();
