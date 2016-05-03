
events.registerListener("internet-connectivity", function(accessible)
  if(accessible) then

    __log("APP_UPLOAD -- Internet connectivity detected. Starting to send files");

    --sort nmea file names
    local fnames = {}
    for n in pairs(fc) do
      if(strsub(k,1,strlen(APP_FILE_NMEA_PREFIX)) == APP_FILE_NMEA_PREFIX) then
        table.insert(fnames, n);
      end
    end
    table.sort(fnames);

    --send older files first
    for i,filename in ipairs(fnames) do

      if(filename ~= _app_getCurrentNmeaFilename()) then
        local fo = file.open(filename, "r");
        filecontents = file.read();
        if(fo) then
          __log("APP_UPLOAD -- Opened file " .. fn .. ". Starting to send it.");
          --FIXME REIMPLEMENT THIS USING RAW SOCKETS BECAUSE DATA HAS TO BE SENT USING SMALL BUFFERS (files dont fit on ram memory)
          parei aqui
          --TODO test if default http module timeout (10s) is a bad thing
          http.post(APP_URL_APPS .. "/" .. registration.app_uid .. "/nmea_files",
            "Content-Type: text/csv\r\n",
            fileContents,
            function(code, data)
              if (code == 201) then
                __log("APP_UPLOAD -- File sent successfuly");
                if(file.remove(filename)) then
                  __log("APP_UPLOAD -- Local file removed. filename=" .. filename);
                else
                  __log("APP_UPLOAD -- Local file could not be removed. filename=" .. filename);
                end
              else
                __log("APP_UPLOAD -- File failed to be sent. code=" .. code .. "; data=" .. data);
              end
          end)
        else
          __log("APP_UPLOAD -- Could not open file " .. fn .. " to send to server.");
        end
      end

    end
  end
end)
