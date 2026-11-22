local addon, F = ...
local events = CreateFrame("Frame")
local queued = false

function F.say(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd277Forever Pet Modes|r  " .. text)
end

function F.refresh()
    local state = F.readPet()
    if F.panel then F.paint(state) end
    return state
end

function F.applySettings(db)
    if InCombatLockdown() then return false end
    F.clickSerial = (F.clickSerial or 0) + 1
    F.pending, F.failedProfile = nil, nil
    F.db, ForeverPetModesDB = db, db
    F.layout()
    F.refresh()
    return true
end

local function start()
    if InCombatLockdown() then return end
    if not F.panel then F.createPanel() end
    F.layout()
    F.refresh()
end

local function refreshSoon()
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        F.refresh()
    end)
end

local function command(message)
    if message:lower():match("^%s*status%s*$") then
        local s = F.refresh()
        local version, build, _, toc = GetBuildInfo()
        F.say(version .. "." .. build .. " / interface " .. toc)
        if s.reason then F.say(s.reason) return end
        F.say("Stance: " .. (s.stance or "unknown"))
        for _, a in ipairs(s.abilities) do
            F.say(a.name .. " (" .. a.id .. ") " .. (a.on and "ON" or "OFF"))
        end
        for _, p in ipairs(F.db.profiles) do
            local diff = F.differences(p, s)
            F.say(p.label .. ": " .. (#diff == 0 and "active" or table.concat(diff, " ")))
        end
    elseif InCombatLockdown() then
        F.say("Open settings after combat. /fpm status shows current pet information.")
    else
        F.openSettings()
    end
end

events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, unit)
    if event == "ADDON_LOADED" then
        if unit ~= addon then return end
        self:UnregisterEvent(event)
        F.db = F.loadSettings(ForeverPetModesDB)
        ForeverPetModesDB = F.db
        SLASH_FOREVERPETMODES1 = "/fpm"
        SlashCmdList.FOREVERPETMODES = command
        for _, name in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
            "PLAYER_REGEN_DISABLED", "UNIT_PET", "UNIT_FLAGS", "UNIT_HEALTH", "PET_BAR_UPDATE",
            "PET_UI_UPDATE", "PET_BAR_UPDATE_COOLDOWN", "PET_BAR_UPDATE_USABLE", "ZONE_CHANGED_NEW_AREA", "SPELLS_CHANGED",
            "UPDATE_VEHICLE_ACTIONBAR", "PLAYER_CONTROL_GAINED", "PLAYER_CONTROL_LOST" }) do
            if name == "UNIT_HEALTH" or name == "UNIT_FLAGS" then self:RegisterUnitEvent(name, "pet")
            else self:RegisterEvent(name) end
        end
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_REGEN_ENABLED" then
        start()
    elseif event == "UNIT_PET" and unit ~= "player" then
        return
    elseif F.panel then
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then F.visibility() end
        refreshSoon()
    end
end)
