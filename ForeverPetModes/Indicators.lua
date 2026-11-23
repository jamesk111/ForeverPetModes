local _, F = ...

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
    chip.text = chip:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    chip.text:SetPoint("LEFT", 0, 0)
    chip.text:SetWordWrap(false)
    chip.text:SetJustifyH("LEFT")
    chip:SetScript("OnEnter", showAbility)
    chip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return chip
end

function F.createIndicators(panel)
    panel.footer = CreateFrame("Frame", nil, panel)
    panel.chips = {}
    panel.status = panel.footer:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    panel.status:SetPoint("TOPLEFT")
    panel.status:SetJustifyH("LEFT")
end

function F.paintIndicators(panel, state, matches)
    panel.status:SetText(state.reason or ("Stance: " .. (state.stance or "Unknown")))
    local x, y = 0, math.ceil(panel.status:GetStringHeight()) + 3
    local rows = state.reason and {} or F.abilityRows(state, F.db.profiles)
    for i, row in ipairs(rows) do
        local chip = panel.chips[i] or makeChip(panel.footer)
        panel.chips[i] = chip
        chip.ability, chip.matches = row, matches
        local value = "|cffb5b5b5Unavailable|r"
        if row.spell then value = row.spell.on and "|cff87e49cON|r" or "|cffffc586OFF|r" end
        chip.text:SetText(row.name .. " " .. value)
        local width = math.min(panel.contentWidth, math.ceil(chip.text:GetUnboundedStringWidth()) + 2)
        if x > 0 and x + width > panel.contentWidth then x, y = 0, y + 17 end
        if chip.x ~= x or chip.y ~= y or chip.width ~= width then
            chip:ClearAllPoints()
            chip:SetPoint("TOPLEFT", x, -y)
            chip:SetSize(width, 16)
            chip.text:SetWidth(width)
            chip.x, chip.y, chip.width = x, y, width
        end
        chip:Show()
        if GameTooltip:IsOwned(chip) then showAbility(chip) end
        x = x + width + 10
    end
    for i = #rows + 1, #panel.chips do panel.chips[i]:Hide() end
    local height = y + (#rows > 0 and 16 or 0)
    panel.footer:SetHeight(height)
    if not InCombatLockdown() and panel.measuredHeight ~= height then
        panel:SetHeight(panel.buttonHeight + height + 6)
        panel.measuredHeight = height
    end
end
