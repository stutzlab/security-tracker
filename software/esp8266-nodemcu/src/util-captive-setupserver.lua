if(log == nil) then
    log = dofile("util-log.lua");
end

local function setupServer(requestHandler, listener, srv)

  if(srv ~= nil) then
    log.log("CAPTIVE -- Closing previous HTTP server");
    srv.close();
  end

  --STARTING REST APIS
  log.log("CAPTIVE -- Starting HTTP server");
  srv = net.createServer(net.TCP);
  srv:listen(80,function(conn)
    conn:on("receive", function(sck,request)
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil) then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local params = {};
        if (vars ~= nil) then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                params[k] = v;
            end
        end

        requestHandler(path, params, function(httpStatus, contentType, responseBody, event)
          log.log("CAPTIVE -- Response status=" .. httpStatus .. "; body=" .. responseBody .. "; mimeType=" .. contentType);

          local headers = "HTTP/1.0 " .. httpStatus .. "\r\n";
          headers = headers .. "Content-Type: " .. contentType .. "\r\n";
          headers = headers .. "Content-Length: " .. string.len(responseBody) .. "\r\n";
          headers = headers .. "Cache-Control: private, no-store, no-cache\r\n\r\n";
          
          sck:send(headers .. responseBody);
          
          if(event ~= nil and listener ~= nil) then
            listener(event);
          end
          
        end)
     end)
    conn:on("sent", function(sck)
        sck:close();
        collectgarbage();
    end)
  end)

  return srv;

end

return setupServer;
