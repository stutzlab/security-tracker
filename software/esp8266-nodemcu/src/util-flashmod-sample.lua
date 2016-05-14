local a = {}; 

function a:doThis()
  print("DID IT!");
  local sample2 = requireFlashModule("util-flashmod-sample2.lua");
  sample2.doThis1();
  self:doThat();
end

function a:doThat()
  print("DID THAT!");
  local sample2 = requireFlashModule("util-flashmod-sample2.lua");
  sample2.doThat1();
end

return a;
