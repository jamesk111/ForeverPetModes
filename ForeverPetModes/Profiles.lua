local _, F = ...

function F.differences(profile, state)
    if state.reason then return { state.reason } end
    local missing = {}
    if state.stance ~= profile.stance then
        missing[#missing + 1] = "Stance is " .. (state.stance or "unknown") .. " (needs " .. profile.stance .. ")."
    end
    for _, rule in ipairs(profile.rules) do
        local spell = F.resolve(state, rule.id)
        if not spell then
            missing[#missing + 1] = "Place an autocastable pet ability for spell ID " .. rule.id .. " on the pet bar."
        elseif spell.on ~= rule.on then
            local setting = rule.on and "ON" or "OFF"
            missing[#missing + 1] = spell.name .. " is " .. (spell.on and "ON" or "OFF") .. " (needs " .. setting .. ")."
        end
    end
    return missing
end

-- Both views use the same identity for configured ranks and the live pet spell.
function F.abilityRows(state, profiles, pins)
    local rows, byID = {}, {}
    local growl = F.resolve(state, 2649)
    local growlID = growl and growl.id or 2649
    local function add(id, name, spell)
        if not byID[id] then
            local row = { id = id, name = name, spell = spell, rules = {} }
            rows[#rows + 1] = row
            byID[id] = row
        end
        return byID[id]
    end
    for _, spell in ipairs(state.abilities) do add(spell.id, spell.name, spell) end
    for id in pairs(pins or {}) do
        local spell = F.resolve(state, id)
        local row = add(spell and spell.id or id, spell and spell.name or F.abilityName(id) or ("Spell " .. id), spell)
        row.pins = row.pins or {}
        row.pins[#row.pins + 1] = id
    end
    for _, profile in ipairs(profiles) do
        for _, rule in ipairs(profile.rules) do
            local spell = F.resolve(state, rule.id)
            local id = spell and spell.id or rule.id
            local name = spell and spell.name or F.abilityName(id) or ("Spell " .. id)
            local row = add(id, name, spell)
            local rules = row.rules[profile] or {}
            rules[#rules + 1] = rule
            row.rules[profile] = rules
        end
    end
    if byID[growlID] then byID[growlID].growl = true end
    table.sort(rows, function(a, b)
        if a.id == growlID or b.id == growlID then return a.id == growlID and b.id ~= growlID end
        if a.name == b.name then return a.id < b.id end
        return a.name < b.name
    end)
    return rows
end

function F.indicatorRows(state)
    local rows = F.abilityRows(state, F.db.profiles, F.db.pinnedAbilities)
    if F.db.indicatorMode == "Pinned abilities" then
        for i = #rows, 1, -1 do
            if not rows[i].growl and not rows[i].pins then table.remove(rows, i) end
        end
    end
    return rows
end

function F.matchesProfile(profile, state)
    return (not F.pending or F.pending == profile) and #F.differences(profile, state) == 0
end

function F.setAbility(profile, row, enabled)
    local previous = row.rules[profile] or {}
    local id = previous[1] and previous[1].id or row.id
    for i = #profile.rules, 1, -1 do
        for _, rule in ipairs(previous) do
            if profile.rules[i] == rule then table.remove(profile.rules, i) break end
        end
    end
    if enabled ~= nil then profile.rules[#profile.rules + 1] = { id = id, on = enabled } end
end

function F.rulesText(rules)
    local parts = {}
    for _, rule in ipairs(rules) do
        parts[#parts + 1] = rule.id .. "=" .. (rule.on and "on" or "off")
    end
    return table.concat(parts, ", ")
end

function F.parseRules(text)
    local rules, used = {}, {}
    if text:match("^%s*$") then return rules end
    for item in (text .. ","):gmatch("(.-),") do
        local number, value = item:match("^%s*(%d+)%s*=%s*(%a+)%s*$")
        local id = tonumber(number)
        if not id or id < 1 or id > 2147483647 or used[id] or (value ~= "on" and value ~= "off") then
            return nil, "Use unique spell IDs, for example 2649=on, 17253=off."
        end
        used[id] = true
        rules[#rules + 1] = { id = id, on = value == "on" }
    end
    return rules
end
