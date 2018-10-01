MCLICKERS = MCLICKERS or {}

include("mclickers_config.lua")

if SERVER then
    AddCSLuaFile("mclickers_config.lua")

    if MCLICKERS.useWorkshop then
        resource.AddWorkshop("685912753")
    else
        resource.AddFile("resource/fonts/roboto.ttf")

        resource.AddFile("materials/moneyclickers/heat.vmt")
        resource.AddFile("materials/moneyclickers/creditcard.vmt")
        resource.AddFile("materials/moneyclickers/health.vmt")
        resource.AddFile("materials/moneyclickers/repair.vmt")

        resource.AddFile("materials/moneyclickers/upgrade_autoclick.vmt")
        resource.AddFile("materials/moneyclickers/upgrade_clickpower.vmt")
        resource.AddFile("materials/moneyclickers/upgrade_cooling.vmt")
        resource.AddFile("materials/moneyclickers/upgrade_storage.vmt")
    end
end

function MCLICKERS.error(...)
    MsgC(Color(255, 150, 0), "[MClickers-Error] ", ...)
    MsgC("\n")
end

function MCLICKERS.print(...)
    MsgC(Color(0, 255, 0), "[MClickers] ", Color(255, 255, 255), ...)
    MsgC("\n")
end

function MCLICKERS.formatPoints(pts)
    return string.format(MCLICKERS.language.textPointsAmount, pts)
end

if SERVER then
    include("mclickers_version.lua")

end
