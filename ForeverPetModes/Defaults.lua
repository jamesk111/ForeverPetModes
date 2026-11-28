local _, F = ...

-- Shared panel dimensions in UI units. Profile button spacing is user configurable.
F.panelMetrics = { padding = 8, gap = 4, dividerWidth = 22, moodSize = 24, petNameWidth = 102, levelWidth = 38, chipHeight = 18, careHeight = 24 }
F.panelMetrics.gripSize = 16
F.panelMetrics.moveGutter = 20

F.defaults = {
    width = 100, height = 32, scale = 1, spacing = 4, border = 2,
    columnWidth = 0, minPanelHeight = 0,
    opacity = 0.78, inactive = "343638", vertical = false, locked = false,
    title = true, icons = false, hideNoPet = false, hideCombat = false,
    huntersOnly = true, showMinimap = false, panelToggleClick = "Left-click", minimapAngle = 225, panelHidden = false,
    indicatorMode = "All abilities", skillDisplay = "Icon and name", pinnedAbilities = {}, showHappiness = true, showRecall = true, showCare = true,
    petControlsCollapsed = false, showHawks = true, hawkPosition = {}, nextProfileID = 1,
    instance = "any", sound = false,
    position = { point = "CENTER", relative = "CENTER", x = 0, y = -135 },
    profiles = {
        { label = "Solo Mode", stance = "Defensive", color = "237440", favorite = "1",
          icon = 132110, rules = { { id = 2649, on = true } } },
        { label = "Dungeon Mode", stance = "Passive", color = "245FA1", favorite = "2",
          icon = 132311, rules = { { id = 2649, on = false } } },
    },
}

function F.copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = F.copy(item) end
    return result
end

function F.mergeSettings(saved)
    local db = F.copy(F.defaults)
    if type(saved) == "table" then
        for key, default in pairs(F.defaults) do
            if type(saved[key]) == type(default) then db[key] = F.copy(saved[key]) end
        end
    end
    return db
end

function F.rgb(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255,
        tonumber(hex:sub(5, 6), 16) / 255
end
