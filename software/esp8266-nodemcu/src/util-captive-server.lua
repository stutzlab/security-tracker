if(log == nil) then
    log = dofile("util-log.lua");
end

--globals
drainPage = 0;
drainFile = "";
drainHasMore = false;

local a = {};

function a.setupServer(requestHandler, listener, srv)
  log.log("CAPTIVE -- Setup HTTP server");

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

        log.log("CAPTIVE -- Calling request handler. path=" .. path .. "; paramscount=" .. #params .. "; heap=" .. node.heap());
        collectgarbage();
        requestHandler(path, params, function(httpStatus, contentType, bodyContents, event, serveFile)
          log.log("CAPTIVE -- Response status=" .. httpStatus .. "; mimeType=" .. contentType .. "; body=" .. bodyContents);
          drainHasMore = true;
          dofile("util-captive-server-res.lua").handleResponse(sck, httpStatus, contentType, bodyContents, event, serveFile);
        end)
     end)
     conn:on("sent", function(sck, c)
        log.log("CAPTIVE -- Data send confirmed");
        if(drainHasMore) then
          log.log("CAPTIVE -- Drain another chunk of data from file. heap=" .. node.heap());
          dofile("util-filedrain.lua").drainFileToSocket(drainFile, sck, drainPage+1);
        else
          sck:close();
          collectgarbage();
          log.log("CAPTIVE -- Finished response send");
        end
     end)
  end)

  return srv;

end

return a;
