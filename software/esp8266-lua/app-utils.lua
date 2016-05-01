
function isConnectedToInternet(callback)
  bootstrap_isConnectedToInternet(callback);
end

function _app_stringSplit(str, separatorChar)
  result = {};
  for token in string.gmatch(str, "([^".. separatorChar .."]+)") do
      result[#result + 1] = token
  end
  return result;
end

--THIS WILL REMOVE OLD FILES IN ORDER TO FREE SPACE ON STORAGE
--FILES WILL BE REMOVED ACCORDING TO FILE NAME SORTING
--minimumFreeBytes: will trigger removal of files
--freeupBytes: amount of bytes that will be freedup
--removeFileNamePrefix: file names prefix that will be removed in order to freeup storage
--return true if had to free up space, false otherwise
function _app_freeupStorage(minimumFreeBytes, freeupBytes, removeFileNamePrefix)
  local remaining, used, total = file.fsinfo();
  if(remaining < minimumFreeBytes) then
    __log("APP_UTILS -- Freeing up space on storage. available=" .. remaining .. "; minimum=" .. minimumFreeBytes .. "; removeFileNamePrefix=" .. removeFileNamePrefix);
    local fc = file.list();

    --sort nmea file names
    local fnames = {}
    for n in pairs(fc) do
      if(strsub(k,1,strlen(removeFileNamePrefix)) == removeFileNamePrefix) then
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
    __log("APP_UTILS -- Removed " .. deletions .. " files. available=" .. remaining .. "; used=" .. used .. "; total=" .. total);
    return true;
  else
    return false;
  end
end
