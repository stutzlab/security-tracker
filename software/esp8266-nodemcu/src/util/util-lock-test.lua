local lockutils = dofile("util-lock.lua");

print("Performing call 1 for lock1");

lockutils.lock("lock1", function(callback)
    print("Executing call 1 for lock1");

    print("Performing call 2 for lock1");
    lockutils.lock("lock1", function(callback)
        print("Executing call 2 for lock1");
        callback();
    end)
    callback();
end)

print("ALL TESTS PASSED: util-lock");

return true;
