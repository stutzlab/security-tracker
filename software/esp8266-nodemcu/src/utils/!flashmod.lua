--BASED ON https://gist.github.com/dnc40085/45e3af2fea22003b3ac2
--heap 5500

local a = {};

function a.loadModule(moduleName)
  local tbl = {
    _MOD_NAME = moduleName
  }
  --print("LOAD MODULE name=" .. moduleName);
  setmetatable(tbl, {
    __index = function(t, k)
      print("FLASHMOD -- Loading module element file " .. string.format("#_%s_%s", t._MOD_NAME, k));
      return loadfile(string.format("#_%s_%s", t._MOD_NAME, k));
    end
  });
  return tbl;
end

function a.fhash(sourceFile)
  file.open(sourceFile, "r");
  local chunk = "";
  local fhash = "";
  repeat
    chunk = file.read(1024);
    fhash = crypto.toHex(crypto.hash("md5", chunk .. fhash));
  until string.len(chunk) ~= 1024
  file.close();
  return fhash;
--  return crypto.fhash(sourceFile);--FIXME why this doesnt work?
end

--verifies if module was already written to flash and load it
--if not written to flash yet, write it then load
--heap 2300
function requireModule(sourceFile)
  local mod = flashModules[sourceFile];
  if(mod ~= nil) then
    print("FLASHMOD -- Reusing module from memory src=" .. sourceFile .. "; count=" .. #flashModules);
    return mod;
  else
    local flashmod = dofile("!flashmod_prep.lua");
    local writeModule = true;
    moduleName = string.sub(sourceFile, 1, string.len(sourceFile)-4);
    local sourceFileHash = "#_" .. sourceFile .. ".fh";
    file.open(sourceFileHash, "r");
    local status, result = pcall(file.read);
    file.close();
    if(status) then
      local rh = result;
      local fh = flashmod.fhash(sourceFile);
      --print("requireFlashModule rh=" .. rh .. "; fh=" .. fh);
      if(fh == rh) then
        writeModule = false;
      end
    end
    print("FLASHMOD -- Reading module file src=" .. sourceFile .. "; write=" .. tostring(writeModule));
    if(writeModule) then
      mod = flashmod.writeModule(sourceFile);
    else
      mod = flashmod.loadModule(moduleName);
    end
    print("FLASHMOD -- Read module file successfully");
    --if(mod.init ~= nil) then
    --  print("FLASHMOD -- Calling init() for module " .. sourceFile);
    --  mod:init();
    --end
    --FIXME Memory cache is not working!
    print("FM " .. #flashModules);
    return mod;
  end
end

--write module itself to flash
--a.writeModuleTbl(a, "flashmod");
--flash = nil;
module = nil;
package = nil;
newproxy = nil;
require = nil;
collectgarbage();

flashModules = {};

return a;
