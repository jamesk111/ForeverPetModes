local _, F = ...
local buttons = {}

local function label(parent, font)
    return parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
end

local function newButton(parent)
    local b = CreateFrame("Button", nil, parent, "InsecureActionButtonTemplate")
    b.edge = b:CreateTexture(nil, "BACKGROUND")
    b.edge:SetAllPoints()
    b.edge:SetColorTexture(0.62, 0.52, 0.34)
    b.fill = b:CreateTexture(nil, "BORDER")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("CENTER")
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.text = label(b, "GameFontHighlightSmall")
    b.text:SetPoint("CENTER")
    b.text:SetWordWrap(false)
    b.mark = label(b, "GameFontNormalSmall")
    b.mark:SetPoint("TOPRIGHT", -3, -1)
    b.mark:SetText("*")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.profile.label)
        local missing = F.differences(self.profile, F.readPet())
        if #missing == 0 then GameTooltip:AddLine("Active", 0.6, 1, 0.6) end
        for _, line in ipairs(missing) do GameTooltip:AddLine(line, 1, 0.88, 0.6, true) end
        if InCombatLockdown() then GameTooltip:AddLine("Use the Blizzard pet bar in combat.", 1, 1, 1) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    F.prepareButton(b)
    return b
end

function F.createPanel()
    local panel = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    F.panel = panel
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel.bg = panel:CreateTexture(nil, "BACKGROUND")
    panel.bg:SetAllPoints()
    panel.title = label(panel, "GameFontNormalSmall")
    panel.title:SetPoint("TOP", 0, -5)
    panel.title:SetText("Forever Pet Modes")
    panel:SetScript("OnDragStart", function(self)
        if not F.db.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    panel:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        local p, _, r, x, y = self:GetPoint()
        F.db.position = { point = p, relative = r, x = x, y = y }
    end)
end

function F.layout()
    if InCombatLockdown() then return end
    local d, panel = F.db, F.panel
    local n, header, pad = #d.profiles, d.title and 18 or 0, 6
    local cols = d.vertical and 1 or n
    local rows = d.vertical and n or 1
    panel:SetSize(cols * d.width + (cols - 1) * d.spacing + 2 * pad,
        rows * d.height + (rows - 1) * d.spacing + 2 * pad + header)
    panel:SetScale(d.scale)
    panel:ClearAllPoints()
    panel:SetPoint(d.position.point, UIParent, d.position.relative, d.position.x, d.position.y)
    panel.bg:SetColorTexture(0.07, 0.06, 0.05, d.opacity)
    panel.title:SetShown(d.title)
    for i, profile in ipairs(d.profiles) do
        local b = buttons[i] or newButton(panel)
        buttons[i] = b
        b.profile = profile
        b:ClearAllPoints()
        local x = d.vertical and 0 or (i - 1) * (d.width + d.spacing)
        local y = d.vertical and (i - 1) * (d.height + d.spacing) or 0
        b:SetPoint("TOPLEFT", pad + x, -pad - header - y)
        b:SetSize(d.width, d.height)
        b.fill:ClearAllPoints()
        b.fill:SetPoint("TOPLEFT", d.border, -d.border)
        b.fill:SetPoint("BOTTOMRIGHT", -d.border, d.border)
        b.text:SetText(profile.label)
        b.text:SetWidth(d.width - 8)
        b.text:SetShown(not d.icons)
        b.icon:SetTexture(profile.icon)
        local size = math.min(d.width, d.height) - 2 * d.border - 4
        b.icon:SetSize(size, size)
        b.icon:SetShown(d.icons)
        b:Show()
    end
    for i = n + 1, #buttons do buttons[i]:Hide() end
    F.visibility()
end

function F.visibility()
    if InCombatLockdown() then return end
    local d, inside = F.db, IsInInstance()
    local conditions = {}
    if d.instance == "inside" and not inside or d.instance == "outside" and inside then
        conditions[1] = "hide"
    else
        if d.hideCombat then conditions[#conditions + 1] = "[combat] hide" end
        if d.hideNoPet then conditions[#conditions + 1] = "[nopet] hide" end
        conditions[#conditions + 1] = "show"
    end
    local driver = table.concat(conditions, "; ")
    if F.driver ~= driver then
        RegisterStateDriver(F.panel, "visibility", driver)
        F.driver = driver
    end
end

function F.paint(state)
    for i, profile in ipairs(F.db.profiles) do
        local b = buttons[i]
        local active = #F.differences(profile, state) == 0
        b.fill:SetColorTexture(F.rgb(active and profile.color or F.db.inactive))
        b.mark:SetShown(active)
        F.bind(b, profile, state)
    end
end
