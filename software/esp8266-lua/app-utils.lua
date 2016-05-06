
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
