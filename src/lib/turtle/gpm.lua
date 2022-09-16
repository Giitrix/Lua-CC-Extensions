local mt = {}
mt.moveType = { basic = 1, diagonal = 2, unreal = 3}

-- movement Help
-- x+   3   east
-- x-   1   west
-- z+   4   south
-- z-   2   north

-- point type {x, y, z}
-- points - array of point

-- go to pos.x - difx
function mt._gox(difx, operateAfter, operation, ...)
    if difx > 0 then
        turtle.rotation.to(turtle.rotation.sides.east)
        if operateAfter ~= nil and operation ~= nil then
            turtle.move.bulk(turtle.move.forward, difx, operation, operateAfter, ...)
        else
            turtle.move.forward(difx)
        end
    else
        if difx < 0 then
            turtle.rotation.to(turtle.rotation.sides.west)
            if operateAfter ~= nil and operation ~= nil then
                turtle.move.bulk(turtle.move.forward, math.abs(difx), operation, operateAfter, ...)
            else
                turtle.move.forward(math.abs(difx))
            end
        end
    end
end
-- go to pos.y - dify
function mt._goy(dify, operateAfter, operation, ...)
    if dify > 0 then
        if operateAfter ~= nil and operation ~= nil then
            turtle.move.bulk(turtle.move.up, dify, operation, operateAfter, ...)
        else
            turtle.move.up(dify)
        end
    else
        if dify < 0 then
            if operateAfter ~= nil and operation ~= nil then
                turtle.move.bulk(turtle.move.down, math.abs(dify), operation, operateAfter, ...)
            else
                turtle.move.down(math.abs(dify))
            end

        end
    end
end
-- go to pos.z - difz
function mt._goz(difz, operateAfter, operation, ...)
    if difz > 0 then
        turtle.rotation.to(turtle.rotation.sides.south)
        if operateAfter ~= nil and operation ~= nil then
            turtle.move.bulk(turtle.move.forward, difz, operation, operateAfter, ...)
        else
            turtle.move.forward(difz)
        end
    else
        if difz < 0 then
            turtle.rotation.to(turtle.rotation.sides.north)
            if operateAfter ~= nil and operation ~= nil then
                turtle.move.bulk(turtle.move.forward, math.abs(difz), operation, operateAfter, ...)
            else
                turtle.move.forward(math.abs(difz))
            end
        end
    end
end


function mt.goTo(x, y, z, moveType, operateAfter, operation, ...)
    turtle.position.get()
    local dif = {x = x - turtle.position.current.x,
                 y = y - turtle.position.current.y,
                 z = z - turtle.position.current.z}
    if moveType == mt.moveType.basic then
        -- go to Y
        mt._goy(dif.y, operateAfter, operation, ...)
        -- go to X
        mt._gox(dif.x, operateAfter, operation, ...)
        -- go to Z
        mt._goz(dif.z, operateAfter, operation, ...)

    else
        if moveType == mt.moveType.diagonal then

        end
        error("Not implemented move type["..moveType.."]")
    end
end

function mt.goPoint(point, moveType, operateAfter, operation, ...)
    mt.goTo(point[1], point[2], point[3], moveType, operateAfter, operation, ...)
end

function mt.goPoints(points, moveType, operateAfter, operation, ...)
    for _, point in pairs(points) do
        mt.goPoint(point, moveType, operateAfter, operation, ...)
    end
end

-- with operation on point
function mt.goPointX(point, moveType, operation, ...)
    mt.goPoint(point, moveType)
    operation(...)
end

-- with operation on las point or every point
-- onEveryPoint - enable operation execution on every point
function mt.goPointsX(points, moveType, onEveryPoint, operation, ...)
    if onEveryPoint then
        for _, point in pairs(points) do
            mt.goPointX(point, moveType, operation, ...)
        end
    else
        mt.goPoints(points, moveType)
        operation(...)
    end
end

return mt