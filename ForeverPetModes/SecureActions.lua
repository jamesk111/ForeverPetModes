local _, F = ...

-- Every line has its own guard. A binding retained during lockdown is inert.
local guard = " [@pet,exists,nodead,nocombat,nomod] "

function F.macro(profile, state)
    if state.reason then return nil, state.reason end
    local slot = state.slots[profile.stance]
    if not slot then return nil, "Put " .. profile.stance .. " on the pet bar." end
    local lines = { "/click" .. guard .. "PetActionButton" .. slot }
    local resolved = {}
    for _, rule in ipairs(profile.rules) do
        local spell = F.resolve(state, rule.id)
        if not spell then return nil, "Missing autocastable pet bar ability for spell ID " .. rule.id .. "." end
        if resolved[spell.id] ~= nil and resolved[spell.id] ~= rule.on then
            return nil, "Two rules request different settings for " .. spell.name .. "."
        end
        if resolved[spell.id] == nil then
            local command = rule.on and "/petautocaston" or "/petautocastoff"
            -- Only names returned by the live pet bar enter the macro.
            if spell.name == "" or spell.name:find("[%c%[%];|/]") then
                return nil, "Use the native pet bar for this ability."
            end
            lines[#lines + 1] = command .. guard .. spell.name
        end
        resolved[spell.id] = rule.on
    end
    local text = table.concat(lines, "\n")
    if #text > 255 then return nil, "Profile exceeds the 255-byte macro budget. Use fewer ability rules." end
    return text
end

function F.bind(button, profile, state)
    if InCombatLockdown() then return end
    local text, reason = F.macro(profile, state)
    button:SetAttribute("macrotext1", text)
    button:SetAttribute("type1", text and "macro" or nil)
    button.problem = reason
end

function F.prepareButton(button)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("useOnKeyDown", false)
    button:SetScript("PreClick", function(self)
        if not InCombatLockdown() then F.bind(self, self.profile, F.readPet()) end
    end)
    button:SetScript("PostClick", function(self)
        if InCombatLockdown() then F.say("Use the Blizzard pet bar in combat.") return end
        if IsModifierKeyDown() then F.say("Click the profile without a modifier key.") return end
        if self.problem then F.say(self.problem) return end
        F.clickSerial = (F.clickSerial or 0) + 1
        local serial, profile = F.clickSerial, self.profile
        C_Timer.After(0.4, function()
            if serial ~= F.clickSerial then return end
            local missing = F.differences(profile, F.refresh())
            if #missing > 0 then
                F.say(table.concat(missing, " "))
            else
                if F.db.confirm then F.say(profile.label .. " active.") end
                if F.db.sound then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
            end
        end)
    end)
end
