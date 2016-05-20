--BASED ON https://gist.github.com/dnc40085/45e3af2fea22003b3ac2
--heap 5500

local a = {};

function a.writeModule(sourceFile)
  local moduleName = string.sub(sourceFile, 1, string.len(sourceFile)-4);
  print("FLASHMOD -- writeModule sourceFile=" .. sourceFile .. "; heap=" .. node.heap());

  --this method doesn't work for large files, so load functions "by hand"
  --local tbl = dofile(sourceFile);
  --a.writeModuleTbl(tbl, moduleName);

  --open file without putting all in memory
  --if(false) then
  local l = file.list();
  local fileSize = 0;
  for k,v in pairs(l) do
    if(k == sourceFile) then
      fileSize = v;
      break;
    end
  end
  --print("FS " .. fileSize);

  local filePos = 0;

  local funcContents = "";
  local line = "";
  repeat
    file.open(sourceFile, "r");
    --print("FSeek " .. filePos);
    file.seek("set", filePos);
    line = file.read('\n');
    filePos = filePos + string.len(line);
    --print("FP " .. filePos .. "; " .. line);
    if(string.sub(line, 1, 8) == "function" or filePos == fileSize) then
      --print("LOADING STRING TO LUA TABLE");
      print("FLASHMOD -- Parsing " .. line);
      file.close();
      local funcPrefix = string.match(string.sub(funcContents,1,string.find(funcContents, "\n")), "function%s+(.*)[:.]");
      local p = "z";
      if(funcPrefix ~= nil) then
        p = funcPrefix;
        --print("FUNCPREFIX " .. funcPrefix);
        --print("FUNCPREFIX contents=>>>" .. funcContents .. "<<<");
      else
        --print("FUNCPREFIX NOT FOUND contents=>>>" .. funcContents .. "<<<");
      end
      local tbl = loadstring("local " .. p .. "={};\n " .. funcContents .. "\n return " .. p .. ";")();
      a.writeModuleTbl(tbl, moduleName);

      --a.writeFunction(funcName, funcContents, moduleName);
      funcContents = line;
      --print("NEW FUNC heap=" .. node.heap());
      --print("FC " .. funcContents);
    else
      funcContents = funcContents .. line;
      --print("ADDED FUNC heap=" .. node.heap());
      --print("FC " .. funcContents);
      if(string.len(funcContents)>2500) then
        error("FLASHMOD -- Function (".. string.sub(funcContents, 1, 20) ..") is too large. Break it in two or more methods keeping each function < 2500 bytes.");
      end
    end
  until filePos == fileSize;
  --print("FINISHED READING FILE");
  --end;


  --write file hash
  local fileHash = a.fhash(sourceFile);
  local sourceFileHash = "#_" .. sourceFile .. ".fh";
  file.open(sourceFileHash, "w+");
  file.write(fileHash);
  file.close();

  return a.loadModule(moduleName);
end

function a.writeModuleTbl(tbl, moduleName)
  --print("FLASHMOD -- Writing module element files to disk module=" .. moduleName);
  for k,v in pairs(tbl) do
    print("FLASHMOD - writeModule moduleName=" .. moduleName .. "; function="  .. k .. ". heap=" .. node.heap());
    if type(v) == "function" then
      a.writeFunction(k, v, moduleName);
      tbl[k] = nil;
      --print("wroteModuleFunc moduleName=" .. moduleName .. "; k=" .. k);
    end
  end
end

function a.writeFunction(funcName, funcContents, moduleName)
  local fn = string.format("#_%s_%s", moduleName, funcName);
  if(string.len(fn)>31) then
    error("FLASHMOD -- Function '" .. moduleName .. "." .. funcName .. "' name is too long (>31). Shorten it by " .. (string.len(fn)-31) .. " chars.");
  end

  file.open(fn, "w+");
  print("FLASHMOD -- About to dump function '" .. moduleName .. "."  .. funcName .. "'. heap=" .. node.heap());
  local status, result = pcall(string.dump, funcContents);
  if(status) then
    print("FLASHMOD -- Dumped ok. len=" .. string.len(result) .. ". heap=" .. node.heap());
    file.write(result);
  else
    error("FLASHMOD -- Function '" .. moduleName .. "." .. funcName .. "' is too large. Break it in two or more methods keeping each function < 1900 bytes.");
  end
  file.close();

end

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
    local flashmod = dofile("_flashmod.lua");
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
    if(mod.init ~= nil) then
      print("FLASHMOD -- Calling init() for module " .. sourceFile);
      mod:init();
    end
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
