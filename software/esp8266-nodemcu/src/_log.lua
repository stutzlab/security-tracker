--heap 2100

local a = {};

function a:init()
  self.logs = {};
  self.config = {
    maxLogs = 0,
    print = true
  }
end

function a:log(message)
  if(self.config.print) then
    print(message);
  end
  --limit message logs in memory
  if(self.config.maxLogs>0) then
      if(self.#logs>=self.config.maxLogs) then
        table.remove(self.logs, 1);
      end
      self.logs[self.#logs+1] = message
  end
end

function a:getLogs()
  return self.logs;
end

function a:setMaxLogs(maxLogs)
  self.config.maxLogs = maxLogs;
end

function a:setPrintLogs(print)
  self.config.print = print;
end

return a;
