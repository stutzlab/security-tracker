print("test2 module started loading. heap=" .. node.heap());

local test2 = {};

local v = "";

for i=0,1000 do
    v = v .. i;
end

function test2.f1(callback)
    callback("test2");
end

function test2.getV()
    return v;
end

print("test2 module finished loading. heap=" .. node.heap());

return test2;
