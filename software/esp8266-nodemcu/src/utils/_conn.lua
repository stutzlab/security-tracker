
local a = {};

function a:init()
  self.log = requireModule("util-log.lua");
  self.socket = nil;
end

--timerId - unused timerid (from 0 to 5)
function a:isConnectedToInternet(isSsl, host, port, timerId, timeout, callback)
  if(self.socket ~= nil) then
    self.socket:close();
  end
  self.socket = net.createConnection(net.TCP, isSsl);

  --success verification
  self.socket:on("connection", function(sck, c)
    self.log:log("CONNECTIVITY -- Socket connection successful to " .. host .. ":" .. port);
    tmr.unregister(timerId);
    callback(true);
  end);

  --timeout verification
  tmr:register(timerId, timeout, tmr.ALARM_SINGLE, function()
    self.log:log("CONNECTIVITY -- Socket connection unsuccessful (timeout 3s) to " .. host .. ":" .. port);
    self.socket.close();
    callback(false);
  end)
  tmr.start(timerId)

  self.socket:connect(port, host);
end

function a:isGoogleReacheable(timerId, timeout, callback)
  self:isConnectedToInternet(false, "www.google.com", 80, timerId, timeout, callback);
end

return a;
