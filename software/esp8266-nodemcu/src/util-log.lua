--heap 2100

local logutils = {};

local logs = {};
local config = {
  maxLogs = 10,
  print = true
}

function logutils.log(message)
  if(config.print) then
    print(message);
  end
  --limit message logs in memory
  if(config.maxLogs>0) then
      if(#logs>=config.maxLogs) then
        table.remove(logs, 1);
      end
      logs[#logs+1] = message
  end
end

function logutils.getLogs()
  return logs;
end

function logutils.setMaxLogs(maxLogs)
  config.maxLogs = maxLogs;
end

function logutils.setPrintLogs(print)
  config.print = print;
end

return logutils;
