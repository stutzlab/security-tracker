print("APP_UPDATE -- Performing app update...");

global BOOTSTRAP_FILE_APP_CONTENTS_TEMP = "app.lua.downloaded";

--global bootstrap_app_info = {
--  name = "undefined",
--  version = "undefined",
--  hash = "AAA",
--  contents-ssl = false,
--  contents-host = "tracker.stutzthings.com",
--  contents-port = 80,
--  contents-path = "/tracker/app-update/hw1.0/contents",
--  sanity = "OK"
--};

function _bootstrap_checkForUpdates()
  print("APP_UPDATE -- Initiating App update process...");
  print("APP_UPDATE -- Trying to connect to Ronda.io server");
  http.get(_bootstrap_config.app-update_info-url, nil, function(code, data)
    if (code < 0) then
      print("APP_UPDATE -- Error during app info download. Skipping update. code=" .. code);
    else
      print("APP_UPDATE -- App info downloaded. data=" .. data);

      --VALIDATE DOWNLOADED APP INFO
      local _app_info_remote = cjson.decode(data);
      if(_app_info_remote.sanity == "OK" and _app_info_remote.name ~= nil
          and _app_info_remote.version ~= nil and _app_info_remote.hash ~= nil) then
          print("APP_UPDATE -- App info sanity check OK");

          local _app_info_local = _utils_getAppInfoFromFile();

          --Verify if local file info contents matches remote (no need to update app)
          local downloadNewApp = false;
          if(_app_info_local ~= nil) then
            if(_app_info_local.name == _app_info_remote.name and
               _app_info_local.version == _app_info_remote.version) then
              print("APP_UPDATE -- Local/Remote app version matches. No need to update. name=" .. _app_info_local.name .. "; version=" .. _app_info_local.version);
            else then
              downloadNewApp = true;
            end

          else
            print("APP_UPDATE -- Could not find local app file info. Continuing update.");
            downloadNewApp = true;
          end

          if(downloadNewApp) then
            print("APP_UPDATE -- Downloading App contents and saving to disk...");

            --Download contents to a temp file
            file.open(BOOTSTRAP_FILE_APP_CONTENTS_TEMP, "w+");

            --Download file contents using raw TCP in order to stream the received bytes
            --directly to the disk. http module would put all data in memory, causing
            --out-of-memory exceptions for Apps larger than available memory
            local conn = net.createConnection(net.TCP, _app_info_remote.contents-ssl);

            conn:on("receive", function(sck, c)
              file.write(c);
              //FIXME: skip http header. verify available storage
            end);

            conn:on("disconnection", function(sck, c)
              file.close();
              print("APP_UPDATE -- Finished downloading new app contents to temp file. Checking it.");
              local newFileHash = crypto.toHex(crypto.fhash(BOOTSTRAP_FILE_APP_CONTENTS_TEMP));

              if(newFileHash == _app_info_remote.hash) then
                print("APP_UPDATE -- Downloaded file contents hash is OK");

                print("APP_UPDATE -- Replacing existing app info and app contents by the newer downloaded files");
                file.remove(BOOTSTRAP_FILE_APP_INFO);
                file.remove(BOOTSTRAP_FILE_APP_CONTENTS);

                print("APP_UPDATE - Replacing app info (storage)");
                file.open(BOOTSTRAP_FILE_APP_INFO, "w+");
                file.write(cjson.encode(_app_info_remote));
                file.close();

                print("APP_UPDATE - Replacing app contents (storage)");
                file.rename(BOOTSTRAP_FILE_APP_CONTENTS_TEMP, BOOTSTRAP_FILE_APP_CONTENTS);

                --reset the unit so that on the next app-update check it will
                --find .downloaded files and copy to the final destination
                print("!!!! APP_UPDATE - Restarting unit to activate new app version !!!!");
                node.restart();

              else
                print("APP_UPDATE -- Downloaded file contents hash is NOT OK. expected=" .. _app_info_remote.hash .. "; actual=" .. newFileHash);
                --TODO: delete temp file?
              end

            end);

            conn:connect(_app_info_remote.contents-port, _app_info_remote.contents-host);
            conn:on("connection", function(sck, c);
              -- Wait for connection before sending.
              sck:send("GET / HTTP/1.1\r\nHost: " .. _app_info_remote.contents-host .. "\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n");
            end)

          end

      else
        print("APP_UPDATE -- Downloaded app info sanity check NOT OK. Aborting update.");
        print(_app_info_remote);
      end

    end
  end)

end
