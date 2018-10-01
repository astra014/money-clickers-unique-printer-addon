include("shared.lua")

local base_gmodentity = scripted_ents.Get("base_gmodentity")

local function createFont(name, size)
    surface.CreateFont(name, {
        font = "Roboto",
        antialias = true,
        size = size,
        weight = 500,
    })
end

createFont("MoneyClickerTitle", 48)
createFont("MoneyClickerTooltip", 35)
createFont("MoneyClickerMoney", 75)
createFont("MoneyClickerMoneySmall", 50)
createFont("MoneyClickerPoints", 75)
createFont("MoneyClickerPointsSmall", 50)
createFont("MoneyClickerMoneySide", 30)
createFont("MoneyClickerPointsSide", 30)
createFont("MoneyClickerName", 40)
createFont("MoneyClickerNameSide", 30)

createFont("MoneyClickerHealth", 30)
createFont("MoneyClickerHealthSide", 30)

local matHeat = Material("moneyclickers/heat")
local matWithdraw = Material("moneyclickers/creditcard")
local matHealth = Material("moneyclickers/health")
local matRepair = Material("moneyclickers/repair")
local matUpgradeAutoClick = Material("moneyclickers/upgrade_autoclick")
local matUpgradeClickPower = Material("moneyclickers/upgrade_clickpower")
local matUpgradeCooling = Material("moneyclickers/upgrade_cooling")
local matUpgradeStorage = Material("moneyclickers/upgrade_storage")

local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local draw_DrawText = draw.DrawText

local table_insert = table.insert
local sin = math.sin
local cos = math.cos
local abs = math.abs
local max = math.max
local rad = math.rad
local floor = math.floor


local function lerpColor(a, b, x)
    a.r = a.r + (b.r - a.r) * x
    a.g = a.g + (b.g - a.g) * x
    a.b = a.b + (b.b - a.b) * x
    a.a = a.a + (b.a - a.a) * x

    return a
end

local function processFormattedTextData(data)
    local lines = {}
    local currLine = 1
    lines[currLine] = {}
    for j = 1, #data do
        local v = data[j]

        if v == nil then continue end

        if type(v) == "table" then
            lines[currLine] = lines[currLine] or {}
            lines[currLine][#lines[currLine] + 1] = v
        else
            local split = string.Explode("\n", tostring(v))
            for i, str in ipairs(split) do
                lines[currLine] = lines[currLine] or {}

                if #str > 0 then
                    lines[currLine][#lines[currLine] + 1] = str
                end

                if i ~= #split then
                    currLine = currLine + 1
                end
            end
        end
    end

    return lines
end

local function drawFormattedTextData(data, x, y, alpha, alignment)
    local tCurY = y
    local _, lineHeight = surface.GetTextSize("\n")
    local currColor = Color(255, 255, 255)
    for _, line in ipairs(data) do
        local totalStr = ""
        for _, dat in ipairs(line) do
            if type(dat) == "string" then
                totalStr = totalStr .. dat
            end
        end

        local tSubWidth, tSubHeight = surface.GetTextSize(totalStr)
        if alignment == TEXT_ALIGN_CENTER then
            surface.SetTextPos(x - tSubWidth / 2, tCurY)
        elseif alignment == TEXT_ALIGN_RIGHT then
            surface.SetTextPos(x - tSubWidth, tCurY)
        else
            surface.SetTextPos(x, tCurY)
        end

        for _, dat in ipairs(line) do
            if type(dat) == "string" then
                surface.SetTextColor(ColorAlpha(currColor, alpha))
                surface.DrawText(dat)
            else
                currColor = dat
            end
        end

        tCurY = tCurY + lineHeight / 2
    end
end

-- Thanks to Bobbleheadbob for the arc code, slightly modified to suit my needs.
local function precacheArc(cx,cy,radius,thickness,startang,endang,roughness)
    local triarc = {}
    -- local deg2rad = math.pi / 180

    -- Define step
    local roughness = max(roughness or 1, 1)
    local step = roughness

    -- Correct start/end ang
    local startang,endang = startang or 0, endang or 0

    if startang > endang then
        step = abs(step) * -1
    end

    -- Create the inner circle's points.
    local inner = {}
    local r = radius - thickness
    for deg=startang, endang, step do
        local rad = -rad(deg)
        -- local rad = deg2rad * deg
        local ox, oy = cx+(cos(rad)*r), cy+(-sin(rad)*r)
        table_insert(inner, {
            x=ox,
            y=oy,
            u=(ox-cx)/radius + .5,
            v=(oy-cy)/radius + .5,
        })
    end


    -- Create the outer circle's points.
    local outer = {}
    for deg=startang, endang, step do
        local rad = -rad(deg)
        -- local rad = deg2rad * deg
        local ox, oy = cx+(cos(rad)*radius), cy+(-sin(rad)*radius)
        table_insert(outer, {
            x=ox,
            y=oy,
            u=(ox-cx)/radius + .5,
            v=(oy-cy)/radius + .5,
        })
    end


    -- Triangulize the points.
    for tri=1,#inner*2 do -- twice as many triangles as there are degrees.
        local p1,p2,p3
        p1 = outer[floor(tri/2)+1]
        p3 = inner[floor((tri+1)/2)+1]
        if tri%2 == 0 then --if the number is even use outer.
            p2 = outer[floor((tri+1)/2)]
        else
            p2 = inner[floor((tri+1)/2)]
        end

        table_insert(triarc, {p3,p2,p1})
    end

    -- Return a table of triangles to draw.
    return triarc
end

-- Draws an arc on your screen.
-- startang and endang are in degrees,
-- radius is the total radius of the outside edge to the center.
-- cx, cy are the x,y coordinates of the center of the arc.
-- roughness determines how many triangles are drawn. Number between 1-360; 2 or 3 is a good number.
local function drawArc(cx,cy,radius,thickness,startang,endang,roughness,color)
    surface_SetDrawColor(color)
    local arc = precacheArc(cx,cy,radius,thickness,startang,endang,roughness)

    for k,v in ipairs(arc) do
        surface.DrawPoly(v)
    end
end

local function drawCircle(x, y, radius, seg, color)
    local cir = {}

    table_insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })
    for i = 0, 360, seg do
        local a = rad(-i)
        table_insert(cir, { x = x + sin(a) * radius, y = y + cos(a) * radius, u = sin(a) / 2 + 0.5, v = cos(a) / 2 + 0.5 })
    end

    local a = rad(0) -- This is need for non absolute segment counts
    table_insert(cir, { x = x + sin(a) * radius, y = y + cos(a) * radius, u = sin(a) / 2 + 0.5, v = cos(a) / 2 + 0.5 })

    surface_SetDrawColor(color)
    surface.DrawPoly(cir)
end

local function rayPlaneIntersection(start, dir, pos, normal)
    local a = normal:Dot(dir)

    -- Check if the ray is aiming towards the plane
    -- (fail if it origin behind the plane, but that is checked later)
    if a < 0 then
        local b = normal:Dot(pos - start)

        --Check if the ray origin in front of plane
        if b < 0 then
            return start + dir * (b / a)
        end

    --Check if the ray is parallel to the plane
    elseif a == 0 then
        --Check if the ray origin inside the plane
        if normal:Dot(pos - start) == 0 then
            return start
        end
    end

    return false
end

local function buildTooltipData(...)
    local tooltip = { ... }
    local tooltipData = processFormattedTextData(tooltip)
    local tooltipString = ""
    for _, dat in ipairs(tooltip) do
        if type(dat) == "string" then
            tooltipString = tooltipString .. dat
        end
    end

    return {
        data = tooltipData,
        text = tooltipString
    }
end


local buttonMeta = {}
buttonMeta.__index = buttonMeta

buttonMeta.clicked = false
buttonMeta.clickX = 0
buttonMeta.clickY = 0
buttonMeta.alpha = 1
buttonMeta.hoverTime = 0
buttonMeta.clickTime = 0
buttonMeta.clickDuration = 0.3
buttonMeta.tooltipTime = 0
buttonMeta.showTooltip = true
buttonMeta.disabled = false

function buttonMeta:GetRadius()
    return math.sqrt((self.width * self.width / 4) + (self.height * self.height / 4))
end

function buttonMeta:SetTooltip(...)
    self.tooltipData = buildTooltipData(...)
end

function buttonMeta:OnClick() end

function buttonMeta:Think()
    if self.disabled then
        self.hovering = false
        return
    end

    local cx = self.x + self.width / 2
    local cy = self.y + self.height / 2

    local hovering = Vector(self.entity.cursorX, self.entity.cursorY, 0):Distance(Vector(self.x + self.width / 2, self.y + self.height / 2, 0)) < self:GetRadius() + 16
    if hovering and not self.hovering then
        surface.PlaySound(MCLICKERS.SOUND_UI_HOVER)
    end
    self.hovering = hovering

    if hovering and LocalPlayer():KeyDown(IN_USE) and not self.oldUseDown then
        self.clicked = true
        self.clickTime = CurTime()
        self.clickX = self.entity.cursorX
        self.clickY = self.entity.cursorY

        surface.PlaySound(MCLICKERS.SOUND_UI_CLICK)

        self:OnClick(self.clickX, self.clickY)
    end

    self.oldUseDown = LocalPlayer():KeyDown(IN_USE)
end

function buttonMeta:Paint(w, h) end

function buttonMeta:PaintOver(w, h)
    local cx = self.x + self.width / 2
    local cy = self.y + self.height / 2

    if self.hovering then
        self.hoverTime = self.hoverTime + (1 - self.hoverTime) * 0.05
    else
        self.hoverTime = self.hoverTime + (0 - self.hoverTime) * 0.05
    end

    if self.hoverTime > 0.01 then
        drawCircle(cx, cy, self:GetRadius() + 16, 16, Color(255, 255, 255, self.alpha * 20 * self.hoverTime))
    end

    if self.clicked then
        local clickFract = math.Clamp((CurTime() - self.clickTime) / self.clickDuration, 0, 1)
        local animX = self.clickX + (cx - self.clickX) * clickFract
        local animY = self.clickY + (cy - self.clickY) * clickFract
        drawCircle(animX, animY, (self:GetRadius() + 16) * clickFract, 24, Color(255, 255, 255, self.alpha * 50 * (1 - max(clickFract * 2 - 1, 0))))

        if CurTime() - self.clickTime >= self.clickDuration then
            self.clicked = false
            self.clickTime = 1
        end
    end

    if self.tooltipData and self.hovering and self.showTooltip then
        self.tooltipTime = self.tooltipTime + (1 - self.tooltipTime) * 0.05
    else
        self.tooltipTime = self.tooltipTime + (0 - self.tooltipTime) * 0.05
    end

    if self.tooltipTime > 0.01 then
        self.entity:DrawOverlayTooltip(self.x + self.width / 2, self.y + self.height / 2 + 10, "MoneyClickerTooltip", self.tooltipData, self.tooltipTime * self.alpha, TEXT_ALIGN_CENTER)
    end
end

function ENT:Initialize()
    base_gmodentity.Initialize(self)

    self.buttons = {}

    self.menuX = 0
    self.menuOpened = false
    self.menuTime = 0
    self.menuContentAlpha = 0

    self.guiPos = Vector()
    self.guiAng = Angle()

    self.guiWorldPos = Vector()
    self.guiWorldAng = Angle()

    self.cursorX = 0
    self.cursorY = 0

    self.guiWidth = 0
    self.guiHeight = 0

    self.guiTopWidth = 614
    self.guiTopHeight = 616

    self.guiSideWidth = 624
    self.guiSideHeight = 223

    self.guiTopAng = Angle(0, 90, 0)
    self.guiTopPos = Vector(-16.35, -15.15, 10.7)

    self.guiSideAng = Angle(0, 90, 90)
    self.guiSidePos = Vector(16.86, -15.405, 11.025)

    local obbSize = self:OBBMaxs() - self:OBBMins()
    self.boundsTopWidth = obbSize.x / 1.09879
    self.boundsTopHeight = obbSize.y / 1.034

    self.boundsSideWidth = obbSize.x / 1.08
    self.boundsSideHeight = obbSize.z / 1.052

    self.boundsWidth = self.boundsTopWidth
    self.boundsHeight = self.boundsTopHeight

    self.side = false
    self.sideAnimTime = 1

    self.clickTopRadius = self.guiTopWidth / 2 - 110
    self.clickTopCenterX = self.guiTopWidth / 2
    self.clickTopCenterY = self.guiTopHeight / 2 + 70


    self.clickSideRadius = 40
    self.clickSideCenterX = 80
    self.clickSideCenterY = self.guiSideHeight / 2 + 40

    self.colPrimary = Color(0, 0, 0, 0)
    self.colSecondary = Color(0, 0, 0, 0)
    self.colText = Color(0, 0, 0, 0)
    self.colHealth = Color(0, 0, 0, 0)

    self.colorR = self.colPrimary.r
    self.colorG = self.colPrimary.g
    self.colorB = self.colPrimary.b

    -- Buttons
    self.buttonMenu = self:AddButton(30, 68, 40, 34)
    self.buttonMenu.OnClick = function()
        self.menuOpened = not self.menuOpened
        self.menuTime = CurTime() + 0.5
    end
    self.buttonMenu.Paint = function(btn, w, h)
        surface_SetDrawColor(Color(255, 255, 255, btn.alpha * 255))
        surface_DrawRect(btn.x, btn.y, w, 6)
        surface_DrawRect(btn.x, btn.y + 14, w, 6)
        surface_DrawRect(btn.x, btn    .y + 28, w, 6)
    end
    self.buttonMenu:SetTooltip(MCLICKERS.language.textUpgrades)

    self.buttonWithdraw = self:AddButton(self.guiTopWidth - 40 - 30, 60, 40, 40)
    local buttonWithdrawThink = self.buttonWithdraw.Think
    self.buttonWithdraw.Think = function(btn)
        buttonWithdrawThink(btn)

        if MCLICKERS.stealing and self:GetClickerOwner() ~= LocalPlayer() and self.stealing then
            if CurTime() >= self.stealStartTime + MCLICKERS.stealHoldTime then
                net.Start("money_clicker_steal")
                    net.WriteEntity(self)
                    net.WriteBool(false)
                net.SendToServer()

                self.stealing = false
            end

            if not btn.hovering or not LocalPlayer():KeyDown(IN_USE) then
                self.stealing = false
            end
        end
    end
    self.buttonWithdraw.OnClick = function(btn)
        if not MCLICKERS.stealing or self:GetClickerOwner() == LocalPlayer() then
            net.Start("money_clicker_withdraw")
                net.WriteEntity(self)
            net.SendToServer()
        else
            self.stealing = true
            self.stealStartTime = CurTime()
            btn.stealCircleAng = 0

            net.Start("money_clicker_steal")
            net.WriteEntity(self)
            net.WriteBool(true)
            net.SendToServer()
        end
    end
    self.buttonWithdraw.stealCircleAlpha = 0
    self.buttonWithdraw.stealCircleAng = 0
    self.buttonWithdraw.Paint = function(btn, w, h)
        surface_SetDrawColor(Color(255, 255, 255, btn.alpha * 255))
        surface.SetMaterial(matWithdraw)
        surface_DrawTexturedRect(btn.x - 5, btn.y - 5, w + 10, h + 10)
        draw.NoTexture()

        btn.showTooltip = not self.stealing
        if self.stealing then
            local fract = 1 - math.Clamp((self.stealStartTime + MCLICKERS.stealHoldTime - CurTime()) / MCLICKERS.stealHoldTime, 0, 1)
            btn.stealCircleAlpha = btn.stealCircleAlpha + (1 - btn.stealCircleAlpha) * 2 * FrameTime()
            btn.stealCircleAng = btn.stealCircleAng + (fract * 360 - btn.stealCircleAng) * 5 * FrameTime()
        else
            btn.stealCircleAlpha = btn.stealCircleAlpha + (0 - btn.stealCircleAlpha) * 2 * FrameTime()
            if btn.stealCircleAng > 320 then
                btn.stealCircleAng = btn.stealCircleAng + (360 - btn.stealCircleAng) * 5 * FrameTime()
            end
        end


        if btn.stealCircleAlpha > 0.01 then
            drawArc(btn.x + w / 2, btn.y + h / 2, w / 1, 6, -90, -90 + math.ceil((btn.stealCircleAng + 2) * 10) / 10, 10, ColorAlpha(self.colSecondary, btn.stealCircleAlpha * 255))
        end
    end

    self.buttonHealth = self:AddButton(self.guiTopWidth - 80 - 30, self.guiTopHeight - 80 - 30, 80, 80)
    self.buttonHealth.OnClick = function()
        if self.info.indestructible then return end

        net.Start("money_clicker_repair")
            net.WriteEntity(self)
            net.WriteString("health")
        net.SendToServer()
    end
    self.buttonHealth.iconFade = 0
    self.buttonHealth.manualPainting = true
    self.buttonHealth.Paint = function(btn, w, h)
        if btn.hovering and not self.info.indestructible then
            btn.iconFade = btn.iconFade + (1 - btn.iconFade) * 0.05
        else
            btn.iconFade = btn.iconFade + (0 - btn.iconFade) * 0.05
        end

        local pulse = math.max(sin(CurTime() * 5), 0) * (self.smoothSide and 4 or 14)
        local progress = 1
        if not self.info.indestructible then
            progress = self.smoothHealth / self:GetMaxHealth()
        end
        local col = lerpColor(Color(0, 0, 0, 40), self.colHealth, math.Clamp(progress + sin(CurTime() * 5) / 10, 0, 1))
        surface_SetDrawColor(ColorAlpha(col, btn.alpha * (1 - btn.iconFade) * col.a))
        surface.SetMaterial(matHealth)
        surface_DrawTexturedRect(btn.x - pulse / 2, btn.y - pulse / 2, w + pulse, h + pulse)
        draw.NoTexture()

        surface_SetDrawColor(Color(255, 255, 255, btn.alpha * btn.iconFade * 255))
        surface.SetMaterial(matRepair)
        surface_DrawTexturedRect(btn.x + 7, btn.y + 7, w - 14, h - 14)
        draw.NoTexture()

        local health = math.Round(self.smoothHealth)
        if self.info.indestructible then health = "∞" end

        if self.smoothSide then
            draw.DrawText(health, "MoneyClickerHealthSide", btn.x - 8, btn.y + h / 2 - 15, ColorAlpha(self.colText, btn.alpha * 255), TEXT_ALIGN_RIGHT)
        else
            draw.DrawText(health, "MoneyClickerHealth", btn.x + w / 2, btn.y + h - 8, ColorAlpha(self.colText, btn.alpha * 255), TEXT_ALIGN_CENTER)
        end
    end

    self.buttonRepair = self:AddButton(
        self.clickTopCenterX - self.clickTopRadius,
        self.clickTopCenterY - self.clickTopRadius,
        self.clickTopRadius * 2, self.clickTopRadius * 2)
    self.buttonRepair.OnClick = function()
        if self:GetBroken() and CurTime() >= self:GetRepairWaitTime() then
            net.Start("money_clicker_repair")
                net.WriteEntity(self)
                net.WriteString("broken")
            net.SendToServer()
        end
    end
    self.buttonRepair.manualPainting = true
    self.buttonRepair.alpha = 0
    self.buttonRepair.disabled = true
    self.buttonRepair.Paint = function(btn, w, h)
        surface_SetDrawColor(Color(255, 255, 255, btn.alpha * 255))
        surface.SetMaterial(matRepair)
        surface_DrawTexturedRect(btn.x - 5, btn.y - 5, w + 10, h + 10)
        draw.NoTexture()
    end


    local function SendUpgradeMessage(update)
        net.Start("money_clicker_upgrade")
            net.WriteEntity(self)
            net.WriteString(update)
        net.SendToServer()
    end

    self.buttonUpg1 = self:AddButton(80, 160, 150, 150)
    self.buttonUpg1.alpha = 0
    self.buttonUpg1.Paint = function(btn, w, h)
        surface_SetDrawColor(Color(255, 255, 255, btn.alpha * 255))
        surface.SetMaterial(matUpgradeAutoClick)
        surface_DrawTexturedRect(btn.x, btn.y, w, h)
        draw.NoTexture()
    end
    self.buttonUpg1.OnClick = function()
        SendUpgradeMessage("autoClick")
    end

    self.buttonUpg2 = self:AddButton(self.guiTopWidth - 80 - 150, 160, 150, 150)
    self.buttonUpg2.alpha = 0
    self.buttonUpg2.Paint = function(btn, w, h)
        surface_SetDrawColor(Color(255, 255, 255, btn.alpha * 255))
        surface.SetMaterial(matUpgradeClickPower)
        surface_DrawTexturedRect(btn.x, btn.y, w, h)
        draw.NoTexture()
    end
    self.buttonUpg2.OnClick = function()
        SendUpgradeMessage("clickPower")
    end

    self.buttonUpg3 = self:AddButton(self.guiTopWidth / 2 - 75, self.guiHeight - 50 - 150, 150, 150)
    self.buttonUpg3.alpha = 0
    self.buttonUpg3.Paint = function(btn, w, h)
        surface_SetDrawColor(Color(255, 255, 255, btn.alpha * 255))
        surface.SetMaterial(matUpgradeCooling)
        surface_DrawTexturedRect(btn.x, btn.y, w, h)
        draw.NoTexture()
    end
    self.buttonUpg3.OnClick = function()
        SendUpgradeMessage("cooling")
    end

    self.buttonUpg4 = self:AddButton(self.guiTopWidth / 2 - 75, self.guiHeight - 50 - 150, 150, 150)
    self.buttonUpg4.alpha = 0
    self.buttonUpg4.Paint = function(btn, w, h)
        surface_SetDrawColor(Color(255, 255, 255, btn.alpha * 255))
        surface.SetMaterial(matUpgradeStorage)
        surface_DrawTexturedRect(btn.x, btn.y, w, h)
        draw.NoTexture()
    end
    self.buttonUpg4.OnClick = function()
        SendUpgradeMessage("storage")
    end

    self.upgradeButtons = {
        self.buttonUpg1,
        self.buttonUpg2,
        self.buttonUpg3,
        self.buttonUpg4,
    }

    self.clicks = {}

    self.smoothProgress = 0
    self.smoothHeat = 0
    self.smoothHeatColor = Color(0, 0, 0, 40)
    self.smoothMoney = 0
    self.smoothPoints = 0
    self.smoothXP = 0
    self.smoothHealth = self:Health()
    self.smoothBroken = 0
    self.smoothLookAway = 0

    self.tooltipLookAway = buildTooltipData(Color(255, 150, 0), "Please look away once\nbefore clicking any further.")

    net.Start("money_clicker_info")
    net.WriteEntity(self)
    net.SendToServer()
end

function ENT:InitializeInfo(info)
    self.info = info

    self.colPrimary = self.info.colorPrimary
    self.colSecondary = self.info.colorSecondary
    self.colText = self.info.colorText
    self.colHealth = self.info.colorHealth

    self.colorR = self.colPrimary.r
    self.colorG = self.colPrimary.g
    self.colorB = self.colPrimary.b

    if not self.info.enableHeat then
        table.remove(self.upgradeButtons, 3)
    end
end

net.Receive("money_clicker_info", function(len)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    ent:InitializeInfo(net.ReadTable())
end)

function ENT:BuildUpgradeTooltip(upgrade, current, statStr, prefix, suffix)
    if not self.info then return end

    local data = self:GetUpgradeData(upgrade)
    local stat = data.stats[current]
    local price = data.prices[current]
    local priceLabel = (price == nil) and MCLICKERS.language.textUpgradeMaxed or (MCLICKERS.formatPoints(price))

    return {
        data.name, "\n",
        Color(0, 255, 0), prefix or "", stat, suffix or "",
        Color(255, 255, 255), " ", statStr, "\n",
        Color(100, 200, 255), priceLabel, "\n",
        Color(0, 255, 0), current .. " / " .. #data.stats
    }
end

function ENT:UpdateTooltips()
    if not self.info then return end

    self.buttonUpg1:SetTooltip(unpack(self:BuildUpgradeTooltip("autoClick", self:GetUpgradeAutoClick(), MCLICKERS.language.unitAutoClick)))
    self.buttonUpg2:SetTooltip(unpack(self:BuildUpgradeTooltip("clickPower", self:GetUpgradeClickPower(), MCLICKERS.language.unitClickPower)))
    self.buttonUpg3:SetTooltip(unpack(self:BuildUpgradeTooltip("cooling", self:GetUpgradeCooling(), MCLICKERS.language.unitCooling, "-")))
    self.buttonUpg4:SetTooltip(unpack(self:BuildUpgradeTooltip("storage", self:GetUpgradeStorage(), MCLICKERS.language.unitStorage, nil, "x")))

    if not MCLICKERS.stealing or self:GetClickerOwner() == LocalPlayer() then
        self.buttonWithdraw:SetTooltip(MCLICKERS.language.textWithdraw, "\n", Color(0, 255, 0), "+" .. DarkRP.formatMoney(self:GetMoney()))
    else
        self.buttonWithdraw:SetTooltip(Color(255, 100, 0), MCLICKERS.language.textSteal, "\n", Color(100, 200, 255), string.format(MCLICKERS.language.textStealHold, MCLICKERS.stealHoldTime))
    end

    if not self.info.indestructible then
        local repairPrice = math.ceil(self.info.repairHealthCost * (1 - (self:Health() / self:GetMaxHealth())))
        self.buttonHealth:SetTooltip(MCLICKERS.language.textRepair, "\n", Color(255, 100, 0), MCLICKERS.formatPoints(repairPrice))
    end

    if self:GetBroken() then
        local data = { MCLICKERS.language.textRepair .. "\n" }
        if CurTime() < self:GetRepairWaitTime() then
            data[#data + 1] = Color(100, 200, 255)
            data[#data + 1] = string.format(MCLICKERS.language.textRepairWait, math.ceil(self:GetRepairWaitTime() - CurTime())) .. "\n"
        end

        data[#data + 1] = Color(255, 100, 0)
        data[#data + 1] = DarkRP.formatMoney(self.info.repairBrokenCost)

        self.buttonRepair:SetTooltip(unpack(data))
    end
end

function ENT:GetCursorPosition()
    local lp = LocalPlayer()
    local trace = util.TraceLine({
        start = lp:EyePos(),
        endpos = lp:EyePos() + LocalPlayer():GetAimVector() * MCLICKERS.clickRange,
        filter = lp
    })
    if trace.Entity ~= self then return 0, 0 end

    local rayVec = util.IntersectRayWithPlane(lp:EyePos(), lp:GetAimVector(), self.guiWorldPos, self.guiWorldAng:Up())
    if not rayVec then return 0, 0 end

    local dist = lp:EyePos():Distance(rayVec)
    if dist > MCLICKERS.clickRange then return 0, 0 end

    local localRayVec = WorldToLocal(rayVec, Angle(), self.guiWorldPos, self.guiWorldAng)

    local cursorFractX = localRayVec.x / self.boundsWidth
    local cursorFractY = -localRayVec.y / self.boundsHeight

    if cursorFractX < 0 or cursorFractX > 1 or cursorFractY < 0 or cursorFractY > 1 then
        return -1, -1
    end

    return cursorFractX * self.guiWidth, cursorFractY * self.guiHeight
end

function ENT:AddButton(x, y, width, height)
    self.buttons = self.buttons or {}

    local button = setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        entity = self
    }, buttonMeta)

    self.buttons[#self.buttons + 1] = button

    return button
end

local lastClick
function ENT:SendClick()
    if self:GetLookAway() then return end

    if lastClick then
        if CurTime() - lastClick < MCLICKERS.clickDelay then
            return false
        end
    end
    lastClick = CurTime()

    net.Start("money_clicker_click")
        net.WriteEntity(self)
    net.SendToServer()

    return true
end

function ENT:Think()
    base_gmodentity.Think(self)

    if not self.lastThink then self.lastThink = CurTime() end
    local elapsed = CurTime() - self.lastThink
    self.lastThink = CurTime()

    local cursorX, cursorY = self:GetCursorPosition()
    self.cursorX = cursorX
    self.cursorY = cursorY

    for _, button in ipairs(self.buttons) do
        if button.alpha < 0.01 then continue end
        button:Think()
    end

    if self.menuOpened then
        if self.menuX > self.guiWidth - 0.01 then
            self.menuX = self.guiWidth
        else
            self.menuX = self.menuX + (self.guiWidth - self.menuX) * 5 * elapsed
        end

        self.colorR = self.colorR + (self.colSecondary.r - self.colorR) * 1.5 * elapsed
        self.colorG = self.colorG + (self.colSecondary.g - self.colorG) * 1.5 * elapsed
        self.colorB = self.colorB + (self.colSecondary.b - self.colorB) * 1.5 * elapsed
    else
        if CurTime() > self.menuTime then
            if self.menuX < 0.01 then
                self.menuX = 0
            else
                self.menuX = self.menuX + (0 - self.menuX) * 5 * elapsed
            end

            self.colorR = self.colorR + (self.colPrimary.r - self.colorR) * 1.5 * elapsed
            self.colorG = self.colorG + (self.colPrimary.g - self.colorG) * 1.5 * elapsed
            self.colorB = self.colorB + (self.colPrimary.b - self.colorB) * 1.5 * elapsed
        end
    end

    if self.menuOpened then
        if self.menuX > self.guiWidth - 10 then
            self.menuContentAlpha = self.menuContentAlpha + (1.0 - self.menuContentAlpha) * 2 * elapsed
        end
    else
        self.menuContentAlpha = self.menuContentAlpha + (0.0 - self.menuContentAlpha) * 8 * elapsed
    end

    for _, btn in ipairs(self.upgradeButtons) do
        btn.disabled = not self.menuOpened
        btn.alpha = self.menuContentAlpha
    end

    local color = self:GetColor()
    if floor(abs(self.colorR - color.r)) ~= 0 or floor(abs(self.colorG - color.g)) ~= 0 or floor(abs(self.colorB - color.b)) ~= 0 then
        self:SetColor(Color(self.colorR, self.colorG, self.colorB))
    end

    if not self.menuOpened then
        if LocalPlayer():KeyDown(IN_USE) and not self.oldClickDown and not self:GetOverheating() and not self:GetBroken() then
            local cx = self.clickTopCenterX
            local cy = self.clickTopCenterY
            local radius = self.clickTopRadius

            if self.side then
                cx = self.clickSideCenterX
                cy = self.clickSideCenterY
                radius = self.clickSideRadius
            end

            local dx = cx - cursorX
            local dy = cy - cursorY
            local dist = math.sqrt((dx * dx) + (dy * dy))

            if dist <= radius then
                if not self:GetLookAway() then
                    if self:SendClick() then
                        self.clicks[#self.clicks + 1] = {
                            x = cursorX,
                            y = cursorY,
                            time = CurTime(),
                            duration = 0.3
                        }

                        surface.PlaySound(MCLICKERS.SOUND_CLICK)
                    end
                end
            end
        end
    end

    self.oldClickDown = LocalPlayer():KeyDown(IN_USE)

    if self.lastTooltipUpdate == nil or CurTime() - self.lastTooltipUpdate >= 0.5 then
        self:UpdateTooltips()
        self.lastTooltipUpdate = CurTime()
    end
end

function ENT:DrawOverlayTooltip(x, y, font, tooltipData, alpha, alignment)
    if x == nil or y == nil or not tooltipData then return end

    alpha = alpha or 1
    alignment = alignment or TEXT_ALIGN_LEFT
    if alpha < 0.01 then return end

    surface.SetFont(font)
    local tw, th = surface.GetTextSize(tooltipData.text)
    surface_SetDrawColor(0, 0, 0, 200 * alpha)

    local offX = alignment == TEXT_ALIGN_LEFT and 0 or (alignment == TEXT_ALIGN_RIGHT and tw or (tw / 2))
    local tx = math.Clamp(x - offX - 15, 0, self.guiWidth - tw - 30)
    local ty = math.Clamp(y - th / 2, 0, self.guiHeight - th - 5)
    surface_DrawRect(tx, ty, tw + 30, th + 5)

    drawFormattedTextData(tooltipData.data, tx + tw / 2 + 15, ty, 255 * alpha, TEXT_ALIGN_CENTER)
end

function ENT:DrawOverlay()
    local elapsed = FrameTime()

    if not self.info then return end

    cam.Start3D2D(self.guiWorldPos, self.guiWorldAng, 0.05)
        local w, h = self.guiWidth, self.guiHeight

        draw.NoTexture()

        local headerBar = self.smoothSide and 30 or 40
        local clickCenterX = self.smoothSide and self.clickSideCenterX or self.clickTopCenterX
        local clickCenterY = self.smoothSide and self.clickSideCenterY or self.clickTopCenterY
        local clickRadius = self.smoothSide and self.clickSideRadius or self.clickTopRadius


        local progress = self:GetProgress() / 100

        -- Ensure a smooth transition from 1 to 0
        if self.smoothProgress > progress then
            self.smoothProgress = (self.smoothProgress + (1 + progress - self.smoothProgress) * 5 * elapsed) % 1
            if self.smoothProgress >= 0.9999 then self.smoothProgress = 0 end

            if not self.prevCycled then
                surface.PlaySound(MCLICKERS.SOUND_CYCLE)

                self.prevCycled = true
            end
        else
            self.smoothProgress = self.smoothProgress + math.max(progress - self.smoothProgress, 0) * 5 * elapsed

            self.prevCycled = false
        end

        -- Smooth transition for heat
        self.smoothHeat = self.smoothHeat + (self:GetHeat() - self.smoothHeat) * 5 * elapsed

        -- Smooth transition money and points
        self.smoothMoney = self.smoothMoney + (self:GetMoney() - self.smoothMoney) * 2.5 * elapsed
        self.smoothPoints = self.smoothPoints + (self:GetPoints() - self.smoothPoints) * 2.5 * elapsed
        self.smoothXP = self.smoothXP + (self:GetStoredXP() - self.smoothXP) * 2.5 * elapsed
        self.smoothHealth = self.smoothHealth + (self:Health() - self.smoothHealth) * 2.5 * elapsed
        self.smoothBroken = self.smoothBroken + ((self:GetBroken() and 1 or 0) - self.smoothBroken) * 2.5 * elapsed

        if self:GetOverheating() then
            lerpColor(self.smoothHeatColor, ColorAlpha(self.colSecondary, 255), 2.5 * elapsed)
        else
            lerpColor(self.smoothHeatColor, Color(0, 0, 0, 40), 2.5 * elapsed)
        end

        local money = math.Round(self.smoothMoney)
        local points = math.Round(self.smoothPoints)
        local xp = math.Round(self.smoothXP)


        if math.Round(self.menuX) < w then
            surface_SetDrawColor(self.colPrimary)
            surface_DrawRect(0, 0, w, h)
        end

        if math.Round(self.menuX) < w then

            local heatFract = self.smoothHeat / 100
            if heatFract > 0 then
                local heat = {}
                local heatCenterX = clickCenterX
                local heatCenterY = clickCenterY
                local heatRadius = clickRadius - 2
                local heatSeg = 12
                local angDiff = 90 - 180 * heatFract


                local a = rad(-90 + angDiff)
                table_insert(heat, {
                    x = heatCenterX + sin(a) * heatRadius,
                    y = heatCenterY + cos(a) * heatRadius,
                    u = sin(a) / 2 + 0.5, v = cos(a) / 2 + 0.5 })

                for i = -90 + angDiff, 90 - angDiff, heatSeg do
                    local a = rad(-i)
                    table_insert(heat, {
                        x = heatCenterX + sin(a) * heatRadius,
                        y = heatCenterY + cos(a) * heatRadius,
                        u = sin(a) / 2 + 0.5, v = cos(a) / 2 + 0.5 })
                end

                local a = rad(90 - angDiff)
                table_insert(heat, {
                    x = heatCenterX + sin(a) * heatRadius,
                    y = heatCenterY + cos(a) * heatRadius,
                    u = sin(a) / 2 + 0.5, v = cos(a) / 2 + 0.5 })

                surface_SetDrawColor(self.smoothHeatColor)
                surface.DrawPoly(heat)

                surface_SetDrawColor(self.colPrimary)
                surface.SetMaterial(matHeat)
                surface_DrawTexturedRect(heatCenterX - heatRadius, heatCenterY - heatRadius, heatRadius * 2, heatRadius * 2)
                draw.NoTexture()
            end

            self.buttonRepair.alpha = self.smoothBroken
            self.buttonRepair.disabled = self.smoothBroken < 0.01
            self.buttonRepair.width = clickRadius
            self.buttonRepair.height = clickRadius
            self.buttonRepair.x = clickCenterX - self.buttonRepair.width / 2
            self.buttonRepair.y = clickCenterY - self.buttonRepair.height / 2


            if self.smoothSide then
                local leftOffset = clickRadius * 2 + 70
                local rightOffset = 40
                local barWidth = self.smoothProgress * (self.guiWidth - rightOffset - leftOffset)
                surface_SetDrawColor(Color(0, 0, 0, 40))
                surface_DrawRect(leftOffset, clickCenterY - 3, self.guiWidth - rightOffset - leftOffset, 6)

                surface_SetDrawColor(self.colSecondary)
                surface_DrawRect(leftOffset, clickCenterY - 3, barWidth, 6)

                drawCircle(leftOffset + barWidth, clickCenterY, 12, 24, self.colSecondary)

                drawArc(clickCenterX, clickCenterY, clickRadius + 5, 4, 0, 360, 6, Color(0, 0, 0, 40))

                draw_DrawText(DarkRP.formatMoney(money), "MoneyClickerMoneySide", leftOffset + 16, clickCenterY - 46, self.colText, TEXT_ALIGN_LEFT)
                draw_DrawText(MCLICKERS.formatPoints(points), "MoneyClickerPointsSide", leftOffset + 16, clickCenterY + 16, self.colText, TEXT_ALIGN_LEFT)

                if self.info.xpPerCycle and LevelSystemConfiguration then
                    draw_DrawText(xp .. " XP", "MoneyClickerPointsSide", (leftOffset + 16 + self.guiWidth - rightOffset - 16) / 2, clickCenterY + 16, self.colText, TEXT_ALIGN_CENTER)
                end

                draw_DrawText(self:GetOwnerName(), "MoneyClickerNameSide", self.guiWidth - rightOffset - 16, clickCenterY - 46, self.colText, TEXT_ALIGN_RIGHT)
            else
                local ang = self.smoothProgress * 360
                local radius = w / 2 - 100
                local thickness = 10
                local cx = w / 2
                local cy = h / 2 + 70
                drawArc(cx, cy, radius + thickness / 2, thickness, 0, 360, 6, Color(0, 0, 0, 40))
                drawArc(cx, cy, radius + thickness / 2, thickness, -90, -90 + math.ceil((ang + 2) * 10) / 10, 6, self.colSecondary)

                local radAng = rad(-90 + ang)
                local dotX = cos(radAng) * radius
                local dotY = sin(radAng) * radius
                drawCircle(cx + dotX, cy + dotY, 16, 24, self.colSecondary)

                local xpOffset = 0

                if self.info.xpPerCycle and LevelSystemConfiguration then
                    xpOffset = 20
                    draw_DrawText(xp .. " XP", "MoneyClickerMoneySmall", w / 2, h / 2 + 180, self.colText, TEXT_ALIGN_CENTER)
                end

                local textCol = ColorAlpha(self.colText, (1 - self.smoothBroken) * 255)
                draw_DrawText(MCLICKERS.language.textMoney, "MoneyClickerMoney", w / 2, h / 2 - 70 - xpOffset, textCol, TEXT_ALIGN_CENTER)
                draw_DrawText(DarkRP.formatMoney(money), "MoneyClickerMoneySmall", w / 2, h / 2 - xpOffset, textCol, TEXT_ALIGN_CENTER)

                draw_DrawText(MCLICKERS.language.textPoints, "MoneyClickerPoints", w / 2, h / 2 + 80 - xpOffset * 2, textCol, TEXT_ALIGN_CENTER)
                draw_DrawText(MCLICKERS.formatPoints(points), "MoneyClickerPointsSmall", w / 2, h / 2 + 150 - xpOffset * 2, textCol, TEXT_ALIGN_CENTER)

                draw_DrawText(self:GetOwnerName(), "MoneyClickerName", self.guiWidth / 2, headerBar + 60, self.colText, TEXT_ALIGN_CENTER)
            end

            draw.NoTexture()
            for i = #self.clicks, 1, -1 do
                local click = self.clicks[i]
                local fract = math.Clamp((CurTime() - click.time) / click.duration, 0, 1)

                drawCircle(
                    click.x + (clickCenterX - click.x) * fract,
                    click.y + (clickCenterY - click.y) * fract,
                    fract * clickRadius, 12, Color(255, 255, 255, 50 * (1 - fract)))

                if CurTime() - click.time >= click.duration then
                    table.remove(self.clicks, i)
                end
            end
        end

        self.buttonHealth:Paint(self.buttonHealth.width, self.buttonHealth.height)
        self.buttonHealth:PaintOver(self.buttonHealth.width, self.buttonHealth.height)

        self.buttonRepair:Paint(self.buttonRepair.width, self.buttonRepair.height)
        self.buttonRepair:PaintOver(self.buttonRepair.width, self.buttonRepair.height)

        surface_SetDrawColor(self.colSecondary)
        surface_DrawRect(0, 0, self.menuX, h)

        surface_SetDrawColor(Color(0, 0, 0, 80))
        surface_DrawRect(0, 0, w, headerBar)

        if self.smoothSide then
            draw_DrawText(MCLICKERS.language.textPoints .. ": " .. MCLICKERS.formatPoints(points), "MoneyClickerPointsSide", w / 2, headerBar + 70, ColorAlpha(self.colText, 255 * self.menuContentAlpha), TEXT_ALIGN_CENTER)
        else
            draw_DrawText(MCLICKERS.language.textPoints .. ": " .. MCLICKERS.formatPoints(points), "MoneyClickerPointsSide", w / 2, headerBar + 80, ColorAlpha(self.colText, 255 * self.menuContentAlpha), TEXT_ALIGN_CENTER)
        end

        draw_DrawText(self:GetClickerName(), "MoneyClickerTitle", 96, headerBar + 17, self.colText, TEXT_ALIGN_LEFT)
        self.buttonMenu.y = headerBar + 23
        self.buttonWithdraw.y = headerBar + 23

        if self.smoothSide then
            for i, btn in ipairs(self.upgradeButtons) do
                btn.x = 80 + (self.guiWidth - 80) / #self.upgradeButtons * (i - 1)
                btn.y = 150

                btn.width = 50
                btn.height = 50
            end

            self.buttonHealth.width = 36
            self.buttonHealth.height = 36
            self.buttonHealth.x = self.guiWidth - self.buttonHealth.width - 50
            self.buttonHealth.y = self.guiHeight - self.buttonHealth.height - 22
        else
            local bx = 1
            local by = 1
            for i, btn in ipairs(self.upgradeButtons) do
                local maxRow = math.min(#self.upgradeButtons - (by - 1) * 2, 2)
                btn.x = self.guiWidth / (maxRow * 2) * (-(i % 2) * 2 + 3) - 75
                btn.y = by * 250 - 60

                if i % 2 == 0 then
                    by = by + 1
                end

                btn.width = 150
                btn.height = 150
            end

            self.buttonHealth.width = 80
            self.buttonHealth.height = 80
            self.buttonHealth.x = self.guiWidth - self.buttonHealth.width - 30
            self.buttonHealth.y = self.guiHeight - self.buttonHealth.height - 30
        end

        for _, button in ipairs(self.buttons) do
            if button.alpha < 0.01 then continue end
            if button.manualPainting then continue end

            button:Paint(button.width, button.height)
        end

        for _, button in ipairs(self.buttons) do
            if button.alpha < 0.01 then continue end
            if button.manualPainting then continue end

            button:PaintOver(button.width, button.height)
        end

        if self:GetLookAway() then
            self.smoothLookAway = self.smoothLookAway + (1 - self.smoothLookAway) * 2.5 * elapsed
        else
            self.smoothLookAway = self.smoothLookAway + (0 - self.smoothLookAway) * 2.5 * elapsed
        end
        self:DrawOverlayTooltip(clickCenterX, clickCenterY, "MoneyClickerTooltip", self.tooltipLookAway, self.smoothLookAway, TEXT_ALIGN_CENTER)

    cam.End3D2D()
end

function ENT:Draw(flags)
    if not self.info then return end

    render.SuppressEngineLighting(true)
    base_gmodentity.Draw(self, flags)
    local lp = LocalPlayer()

    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    if dist > 150 then
        render.SuppressEngineLighting(false)
        surface.SetAlphaMultiplier(1)
        return
    end

    local upDot = (lp:EyePos() - self:LocalToWorld(self.guiTopPos)):GetNormalized():Dot(self:GetUp())
    local forwardDot = (lp:EyePos() - self:LocalToWorld(self.guiSidePos)):GetNormalized():Dot(self:GetForward())
    local trigger = upDot < 0.2 and forwardDot > 0
    if not trigger then
        local upTrace = util.TraceLine({
            start = self:GetPos(),
            endpos = self:GetPos() + self:GetUp() * 15,
            filter = self
        })
        trigger = upTrace.Hit
        if trigger and IsValid(upTrace.Entity) and upTrace.Entity:IsPlayer() then
            trigger = false
        end
    end

    if not trigger then
        local downTrace = util.TraceLine({
            start = self:GetPos(),
            endpos = self:GetPos() - self:GetUp() * 5,
            filter = self
        })
        if IsValid(downTrace.Entity) and downTrace.Entity:GetClass() == "money_clicker" then
            trigger = true
        end
    end

    if self.side ~= trigger then
        self.side = trigger
        self.sideAnimTime = 0
    end
    self.sideAnimTime = math.min(self.sideAnimTime + 0.01, 1)

    if self.sideAnimTime > 0.5 then
        self.smoothSide = self.side

        if self.side then
            self.guiWidth = self.guiSideWidth
            self.guiHeight = self.guiSideHeight

            self.boundsWidth = self.boundsSideWidth
            self.boundsHeight = self.boundsSideHeight

            self.guiAng = self.guiSideAng
            self.guiPos = self.guiSidePos
        else
            self.guiWidth = self.guiTopWidth
            self.guiHeight = self.guiTopHeight

            self.boundsWidth = self.boundsTopWidth
            self.boundsHeight = self.boundsTopHeight

            self.guiAng = self.guiTopAng
            self.guiPos = self.guiTopPos
        end
    end

    self.guiWorldPos = self:LocalToWorld(self.guiPos)
    self.guiWorldAng = self:LocalToWorldAngles(self.guiAng)

    surface.SetAlphaMultiplier((1 - math.Clamp((dist - 125) / 25, 0, 1)) * (1 - sin(math.pi * self.sideAnimTime)))

    local dot = (lp:EyePos() - self.guiWorldPos):Dot(self.guiWorldAng:Up())
    if dot > 0 then
        self:DrawOverlay()
    end

    render.SuppressEngineLighting(false)

    surface.SetAlphaMultiplier(1)
end
