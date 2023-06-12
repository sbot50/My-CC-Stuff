local w,h = term.getSize()

-- loadingbar
local function progressBar(percent,x,y,w,h,fg,bg)
    local filled = w*(percent/100)
    term.setCursorPos(x,y)
    term.setBackgroundColor(fg)
    term.write(string.rep(" ",filled))
    term.setBackgroundColor(bg)
    term.write(string.rep(" ",w-filled))
end

-- main
local function main (y)
    while true do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        if event == "PBKDF2" then
            progressBar(eventData[2]/2200*100,(w-1)/2-4,y,11,1,colors.green,colors.gray)
        end
    end
end

return main