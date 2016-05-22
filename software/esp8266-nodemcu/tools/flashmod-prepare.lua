--BASED ON https://gist.github.com/dnc40085/45e3af2fea22003b3ac2
--inside ESP8266 lua program, use "requireModule" in order to load precompiled modules

function writeModule(sourceFile, destDir)
  local moduleName = string.sub(sourceFile, 1, string.len(sourceFile)-4);
  print("Preparing " .. sourceFile .. ". Writing function files to ".. destDir .."...");

  --get file size
  local file = assert(io.open(sourceFile, "r"));
  local fileSize = file:seek("end");
  -- print("FS " .. fileSize);
  io.close(file);

  local filePos = 0;
  local funcContents = "";
  local line = "";
  repeat
    -- print("FSeek " .. filePos);
    file = assert(io.open(sourceFile, "r"));
    io.input(file);
    file:seek("set", filePos);
    line = io.read("*line");
    print("Read '" .. line .. "'");
    io.close(file);

    if(string.len(line)==0) then
      filePos = filePos + 1;
    else
      filePos = filePos + string.len(line);
    end

    --print("FP " .. filePos .. "; " .. line);
    if(string.sub(line, 1, 8) == "function" or filePos == fileSize) then
      --print("LOADING STRING TO LUA TABLE");
--      local funcPrefix = string.match(string.sub(funcContents,1,string.find(funcContents, "\n")), "function%s+(.*)[:.]");
--      local p = "z";
--      if(funcPrefix ~= nil) then
--        p = funcPrefix;
        --print("FUNCPREFIX " .. funcPrefix);
        --print("FUNCPREFIX contents=>>>" .. funcContents .. "<<<");
--      else
        --print("FUNCPREFIX NOT FOUND contents=>>>" .. funcContents .. "<<<");
--      end

      -- local funcName = string.match(string.sub(funcContents,1,string.find(funcContents, "\n")),
      --                               "function%s+(.*)[:.]");

      -- local func = loadstring(funcContents);
      -- if(func ~= nil) then
      --   for k,v in pairs(func) do
      --     if type(v) == "function" then
      --       print("Function " .. k .. " found in chunk");
      --       writeFunction(k, funcContents, moduleName, destDir);
      --     else
      --       print("Function not found in chunk");
      --     end
      --   end
      -- end

      --print("FUNCCONTENTS " .. funcContents);
      local funcName = string.match(funcContents, "function%s+(.-)%(");
      -- print("FUNCNAME1 '" .. tostring(funcName) .. "'");
      if(funcName~=nil) then
        local p = string.find(funcName, ".");
        if(p==null) then
          p = string.find(funcName, ":");
        end
        if(p~=nil) then
          funcName = string.sub(funcName, p+2);
        end

        -- print("FUNCNAME2 '" .. funcName .. "'");

        -- print("FUNCCONTENTS1 '" .. funcContents .. "'");
        funcContents = string.match(funcContents, "function.-%)(.*)end");
        -- print("FUNCCONTENTS2 '" .. funcContents .. "'");

        writeFunction(funcName, funcContents, moduleName, destDir);
      end

      funcContents = line .. "\n";
      --print("NEW FUNC heap=" .. node.heap());
      --print("FC " .. funcContents);
    else
      funcContents = funcContents .. line .. "\n";
      --print("ADDED FUNC heap=" .. node.heap());
      --print("FC " .. funcContents);
      if(string.len(funcContents)>2500) then
        error("FLASHMOD -- Function (".. string.sub(funcContents, 1, 20) ..") is too large. Break it in two or more methods keeping each function < 2500 bytes.");
      end
    end
  until filePos == fileSize;
  --print("FINISHED READING FILE");
  --end;
end

function writeFunction(funcName, funcContents, moduleName, destDir)
  local fn = string.format(destDir .. "/#_%s_%s", moduleName, funcName);
  if(string.len(fn)>31+string.len(destDir)+1) then
    error("Function '" .. moduleName .. "." .. funcName .. "' name is too long (>31). Shorten it by " .. (string.len(fn)-31) .. " chars");
  end

  local file = io.open(fn, "w+");
  io.output(file);
  --print("Dumping " .. moduleName .. "." .. funcName);
  -- local result = string.dump(funcContents);
  local result = funcContents;
  if(string.len(result)<10000) then
    io.write(result);
    print("Function " .. moduleName .. "."  .. funcName .. " written to disk. len=" .. string.len(result) .. ".");
  else
    error("Function " .. moduleName .. "." .. funcName .. " is too large and may not fit esp8266 ram. Break it into two or more methods keeping each function ~2000 bytes.");
  end
  io.close(file);

  -- print("ABOUT TO TEST " .. fn);
  -- local test = assert(loadfile(fn))("test");
  -- print("TEST " .. tostring(test));

end


if(arg[1] == nil or arg[2] == nil) then
  print("Usage: lua _flashmod_prepare2.lua [lua file] [dest dir]");
else
  writeModule(arg[1], arg[2]);
end
