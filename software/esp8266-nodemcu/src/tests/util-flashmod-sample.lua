local a = {};

function a:doThis()
  print("DID THIS!");
  local sample2 = requireModule("util-flashmod-sample2.lua");
  sample2:doThis1();
  self.var = "b"
  print("2sample.var=".. self.var);
  self.var = "c"
  self:doThat();
end

function a:doThat()
  print("DID THAT!");
  local sample2 = requireModule("util-flashmod-sample2.lua");
  sample2.doThat1();
  print("3sample.var=".. self.var);
end

return a;
