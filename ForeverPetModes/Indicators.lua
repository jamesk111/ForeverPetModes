local _, F = ...
local metrics = F.panelMetrics

function F.addPetStatusLines(tip, state, rows)
    local names = {}
    for _, profile in ipairs(F.db.profiles) do
        if F.matchesProfile(profile, state) then names[#names + 1] = profile.label end
    end
    local mode = #names > 0 and table.concat(names, ", ") or (state.stance and "Custom" or "Unknown")
    tip:AddLine(mode .. "  ·  " .. (state.stance or "Unknown stance"), 1, 1, 1, true)
    if F.db.showHappiness and state.happiness then
        local mood = state.happiness
        tip:AddLine("|A:" .. mood.atlas .. ":16:16|a Happiness: " .. mood.label, 1, 1, 1)
    end
    for _, row in ipairs(rows) do
        local value = row.spell and (row.spell.on and "ON" or "OFF") or "Unavailable"
        tip:AddLine(row.name .. " " .. value, 1, 1, 1)
    end
end

local function showPetDetails(icon)
    local state, pet = icon.state, F.readPetDetails()
    local tip = GameTooltip
    tip:SetOwner(icon, "ANCHOR_TOP")
    tip:SetText(pet.name or "Pet details")
    local identity = {}
    if pet.level and pet.level > 0 then identity[#identity + 1] = "Level " .. pet.level end
    if pet.family then identity[#identity + 1] = pet.family end
    if #identity > 0 then tip:AddLine(table.concat(identity, "  ·  "), 0.85, 0.8, 0.68) end
    if pet.health and pet.maxHealth and pet.maxHealth > 0 then
        tip:AddLine("Health: " .. pet.health .. " / " .. pet.maxHealth, 1, 1, 1)
    end
    if pet.power and pet.maxPower and pet.maxPower > 0 then
        tip:AddLine(pet.resource .. ": " .. pet.power .. " / " .. pet.maxPower, 1, 1, 1)
    end
    if icon.xp:IsShown() then
        tip:AddLine("Experience: " .. icon.currentXP .. " / " .. icon.nextXP, 0.83, 0.72, 1)
    end
    if state.reason then tip:AddLine(state.reason, 1, 0.82, 0.4)
    else F.addPetStatusLines(tip, state, F.abilityRows(state, F.db.profiles, F.db.pinnedAbilities)) end
    if pet.loyalty then tip:AddLine("Loyalty: " .. pet.loyalty, 1, 1, 1) end
    if pet.diet then tip:AddLine("Diet: " .. pet.diet, 1, 1, 1, true) end
    tip:Show()
end

local function showAbility(chip)
    local row = chip.ability
    GameTooltip:SetOwner(chip, "ANCHOR_TOP")
    GameTooltip:SetText(row.name)
    local value = "Unavailable on this pet bar"
    if row.spell then value = "Autocast " .. (row.spell.on and "ON" or "OFF") end
    GameTooltip:AddLine(value, 1, 1, 1)
    for _, profile in ipairs(F.db.profiles) do
        local rules = row.rules[profile]
        local target = "Leave alone"
        if rules then target = rules[1].on and "Turn on" or "Turn off" end
        for _, rule in ipairs(rules or {}) do
            if rule.on ~= rules[1].on then target = "Conflicting rules" end
        end
        local active = chip.matches[profile] and " (active)" or ""
        GameTooltip:AddLine(profile.label .. active .. ": " .. target, 0.92, 0.86, 0.71)
    end
    GameTooltip:Show()
end

local function makeChip(footer)
    local chip = CreateFrame("Frame", nil, footer)
    chip:SetMouseMotionEnabled(true)
    chip.surface = chip:CreateTexture(nil, "BACKGROUND")
    chip.surface:SetAllPoints()
    chip.icon = chip:CreateTexture(nil, "ARTWORK")
    chip.icon:SetSize(14, 14)
    chip.icon:SetPoint("LEFT", 2, 0)
    chip.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    chip.value = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chip.value:SetPoint("RIGHT", -4, 0)
    chip.value:SetFontHeight(10)
    chip.text = chip:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    chip.text:SetPoint("LEFT", 19, 0)
    chip.text:SetWordWrap(false)
    chip.text:SetJustifyH("LEFT")
    chip:SetScript("OnEnter", showAbility)
    chip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return chip
end

local function layoutSkills(panel, rows, matches)
    local mode = F.db.skillDisplay
    local showName, showIcon = mode ~= "Icon only", mode ~= "Name only"
    local labelStart = showIcon and 19 or 4
    local valueWidth = 18 -- Reserve room for OFF so toggling autocast keeps the grid stable.
    for i, row in ipairs(rows) do
        local chip = panel.chips[i] or makeChip(panel.abilities)
        panel.chips[i] = chip
        chip.ability, chip.matches = row, matches
        local value = row.spell and (row.spell.on and "ON" or "OFF") or "Unavailable"
        chip.value:SetText(value)
        chip.text:SetText(row.name)
        chip.text:SetShown(showName)
        chip.icon:SetShown(showIcon)
        chip.icon:SetTexture(row.spell and row.spell.icon or (row.id and C_Spell.GetSpellTexture(row.id)) or 134400)
        chip.icon:SetDesaturated(value ~= "ON")
        if value == "ON" then
            chip.surface:SetColorTexture(0.12, 0.20, 0.15, 0.90)
            chip.value:SetTextColor(0.59, 0.91, 0.67)
        elseif value == "OFF" then
            chip.surface:SetColorTexture(0.23, 0.18, 0.13, 0.90)
            chip.value:SetTextColor(1, 0.78, 0.54)
        else
            chip.surface:SetColorTexture(0.16, 0.16, 0.16, 0.90)
            chip.value:SetTextColor(0.78, 0.78, 0.78)
        end
        chip.valueWidth = math.ceil(chip.value:GetUnboundedStringWidth())
        valueWidth = math.max(valueWidth, chip.valueWidth)
    end
    for i = #rows + 1, #panel.chips do panel.chips[i]:Hide() end
    if #rows == 0 then return 0 end

    local minimum = labelStart + valueWidth + (showName and 36 or 4)
    local gap = metrics.gap
    local columns = math.max(1, math.min(#rows, math.floor((panel.contentWidth + gap) / (minimum + gap))))
    local width = (panel.contentWidth - (columns - 1) * gap) / columns
    -- Give short rows some breathing room without stretching a lone badge across several profiles.
    width = math.min(width, showName and 148 or math.max(60, minimum))
    for i = 1, #rows do
        local chip = panel.chips[i]
        local x = ((i - 1) % columns) * (width + gap)
        local y = math.floor((i - 1) / columns) * (metrics.chipHeight + gap)
        if showName then
            if chip.labelStart ~= labelStart then
                chip.text:ClearAllPoints()
                chip.text:SetPoint("LEFT", labelStart, 0)
                chip.labelStart = labelStart
            end
            chip.text:SetWidth(math.max(1, width - labelStart - chip.valueWidth - 7))
        end
        if chip.x ~= x or chip.y ~= y or chip.width ~= width then
            chip:ClearAllPoints()
            chip:SetPoint("TOPLEFT", x, -y)
            chip:SetSize(width, metrics.chipHeight)
            chip.x, chip.y, chip.width = x, y, width
        end
        chip:Show()
        if GameTooltip:IsOwned(chip) then showAbility(chip) end
    end
    return math.ceil(#rows / columns) * (metrics.chipHeight + gap) - gap
end

local function badgeLabel(badge, top, fontHeight)
    local text = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", metrics.moodSize + metrics.gap, -top)
    text:SetSize(metrics.petNameWidth, metrics.moodSize / 2)
    text:SetFontHeight(fontHeight)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(false)
    text:SetMaxLines(1)
    return text
end

function F.sizePetBadge(badge, width)
    local textWidth = width - metrics.moodSize - metrics.gap
    badge:SetSize(width, metrics.moodSize)
    badge.petName:SetWidth(textWidth)
    badge.health:SetSize(textWidth - metrics.levelWidth - metrics.gap, 5)
    badge.xp:SetSize(textWidth - metrics.levelWidth - metrics.gap, 3)
end

function F.createIndicators(panel)
    panel.footer = CreateFrame("Frame", nil, panel)
    panel.abilities = CreateFrame("Frame", nil, panel.footer)
    panel.chips = {}
    panel.status = panel.footer:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.status:SetJustifyH("LEFT")
    panel.status:SetPoint("TOPLEFT", 0, 0)
    panel.stanceRule = panel.footer:CreateTexture(nil, "BACKGROUND")
    panel.stanceRule:SetHeight(1)
    panel.stanceRule:SetColorTexture(0.59, 0.53, 0.40, 0.45)
    local icon = CreateFrame("Frame", nil, panel)
    icon:SetMouseMotionEnabled(true)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("LEFT")
    icon.texture:SetSize(metrics.moodSize, metrics.moodSize)
    icon.info = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    icon.info:SetPoint("CENTER", icon.texture, "CENTER")
    icon.info:SetText("i")
    icon.petName = badgeLabel(icon, 0, 12)
    icon.petName:SetTextColor(1, 0.96, 0.85)
    icon.petLevel = badgeLabel(icon, metrics.moodSize / 2, 10)
    icon.petLevel:SetWidth(metrics.levelWidth)
    icon.petLevel:SetTextColor(0.85, 0.8, 0.68)
    icon.health = CreateFrame("StatusBar", nil, icon)
    icon.health:SetPoint("LEFT", icon, "TOPLEFT", metrics.moodSize + metrics.levelWidth + 2 * metrics.gap, -metrics.moodSize * 0.75 + 2)
    icon.health:EnableMouse(false)
    icon.health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    icon.health:GetStatusBarTexture():SetDrawLayer("ARTWORK")
    icon.health:SetStatusBarColor(0.43, 0.79, 0.53)
    local track = icon.health:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0.22, 0.24, 0.22)
    icon.xp = CreateFrame("StatusBar", nil, icon)
    icon.xp:SetPoint("TOPLEFT", icon.health, "BOTTOMLEFT", 0, -1)
    icon.xp:EnableMouse(false)
    icon.xp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    icon.xp:GetStatusBarTexture():SetDrawLayer("ARTWORK")
    icon.xp:SetStatusBarColor(0.69, 0.49, 0.90)
    local xpTrack = icon.xp:CreateTexture(nil, "BACKGROUND")
    xpTrack:SetAllPoints()
    xpTrack:SetColorTexture(0.24, 0.20, 0.28)
    icon.xp:Hide()
    icon:SetScript("OnEnter", showPetDetails)
    local function hideTooltip(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end
    icon:SetScript("OnLeave", hideTooltip)
    icon:SetScript("OnHide", hideTooltip)
    panel.moodIcon = icon
end

function F.paintIndicators(panel, state, matches)
    panel.statusMatches = matches
    local icon = panel.moodIcon
    local mood = F.db.showHappiness and state.happiness or nil
    if mood and icon.mood ~= mood then icon.texture:SetAtlas(mood.atlas) end
    icon.mood = mood
    icon.state = state
    icon.texture:SetShown(mood ~= nil)
    icon.info:SetShown(mood == nil)
    local showDetails = F.db.showHappiness and not F.db.petControlsCollapsed
    icon:SetShown(showDetails)
    if showDetails then
        local name, level = F.readPetIdentity()
        icon.petName:SetText(name or "")
        icon.petLevel:SetText(level and ("Lv. " .. level) or "")
        -- WoW can render restricted health directly in a StatusBar.
        -- Only the tooltip needs readable numbers for formatting.
        local exists = UnitExists("pet")
        local xp, needed
        if not issecretvalue(exists) and exists and GetPetExperience then xp, needed = GetPetExperience() end
        local hasXP = not issecretvalue(xp) and not issecretvalue(needed) and type(xp) == "number"
            and type(needed) == "number" and needed > 0
        icon.xp:SetShown(hasXP)
        if hasXP then
            icon.currentXP, icon.nextXP = xp, needed
            icon.xp:SetMinMaxValues(0, needed)
            icon.xp:SetValue(xp)
        end
        if issecretvalue(exists) or exists then
            icon.health:SetMinMaxValues(0, 1)
            icon.health:SetValue(UnitHealthPercent("pet", false))
            icon.health:Show()
        else
            icon.health:Hide()
        end
    end
    if showDetails and GameTooltip:IsOwned(icon) then showPetDetails(icon) end
    F.layoutStatus(panel, state, matches)
end

function F.layoutStatus(panel, state, matches)
    panel.status:SetWidth(panel.contentWidth)
    local stance = state.stance or "Unknown"
    local art = _G["PET_" .. stance:upper() .. "_TEXTURE"]
    local prefix = art and ("|T" .. art .. ":15:15:0:0|t  ") or ""
    panel.status:SetText(state.reason or (prefix .. "|cffc6bcaaStance:|r |cffffefd4" .. stance .. "|r"))
    local ruleStart = math.ceil(panel.status:GetUnboundedStringWidth()) + 7
    panel.stanceRule:SetShown(not state.reason and panel.contentWidth - ruleStart >= 12)
    if not state.reason and panel.contentWidth - ruleStart >= 12 then
        panel.stanceRule:ClearAllPoints()
        panel.stanceRule:SetPoint("LEFT", panel.status, "LEFT", ruleStart, 0)
        panel.stanceRule:SetWidth(panel.contentWidth - ruleStart)
    end
    local textHeight = math.ceil(panel.status:GetStringHeight())
    local rows = state.reason and {} or F.indicatorRows(state)
    local abilityHeight = layoutSkills(panel, rows, matches)
    local contentHeight = textHeight + (abilityHeight > 0 and metrics.gap + abilityHeight or 0)
    local height = math.max(contentHeight, panel.petColumnBottom - panel.buttonHeight,
        F.db.minPanelHeight - panel.buttonHeight - metrics.gripSize)
    -- Spend spare height on the two gaps before adding space below the last line.
    local inset = math.min(metrics.padding, math.floor((height - contentHeight) / 2))
    if panel.statusInset ~= inset then
        panel.status:ClearAllPoints()
        panel.status:SetPoint("TOPLEFT", 0, -inset)
        panel.abilities:ClearAllPoints()
        panel.abilities:SetPoint("TOPLEFT", panel.status, "BOTTOMLEFT", 0, -(metrics.gap + inset))
        panel.statusInset = inset
    end
    panel.abilities:SetSize(panel.contentWidth, math.max(1, abilityHeight))
    panel.footer:SetHeight(height)
    if not InCombatLockdown() and panel.measuredHeight ~= height then
        panel:SetHeight(panel.buttonHeight + height + metrics.gripSize)
        panel.measuredHeight = height
    end
end
