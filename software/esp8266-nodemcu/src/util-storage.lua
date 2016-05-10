--heap 2400
--THIS WILL REMOVE OLD FILES IN ORDER TO FREE SPACE ON STORAGE
--FILES WILL BE REMOVED ACCORDING TO FILE NAME SORTING
--minimumFreeBytes: will trigger removal of files
--freeupBytes: amount of bytes that will be freedup
--removeFileNamePrefix: file names prefix that will be removed in order to freeup storage
--return true if had to free up space, false otherwise

if(log == nil) then
    log = dofile("util-log.lua");
end

local storageutils = {};

function storageutils.freeupStorage(minimumFreeBytes, freeupBytes, removeFileNamePrefix)
  local remaining, used, total = file.fsinfo();
  if(remaining < minimumFreeBytes) then
    log.log("app-UTILS -- Freeing up space on storage. available=" .. remaining .. "; minimum=" .. minimumFreeBytes .. "; freeupBytes=" .. freeupBytes .. "; removeFileNamePrefix=" .. removeFileNamePrefix);

    --sort nmea file names
    local fc = file.list();
    local fnames = {}
    for n in pairs(fc) do
      if(string.sub(n,1,string.len(removeFileNamePrefix)) == removeFileNamePrefix) then
        table.insert(fnames, n);
      end
    end
    table.sort(fnames);

    --delete oldest files first
    local deletions = 0;
    for i,fn in ipairs(fnames) do
      local remaining, used, total = file.fsinfo();
      if(remaining < freeupBytes) then
        file.remove(fn);
        deletions = deletions + 1;
      end
    end

    local remaining, used, total = file.fsinfo();
    log.log("app-UTILS -- Removed " .. deletions .. " files. available=" .. remaining .. "; used=" .. used .. "; total=" .. total);
    return true;
  else
    return false;
  end
end

return storageutils;
