--heap 1600

local events = {};

local listeners = {};

function events.registerListener(eventName, listener)
  if(listeners[eventName] == nil) then
    listeners[eventName] = {};
  end
  local eventListeners = listeners[eventName];
  eventListeners[#eventListeners + 1] = listener;
end

function events.removeListener(eventName, listener)
  local eventListeners = listeners[eventName];
  if(eventListeners ~= nil and #eventListeners>0) then
    local itemIndex = 0;
    for i=1,#eventListeners do
      if(eventListeners[i] == listener) then
        itemIndex = i;
      end
    end
    if(itemIndex > 0) then
      table.remove(eventListeners, itemIndex);
    end
  end
end

function events.publishEvent(eventName, data)
  local eventListeners = listeners[eventName];
  if(eventListeners ~= nil and #eventListeners>0) then
    for i=1,#eventListeners do
      eventListeners[i](eventName, data);
    end
  end
end

return events;
