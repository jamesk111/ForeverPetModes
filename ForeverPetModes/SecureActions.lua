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
    button:SetScript("PreClick", function(self)
        if not InCombatLockdown() then F.bind(self, self.profile, F.readPet()) end
    end)
    button:SetScript("PostClick", function(self)
        F.clickSerial = (F.clickSerial or 0) + 1
        local serial, profile = F.clickSerial, self.profile
        F.pending, F.failedProfile, F.confirmedProfile = nil, nil, nil

        local function finish(message, state)
            F.pending, F.feedback = nil, message
            F.paint(state)
            if message then
                C_Timer.After(4, function()
                    if serial ~= F.clickSerial then return end
                    F.feedback, F.failedProfile, F.confirmedProfile = nil, nil, nil
                    F.refresh()
                end)
            end
        end

        local state = F.readPet()
        if InCombatLockdown() then finish("Use the pet bar in combat.", state) return end
        if IsModifierKeyDown() then finish("Click without a modifier key.", state) return end
        if self.problem then finish(self.problem, state) return end

        -- The stance and autocast updates can arrive on different frames.
        -- Only sample the bar here. Never replay a pet command from a timer.
        F.pending = profile
        F.feedback = "Switching to " .. profile.label .. "..."
        local delays = { 0.15, 0.35, 0.70, 1.0 }
        local function verify(index, snapshot)
            if serial ~= F.clickSerial then return end
            if #F.differences(profile, snapshot) == 0 then
                F.confirmedProfile = profile
                finish(F.db.confirm and (profile.label .. " active") or nil, snapshot)
                if F.db.sound then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
            elseif delays[index] then
                F.paint(snapshot)
                C_Timer.After(delays[index], function() verify(index + 1, F.readPet()) end)
            else
                F.failedProfile = profile
                finish(profile.label .. " incomplete. Check the pet bar.", snapshot)
            end
        end
        verify(1, state)
    end)
end
