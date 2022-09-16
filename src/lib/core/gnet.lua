assert(_G.os.pullEventTimeout ~= nil, "gos lib needed!")
local modems = {}
for _, m in pairs({peripheral.find("modem")}) do modems[peripheral.getName(m)] = m  end
assert(modems ~= nil, "Modem not found")

local net = {}
net.modem = {}
net.modem.current = nil

local modem
for n, m in pairs(modems) do
    modem = m
    net.modem.current = n
    break
end

net.isOpen = modem.isOpen
net.open = modem.open
net.close = modem.close
net.closeAll = modem.closeAll
net.isWireless = modem.isWireless

function net.modem.set(name)
    modem = modems[name]
end

function net.modem.getNames()
    local names = {}
    for name, _ in pairs(modems) do
        if name ~= nil then
            table.insert(names, name)
        end
    end
    return names
end

function net.modem.doForAll(func, ...)
    local results = {}
    for n, _ in pairs(modems) do
        net.modem.set(n)
        results[n] = {func(...)}
    end
    return results
end

function net.modem.doFor(name, func, ...)
    local cur = net.modem.current
    net.modem.set(name)
    local res = {func(...)}
    net.modem.set(cur)
    return table.unpack(res)
end

function net.filterEvent(label, timeout)
    ev = {os.pullEventTimeout("modem_message", timeout)}
    if ev ~= nil and ev[5] ~= nil then
        local mt = textutils.unserialise(ev[5])
        if  mt.label ~= nil and mt.label == label then
            return table.unpack(ev)
        end
    end
end

function net.send(channel, replyChannel, message, label)
    modem.transmit(channel, replyChannel, textutils.serialise({label = label, message = message}))
end

function net.receive(channel, label, timeout)
    while true do
        local ev
        if label ~= nil then
            ev = {net.filterEvent(label, timeout)}
        else
            ev = {os.pullEventTimeout("modem_message", timeout)}
        end
        if ev == nil then return end
        local msg = {side = ev[2], channel = ev[3], replyChannel = ev[4], message = ev[5], distance = ev[6] }
        if msg.message ~= nil then msg.message = textutils.unserialise(msg.message) end
        if msg.message ~= nil and msg.message.message ~= nil then
            msg.message = msg.message.message
        end
        if channel ~= nil then
            if ev[3] == channel then return msg  end
        else
            return msg
        end
    end
end

return net

