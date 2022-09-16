_G.os.pullEventTimeout = function(filter, time)
    if time == nil or (time ~= nil and time <= 0) then
        return os.pullEvent(filter)
    end
    local tid = os.startTimer(time)
    while true do
        ev = {os.pullEvent()}
        if ev ~= nil then
            if ev[1] == "timer" and ev[2] ~= nil and ev[2] == tid then return end
            if ev[1] == filter then return table.unpack(ev) end
        end
    end
end


-- Thread safe block
if _G.os.runThreadsManager ~= nil then
    -- nothing now
end