
local a = {};

--timerId - unused timerid (from 0 to 5)
function a.isConnectedToInternet(isSsl, host, port, timerId, timeout, callback)
  local socket = net.createConnection(net.TCP, isSsl);

  --success verification
  socket:on("connection", function(sck, c)
    log.log("CAPTIVE -- Socket connection successful to " .. host .. ":" .. port);
    tmr.unregister(timerId);
    callback(true);
  end);

  --timeout verification
  tmr.register(timerId, timeout, tmr.ALARM_SINGLE, function()
    log.log("CAPTIVE -- Socket connection unsuccessful (timeout 3s) to " .. host .. ":" .. port);
    socket.close();
    callback(false);
  end)
  tmr.start(timerId)

  socket:connect(port, host);
end

function a.isGoogleReacheable(timerId, timeout, callback)
  a.isConnectedToInternet(false, "www.google.com", 80, timerId, timeout, callback);
end

return a;
