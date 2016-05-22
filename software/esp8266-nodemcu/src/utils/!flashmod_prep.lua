local a = {};

function a.writeModule(sourceFile)
  print("FLASHMOD -- writeModule sourceFile=" .. tostring(sourceFile) .. "; heap=" .. node.heap());
  local moduleName = string.sub(sourceFile, 1, string.len(sourceFile)-4);

  --open file without putting all in memory
  local l = file.list();
  local fileSize = 0;
  for k,v in pairs(l) do
    if(k == sourceFile) then
      fileSize = v;
      break;
    end
  end

  local filePos = 0;

  local funcContents = "";
  local line = "";
  repeat

    if(not file.open(sourceFile, "r")) then
      error("File not found: " .. sourceFile);
    end

    --print("FSeek " .. filePos);
    file.seek("set", filePos);
    line = file.read('\n');
    if(line == nil) then
      filePos = fileSize;
      line = "";
    else
      filePos = filePos + string.len(line);
    end

    --print("FP " .. filePos .. "; " .. line);
    if(string.sub(line, 1, 8) == "function" or filePos == fileSize) then
      --print("LOADING STRING TO LUA TABLE");
      print("FLASHMOD -- Parsing '" .. line .. "'");
      file.close();
      local funcPrefix = string.match(string.sub(funcContents,1,string.find(funcContents, "\n")), "function%s+(.*)[:.]");
      local p = "z";
      if(funcPrefix ~= nil) then
        p = funcPrefix;
      end
      print("NEW FUNC0 heap=" .. node.heap());
      print("LOADSTRING " .. tostring(p) .. "; " .. string.len(funcContents));
      local tbl = loadstring("local " .. p .. "={};\n " .. funcContents .. "\n return " .. p .. ";")();
      print("NEW FUNC1 heap=" .. node.heap());
      a.writeModuleTbl(tbl, moduleName);

      funcContents = line;
      print("NEW FUNC2 heap=" .. node.heap());
    else
      funcContents = funcContents .. line;
      print("ADDED FUNC heap=" .. node.heap());
      if(string.len(funcContents)>1900) then
        error("FLASHMOD -- Function (".. string.sub(funcContents, 1, 20) ..") is too large (".. string.len(funcContents) .."). Break it in two or more methods keeping each function < 1900 bytes.");
      end
    end
  until filePos == fileSize;

  --write file hash
  local fileHash = a.fhash(sourceFile);
  local sourceFileHash = "#_" .. sourceFile .. ".fh";
  file.open(sourceFileHash, "w+");
  file.write(fileHash);
  file.close();
end

function a.writeModuleTbl(tbl, moduleName)
  for k,v in pairs(tbl) do
    print("FLASHMOD - writeModule moduleName=" .. moduleName .. "; function="  .. k .. ". heap=" .. node.heap());
    if type(v) == "function" then
      a.writeFunction(k, v, moduleName);
      tbl[k] = nil;
    end
  end
end

function a.writeFunction(funcName, funcContents, moduleName)
  local fn = string.format("#_%s_%s", moduleName, funcName);
  if(string.len(fn)>31) then
    error("FLASHMOD -- Function '" .. moduleName .. "." .. funcName .. "' name is too long (".. string.len(fn) .."). Max 31 chars.");
  end

  file.open(fn, "w+");
  print("FLASHMOD -- About to dump function '" .. moduleName .. "."  .. funcName .. "'. heap=" .. node.heap());
  local status, result = pcall(string.dump, funcContents);
  if(status) then
    print("FLASHMOD -- Dumped ok. len=" .. string.len(result) .. ". heap=" .. node.heap());
    file.write(result);
  else
    error("FLASHMOD -- Function '" .. moduleName .. "." .. funcName .. "' is too large. Max size 1900 bytes.");
  end
  file.close();

end

function a.fhash(sourceFile)
  file.open(sourceFile, "r");
  local chunk = "";
  local fhash = "";
  repeat
    chunk = file.read(1024);
    if(chunk ~= nil) then
      fhash = crypto.toHex(crypto.hash("md5", chunk .. fhash));
    end
  until chunk == nil or string.len(chunk) ~= 1024
  file.close();
  return fhash;
--  return crypto.fhash(sourceFile);--FIXME why this doesnt work?
end

return a;
