dofile("app-log.lua");

local a = {};

--adjust according to ram memory availability
local UPLOAD_CHUNK_SIZE = 1024;

--global vars
_app_uploadStatus = {
  pendingFiles = 0,
  pendingBytes = 0
};

function a.uploadDataToServer()
  log.log("UPLOAD -- Sending files to server");

  --sort nmea file names
  local fc = file.list();
  local fnames = {}
  local fsizes = {}
  local totalUploadPendingSize = 0;
  for n,s in pairs(fc) do
    if(strsub(k,1,strlen(app-FILE_NMEA_PREFIX)) == app-FILE_NMEA_PREFIX) then
      table.insert(fnames, n);
      table.insert(fsizes, s);
      totalUploadPendingSize = totalUploadPendingSize + s;
    end
  end
  table.sort(fnames);

  log.log("UPLOAD -- Total upload pending: nr files=".. #fnames .."; bytes=" .. totalUploadPendingSize);
  uploadStatus.pendingBytes = totalUploadPendingSize;
  uploadStatus.pendingFiles = #fnames;

  --send older files first
  dofile("app-upload-send.lua").uploadFiles(fnames, 1);

end

return a;
