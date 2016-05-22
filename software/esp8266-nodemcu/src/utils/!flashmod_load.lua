--BASED ON https://gist.github.com/dnc40085/45e3af2fea22003b3ac2

flashModules = {};

function requireModule(sourceFile)
  local mod = flashModules[sourceFile];
  if(mod ~= nil) then
    print("FLASHMOD -- Reusing module from memory src=" .. sourceFile .. "; count=" .. #flashModules);
    return mod;
  else
    moduleName = string.sub(sourceFile, 1, string.len(sourceFile)-4);

    --instrument module metadata to load precompiled files on function calls
    local mod = {
      _MOD_NAME = moduleName
    }
    --print("FLASHMOD -- Preparing module function proxy");
    setmetatable(mod, {
      __index = function(t, k)
        local fn = string.format("#_%s_%s", t._MOD_NAME, k);
        print("FLASHMOD -- Loading module element file " .. fn);
        local m = nil;
        if(file.open(fn, "r")) then
          file.close();
          m = assert(loadfile(fn));
          if(m == nil) then
            print("FLASHMOD -- Module couldn't be loaded");
          else
            print("FLASHMOD -- Module load ok. m=" .. tostring(m));
          end
        else
          print("FLASHMOD -- Module file not found. fn=" .. fn);
        end
        return m;
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
