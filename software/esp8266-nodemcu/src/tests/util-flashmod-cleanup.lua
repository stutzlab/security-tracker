print("FLASHMOD - removing all temp files");
local l = file.list();
for k,v in pairs(l) do
  if(string.sub(k, 1, 2) == "_#") then
    print("name:"..k..", size:"..v)
    file.remove(k);
  end
end
