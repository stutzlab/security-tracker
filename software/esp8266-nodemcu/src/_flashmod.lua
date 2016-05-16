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
  local insideFunc = false;
  repeat
    file.open(sourceFile, "r");
--print("OPEN " .. sourceFile);
    --print("FSeek " .. filePos);
    file.seek("set", filePos);
--print("SEEK " .. filePos);
    line = file.read('\n');
--print("LINE " .. tostring(line));
    if(line ~= nil) then
      filePos = filePos + string.len(line);
    end
--print("FILEPOS " .. filePos);
    --print("FP " .. filePos .. "; " .. line);
    if(line==nil or string.sub(line, 1, 8) == "function" or filePos == fileSize) then
      --print("LOADING STRING TO LUA TABLE");
        file.close();
        local firstLine = string.sub(funcContents,1,string.find(funcContents, "\n"));
--print("FUNCCONTENTS=" .. funcContents);
        --local funcContents2 = string.gsub(funcContents, "function%s+(.*[:.]).*", "");
        local firstLine2 = string.gsub(firstLine, "(%s.*[:.])", " ", 1);
--print("FIRSTLINE2=" .. firstLine2);
        --local funcName = string.match(funcContents, "function%s+.*[:.]+(.*)%(.*");
        local funcName = string.match(firstLine2, "function%s+(.*)%(.*");
--print("FUNCNAME=" .. tostring(funcName));
        if(funcName ~= nil) then
          local funcContents2 = firstLine2 .. string.sub(funcContents,string.find(funcContents, "\n")+1);
--print("FUNCCONTENTS2=" .. funcContents2);
          if(funcName ~= nil) then
            local fn = string.format("#_%s_%s", moduleName, funcName);
            if(string.len(fn)>31) then
              error("FLASHMOD -- Function '" .. moduleName .. "." .. funcName .. "' name is too long (>31 chars). Shorten it by " .. (string.len(fn)-31) .. " chars.");
            end

            local tmpFile = "#_tmp.lua";
            file.open(tmpFile, "w+");
            file.write(funcContents2);
            file.close();

            node.compile(tmpFile);
print("COMPILED " .. fn);
            file.rename("#_tmp.lc", fn);
          end
        end

        --a.writeFunction(funcName, funcContents, moduleName);
        if(line ~= nil) then
          funcContents = line;
        end
        --print("FC " .. funcContents);
    else
      funcContents = funcContents .. line;
      --print("FC " .. funcContents);
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

function a.writeFunction(funcName, funcContents, moduleName)
  local fn = string.format("#_%s_%s", moduleName, funcName);
  if(string.len(fn)>30) then
    error("FLASHMOD -- Function '" .. moduleName .. "." .. funcName .. "' name is too long (>31 chars). Shorten it by " .. (string.len(fn)-31) .. " chars.");
  end

  file.open(fn, "w+");
  local status, result = pcall(string.dump, funcContents);
  if(status) then
    file.write(result);
  else
    error("FLASHMOD -- Function '" .. moduleName .. "." .. funcName .. "' is too large. Break it in two or more methods keeping each function < 1900 bytes.");
  end
  file.close();
end

function a.writeModuleTbl(tbl, moduleName)
  print("FLASHMOD -- Writing module element files to disk module=" .. moduleName);
  for k,v in pairs(tbl) do
    --print("writeModule moduleName=" .. moduleName .. "; function="  .. k);
	if type(v) == "function" then
      a.writeFunction(k, v, moduleName);
      tbl[k] = nil;
      --print("wroteModuleFunc moduleName=" .. moduleName .. "; k=" .. k);
	end
  end
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
