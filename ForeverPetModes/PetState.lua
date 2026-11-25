local _, F = ...

local tokens = {
    PET_MODE_DEFENSIVE = "Defensive", PET_ACTION_DEFENSIVE = "Defensive",
    -- Forever's native button labeled Defensive uses the DefensiveAssist token.
    PET_MODE_DEFENSIVEASSIST = "Defensive", PET_DEFENSIVEASSIST_TEXTURE = "Defensive",
    PET_MODE_ASSIST = "Assist", PET_ASSIST_TEXTURE = "Assist",
    PET_MODE_PASSIVE = "Passive", PET_ACTION_MODE_PASSIVE = "Passive",
    PET_MODE_AGGRESSIVE = "Aggressive", PET_ACTION_AGGRESSIVE = "Aggressive",
    PET_DEFENSIVE_TEXTURE = "Defensive", PET_PASSIVE_TEXTURE = "Passive",
    PET_AGGRESSIVE_TEXTURE = "Aggressive",
}

local function secret(...)
    if not issecretvalue then return false end
    for index = 1, select("#", ...) do
        if issecretvalue((select(index, ...))) then return true end
    end
    return false
end

local function flagged(value)
    return value == true or value == 1
end

local commandTokens = {
    PET_ACTION_ATTACK="attack", PET_ATTACK_TEXTURE="attack",
    PET_ACTION_FOLLOW="follow", PET_FOLLOW_TEXTURE="follow",
    PET_ACTION_WAIT="stay", PET_ACTION_STAY="stay", PET_WAIT_TEXTURE="stay",
}

local function unavailable(message)
    return { reason = message, slots = {}, abilities = {} }
end

local moods = {
    { label = PET_HAPPINESS1 or "Unhappy", atlas = "UI-PetMad" },
    { label = PET_HAPPINESS2 or "Content", atlas = "UI-PetNeutral" },
    { label = PET_HAPPINESS3 or "Happy", atlas = "UI-PetHappiness" },
}

local function readHappiness()
    if not (C_PetInfo and C_PetInfo.GetPetHappiness and HasPetUI) then return end
    local _, hunterPet = HasPetUI()
    if secret(hunterPet) or not hunterPet then return end
    local level = C_PetInfo.GetPetHappiness()
    if not secret(level) then return moods[level] end
end

function F.readPet()
    local exists = UnitExists("pet")
    if secret(exists) then return unavailable("Pet state is restricted.") end
    if not exists then return unavailable("Summon a pet.") end
    local dead, bar = UnitIsDeadOrGhost("pet"), PetHasActionBar()
    if secret(dead, bar) then return unavailable("Pet state is restricted.") end
    if dead then return unavailable("Revive your pet.") end
    if not bar then return unavailable("The pet action bar is unavailable.") end

    local state = { slots = {}, abilities = {}, happiness = readHappiness(), commandKeys = {}, commandSlots = {} }
    for slot = 1, (NUM_PET_ACTION_SLOTS or 10) do
        local name, icon, token, active, allowed, enabled, id = GetPetActionInfo(slot)
        if secret(name, icon, token, active, allowed, enabled, id) then
            return unavailable("Pet bar information is restricted.")
        end
        if flagged(token) then
            local command = commandTokens[name] or commandTokens[icon]
            if command and not state.commandKeys[command] then
                local key = GetBindingKey("BONUSACTIONBUTTON" .. slot)
                state.commandSlots[command] = state.commandSlots[command] or slot
                if not secret(key) and key ~= "" then state.commandKeys[command] = key end
                if state.commandKeys[command] then state.commandSlots[command] = slot end
            end
            local stance = tokens[name] or tokens[icon]
            if stance then
                state.slots[stance] = slot
                if flagged(active) then
                    if state.stance and state.stance ~= stance then
                        return unavailable("Pet stance is changing.")
                    end
                    state.stance = stance
                end
            end
        elseif flagged(allowed) and type(id) == "number" and type(name) == "string" then
            state.abilities[#state.abilities + 1] = {
                id = id, name = name, icon = icon, on = flagged(enabled),
            }
        end
    end
    return state
end

function F.abilityName(id)
    local name = C_Spell.GetSpellName(id)
    if not secret(name) then return name end
end

local function readable(value)
    if not secret(value) then return value end
end

function F.readPetIdentity()
    if not readable(UnitExists("pet")) then return end
    local name = readable(UnitName("pet"))
    local level = readable(UnitLevel("pet"))
    return name, level and level > 0 and level or nil
end

function F.readPetHealth()
    if not readable(UnitExists("pet")) then return end
    return readable(UnitHealth("pet")), readable(UnitHealthMax("pet"))
end

function F.readPetDetails()
    local details = {}
    if not readable(UnitExists("pet")) then return details end
    details.name, details.level = F.readPetIdentity()
    details.family = readable(UnitCreatureFamily("pet"))
    details.health, details.maxHealth = F.readPetHealth()
    local powerType, token = UnitPowerType("pet")
    if not secret(powerType, token) and type(token) == "string" then
        details.resource = _G[token] or token
        details.power = readable(UnitPower("pet", powerType))
        details.maxPower = readable(UnitPowerMax("pet", powerType))
    end
    local _, hunter = HasPetUI()
    if secret(hunter) or not hunter or not C_PetInfo then return details end
    if C_PetInfo.GetPetLoyalty then details.loyalty = readable(C_PetInfo.GetPetLoyalty()) end
    if C_PetInfo.GetPetFoodTypes then
        local foods = readable(C_PetInfo.GetPetFoodTypes())
        local names = {}
        if type(foods) == "table" then
            for _, name in ipairs(foods) do
                if not secret(name) and type(name) == "string" then names[#names + 1] = name end
            end
        end
        if #names > 0 then details.diet = table.concat(names, ", ") end
    end
    return details
end

function F.resolve(state, id)
    for _, spell in ipairs(state.abilities) do
        if spell.id == id then return spell end
    end
    -- Configured rank and trained rank may have different IDs but one localized name.
    local name = F.abilityName(id)
    if not name then return end
    for _, spell in ipairs(state.abilities) do
        if spell.name == name then return spell end
    end
end
