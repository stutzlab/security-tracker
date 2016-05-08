local apputils = dofile("app-utils.lua");

--TEST 1
local results = apputils.stringSplit("a,b,c,d,e,f,g", ",");

assert(#results == 7);
assert(results[1]=="a");
assert(results[2]=="b");
assert(results[3]=="c");
assert(results[4]=="d");
assert(results[5]=="e");
assert(results[6]=="f");
assert(results[7]=="g");


print("ALL TESTS PASSED: app-utils");

return true;
