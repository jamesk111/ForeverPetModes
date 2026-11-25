local _, F = ...

-- Every line has its own guard. A binding retained during lockdown is inert.
local guard = " [@pet,exists,nodead,nocombat,nomod] "

function F.macro(profile, state)
    if state.reason then return nil, state.reason end
    local slot = state.slots[profile.stance]
    if not slot then return nil, "Put " .. profile.stance .. " on the pet bar." end
    local name = "PetActionButton" .. slot
    local native = _G[name]
    local lines, needed = {}, {}
    if native and not native:IsForbidden() and native:IsObjectType("Button")
        and not native:HasAccessConstraints() and not native:HasAnyForbiddenAspects(Enum.ForbiddenAspect.ScriptedInput) then
        lines[1] = "/click" .. guard .. name
        if state.stance ~= profile.stance then needed[1] = lines[1] end
    elseif state.stance ~= profile.stance then
        return nil, "Select " .. profile.stance .. " on the native pet bar. Its stance button is unavailable for addon clicks."
    end
    local resolved = {}
    for _, rule in ipairs(profile.rules) do
        local spell = F.resolve(state, rule.id)
        if not spell then return nil, "Place " .. (F.abilityName(rule.id) or ("spell " .. rule.id)) .. " on the pet bar, or choose Leave alone in this profile." end
        if resolved[spell.id] ~= nil and resolved[spell.id] ~= rule.on then
            return nil, "Two rules request different settings for " .. spell.name .. ".", "rules"
        end
        if resolved[spell.id] == nil then
            local command = rule.on and "/petautocaston" or "/petautocastoff"
            -- Only names returned by the live pet bar enter the macro.
            if spell.name == "" or spell.name:find("[%c%[%];|/]") then
                return nil, "Use the native pet bar for " .. spell.name .. ".", "rules"
            end
            local line = command .. guard .. spell.name
            lines[#lines + 1] = line
            if rule.on ~= spell.on then needed[#needed + 1] = line end
        end
        resolved[spell.id] = rule.on
    end
    local text = table.concat(lines, "\n")
    if #text > 255 then text = table.concat(needed, "\n") end
    if text == "" then return nil end
    if #text > 255 then return nil, "This combination exceeds the click limit. Choose Leave alone for an ability.", "rules" end
    return text
end

function F.bind(button, profile, state)
    if InCombatLockdown() then return end
    local text, reason = F.macro(profile, state)
    if button.boundText ~= text then
        button:SetAttribute("macrotext1", text)
        button:SetAttribute("type1", text and "macro" or nil)
        button.boundText = text
    end
    button.problem = reason
end

function F.prepareButton(button)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("useOnKeyDown", false)
    button:SetScript("PreClick", function(self, mouse)
        if mouse == "RightButton" or InCombatLockdown() then return end
        if self.profile and F.classVisible then F.bind(self, self.profile, F.readPet())
        else
            self:SetAttribute("type1", nil)
            self.boundText = nil
        end
    end)
    button:SetScript("PostClick", function(self, mouse)
        if mouse == "RightButton" or not self.profile or not F.classVisible then return end
        F.clickSerial = (F.clickSerial or 0) + 1
        local serial, profile = F.clickSerial, self.profile
        F.pending, F.failedProfile = nil, nil
        local state = F.readPet()
        if InCombatLockdown() or IsModifierKeyDown() or self.problem then
            F.paint(state)
            return
        end

        -- Read delayed bar updates without replaying any pet action.
        F.pending = profile
        local delays = { 0.15, 0.35, 0.70, 1.0 }
        local function verify(index, snapshot)
            if serial ~= F.clickSerial then return end
            if #F.differences(profile, snapshot) == 0 then
                F.pending = nil
                if F.db.sound then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
            elseif delays[index] then
                C_Timer.After(delays[index], function() verify(index + 1, F.readPet()) end)
            else
                F.pending, F.failedProfile = nil, profile
            end
            F.paint(snapshot)
        end
        verify(1, state)
    end)
end
