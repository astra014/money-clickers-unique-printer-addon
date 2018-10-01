AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("money_clicker_withdraw")
util.AddNetworkString("money_clicker_steal")
util.AddNetworkString("money_clicker_click")
util.AddNetworkString("money_clicker_syncinfo")
util.AddNetworkString("money_clicker_upgrade")
util.AddNetworkString("money_clicker_repair")
util.AddNetworkString("money_clicker_info")

local base_gmodentity = scripted_ents.Get("base_gmodentity")

function ENT:Assert(test, ...)
    if test then return false end

    MCLICKERS.error("Something went wrong in the configuration!")
    MCLICKERS.error("> ", ...)
    MCLICKERS.error("Please refer to the config file to see how to set it up correctly.")
    self.errored = true
    self:Remove()

    return true
end

local configTemplate = {
    "pointsPerCycle", "moneyPerCycle", "maxPoints", "maxMoney",
    "health", "indestructible", "repairHealthCost", "maxCycles", "repairBrokenCost", "upgrades",
    "enableHeat", "heatPerClick", "colorPrimary", "colorSecondary", "colorText", "colorHealth",
    "upgrades.autoClick", "upgrades.clickPower", "upgrades.cooling", "upgrades.storage",
    "upgrades.autoClick.stats", "upgrades.clickPower.stats", "upgrades.cooling.stats", "upgrades.storage.stats",
    "upgrades.autoClick.prices", "upgrades.clickPower.prices", "upgrades.cooling.prices", "upgrades.storage.prices",
    "upgrades.autoClick.name", "upgrades.clickPower.name", "upgrades.cooling.name", "upgrades.storage.name",
}


hook.Add("onPocketItemAdded", "MClicker_PocketAdded", function(ply, ent, serialized)
    if not ent.IsMoneyClicker then return end

    serialized._health = { ent:Health(), ent:GetMaxHealth() }
end)

hook.Add("onPocketItemDropped", "MClicker_PocketDropped", function(ply, ent, item, id)
    if not ent.IsMoneyClicker then return end

    ent:SetHealth(id._health[1])
    ent:SetMaxHealth(id._health[2])
end)

function ENT:Initialize()
    base_gmodentity.Initialize(self)

    self:SetModel("models/props_c17/consolebox01a.mdl")
    self:SetMaterial("models/debug/debugwhite")

    if not IsValid(self:Getowning_ent()) then
        self:Remove()
        return
    end
    self.infoInitialized = nil
    if self.DarkRPItem then
        self:InitializeInfo()
    end

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()

    timer.Simple(0.1, function()
        if IsValid(phys) then
            phys:Wake()
        end
    end)
end

function ENT:InitializeInfo()
    if self.infoInitialized then return end
    self.infoInitialized = true

    self.info = self.DarkRPItem.mClickerInfo

    if self:Assert(self.info ~= nil, "Missing mClickerInfo in DarkRP.createEntity.") then return end

    for _, k in ipairs(configTemplate) do
        local traverse = string.Explode(".", k)

        local tbl = self.info
        for i = 1, #traverse - 1 do
            tbl = tbl[traverse[i]]
        end
        local last = traverse[#traverse]

        if self:Assert(tbl[last] ~= nil, "Missing ", k, " in mClickerInfo.") then return end
    end

    self:SetClickerName(self.DarkRPItem.name)
    self:SetOwnerName(self:Getowning_ent():getDarkRPVar("rpname"))
    self:SetClickerOwner(self:Getowning_ent())

    self:SetMaxHealth(self.info.health or 100)
    self:SetHealth(self:GetMaxHealth())

    self.cycles = self.info.maxCycles
    self.lookAwayMin = 1000
    self.lookAwayMax = 4000
    self.clickCount = math.random(self.lookAwayMin, self.lookAwayMax)

    self:UpdateUpgrades()
end

local function iterateTable(tbl, cb)
    for k, v in pairs(tbl) do
        cb(tbl, k, v)

        if type(v) == "table" then
            iterateTable(v, cb)
        end
    end
end

function ENT:SyncInfo(ply)
    net.Start("money_clicker_info")
    net.WriteEntity(self)

    -- net.WriteTable does not allow functions,
    -- get rid of all functions in the info table.
    local info = table.Copy(self.info)

    iterateTable(info, function(tbl, key, value)
        if type(value) == "function" then
            tbl[key] = nil
        end
    end)

    net.WriteTable(info)

    if IsValid(ply) then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

net.Receive("money_clicker_info", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    ent:SyncInfo(ply)
end)

function ENT:UpdateUpgrades()
    local autoClick = self:GetUpgradeData("autoClick").stats[self:GetUpgradeAutoClick()]
    self.clickInterval = nil
    if autoClick > 0 then self.clickInterval = 1 / autoClick end

    self.clickPower = self:GetUpgradeData("clickPower").stats[self:GetUpgradeClickPower()]
    self.cooling = self:GetUpgradeData("cooling").stats[self:GetUpgradeCooling()]
    self.storageMod = self:GetUpgradeData("storage").stats[self:GetUpgradeStorage()]
end

function ENT:Withdraw(ply, notify)
    if self:GetMoney() == 0 then return end

    local amt = self:GetMoney()
    ply:addMoney(amt)
    self:SetMoney(0)

    if notify then
        DarkRP.notify(ply, 0, 4, string.format(MCLICKERS.MESSAGE_WITHDRAW, DarkRP.formatMoney(amt)))
    end

    if LevelSystemConfiguration then
        local amtXP = self:GetStoredXP()
        ply:addXP(amtXP)
        self:SetStoredXP(0)
    end
end

function ENT:SetHeat(value)
    if not self.info.enableHeat then return end

    value = math.Clamp(value, 0, 100)
    self:SetHeatInternal(value)

    if self:GetOverheating() and value <= 0 then
        self:SetOverheating(false)
    end

    if value >= 100 then
        self:SetOverheating(true)
    end
end

function ENT:OnProgressCompleted()
    self:AddMoney(self.info.moneyPerCycle)
    self:AddPoints(self.info.pointsPerCycle)

    if self.info.xpPerCycle and LevelSystemConfiguration then
        self:AddStoredXP(self.info.xpPerCycle)
    end

    self:SetHeat(self:GetHeat() + self.info.heatPerClick)

    if self.info.maxCycles > 0 then
        self.cycles = math.max(self.cycles - 1, 0)

        if self.cycles <= 0 then
            self:SetBroken(true)
            self:SetRepairWaitTime(CurTime() + 10)

            DarkRP.notify(self:GetClickerOwner(), 1, 4, MCLICKERS.MESSAGE_BREAK)
        end
    end
end

function ENT:SetProgress(value)
    if value >= 100 then
        value = 0

        self:OnProgressCompleted()
    end

    self:SetProgressInternal(value)
end

function ENT:AddProgress(amt)
    self:SetProgress(self:GetProgress() + amt)
end

function ENT:AddPoints(amt)
    self:SetPoints(math.min(self:GetPoints() + amt, self.info.maxPoints * self.storageMod))
end

function ENT:AddMoney(amt)
    self:SetMoney(math.min(self:GetMoney() + amt, self.info.maxMoney * self.storageMod))
end

function ENT:AddStoredXP(amt)
    local new = self:GetStoredXP() + amt

    if self.info.maxXP then
        self:SetStoredXP(math.min(self:GetStoredXP() + amt, self.info.maxXP * self.storageMod))
    else
        self:SetStoredXP(new)
    end
end

function ENT:Pay(ply, amt)
    if amt > self:GetPoints() then return false end

    self:SetPoints(math.max(self:GetPoints() - amt, 0))

    return true
end

function ENT:SetUpgradeLevel(upgrade, level)
    if upgrade == "autoClick" then
        current = self:SetUpgradeAutoClick(level)
    elseif upgrade == "clickPower" then
        current = self:SetUpgradeClickPower(level)
    elseif upgrade == "cooling" then
        current = self:SetUpgradeCooling(level)
    elseif upgrade == "storage" then
        current = self:SetUpgradeStorage(level)
    end
end

function ENT:Upgrade(ply, upgrade)
    local current = self:GetUpgradeLevel(upgrade)
    local data = self:GetUpgradeData(upgrade)
    if not current or not data then return end

    local max = #data.stats
    if current == max then return end

    if data.customCheck then
        local b, str = data.customCheck(ply, upgrade, data, current, max)
        if b then
            DarkRP.notify(ply, 1, 4, str or MCLICKERS.MESSAGE_DEFAULT_UPGRADE_ALLOWED)
            return
        end
    end

    local price = data.prices[current]
    if self:Pay(ply, price) then
        self:SetUpgradeLevel(upgrade, current + 1)

        self:UpdateUpgrades()
    else
        DarkRP.notify(ply, 1, 4, MCLICKERS.MESSAGE_UPGRADE_INSUFFICIENT)
    end
end

function ENT:RepairHealth(ply)
    if self.info.indestructible then return end
    if self:Health() == self:GetMaxHealth() then return end

    local fract = self:Health() / self:GetMaxHealth()
    local price = math.ceil(self.info.repairHealthCost * (1 - fract))
    if self:Pay(ply, price) then
        self:SetHealth(self:GetMaxHealth())

        self:EmitSound("ambient/machines/pneumatic_drill_" .. math.random(1, 4) .. ".wav")
    else
        DarkRP.notify(ply, 1, 4, MCLICKERS.MESSAGE_REPAIR_INSUFFICIENT)
    end
end

function ENT:Repair(ply)
    if not self:GetBroken() then return end
    if CurTime() < self:GetRepairWaitTime() then return end
    if self.info.maxCycles <= 0 then return end

    local money = ply:getDarkRPVar("money")
    if money >= self.info.repairBrokenCost then
        ply:addMoney(-self.info.repairBrokenCost)
        self:SetBroken(false)
        self.cycles = self.info.maxCycles

        self:EmitSound("ambient/machines/pneumatic_drill_" .. math.random(1, 4) .. ".wav")
    end
end

function ENT:DoClick(ply, isManual)
    if self:GetBroken() or self:GetOverheating() then return end
    if self:GetMoney() == self.info.maxMoney * self.storageMod and self:GetPoints() == self.info.maxPoints * self.storageMod then
        return
    end

    if isManual and MCLICKERS.antiAutoClick then
        if self:GetLookAway() then return end

        self.clickCount = self.clickCount - 1

        if self.clickCount == 0 then
            self:SetLookAway(true)
            self.clickCount = math.random(self.lookAwayMin, self.lookAwayMax)
        end
    end

    self:AddProgress(self.clickPower)

    if IsValid(ply) then
        self.lastPlayerClicked = ply
    end
end

function ENT:TransferOwner(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    self:SetClickerOwner(ply)
    self:SetOwnerName(ply:getDarkRPVar("rpname"))

    local effectdata = EffectData()
    effectdata:SetEntity(self)
    effectdata:SetScale(1)
    util.Effect("entity_remove", effectdata)
end

function ENT:Use(activator, caller, useType, value)
    if not MCLICKERS.wireUserEnabled then return end

    -- The code below is to detect if the entity was used by
    -- a Wire User instead of a Player
    local stackIndex = 1
    local stackEntry = debug.getinfo(stackIndex)
    local isWireUser = false

    while stackEntry ~= nil do
        if string.find(stackEntry.short_src, "gmod_wire_user") then
            isWireUser = true
            break
        end

        stackIndex = stackIndex + 1
        stackEntry = debug.getinfo(stackIndex)
    end

    -- If a Wire User was used instead of a Player, withdraw the money directly
    -- without having to press the withdraw icon on the 3D2D display.
    if isWireUser then
        self:Withdraw(activator)
    end
end

function ENT:OnTakeDamage(damageInfo)
    if self.info.indestructible then return end

    self:EmitSound("ambient/energy/spark" .. math.random(1, 4) .. ".wav")

    self:SetHealth(math.max(self:Health() - (damageInfo:GetDamage() or 10), 0))
    if self:Health() == 0 then
        local effectData = EffectData()
        effectData:SetStart(self:GetPos())
        effectData:SetOrigin(self:GetPos())
        effectData:SetScale(1)
        util.Effect("Explosion", effectData)

        self:Remove()
    end
end

local function checkDistance(ent, ply)
    if not IsValid(ent) or not IsValid(ply) then return false end

    local trace = ply:GetEyeTrace()
    if trace.Entity ~= ent then return false end
    if trace.HitPos:Distance(ply:GetShootPos()) > MCLICKERS.clickRange then return false end

    return true
end

function ENT:Think()
    if self:GetHeat() > 0 and (self.lastHeatTime == nil or CurTime() - self.lastHeatTime >= 0.25) then
        self:SetHeat(self:GetHeat() - self.cooling)
        self.lastHeatTime = CurTime()
    end

    if self.clickInterval and (self.lastClickTime == nil or CurTime() - self.lastClickTime >= self.clickInterval) then
        self:DoClick()

        self.lastClickTime = CurTime()
    end

    if self:GetLookAway() then
        if not IsValid(self.lastPlayerClicked) then
            self:SetLookAway(false)
        else
            if self.lastPlayerClicked:GetEyeTrace().Entity ~= self then
                self:SetLookAway(false)
            end
        end
    end

    if MCLICKERS.stealing and self.stealing and IsValid(self.stealingPly) then
        local trace = self.stealingPly:GetEyeTrace()
        if trace.Entity ~= self or not checkDistance(self, self.stealingPly) then
            self.stealing = false
        end
    end

    if not IsValid(self:GetClickerOwner()) then
        self:TransferOwner(self:Getowning_ent())
    end

    self:NextThink(CurTime() + math.min(0.25, self.clickInterval or 0.25))
    return true
end

net.Receive("money_clicker_withdraw", function(len, ply)
    local ent = net.ReadEntity()

    if not IsValid(ent) then return end
    if not IsValid(ply) then return end
    if ent:GetMoney() == 0 then return end
    if MCLICKERS.stealing and ent:GetClickerOwner() ~= ply then
        DarkRP.notify(ply, 1, 4, MCLICKERS.MESSAGE_NOT_OWNED)
        return
    end

    if not checkDistance(ent, ply) then return end

    ent:Withdraw(ply, true)
end)

net.Receive("money_clicker_steal", function(len, ply)
    local ent = net.ReadEntity()
    local start = net.ReadBool()

    if not MCLICKERS.stealing then return end
    if not IsValid(ent) then return end
    if not IsValid(ply) then return end
    if ent:GetClickerOwner() == ply then return end
    if not checkDistance(ent, ply) then return end

    if start then
        ent.stealing = true
        ent.stealingPly = ply
    else
        if ent.stealing then
            ent:TransferOwner(ply)

            DarkRP.notify(ply, 0, 4, MCLICKERS.MESSAGE_STOLEN)
        end
    end
end)

net.Receive("money_clicker_click", function(len, ply)
    local ent = net.ReadEntity()

    if not IsValid(ent) then return end
    if not IsValid(ply) then return end

    if ply._mClickersLastClick and CurTime() - ply._mClickersLastClick < MCLICKERS.clickDelay then
        return
    end
    ply._mClickersLastClick = CurTime()
    if not checkDistance(ent, ply) then return end

    ent:DoClick(ply, true)
end)

net.Receive("money_clicker_upgrade", function(len, ply)
    local ent = net.ReadEntity()
    local upgrade = net.ReadString()

    if not IsValid(ent) then return end
    if not IsValid(ply) then return end
    if MCLICKERS.stealing and ent:GetClickerOwner() ~= ply then
        DarkRP.notify(ply, 1, 4, MCLICKERS.MESSAGE_NOT_OWNED)
        return
    end

    if upgrade == "cooling" and not ent.info.enableHeat then return end
    if not checkDistance(ent, ply) then return end

    ent:Upgrade(ply, upgrade)
end)

net.Receive("money_clicker_repair", function(len, ply)
    local ent = net.ReadEntity()
    local repairType = net.ReadString()

    if not IsValid(ent) then return end
    if not IsValid(ply) then return end
    if not checkDistance(ent, ply) then return end

    if repairType == "health" then
        ent:RepairHealth(ply)
    else
        ent:Repair(ply)
    end
end)
