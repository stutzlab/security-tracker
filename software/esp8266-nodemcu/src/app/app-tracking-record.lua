dofile("app-log.lua");

local a = {};

--adjust according to available ram memmory
local NMEA_MAX_MEMORY_SAMPLES = 10;

local STORAGE_MINIMUM = 1000;
local STORAGE_FREEUP = 5000;

--memory buffer
local nmeaMemSamples = {};
local nmeaSampleCount = 0;

function a.recordNmeaSample(sample, speedKnots)
  local stoppedMode = (speedKnots <= 2);

  if(stoppedMode) then -- speed <= 2 knots
    log.log("TRACKING -- Device is stopped. Record frequency is reduced. speedKnots=" .. speedKnots);
    if(skippedRecordCountWhenStopped < skipRecordsWhenStopped) then
      skippedRecordCountWhenStopped = skippedRecordCountWhenStopped + 1;
      return;
    else
      skippedRecordCountWhenStopped = 0;
    end
  end

  --record sample
  a.recordSample(sample, stoppedMode);

  nmeaSampleCount = nmeaSampleCount + 1;
end

function a.recordSample(nmeaSample, forceFlush)
  nmeaMemSamples[#nmeaMemSamples + 1] = nmeaSample;

  --flush memory samples to disk
  if(forceFlush or #nmeaMemSamples > NMEA_MAX_MEMORY_SAMPLES) then
    if(a.flushSamplesToDisk(nmeaMemSamples)) then
      log.log("TRACKING -- Samples flushed to disk. nsamples=" .. #nmeaMemSamples);
    else
      log.log("TRACKING -- Samples could not be flushed to disk. Lost samples=" .. #nmeaMemSamples);
    end
    nmeaMemSamples = {};
  end
end

function a.flushSamplesToDisk(nmeaSamples)
  --TODO Verify if there will be a problem during removal while an open file for writing exists
  local reboot = false;
  if(dofile("util-storage.lua").freeupStorage(STORAGE_MINIMUM, STORAGE_FREEUP, "")) then
    log.log("TRACKING -- Some older files were removed because of low storage space. Watchdog incremented.");
    reboot = true;
  end

  local filename = a.getNmeaFilename();
  local fo = file.open(filename, "a+");
  if(fo) then
    log.log("TRACKING -- Opened file for flushing memory samples to disk. filename=" .. filename .. "; numberSamples=" .. #nmeaSamples);
    for i=1, #nmeaSamples do
      --TODO write or writeLine?
      file.write(nmeaSamples[i]);
    end
    return true;
  else
    log.log("TRACKING -- Error during file opening for nmea recording. filename=" .. filename .. "; numberSamples=" .. #nmeaSamples);
    return false;
  end
  file.close();
  if(reboot) then
    log.log("TRACKING -- Rebooting unit after detection of low storage");
    node.reboot();
end

function a.getNmeaFilename()
  --change nmea file used for recording samples
  if(nmeaSampleCount >= NMEA_SAMPLES_PER_FILE) then
    log.log("TRACKING -- Allocating new file for nmea recording. samples=" .. nmeaSampleCount);
    --nmea file counter
    nmeaSampleCount = 0;
    nmeaFileCount = nmeaFileCount + 1;
    if(nmeaFileCount >= 9999999) then
      log.log("TRACKING -- Reseted file counter. Strange...");
      nmeaFileCount = 1;
    end
  end

  return FILE_NMEA_PREFIX .. nmeaFileCount;
end

return a;
