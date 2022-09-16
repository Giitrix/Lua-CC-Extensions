shell.run("emu open 1")
term.clear()
term.setCursorPos(1,1)
--Peripherla emu
ccemux.attach("left", "wireless_modem", {
    -- The range of this modem
    range = 64,
    -- Whether this is an ender modem
    interdimensional = true,
    -- The current world's name. Sending messages between worlds requires an interdimensional modem
    world = "Universe",
    -- The position of this wireless modem within the world
    posX = 0, posY = 0, posZ = 0,
})

require("lib/core/gos")
require("lib/core/threads")
_G.net = require("lib/core/gnet")
os.runShellThread()
os.runThreadsManager()
shell.run("exit")