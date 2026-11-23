local _, F = ...

local function position(button, angle)
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

local function create()
    local b = CreateFrame("Button", "ForeverPetModesMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    b:RegisterForClicks("LeftButtonUp")
    b:RegisterForDrag("LeftButton")

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(21, 21)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
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
        GameTooltip:SetText("Forever Pet Modes")
        GameTooltip:AddLine(InCombatLockdown() and "Settings available after combat." or "Click for settings.", 1, 1, 1)
        GameTooltip:AddLine("Drag around the minimap to move.", 0.85, 0.8, 0.68)
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
    b:SetScript("OnClick", function(self)
        if not self.wasDragged and not InCombatLockdown() then F.openSettings() end
    end)
    Minimap:HookScript("OnSizeChanged", function()
        if b:IsShown() then position(b, F.db.minimapAngle) end
    end)
    return b
end

function F.updateMinimap()
    if not Minimap or not F.classVisible or not F.db.showMinimap then
        if F.minimapButton then F.minimapButton:Hide() end
        return
    end
    if not F.minimapButton then F.minimapButton = create() end
    position(F.minimapButton, F.db.minimapAngle)
    F.minimapButton:Show()
end
