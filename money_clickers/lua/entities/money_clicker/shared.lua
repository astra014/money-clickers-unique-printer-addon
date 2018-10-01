ENT.Type = "anim"
ENT.PrintName = "Money Clicker"
ENT.Author = "Metamist"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Category = "Money Clickers"
ENT.IsMoneyClicker = true

DEFINE_BASECLASS("base_gmodentity")

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "owning_ent")
    self:NetworkVar("Entity", 1, "ClickerOwner")

    self:NetworkVar("String", 0, "ClickerName")
    self:NetworkVar("String", 1, "OwnerName")

    self:NetworkVar("Int", 0, "Points")
    self:NetworkVar("Int", 1, "Money")
    self:NetworkVar("Int", 2, "StoredXP")

    self:NetworkVar("Int", 3, "UpgradeAutoClick")
    self:NetworkVar("Int", 4, "UpgradeClickPower")
    self:NetworkVar("Int", 5, "UpgradeCooling")
    self:NetworkVar("Int", 6, "UpgradeStorage")

    self:NetworkVar("Bool", 0, "Broken")
    self:NetworkVar("Bool", 1, "LookAway")
    self:NetworkVar("Bool", 2, "Overheating")

    self:NetworkVar("Float", 0, "RepairWaitTime")
    self:NetworkVar("Float", 1, "ProgressInternal")
    self:NetworkVar("Float", 2, "HeatInternal")

    if SERVER then
    	self:SetMoney(0)
        self:SetPoints(0)
        self:SetStoredXP(0)
        self:SetClickerName("Money Clicker")
        self:SetBroken(false)
        self:SetLookAway(false)

        self:SetUpgradeAutoClick(1)
        self:SetUpgradeClickPower(1)
        self:SetUpgradeCooling(1)
        self:SetUpgradeStorage(1)
    end
end

function ENT:GetProgress()
    return self:GetProgressInternal()
end

function ENT:GetHeat()
    return self:GetHeatInternal()
end

function ENT:GetUpgradeData(upgrade)
    if not self.info then return end

    local data = self.info.upgrades[upgrade]
    if data then
        return data
    else
        MsgC("Missing upgrade ", upgrade, " in config\n")
        return
    end
end

function ENT:GetUpgradeLevel(upgrade)
    if upgrade == "autoClick" then
        return self:GetUpgradeAutoClick()
    elseif upgrade == "clickPower" then
        return self:GetUpgradeClickPower()
    elseif upgrade == "cooling" then
        return self:GetUpgradeCooling()
    elseif upgrade == "storage" then
        return self:GetUpgradeStorage()
    else
        MsgC("Missing upgrade ", upgrade, " in config\n")
        return
    end
end
