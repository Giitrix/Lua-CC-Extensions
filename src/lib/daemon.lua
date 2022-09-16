assert(net.open ~= nil, "Net lib required!")

local daemon = {}
daemon.commands = {}
daemon.label = ""
daemon.port = 0
daemon.timeout = 0
daemon.timeoutFunc = nil
daemon.receiveFunc = nil

function daemon.AddCommandHandler(cmd, func)
    daemon.commands[cmd] = func
end

function daemon.StartUp(port, label, timeout)
    daemon.label = label
    daemon.port = port
    daemon.timeout = timeout
end

function daemon.SetTimeoutCallback(func)
    daemon.timeoutFunc = func
end

function daemon.SetReciveCallback(func)
    daemon.receiveFunc = func
end


function daemon.Run()
    net.open(daemon.port)
    while true do
        local rec = net.receive(daemon.port, daemon.label, daemon.timeoutFunc)

        if daemon.receiveFunc ~= nil then
            daemon.receiveFunc(rec)
        end

        if rec ~= nil then

            if type(rec.message) == "string" then
                if (daemon.commands[rec.message]) ~= nil then
                    (daemon.commands[rec.message])()
                else
                    print("Nil command ["..rec.message.."]")
                end
            else
                print("Wrong message type")
            end

        else

            if daemon.timeoutFunc ~= nil then
                daemon.timeoutFunc()
            end
        end
    end
end

return daemon