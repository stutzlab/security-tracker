
local a = {};

function a.handleResponse(sck, httpStatus, contentType, bodyContents, event, serveFile)
  log.log("CAPTIVE -- Sending response to client. httpStatus=" .. httpStatus);
  local contentLength = 0;
  if(serveFile) then
     log.log("CAPTIVE -- Serving file " .. bodyContents);
     local fileSize = file.list()[bodyContents];
     contentLength = fileSize;
  else
     log.log("CAPTIVE -- Sending body contents. size=" .. string.len(bodyContents));
     contentLength = string.len(bodyContents);
  end

  local headers = "HTTP/1.0 " .. httpStatus .. "\r\n";
  headers = headers .. "Content-Type: " .. contentType .. "\r\n";
  headers = headers .. "Content-Length: " .. contentLength .. "\r\n";
  headers = headers .. "Cache-Control: private, no-store, no-cache\r\n\r\n";

  if(serveFile) then
    log.log("CAPTIVE -- Copying file contents to socket output. filename=" .. bodyContents .. "; contentLength=" .. contentLength);
    dofile("util-filedrain.lua").drainFileToSocket(bodyContents, sck, 0, headers);
  else
    drainHasMore = false;
    sck:send(headers .. bodyContents);
  end

  if(event ~= nil and listener ~= nil) then
    listener(event);
  end
end

return a;
