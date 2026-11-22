local _, F = ...

function F.differences(profile, state)
    if state.reason then return { state.reason } end
    local missing = {}
    if state.stance ~= profile.stance then
        missing[#missing + 1] = "Select " .. profile.stance .. " on the pet bar."
    end
    for _, rule in ipairs(profile.rules) do
        local spell = F.resolve(state, rule.id)
        if not spell then
            missing[#missing + 1] = "Place an autocastable pet ability for spell ID " .. rule.id .. " on the pet bar."
        elseif spell.on ~= rule.on then
            local setting = rule.on and "ON" or "OFF"
            missing[#missing + 1] = "Right-click " .. spell.name .. " on the pet bar to turn autocast " .. setting .. "."
        end
    end
    return missing
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
