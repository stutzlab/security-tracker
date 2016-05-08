local apputils = dofile("util-events.lua");


--TEST 1
local event1OneFound = false;
local event1TwoFound = false;
local eventListener1 = function(eventName, eventData)
  --print("eventName=" .. eventName .. "; eventData=" .. eventData);
  if(not event1OneFound) then
    event1OneFound = true;
    assert(eventData == "Event data One!");
  else
    event1TwoFound = true;
  end
end;

apputils.registerListener("testEvent1", eventListener1);
apputils.publishEvent("testEvent1", "Event data One!");
apputils.removeListener("testEvent1", eventListener1);
apputils.publishEvent("testEvent1", "Event data Two!");

assert(event1OneFound);
assert(not event1TwoFound);



--TEST 2
local event2Counter = 0;
local event2Found = false;
local event3Found = false;
local event4Found = false;
apputils.registerListener("testEvent2", function(eventName, eventData)
    event2Found = true;
    assert("Event datas" == string.sub(eventData, 1, 11));
    event2Counter = event2Counter + 1;
end)
apputils.registerListener("testEvent2", function(eventName, eventData)
    event3Found = true;
    assert("Event datas" == string.sub(eventData, 1, 11));
    event2Counter = event2Counter + 1;
end)
apputils.registerListener("testEvent2", function(eventName, eventData)
    event4Found = true;
    assert("Event datas" == string.sub(eventData, 1, 11));
    event2Counter = event2Counter + 1;
end)
apputils.publishEvent("testEvent2", "Event datas 1");
apputils.publishEvent("testEvent2", "Event datas 2");
apputils.publishEvent("testEvent2", "Event datas 3");
apputils.publishEvent("testEvent2", "Event datas 4");

assert(event2Found);
assert(event3Found);
assert(event4Found);
assert(event2Counter == 12);


print("ALL TESTS PASSED: util-events");

return true;
