local _, F = ...
local buttons, favorites, ordinary = {}, {}, {}
local metrics = F.panelMetrics

local function horizontalAnchor(point)
    if point:find("LEFT") then return 0 end
    if point:find("RIGHT") then return 1 end
    return 0.5
end

local function label(parent, font)
    return parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
end

local function showTarget(b, state)
    GameTooltip:SetOwner(b, "ANCHOR_TOP")
    GameTooltip:SetText(b.profile.label)
    if b.unavailable then GameTooltip:AddLine(b.unavailable, 1, 0.78, 0.38, true)
    else GameTooltip:AddLine("Click to apply", 1, 0.82, 0.4) end
    GameTooltip:AddLine("Stance: " .. b.profile.stance, 1, 1, 1)
    for _, rule in ipairs(b.profile.rules) do
        local spell = F.resolve(state, rule.id)
        local name = spell and spell.name or F.abilityName(rule.id) or ("Spell " .. rule.id)
        GameTooltip:AddLine(name .. " autocast: " .. (rule.on and "ON" or "OFF"), 1, 1, 1)
    end
    if not b.unavailable and F.failedProfile == b.profile then
        for _, difference in ipairs(F.differences(b.profile, state)) do
            GameTooltip:AddLine(difference, 1, 0.8, 0.5, true)
        end
    end
    F.bindingHint(b)
    GameTooltip:Show()
end

local function actionButton(parent, template, name)
    local b = CreateFrame("Button", name, parent, template)
    b.edge = b:CreateTexture(nil, "BACKGROUND")
    b.edge:SetAllPoints()
    b.edge:SetColorTexture(0.44, 0.39, 0.30)
    b.fill = b:CreateTexture(nil, "BORDER")
    local light = b:CreateTexture(nil, "BORDER", nil, 1)
    light:SetPoint("TOPLEFT", b.fill, "TOPLEFT")
    light:SetPoint("TOPRIGHT", b.fill, "TOPRIGHT")
    light:SetHeight(1)
    light:SetColorTexture(1, 0.94, 0.80, 0.07)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("CENTER")
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.text = label(b, "GameFontHighlightSmall")
    b.text:SetPoint("CENTER")
    b.text:SetWordWrap(false)
    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 0.91, 0.72, 0.10)
    local press = b:CreateTexture(nil, "OVERLAY")
    press:SetColorTexture(0, 0, 0, 0.22)
    press:SetAllPoints()
    b:SetPushedTexture(press)
    return b
end

local function insetFill(button, border, left)
    button.fill:ClearAllPoints()
    button.fill:SetPoint("TOPLEFT", left or border, -border)
    button.fill:SetPoint("BOTTOMRIGHT", -border, border)
end

local function newButton(parent, name)
    local b = actionButton(parent, "InsecureActionButtonTemplate", name)
    b.mark = b:CreateTexture(nil, "OVERLAY")
    b.mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    b.mark:SetSize(17, 17)
    b.mark:SetPoint("LEFT", 2, 0)
    b.warning = label(b, "GameFontNormal")
    b.warning:SetPoint("TOPRIGHT", -3, -1)
    b.warning:SetText("|cffffc04d!|r")
    b:SetScript("OnEnter", function(self) showTarget(self, F.readPet()) end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    F.prepareButton(b)
    F.attachBindingMenu(b)
    return b
end

local function createDivider(panel)
    local b = CreateFrame("Button", nil, panel)
    b:SetWidth(metrics.dividerWidth)
    local function rail(startPoint, startOffset, endPoint, endOffset)
        local line = b:CreateTexture(nil, "BACKGROUND")
        line:SetWidth(1)
        line:SetPoint("TOP", b, startPoint, 0, startOffset)
        line:SetPoint("BOTTOM", b, endPoint, 0, endOffset)
        line:SetColorTexture(0.48, 0.44, 0.35, 0.42)
        return line
    end
    b.upperRail = rail("TOP", 0, "CENTER", 8)
    b.lowerRail = rail("CENTER", -8, "BOTTOM", 0)
    b.arrow = b:CreateTexture(nil, "OVERLAY")
    b.arrow:SetAtlas("common-icon-forwardarrow")
    b.arrow:SetSize(10, 10)
    b.arrow:SetPoint("CENTER")
    b.arrow:SetVertexColor(0.71, 0.69, 0.62)
    b:SetScript("OnClick", F.togglePetControls)
    b:SetScript("OnEnter", function(self)
        self.arrow:SetVertexColor(1, 0.91, 0.68)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(F.db.petControlsCollapsed and "Expand pet controls" or "Collapse pet controls")
        if InCombatLockdown() then GameTooltip:AddLine("Available after combat.", 1, 1, 1) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        self.arrow:SetVertexColor(0.71, 0.69, 0.62)
        GameTooltip:Hide()
    end)
    return b
end

local function createCallCard()
    local b = actionButton(UIParent, "SecureActionButtonTemplate")
    b:SetClampedToScreen(true)
    b:Hide()
    b.binding = "CLICK ForeverPetModesPetCare:LeftButton"
    b:SetAttribute("useOnKeyDown", false)
    b.icon:ClearAllPoints()
    b.icon:SetSize(36, 36)
    b.icon:SetPoint("LEFT", 4, 0)
    b.icon:SetTexCoord(0, 1, 0, 1)
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", b.icon, "RIGHT", 9, 0)
    b.text:SetPoint("RIGHT", -8, 0)
    b.text:SetJustifyH("LEFT")
    b.text:SetTextColor(1, 0.94, 0.76)
    b.fill:SetColorTexture(0.10, 0.13, 0.11)
    F.attachBindingMenu(b)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.caption)
        if F.panel.reviveSpell then GameTooltip:AddLine("Shift-click to revive a missing pet.", 1, 1, 1) end
        F.bindingHint(self)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

function F.refreshCallCard()
    local b = F.panel.callCard
    local info = C_StableInfo and C_StableInfo.GetStablePetInfo and C_StableInfo.GetStablePetInfo(1)
    local liveName = F.readPetIdentity()
    if issecretvalue(info) then info = nil end
    local name, displayID, iconID
    if info and not issecretvalue(info.name) and type(info.name) == "string"
        and (not liveName or info.name == liveName) then
        name = info.name
        if not issecretvalue(info.displayID) and type(info.displayID) == "number" and info.displayID > 0 then displayID = info.displayID end
        if not issecretvalue(info.icon) and type(info.icon) == "number" and info.icon > 0 then iconID = info.icon end
    end
    name = liveName or name
    local last = type(ForeverPetModesLastPet) == "table" and ForeverPetModesLastPet or {}
    if name and name ~= "" then
        if last.name ~= name then last = {} end
        last.name, last.displayID, last.iconID = name, displayID or last.displayID, iconID or last.iconID
        ForeverPetModesLastPet = last
    end
    b.caption = type(last.name) == "string" and ("Call " .. last.name) or "Call Pet"
    b.text:SetText(b.caption)
    if type(last.displayID) == "number" then
        b.livePortraitName = nil
        SetPortraitTextureFromCreatureDisplayID(b.icon, last.displayID)
    elseif liveName and SetPortraitTexture then
        SetPortraitTexture(b.icon, "pet")
        b.livePortraitName = liveName
    elseif not last.name or b.livePortraitName ~= last.name then
        b.icon:SetTexture(last.iconID or 132161)
    end
end

local function createResizeGrip(panel)
    local grip = CreateFrame("Button", nil, panel)
    grip:SetPoint("BOTTOMRIGHT")
    grip:SetSize(metrics.gripSize, metrics.gripSize)
    for _, length in ipairs({4, 8}) do
        local line = grip:CreateLine(nil, "ARTWORK")
        line:SetStartPoint("BOTTOMRIGHT", grip, -3 - length, 3)
        line:SetEndPoint("BOTTOMRIGHT", grip, -3, 3 + length)
        line:SetThickness(1)
        line:SetColorTexture(0.82, 0.76, 0.62, 1)
    end
    grip:SetAlpha(0.55)
    grip:RegisterForDrag("LeftButton")
    grip:RegisterForClicks("RightButtonUp")
    local drag
    local function stop()
        drag = nil
        grip:SetScript("OnUpdate", nil)
    end
    local function update()
        if not drag then return end
        if F.db.locked or InCombatLockdown() then stop() return end
        local x, y = GetCursorPosition()
        local dx = math.floor((x - drag.x) / drag.scale + 0.5)
        local dy = math.floor((drag.y - y) / drag.scale + 0.5)
        local column = math.max(panel.minColumnWidth, math.min(drag.column + dx, drag.maxColumn))
        local height = math.max(0, math.min(drag.height + dy, drag.maxHeight))
        -- A purely vertical drag keeps the automatic width, and vice versa.
        if dx == 0 then column = drag.savedColumn end
        if dy == 0 then height = drag.savedHeight end
        if column == F.db.columnWidth and height == F.db.minPanelHeight then return end
        F.db.columnWidth, F.db.minPanelHeight = column, height
        F.db.position = drag.anchor
        F.syncPanelGeometry()
        F.layout(true)
    end
    grip:SetScript("OnDragStart", function()
        if F.db.locked or InCombatLockdown() then return end
        if panel.foodPicker then panel.foodPicker:Hide() end
        GameTooltip:Hide()
        local x, y = GetCursorPosition()
        local scale = panel:GetEffectiveScale()
        local ratio = UIParent:GetEffectiveScale() / scale
        local left, top = panel:GetLeft(), panel:GetTop()
        drag = { x=x, y=y, scale=scale, column=panel.contentWidth, height=panel:GetHeight(),
            savedColumn=F.db.columnWidth, savedHeight=F.db.minPanelHeight,
            maxColumn=UIParent:GetRight() * ratio - left - (panel:GetWidth() - panel.contentWidth),
            maxHeight=top - UIParent:GetBottom() * ratio,
            anchor={point="TOPLEFT", relative="TOPLEFT", x=left - UIParent:GetLeft() * ratio,
                y=top - UIParent:GetTop() * ratio} }
        local elapsed = 0
        grip:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + dt
            if elapsed >= 1 / 30 then
                elapsed = 0
                update()
            end
        end)
    end)
    grip:SetScript("OnDragStop", function()
        update()
        stop()
    end)
    grip:SetScript("OnHide", stop)
    grip:SetScript("OnClick", function(_, mouse)
        if mouse ~= "RightButton" or F.db.locked or InCombatLockdown() then return end
        F.db.columnWidth, F.db.minPanelHeight = 0, 0
        F.syncPanelGeometry()
        F.layout()
        F.refresh()
    end)
    grip:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Resize panel")
        GameTooltip:AddLine(InCombatLockdown() and "Available after combat." or "Drag to resize. Right-click for automatic size.", 1, 1, 1)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function(self)
        self:SetAlpha(0.55)
        GameTooltip:Hide()
    end)
    return grip
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
    panel.title:SetWordWrap(false)
    panel.title:SetText("Forever Pet Modes")
    F.createIndicators(panel)
    panel.divider = createDivider(panel)
    F.createPetControls(panel, actionButton)
    panel.resizeGrip = createResizeGrip(panel)
    panel.callCard = createCallCard()
    panel.callCard:SetPoint("TOPLEFT", panel, "TOPLEFT")
    panel.bg:SetPoint("TOPLEFT", panel, "TOPLEFT")
    panel.bg:SetPoint("BOTTOMRIGHT", panel.footer, "BOTTOMRIGHT", metrics.padding, -metrics.gripSize)
    local function startMoving()
        if not F.db.locked and not InCombatLockdown() then panel:StartMoving() end
    end
    local function stopMoving()
        if InCombatLockdown() then return end
        panel:StopMovingOrSizing()
        local p, _, r, x, y = panel:GetPoint()
        F.db.position = { point = p, relative = r, x = x + panel.foldedWidth * horizontalAnchor(p), y = y }
        F.syncPanelGeometry()
    end
    panel:SetScript("OnDragStart", startMoving)
    panel:SetScript("OnDragStop", stopMoving)
    local strip = CreateFrame("Frame", nil, panel)
    strip:SetPoint("TOPLEFT", panel, "TOPLEFT")
    panel.title:SetPoint("CENTER", strip, "CENTER")
    strip:EnableMouse(true)
    strip:RegisterForDrag("LeftButton")
    strip:SetScript("OnDragStart", startMoving)
    strip:SetScript("OnDragStop", stopMoving)
    strip.mark = strip:CreateTexture(nil, "ARTWORK")
    strip.mark:SetSize(26, 2)
    strip.mark:SetPoint("CENTER")
    strip.mark:SetColorTexture(0.56, 0.52, 0.43, 0.65)
    strip:SetScript("OnEnter", function(self) self.mark:SetColorTexture(0.90, 0.83, 0.68) end)
    strip:SetScript("OnLeave", function(self) self.mark:SetColorTexture(0.56, 0.52, 0.43, 0.65) end)
    panel.dragStrip = strip
end

function F.layout(resizing)
    if InCombatLockdown() then return end
    local d, panel = F.db, F.panel
    if not resizing and panel.foodPicker then panel.foodPicker:Hide() end
    panel:SetScale(d.scale)
    local card = panel.callCard
    local border = PixelUtil.GetNearestPixelSize(d.border, panel:GetEffectiveScale(), d.border > 0 and 1 or 0)
    local n, pad, gap = #d.profiles, metrics.padding, metrics.gap
    local header = d.title and (math.ceil(panel.title:GetStringHeight()) + gap) or 0
    local cols = d.vertical and 1 or math.min(n, 4)
    local rows = math.ceil(n / cols)
    local barWidth = cols * d.width + (cols - 1) * d.spacing
    if not resizing then
        panel.hasCare = F.prepareCare(panel, d.showCare)
        card:SetScale(d.scale)
        card:SetSize(math.max(172, d.width + 66), 44)
        insetFill(card, border)
        card:SetAttribute("*type1", panel.callSpell and "macro" or nil)
    end
    local hasCare = panel.hasCare
    if panel.callSpell and not resizing then
        local revive = panel.reviveSpell and ("[mod:shift,@pet,noexists] " .. panel.reviveSpell .. "; ") or ""
        card:SetAttribute("*macrotext1", "/cast " .. revive .. "[@pet,noexists] " .. panel.callSpell)
        F.refreshCallCard()
    end
    local hasControls = d.showRecall or d.showHappiness or hasCare
    local expanded = hasControls and not d.petControlsCollapsed
    panel.minColumnWidth = math.max(110, cols * 40 + (cols - 1) * d.spacing)
    local leftWidth = d.columnWidth > 0 and math.max(panel.minColumnWidth, d.columnWidth) or math.max(150, barWidth)
    local buttonWidth = d.columnWidth > 0 and (leftWidth - (cols - 1) * d.spacing) / cols or d.width
    local badgeWidth = metrics.moodSize + gap + metrics.petNameWidth
    local commandWidth = 3 * (d.icons and d.height or 48) + 2 * gap
    local rightWidth = math.max(d.showRecall and commandWidth or 0, d.showHappiness and badgeWidth or 0, hasCare and 92 or 0)
    local dividerX = pad + leftWidth + gap
    local rightX = dividerX + metrics.dividerWidth + gap
    local folded = hasControls and not expanded
    local extension = 2 * gap + metrics.dividerWidth + rightWidth
    local width = leftWidth + 2 * pad + (expanded and extension or 0)
    panel.foldedWidth = folded and extension or 0
    local top = math.max(metrics.moveGutter, pad + header)
    local headerInset = folded and metrics.dividerWidth or 0
    panel.dragStrip:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -headerInset, 0)
    panel.title:SetWidth(width - headerInset - 2 * pad)
    panel.dragStrip:SetHeight(top)
    panel.dragStrip:SetShown(not d.locked)
    panel.dragStrip.mark:SetShown(not d.title)
    panel.buttonHeight = top + rows * d.height + (rows - 1) * d.spacing + gap
    panel.divider:ClearAllPoints()
    if folded then
        panel.divider:SetPoint("TOPRIGHT", panel, "TOPRIGHT")
        panel.divider:SetHeight(top)
    else
        panel.divider:SetPoint("TOPLEFT", dividerX, -top)
        panel.divider:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", dividerX, pad)
    end
    panel.divider.upperRail:SetShown(expanded)
    panel.divider.lowerRail:SetShown(expanded)
    panel.divider.arrow:SetRotation(expanded and math.pi or 0)
    panel.divider:SetShown(hasControls)
    panel.moodIcon:ClearAllPoints()
    panel.moodIcon:SetPoint("TOPLEFT", rightX, -top)
    F.sizePetBadge(panel.moodIcon, math.max(badgeWidth, rightWidth))
    local nextRow = top + (d.showHappiness and metrics.moodSize + gap or 0)
    F.layoutPetCommands(panel, d, expanded, rightX, nextRow, rightWidth, border, insetFill)
    if d.showRecall then nextRow = nextRow + d.height + gap end
    F.layoutCare(panel, expanded and hasCare, rightX, nextRow, rightWidth, border, insetFill)
    panel.petColumnBottom = hasCare and nextRow + metrics.careHeight or nextRow - gap
    panel:SetWidth(width)
    panel.resizeGrip:SetShown(not d.locked)
    panel.contentWidth = leftWidth
    panel.footer:ClearAllPoints()
    panel.footer:SetPoint("TOPLEFT", pad, -panel.buttonHeight)
    panel.footer:SetWidth(width - 2 * pad)
    panel.measuredHeight = nil
    panel:ClearAllPoints()
    -- Keep the profile column in place as the panel changes width.
    local x = d.position.x - panel.foldedWidth * horizontalAnchor(d.position.point)
    panel:SetPoint(d.position.point, UIParent, d.position.relative, x, d.position.y)
    panel.bg:SetColorTexture(0.07, 0.06, 0.05, d.opacity)
    panel.title:SetShown(d.title)
    local used = {}
    for i, profile in ipairs(d.profiles) do
        local slot = tonumber(profile.favorite)
        if slot and used[favorites[slot]] then slot = nil end
        local pool, index = slot and favorites or ordinary, slot or profile.bindingID
        local name = (slot and "ForeverPetModesFavorite" or "ForeverPetModesProfile") .. index
        local b = pool[index] or newButton(panel, name)
        b.binding = "CLICK " .. name .. ":LeftButton"
        b.personalBinding = nil
        pool[index], used[b] = b, true
        buttons[i] = b
        b.profile = profile
        b:SetAlpha(1)
        b:EnableMouse(true)
        b:ClearAllPoints()
        local column = (i - 1) % cols
        local x = column * (buttonWidth + d.spacing)
        local y = math.floor((i - 1) / cols) * (d.height + d.spacing)
        -- At compact spacing, adjacent profiles share one seam and the entire strip is clickable.
        local joined = d.spacing <= gap
        local joinLeft = joined and column > 0
        local joinRight = joined and column < cols - 1 and i < n
        b:SetPoint("TOPLEFT", pad + x, -top - y)
        b:SetSize(buttonWidth + (joinRight and d.spacing or 0), d.height)
        insetFill(b, border, joinLeft and 0 or border)
        b.text:SetText(profile.label)
        b.text:ClearAllPoints()
        b.text:SetPoint("CENTER", 4, 0)
        b.text:SetWidth(math.max(12, buttonWidth - 28))
        b.text:SetShown(not d.icons)
        b.icon:SetTexture(profile.icon)
        local size = math.min(buttonWidth, d.height) - 2 * d.border - 4
        b.icon:SetSize(size, size)
        b.icon:SetShown(d.icons)
        b:Show()
        -- Keep this profile's own shortcut usable if it later becomes a favorite.
        if slot then
            local personalName = "ForeverPetModesProfile" .. profile.bindingID
            local personal = "CLICK " .. personalName .. ":LeftButton"
            if GetBindingKey(personal) then
                local alias = ordinary[profile.bindingID] or newButton(panel, personalName)
                ordinary[profile.bindingID], used[alias] = alias, true
                alias.profile, alias.binding, b.personalBinding = profile, personal, personal
                alias:ClearAllPoints()
                alias:SetAllPoints(b)
                alias:SetAlpha(0)
                alias:EnableMouse(false)
                alias:Show()
            end
        end
    end
    for _, pool in ipairs({favorites, ordinary}) do
        for _, b in pairs(pool) do
            if not used[b] and b.profile then
                b:Hide()
                b:SetAttribute("type1", nil)
                b:SetAttribute("macrotext1", nil)
                b.profile, b.boundText = nil, nil
            end
        end
    end
    for i = #buttons, n + 1, -1 do buttons[i] = nil end
    if resizing then
        F.layoutStatus(panel, panel.moodIcon.state, panel.statusMatches)
        return
    end
    F.visibility()
    if hasControls and GameTooltip:IsOwned(panel.divider) then panel.divider:GetScript("OnEnter")(panel.divider) end
end

function F.visibility()
    if InCombatLockdown() then return end
    local d, inside = F.db, IsInInstance()
    for _, button in ipairs(F.panel.commands) do
        button:SetAttribute("*type1", F.classVisible and "macro" or nil)
    end
    local conditions = {}
    local cardCondition = "hide"
    if not F.classVisible or (d.panelHidden and d.showMinimap)
        or (d.instance == "inside" and not inside) or (d.instance == "outside" and inside) then
        conditions[1] = "hide"
    else
        if d.hideCombat then conditions[#conditions + 1] = "[combat] hide" end
        if F.panel.callSpell then
            cardCondition = (d.hideCombat and "[combat] hide; " or "") .. "[@pet,noexists] show; hide"
            conditions[#conditions + 1] = "[@pet,noexists] hide"
        elseif d.hideNoPet and not F.panel.absentPetCare then conditions[#conditions + 1] = "[nopet] hide" end
        conditions[#conditions + 1] = "show"
    end
    local driver = table.concat(conditions, "; ")
    if F.cardDriver ~= cardCondition then
        RegisterStateDriver(F.panel.callCard, "visibility", cardCondition)
        F.cardDriver = cardCondition
    end
    if F.driver ~= driver then
        RegisterStateDriver(F.panel, "visibility", driver)
        F.driver = driver
    end
end

function F.paint(state)
    F.paintPetCommands(F.panel, state)
    local matches = {}
    for i, profile in ipairs(F.db.profiles) do
        local b = buttons[i]
        local active = F.matchesProfile(profile, state)
        if active and F.failedProfile == profile then F.failedProfile = nil end
        matches[profile] = active
        F.bind(b, profile, state)
        b.unavailable = InCombatLockdown() and "Available after combat." or
            (IsModifierKeyDown() and "Release the modifier key to apply this profile." or b.problem)
        local r, g, blue = F.rgb(active and profile.color or F.db.inactive)
        b.fill:SetColorTexture(r, g, blue)
        if active then b.edge:SetColorTexture(0.26 + 0.70 * r, 0.26 + 0.70 * g, 0.24 + 0.70 * blue)
        else b.edge:SetColorTexture(0.40, 0.38, 0.32) end
        b.mark:SetShown(active)
        b.warning:SetShown(b.unavailable ~= nil or F.failedProfile == profile)
        if GameTooltip:IsOwned(b) then showTarget(b, state) end
    end
    F.paintIndicators(F.panel, state, matches)
    F.refreshMinimapTooltip(state)
end
