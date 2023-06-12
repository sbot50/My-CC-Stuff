local w, h = term.getSize()
local watermark = "Sbot Inc.©"

-- watermark function
local function pasteWatermark ()
    local oldx,oldy,oldz = term.getCursorPos()
    term.setCursorPos(w-#watermark+1,h)
    term.write(watermark)
    term.setCursorPos(oldx,oldy,oldz)
end

-- make dots
local function makeDots (y)
    term.setCursorPos((w-1)/2-3,y)
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.black)
    term.write("  \149    \149 ")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lightGray)
    term.setCursorPos((w-1)/2+1,y)
    term.write(" ")
    term.setCursorPos((w-1)/2+3,y)
    term.write("\149")
    term.setCursorPos((w-1)/2-2,y)
    term.write("\149")
end

-- main
local function main (y)
    -- loading screen
    term.setBackgroundColor(colors.black)
    term.clear()
    pasteWatermark()
    local index = 1
    local type = "up"
    makeDots(y)
    while true do
        os.queueEvent("UpdateAnimation")
        makeDots(y)
        if index == 1 then
            term.setCursorPos((w-1)/2-3,y)
            term.setBackgroundColor(colors.gray)
            term.write(" ")
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.gray)
            term.write("\149")
        elseif index == 2 then
            term.setCursorPos((w-1)/2-1,y)
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.black)
            term.write("\149 ")
        elseif index == 3 then
            term.setCursorPos((w-1)/2+2,y)
            term.setBackgroundColor(colors.gray)
            term.write(" ")
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.gray)
            term.write("\149")
        elseif index == 4 then
            term.setCursorPos((w-1)/2+4,y)
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.black)
            term.write("\149 ")
        end
        if type == "up" then
            index = index + 1
            if index > 4 then
                index = 3
                type = "down"
            end
        else
            index = index - 1
            if index < 1 then
                index = 2
                type = "up"
            end
        end
        os.sleep(0.25)
    end
end

return main