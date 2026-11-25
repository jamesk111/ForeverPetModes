local _, F = ...
local size, gap, padding = 32, 4, 6

local function canFeed()
    if InCombatLockdown() then return false end
    local exists, dead = UnitExists("pet"), UnitIsDeadOrGhost("pet")
    return not issecretvalue(exists) and exists and not issecretvalue(dead) and not dead
end

local function edibleSlot(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if issecretvalue(info) or not info or issecretvalue(info.itemID) or not info.itemID or issecretvalue(info.isLocked)
        or info.isLocked or issecretvalue(info.stackCount) or not info.stackCount or info.stackCount < 1 then return end
    local edible = C_PetInfo.CanPetEatItem(info.itemID)
    if not issecretvalue(edible) and edible then return info end
end

local function carriedFood()
    local choices, byID = {}, {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = edibleSlot(bag, slot)
            if info then
                local food = byID[info.itemID]
                if not food then
                    food = {id=info.itemID, icon=info.iconFileID, count=0, bag=bag, slot=slot}
                    choices[#choices + 1], byID[info.itemID] = food, food
                end
                food.count = food.count + info.stackCount
            end
        end
    end
    return choices
end

local function tooltip(button)
    local food = button.food
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(food.bag, food.slot)
    GameTooltip:Show()
end

local redraw
local function newChoice(tray)
    local b = CreateFrame("Button", nil, tray, "SecureActionButtonTemplate")
    b:SetSize(size, size)
    local edge = b:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints()
    edge:SetColorTexture(0.49, 0.45, 0.35)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 1, -1)
    b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", -2, 2)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:RegisterForClicks("LeftButtonUp")
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("*spell1", 6991)
    b:SetScript("OnEnter", tooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnHide", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    b:SetScript("OnMouseDown", function(self) self.pressedID = self.food and self.food.id end)
    b:SetScript("PreClick", function(self)
        if not canFeed() or not tray:IsVisible() or SpellIsTargeting() or GetCursorInfo() then return end
        local food = self.food
        local info = food and edibleSlot(food.bag, food.slot)
        if not info or info.itemID ~= food.id or (self.pressedID and self.pressedID ~= food.id) then return end
        self:SetAttribute("*target-bag1", food.bag)
        self:SetAttribute("*target-slot1", food.slot)
        self:SetAttribute("*type1", "spell")
        self.armed = true
    end)
    b:SetScript("PostClick", function(self)
        self.pressedID = nil
        if InCombatLockdown() then return end
        if self.armed then
            self.armed = nil
            self:SetAttribute("*type1", nil)
            self:SetAttribute("*target-bag1", nil)
            self:SetAttribute("*target-slot1", nil)
            tray:Hide()
        elseif tray:IsVisible() then
            redraw(tray)
        end
    end)
    return b
end

redraw = function(tray)
    if InCombatLockdown() then return end
    if not canFeed() then tray:Hide() return end
    local foods = carriedFood()
    local width = F.panel:GetWidth()
    local cols = math.max(1, math.floor((width - 2 * padding + gap) / (size + gap)))
    local perPage = cols * 2
    local pages = math.max(1, math.ceil(#foods / perPage))
    tray.page = math.min(pages, tray.page)
    local offset = (tray.page - 1) * perPage
    local visible = math.min(perPage, #foods - offset)
    for i = 1, visible do
        local b = tray.choices[i] or newChoice(tray)
        tray.choices[i], b.food = b, foods[offset + i]
        b.icon:SetTexture(b.food.icon)
        b.count:SetText(b.food.count > 1 and b.food.count or "")
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", padding + ((i - 1) % cols) * (size + gap), -padding - math.floor((i - 1) / cols) * (size + gap))
        b:Show()
        if GameTooltip:IsOwned(b) then tooltip(b) end
    end
    for i = visible + 1, #tray.choices do
        tray.choices[i].food = nil
        tray.choices[i]:Hide()
    end
    tray.message:SetShown(visible == 0 or pages > 1)
    tray.message:SetText(visible == 0 and "No suitable food in your bags." or (tray.page .. " / " .. pages))
    tray.prev:SetShown(pages > 1)
    tray.next:SetShown(pages > 1)
    tray.prev:SetEnabled(tray.page > 1)
    tray.next:SetEnabled(tray.page < pages)
    local rows = math.ceil(visible / cols)
    local content = rows > 0 and rows * (size + gap) - gap or 20
    tray:SetSize(width, 2 * padding + content + (pages > 1 and 24 or 0))
end

local function createTray(feed)
    local tray = CreateFrame("Frame", nil, feed, "BackdropTemplate")
    tray:Hide()
    tray:EnableMouse(true)
    tray:SetPoint("TOPLEFT", F.panel, "BOTTOMLEFT", 0, -gap)
    tray:SetClampedToScreen(true)
    tray:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    tray:SetBackdropColor(0.075, 0.08, 0.07, 0.96)
    tray:SetBackdropBorderColor(0.36, 0.33, 0.26)
    tray.choices = {}
    tray.message = tray:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tray.message:SetPoint("BOTTOM", 0, padding + 4)
    local function pageButton(label, anchor, x, delta)
        local button = CreateFrame("Button", nil, tray, "UIPanelButtonTemplate")
        button:SetSize(28, 20)
        button:SetPoint(anchor, x, padding)
        button:SetText(label)
        button:SetScript("OnClick", function()
            tray.page = math.max(1, tray.page + delta)
            redraw(tray)
        end)
        return button
    end
    tray.prev = pageButton("<", "BOTTOMLEFT", padding, -1)
    tray.next = pageButton(">", "BOTTOMRIGHT", -padding, 1)
    tray:SetScript("OnShow", function(self)
        self:RegisterEvent("BAG_UPDATE_DELAYED")
        self:RegisterEvent("ITEM_LOCK_CHANGED")
        self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    end)
    tray:SetScript("OnHide", function(self)
        self:UnregisterAllEvents()
        if not InCombatLockdown() and self:IsShown() then self:Hide() end
    end)
    tray:SetScript("OnEvent", function(self)
        if self:IsVisible() and not self.pending then
            self.pending = true
            C_Timer.After(0, function()
                self.pending = nil
                if self:IsVisible() then redraw(self) end
            end)
        end
    end)
    return tray
end

function F.toggleFoodPicker(feed, mouse)
    if mouse ~= "LeftButton" or not feed:IsVisible() or not canFeed() then return end
    local tray = F.panel.foodPicker or createTray(feed)
    F.panel.foodPicker = tray
    if tray:IsShown() then tray:Hide() return end
    tray.page = 1
    tray:Show()
    redraw(tray)
end
