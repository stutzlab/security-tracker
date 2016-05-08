--heap 1100

local apputils = {};

function apputils.isConnectedToInternet(callback)
  bootstrap_isConnectedToInternet(callback);
end

function apputils.stringSplit(str, separatorChar)
  local result = {};
  for token in string.gmatch(str, "([^".. separatorChar .."]+)") do
      result[#result + 1] = token
  end
  return result;
end

return apputils;
