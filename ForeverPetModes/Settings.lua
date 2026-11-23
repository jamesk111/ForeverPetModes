local _, F = ...
local appearance = {
    { "width", "Button width", 40, 220 }, { "height", "Button height", 20, 80 },
    { "scale", "Panel scale", 0.5, 2 }, { "spacing", "Button spacing", 0, 32 },
    { "border", "Border thickness", 0, 6 }, { "opacity", "Background opacity", 0, 1 },
    { "inactive", "Inactive color (hex)", "color" },
    { "vertical", "Vertical layout", "toggle" }, { "icons", "Use icons", "toggle" },
    { "title", "Show title", "toggle" },
}
local behavior = {
    { "locked", "Lock position", "toggle" }, { "hideNoPet", "Hide without a pet", "toggle" },
    { "hideCombat", "Hide in combat", "toggle" }, { "instance", "Show in", { "any", "inside", "outside" } },
    { "sound", "Confirmation sound", "toggle" },
    { "huntersOnly", "Hunters only", "toggle" }, { "showMinimap", "Minimap button", "toggle" },
}
local profileFields = {
    { "label", "Button label", "label" }, { "stance", "Pet stance", { "Defensive", "Passive", "Aggressive", "Assist" } },
    { "color", "Active color (hex)", "color" }, { "icon", "Icon file ID", 1, 2147483647 },
    { "rules", "Autocast rules", "rules" },
}
local window, page, draft, advanced
local tabs, picks = {}, {}
local render, selectPage
local rows = {}

local function decode(field, raw)
    local kind = field[3]
    if kind == "toggle" or type(kind) == "table" then return raw end
    if kind == "rules" then return F.parseRules(raw) end
    if kind == "color" and raw:match("^%x%x%x%x%x%x$") then return raw:upper() end
    if kind == "label" and #raw <= 40 and raw:match("%S") and not raw:find("[%c|]") then return raw end
    if type(kind) == "number" then
        local n = tonumber(raw)
        if n and n >= kind and n <= field[4] and (field[1] ~= "icon" or n == math.floor(n)) then return n end
        return nil, "Enter a number from " .. kind .. " to " .. field[4] .. "."
    end
    return nil, kind == "color" and "Enter six hex digits, such as 237440." or "Enter a label of 1 to 40 bytes."
end

local function validSaved(field, value)
    local kind = field[3]
    if kind == "toggle" then return type(value) == "boolean" end
    if type(kind) == "table" then
        for _, choice in ipairs(kind) do if value == choice then return true end end
        return false
    end
    if kind == "rules" then
        if type(value) ~= "table" then return false end
        local seen = {}
        for i, rule in pairs(value) do
            if type(i) ~= "number" or i < 1 or i > #value or i ~= math.floor(i)
                or type(rule) ~= "table" or type(rule.id) ~= "number" or rule.id < 1
                or rule.id > 2147483647 or rule.id ~= math.floor(rule.id) or seen[rule.id]
                or type(rule.on) ~= "boolean" then return false end
            seen[rule.id] = true
        end
        for i = 1, #value do if value[i] == nil then return false end end
        return true
    end
    if type(kind) == "number" and type(value) ~= "number" then return false end
    if type(kind) == "string" and type(value) ~= "string" then return false end
    return decode(field, tostring(value)) ~= nil
end

local function repair(target, fields, defaults)
    for _, field in ipairs(fields) do
        local key = field[1]
        if not validSaved(field, target[key]) then target[key] = F.copy(defaults[key]) end
    end
end

function F.loadSettings(saved)
    local db = F.mergeSettings(saved)
    if math.abs(db.minimapAngle) < math.huge then db.minimapAngle = db.minimapAngle % 360
    else db.minimapAngle = F.defaults.minimapAngle end
    repair(db, appearance, F.defaults)
    repair(db, behavior, F.defaults)
    local anchor = { CENTER=true, TOP=true, TOPLEFT=true, TOPRIGHT=true, BOTTOM=true,
        BOTTOMLEFT=true, BOTTOMRIGHT=true, LEFT=true, RIGHT=true }
    local p = db.position
    if not anchor[p.point] or not anchor[p.relative] or type(p.x) ~= "number" or type(p.y) ~= "number"
        or not (math.abs(p.x) < 100000 and math.abs(p.y) < 100000) then
        db.position = F.copy(F.defaults.position)
    end
    for i = 1, math.max(#db.profiles, #F.defaults.profiles) do
        local defaults = F.defaults.profiles[i] or F.defaults.profiles[1]
        if type(db.profiles[i]) ~= "table" then db.profiles[i] = F.copy(defaults) end
        repair(db.profiles[i], profileFields, defaults)
    end
    return db
end

local function textAt(parent, font, x, y)
    local t = parent:CreateFontString(nil, "OVERLAY", font)
    t:SetPoint("TOPLEFT", x, -y)
    t:SetJustifyH("LEFT")
    return t
end

local function button(parent, width, name, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 23)
    b:SetText(name)
    b:SetScript("OnClick", callback)
    return b
end

local function display(value)
    if type(value) == "boolean" then return value and "On" or "Off" end
    return tostring(value)
end


local function rowAt(i)
    if rows[i] then return rows[i] end
    local y = 2 + (i - 1) * 29
    local row = { title = textAt(window.body, "GameFontHighlight", 4, y + 4) }
    row.input = CreateFrame("EditBox", nil, window.body, "InputBoxTemplate")
    row.input:SetPoint("TOPLEFT", 183, -y)
    row.input:SetSize(235, 21)
    row.input:SetAutoFocus(false)
    row.input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    row.input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    row.choice = button(window.body, 243, "", function(self)
        local choices = row.choices
        if choices == "toggle" then row.value = not row.value
        else
            for index, option in ipairs(choices) do
                if option == row.value then row.value = choices[index % #choices + 1] break end
            end
        end
        self:SetText(display(row.value))
    end)
    row.choice:SetPoint("TOPLEFT", 177, -y)
    rows[i] = row
    return row
end

local function currentPage()
    if page > 1 then
        local fields = advanced and {profileFields[3], profileFields[4], profileFields[5]}
            or {profileFields[1], profileFields[2]}
        return fields, draft.profiles[page - 1]
    end
    if advanced then
        return {appearance[4], appearance[5], appearance[6], appearance[7]}, draft
    end
    return {appearance[1], appearance[2], appearance[3], appearance[8], behavior[1], behavior[6], behavior[7],
        appearance[9], appearance[10], behavior[2], behavior[3], behavior[4], behavior[5]}, draft
end

local function capture()
    local fields, target = currentPage()
    for i, field in ipairs(fields) do
        local row = rows[i]
        local raw = row.value
        if row.input:IsShown() then raw = row.input:GetText() end
        local value, problem = decode(field, raw)
        if value == nil then
            window.message:SetText(field[2] .. ": " .. problem)
            row.input:SetFocus()
            return false
        end
        target[field[1]] = value
    end
    return true
end

local choices = { "Leave alone", "Turn on", "Turn off" }

local function pickAt(i)
    if picks[i] then return picks[i] end
    local pick = CreateFrame("Frame", nil, window.body)
    pick:SetSize(425, 28)
    pick:SetPoint("TOPLEFT", 3, -93 - (i - 1) * 30)
    pick.icon = pick:CreateTexture(nil, "ARTWORK")
    pick.icon:SetSize(21, 21)
    pick.icon:SetPoint("LEFT")
    pick.name = textAt(pick, "GameFontHighlightSmall", 26, 6)
    pick.name:SetWidth(117)
    pick.name:SetWordWrap(false)
    pick.buttons = {}
    for k, caption in ipairs(choices) do
        local b = button(pick, 88, caption, function()
            local profile = draft.profiles[page - 1]
            local enabled
            if k ~= 1 then enabled = k == 2 end
            F.setAbility(profile, pick.ability, enabled)
            F.refreshPicker(F.readPet())
        end)
        b:SetPoint("LEFT", 149 + (k - 1) * 91, 0)
        pick.buttons[k] = b
    end
    picks[i] = pick
    return pick
end

function F.refreshPicker(state)
    if not window or not window:IsShown() or page == 1 or advanced then return end
    local profile = draft.profiles[page - 1]
    local stance = rows[2]
    stance.choices = {}
    for _, option in ipairs(profileFields[2][3]) do
        if not next(state.slots) or state.slots[option] or option == stance.value then
            table.insert(stance.choices, option)
        end
    end
    local abilities = F.abilityRows(state, {profile})
    window.pickerHeading:SetText(#abilities > 0 and "Ability autocast" or "Place a pet ability on the pet bar to configure autocast.")
    for i, ability in ipairs(abilities) do
        local pick = pickAt(i)
        pick.ability = ability
        pick.name:SetText(ability.name)
        pick.name:SetTextColor(1, ability.spell and 1 or 0.78, ability.spell and 1 or 0.4)
        pick.icon:SetTexture(ability.spell and ability.spell.icon or C_Spell.GetSpellTexture(ability.id) or 134400)
        local rules = ability.rules[profile]
        local selected = 1
        if rules then
            selected = rules[1].on and 2 or 3
            for _, rule in ipairs(rules) do
                if rule.on ~= rules[1].on then selected = 0 end
            end
        end
        for index, b in ipairs(pick.buttons) do
            b:SetEnabled(index ~= selected)
            b:SetText(index == selected and ("|cffffd274" .. choices[index] .. "|r") or choices[index])
        end
        pick:Show()
    end
    for i = #abilities + 1, #picks do picks[i]:Hide() end
    window.body:SetHeight(100 + #abilities * 30)
end

local function showTabs()
    local count = 1 + #draft.profiles
    for i = 1, count do
        if not tabs[i] then
            tabs[i] = button(window, 103, "", function() selectPage(i, false) end)
        end
        local p = draft.profiles[i - 1]
        local name = p and p.label or "Panel"
        if name == "Solo Mode" then name = "Solo" elseif name == "Dungeon Mode" then name = "Dungeon" end
        local tab = tabs[i]
        tab:SetText(i == page and ("|cffffd274" .. name .. "|r") or name)
        tab:ClearAllPoints()
        tab:SetPoint("TOPLEFT", 15 + (i - 1) % 4 * 107, -43 - math.floor((i - 1) / 4) * 25)
        tab:SetEnabled(i ~= page or advanced)
        tab:Show()
    end
    for i = count + 1, #tabs do tabs[i]:Hide() end
    local y = 43 + math.ceil(count / 4) * 25 + 10
    window.scroll:ClearAllPoints()
    window.scroll:SetPoint("TOPLEFT", 15, -y)
    window.scroll:SetPoint("BOTTOMRIGHT", -35, 73)
end

render = function()
    local fields, target = currentPage()
    window.message:SetText("")
    showTabs()
    window.advanced:SetText(advanced and "Basic" or "Advanced")
    window.scroll:SetVerticalScroll(0)
    for _, row in ipairs(rows) do
        row.title:Hide()
        row.choice:Hide()
        row.input:ClearFocus()
        row.input:Hide()
    end
    for _, pick in ipairs(picks) do pick:Hide() end
    local state = F.readPet()
    for i, field in ipairs(fields) do
        local row = rowAt(i)
        local key, kind = field[1], field[3]
        row.title:SetText(field[2])
        row.title:Show()
        row.value, row.choices = target[key], kind
        if kind == "toggle" or type(kind) == "table" then
            row.input:Hide()
            row.choice:SetText(display(row.value))
            row.choice:Show()
        else
            row.choice:Hide()
            row.input:SetText(key == "rules" and F.rulesText(row.value) or tostring(row.value))
            row.input:SetCursorPosition(0)
            row.input:Show()
        end
    end
    window.body:SetHeight(#fields * 29 + 6)
    window.pickerHeading:SetShown(page > 1 and not advanced)
    F.refreshPicker(state)
end

selectPage = function(nextPage, showAdvanced)
    if not capture() then return end
    page, advanced = nextPage, showAdvanced
    render()
end

local function build()
    window = CreateFrame("Frame", "ForeverPetModesSettings", UIParent, "BackdropTemplate")
    window:SetSize(476, 448)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:EnableMouse(true)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    window:SetBackdropColor(0.06, 0.055, 0.05, 0.98)
    window:SetBackdropBorderColor(0.55, 0.45, 0.28)
    textAt(window, "GameFontNormalLarge", 18, 14):SetText("Forever Pet Modes")
    window.advanced = button(window, 85, "Advanced", function() selectPage(page, not advanced) end)
    window.advanced:SetPoint("TOPRIGHT", -15, -9)
    window.scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    window.body = CreateFrame("Frame", nil, window.scroll)
    window.body:SetSize(426, 1)
    window.scroll:SetScrollChild(window.body)
    window.pickerHeading = textAt(window.body, "GameFontNormal", 4, 68)
    window.message = textAt(window, "GameFontHighlightSmall", 16, 382)
    window.message:SetWidth(443)
    button(window, 128, "Reset to defaults", function()
        draft, page, advanced = F.copy(F.defaults), 1, false
        render()
        window.message:SetText("Defaults are staged. Save to apply or Cancel to keep your settings.")
    end):SetPoint("BOTTOMLEFT", 15, 13)
    button(window, 72, "Cancel", function() window:Hide() end):SetPoint("BOTTOMRIGHT", -95, 13)
    button(window, 72, "Save", function()
        if not capture() then return end
        local state = F.readPet()
        for i, profile in ipairs(draft.profiles) do
            if F.rulesText(profile.rules) ~= F.rulesText(F.db.profiles[i] and F.db.profiles[i].rules or {}) then
                local _, problem, kind = F.macro(profile, state)
                if kind == "rules" then
                    page, advanced = i + 1, false
                    render()
                    window.message:SetText(problem)
                    return
                end
            end
        end
        if F.applySettings(draft) then window:Hide()
        else window.message:SetText("Save your edits after combat.") end
    end):SetPoint("BOTTOMRIGHT", -15, 13)
    UISpecialFrames[#UISpecialFrames + 1] = "ForeverPetModesSettings"
end

function F.saveMinimapAngle(angle)
    F.db.minimapAngle = angle
    if window and window:IsShown() then draft.minimapAngle = angle end
end

function F.openSettings()
    if not window then build()
    elseif window:IsShown() then window:Hide() return end
    page, advanced, draft = 1, false, F.copy(F.db)
    window:Show()
    render()
end
