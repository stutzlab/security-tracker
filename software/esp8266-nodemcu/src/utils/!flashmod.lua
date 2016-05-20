--BASED ON https://gist.github.com/dnc40085/45e3af2fea22003b3ac2

function requireModule(sourceFile)
  local mod = flashModules[sourceFile];
  if(mod ~= nil) then
    print("FLASHMOD -- Reusing module from memory src=" .. sourceFile .. "; count=" .. #flashModules);
    return mod;
  else
    local flashmod = dofile("_flashmod.lua");
    moduleName = string.sub(sourceFile, 1, string.len(sourceFile)-4);

    --instrument module metadata to load precompiled files on function calls
    local mod = {
      _MOD_NAME = moduleName
    }
    --print("LOAD MODULE name=" .. moduleName);
    print("FLASHMOD -- Preparing module proxy");
    setmetatable(tbl, {
      __index = function(t, k)
        print("FLASHMOD -- Loading module element file " .. string.format("#_%s_%s", t._MOD_NAME, k));
        return loadfile(string.format("#_%s_%s", t._MOD_NAME, k));
      end
    });

    if(mod.init ~= nil) then
      print("FLASHMOD -- Calling init() for module " .. sourceFile);
      mod:init();
    end
    --FIXME Memory cache is not working!
    print("FM " .. #flashModules);
    return mod;
  end
  -- module = nil;
  -- package = nil;
  -- newproxy = nil;
  -- require = nil;
  -- collectgarbage();
end
