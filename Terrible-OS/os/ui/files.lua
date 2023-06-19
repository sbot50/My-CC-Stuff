local w,h = term.getSize()
local Username = nil
local Skip = 0

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

-- Get Files
local function getFiles (dir)
    local dir = dir:sub(3)
    local rawFiles = fs.list(dir)
    local folders = {}
    local luaFiles = {}
    local files = {}
    local dotFiles = {}

    for _,f in pairs(rawFiles) do
        local fileType = "Folder"
        local fileName = f
        if not fs.isDir(dir .. "/" .. f) then
            if f:sub(1,1) == "." then
                fileName = f
                fileType = "Hidden"
            else
                if string.find(f, "%.") then
                    fileName = string.match(f,"(.+)%..+")
                    fileType = string.gsub(string.sub(dir .. "/" .. f,string.find(dir .. "/" .. f, "%.") + 1), "^%l", string.upper)
                    if #fileType > 8 then fileType = string.sub(fileType,1,5) .. "..." end
                    if #fileName > w-18 then fileName = string.sub(fileName,1,w-21) .. "..." end
                else fileType = "File" end
            end
        end
        local fileStats = {
            name = fileName,
            type = fileType,
            size = formatBytes(fs.getSize(dir .. "/" .. f)),
            fullName = dir .. "/" .. f
        }
        if fs.isDir(dir .. "/" .. f) then
            table.insert(folders,fileStats)
        elseif fileType == "Hidden" then
            table.insert(dotFiles,fileStats)
        elseif fileType == "Lua" then
            table.insert(luaFiles,fileStats)
        else
            table.insert(files,fileStats)
        end
    end

    local allFiles = {}
    for i = 1, #folders do
        allFiles[#allFiles + 1] = folders[i]
    end
    for i = 1, #dotFiles do
        allFiles[#allFiles + 1] = dotFiles[i]
    end
    for i = 1, #luaFiles do
        allFiles[#allFiles + 1] = luaFiles[i]
    end
    for i = 1, #files do
        allFiles[#allFiles + 1] = files[i]
    end
    return allFiles
end

-- Draw Files
local function drawFiles (allFiles,hiddenFiles,showHidden,skip)
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.black)
    local height = 4
    local files = deepcopy(allFiles)
    local skip = skip or 0
    if #files >= 16 then
        for i = #files, 16 + skip, -1 do
            table.remove(files, i)
        end
        for i = 1, skip do
            table.remove(files, 1)
        end
    end
    for _,f in pairs(files) do
        term.setTextColor(colors.white)
        local hasFound
        if not showHidden then
            for _, value in pairs(hiddenFiles) do
                local name = f.fullName
                if name:sub(1, 2) == './' then name = name:sub(3)
                elseif name:sub(1, 1) == '/' then name = name:sub(2) end
                if value == name or name:sub(1,1) == "." then
                    hasFound = true
                end
            end
        end
        if not hasFound then
            if f.type == "Folder" then
                term.setTextColor(colors.green)
                f.name = f.name .. "/"
            elseif f.type == "Hidden" then term.setTextColor(colors.gray)
            elseif f.type == "Lua" then term.setTextColor(colors.blue) end
            term.setCursorPos(1,height)
            term.clearLine()
            print(f.name)
            term.setCursorPos(w-16,height)
            print(f.type)
            term.setCursorPos(w-#f.size+1,height)
            print(f.size)
            height = height + 1
        end
    end
    term.setTextColor(colors.green)
    term.setCursorPos(1,h)
    term.write("+")
    term.setCursorPos(w-1,h)
    term.setTextColor(colors.gray)
    if skip > 0 then term.setTextColor(colors.green) end
    term.write("\x1E")
    term.setTextColor(colors.gray)
    if #allFiles-skip >= 16 then term.setTextColor(colors.green) end
    term.write("\x1F")
end

-- clicked File
local function clickedFile (allFiles,hiddenFiles,showHidden,y,skip)
    local files = deepcopy(allFiles)
    local skip = skip or 0
    if not showHidden then
        for i,v in ipairs(hiddenFiles) do
            for j,k in ipairs(files) do
                local name = k.fullName
                if name:sub(1, 2) == './' then name = name:sub(3)
                elseif name:sub(1, 1) == '/' then name = name:sub(2) end
                if name == v then
                    table.remove(files,j)
                end
            end
        end
    end
    return files[y-3+skip]
end

-- format bytes
function formatBytes(bytes)
    local units = {" B", "KB", "MB", "GB", "TB"}
    local unitIndex = 1
    while bytes >= 1024 and unitIndex < #units do
        bytes = bytes / 1024
        unitIndex = unitIndex + 1
    end
    return string.format("%.1f%s", bytes, units[unitIndex])
end

-- get string sub
local function breh(str, n)
    local result = ""
    local len = string.len(str)
    local removed = 0
    if n > len then
        result = str
    else
        removed = len - n
        for i = len - n + 1, len do
            result = result .. string.sub(str, i, i)
        end
    end
    return result, removed
end

-- clear screen
local function clearScreen (path)
    term.setBackgroundColor(colors.black)
    for i=4,h,1 do
        term.setCursorPos(1,i)
        term.write(string.rep(" ",w))
    end
    term.setCursorPos(1,2)
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.white)
    term.clearLine()
    local stringPath = table.concat(path,"/") .. "/"
    if #stringPath > w then stringPath = breh(stringPath,w) end
    term.write(stringPath)
    term.setCursorPos(1,3)
    term.setBackgroundColor(colors.gray)
    term.clearLine()
    term.write("Name")
    local text = "Type     Size    "
    term.setCursorPos(w-#text+1,3)
    term.write(text)
end

-- clicked dir
local function clickedDir (path,x)
    if #(table.concat(path,"/") .. "/") > w then
        local _,add = breh(table.concat(path,"/") .. "/",w)
        x = x + add
    end
    local index = 1
    local count = 0
    for i, item in ipairs(path) do
        count = count + #item + 1
        if x <= count then
            index = i
            break
        end
    end
    if x > count then return nil
    else return index end 
end

-- table.sub
function table.sub(t, start_index, end_index)
    local new_table = {}
    for i = start_index, end_index do
        table.insert(new_table, t[i])
    end
    return new_table
end

local function main (username)
    Username = username
    local path = {"."}
    
    clearScreen(path)

    local hiddenFiles = {
        "os",
        "rom",
        "startup.lua"
    }

    local file = io.open("./os/login/accounts.lson", "rb")
    local db = file:read("*all")
    file:close()
    db = textutils.unserialize(db);

    local allFiles = getFiles(table.concat(path))
    drawFiles(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],Skip)

    while true do
        local eventData = {os.pullEvent()}
        local event = eventData[1]
        local x = eventData[3]
        local y = eventData[4]
        if event == "mouse_click" then
            if y == 2 then
                local clickedIndex = clickedDir(path,x)
                if clickedIndex ~= nil then
                    Skip = 0
                    path = table.sub(path,1,clickedIndex)
                    clearScreen(path)
                    local allFiles = getFiles(table.concat(path,"/"))
                    drawFiles(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],Skip)
                end
            elseif x == w and y == h then
                local allFiles = getFiles(table.concat(path,"/"))
                if #allFiles-Skip >= 16 then
                    Skip = Skip + 1
                    drawFiles(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],Skip)
                end
            elseif x == w-1 and y == h and Skip > 0 then
                Skip = Skip - 1
                local allFiles = getFiles(table.concat(path,"/"))
                drawFiles(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],Skip)
            end
            if eventData[2] == 1 then
                if y >= 4 and y < h then
                    local allFiles = getFiles(table.concat(path,"/"))
                    local file = clickedFile(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],eventData[4],Skip)
                    if file ~= nil and file.type == "Folder" then
                        Skip = 0
                        path[#path+1] = file.name
                        clearScreen(path)
                        local allFiles = getFiles(table.concat(path,"/"))
                        drawFiles(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],Skip)
                    elseif file ~= nil then
                        local filePath = file.fullName
                        if filePath:sub(1,1) == "/" then filePath = filePath:sub(2) end
                        filePath = "./" .. filePath
                        os.queueEvent("OSClockChange",false)
                        os.queueEvent("MenuBar",false)
                        if db[Username].settings.Root.Root or db[Username].settings.Root.Read then
                            local base_fsopen = fs.open
                            local base_isReadOnly = fs.isReadOnly
                            local base_openTab = shell.openTab
                            if not db[Username].settings.Root.Root and not db[Username].settings.Root.Write then
                                function fs.open(path, mode)
                                    if path == filePath:sub(3) and mode ~= "r" and mode ~= "rb" then return nil, "Permission denied" end
                                    return base_fsopen(path, mode)
                                end
                                function fs.isReadOnly(path)
                                    return path == filePath:sub(3) or base_isReadOnly(path)
                                end
                            end
                            if not db[Username].settings.Root.Root and not db[Username].settings.Root.Execute then
                                function shell.openTab(string)
                                    if string == "/.temp." .. file.name then return nil end
                                    return base_openTab(string)
                                end
                            end
                            shell.run("edit " .. filePath)
                            fs.open = base_fsopen
                            fs.isReadOnly = base_isReadOnly
                            shell.openTab = base_openTab
                        end
                        os.queueEvent("MenuBar",true)
                        os.queueEvent("OSClockChange",true)
                        clearScreen(path)
                        local allFiles = getFiles(table.concat(path,"/"))
                        drawFiles(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],Skip)
                    end
                end
            elseif eventData[2] == 2 then

            elseif eventData[2] == 3 then

            end
        elseif event == "mouse_scroll" then
            if eventData[2] == 1 then
                local allFiles = getFiles(table.concat(path,"/"))
                if #allFiles-Skip >= 16 then
                    Skip = Skip + 1
                    drawFiles(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],Skip)
                end
            elseif eventData[2] == -1 and Skip > 0 then
                Skip = Skip - 1
                local allFiles = getFiles(table.concat(path,"/"))
                drawFiles(allFiles,hiddenFiles,db[Username].settings["Show hidden files"],Skip)
            end
        end
    end
end

return main