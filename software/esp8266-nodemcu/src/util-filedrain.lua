
local a = {};

--drain file contents to socket at 256 bytes per page to avoid putting all in memory
function a.drainFileToSocket(filename, socket, page, contentPrefix)
    drainFile = filename;
    drainPage = page;
    log.log("FILEDRAIN -- drainFile=" .. filename .. "; page=" .. page);
    if(file.open(filename, "r")) then
      local contents = "";
      if(contentPrefix ~= nil) then
        contents = contentPrefix;
      end
      if(page>0) then
        log.log("FILEDRAIN -- Reading page " .. page);
        file.seek("set", 256 * page);
      end
      contents = file.read(256);
      log.log("FILEDRAIN -- About to send " .. string.len(contents) .. " bytes");
      if(string.len(contents) == 256) then
        drainHasMore = true;
      else
        drainHasMore = false;
      end
      log.log("FILEDRAIN -- Sending contents=" .. contents);
      socket:send(contents);

    else
      error("File not found: " .. filename);
    end
end

return a;
