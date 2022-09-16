-- Variables
local tArgs = {
    ["-i"] = "string",
    ["-r"] = "string",
    ["-u"] = "string",
    ["-l"] = "string",
    ["-f"] = false,
    ["-y"] = false,
    ["-s"] = false
}
local dbPath = ".spmdb.json"
local installedPath = ".spmi.json"
local cloudDbUrl = "https://raw.githubusercontent.com/Giitrix/Lua-CC-Extensions/master/src/packages.json"
-- Args parsing
function interpretArgs(tInput, tArgs)
    local output = {}
    local errors = {}
    local usedEntries = {}
    for aName, aType in pairs(tArgs) do
        output[aName] = false
        for i = 1, #tInput do
            if not usedEntries[i] then
                if tInput[i] == aName and not output[aName] then
                    if aType then
                        usedEntries[i] = true
                        if type(tInput[i+1]) == aType or type(tonumber(tInput[i+1])) == aType then
                            usedEntries[i+1] = true
                            if aType == "number" then
                                output[aName] = tonumber(tInput[i+1])
                            else
                                output[aName] = tInput[i+1]
                            end
                        else
                            output[aName] = nil
                            errors[1] = errors[1] and (errors[1] + 1) or 1
                            errors[aName] = "expected " .. aType .. ", got " .. type(tInput[i+1])
                        end
                    else
                        usedEntries[i] = true
                        output[aName] = true
                    end
                end
            end
        end
    end
    for i = 1, #tInput do
        if not usedEntries[i] then
            output[#output+1] = tInput[i]
        end
    end
    return output, errors
end
local argList, argErrors = interpretArgs({...}, tArgs)
if #argErrors > 0 then
    local errList = ""
    for k,v in pairs(argErrors) do
        if k ~= 1 then
            errList = errList .. "\"" .. k .. "\": " .. v .. "; "
        end
        error(errList:sub(1, -2))
    end
end

local packagesDB
local packagesInstalled

-- Functions
function get(sUrl)
    assert(sUrl ~= nil, "Url can't be nil")
    local ok, err = http.checkURL(sUrl)
    if not ok then
        printError(err or "Invalid URL.")
        return
    end

    print("Connecting to " .. sUrl .. "... ")

    local response = http.get(sUrl , nil , true)
    assert(response ~= nil, "Failed!")
    assert(response.getResponseCode() == 200, "Invalid response code: "..response.getResponseCode())
    print("Success.")

    local res = response.readAll()
    response.close()
    return res or ""
end

function download(sUrl, path, rewrite)
    local ok, err = http.checkURL(sUrl)
    if not ok then
        printError(err or "Invalid URL.")
        return
    end

    if fs.exists(path) and not rewrite then
        print("File exists ["..path.."]")
        return
    end

    print("Connecting to " .. sUrl .. "... ")

    local response = http.get(sUrl , nil , true)
    assert(response ~= nil, "Failed!")
    assert(response.getResponseCode() == 200, "Invalid response code: "..response.getResponseCode())
    print("Success.")

    if fs.exists(path) then fs.delete(path) end
    local file = io.open(path, "w")

    file:write(response.readAll())

    file:close()
    response.close()
    --local file =
end

function getJson(sUrl)
    return textutils.unserialiseJSON(get(sUrl))
end

function minify(code)
    local lines = {}
    local inMultilineComment = false
    for line in string.gmatch(code, "[^\n]+") do
        line = line
                :gsub("^%s*(.-)%s*$", "%1")
                :gsub("^%-%-[^%[]*$", "")
        local keep = not inMultilineComment
        if inMultilineComment then
            if line == "]]" then
                inMultilineComment = false
            end
        elseif line:match("^%-%-%[%[") then
            inMultilineComment = true
            keep = false
        end
        if keep and line ~= "" then
            table.insert(lines, line)
        end
    end
    return table.concat(lines, "\n")
end

function isInstalled(name)
    if packagesInstalled[name] ~= nil and packagesInstalled[name].isInstalled ~= nil
            and packagesInstalled[name].isInstalled == true then
        return true
    end
    return false
end

function saveDbs()
    local db = io.open(dbPath, "w")
    db:write(textutils.serialiseJSON(packagesDB))
    db:close()
    local dbi = io.open(installedPath, "w")
    dbi:write(textutils.serialiseJSON(packagesInstalled))
    dbi:close()
end

function install(name)
    assert(packagesDB.packages[name] ~= nil, "Can't find package["..name.."] in db.\r\nTry to update and try again.")
    assert(not isInstalled(name) or argList["-f"], "Package "..name..", installed.\r\nSet -f for reinstall or force rewrite.")
    local toInstall = {}
    local toIL = 0
    toInstall[name] = name

    for l,v in pairs(packagesDB.packages[name].require) do
        if toInstall[v] == nil then
            toInstall[v] = v
        end
    end
    -- recheck dependency
    while toIL < #toInstall do
        toIL = #toInstall
        for _, v in pairs(toInstall) do
            for l,k in pairs(packagesDB.packages[v].require) do
                if toInstall[k] == nil then
                    toInstall[k] = k
                end
            end
        end
    end

    for n, d in pairs(toInstall) do
        assert(packagesDB.packages[n] ~= nil, "Package "..n.." is not installed or not found.")
        if packagesInstalled[n] ~= nil and packagesInstalled[n].isInstalled and packagesInstalled[n].version ~= packagesDB.packages[n].version then
            print("Package "..n.." skipped (installed and up to date).")

        else
            download(packagesDB.packages[n].url, packagesDB.packages[n].path, true)
            packagesInstalled[n] = {}
            packagesInstalled[n].isInstalled = true
            packagesInstalled[n].path = packagesDB.packages[n].path
            packagesInstalled[n].version = packagesDB.packages[n].version
            packagesInstalled[n].startup = packagesDB.packages[n].startup
            packagesInstalled[n].priority = packagesDB.packages[n].priority
        end
    end
    saveDbs()
end

function remove(name)
    assert(isInstalled(name), "Package is not installed or not found.")
    fs.delete(packagesInstalled[name].path)
    packagesInstalled[name] = nil
    saveDbs()
end

function getList(str)
    if str == "installed" then
        assert(packagesInstalled ~= nil, "Installed db corrupted!")
        for n, k in pairs(packagesInstalled) do
            print(n.." "..textutils.serialise(k).." \r\n")
        end
    end
    if str == "db" then
        assert(packagesDB.packages ~= nil, "Packages db corrupted!")
        for n, k in pairs(packagesDB.packages) do
            print(n.." ver:"..k.version.." path:"..k.path.." dep:"..textutils.serialiseJSON(k.require).."\r\n")
        end
    end
    if str == "pack" then
        assert(packagesDB.pack ~= nil, "Packs db corrupted!")
        for n, k in pairs(packagesDB.pack) do
            print(n.." contains:"..textutils.serialiseJSON(k.contains).."\r\n")
        end
    end
end

function update(name)
    assert(packagesInstalled[name] ~= nil, "Package on found.\r\nTry to update db and try again.")
    assert(packagesInstalled[name].version ~= packagesDB.packages[name].version, "Package is up to date.")
    argList["-f"] = true
    install(name)
end

function updateDB()
    local scDB = get(cloudDbUrl)
    if scDB == nil or scDB == "" then
        error("Something wrong with cloud db, restart and try again.")
    end

    fs.delete(dbPath)
    local fdb = io.open(dbPath, "w")
    fdb:write(scDB)
    fdb:close()

    packagesDB = textutils.unserialiseJSON(scDB)

    if packagesDB == nil then
        error("SPM DB load error")
    end
end

function enableStartup(name)
    if packagesInstalled[name].startup ~= nil or packagesInstalled[name].startup ~= "" then
        if fs.exists("startup") then
            local f = io.open("startup", "a")
            f:write(packagesInstalled[name].startup + "\r\n")
            f:close()
        else
            local f = io.open("startup", "w")
            f:write(packagesInstalled[name].startup + "\r\n")
            f:close()
        end
    end
end

function enableAll()
    for n,_ in pairs(packagesInstalled) do
        enableStartup(n)
    end
end

function rewriteStartup()
    local startup = "-- Generated by SPM\r\n-- Do not user this startup file! Use startup-scripts!\r\n"
    local startupScripts = {}
    -- getting all scripts
    for k, v in pairs(packagesInstalled) do
        startupScripts[k] = {}
        startupScripts[k].priority = v.priority
        startupScripts[k].script = v.startup
    end
    -- sorting by priority
    local bauble = function(tbl)
        local new_tbl = {}
        local count = 0
        for _,_ in pairs(tbl) do
            count = count + 1
        end
        for i = 1, count, 1 do
            local smaller = {}
            for j, k in pairs(tbl) do
                if smaller.priority ~= nil then
                    if smaller.priority > k.priority then
                        smaller = k
                        smaller.name = j
                    end
                else
                    smaller = k
                    smaller.name = j
                end
            end
            tbl[smaller.name] = nil
            table.insert(new_tbl, smaller)
        end

        return new_tbl
    end
    startupScripts = bauble(startupScripts)

    for n, v in pairs(startupScripts) do
        startup = startup..v.script.."\r\n"
    end

    startup = startup..'\r\nshell.run("startup-scripts")'
    print("Generated startup successful.")

    fs.delete("startup")
    local f = io.open("startup", "w")
    f:write(startup)
    f:close()
    if not fs.exists("startup-scripts") then
        local f = io.open("startup-scripts", "w")
        f:write("-- Write your startup script here.\r\n-- Don not use startup file!")
        f:close()
    end
end

-- Logic

---- loading db or uploading
if fs.exists(dbPath) then
    local fdb = io.open(dbPath, "r")
    packagesDB = textutils.unserialiseJSON(fdb:read("a"))
    fdb:close()
    if packagesDB == nil then
        error("SPM DB load error")
    end
else
    -- Download and write when not exists
    local scDB = get(cloudDbUrl)
    if scDB == nil or scDB == "" then
        error("Something wrong with cloud db, restart and try again.")
    end

    local fdb = io.open(dbPath, "w")
    fdb:write(scDB)
    fdb:close()

    packagesDB = textutils.unserialiseJSON(scDB)

    if packagesDB == nil then
        error("SPM DB load error")
    end
end

if fs.exists(installedPath) then
    local fi = io.open(installedPath, "r")
    packagesInstalled = textutils.unserialiseJSON(fi:read("a"))
    fi:close()
else
    packagesInstalled = {}
    local dbi = io.open(installedPath, "w")
    dbi:write(textutils.serialiseJSON(packagesInstalled))
    dbi:close()
end

for k, v in pairs(argList) do
    if v ~= nil and v ~= false then
        if k == "-i" and v ~= ""  then

        end
    end
end


if argList["-y"] then
    updateDB()
end

if argList["-l"] ~= false then
    getList(argList["-l"])
end

if argList["-r"] ~= false then
    remove(argList["-r"])
end

if argList["-u"] ~= false then
    update(argList["-u"])
end

if argList["-i"] ~= false then
    install(argList["-i"])
end

if argList["-s"] ~= false then
    rewriteStartup()
end

saveDbs()
rewriteStartup()