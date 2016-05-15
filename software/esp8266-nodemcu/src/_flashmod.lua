--BASED ON https://gist.github.com/dnc40085/45e3af2fea22003b3ac2

local a = {};

function a.writeModule(sourceFile)
  --print("writeModule sourceFile=" .. sourceFile);
  local tbl = dofile(sourceFile);
  local moduleName = string.sub(sourceFile, 1, string.len(sourceFile)-4);
  --write file hash
  local fileHash = a.fhash(sourceFile);
  local sourceFileHash = "#_" .. sourceFile .. ".fh";
  file.open(sourceFileHash, "w+");
  file.write(fileHash);
  file.close();
  return a.writeModuleTbl(tbl, moduleName);
end

function a.writeModuleTbl(tbl, moduleName)
  print("WRITING MODULE FILES " .. moduleName);
  for k,v in pairs(tbl) do
    --print("writeModule moduleName=" .. moduleName .. "; function="  .. k);
	  if type(v) == "function" then
      file.open(string.format("#_%s_%s", moduleName, k), "w+");
      file.write(string.dump(v));
      file.close();
      tbl[k] = nil;
      --print("wroteModuleFunc moduleName=" .. moduleName .. "; k=" .. k);
	  end
  end
  return a.loadModule(moduleName);
end

function a.loadModule(moduleName)
  local tbl = {
    _MOD_NAME = moduleName
  }
  --print("LOAD MODULE name=" .. moduleName);
  setmetatable(tbl, {
    __index = function(t, k)
      print("LOADING ELEMENT " .. string.format("#_%s_%s", t._MOD_NAME, k));
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
function requireModule(sourceFile)
  local mod = flashModules[sourceFile];
  if(mod ~= nil) then
    print("REUSING MODULE FROM MEMORY");
    return mod;
  else
    print("LOADING MODULE FROM DISK " .. #flashModules);
    local flashmod = dofile("_flashmod.lua");
    local writeModule = true;
    moduleName = string.sub(sourceFile, 1, string.len(sourceFile)-4);
  --  local sourceFile = dofile("util/flashmod.lua").getSourceFile(moduleName);
    local sourceFileHash = "#_" .. sourceFile .. ".fh";
    --print("requireFlashModule moduleName=" .. moduleName .. "; sourceFile=" .. sourceFile);
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
    if(writeModule) then
      mod = flashmod.writeModule(sourceFile);
    else
      mod = flashmod.loadModule(moduleName);
    end
    --FIXME Memory cache is not working!
    print("CALLING init() for module " .. sourceFile);
    if(mod.init ~= nil) then
      mod:init();
    end
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
