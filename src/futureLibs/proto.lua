local Net = {}
Net.dns = { "dns-server-00"}
Net.hostName = ""
Net.hostPort = 0
Net.modem = {}
Net.knowHosts = {}
-- Basic setup
function Net.Start(hostname, modem_, port)
    modem = modem_
    hostName = hostname
    hostPort = port
    modem.open(hostPort)
end

-- Start listener in second thread
function Net.lister(filter)
    local event, side, channel, replyChannel, message, distance
    while true do
        event, side, channel, replyChannel, message, distance = os.pullEvent(filter)
        local host1, host2, data = Net.unserialize(message)
        if host1 == Net.hostName then
            return data, host2, replyChannel, distance
        end
    end
end
-- Send message with basic protocol
function Net.Send(hostname, port, data)
    local sendData = Net.serialize({hostname, hostName, data })
    Net.modem.transmit(port, Net.hostPort, sendData)
end

function Net.serialize(data, hostname)
    return ([[%s
%s
%s]]).format(data, Net.hostName, hostname)

end
function Net.unserialize(data)
    local result = string.find(data, "(\n.)")
    local hostname1 = string.sub(data, 1, result-1)
    data = string.sub(data, result+1)
    result = string.find(data, "(\n.)")
    local hostname2 = string.sub(data, 1, result-1)

    return hostname1, hostname2, string.sub(data, result+1)
end
function Net.SaveKnownHosts()
    local file = io.open("knownhosts", "w")
    file.write(textutils.serialize(Net.knowHosts))
    file.flush()
    file.close()
end
function Net.LoadKnownHosts()
    local file = io.open("knownhosts","r")
    if file ~= nil then
        Net.knowHosts = textutils.unserialize(file.read("a"))
    end
    file.close()
end


return Net