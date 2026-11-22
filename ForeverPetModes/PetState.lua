local _, F = ...

local tokens = {
    PET_MODE_DEFENSIVE = "Defensive", PET_ACTION_DEFENSIVE = "Defensive",
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

local function unavailable(message)
    return { reason = message, slots = {}, abilities = {} }
end

function F.readPet()
    local exists = UnitExists("pet")
    if secret(exists) then return unavailable("Pet state is restricted.") end
    if not exists then return unavailable("Summon a pet.") end
    local dead, bar = UnitIsDeadOrGhost("pet"), PetHasActionBar()
    if secret(dead, bar) then return unavailable("Pet state is restricted.") end
    if dead then return unavailable("Revive your pet.") end
    if not bar then return unavailable("The pet action bar is unavailable.") end

    local state = { slots = {}, abilities = {} }
    for slot = 1, (NUM_PET_ACTION_SLOTS or 10) do
        local name, icon, token, active, allowed, enabled, id = GetPetActionInfo(slot)
        if secret(name, icon, token, active, allowed, enabled, id) then
            return unavailable("Pet bar information is restricted.")
        end
        if token then
            local stance = tokens[name] or tokens[icon]
            if stance then
                state.slots[stance] = slot
                if active then
                    if state.stance and state.stance ~= stance then
                        return unavailable("Pet stance is changing.")
                    end
                    state.stance = stance
                end
            end
        elseif allowed and type(id) == "number" and type(name) == "string" then
            state.abilities[#state.abilities + 1] = {
                id = id, name = name, on = enabled == true or enabled == 1,
            }
        end
    end
    return state
end

function F.resolve(state, id)
    for _, spell in ipairs(state.abilities) do
        if spell.id == id then return spell end
    end
    -- Configured rank and trained rank may have different IDs but one localized name.
    local name = C_Spell.GetSpellName(id)
    if secret(name) or not name then return end
    for _, spell in ipairs(state.abilities) do
        if spell.name == name then return spell end
    end
end
