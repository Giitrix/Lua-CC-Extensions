local threads = {}
local starting = {}
local eventFilter

_G.os.startThread = function(fn, blockTerminate)
	table.insert(starting, {
		cr = coroutine.create(fn),
		blockTerminate = blockTerminate or false,
		targetTime = nil,
		error = nil,
		dead = false,
		filter = nil
	})
end

local function tick(t, evt, ...)
	if t.dead then return end
	if t.filter ~= nil and evt ~= t.filter then return end
	if evt == "terminate" and t.blockTerminate then return end
	if t.targetTime ~= nil and t.targetTime > os.clock() then return else t.targetTime = nil end

	local _, arg = coroutine.resume(t.cr, evt, ...)
	if arg ~= nil and arg.sleep ~= nil then
		t.targetTime = arg.sleep
	end

	t.dead = (coroutine.status(t.cr) == "dead")
end

local function tickAll()
	if #starting > 0 then
		local clone = starting
		starting = {}
		for _,v in ipairs(clone) do
			tick(v)
			table.insert(threads, v)
		end
	end
	local e = {}
	if eventFilter then
		e = {eventFilter(coroutine.yield())}
	else
		e = {coroutine.yield()}
	end
	local dead
	local minimalTargetTime
	local sleepThreadCount = 0
	for k,v in ipairs(threads) do
		tick(v, unpack(e))
		if v.targetTime ~= nil then
			sleepThreadCount = sleepThreadCount + 1
			if minimalTargetTime ~= nil and minimalTargetTime > v.targetTime then
				minimalTargetTime = v.targetTime
			else
				minimalTargetTime = v.targetTime
			end
		end
		if v.dead then
			if dead == nil then dead = {} end
			table.insert(dead, k - #dead)
		end
	end
	if dead ~= nil then
		for _,v in ipairs(dead) do
			table.remove(threads, v)
		end
	end
	if minimalTargetTime ~= nil and sleepThreadCount >= #threads then
		local target_time = minimalTargetTime - os.clock()
		os.sleep(target_time)
	end
end

_G.os.setGlobalEventFilter = function(fn)
	if eventFilter ~= nil then error("This can only be set once!") end
	eventFilter = fn
	rawset(os, "setGlobalEventFilter", nil)
end

_G.os.runThreadsManager = function()
	while #threads > 0 or #starting > 0 do
		tickAll()
	end
end

_G.os.runShellThread = function()
	if type(threadMain) == "function" then
		os.startThread(threadMain)
	else
		os.startThread(function() shell.run("shell") end)
	end
end

_G.os.getThreads = function()
	return threads
end

_G.os.getThreadCount = function()
	return #threads
end

_G.os.sleepThread = function(time)
	local target_time = os.clock() + time
	coroutine.yield({sleep = target_time })
end
