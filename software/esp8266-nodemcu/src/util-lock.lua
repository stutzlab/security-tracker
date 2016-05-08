
local lockutil = {};

local locks = {};

--FIXME NEED EXTENSIVE TESTING

function lockutil.lock(lockName, next)
  local l = nil;
  if(locks[lockName] ~= nil) then
    local l = locks[lockName];
  else
    local l = lockutil.newLock();
  end
  l.lock(next);
end

function lockutil.newLock()
  local nexts = {};
  local function instance()
    local function unlock()
      if(#next>0) then
        local nxt = nexts[1];
        nexts[1] = nil;
        nxt(unlock);
      end
    end
    local function lock(next)
      if(#nexts == 0) then
        next(unlock);
      else
        nexts[#nexts] = next;
      end
    end
  end
  return instance();
end

return lockutil;