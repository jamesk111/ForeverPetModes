local _, F = ...
local summon = 1293241
local ranks = { [summon]=true, [1293525]=true, [1293526]=true, [1293527]=true }
local lifetime, capacity = 18, 2
local birds = {}
local tracker, lastCast, hawkIcon, hawkName
local placing = false

local function readable(value)
    return not issecretvalue(value) and value
end

local badgeHeight, badgeGap, laneWidth = 28, 3, 30

local function finishMove(badge)
    if not badge.dragging then return end
    badge:StopMovingOrSizing()
    badge.dragging = false
    badge:SetUserPlaced(false)
    badge.anchor = nil
    local x, y = badge:GetCenter()
    if x and y then
        local scale = badge:GetEffectiveScale() / UIParent:GetEffectiveScale()
        F.saveHawkPosition({
            x = (x * scale - UIParent:GetLeft()) / UIParent:GetWidth(),
            y = (y * scale - UIParent:GetBottom()) / UIParent:GetHeight(),
        })
    end
    placing = false
end

local function canMove()
    return not InCombatLockdown() and (placing or not F.db.locked)
end

local function makeBadge(parent)
    local badge = CreateFrame("Button", nil, parent, "BackdropTemplate")
    badge:SetSize(126, badgeHeight)
    badge:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    badge:SetBackdropColor(0.075, 0.08, 0.07, 0.96)
    badge:SetBackdropBorderColor(0.36, 0.33, 0.26)
    badge:SetMovable(true)
    badge:SetClampedToScreen(true)
    badge:RegisterForDrag("LeftButton")
    badge:RegisterForClicks("RightButtonUp")
    badge:SetScript("OnDragStart", function(self)
        if not canMove() then return end
        GameTooltip:Hide()
        self.dragging = true
        self:StartMoving()
    end)
    badge:SetScript("OnDragStop", finishMove)
    badge:SetScript("OnHide", finishMove)
    badge:SetScript("OnClick", function(self, button)
        if button ~= "RightButton" or not canMove() then return end
        F.saveHawkPosition({})
        placing = false
        GameTooltip:Hide()
    end)
    badge:SetScript("OnEnter", function(self)
        if not canMove() then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Summoned hawks")
        GameTooltip:AddLine("Drag to move. Right-click to reattach.", 1, 1, 1)
        GameTooltip:Show()
    end)
    badge:SetScript("OnLeave", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    local icon = badge:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", 5, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    badge.icon = icon
    badge.count = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge.count:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    badge.count:SetTextColor(0.94, 0.88, 0.72)
    local divider = badge:CreateTexture(nil, "ARTWORK")
    divider:SetSize(1, 16)
    divider:SetPoint("LEFT", 51, 0)
    divider:SetColorTexture(0.36, 0.33, 0.26, 0.8)
    badge.lanes = {}
    for i = 1, capacity do
        local x = 56 + (i - 1) * (laneWidth + 5)
        local label = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("TOPLEFT", x, -4)
        label:SetWidth(laneWidth)
        label:SetWordWrap(false)
        local track = badge:CreateTexture(nil, "ARTWORK")
        track:SetSize(laneWidth, 2)
        track:SetPoint("BOTTOMLEFT", x, 5)
        track:SetColorTexture(0.24, 0.24, 0.20)
        local fill = badge:CreateTexture(nil, "OVERLAY")
        fill:SetHeight(2)
        fill:SetPoint("LEFT", track, "LEFT")
        badge.lanes[i] = {label=label, fill=fill}
    end
    badge:Hide()
    return badge
end

local function dock(badge)
    if badge.dragging then return end
    local pos = F.db.hawkPosition
    if pos.x then
        local scale = UIParent:GetEffectiveScale() / badge:GetEffectiveScale()
        local x, y = pos.x * UIParent:GetWidth() * scale, pos.y * UIParent:GetHeight() * scale
        if badge.anchor ~= UIParent or x ~= badge.savedX or y ~= badge.savedY then
            badge:ClearAllPoints()
            badge:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            badge.anchor, badge.savedX, badge.savedY = UIParent, x, y
        end
        return
    end
    local parent = badge:GetParent()
    local anchor = parent.bg or parent
    if parent.foodPicker and parent.foodPicker:IsVisible() then anchor = parent.foodPicker end
    local bottom = anchor:GetBottom()
    local above = bottom and bottom < badgeHeight + badgeGap
    if above then anchor = parent end
    if badge.anchor == anchor and badge.above == above then return end
    badge:ClearAllPoints()
    if above then badge:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, badgeGap)
    else badge:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -badgeGap) end
    badge.anchor, badge.above = anchor, above
end

local function paintLane(lane, bird, now)
    local remaining = bird and bird.ends - now or 0
    local seconds = math.ceil(remaining)
    local text = bird and ((bird.estimated and "~" or "") .. seconds .. "s") or "—"
    if text ~= lane.text then
        lane.text = text
        lane.label:SetText(text)
        if not bird then lane.label:SetTextColor(0.50, 0.50, 0.45)
        elseif seconds <= 3 then lane.label:SetTextColor(1, 0.77, 0.42)
        else lane.label:SetTextColor(0.94, 0.91, 0.83) end
        if seconds <= 3 then lane.fill:SetColorTexture(0.93, 0.60, 0.24)
        else lane.fill:SetColorTexture(0.47, 0.66, 0.52) end
        lane.fill:SetShown(bird ~= nil)
    end
    if bird then
        local fraction = math.min(1, remaining / math.max(1, bird.ends - bird.start))
        lane.fill:SetWidth(math.max(1, math.floor(laneWidth * fraction + 0.5)))
    end
end

local function earliest(a, b)
    return a.ends < b.ends
end

local function render(now)
    for i = #birds, 1, -1 do
        if birds[i].ends <= now then table.remove(birds, i) end
    end
    table.sort(birds, earliest)
    while #birds > capacity do table.remove(birds, 1) end
    local visible = tracker.enabled and (#birds > 0 or placing)
    local moving = false
    for _, badge in ipairs(tracker.badges) do
        if badge.dragging and (not canMove() or not tracker.enabled) then finishMove(badge) end
        if visible or badge.dragging then
            dock(badge)
            badge:EnableMouse(canMove())
            badge.count:SetText(#birds .. "/" .. capacity)
            for i, lane in ipairs(badge.lanes) do paintLane(lane, birds[i], now) end
        end
        if badge.dragging then moving = true end
        badge:SetShown(visible or badge.dragging or false)
    end
    tracker:SetShown(visible or moving)
end

function F.toggleHawkPlacement()
    if InCombatLockdown() then return end
    if not tracker or not tracker.enabled then
        F.say("Enable Summon Hawk timers on your Hunter to move the tab.")
        return
    end
    if not F.panel:IsVisible() and not F.panel.callCard:IsVisible() then
        F.say("Show the pet panel before moving the hawk tab.")
        return
    end
    placing = not placing
    render(GetTime())
end

-- A slot notification may precede or follow the matching cast. Match only
-- within the arrival window, shorter than the spell's six-second cooldown.
local function scanSlots(now)
    for slot = 1, GetNumTotemSlots() do
        local present, name, start, duration, icon, _, id = GetTotemInfo(slot)
        local bound
        for i, bird in ipairs(birds) do
            if bird.slot == slot then bound = i break end
        end
        local hawk = ranks[readable(id)] or (hawkIcon and readable(icon) == hawkIcon)
            or (hawkName and readable(name) == hawkName)
        if issecretvalue(present) or (present and not hawk and (issecretvalue(id) or issecretvalue(icon) or issecretvalue(name))) then
            if bound then birds[bound].estimated = true end
        elseif not present or not hawk then
            if bound then table.remove(birds, bound) end
        elseif type(readable(start)) == "number" and start > 0
            and type(readable(duration)) == "number" and duration > 0 then
            local left = readable(GetTotemTimeLeft(slot))
            local ends = type(left) == "number" and now + left or start + duration
            if bound then table.remove(birds, bound) end
            for i = #birds, 1, -1 do
                if not birds[i].slot and math.abs(birds[i].start - start) <= 2 then table.remove(birds, i) end
            end
            birds[#birds + 1] = {slot=slot, start=start, ends=ends}
        elseif bound then
            birds[bound].estimated = true
        end
    end
end

local function reset()
    birds = {}
    lastCast = nil
end

local function onEvent(self, event, unit, castGUID, spellID)
    if event == "PLAYER_REGEN_DISABLED" then
        placing = false
    elseif event == "PLAYER_DEAD" then
        reset()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if readable(unit) ~= "player" then return end
        if readable(spellID) == 2641 then -- A completed Dismiss Pet also dismisses hawks.
            reset()
            render(GetTime())
            return
        end
        if not ranks[readable(spellID)] then return end
        local now = GetTime()
        if lastCast and now - lastCast < 1 then return end
        lastCast = now
        birds[#birds + 1] = {start=now, ends=now + lifetime, estimated=true}
        scanSlots(now)
    else
        if event == "PLAYER_ENTERING_WORLD" then reset() end
        scanSlots(GetTime())
    end
    render(GetTime())
end

function F.configureHawks(panel, enabled)
    if not enabled and not tracker then return end
    if not tracker then
        tracker = CreateFrame("Frame")
        panel.hawkTracker = tracker
        tracker.badges = {
            makeBadge(panel),
            makeBadge(panel.callCard),
        }
        tracker:SetScript("OnEvent", onEvent)
        local elapsed = 0
        tracker:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + dt
            if elapsed < 0.2 then return end
            elapsed = 0
            render(GetTime())
        end)
    end
    if enabled ~= tracker.enabled then
        tracker.enabled = enabled
        reset()
        if enabled then
            hawkIcon = readable(C_Spell.GetSpellTexture(summon))
            hawkName = readable(C_Spell.GetSpellName(summon))
            for _, badge in ipairs(tracker.badges) do badge.icon:SetTexture(hawkIcon) end
            tracker:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
            for _, event in ipairs({"PLAYER_TOTEM_UPDATE", "PLAYER_DEAD", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED"}) do
                tracker:RegisterEvent(event)
            end
        else
            placing = false
            tracker:UnregisterAllEvents()
        end
    end
    if enabled then scanSlots(GetTime()) end
    render(GetTime())
end
