dofile("app-log.lua");

local a = {};

function a.uploadFiles(fnames, i, callback)
  if(i > #fnames) then
    log.log("UPLOAD -- No pending files found");
    callback();
    return;
  end

  local filename = fnames[i];
  if(filename ~= _app-getCurrentNmeaFilename()) then
    local fileHash = crypto.toHex(crypto.fhash("sha1", filename));
    local fo = file.open(filename, "r");
    if(fo) then

      log.log("UPLOAD -- Opened file " .. fn);
      local lastFilePosition = 0;
      global uploadSize = fsizes[i];
      local responseData = "";

      local conn = net.createConnection(net.TCP, _app-info_remote.contents-ssl);

      conn:on("connection", function(sck, c)
        log.log("UPLOAD -- Sending POST to server with file contents. filename=" .. filename .. "; size=" .. uploadSize);
        local post = "POST " .. app-URL_APPS .. "/" .. registration.app-uid .. "/nmea_files" .. " HTTP/1.0\r\n";
        post = post .. "User-Agent: ".. bootstrap-getConfig().device-name .. "\r\n";
        post = post .. "Content-Type: text/csv\r\n";
        post = post .. "X-Content-Hash: " .. fileHash .. "\r\n";
        post = post .. "X-Internal-Filename: " .. filename .. "\r\n";
        post = post .. "Content-Length: " .. uploadSize .. "\r\n\r\n";
        responseData = "";
        sck:send(post);
      end)

      conn:on("sent", function(sck)
        log.log("UPLOAD -- 'sent' event");
        if(uploadSize > lastFilePosition) then
          log.log("UPLOAD -- Reading next file chunk from disk. position=" .. lastFilePosition);
          file.seek("set", lastFilePosition);
          log.log("UPLOAD -- Reading chunk data from disk");
          local data = file.read(app-UPLOAD_CHUNK_SIZE);
          log.log("UPLOAD -- Read " .. strlen(data) .. " bytes from disk");
          lastFilePosition = lastFilePosition + strlen(data);
          log.log("UPLOAD -- Sending file chunk to server. length=" .. strlen(data));
          sck:send(data);
        else
          log.log("UPLOAD -- File data uploaded. Closing connection. filename=" .. filename);
          file.close();
          sck:close();
        end
      end)

      conn:on("disconnection", function(sck)
        log.log("UPLOAD -- File upload connection closed");
        file.close();
      end)

      conn:on("receive", function(sck, c)
        responseData = responseData .. c;
        if(c == "\r") then
          log.log("UPLOAD -- Response line received. responseData=" .. responseData);
          response = _app-stringSplit(responseData, " ");
          if(reponse[2] == 201) then
            log.log("UPLOAD -- File accepted by server. response=" .. responseData);
            _app_uploadStatus.pendingBytes = _app_uploadStatus.pendingBytes - uploadSize;
            _app_uploadStatus.pendingFiles = _app_uploadStatus.pendingFiles - 1;
            file.remove(filename);
            log.log("UPLOAD -- File removed from local filesystem. filename=" .. filename);
            a.uploadFiles(fnames, i+1);
          else
            log.log("UPLOAD -- File rejected by server. response=" .. responseData);
          end
          sck:close();
        end
      end)

      conn:connect(_app-info_remote.contents-port, _app-info_remote.contents-host);

    else
      log.log("UPLOAD -- Could not open file " .. fn .. " to send to server.");
    end

  else
    log.log("UPLOAD -- Skipping uploading nmea file because it is being used for writing. filename=" .. filename);
  end

end)

return a;
