-- Override the therminate program event
--[[ local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw --]]

-- run login
local username, passed = loadfile("./os/login/main.lua", nil, _ENV)()
if passed ~= true then
    os.reboot()
end
require("ui.main")(username)

-- Allow therminating programs again
-- os.pullEvent = oldPullEvent
