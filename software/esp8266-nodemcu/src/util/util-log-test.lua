local log = dofile("util-log.lua");

log.setPrintLogs(false);
assert(#log.getLogs()==0);

log.log("log1");
assert(#log.getLogs()==1);

log.log("log2");
assert(#log.getLogs()==2);

log.setMaxLogs(5);
log.log("log3");
log.log("log4");
log.log("log5");
assert(#log.getLogs()==5);
assert(log.getLogs()[1]=="log1");
assert(log.getLogs()[5]=="log5");

log.log("log6");
assert(#log.getLogs()==5);
assert(log.getLogs()[1]=="log2");
assert(log.getLogs()[5]=="log6");

--for i=7,1000 do
--    print("HEY " .. i);
--end

--if this is not working OK, out of memory will occur
log.setMaxLogs(10);
for i=7,500 do
  log.log("log" .. i .. " 0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789");
end

assert(#log.getLogs()==10);

print("ALL TESTS PASSED: util-log");

return true;
