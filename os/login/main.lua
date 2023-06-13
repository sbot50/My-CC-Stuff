local hash = require "login.hash"
local Success = false
local Username = nil
local w, h = term.getSize()
local watermark = "Sbot Inc.©"

-- watermark function
local function pasteWatermark ()
    local oldx,oldy,oldz = term.getCursorPos()
    term.setCursorPos(w-#watermark+1,h)
    term.write(watermark)
    term.setCursorPos(oldx,oldy,oldz)
end

-- Quick salt (made by Fatboychummy)
local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local chars_n = #chars
local function gen_salt(length)
    local salt = ""
    for i = 1, (length or 32) do
        local rng = math.random(chars_n)
        salt = salt .. string.sub(chars,rng,rng)
    end
    return salt
end

-- text input function
local function input (eventType, eventData, input, base, w, height, secret)
    if eventType == "char" then
        if #(input .. eventData) == 1 then
            if secret then
                term.write("*" .. string.rep(" ", #base-1))
            else
                term.write(input .. eventData .. string.rep(" ", #base-1))
            end
        end
        term.setCursorPos((math.ceil(w/4)+1)+1,height)
        input = input .. eventData
        local i = 0+(#input-(w/2-4))
        if i < 0 then 
            i = 0
        end
        if secret then
            term.write(string.rep("*", #string.sub(input, i, #input)))
        else
            term.write(string.sub(input, i, #input))
        end
        if #input > w/2-4 then
            term.setCursorPos((math.ceil(w/4)+1)+(w/2-2),height)
        end
    elseif eventType == "key" and eventData == "backspace" then
        term.setCursorPos((math.ceil(w/4)+1)+1,height)
        input = string.sub(input, 1, #input-1)
        if #(input .. " ") > (w/2-3) then
            local write = ""
            if secret then
                write = string.sub(string.rep("*", #input) .. " ", 0+(#(input .. " ")-(w/2-4)), #(input .. " "))
            else
                write = string.sub(input .. " ", 0+(#(input .. " ")-(w/2-4)), #(input .. " "))
            end
            if #input > (w/2-3) then
                if secret then
                    write = string.sub(string.rep("*", #input), 0+(#input-(w/2-4)), #input)
                else
                    write = string.sub(input, 0+(#input-(w/2-4)), #input)
                end
            end
            term.write(write)
            term.setCursorPos((math.ceil(w/4)+1)+(w/2-2),height)
        else
            if secret then
                term.write(string.rep("*",#input) .. " ")
            else
                term.write(input .. " ")
            end
            if #input == 0 then
                term.setTextColor(colors.lightGray)
                term.setCursorPos((math.ceil(w/4)+1)+1,height)
                term.write(base .. string.rep(" ",(w/2-(2+#base))))
                term.setTextColor(colors.white)
                term.setCursorPos((math.ceil(w/4)+1)+1,height)
            end
            term.setCursorPos((math.ceil(w/4)+1)+1+#input,height)
        end
    end
    return input
end

-- password screen
term.setBackgroundColor(colors.black)
term.clear()
pasteWatermark()
for i = 0,4,1 do
    term.setBackgroundColor(colors.gray)
    term.setCursorPos((math.ceil(w/4)+1),math.ceil(h/2-(2-i)))
    term.write(string.rep(" ",(w/2)))
    term.setTextColor(colors.black)
    term.setCursorPos((math.ceil(w/4)+1)-1,math.ceil(h/2-(2-i)))
    term.write("\149")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.setCursorPos((math.ceil(w/4)+1)+(w/2),math.ceil(h/2-(2-i)))
    term.write("\149")
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.lightGray)
term.setCursorPos((math.ceil(w/4)+1)+1,math.ceil(h/2-1))
term.write("Name" .. string.rep(" ",(w/2-6)))
term.setCursorPos((math.ceil(w/4)+1)+1,math.ceil(h/2+1))
term.write("Password" .. string.rep(" ",(w/2-10)))

-- reset cursor pos, add blinking
term.setTextColor(colors.white)
term.setCursorPos((math.ceil(w/4)+1)+1,math.ceil(h/2-1))
term.setCursorBlink(true)
local field = "Name"
local username = ""
local password = ""

-- username input
while true do
    local eventData = {os.pullEvent()}
    local event = eventData[1]
    if event == "char" then
        if field == "Name" then
            username = input ("char", eventData[2], username, field, w, math.ceil(h/2-1), false)
        elseif field == "Password" then
            password = input ("char", eventData[2], password, field, w, math.ceil(h/2+1), true)
        end
    elseif event == "key" then
        if keys.getName(eventData[2]) == "backspace" then
            if field == "Name" then
                username = input ("key", keys.getName(eventData[2]), username, field, w, math.ceil(h/2-1), false)
            elseif field == "Password" then
                password = input ("key", keys.getName(eventData[2]), password, field, w, math.ceil(h/2+1), true)
            end
        elseif keys.getName(eventData[2]) == "enter" then
            if field == "Name" then
                field = "Password"
                term.setCursorPos((math.ceil(w/4)+1)+1+#password,math.ceil(h/2+1))
            elseif field == "Password" then
                field = "Hashing"
                term.setCursorBlink(false)
                local file = io.open("./os/login/accounts.lson", "rb")
                local db = file:read("*all")
                file:close()
                db = textutils.unserialize(db);
                if db[username] then
                    local salt = db[username].salt;
                    local pwcheck = db[username].password;
                    local function waitForHash ()
                        password = hash.pbkdf2(password, salt, 2200)
                    end
                    local function loading ()
                        require("loading.loading")((h-1)/2)
                    end
                    local function loadingBar ()
                        require("loading.progress")((h-1)/2+2)
                    end
                    parallel.waitForAny(waitForHash, loading, loadingBar)
                    if table.concat(password) == table.concat(pwcheck) then
                        Username = username
                        Success = true
                        break
                    else
                        os.reboot()
                    end
                else
                    os.reboot()
                end
                -- -- Add to install and new user dialogue. Or just make 0 users mean it makes a new one.
                -- if username == "sbot50" and password == "ComputerCraft" then
                --     local salt = gen_salt(50)
                --     print(salt)
                --     password = hash.pbkdf2(password, salt, 2200)
                --     local db = {}
                --     db[username] = {salt = salt, password = password}
                --     db = textutils.serialize(db);
                --     file = io.open("./os/login/accounts.lson", "w+")
                --     file:write(db)
                --     file:close()
                --     Success = true
                --     break
                -- else
                --     os.reboot()
                -- end
            end
        elseif keys.getName(eventData[2]) == "up" or keys.getName(eventData[2]) == "down" then
            if field == "Name" then
                field = "Password"
                term.setCursorPos((math.ceil(w/4)+1)+1+#password,math.ceil(h/2+1))
            elseif field == "Password" then
                field = "Name"
                term.setCursorPos((math.ceil(w/4)+1)+1+#username,math.ceil(h/2-1))
            end
        end
    elseif event == "mouse_click" then
        if eventData[4] == math.ceil(h/2-1) and eventData[3] >= (math.ceil(w/4)+1)+1 and eventData[3] <= (math.ceil(w/4)+1)+(w/2-2) then
            field = "Name"
            term.setCursorPos((math.ceil(w/4)+1)+1+#username,math.ceil(h/2-1))
        elseif eventData[4] == math.ceil(h/2+1) and eventData[3] >= (math.ceil(w/4)+1)+1 and eventData[3] <= (math.ceil(w/4)+1)+(w/2-2) then
            field = "Password"
            term.setCursorPos((math.ceil(w/4)+1)+1+#password,math.ceil(h/2+1))
        end
    end
end
return Username, Success
