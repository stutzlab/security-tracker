
local function download(_app-info_remote)

  _b_log.log("app-UPDATE -- Checking if there is enough disk space for downloading the new App version... contents-size=" .. _app-info_remote.contents-size);
  local remaining, used, total = file.fsinfo();
  _b_log.log("app-UPDATE -- Filesystem status: remaining=" .. remaining .. "; used=" .. used .. "; total=" .. total);

  if(remaining > _app-info_remote.contents-size) then
    _b_log.log("app-UPDATE -- There is enough disk. Proceding with update...");
  else
    _b_log.log("app-UPDATE -- Insufficient disk detected. Performing a factory reset to cleanup space...");
    dofile("bootstrap-utils.lua").performFactoryReset();
  end

  _b_log.log("app-UPDATE -- Downloading App contents and saving to disk...");

  --Download contents to a temp file
  local config = dofile("bootstrap-config.lua");
  local appContentsTemp = config.app-contents_file .. ".tmp"
  file.open(appContentsTemp, "w+");

  --Download file contents using raw TCP in order to stream the received bytes
  --directly to the disk. http module would put all data in memory, causing
  --out-of-memory exceptions for Apps larger than available memory
  local conn = net.createConnection(net.TCP, _app-info_remote.contents-ssl);
  conn:on("receive", function(sck, c)
    file.write(c);
    --FIXME: skip http header. verify available storage
  end);

  conn:on("disconnection", function(sck, c)
    file.close();
    _b_log.log("app-UPDATE -- Finished downloading new app contents to temp file. Checking it.");
    local newFileHash = crypto.toHex(crypto.fhash(appContentsTemp));

    if(newFileHash == _app-info_remote.hash) then
      _b_log.log("app-UPDATE -- Downloaded file contents hash is OK");

      _b_log.log("app-UPDATE -- Removing current app info and app contents");
      file.remove(config.app-info_file);
      file.remove(config.app-contents_file);

      _b_log.log("app-UPDATE - Replacing app info with new version");
      file.open(config.app-info_file, "w+");
      file.write(cjson.encode(_app-info_remote));
      file.close();

      _b_log.log("app-UPDATE - Replacing app contents with new version");
      file.rename(appContentsTemp, config.app-contents_file);

      listener("app-updated");

    else
      _b_log.log("app-UPDATE -- Downloaded file contents hash is NOT OK. expected=" .. _app-info_remote.hash .. "; actual=" .. newFileHash);
      --TODO: delete temp file?
      listener("app-update-error");
    end

  end);

  conn:on("connection", function(sck, c)
    -- Wait for connection before sending.
    sck:send("GET ".. _app-info_remote.contents-path .." HTTP/1.1\r\nHost: " .. _app-info_remote.contents-host .. "\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n");
  end)

  conn:connect(_app-info_remote.contents-port, _app-info_remote.contents-host);

end

return download;
