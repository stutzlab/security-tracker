dofile("app-log.lua");

local a = {};

log.log("REGISTRATION -- Checking App registration...");

local FILE_REGISTRATION = "app-registration";
local URL_APPS = "http://tracker.stutzthings.com/tracker/devices/apps";

local registrationCounter = 0;
local registration = nil;

function a.startAppRegistration(callback)
  log.log("REGISTRATION -- Initiating captive portal for App registration");
  local registrationCaptive = dofile("app-registration-captivehandler.lua");
  registrationCaptive.setup(FILE_REGISTRATION, URL_APPS);
  dofile("util-captive.lua").start(
        registrationCaptive.appRegistrationRequestHandler,
        10000,
        callback)
  registrationCaptive = nil;
end

--callback(true) if registration is valid (even offline)
function a.checkAppRegistration(callback)
  dofile("app-registration-check.lua").checkAppRegistration(FILE_REGISTRATION, callback);
end

function a.getRegistration()
  local rf = file.open(FILE_REGISTRATION, "r");
  local registration = nil;
  if(rf) then
    log.log("REGISTRATION -- Registration file found");
    local registration = cjson.decode(file.read());
  else
    log.log("REGISTRATION -- Registration file NOT found");
  end
  file.close();
  return registration;
end

return a;
