

function get(sUrl)
    local ok, err = http.checkURL(url)
    if not ok then
        printError(err or "Invalid URL.")
        return
    end

    print("Connecting to " .. sUrl .. "... ")

    local response = http.get(sUrl , nil , true)
    assert(response ~= nil, "Failed!")
    assert(res.getResponseCode() == 200, "Invalid response code: "..res.getResponseCode())
    print("Success.")

    local res = response.readAll()
    response.close()
    return res or ""
end

function download(sUrl, path, rewrite)
    local ok, err = http.checkURL(url)
    if not ok then
        printError(err or "Invalid URL.")
        return
    end

    if fs.exists(path) and not rewrite then
        print("File exists")
        return
    end

    print("Connecting to " .. sUrl .. "... ")

    local response = http.get(sUrl , nil , true)
    assert(response ~= nil, "Failed!")
    assert(res.getResponseCode() == 200, "Invalid response code: "..res.getResponseCode())
    print("Success.")

    if fs.exists(path) then fs.delete(path) end
    fs.open(path, "w")
    for line in response.readLine() do
        file.writeLine(line)
    end
    fs.close()
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


-- update (name, all)
-- install (name, names, all)
-- list (installed, cloud)
-- remove (name, all)