
local a = {};

function a.isConnectedToInternet(isSsl, host, port, callback)
  local socket = net.createConnection(net.TCP, isSsl);

  --success verification
  socket:on("connection", function(sck, c)
    log.log("CAPTIVE -- Socket connection successful to " .. host .. ":" .. port);
    callback(true);
    tmr.unregister(6);
  end);

  --timeout verification
  tmr.register(6, 3000, tmr.ALARM_SINGLE, function()
    log.log("CAPTIVE -- Socket connection unsuccessful (timeout 3s) to " .. host .. ":" .. port);
    callback(false);
    socket.close();
  end)
  tmr.start(6)

  socket:connect(port, host);
end

return a;
