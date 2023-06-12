local w,h = term.getSize()
local Username = nil

-- lua is dumb
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Change Setting
local function changeSetting (db,setting)
    local db = deepcopy(db)
    for key,value in pairs(db) do
        if type(value) == "table" then
            db[key] = changeSetting(value,setting)
        elseif type(value) ~= "table" and db[setting] ~= nil and key == setting then
            db[setting] = not db[setting]
        end
    end
    return db
end

-- Click settings
local function clickSettings (keys,h,r,x,y)
    local out = nil
    for _,value in pairs(keys) do
        if type(value) == "table" then
            out = clickSettings(value,h,r+1,x,y)
        else
            if math.floor(w/2)+3+(r*2) <= x and x <= math.floor(w/2)+3+(r*2)+#value+1 and y == h then
                out = value
                break
            end
        end
        if out ~= nil then break end
        h = h+1
    end
    return out
end

-- settings function
local function drawSettings (db,keyOrder,settingsHeight,overridden,recurse)
    local index = 1
    local db = deepcopy(db)
    for _,realKey in pairs(keyOrder) do
        if type(realKey) ~= "table" then
            local key = realKey
            local value = db[key]
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.white)
            term.setCursorPos(math.floor(w/2)+3+(recurse*2),settingsHeight)
            if (type(value) ~= "table" and value) or (type(value) == "table" and value[key]) then
                term.setTextColor(colors.black)
            end
            term.write("\136 ")
            term.setTextColor(colors.white)
            term.write(key)
            settingsHeight = settingsHeight + 1
            if type(value) == "table" then
                local beginHeight = settingsHeight
                local override = overridden
                if override ~= true then override = value[key] end
                value[key] = nil
                index = index + 1
                settingsHeight = drawSettings(value,keyOrder[index],beginHeight,override,recurse+1)
                for i = beginHeight,settingsHeight-1,1 do
                    term.setBackgroundColor(colors.lightGray)
                    if override then term.setBackgroundColor(colors.black) end
                    term.setTextColor(colors.gray)
                    term.setCursorPos(math.floor(w/2)+3+(recurse*2),i)
                    if i == settingsHeight-1 then
                        term.setBackgroundColor(colors.gray)
                        term.setTextColor(colors.lightGray)
                        if override then term.setTextColor(colors.black) end
                        term.write("\138")
                    else
                        term.write("\149")
                    end
                    term.setBackgroundColor(colors.gray)
                    term.setTextColor(colors.lightGray)
                    if override then term.setTextColor(colors.black) end
                    term.setCursorPos(math.floor(w/2)+3+(recurse*2+1),i)
                    term.write("\132")
                end
                settingsHeight = beginHeight
            end
        end
        index = index + 1
    end
    return settingsHeight
end

local function main (username)
    Username = username
    term.setTextColor(colors.white)
    for i=2,h,1 do
        term.setCursorPos(1,i)
        term.setBackgroundColor(colors.lightGray)
        term.write(string.rep(" ",math.floor(w/2)))
        term.setBackgroundColor(colors.black)
        term.write(" ")
        term.setBackgroundColor(colors.gray)
        term.write(string.rep(" ",math.floor(w/2)))
    end
    term.setCursorPos(math.floor(w/2)+2,2)
    term.setTextColor(colors.blue)
    term.write("Account Settings")
    term.setBackgroundColor(colors.lightGray)
    term.setCursorPos(1,2)
    term.write("Accounts")

    local file = io.open("./os/login/accounts.lson", "rb")
    local db = file:read("*all")
    file:close()
    db = textutils.unserialize(db);
    
    local keyOrder = {"Show hidden files","Root",{"Execute","Read","Write","Accounts",{"Create","Delete","Edit"}}}

    local keys = {}
    for key,_ in pairs(db) do keys[#keys+1] = key end
    table.sort(keys)

    local height = 3
    local settingsHeight = 4
    for _,key in pairs(keys) do
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.lightGray)
        value = db[key]
        if key == Username then
            term.setTextColor(colors.gray)
            term.setCursorPos(1,height)
            term.write(key)
            drawSettings (db[key].settings,keyOrder,settingsHeight,false,0)
        else
            term.setCursorPos(1,height)
            term.write(key)
        end
        height = height + 1
    end

    while true do
        local eventData = {os.pullEvent("mouse_click")}
        local event = eventData[1]
        if event == "mouse_click" then
            local x = eventData[3]
            local y = eventData[4]
            if math.floor(w/2)+2 <= x and x <= math.floor(w/2)+2+w and y >= 3 then
                local h = 4
                local r = 0
                setting = clickSettings(keyOrder,h,r,x,y)
                if setting ~= nil then
                    db[Username].settings = changeSetting(db[Username].settings,setting)
                    serDb = textutils.serialize(db);
                    file = io.open("./os/login/accounts.lson", "w+")
                    file:write(serDb)
                    file:close()
                    local settingsHeight = 4
                    drawSettings (db[Username].settings,keyOrder,settingsHeight,false,0)
                end
            end
        end
    end
end

return main