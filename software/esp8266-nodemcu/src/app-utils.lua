dofile("app-log.lua");

local apputils = {};

function apputils.stringSplit(str, separatorChar)
  local result = {};
  for token in string.gmatch(str, "([^".. separatorChar .."]+)") do
      result[#result + 1] = token
  end
  return result;
end

return apputils;
