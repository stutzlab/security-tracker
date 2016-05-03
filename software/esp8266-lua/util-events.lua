
local events = {};

local function registerListener(eventName, listener)
  if(events[eventName] == nil) then
    events[eventName] = {};
  end
  local eventListeners = events[eventName];
  eventListeners[#eventListeners + 1] = listener;
end

local function removeListener(eventName, listener)
  local eventListeners = events[eventName];
  if(eventListeners ~= nil) then
    local itemIndex = 0;
    for i to #eventListeners do
      if(eventListeners[i] == listener) then
        itemIndex = i;
      end
    end
    if(itemIndex > 0) then
      table.remove(eventListeners, itemIndex);
    end
  end
end

local function publishEvent(eventName, data)
  local eventListeners = events[eventName];
  if(eventListeners ~= nil) then
    for i to #eventListeners do
      eventListeners[i](data);
    end
  end
end
