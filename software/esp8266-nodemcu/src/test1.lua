--local t2 = dofile("test2.lua");

--t2.f1(function(callback)
--    print(callback);
--end);

print("heap=" .. node.heap());

collectgarbage();

print("heap=" .. node.heap());

dofile("test2.lua").f1(function(c)
    collectgarbage();
    print("heapa=" .. node.heap());
--    t2 = nil;
    collectgarbage();
    print("heapb=" .. node.heap());
    print("===== " .. c);
end);


print("heap=" .. node.heap());

collectgarbage();

print("heap=" .. node.heap());

