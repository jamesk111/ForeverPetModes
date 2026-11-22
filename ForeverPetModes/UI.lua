local _, F = ...
local buttons = {}

local function label(parent, font)
    return parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
end

local function showTarget(b, state)
    GameTooltip:SetOwner(b, "ANCHOR_TOP")
    GameTooltip:SetText(b.profile.label)
    GameTooltip:AddLine("Click to apply", 1, 0.82, 0.4)
    GameTooltip:AddLine("Stance: " .. b.profile.stance, 1, 1, 1)
    for _, rule in ipairs(b.profile.rules) do
        local spell = F.resolve(state, rule.id)
        local name = spell and spell.name or F.abilityName(rule.id) or ("Spell " .. rule.id)
        GameTooltip:AddLine(name .. " autocast: " .. (rule.on and "ON" or "OFF"), 1, 1, 1)
    end
    if InCombatLockdown() then
        GameTooltip:AddLine("Available after combat.", 1, 0.8, 0.5)
    elseif b.problem then
        GameTooltip:AddLine(b.problem, 1, 0.8, 0.5, true)
    elseif F.failedProfile == b.profile then
        for _, difference in ipairs(F.differences(b.profile, state)) do
            GameTooltip:AddLine(difference, 1, 0.8, 0.5, true)
        end
    end
    GameTooltip:Show()
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
    b:SetScript("OnEnter", function(self) showTarget(self, F.readPet()) end)
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
    panel.title = label(panel, "GameFontNormalSmall")
    panel.title:SetPoint("TOP", 0, -5)
    panel.title:SetText("Forever Pet Modes")
    panel.status = label(panel, "GameFontHighlightSmall")
    panel.status:SetJustifyH("LEFT")
    panel.status:SetJustifyV("TOP")
    panel.status:SetWordWrap(true)
    panel.bg:SetPoint("TOPLEFT", panel, "TOPLEFT")
    panel.bg:SetPoint("BOTTOMRIGHT", panel.status, "BOTTOMRIGHT", 6, -6)
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
    local barWidth = cols * d.width + (cols - 1) * d.spacing
    local width = math.max(150, barWidth) + 2 * pad
    panel.buttonHeight = rows * d.height + (rows - 1) * d.spacing + 2 * pad + header
    panel:SetWidth(width)
    panel.status:ClearAllPoints()
    panel.status:SetPoint("TOPLEFT", pad, -panel.buttonHeight)
    panel.status:SetWidth(width - 2 * pad)
    panel.measuredHeight = nil
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
        b:SetPoint("TOPLEFT", (width - barWidth) / 2 + x, -pad - header - y)
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

local function statusText(state)
    if state.reason then return state.reason end
    local lines = { "Stance: " .. (state.stance or "Unknown") }
    local seen = {}
    for _, spell in ipairs(state.abilities) do
        if not seen[spell.id] then
            local flag = spell.on and "|cff78df91ON|r" or "|cffffc080OFF|r"
            lines[#lines + 1] = spell.name .. "  " .. flag
            seen[spell.id] = true
        end
    end
    for _, p in ipairs(F.db.profiles) do
        for _, rule in ipairs(p.rules) do
            if not seen[rule.id] then
                if not F.resolve(state, rule.id) then
                    local name = F.abilityName(rule.id) or ("Spell " .. rule.id)
                    lines[#lines + 1] = name .. "  |cffb0b0b0Unavailable|r"
                end
                seen[rule.id] = true
            end
        end
    end
    return table.concat(lines, "\n")
end

function F.paint(state)
    for i, profile in ipairs(F.db.profiles) do
        local b = buttons[i]
        local active = #F.differences(profile, state) == 0
        if active and F.failedProfile == profile then F.failedProfile = nil end
        active = active and (not F.pending or F.pending == profile)
        b.fill:SetColorTexture(F.rgb(active and profile.color or F.db.inactive))
        b.mark:SetShown(active)
        F.bind(b, profile, state)
    end
    local panel = F.panel
    local text = statusText(state)
    if text ~= panel.status:GetText() then panel.status:SetText(text) end
    if not InCombatLockdown() then
        local height = panel.buttonHeight + math.ceil(panel.status:GetStringHeight()) + 6
        if height ~= panel.measuredHeight then
            panel:SetHeight(height)
            panel.measuredHeight = height
        end
    end
end
