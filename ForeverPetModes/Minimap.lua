local _, F = ...
local launcherName = "ForeverPetModes"
local launcherIcon = "Interface\\Icons\\Ability_Hunter_BeastCall"
local iconLib, iconSettings, visible
local lastTooltip

local function tooltip(tip, standalone, state)
    lastTooltip = tip
    tip:SetText("Forever Pet Modes")
    state = state or F.readPet()
    if state.reason then
        tip:AddLine(state.reason, 1, 0.82, 0.4)
    else
        F.addPetStatusLines(tip, state, F.indicatorRows(state))
    end
    if InCombatLockdown() then
        tip:AddLine("Minimap controls available after combat.", 1, 1, 1)
    else
        local panel = F.db.panelHidden and " to show the panel." or " to hide the panel."
        local leftToggles = F.db.panelToggleClick == "Left-click"
        tip:AddLine("Left-click" .. (leftToggles and panel or " for settings."), 1, 1, 1)
        tip:AddLine("Right-click" .. (leftToggles and " for settings." or panel), 1, 1, 1)
    end
    if standalone then tip:AddLine("Drag around the minimap to move.", 0.85, 0.8, 0.68) end
end

function F.refreshMinimapTooltip(state)
    local b = F.minimapButton
    if b and lastTooltip and lastTooltip:IsShown() and lastTooltip:IsOwned(b) then
        tooltip(lastTooltip, b:GetParent() == Minimap, state)
        lastTooltip:Show()
    end
end

local function launcherClick(_, mouseButton)
    if InCombatLockdown() or not F.classVisible or not F.db.showMinimap then return end
    local panelButton = F.db.panelToggleClick == "Left-click" and "LeftButton" or "RightButton"
    if mouseButton == panelButton then
        F.togglePanel()
    elseif mouseButton == "LeftButton" or mouseButton == "RightButton" then
        F.openSettings()
    end
end

local function position(button, angle)
    if button:GetParent() ~= Minimap then return end
    local radians = math.rad(angle)
    local x, y = math.cos(radians), math.sin(radians)
    if GetMinimapShape and GetMinimapShape() == "SQUARE" then
        local edge = math.max(math.abs(x), math.abs(y))
        x, y = x / edge, y / edge
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x * (Minimap:GetWidth() / 2 + 3),
        y * (Minimap:GetHeight() / 2 + 3))
end

local function drag(button)
    if button:GetParent() ~= Minimap then return end
    local cx, cy = Minimap:GetCenter()
    if not cx or not cy then return end
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local x = (px / scale - cx) / (Minimap:GetWidth() / 2 + 3)
    local y = (py / scale - cy) / (Minimap:GetHeight() / 2 + 3)
    if x == 0 and y == 0 then return end
    local angle = math.deg(math.atan2(y, x)) % 360
    F.saveMinimapAngle(angle)
    position(button, angle)
end

local function createStandalone()
    local b = CreateFrame("Button", "ForeverPetModesMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER")
    icon:SetTexture(launcherIcon)
    local mask = b:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    icon:AddMaskTexture(mask)
    local rim = b:CreateTexture(nil, "OVERLAY")
    rim:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    rim:SetPoint("TOPLEFT")
    rim:SetSize(53, 53)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        tooltip(GameTooltip, self:GetParent() == Minimap)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseDown", function(self) self.wasDragged = false end)
    b:SetScript("OnDragStart", function(self)
        self.wasDragged = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", drag)
        drag(self)
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        drag(self)
    end)
    b:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    b:SetScript("OnClick", function(self, mouseButton)
        if not self.wasDragged then launcherClick(self, mouseButton) end
    end)
    Minimap:HookScript("OnSizeChanged", function()
        if b:IsShown() then position(b, F.db.minimapAngle) end
    end)
    return b
end

local function createLauncher()
    local broker = LibStub and LibStub("LibDataBroker-1.1", true)
    iconLib = broker and LibStub("LibDBIcon-1.0", true)
    if not iconLib then return createStandalone() end

    iconSettings = { minimapPos = F.db.minimapAngle, hide = false }
    local object = broker:NewDataObject(launcherName, {
        type = "launcher", label = "Forever Pet Modes", icon = launcherIcon,
        OnClick = launcherClick,
        OnTooltipShow = function(tip)
            tooltip(tip, F.minimapButton and F.minimapButton:GetParent() == Minimap)
        end,
    })
    iconLib:Register(launcherName, object, iconSettings)
    local button = iconLib:GetMinimapButton(launcherName)
    local start = button:GetScript("OnDragStart")
    if start then
        button:SetScript("OnDragStart", function(self, ...)
            if self:GetParent() == Minimap then start(self, ...) end
        end)
    end
    button:HookScript("OnDragStop", function(self)
        if self:GetParent() == Minimap then F.saveMinimapAngle(iconSettings.minimapPos) end
    end)
    return button
end

function F.updateMinimap()
    local show = Minimap ~= nil and F.classVisible and F.db.showMinimap
    local b = F.minimapButton
    if not b then
        if not show then return end
        b = createLauncher()
        F.minimapButton = b
    end

    if iconLib then
        local moved = iconSettings.minimapPos ~= F.db.minimapAngle
        iconSettings.minimapPos = F.db.minimapAngle
        iconSettings.hide = not show
        -- Show/Hide notify collectors. Repeating Show also resets the frame anchor.
        if visible ~= show then
            if show then iconLib:Show(launcherName) else iconLib:Hide(launcherName) end
        elseif show and moved and b:GetParent() == Minimap then
            iconLib:Show(launcherName)
        end
    else
        if show then position(b, F.db.minimapAngle) end
        if visible ~= show then b:SetShown(show) end
    end
    visible = show
end
