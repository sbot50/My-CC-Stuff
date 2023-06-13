local w,h = term.getSize()
local watermark = "Sbot Inc.©"
local username = nil

-- watermark function
local function pasteWatermark ()
    local oldx,oldy,oldz = term.getCursorPos()
    term.setCursorPos(w-#watermark+1,h)
    term.write(watermark)
    term.setCursorPos(oldx,oldy,oldz)
end

-- init buttons
local buttons = {
    Files = {
        x = 1,
        y = 1,
        w = 4,
        h = 0,
        label = "Files"
    },
    Settings = {
        x = w-#"Settings"+1,
        y = 1,
        w = 7,
        h = 0,
        label = "Settings"
    }
}
local selected = "Files"

-- draw buttons
local function drawButtons ()
    for _,value in pairs(buttons) do
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        if value.label == selected then
            term.setTextColor(colors.lightGray)
        end
        term.setCursorPos(value.x,value.y)
        term.write(value.label)
    end
end

-- clock
local function clock ()
    while true do
        local oldColor = term.getTextColor()
        local oldBackground = term.getBackgroundColor()
        local oldx,oldy = term.getSize()
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
        term.setCursorPos((w-1)/2-1,1)
        local time = textutils.formatTime(os.time(),true)
        term.write(string.format("%02d:%02d", time:match("^(%d+):(%d+)$")))
        term.setTextColor(oldColor)
        term.setBackgroundColor(oldBackground)
        term.setCursorPos(oldx,oldy)
        os.sleep(0.25)
    end
end

-- run clock
local function clockManager ()
    local updateClock = true
    local function clockEvents ()
        while true do
            local event,value = os.pullEvent("OSClockChange")
            updateClock = value
            break
        end
    end
    while true do
        if updateClock then
            drawButtons()
            parallel.waitForAny(clockEvents,clock)
        else 
            parallel.waitForAny(clockEvents)
        end
    end
end

-- check for click
local function waitForClick ()
    local enabled = true
    while true do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        local button = nil
        if event == "mouse_click" and enabled then
            for key,value in pairs(buttons) do
                if value.x <= eventData[3] and eventData[3] <= value.x+value.w and value.y <= eventData[4] and eventData[4] <= value.y+value.h then
                    button = key
                    break
                end
            end
            if button ~= nil and button ~= selected then
                selected = button
                drawButtons()
                break
            end
        elseif event == "MenuBar" then enabled = eventData[2] end
    end
end

-- start program
local function startProgram ()
    require("ui." .. string.lower(selected))(Username)
end

-- main
local function main (username)
    Username = username
    -- basic menu
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    pasteWatermark()
    drawButtons()

    while true do
        parallel.waitForAny(waitForClick,startProgram,clockManager)
        os.sleep()
    end
end

return main