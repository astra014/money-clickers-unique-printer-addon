
MCLICKERS.version = "1.5.4"

local function parseVersion(str)
    local arr = string.Explode(".", str)
    return setmetatable({
        tonumber(arr[1]),
        tonumber(arr[2]),
        tonumber(arr[3])
    }, {
        __tostring = function(a) return str end
    })
end

local function compareVersions(a, b)
    local len = math.max(#a, #b)

    for j = 1, len do
        local aPart = a[j] or 0
        local bPart = b[j] or 0
        if aPart < bPart then
            return -1
        elseif aPart > bPart then
            return 1
        end
    end

    return 0
end

function MCLICKERS.checkVersion()
    http.Fetch("https://raw.githubusercontent.com/Metamist/garrysmod-MetaAddons/master/MoneyClickers/versions.txt", function(body, len, headers, code)
        if code ~= 200 then
            -- Failed to fetch versions
            return
        end

        local tbl = util.JSONToTable(body)

        local currentVersion = parseVersion(MCLICKERS.version)
        local latestVersion = parseVersion(tbl[1].version)

        if compareVersions(currentVersion, latestVersion) < 0 then -- Out of date
            local changelog = {}
            for i = 1, #tbl do
                local verData = tbl[i]

                local version = parseVersion(verData.version)

                if compareVersions(currentVersion, version) < 0 then
                    for j = 1, #verData.changelog do
                        changelog[#changelog + 1] = verData.changelog[j]
                    end
                end
            end

            if #changelog > 0 then
                print()
                MCLICKERS.print("A new version is available (",
                    Color(0, 255, 0), latestVersion,
                    Color(255, 255, 255), "), current version is ",
                    Color(255, 0, 0), currentVersion)

                MCLICKERS.print("Please go to ScriptFodder and download the new version!")

                MCLICKERS.print("Changelog: ")

                for i = 1, #changelog do
                    MCLICKERS.print(" * " .. changelog[i])
                end
                print()
            end
        end
    end)
end


hook.Add("Initialize", "MClickers_VersionCheck", function()
    timer.Simple(5, function()
        MCLICKERS.checkVersion()
    end)
end)
