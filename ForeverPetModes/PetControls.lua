local _, F = ...
local commands = {
    { id="attack", label="Attack", icon="Interface\\Icons\\Ability_GhoulFrenzy",
      macro="/petattack [@target,harm,nodead,pet]", help="Send your pet to attack your hostile target." },
    { id="follow", label="Follow", icon="Interface\\Icons\\Ability_Tracking",
      macro="/petfollow [@pet,exists,nodead]", help="Call your pet to your side." },
    { id="stay", label="Stay", icon="Interface\\Icons\\Spell_Nature_TimeStop",
      macro="/petstay [@pet,exists,nodead]", help="Tell your pet to stay at its current position." },
}
local primaryCare = {
    { id=982, label="Revive", condition="[@pet,exists,dead]" },
    { id=136, label="Mend", condition="[@pet,exists,nodead]" },
    { id=883, label="Call", condition="[nopet]" },
}
local care = {
    { name="PetCare", label="Pet care", column=1 },
    { name="Feed", label="Feed", column=2, id=6991, condition="[@pet,exists,nodead,nocombat]",
      help="Choose food from your bags below the panel." },
    { name="Revive", label="Revive", column=2, id=982, condition="[nopet]",
      help="Revive your pet if its body is no longer present." },
}

BINDING_HEADER_FOREVERPETMODES = "Forever Pet Modes"
local function bindingName(buttonName)
    return "CLICK " .. buttonName .. ":LeftButton"
end
for _, command in ipairs(commands) do
    _G["BINDING_NAME_" .. bindingName("ForeverPetModes" .. command.label)] = command.label
end
for _, action in ipairs(care) do
    _G["BINDING_NAME_" .. bindingName("ForeverPetModes" .. action.name)] = action.label
end
for i = 1, 4 do
    _G["BINDING_NAME_" .. bindingName("ForeverPetModesFavorite" .. i)] = "Profile favorite " .. i
end

local function commandTooltip(b)
    GameTooltip:SetOwner(b, "ANCHOR_TOP")
    GameTooltip:SetText(b.bindingText and (b.caption .. " (" .. b.bindingText .. ")") or b.caption)
    GameTooltip:AddLine(b.help, 1, 1, 1, true)
    F.bindingHint(b)
    GameTooltip:Show()
end

function F.createPetControls(panel, actionButton)
    panel.commands, panel.care = {}, {}
    for i, command in ipairs(commands) do
        local name = "ForeverPetModes" .. command.label
        local b = actionButton(panel, "SecureActionButtonTemplate", name)
        b.caption, b.help, b.binding = command.label, command.help, bindingName(name)
        b.text:SetText(command.label)
        b.icon:SetTexture(command.icon)
        b.hotkey = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
        b.hotkey:SetWordWrap(false)
        b.hotkey:SetJustifyH("RIGHT")
        b.hotkey:SetTextColor(0.90, 0.85, 0.72)
        b.edge:SetColorTexture(0.36, 0.35, 0.31)
        b.fill:SetColorTexture(0.17, 0.18, 0.17)
        b:RegisterForClicks("LeftButtonUp")
        b:SetAttribute("useOnKeyDown", false)
        b:SetAttribute("*macrotext1", command.macro)
        b:SetScript("OnEnter", commandTooltip)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b.commandID = command.id
        F.attachBindingMenu(b)
        panel.commands[i] = b
    end
    panel.careRow = CreateFrame("Frame", nil, panel)
    for i, spell in ipairs(care) do
        local name = "ForeverPetModes" .. spell.name
        local b = actionButton(panel.careRow, "SecureActionButtonTemplate", name)
        b.binding, b.caption = bindingName(name), spell.label
        if i == 1 then
            b:SetScript("OnAttributeChanged", function(self, attribute, value)
                if attribute == "state-petcare" and value then
                    self.caption = value
                    self.text:SetText(value)
                end
            end)
        elseif spell.name == "Feed" then
            b:SetScript("PostClick", F.toggleFoodPicker)
        end
        b.icon:Hide()
        b.text:SetText(spell.label)
        b.edge:SetColorTexture(0.27, 0.28, 0.25)
        b.fill:SetColorTexture(0.12, 0.14, 0.13)
        b.text:SetTextColor(0.89, 0.88, 0.81)
        b:RegisterForClicks("LeftButtonUp")
        b:SetAttribute("useOnKeyDown", false)
        F.attachBindingMenu(b)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.caption)
            if spell.help then GameTooltip:AddLine(spell.help, 1, 1, 1, true) end
            F.bindingHint(self)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        panel.care[i] = b
    end
end

local function learnedName(id)
    local name = F.abilityName(id)
    if name and (C_SpellBook.IsSpellKnown(id) or C_SpellBook.FindSpellBookSlotForSpell(name)) then
        return name
    end
end

local function setDriver(button, attribute, condition)
    if button[attribute] ~= condition then
        RegisterStateDriver(button, attribute, condition)
        button[attribute] = condition
    end
end

function F.prepareCare(panel, enabled)
    local _, class = UnitClass("player")
    enabled = enabled and class == "HUNTER"
    local any = false
    panel.absentPetCare = false
    panel.callSpell, panel.reviveSpell = nil, nil
    for i, action in ipairs(care) do
        local button = panel.care[i]
        local casts, labels, visibility = {}, {}, {}
        for _, spell in ipairs(i == 1 and primaryCare or {action}) do
            local name = enabled and learnedName(spell.id)
            if name then
                casts[#casts + 1] = spell.condition .. " " .. name
                labels[#labels + 1] = spell.condition .. " " .. spell.label
                visibility[#visibility + 1] = spell.condition .. " show"
                if spell.condition == "[nopet]" then panel.absentPetCare = true end
                if spell.id == 883 then panel.callSpell = name end
                if spell.id == 982 then panel.reviveSpell = name end
            end
        end
        local present = #casts > 0
        local macro = present and action.name ~= "Feed" and ("/cast " .. table.concat(casts, "; ")) or nil
        if macro ~= button.careMacro then
            button:SetAttribute("*macrotext1", macro)
            button:SetAttribute("*type1", present and "macro" or nil)
            button.careMacro = macro
        end
        if i == 1 then
            labels[#labels + 1] = "Pet care"
            setDriver(button, "petcare", table.concat(labels, "; "))
        end
        visibility[#visibility + 1] = "hide"
        setDriver(button, "visibility", table.concat(visibility, "; "))
        any = any or present
    end
    return any
end

function F.layoutPetCommands(panel, d, expanded, x, top, width, border, insetFill)
    if not (expanded and d.showRecall) then
        for _, b in ipairs(panel.commands) do b:Hide() end
        return
    end
    local gap = F.panelMetrics.gap
    local cell = (width - 2 * gap) / 3
    for i, b in ipairs(panel.commands) do
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", x + (i - 1) * (cell + gap), -top)
        b:SetSize(cell, d.height)
        insetFill(b, border)
        local iconSize = math.max(4, math.min(cell, d.height) - 2 * d.border - 4)
        b.icon:SetSize(iconSize, iconSize)
        b.icon:SetShown(d.icons)
        b.text:ClearAllPoints()
        local inset = math.max(1, math.min(3, border))
        local inside = d.height - 2 * inset
        local keyHeight = math.min(11, math.floor(inside * 0.44))
        local labelHeight = math.min(12, inside - keyHeight)
        -- Center the caption as far as the reserved hotkey line allows.
        local labelTop = math.max(inset + keyHeight, (d.height - labelHeight) / 2)
        b.text:SetPoint("TOP", 0, -labelTop)
        b.text:SetHeight(labelHeight)
        b.text:SetFontHeight(math.min(11, labelHeight))
        b.text:SetShown(not d.icons)
        b.hotkey:ClearAllPoints()
        b.hotkey:SetPoint("TOPRIGHT", -(inset + 1), -inset)
        b.hotkey:SetHeight(keyHeight)
        b.hotkey:SetWidth(math.max(1, cell - 4))
        b.hotkey:SetFontHeight(math.min(10, keyHeight))
        b:Show()
    end
end

function F.layoutCare(panel, shown, x, top, width, border, insetFill)
    local row, gap = panel.careRow, F.panelMetrics.gap
    row:SetShown(shown)
    if not shown then return end
    local height = F.panelMetrics.careHeight
    local half = (width - gap) / 2
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", x, -top)
    row:SetSize(width, height)
    for i, b in ipairs(panel.care) do
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", (care[i].column - 1) * (half + gap), 0)
        b:SetSize(half, height)
        insetFill(b, border)
    end
    return top + height
end

function F.paintPetCommands(panel, state)
    for i, command in ipairs(commands) do
        local b = panel.commands[i]
        local key = state.commandKeys and state.commandKeys[command.id]
        key = key or GetBindingKey(b.binding)
        local short = key and GetBindingText(key, true) or ""
        local full = key and GetBindingText(key) or nil
        if b.hotkey:GetText() ~= short or b.bindingText ~= full then
            b.bindingText = full
            b.hotkey:SetText(short)
            if GameTooltip:IsOwned(b) then commandTooltip(b) end
        end
    end
end
