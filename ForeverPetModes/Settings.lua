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
}
local profileFields = {
    { "label", "Button label", "label" }, { "stance", "Pet stance", { "Defensive", "Passive", "Aggressive" } },
    { "color", "Active color (hex)", "color" }, { "icon", "Icon file ID", 1, 2147483647 },
    { "rules", "Autocast rules", "rules" },
}
local window, page, draft
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
    local y = 83 + (i - 1) * 28
    local row = { title = textAt(window, "GameFontHighlight", 18, y + 4) }
    row.input = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    row.input:SetPoint("TOPLEFT", 189, -y)
    row.input:SetSize(202, 21)
    row.input:SetAutoFocus(false)
    row.input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    row.input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    row.choice = button(window, 205, "", function(self)
        local choices = row.field[3]
        if choices == "toggle" then row.value = not row.value
        else
            for index, option in ipairs(choices) do
                if option == row.value then row.value = choices[index % #choices + 1] break end
            end
        end
        self:SetText(display(row.value))
    end)
    row.choice:SetPoint("TOPLEFT", 183, -y)
    row.input:Hide()
    row.choice:Hide()
    rows[i] = row
    return row
end

local function currentPage()
    if page == 1 then return "Appearance", appearance, draft end
    if page == 2 then return "Behavior", behavior, draft end
    local profile = draft.profiles[page - 2]
    return profile.label, profileFields, profile
end

local function render()
    local title, fields, target = currentPage()
    window.heading:SetText(title)
    window.message:SetText(page > 2 and "Autocast rules use spell IDs, e.g. 2649=on. Separate rules with commas. Use /fpm status to list pet bar IDs." or
        (page == 1 and "Use zero opacity to hide the background. Drag the title or outer edge to move the panel." or
        "Profiles apply on an unmodified click outside combat. Instance visibility updates after combat if needed."))
    for _, row in ipairs(rows) do
        row.title:Hide()
        row.choice:Hide()
        row.input:ClearFocus()
        row.input:Hide()
    end
    for i, field in ipairs(fields) do
        local row = rowAt(i)
        row.field = field
        row.title:SetText(field[2])
        row.title:Show()
        local v = target[field[1]]
        if field[3] == "toggle" or type(field[3]) == "table" then
            row.value = v
            row.choice:SetText(display(v))
            row.choice:Show()
        else
            row.input:SetText(field[1] == "rules" and F.rulesText(v) or tostring(v))
            row.input:SetCursorPosition(0)
            row.input:Show()
        end
    end
end

local function capture()
    local _, fields, target = currentPage()
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

local function turn(delta)
    if capture() then
        page = (page - 1 + delta) % (#draft.profiles + 2) + 1
        render()
    end
end

local function build()
    window = CreateFrame("Frame", "ForeverPetModesSettings", UIParent, "BackdropTemplate")
    window:SetSize(412, 460)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:EnableMouse(true)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    window:SetBackdropColor(0.06, 0.055, 0.05, 0.98)
    window:SetBackdropBorderColor(0.55, 0.45, 0.28)
    textAt(window, "GameFontNormalLarge", 18, 14):SetText("Forever Pet Modes")
    window.heading = textAt(window, "GameFontNormal", 53, 52)
    window.message = textAt(window, "GameFontHighlightSmall", 18, 373)
    window.message:SetWidth(378)
    button(window, 25, "<", function() turn(-1) end):SetPoint("TOPLEFT", 17, -46)
    button(window, 25, ">", function() turn(1) end):SetPoint("TOPRIGHT", -18, -46)
    button(window, 128, "Reset to defaults", function()
        draft, page = F.copy(F.defaults), 1
        render()
        window.message:SetText("Default settings and position are staged. Click Save to apply or Cancel to keep your settings.")
    end):SetPoint("BOTTOMLEFT", 15, 13)
    button(window, 72, "Cancel", function() window:Hide() end):SetPoint("BOTTOMRIGHT", -95, 13)
    button(window, 72, "Save", function()
        if not capture() then return end
        if F.applySettings(draft) then window:Hide()
        else window.message:SetText("Combat lockdown. Save your edits after combat.") end
    end):SetPoint("BOTTOMRIGHT", -15, 13)
    UISpecialFrames[#UISpecialFrames + 1] = "ForeverPetModesSettings"
end

function F.openSettings()
    if not window then build()
    elseif window:IsShown() then window:Hide() return end
    page, draft = 1, F.copy(F.db)
    window:Show()
    render()
end
