
global internetAccessible = false;

__log("APP_CONNECTIVITY -- Starting to monitor internet connectivity");
tmr.register(1, 2000, tmr.ALARM_AUTO, function()
  local conn = net.createConnection(net.TCP, _app_info_remote.contents-ssl);
  conn:connect(_app_info_remote.contents-port, _app_info_remote.contents-host);
  conn:on("connection", function(sck, c)
    sck.close();
    tmr.unregister(2);
    if(not internetAccessible) then
      internetAccessible = true;
      events.publishEvent("internet-connectivity", true);
    end
  end)
  --register timeout
  tmr.register(2, 1800, tmr.ALARM_SINGLE, function()
    if(internetAccessible) then
      internetAccessible = false;
      events.publishEvent("internet-connectivity", false);
    end
  end)
  tmr.start(2);
end)
tmr.start(1);
