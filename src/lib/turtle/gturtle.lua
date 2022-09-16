local t = {}
local turtle = turtle
t.move = {}
t.rotation = {}
t.position = {}
t.block = {}
t.block.dig = {}
t.block.place = {}
t.block.inspect = {}
t.block.detect = {}
t.item = {}
t.item.suck = {}
t.item.drop = {}
t.action = {}
t.action.compare = {}
t.action.attack = {}
t.fuel = {}
t.inventory = {}
t.inventory.slot = {}
t.inventory.equip = {}
-- vars
t.inventory.slot.count = 16
t.rotation.sides = { north = 2, east = 3, south = 4, west = 1 }
t.position.current = {x = 0, y = 0, z  = 0, r = 0}
-- movement
function t.move.up(dist)
    for i=1, dist, 1 do
        assert(turtle.up())
    end
end
function t.move.down(dist)
    for i=1, dist, 1 do
        assert(turtle.down())
    end
end
function t.move.left(dist)
    assert( turtle.turnLeft())
    for i=1, dist, 1 do
        assert(turtle.forward())
    end
    assert(turtle.turnRight())
end
function t.move.right(dist)
    assert( turtle.turnRight())
    for i=1, dist, 1 do
        assert(turtle.forward())
    end
    assert(turtle.turnLeft())
end
function t.move.forward(dist)
    for i=1, dist, 1 do
        assert(turtle.forward())
    end
end
function t.move.back(dist)
    for i = 1, dist, 1  do
        assert(turtle.back())
    end
end
function t.move.bulk(movement, dist, operation, operateAfer, ...)
    if operateAfer then
        for i=1, dist, 1 do
            movement(1)
            operation(...)
        end
    else
        for i=1, dist, 1 do
            operation(...)
            movement(1)
        end
    end
end
-- rotation
function t.rotation.right(count)
    for i = 1, count, 1 do
        if t.position.current.r == 4 then
            t.position.current.r = 1
        else
            t.position.current.r = t.position.current.r + 1
        end
        turtle.turnRight()
    end
end
function t.rotation.left(count)
    for i = 1, count, 1 do
        if t.position.current.r == 1 then
            t.position.current.r = 4
        else
            t.position.current.r = t.position.current.r - 1
        end
        turtle.turnLeft()
    end
end
function t.rotation.to (side)
    local df = t.position.current.r - side
    if df < 0 then
        t.rotation.right(math.abs(df))
    else
        t.rotation.left(math.abs(df))
    end
end
function t.rotation.get()
    loc1 = vector.new(gps.locate(2, false))
    if not turtle.forward() then
        for j=1,6 do
            if not turtle.forward() then
                turtle.dig()
            else break end
        end
    end
    loc2 = vector.new(gps.locate(2, false))
    turtle.back()
    heading = loc2 - loc1
    t.position.current.x, t.position.current.y, t.position.current.z = gps.locate(2, false)
    t.position.current.r = ((heading.x + math.abs(heading.x) * 2) + (heading.z + math.abs(heading.z) * 3))
    return t.position.current.r
end
-- fuel
t.fuel.get = turtle.getFuelLevel
t.fuel.limit = turtle.getFuelLimit
t.fuel.refuel = turtle.refuel
-- block
t.block.dig.up = turtle.digUp
t.block.dig.forward = turtle.dig
t.block.dig.down = turtle.digDown
t.block.place.up = turtle.placeUp
t.block.place.forward = turtle.place
t.block.place.down = turtle.placeDown
t.block.inspect.up = turtle.inspectUp
t.block.inspect.forward = turtle.inspect
t.block.inspect.down = turtle.inspectDown
t.block.detect.up = turtle.detectUp
t.block.detect.forward = turtle.detect
t.block.detect.down = turtle.detectDown
-- action
t.action.compare.up = turtle.compareUp
t.action.compare.forward = turtle.compare
t.action.compare.down = turtle.compareDown
t.action.attack.up = turtle.attackUp
t.action.attack.forward = turtle.attack
t.action.attack.down = turtle.attackDown
-- item
t.item.suck.up = turtle.suckUp
t.item.suck.forward = turtle.suck
t.item.suck.down = turtle.suckDown
t.item.drop.up = turtle.dropUp
t.item.drop.forward = turtle.drop
t.item.drop.down = turtle.dropDown
-- inventory
function t.inventory.select(item)
    for i=1, t.inventory.slot.count, 1 do
        local slotItem = turtle.getItemDetail(i)
        if slotItem ~= nil and slotItem.name == item then
            turtle.select(i)
            return i
        end
    end
end
t.inventory.slot.select = turtle.select
t.inventory.slot.itemCount = turtle.getItemCount
t.inventory.slot.itemSpace = turtle.getItemSpace
t.inventory.slot.getSelected = turtle.getSelectedSlot
t.inventory.equip.left = turtle.equipLeft
t.inventory.equip.right = turtle.equipRight
-- position
function t.position.get()
    t.position.current.x, t.position.current.y, t.position.current.z = gps.locate(2, false)
    return vector.new(t.position.current.x, t.position.current.y, t.position.current.z)
end
function t.position.save()
    local file = io.open(".location", "w")
    file:write(textutils.serialise(t.position.current, {compact = true, allow_repetitions = false}).."\r\n")
    file:flush()
    file:close()
end
function t.position.load()
    local file = io.open(".location", "r")
    local readed = file:read("a")
    file:close()
    t.position.current = textutils.unserialize(readed)
end

return t