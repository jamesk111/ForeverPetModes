local _, F = ...
local capture

local function target(button)
    if button.personalBinding and GetBindingKey(button.personalBinding) then return button.personalBinding end
    local state = button.commandID and F.readPet()
    local slot = state and state.commandSlots and state.commandSlots[button.commandID]
    if slot then
        local native = "BONUSACTIONBUTTON" .. slot
        if GetBindingKey(native) or not GetBindingKey(button.binding) then
            return native, "Pet bar slot " .. slot
        end
    end
    return button.binding
end

local function current(button, action, profile)
    return not InCombatLockdown() and F.classVisible and button:IsVisible()
        and button.profile == profile and target(button) == action
end

local function displayName(action)
    return _G["BINDING_NAME_" .. action] or action
end

function F.bindingHint(button)
    local key = GetBindingKey(button.personalBinding or button.binding)
    if key and not button.commandID then GameTooltip:AddLine("Shortcut: " .. GetBindingText(key), 1, 1, 1) end
    GameTooltip:AddLine(InCombatLockdown() and "Edit shortcuts after combat." or "Right-click for keybindings.", 0.78, 0.75, 0.64)
end

function F.releaseRemovedProfileKeys(previous, updated)
    local retained, changed = {}, false
    for _, p in ipairs(updated.profiles) do retained[p.bindingID] = true end
    for _, p in ipairs(previous.profiles) do
        if p.bindingID and not retained[p.bindingID] then
            local action = "CLICK ForeverPetModesProfile" .. p.bindingID .. ":LeftButton"
            for _, key in ipairs({GetBindingKey(action)}) do
                if GetBindingAction(key) == action and SetBinding(key, nil) then changed = true end
            end
        end
    end
    if changed then SaveBindings(GetCurrentBindingSet()) end
end

local function buildCapture()
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(320, 116)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    frame:SetBackdropColor(0.08, 0.09, 0.08, 0.98)
    frame:SetBackdropBorderColor(0.50, 0.46, 0.35)
    frame:EnableMouse(true)
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(false)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", 0, -12)
    frame.prompt = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.prompt:SetSize(292, 40)
    frame.prompt:SetPoint("TOP", 0, -31)
    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancel:SetSize(90, 24)
    cancel:SetPoint("BOTTOM", 50, 10)
    cancel:SetText(CANCEL or "Cancel")
    cancel:SetScript("OnClick", function() frame:Hide() end)
    frame.replace = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.replace:SetSize(90, 24)
    frame.replace:SetPoint("BOTTOM", -50, 10)
    frame.replace:SetText("Replace")

    local function assign(key, confirmed)
        if not current(frame.owner, frame.action, frame.profile) then frame:Hide() return end
        local owner = GetBindingAction(key)
        if owner == frame.action then frame:Hide() return end
        if owner and owner ~= "" and owner ~= confirmed then
            frame.key, frame.conflict = key, owner
            frame.prompt:SetText(GetBindingText(key) .. " is bound to " .. displayName(owner) .. ". Replace it?")
            frame.replace:Show()
            return
        end
        local _, second = GetBindingKey(frame.action)
        if second then frame.prompt:SetText("Unbind a shortcut first. Both slots are in use.") return end
        if SetBinding(key, frame.action) then
            SaveBindings(GetCurrentBindingSet())
            frame:Hide()
            F.refresh()
        else frame.prompt:SetText("WoW could not bind that key. Choose another.") end
    end
    frame.replace:SetScript("OnClick", function()
        if frame.key then assign(frame.key, frame.conflict) end
    end)
    frame:SetScript("OnKeyDown", function(self, input)
        if input == "ESCAPE" or InCombatLockdown() then self:Hide() return end
        local key = GetConvertedKeyOrButton(input)
        if not key or IsKeyPressIgnoredForBinding(key) then return end
        self.replace:Hide()
        self.key, self.conflict = nil, nil
        if self.profile and IsModifierKeyDown() then
            self.prompt:SetText("Choose a key without Ctrl, Alt or Shift for a profile.")
            return
        end
        assign(CreateKeyChordStringUsingMetaKeyState(key))
    end)
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:SetScript("OnEvent", function(self) self:Hide() end)
    frame:SetScript("OnHide", function(self)
        self.owner, self.profile, self.key, self.conflict = nil, nil, nil, nil
    end)
    return frame
end

function F.attachBindingMenu(button)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:HookScript("OnMouseUp", function(self, mouse)
        if mouse ~= "RightButton" or InCombatLockdown() then return end
        local action, source = target(self)
        local profile = self.profile
        local label = profile and profile.label or self.caption
        if not action or not label then return end
        MenuUtil.CreateContextMenu(self, function(_, menu)
            menu:CreateTitle(label)
            if source then menu:CreateTitle(source) end
            local keys = {GetBindingKey(action)}
            local bind = menu:CreateButton("Bind a key…", function()
                if not current(self, action, profile) then return end
                capture = capture or buildCapture()
                capture.owner, capture.action, capture.profile = self, action, profile
                capture.key, capture.conflict = nil, nil
                capture.title:SetText("Bind " .. label)
                capture.prompt:SetText(profile and "Press an unmodified key. Esc cancels." or "Press a key or key combination. Esc cancels.")
                capture.replace:Hide()
                capture:Show()
            end)
            bind:SetEnabled(#keys < 2)
            for _, key in ipairs(keys) do
                menu:CreateButton("Unbind " .. GetBindingText(key), function()
                    if current(self, action, profile) and GetBindingAction(key) == action and SetBinding(key, nil) then
                        SaveBindings(GetCurrentBindingSet())
                        F.refresh()
                    end
                end)
            end
        end)
    end)
end
