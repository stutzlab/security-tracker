local watchdog = dofile("util-watchdog.lua");
local watchdog2 = dofile("util-watchdog.lua");

watchdog.reset();
assert(not watchdog.isTriggered(1));
watchdog.increment();
assert(watchdog.isTriggered(0));
watchdog.reset();
assert(not watchdog.isTriggered(1));
watchdog.increment();
watchdog.increment();
watchdog.increment();
watchdog.increment();
watchdog.increment();
assert(not watchdog.isTriggered(6));
assert(watchdog.isTriggered(5));

watchdog2.setFile("_watchdog2.counter");
watchdog2.reset();
assert(not watchdog2.isTriggered(1));
watchdog2.increment();
assert(watchdog2.isTriggered(1));
watchdog2.reset();
assert(not watchdog2.isTriggered(1));


print("ALL TESTS PASSED: util-watchdog");

return true;
