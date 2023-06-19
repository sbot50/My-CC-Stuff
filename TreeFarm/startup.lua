-- refuel
local function refuel ()
    local fuelNeeded = (2000-turtle.getFuelLevel())/15
    if fuelNeeded > 0 then
        for i = 1,16,1 do
            turtle.select(i)
            if turtle.getItemDetail() and turtle.getItemDetail().name ~= "minecraft:oak_sapling" and turtle.getItemDetail().name ~= "minecraft:stick" then
                local fuelCount = turtle.getItemDetail().count
                if fuelNeeded < fuelCount then fuelCount = fuelNeeded end
                local refueled,_ = turtle.refuel(fuelNeeded)
                if refueled then fuelNeeded = fuelNeeded - fuelCount end
            end
        end
        turtle.select(1)
    end
end

-- Select Sapling
local function sapling ()
    for i = 1,16,1 do
        turtle.select(i)
        if turtle.getItemDetail() and turtle.getItemDetail().name == "minecraft:oak_sapling" then 
            return
        end
    end
    turtle.select(1)
end

-- DESTROY
local function cutDown (right)
    turtle.dig()
    turtle.forward()
    local up = 0
    while true do
        local solidUp,blockUp = turtle.inspectUp()
        local solidFront,blockFront = turtle.inspect()
        if solidFront and blockFront.name == "minecraft:oak_log" or blockFront.name == "minecraft:oak_leaves" then turtle.dig() end
        turtle.turnLeft()
        local solidFront,blockFront = turtle.inspect()
        if solidFront and blockFront.name == "minecraft:oak_log" or blockFront.name == "minecraft:oak_leaves" then turtle.dig() end
        turtle.turnRight()
        if not solidUp or (blockUp.name ~= "minecraft:oak_log" and blockFront.name ~= "minecraft:oak_leaves")  then
            break
        else
            up = up + 1
            turtle.digUp()
            turtle.up()
        end
    end
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1,up,1 do
        local solidDown,blockDown = turtle.inspectDown()
        local solidFront,blockFront = turtle.inspect()
        if solidFront and blockFront.name == "minecraft:oak_log" or blockFront.name == "minecraft:oak_leaves" then turtle.dig() end
        turtle.turnLeft()
        local solidFront,blockFront = turtle.inspect()
        if solidFront and blockFront.name == "minecraft:oak_log" or blockFront.name == "minecraft:oak_leaves" then turtle.dig() end
        turtle.turnRight()
        if solidDown then
            break
        else
            turtle.digDown()
            turtle.down()
        end
    end
    turtle.forward()
    turtle.turnLeft()
    turtle.turnLeft()
    sapling()
    turtle.place()
    if right then turtle.turnRight()
    else turtle.turnLeft() end
end

-- Plant
local function plant ()
    if not turtle.getItemDetail() or turtle.getItemDetail().name ~= "minecraft:oak_sapling" then sapling() end
    turtle.turnRight()
    local solid,block = turtle.inspect()
    if not solid then 
        turtle.place()
        turtle.turnLeft()
    elseif block.name == "minecraft:oak_log" then
        cutDown()
    else
        turtle.turnLeft()
    end
    turtle.turnLeft()
    local solid,block = turtle.inspect()
    if not solid then 
        turtle.place()
    elseif block.name == "minecraft:oak_log" then
        cutDown(true)
        turtle.turnLeft()
    end
    turtle.turnRight()
end

-- Move
local function move ()
    turtle.turnRight()
    turtle.forward()
    turtle.turnLeft()
    turtle.forward()
    local turnRight = true
    for x = 1,4,1 do
        for z = 1,13,1 do
            if z%2 ~= 0 then plant() end
            turtle.forward()
        end
        if x ~= 4 then
            if turnRight then turtle.turnRight()
            else turtle.turnLeft() end
            turtle.forward()
            turtle.forward()
            turtle.forward()
            turtle.forward()
            if turnRight then turtle.turnRight()
            else turtle.turnLeft() end
            turtle.forward()
            turnRight = not turnRight
        end
    end
end

-- Return
local function back ()
    turtle.turnRight()
    for i = 1,13,1 do
        turtle.forward()
    end
    turtle.turnRight()
end


-- Pickup Items
local function pickup ()
    while true do
        if not turtle.inspect() then
            turtle.suck()
        end
        sleep()
    end
end

-- Deposit
local function depot ()
    local saveSapling = true
    for i = 1,16,1 do
        turtle.select(i)
        if turtle.getItemDetail() and turtle.getItemDetail().name == "minecraft:oak_sapling" and saveSapling then
            saveSapling = false
            local keep = turtle.getItemDetail().count-10
            if keep < 0 then keep = 0 end
            turtle.dropDown(keep)
        else
            turtle.dropDown()
        end
    end
end

-- main
local function main ()
    refuel()
    while true do
        move()
        back()
        refuel()
        depot()
    end
end

parallel.waitForAny(main,pickup)

