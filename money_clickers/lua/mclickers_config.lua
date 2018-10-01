------------------------------------------------------------------------
------------------------------------------------------------------------
--  __  __                           ____ _ _      _                  --
-- |  \/  | ___  _ __   ___ _   _   / ___| (_) ___| | _____ _ __ ___  --
-- | |\/| |/ _ \| '_ \ / _ \ | | | | |   | | |/ __| |/ / _ \ '__/ __| --
-- | |  | | (_) | | | |  __/ |_| | | |___| | | (__|   <  __/ |  \__ \ --
-- |_|  |_|\___/|_| |_|\___|\__, |  \____|_|_|\___|_|\_\___|_|  |___/ --
--                          |___/                                     --
--                     ____             __ _                          --
--                    / ___|___  _ __  / _(_) __ _                    --
--                   | |   / _ \| '_ \| |_| |/ _` |                   --
--                   | |__| (_) | | | |  _| | (_| |                   --
--                    \____\___/|_| |_|_| |_|\__, |                   --
--                                           |___/                    --
------------------------------------------------------------------------
------------------------------------------------------------------------

MCLICKERS.clickDelay = 0.1       -- 0.1 seconds delay before being able to click again. This is to prevent auto-clickers.
MCLICKERS.clickRange = 80        -- Range in units that people can click.
MCLICKERS.wireUserEnabled = true -- Can the Wire User be used to withdraw money?
MCLICKERS.antiAutoClick = true   -- After a random amount of clicks, force the user to look away from the clicker.
MCLICKERS.useWorkshop = false    -- Use workshop downloading instead of FastDL for textures
MCLICKERS.stealing = false       -- Enable stealing mechanic, players are required to own (steal) to interact with someone's clicker
MCLICKERS.stealHoldTime = 10     -- How long to hold down in order to steal a clicker

MCLICKERS.SOUND_UI_HOVER = "garrysmod/ui_hover.wav"
MCLICKERS.SOUND_UI_CLICK = "garrysmod/ui_click.wav"
MCLICKERS.SOUND_CLICK    = "buttons/lightswitch2.wav"
MCLICKERS.SOUND_CYCLE    = "garrysmod/content_downloaded.wav"

MCLICKERS.MESSAGE_BREAK = "One of your Money Clickers has broken down! Go and repair it."
MCLICKERS.MESSAGE_UPGRADE_INSUFFICIENT = "You do not have enough to pay for this upgrade!"
MCLICKERS.MESSAGE_REPAIR_INSUFFICIENT = "You do not have enough to pay for the reparation!"
MCLICKERS.MESSAGE_WITHDRAW = "You have withdrawn %s."
MCLICKERS.MESSAGE_DEFAULT_UPGRADE_ALLOWED = "You are not allowed to purchase this upgrade!"
MCLICKERS.MESSAGE_STOLEN = "You have stolen this Money Clicker!"
MCLICKERS.MESSAGE_NOT_OWNED = "You must own this Money Clicker to do this!"


MCLICKERS.language = {
    unitAutoClick    = "clicks/s",
    unitClickPower   = "power/click",
    unitCooling      = "heat/0.25s",
    unitStorage      = "storage",

    textWithdraw     = "Withdraw Money",
    textRepair       = "Repair",
    textRepairWait   = "Please wait %is",
    textUpgrades     = "Upgrades",

    textUpgradeMaxed = "MAXED",
    textPointsAmount = "%i Points",
    textMoney        = "Money",
    textPoints       = "Points",
    textSteal        = "Steal",
    textStealHold    = "Hold for %is to\nsteal this clicker",
}

--[[

----------------------------------------
-- How to add your own Money Clickers --
----------------------------------------

To add custom Money Clicker entities, you write the code below in
    darkrpmodification/lua/darkrp_customthings/entities.lua
The code below includes all configuration that is available, some are optional though.
Take a look at the examples further down for 3 tiers of Money Clickers!

To change the colors I recommend going to the following websites
    http://color.adobe.com/
    http://www.materialpalette.com/  -->  http://hex.colorrrs.com/  <--  Need to convert hex to RGB
Make sure the color format looks like this, Color(R, G, B) - example: Color(255, 150, 0)

DarkRP.createEntity("Money Clicker", { -- The name of the money clicker
    ent = "money_clicker", -- Do not change this class
    model = "models/props_c17/consolebox01a.mdl", -- Do not change this model
    price = 100,
    max = 3,
    cmd = "buymoneyclicker1", -- This has to be a unique command for each Money Clicker
    mClickerInfo = {
        pointsPerCycle = 10,     -- How many points you get per cycle
        moneyPerCycle = 7,       -- How much money you get per cycle
        maxPoints = 1000,        -- The base points capacity
        maxMoney = 1500,         -- The base money capacity
        health = 100,            -- How much health it has, a crowbar deals 25 damage
        indestructible = false,  -- Can not be destroyed
        repairHealthCost = 100,  -- Repair health price in points
        maxCycles = 100,         -- Amount of cycles before it breaks, set to 0 to disable
        repairBrokenCost = 1000, -- Repair price in money for when the clicker breaks down

        -- The stats the clickers have per upgrade level, each starts at level 1
        -- For example, when you first spawn in a clicker, it will auto click at
        -- a rate of 0 clicks/s which means no auto clicking at all.
        -- With no upgrades to click power, it will increase the progress by 10
        -- each click.
        -- The first entry for the prices is for the second upgrade, as the first
        -- upgrade is the one you have when the clicker is spawned.
        upgrades = {
            autoClick = {
                name = "Professional Idler",     -- The display name of the upgrade
                stats = { 0, 1, 2, 3, 4 },       -- Clicks per second, set per upgrade level
                prices = { 200, 300, 400, 500 }, -- Prices for the second upgrade and up (starts with first upgrade)

                -- OPTIONAL: Lua function to check if a player is allowed to purchase the next upgrade
                --           Check examples below for job and group whitelist
                --           Remove if you want all upgrade levels to be available to everyone
                customCheck = function(ply, upgrade, data, current, max)
                    -- Custom check, return true to prevent purchasing upgrade
                    return true, "Optional custom message"
                end,
            },
            clickPower = {
                name = "Power Clicker",         -- The display name of the upgrade
                stats = { 10, 12, 14, 16 },     -- Progress per click, set per upgrade level
                prices = { 200, 300, 400 },     -- Prices for the second upgrade and up (starts with first upgrade)
            },
            cooling = {
                name = "Cooler Master",         -- The display name of the upgrade
                stats = { 1.7, 2.2, 3.5, 5 },   -- Cooling per 0.25 seconds. For reference, max heat is 100
                prices = { 200, 300, 400 },     -- Prices for the second upgrade and up (starts with first upgrade)
            },
            storage = {
                name = "Hardcore Hoarder",      -- The display name of the upgrade
                stats = { 1, 2, 3, 4 },         -- Storage modifier, starts at 1x storage
                prices = { 200, 300, 400 },     -- Prices for the second upgrade and up (starts with first upgrade)
            },
        },

        enableHeat = true, -- Make the clicker heat up when clicking it too much, will not blow it up but will disable it for a while
        heatPerClick = 20, -- Max heat is 100

    	colorPrimary = Color(139, 195, 74),  -- The primary color that is used for the entire model
    	colorSecondary = Color(255, 87, 34), -- The secondary color, AKA accent color, used for details
        colorText = Color(255, 255, 255),    -- The color of the text
        colorHealth = Color(255, 100, 100),  -- The color of the health icon
    },
})

You can add however many you want of these if you want different tiers of money clickers.
All of them should use entity "money_clicker"
Want to limit certain upgrades to certain jobs/groups? Check the ScriptFodder description
for some examples (Lua knowledge needed! However there is two examples that does this on the page)


--------------------------------
--       Example Setup        --
--------------------------------
-- Bronze, Silver, Gold Tiers --
--------------------------------

DarkRP.createEntity("Money Clicker Bronze", {
    ent = "money_clicker", -- Do not change this class
    model = "models/props_c17/consolebox01a.mdl", -- Do not change this model
    price = 100,
    max = 3,
    cmd = "buymoneyclickerbronze",
    mClickerInfo = {
        pointsPerCycle = 10,
        moneyPerCycle = 7,
        maxPoints = 1000,
        maxMoney = 1500,
        health = 100,
        indestructible = false,
        repairHealthCost = 100,
        maxCycles = 100,
        repairBrokenCost = 1000,

        upgrades = {
            autoClick = {
                name = "Professional Idler",
                stats = { 0, 1, 2, 3, 4 },
                prices = { 200, 300, 400, 500 },
            },
            clickPower = {
                name = "Power Clicker",
                stats = { 10, 12, 14, 16 },
                prices = { 200, 300, 400 },
            },
            cooling = {
                name = "Cooler Master",
                stats = { 1.7, 2.2, 3.5, 5 },
                prices = { 200, 300, 400 },
            },
            storage = {
                name = "Hardcore Hoarder",
                stats = { 1, 2, 3, 4 },
                prices = { 200, 300, 400 },
            },
        },

        enableHeat = true,
        heatPerClick = 20,

    	colorPrimary = Color(139, 195, 74),
    	colorSecondary = Color(255, 87, 34),
        colorText = Color(255, 255, 255),
        colorHealth = Color(255, 100, 100),
    },
})

DarkRP.createEntity("Money Clicker Silver", {
    ent = "money_clicker", -- Do not change this class
    model = "models/props_c17/consolebox01a.mdl", -- Do not change this model
    price = 100,
    max = 3,
    cmd = "buymoneyclickersilver",
    mClickerInfo = {
        pointsPerCycle = 15,
        moneyPerCycle = 15,
        maxPoints = 2000,
        maxMoney = 3500,
        health = 2000,
        indestructible = false,
        repairHealthCost = 100,
        maxCycles = 100,
        repairBrokenCost = 1000,

        upgrades = {
            autoClick = {
                name = "Professional Idler",
                stats = { 1, 2, 3, 4, 5 },
                prices = { 250, 375, 525, 600 },
            },
            clickPower = {
                name = "Power Clicker",
                stats = { 15, 17, 19, 21 },
                prices = { 250, 375, 525 },
            },
            cooling = {
                name = "Cooler Master",
                stats = { 1.8, 2.3, 3.6, 5.2 },
                prices = { 250, 375, 525 },
            },
            storage = {
                name = "Hardcore Hoarder",
                stats = { 1, 2.5, 4, 6 },
                prices = { 250, 375, 525 },
            },
        },

        enableHeat = true,
        heatPerClick = 20,

    	colorPrimary = Color(139, 195, 74),
    	colorSecondary = Color(255, 87, 34),
        colorText = Color(255, 255, 255),
        colorHealth = Color(255, 100, 100),
    },
})

DarkRP.createEntity("Money Clicker Gold", {
    ent = "money_clicker", -- Do not change this class
    model = "models/props_c17/consolebox01a.mdl", -- Do not change this model
    price = 100,
    max = 3,
    cmd = "buymoneyclickergold",
    mClickerInfo = {
        pointsPerCycle = 20,
        moneyPerCycle = 30,
        maxPoints = 4000,
        maxMoney = 6000,
        health = 100,
        indestructible = true,
        repairHealthCost = 100,
        maxCycles = 100,
        repairBrokenCost = 1000,

        upgrades = {
            autoClick = {
                name = "Professional Idler",
                stats = { 2, 3, 4, 5, 6 },
                prices = { 300, 425, 675, 800 },
            },
            clickPower = {
                name = "Power Clicker",
                stats = { 20, 22, 24, 26 },
                prices = { 300, 425, 675 },
            },
            cooling = {
                name = "Cooler Master",
                stats = { 2, 2.5, 4, 6 },
                prices = { 300, 425, 675 },
            },
            storage = {
                name = "Hardcore Hoarder",
                stats = { 1, 3, 5, 8 },
                prices = { 300, 425, 675 },
            },
        },

        enableHeat = true,
        heatPerClick = 20,

    	colorPrimary = Color(139, 195, 74),
    	colorSecondary = Color(255, 87, 34),
        colorText = Color(255, 255, 255),
        colorHealth = Color(255, 100, 100),
    },
})

]]
