
--adjust according to ram memory availability
global APP_UPLOAD_CHUNK_SIZE = 1024;

global _app_uploadStatus = {
  pendingFiles = 0,
  pendingBytes = 0
};

log.log("APP_REGISTRATION -- Registering upload timer loop");
tmr.register(4, 5000, tmr.ALARM_AUTO,
  lock("internet", function(callback)
    _app_uploadDataToServer(callback);
  end);
end);

events.registerListener("internet-connectivity", function(accessible)
  if(accessible) then
    tmr.start(4);
  else
    tmr.stop(4);
  end
end);

function _app_uploadDataToServer()
  log.log("APP_UPLOAD -- Internet connectivity detected. Starting to send files");

  --sort nmea file names
  local fc = file.list();
  global fnames = {}
  local fsizes = {}
  local totalUploadPendingSize = 0;
  for n,s in pairs(fc) do
    if(strsub(k,1,strlen(APP_FILE_NMEA_PREFIX)) == APP_FILE_NMEA_PREFIX) then
      table.insert(fnames, n);
      table.insert(fsizes, s);
      totalUploadPendingSize = totalUploadPendingSize + s;
    end
  end
  table.sort(fnames);

  log.log("APP_UPLOAD -- Total upload pending: nr files=".. #fnames .."; bytes=" .. totalUploadPendingSize);
  _app_uploadStatus.pendingBytes = totalUploadPendingSize;
  _app_uploadStatus.pendingFiles = #fnames;

  --send older files first
  _app_uploadFiles(fnames, 1);

end

function _app_uploadFiles(fnames, i)
  if(i > #fnames) then
    log.log("APP_UPLOAD -- No pending files found");
    return;
  end

  local filename = fnames[i];
  if(filename ~= _app_getCurrentNmeaFilename()) then
    local fileHash = crypto.toHex(crypto.fhash("sha1", filename));
    local fo = file.open(filename, "r");
    if(fo) then

      log.log("APP_UPLOAD -- Opened file " .. fn);
      local lastFilePosition = 0;
      global uploadSize = fsizes[i];
      local responseData = "";

      local conn = net.createConnection(net.TCP, _app_info_remote.contents-ssl);

      conn:on("connection", function(sck, c)
        log.log("APP_UPLOAD -- Sending POST to server with file contents. filename=" .. filename .. "; size=" .. uploadSize);
        local post = "POST " .. APP_URL_APPS .. "/" .. registration.app_uid .. "/nmea_files" .. " HTTP/1.0\r\n";
        post = post .. "User-Agent: ".. bootstrap_getConfig().device-name .. "\r\n";
        post = post .. "Content-Type: text/csv\r\n";
        post = post .. "X-Content-Hash: " .. fileHash .. "\r\n";
        post = post .. "X-Internal-Filename: " .. filename .. "\r\n";
        post = post .. "Content-Length: " .. uploadSize .. "\r\n\r\n";
        responseData = "";
        sck:send(post);
      end)

      conn:on("sent", function(sck)
        log.log("APP_UPLOAD -- 'sent' event");
        if(uploadSize > lastFilePosition) then
          log.log("APP_UPLOAD -- Reading next file chunk from disk. position=" .. lastFilePosition);
          file.seek("set", lastFilePosition);
          log.log("APP_UPLOAD -- Reading chunk data from disk");
          local data = file.read(APP_UPLOAD_CHUNK_SIZE);
          log.log("APP_UPLOAD -- Read " .. strlen(data) .. " bytes from disk");
          lastFilePosition = lastFilePosition + strlen(data);
          log.log("APP_UPLOAD -- Sending file chunk to server. length=" .. strlen(data));
          sck:send(data);
        else
          log.log("APP_UPLOAD -- File data uploaded. Closing connection. filename=" .. filename);
          file.close();
          sck:close();
        end
      end)

      conn:on("disconnection", function(sck)
        log.log("APP_UPLOAD -- File upload connection closed");
        file.close();
      end)

      conn:on("receive", function(sck, c)
        responseData = responseData .. c;
        if(c == "\r") then
          log.log("APP_UPLOAD -- Response line received. responseData=" .. responseData);
          response = _app_stringSplit(responseData, " ");
          if(reponse[2] == 201) then
            log.log("APP_UPLOAD -- File accepted by server. response=" .. responseData);
            _app_uploadStatus.pendingBytes = _app_uploadStatus.pendingBytes - uploadSize;
            _app_uploadStatus.pendingFiles = _app_uploadStatus.pendingFiles - 1;
            file.remove(filename);
            log.log("APP_UPLOAD -- File removed from local filesystem. filename=" .. filename);
            _app_uploadFiles(fnames, i+1);
          else
            log.log("APP_UPLOAD -- File rejected by server. response=" .. responseData);
          end
          sck:close();
        end
      end)

      conn:connect(_app_info_remote.contents-port, _app_info_remote.contents-host);

    else
      log.log("APP_UPLOAD -- Could not open file " .. fn .. " to send to server.");
    end

  else
    log.log("APP_UPLOAD -- Skipping uploading nmea file because it is being used for writing. filename=" .. filename);
  end

end)

function _app_getUploadStatus()
  return _app_uploadStatus;
end
