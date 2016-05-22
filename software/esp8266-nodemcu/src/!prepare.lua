print("LAUNCHER -- Preprocess all modules " .. node.heap());
print("LAUNCHER -- CAPTIVE.LUA " .. node.heap());
dofile("!flashmod_prep.lua").writeModule("_captive.lua");
print("LAUNCHER -- BOOT.LUA " .. node.heap());
dofile("!flashmod_prep.lua").writeModule("_boot.lua");
print("LAUNCHER -- UPDATER.LUA " .. node.heap());
dofile("!flashmod_prep.lua").writeModule("_updater.lua");
print("LAUNCHER -- RUNNER.LUA " .. node.heap());
dofile("!flashmod_prep.lua").writeModule("_runner.lua");
print("LAUNCHER -- FILEDRAIN.LUA " .. node.heap());
dofile("!flashmod_prep.lua").writeModule("_filedrain.lua");
print("LAUNCHER -- LOG.LUA " .. node.heap());
dofile("!flashmod_prep.lua").writeModule("_log.lua");
print("LAUNCHER -- CONN.LUA " .. node.heap());
dofile("!flashmod_prep.lua").writeModule("_conn.lua");

