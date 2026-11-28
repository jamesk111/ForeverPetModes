-- Run from the repository root with Lua 5.1. These fixtures do not execute WoW macros.
local F, count = {}, 0
local slots, exists, dead, combat, bar, inside, secret = {}, true, false, false, true, false, {}
local frames, callbacks, chat = {}, {}, {}
local playerClass, cursorX, cursorY, mapShape = "HUNTER", 0, 0, "ROUND"
local strict = { SetAttribute=true, SetSize=true, SetPoint=true, ClearAllPoints=true, SetScale=true,
    StartMoving=true, StopMovingOrSizing=true, Show=true, Hide=true }
local methods = {}
local uiScale, unitsPerPixel = 1, 1
function methods:SetScale(scale) assert(not (combat and self.protected)) self.scale = scale end
function methods:GetEffectiveScale() return (self.scale or 1) * uiScale end
PixelUtil = { GetNearestPixelSize=function(size, scale, minimum)
    return math.max(minimum, math.floor(size * scale / unitsPerPixel + 0.5)) * unitsPerPixel / scale
end }
local function widget(kind, parent, template)
    local w = { kind=kind, template=template, parent=parent, scripts={}, attributes={}, shown=true }
    return setmetatable(w, { __index=function(_, name)
        if methods[name] then return methods[name] end
        if not name:match("^%u") then return nil end
        return function(self)
            if combat and self.protected and strict[name] then error("lockdown: " .. name) end
        end
    end })
end
function CreateFrame(kind, name, parent, template)
    local w = widget(kind, parent, template)
    w.globalName = name
    w.protected = template == "InsecureActionButtonTemplate" or template == "SecureHandlerStateTemplate"
        or (template and template:find("SecureActionButtonTemplate", 1, true) ~= nil)
    assert(not (combat and w.protected))
    frames[#frames+1] = w
    return w
end
function methods:CreateMaskTexture() return widget("MaskTexture", self) end
function methods:SetPoint(...) self.lastPoint = {...} end
function methods:SetSize(w, h)
    assert(not (combat and self.protected))
    self.layoutWidth, self.layoutHeight = w, h
end
function methods:HookScript(name, callback) self.scripts[name] = callback end
function methods:CreateTexture() return widget("Texture", self) end
function methods:CreateLine() return widget("Line", self) end
function methods:GetStatusBarTexture() return widget("Texture", self) end
function methods:SetAtlas(atlas) self.atlas = atlas end
function methods:SetRotation(angle) self.rotation = angle end
function methods:CreateFontString()
    local font = widget("FontString", self)
    self.fonts = self.fonts or {}
    table.insert(self.fonts, font)
    return font
end
function methods:SetText(v) self.textValue = v end
function methods:SetHeight(v) self.layoutHeight = v end
function methods:SetValue(v) self.value = v end
function methods:SetMinMaxValues(lo, hi) self.minimum, self.maximum = lo, hi end
function methods:SetWidth(v) self.layoutWidth = v end
function methods:GetText() return self.textValue end
function methods:GetStringHeight() return 12 end
function methods:GetUnboundedStringWidth() return #(self.textValue:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) * 6 end
function methods:SetEnabled(on) self.enabled = on end
GameTooltip = widget("Tooltip")
function methods:Show() assert(not (combat and self.protected)) self.shown = true end
function methods:Hide() assert(not (combat and self.protected)) self.shown = false end
function methods:SetShown(v) self.shown = v end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or not self.parent.IsVisible or self.parent:IsVisible()) end
function methods:SetScript(k, f) self.scripts[k] = f end
function methods:SetAttribute(k, v) assert(not combat) self.attributes[k] = v end
function methods:GetParent() return self.parent end
function methods:GetScript(kind) return self.scripts[kind] end
function methods:GetPoint() return "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 120, 140 end
function RegisterStateDriver(w, _, cond) assert(not combat) w.condition = cond end
function UnitClass() return "Localized class name", playerClass end
function GetCursorPosition() return cursorX, cursorY end
local hawkTime, summons = 100, {}
function GetTime() return hawkTime end
function GetNumTotemSlots() return 4 end
function GetTotemInfo(slot) return unpack(summons[slot] or {false}, 1, 7) end
function GetTotemTimeLeft(slot) return summons[slot][3] + summons[slot][4] - hawkTime end
function GetMinimapShape() return mapShape end
Minimap = widget("Minimap")
function Minimap:GetCenter() return 300, 200 end
function Minimap:GetWidth() return 160 end
function Minimap:GetHeight() return 160 end
function Minimap:GetEffectiveScale() return 2 end
function Minimap:GetFrameLevel() return 4 end
function UnitExists() return exists end
function UnitName() return "Ash" end
function UnitLevel() return 32 end
function UnitCreatureFamily() return "Cat" end
function UnitHealth() return 334 end
function UnitHealthMax() return 500 end
function UnitHealthPercent() return 0.668 end
function UnitPowerType() return 2, "FOCUS" end
function UnitPower() return 65 end
function UnitPowerMax() return 100 end
FOCUS = "Focus"
function UnitIsDeadOrGhost() return dead end
function PetHasActionBar() return bar end
function GetBindingKey() return nil end
C_SpellBook = {IsSpellKnown=function() return false end, FindSpellBookSlotForSpell=function() return nil end}
function GetPetActionInfo(i) return unpack(slots[i] or {}, 1, 7) end
function InCombatLockdown() return combat end
function IsInInstance() return inside end
function IsModifierKeyDown() return false end
function issecretvalue(v) return v == secret end
local metadataVersion = "0.0.0-test"
C_AddOns = { GetAddOnMetadata = function(name, field)
    assert(name == "ForeverPetModes" and field == "Version")
    return metadataVersion
end }
function GetBuildInfo() return "1.60.1", "71037", "", 16001 end
C_Spell = { GetSpellTexture=function() return 134400 end, GetSpellName=function(id) if id == 2649 then return "Knurren" elseif id == 17253 then return "Bite" end end }
C_Timer = { After=function(_, fn) callbacks[#callbacks+1] = fn end }
DEFAULT_CHAT_FRAME = { AddMessage=function(_, msg) chat[#chat+1] = msg end }
UIParent, SlashCmdList, UISpecialFrames, NUM_PET_ACTION_SLOTS = {}, {}, {}, 10
Enum = { ForbiddenAspect = { ScriptedInput = 1 } }
local nativeButton = { IsForbidden = function() return false end, IsObjectType = function() return true end,
    HasAccessConstraints = function() return false end, HasAnyForbiddenAspects = function() return false end }
for slot = 1, 10 do _G["PetActionButton" .. slot] = nativeButton end
local function flush()
    local pending = callbacks
    callbacks = {}
    for _, fn in ipairs(pending) do fn() end
end
local function test(name, fn)
    fn()
    count = count + 1
    print("ok " .. count .. " - " .. name)
end
for line in io.lines("ForeverPetModes/ForeverPetModes.toc") do
    local file = line:match("^([%w]+%.lua)")
    if file then assert(loadfile("ForeverPetModes/" .. file))("ForeverPetModes", F) end
end
local eventFrame = frames[1]
local function event(name, unit) eventFrame.scripts.OnEvent(eventFrame, name, unit) end
slots[5] = { "PET_MODE_DEFENSIVE", nil, true, true }
slots[10] = { "PET_MODE_PASSIVE", nil, true, false }
slots[4] = { "Knurren", nil, false, false, true, true, 14916 }
local solo, dungeon, soloButton, dungeonButton
test("a non-Hunter with a live pet starts with both addon surfaces hidden", function()
    playerClass = "WARLOCK"
    event("ADDON_LOADED", "ForeverPetModes")
    event("PLAYER_LOGIN")
    assert(F.db.huntersOnly and not F.db.showMinimap and not F.panel and not F.minimapButton)
    event("UNIT_PET", "player")
    assert(#callbacks == 0 and SlashCmdList.FOREVERPETMODES)
    playerClass = "HUNTER"
end)
test("login builds profiles and matches a localized higher rank", function()
    event("PLAYER_LOGIN")
    solo, dungeon = unpack(F.db.profiles)
    for _, w in ipairs(frames) do
        if w.profile == solo then soloButton = w end
        if w.profile == dungeon then dungeonButton = w end
    end
    assert(soloButton.mark.shown and not dungeonButton.mark.shown)
    local macro = soloButton.attributes.macrotext1
    assert(macro == "/click [@pet,exists,nodead,nocombat,nomod] PetActionButton5\n/petautocaston [@pet,exists,nodead,nocombat,nomod] Knurren")
    assert(dungeonButton.attributes.macrotext1:find("/petautocastoff", 1, true))
end)
test("manual partial and complete changes repaint on coalesced events", function()
    slots[4][6] = false
    event("PET_BAR_UPDATE")
    event("PET_UI_UPDATE")
    assert(#callbacks == 1)
    flush()
    assert(not soloButton.mark.shown and not dungeonButton.mark.shown)
    slots[5][4], slots[10][4] = false, true
    event("PET_BAR_UPDATE")
    flush()
    assert(dungeonButton.mark.shown and not soloButton.mark.shown)
end)
test("Forever Defensive shares the DefensiveAssist token and remains distinct from Assist", function()
    local original = slots[5]
    slots[5] = nil
    slots[8] = { "PET_MODE_ASSIST", "PET_ASSIST_TEXTURE", true, false }
    slots[9] = { "PET_MODE_DEFENSIVEASSIST", "PET_DEFENSIVEASSIST_TEXTURE", true, false }
    soloButton.scripts.PreClick(soloButton)
    local text = soloButton.attributes.macrotext1
    assert(text and text:find("PetActionButton9", 1, true), "Solo must bind the live Defensive slot")
    assert(text:find("/petautocaston", 1, true) and text:find("Knurren", 1, true))
    slots[9][4], slots[10][4], slots[4][6] = true, false, true
    assert(#F.differences(solo, F.readPet()) == 0)
    slots[8][4], slots[9][4] = true, false
    assert(F.readPet().stance == "Assist" and #F.differences(solo, F.readPet()) > 0)
    slots[8], slots[9], slots[5], slots[10][4], slots[4][6] = nil, nil, original, true, false
    F.refresh()
end)
test("a rejected switch leaves only actual state on the panel", function()
    soloButton.scripts.PostClick(soloButton)
    assert(not dungeonButton.mark.shown and not soloButton.mark.shown)
    for i = 1, 4 do flush() end
    assert(F.failedProfile == solo and not F.panel.status:GetText():find("Solo Mode", 1, true))
    assert(F.panel.status:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") == "Stance: Passive")
    assert(dungeonButton.mark.shown and not soloButton.mark.shown and #chat == 0)
    flush()
end)
test("Dungeon to Solo clears stale color and tracks late Growl with no extra event", function()
    soloButton.scripts.PostClick(soloButton)
    slots[5][4], slots[10][4] = 1, 0
    flush()
    assert(not soloButton.mark.shown and not dungeonButton.mark.shown)
    assert(F.panel.status:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") == "Stance: Defensive")
    assert(F.panel.chips[1].text:GetText() == "Knurren" and F.panel.chips[1].value:GetText() == "OFF")
    slots[4][6] = 1
    flush()
    assert(soloButton.mark.shown and not dungeonButton.mark.shown)
    assert(F.panel.chips[1].text:GetText() == "Knurren" and F.panel.chips[1].value:GetText() == "ON")
    assert(#chat == 0)
    flush()
    slots[5][4], slots[10][4], slots[4][6] = false, true, false
    F.refresh()
end)
test("new clicks supersede old confirmations and tooltips describe click targets", function()
    soloButton.scripts.PostClick(soloButton)
    dungeonButton.scripts.PostClick(dungeonButton)
    flush()
    assert(not F.pending and dungeonButton.mark.shown and not soloButton.mark.shown)
    GameTooltip = widget("Tooltip")
    local lines = {}
    function GameTooltip:AddLine(line) lines[#lines + 1] = line end
    soloButton.scripts.OnEnter(soloButton)
    local tooltip = table.concat(lines, " ")
    assert(tooltip:find("Click to apply", 1, true) and tooltip:find("Knurren autocast: ON", 1, true))
    assert(not tooltip:find("Right-click") and #chat == 0)
end)
test("live panel lists other autocasts and marks missing Growl unavailable", function()
    local growl = slots[4]
    slots[4] = { "Bite", nil, 0, false, 1, false, 17253 }
    F.refresh()
    assert(F.panel.chips[1].text:GetText() == "Knurren" and F.panel.chips[1].value:GetText() == "Unavailable")
    assert(F.panel.chips[2].text:GetText() == "Bite" and F.panel.chips[2].value:GetText() == "OFF")
    assert(not soloButton.mark.shown and not dungeonButton.mark.shown)
    slots[4] = growl
    F.refresh()
end)
test("bar reordering resolves again immediately before the physical click", function()
    slots[2], slots[5] = slots[5], nil
    soloButton.scripts.PreClick(soloButton)
    assert(soloButton.attributes.macrotext1:find("PetActionButton2", 1, true))
end)
test("summon, dismissal, death, resurrection and pet swaps", function()
    exists = false
    event("UNIT_PET", "player")
    flush()
    assert(not dungeonButton.mark.shown and not dungeonButton.attributes.type1 and dungeonButton.warning.shown)
    exists, dead = true, true
    assert(F.readPet().reason:find("Revive"))
    dead, bar = false, false
    assert(F.readPet().reason)
    bar = true
    assert(#F.differences(dungeon, F.readPet()) == 0)
    local old = slots[4]
    slots[4] = nil
    F.refresh()
    assert(not dungeonButton.attributes.type1 and not dungeonButton.mark.shown)
    slots[4] = old
end)
test("restricted and ambiguous reads clear match and binding", function()
    slots[4][6] = secret
    F.refresh()
    assert(not dungeonButton.mark.shown and dungeonButton.attributes.type1 == nil)
    slots[4][6], slots[2][4] = false, true
    assert(F.readPet().reason)
    slots[2][4] = false
end)
test("combat defers frame changes and emits manual fallback", function()
    combat = true
    event("PLAYER_REGEN_DISABLED")
    flush()
    soloButton.scripts.PreClick(soloButton)
    soloButton.scripts.PostClick(soloButton)
    assert(not F.panel.status:GetText():find("combat", 1, true) and #chat == 0)
    assert(dungeonButton.warning.shown and dungeonButton.mark.shown)
    assert(not F.applySettings(F.copy(F.db)))
    combat = false
    event("PLAYER_REGEN_ENABLED")
end)
test("profile rules handle ignore, duplicates, conflicts and macro length", function()
    assert(#F.parseRules("") == 0)
    assert(not F.parseRules("2649=off,2649=on"))
    assert(not F.parseRules("1=maybe"))
    assert(not F.parseRules("4=on,"))
    assert(F.rulesText(F.parseRules(" 2649=on, 123=off ")) == "2649=on, 123=off")
    local p = F.copy(solo)
    p.rules = F.parseRules("2649=on,14916=off")
    assert(not F.macro(p, F.readPet()))
    local s = F.readPet()
    s.abilities[1].name = string.rep("x", 240)
    p.rules = F.parseRules("14916=on")
    assert(not F.macro(p, s))
    s.abilities[1].name = "Growl\n/cast Other"
    assert(not F.macro(p, s))
end)
test("settings persist position, empty rule lists and extra profiles", function()
    F.panel.scripts.OnDragStop(F.panel)
    local d = F.copy(F.db)
    d.profiles[3] = F.copy(solo)
    d.profiles[3].rules = {}
    d.vertical, d.hideCombat, d.hideNoPet, d.instance = true, true, true, "inside"
    assert(F.applySettings(d))
    assert(F.panel.condition == "hide")
    inside = true
    event("ZONE_CHANGED_NEW_AREA")
    flush()
    assert(F.panel.condition == "[combat] hide; [nopet] hide; show")
    local restored = F.loadSettings(ForeverPetModesDB)
    assert(#restored.profiles == 3 and #restored.profiles[3].rules == 0)
    assert(restored.position.x == 120 and restored.vertical)
end)
test("settings window applies edits, cancels and stages reset", function()
    SlashCmdList.FOREVERPETMODES("")
    local save, cancel, reset, width
    for _, w in ipairs(frames) do
        if w.textValue == "Save" then save = w end
        if w.textValue == "Cancel" then cancel = w end
        if w.textValue == "Reset to defaults" then reset = w end
        if w.kind == "EditBox" and w.textValue == "100" then width = w end
    end
    width:SetText("900")
    save.scripts.OnClick()
    assert(save.parent.shown and F.db.width == 100)
    width:SetText("118")
    save.scripts.OnClick()
    assert(F.db.width == 118 and not save.parent.shown)
    F.openSettings()
    reset.scripts.OnClick()
    cancel.scripts.OnClick()
    assert(F.db.width == 118)
    F.openSettings()
    reset.scripts.OnClick()
    save.scripts.OnClick()
    assert(F.db.width == 100 and #F.db.profiles == 2)
end)
test("Growl stays first, chips share a row, and hover identifies unmanaged Bite", function()
    slots[1] = { "Bite", 132127, false, false, true, true, 17253 }
    F.refresh()
    local first, second = F.panel.chips[1], F.panel.chips[2]
    assert(first.ability.name == "Knurren" and second.ability.name == "Bite")
    assert(second.x > first.x and second.y == first.y)
    local lines = {}
    function GameTooltip:AddLine(line) lines[#lines+1] = line end
    second.scripts.OnEnter(second)
    assert(table.concat(lines, " "):find("Dungeon Mode (active): Leave alone", 1, true))
end)
test("settings header displays the installed addon metadata version", function()
    for _, frame in ipairs(frames) do
        if frame.advanced and frame.scroll then
            for _, label in ipairs(frame.fonts) do
                if label:GetText() == "v" .. metadataVersion then return end
            end
        end
    end
    error("installed version missing from settings header")
end)
test("named tabs, icon picker, rank preservation, cancel and advanced settings", function()
    F.openSettings()
    local function find(caption)
        for _, w in ipairs(frames) do
            if w.textValue == caption and w.shown then return w end
        end
        error("could not find " .. caption)
    end
    local soloTab = find("Solo")
    soloTab.scripts.OnClick()
    local function pickFor(name)
        for _, w in ipairs(frames) do
            if w.ability and w.buttons and w.ability.name == name and w.shown then return w end
        end
    end
    local growl, bite = pickFor("Knurren"), pickFor("Bite")
    assert(growl.buttons[2].enabled == false and bite.buttons[1].enabled == false)
    bite.buttons[3].scripts.OnClick()
    growl.buttons[3].scripts.OnClick()
    assert(growl.buttons[3].enabled == false)
    find("Advanced").scripts.OnClick()
    assert(not bite.shown)
    find("Save").scripts.OnClick()
    local rules = F.db.profiles[1].rules
    assert(#rules == 2 and F.rulesText(rules):find("2649=off", 1, true))
    assert(F.rulesText(rules):find("17253=off", 1, true))
    F.openSettings()
    soloTab.scripts.OnClick()
    growl.buttons[1].scripts.OnClick()
    find("Cancel").scripts.OnClick()
    assert(#F.db.profiles[1].rules == 2)
    F.openSettings()
    soloTab.scripts.OnClick()
    slots[1] = nil
    F.refresh()
    assert(pickFor("Bite") and not pickFor("Bite").ability.spell)
    pickFor("Bite").buttons[1].scripts.OnClick()
    find("Save").scripts.OnClick()
    assert(F.rulesText(F.db.profiles[1].rules) == "2649=off")
end)
test("preflight clears a lost skill binding and restores it when the pet returns", function()
    local p = F.db.profiles[1]
    local b
    for _, w in ipairs(frames) do if w.profile == p then b = w end end
    local growl = slots[4]
    slots[4] = nil
    b.scripts.PreClick(b)
    assert(b.attributes.type1 == nil and b.problem:find("Knurren", 1, true))
    F.refresh()
    assert(b.warning.shown)
    slots[4] = growl
    event("UNIT_PET", "player")
    flush()
    assert(not b.warning.shown and b.attributes.type1 == "macro")
end)
test("an inaccessible native stance button cannot partially apply a mismatched profile", function()
    local s = F.readPet()
    local p = F.copy(F.defaults.profiles[1])
    local name = "PetActionButton" .. s.slots.Defensive
    _G[name] = nil
    local text, why = F.macro(p, s)
    assert(not text and why:find("native pet bar", 1, true))
    s.stance = "Defensive"
    text = assert(F.macro(p, s))
    assert(not text:find("/click", 1, true) and text:find("/petautocaston", 1, true))
    _G[name] = nativeButton
end)
test("a partial switch exposes a specific hover warning until the pet matches", function()
    local p = F.db.profiles[2]
    local b
    for _, w in ipairs(frames) do if w.profile == p then b = w end end
    slots[4][6] = true
    b.scripts.PostClick(b)
    for i = 1, 4 do flush() end
    assert(b.warning.shown and not b.mark.shown)
    local lines = {}
    function GameTooltip:AddLine(line) lines[#lines+1] = line end
    b.scripts.OnEnter(b)
    assert(table.concat(lines, " "):find("Knurren is ON (needs OFF)", 1, true))
    slots[4][6] = false
    F.refresh()
    assert(not b.warning.shown and b.mark.shown and #chat == 0)
end)
test("large profiles keep their guards and omit satisfied commands to fit", function()
    local s = F.readPet()
    local p = { stance="Defensive", rules={} }
    for i = 1, 6 do
        table.insert(s.abilities, { id=i, name="Ability " .. i, on=i ~= 6 })
        table.insert(p.rules, { id=i, on=true })
    end
    local text = assert(F.macro(p,s))
    assert(#text <= 255 and text:find("nocombat", 1, true) and text:find("Ability 6", 1, true))
    assert(not text:find("Ability 1", 1, true))
end)
test("Hunter filter applies to existing panels and the launcher stays available without a pet", function()
    local d = F.copy(F.db)
    d.showMinimap, d.hideNoPet = true, true
    assert(F.applySettings(d))
    assert(F.minimapButton.shown and F.panel.condition:find("nopet", 1, true))
    exists = false
    event("UNIT_PET", "player")
    flush()
    assert(F.minimapButton.shown)
    playerClass, exists = "WARLOCK", true
    event("PLAYER_ENTERING_WORLD")
    assert(not F.classVisible and not F.minimapButton.shown and F.panel.condition == "hide")
    d = F.copy(F.db)
    d.huntersOnly = false
    assert(F.applySettings(d) and F.classVisible and F.minimapButton.shown and F.panel.condition ~= "hide")
    playerClass = "HUNTER"
end)
test("minimap click opens settings, drag persists on save, and combat clicks stay quiet", function()
    local b = F.minimapButton
    local window
    for _, f in ipairs(frames) do if f.advanced and f.scroll then window = f end end
    assert(window and not window.shown)
    b.scripts.OnMouseDown(b)
    b.scripts.OnClick(b, "RightButton")
    assert(window.shown and not F.db.panelHidden)
    b.scripts.OnMouseDown(b)
    cursorX, cursorY = 600, 620
    b.scripts.OnDragStart(b)
    assert(b.scripts.OnUpdate)
    b.scripts.OnDragStop(b)
    b.scripts.OnClick(b, "LeftButton")
    assert(window.shown and not F.db.panelHidden and not b.scripts.OnUpdate and math.abs(F.db.minimapAngle - 90) < 0.001)
    local save
    for _, f in ipairs(frames) do if f.textValue == "Save" then save = f end end
    save.scripts.OnClick(save)
    assert(not window.shown and math.abs(F.loadSettings(ForeverPetModesDB).minimapAngle - 90) < 0.001)
    assert(math.abs(b.lastPoint[5] - 83) < 0.001)
    combat = true
    b.scripts.OnMouseDown(b)
    b.scripts.OnClick(b, "LeftButton")
    b.scripts.OnClick(b, "RightButton")
    assert(not window.shown and not F.db.panelHidden and #chat == 0)
    combat = false
    mapShape = "SQUARE"
    F.db.minimapAngle = 45
    Minimap.scripts.OnSizeChanged()
    assert(math.abs(b.lastPoint[4] - 83) < 0.001 and math.abs(b.lastPoint[5] - 83) < 0.001)
    mapShape = "ROUND"
end)
test("upgrades preserve minimap visibility and default to left-click for the panel", function()
    local old = F.loadSettings({ width=122 })
    assert(old.width == 122 and old.huntersOnly and not old.showMinimap and old.panelToggleClick == "Left-click")
    for _, saved in ipairs({{showMinimap=true}, {minimapAction="Open settings"}, {minimapAction="Show/hide panel"}}) do
        local upgraded = F.loadSettings(saved)
        assert(upgraded.showMinimap and upgraded.panelToggleClick == "Left-click")
    end
    assert(not F.loadSettings({minimapAction="Off"}).showMinimap)
    assert(not F.loadSettings({showMinimap=false}).showMinimap)
    assert(F.loadSettings({panelToggleClick="invalid"}).panelToggleClick == "Left-click")
end)
test("the Panel page swaps the two mouse buttons and saves the choice", function()
    F.openSettings()
    local save
    for _, f in ipairs(frames) do if f.textValue == "Save" then save = f end end
    local function toggle(caption)
        local body = save.parent.body
        for _, title in ipairs(body.fonts) do
            if title.shown and title.textValue == caption then
                for _, f in ipairs(frames) do
                    if f.parent == body and f.kind == "Button" and f.shown
                        and f.lastPoint[3] == title.lastPoint[3] + 4 then return f end
                end
            end
        end
        error("Missing Panel toggle: " .. caption)
    end
    local only, bubble = toggle("Hunters only"), toggle("Minimap button")
    local mapping = toggle("Show/hide panel with")
    assert(only.textValue == "Off" and bubble.textValue == "On" and mapping.textValue == "Left-click")
    only.scripts.OnClick(only)
    mapping.scripts.OnClick(mapping)
    save.scripts.OnClick(save)
    assert(F.db.huntersOnly and F.loadSettings(ForeverPetModesDB).panelToggleClick == "Right-click")
    local b = F.minimapButton
    b.scripts.OnMouseDown(b)
    b.scripts.OnClick(b, "RightButton")
    assert(F.db.panelHidden and not save.parent:IsShown())
    b.scripts.OnClick(b, "LeftButton")
    assert(F.db.panelHidden and save.parent:IsShown())
    bubble.scripts.OnClick(bubble)
    save.scripts.OnClick(save)
    assert(not F.db.showMinimap and not F.db.panelHidden and not b.shown)
    assert(F.loadSettings({minimapAngle=math.huge}).minimapAngle == F.defaults.minimapAngle)
end)
test("manual hiding persists and showing restores the configured visibility rules", function()
    local d = F.copy(F.db)
    d.showMinimap, d.panelToggleClick, d.hideNoPet, d.hideCombat = true, "Left-click", true, true
    d.instance = "any"
    assert(F.applySettings(d))
    local b = F.minimapButton
    local function click(key)
        b.scripts.OnMouseDown(b)
        b.scripts.OnClick(b, key)
    end
    local rules = F.panel.condition
    assert(rules:find("nopet", 1, true) and rules:find("combat", 1, true))
    click("RightButton")
    click("LeftButton")
    local save
    for _, f in ipairs(frames) do if f.textValue == "Save" then save = f end end
    assert(save.parent:IsShown() and F.db.panelHidden and b.shown and F.panel.condition == "hide")
    save.scripts.OnClick(save)
    assert(F.applySettings(F.loadSettings(ForeverPetModesDB)))
    event("PLAYER_ENTERING_WORLD")
    combat = true
    click("LeftButton")
    combat = false
    event("PLAYER_REGEN_ENABLED")
    assert(F.db.panelHidden and F.panel.condition == "hide")
    click("LeftButton")
    assert(not F.db.panelHidden and F.panel.condition == rules)
    b.scripts.OnMouseDown(b)
    b.scripts.OnDragStart(b)
    b.scripts.OnDragStop(b)
    b.scripts.OnClick(b, "LeftButton")
    assert(not F.db.panelHidden)
    click("LeftButton")
    d = F.copy(F.db)
    d.showMinimap = false
    assert(F.applySettings(d) and not F.db.panelHidden and F.panel.condition == rules and not b.shown)
end)
test("a collector can capture standalone launchers without a refresh stealing their anchors", function()
    F.db.showMinimap = true
    F.updateMinimap()
    local button, bin = F.minimapButton, {}
    button.parent = bin
    button:SetPoint("LEFT", bin, "LEFT", 3, 0)
    local anchor = button.lastPoint
    F.updateMinimap()
    Minimap.scripts.OnSizeChanged()
    assert(button.lastPoint == anchor)
    button.parent = Minimap
end)
test("broker discovery, bin ownership, visibility and settings click use one launcher", function()
    local bin, registrations, shows, hides, clicks = {}, 0, 0, 0, 0
    local broker, icons, icon = {}, {}, nil
    function broker:NewDataObject(name, obj)
        assert(name == "ForeverPetModes" and obj.type == "launcher")
        return obj
    end
    function icons:Register(name, obj, db)
        registrations = registrations + 1
        icon = widget("Button", Minimap)
        icon.object, icon.db = obj, db
        icon:SetScript("OnDragStart", function(self) self.dragged = true end)
    end
    function icons:GetMinimapButton() return icon end
    function icons:Show()
        assert(not icon.db.hide)
        shows = shows + 1
        icon:Show()
        -- The collector hooks Show, gathers the registered button and takes its anchor.
        icon.parent = bin
        icon:SetPoint("TOPLEFT", bin, "TOPLEFT", 4, -4)
    end
    function icons:Hide() assert(icon.db.hide) hides = hides + 1 icon:Hide() end
    LibStub = function(name) return name == "LibDBIcon-1.0" and icons or broker end
    local toggles = 0
    local f = { db={ showMinimap=true, panelToggleClick="Left-click", minimapAngle=72 }, classVisible=true,
        togglePanel=function() toggles=toggles+1 end,
        openSettings=function() clicks=clicks+1 end, saveMinimapAngle=function(angle) assert(angle == 168) end }
    assert(loadfile("ForeverPetModes/Minimap.lua"))("ForeverPetModes", f)
    f.updateMinimap()
    assert(registrations == 1 and shows == 1 and icon == f.minimapButton and icon.parent == bin)
    local anchor = icon.lastPoint
    local brokerTip = widget("Tooltip")
    local petReason = "Summon a pet."
    f.readPet = function() return {reason=petReason} end
    function brokerTip:IsOwned(owner) return owner == icon end
    function brokerTip:AddLine(line) self.lines[#self.lines+1] = line end
    function brokerTip:SetText() self.lines = {} end
    icon.object.OnTooltipShow(brokerTip)
    assert(brokerTip.lines[1] == petReason)
    petReason = "Revive your pet."
    f.refreshMinimapTooltip(f.readPet())
    assert(brokerTip.lines[1] == petReason)
    icon.scripts.OnDragStart(icon)
    assert(not icon.dragged)
    f.db.minimapAngle = 180
    f.updateMinimap()
    assert(shows == 1 and icon.lastPoint == anchor)
    icon.object.OnClick(icon, "LeftButton")
    combat = true
    icon.object.OnClick(icon, "LeftButton")
    combat = false
    assert(toggles == 1 and clicks == 0)
    icon.object.OnClick(icon, "RightButton")
    f.db.panelToggleClick = "Right-click"
    icon.object.OnClick(icon, "LeftButton")
    assert(toggles == 1 and clicks == 2)
    icon.object.OnClick(icon, "RightButton")
    assert(toggles == 2 and clicks == 2)
    f.classVisible = false
    f.updateMinimap()
    f.updateMinimap()
    assert(not icon.shown and hides == 1)
    f.classVisible = true
    f.updateMinimap()
    assert(icon.shown and shows == 2 and registrations == 1)
    icon.parent = Minimap
    icon.scripts.OnDragStart(icon)
    assert(icon.dragged)
    icon.db.minimapPos = 168
    icon.scripts.OnDragStop(icon)
    LibStub = nil
end)
test("corrupt fields recover without dropping adjacent valid edits", function()
    local d = F.loadSettings({ width=-1, height=54, inactive="zzzzzz", position={},
        profiles={ { rules="old", color=false, label="Keep me" }, false } })
    assert(d.width == 100 and d.height == 54 and d.position.point == "CENTER")
    assert(d.profiles[1].label == "Keep me" and d.profiles[1].rules[1].id == 2649)
    assert(d.profiles[2].stance == "Passive")
end)
local function settingsButton(caption)
    for _, frame in ipairs(frames) do
        if frame.kind == "Button" and frame.shown and frame.textValue == caption then return frame end
    end
    error("Missing button " .. caption)
end
local function press(caption)
    local b = settingsButton(caption)
    b.scripts.OnClick(b)
end
test("custom profiles duplicate independently, rename, cancel removal and save removal", function()
    assert(F.applySettings(F.loadSettings({})))
    F.openSettings()
    press("Solo")
    press("Duplicate profile")
    local copyLabel
    for _, w in ipairs(frames) do
        if w.kind == "EditBox" and w.shown and w.textValue == "Custom 1" then copyLabel = w end
    end
    assert(copyLabel and #F.db.profiles == 2)
    copyLabel:SetText("Farming")
    press("Save")
    assert(F.db.profiles[3].label == "Farming" and F.db.profiles[3].rules ~= F.db.profiles[1].rules)
    assert(F.loadSettings(ForeverPetModesDB).profiles[3].label == "Farming")
    for _, action in ipairs({"Cancel", "Save"}) do
        F.openSettings()
        press("Farming")
        press("Remove profile")
        press(action)
        assert(#F.db.profiles == (action == "Cancel" and 3 or 2))
    end
end)
test("pinned ability selection persists, follows trained ranks and can be cleared without that pet", function()
    slots[1] = { "Bite", 132127, false, false, true, true, 17253 }
    F.openSettings()
    press("All abilities")
    assert(not settingsButton("Knurren (always shown)").enabled)
    press("Bite (pin)")
    press("Save")
    local saved = F.loadSettings(ForeverPetModesDB)
    assert(saved.indicatorMode == "Pinned abilities" and saved.pinnedAbilities[17253])
    slots[1][7] = 17254
    slots[3] = { "Claw", 123, false, false, true, false, 111 }
    local rows = F.indicatorRows(F.readPet())
    assert(#rows == 2 and rows[1].growl and rows[2].id == 17254)
    slots[1] = nil
    F.openSettings()
    press("Bite (pinned)")
    press("Save")
    assert(#F.indicatorRows(F.readPet()) == 1 and next(F.db.pinnedAbilities) == nil)
    local repaired = F.loadSettings({pinnedAbilities={bad=true, [17253]=true, [10]=false}})
    assert(repaired.pinnedAbilities[17253] and not repaired.pinnedAbilities.bad and repaired.pinnedAbilities[10] == nil)
end)
test("happiness follows the pet and omits unavailable or restricted values", function()
    local value, hunterPet = 1, true
    C_PetInfo = { GetPetHappiness=function() return value end }
    HasPetUI = function() return true, hunterPet end
    local atlases = {"UI-PetMad", "UI-PetNeutral", "UI-PetHappiness"}
    local icon = F.panel.moodIcon
    local lines = {}
    function GameTooltip:AddLine(line) lines[#lines+1] = line end
    for n, label in ipairs({"Unhappy", "Content", "Happy"}) do
        value = n
        event("UNIT_HAPPINESS", "pet")
        flush()
        assert(icon.shown and icon.texture.atlas == atlases[n])
        assert(not F.panel.status:GetText():find(label, 1, true))
        icon.scripts.OnEnter(icon)
        assert(GameTooltip:GetText() == "Ash" and table.concat(lines, " "):find("Happiness: " .. label, 1, true))
    end
    F.db.showHappiness = false
    F.refresh()
    assert(not icon.shown)
    F.db.showHappiness = true
    value = secret
    assert(F.refresh().happiness == nil and icon.shown and icon.info.shown and not icon.texture.shown)
    value, hunterPet = 2, false
    assert(F.readPet().happiness == nil)
    hunterPet = true
    exists = false
    assert(F.readPet().happiness == nil)
    exists = true
end)
test("minimap hover reads live matches, pins, custom state and missing pets with the panel hidden", function()
    local d = F.copy(F.db)
    d.showMinimap, d.panelHidden = true, true
    assert(F.applySettings(d))
    assert(F.panel.condition == "hide")
    local lines = {}
    function GameTooltip:AddLine(line) lines[#lines+1] = line end
    function GameTooltip:IsOwned(w) return w == F.minimapButton end
    local s = F.readPet()
    local growl = F.resolve(s, 2649)
    assert(growl)
    local p = F.db.profiles[1]
    p.stance, p.rules = s.stance, { {id=2649, on=growl.on} }
    F.minimapButton.scripts.OnEnter(F.minimapButton)
    assert(table.concat(lines, " "):find(p.label, 1, true))
    assert(table.concat(lines, " "):find("|A:UI-PetNeutral:16:16|a Happiness: Content", 1, true))
    assert(not table.concat(lines, " "):find("Claw", 1, true))
    lines = {}
    for _, profile in ipairs(F.db.profiles) do profile.stance = "Aggressive" end
    F.refresh()
    assert(table.concat(lines, " "):find("Custom", 1, true))
    exists, lines = false, {}
    F.refresh()
    assert(lines[1] == "Summon a pet.")
    exists = true
    GameTooltip.IsOwned = nil
end)
test("recall is an independent opt-in hardware action with a fixed living-pet guard", function()
    local d = F.copy(F.db)
    d.showRecall, d.panelHidden = true, false
    assert(F.applySettings(d))
    local b = F.panel.commands[2]
    assert(b.shown and b.protected and b.attributes["*type1"] == "macro")
    assert(b.attributes["*macrotext1"] == "/petfollow [@pet,exists,nodead]")
    assert(not b.scripts.PreClick and not b.scripts.PostClick and not b.scripts.OnClick)
    combat = true
    F.refresh()
    assert(b.attributes["*macrotext1"] == "/petfollow [@pet,exists,nodead]")
    combat = false
    d.showRecall = false
    assert(F.applySettings(d) and not b.shown)
end)
test("the pet badge leads the command column and the profile footer stays in place", function()
    local d = F.copy(F.db)
    d.showHappiness = true
    for _, vertical in ipairs({false, true}) do
        for _, icons in ipairs({false, true}) do
            d.vertical, d.icons, d.showRecall = vertical, icons, false
            assert(F.applySettings(d))
            local footerY = F.panel.footer.lastPoint[3]
            d.showRecall = true
            assert(F.applySettings(d))
            local recall = F.panel.commands[2]
            assert(recall.shown and recall.layoutHeight == d.height)
            assert(F.panel.footer.lastPoint[3] == footerY and recall.text.shown == not icons)
            for _, button in ipairs(frames) do
                if button.profile and button.shown then
                    assert(button.lastPoint[2] + button.layoutWidth < recall.lastPoint[2])
                    if button.profile == d.profiles[1] then assert(button.lastPoint[3] == F.panel.moodIcon.lastPoint[3]) end
                end
            end
            assert(recall.lastPoint[2] + recall.layoutWidth <= F.panel.layoutWidth - F.panelMetrics.padding)
            assert(F.panel.moodIcon.lastPoint[2] + F.panel.moodIcon.layoutWidth <= F.panel.layoutWidth - F.panelMetrics.padding)
        end
    end
    assert(F.panel.moodIcon.lastPoint[1] == "TOPLEFT")
    assert(F.panel.status.lastPoint[2] == 0)
    d.showHappiness = false
    assert(F.applySettings(d) and F.panel.status.lastPoint[2] == 0)
end)
test("Follow and profiles use the configured border thickness", function()
    local d = F.copy(F.db)
    d.showRecall, d.height = true, 20
    for _, border in ipairs({0, 2, 6}) do
        d.border = border
        assert(F.applySettings(d))
        for _, button in ipairs(frames) do
            if button.shown and (button.profile or button == F.panel.commands[2]) then
                local corner = button.fill.lastPoint
                assert(corner[1] == "BOTTOMRIGHT" and corner[2] == -border and corner[3] == border)
            end
        end
        assert(F.panel.commands[2].icon.layoutHeight <= d.height - 2 * border)
    end
end)
test("border insets use whole screen pixels after zoom, UI scale and resolution changes", function()
    local d = F.copy(F.db)
    d.scale, d.border, d.showRecall = 1.2, 2, true
    uiScale, unitsPerPixel = 0.8, 0.75
    assert(F.applySettings(d))
    local function check(expectedPixels)
        for _, b in ipairs(frames) do
            if b.shown and (b.profile or b == F.panel.commands[2]) then
                local corner = b.fill.lastPoint
                local pixelsPerUnit = d.scale * uiScale / unitsPerPixel
                assert(math.abs(-corner[2] * pixelsPerUnit - expectedPixels) < 0.00001)
                assert(corner[3] == -corner[2])
            end
        end
    end
    check(3)
    uiScale = 0.7
    event("UI_SCALE_CHANGED")
    check(2)
    unitsPerPixel = 0.55
    event("DISPLAY_SIZE_CHANGED")
    check(3)
    d.border = 0
    assert(F.applySettings(d))
    check(0)
    uiScale, unitsPerPixel = 1, 1
end)
test("divider collapses only the pet controls and survives settings save and reload", function()
    local d = F.loadSettings({})
    d.showRecall = true
    assert(F.applySettings(d))
    local p, m = F.panel, F.panelMetrics
    local expanded, left = p.layoutWidth, p.contentWidth
    local arrow = p.divider.arrow
    assert(arrow.atlas == "common-icon-forwardarrow" and arrow.rotation == math.pi)
    assert(arrow.layoutWidth < p.divider.layoutWidth)
    local leftEdge = p.lastPoint[4] - expanded / 2
    assert(p.moodIcon.lastPoint[3] - m.moodSize - m.gap == p.commands[2].lastPoint[3])
    assert(p.moodIcon.lastPoint[2] == p.commands[1].lastPoint[2])
    assert(p.footer.lastPoint[2] == m.padding and p.status.layoutWidth == left)
    assert(p.commands[1].lastPoint[2] == m.padding + left + m.gap * 2 + m.dividerWidth)
    F.openSettings()
    p.divider.scripts.OnClick()
    assert(p.divider.shown and p.layoutWidth < expanded and p.contentWidth == left)
    assert(arrow.rotation == 0)
    assert(p.lastPoint[4] - p.layoutWidth / 2 == leftEdge)
    assert(not p.moodIcon.shown and not p.commands[2].shown and p.status.shown)
    press("Save")
    assert(F.applySettings(F.loadSettings(ForeverPetModesDB)) and F.db.petControlsCollapsed)
    combat = true
    p.divider.scripts.OnClick()
    assert(F.db.petControlsCollapsed)
    combat = false
    p.divider.scripts.OnClick()
    assert(not F.db.petControlsCollapsed and p.commands[2].shown and p.moodIcon.shown and p.layoutWidth == expanded)
    assert(arrow.rotation == math.pi)
    d = F.copy(F.db)
    d.showRecall, d.showHappiness = false, false
    assert(F.applySettings(d) and not p.divider.shown and p.layoutWidth == left + m.padding * 2)
end)
test("folded profiles fill the panel and the header keeps separate move and expand targets", function()
    local p, m = F.panel, F.panelMetrics
    for _, title in ipairs({false, true}) do
        for _, locked in ipairs({false, true}) do
            local d = F.loadSettings({})
            d.title, d.locked, d.showRecall = title, locked, true
            d.columnWidth = 110
            assert(F.applySettings(d))
            local width, height = p.layoutWidth, p.layoutHeight
            local footerY = p.footer.lastPoint[3]
            p.divider.scripts.OnClick()
            assert(p.layoutWidth == p.contentWidth + 2 * m.padding)
            assert(p.layoutHeight == height and p.footer.lastPoint[3] == footerY)
            assert(p.divider.shown and p.divider.lastPoint[1] == "TOPRIGHT")
            assert(p.divider.layoutHeight == p.dragStrip.layoutHeight)
            assert(not p.divider.upperRail.shown and not p.divider.lowerRail.shown)
            assert(p.dragStrip.lastPoint[4] == -p.divider.layoutWidth)
            assert(p.title.layoutWidth <= p.layoutWidth - p.divider.layoutWidth)
            assert(p.dragStrip.shown == not locked and p.resizeGrip.shown == not locked)
            p.divider.scripts.OnClick()
            assert(p.layoutWidth == width and p.layoutHeight == height)
            assert(p.divider.lastPoint[1] == "BOTTOMLEFT" and p.dragStrip.lastPoint[4] == 0)
            assert(p.divider.upperRail.shown and p.divider.lowerRail.shown)
        end
    end
end)
test("pet details include identity, vitals and unpinned autocasts and omit unreadable data", function()
    local d = F.loadSettings({})
    d.indicatorMode = "Pinned abilities"
    assert(F.applySettings(d))
    local icon = F.panel.moodIcon
    C_PetInfo.GetPetLoyalty = function() return "Faithful" end
    C_PetInfo.GetPetFoodTypes = function() return {"Meat", "Fish"} end
    local lines = {}
    function GameTooltip:AddLine(line) lines[#lines+1] = line end
    icon.scripts.OnEnter(icon)
    assert(GameTooltip:GetText() == "Ash")
    local text = table.concat(lines, " ")
    for _, value in ipairs({"Level 32", "Cat", "334 / 500", "Focus: 65 / 100", "Claw OFF", "Faithful", "Meat, Fish"}) do
        assert(text:find(value, 1, true), value)
    end
    local getHealth = UnitHealth
    UnitHealth = function() return secret end
    lines = {}
    icon.scripts.OnEnter(icon)
    assert(not table.concat(lines, " "):find("Health:", 1, true))
    UnitHealth = getHealth
    exists = false
    F.refresh()
    lines = {}
    icon.scripts.OnEnter(icon)
    assert(icon.info.shown and lines[1] == "Summon a pet." and GameTooltip:GetText() == "Pet details")
    exists = true
end)
test("pet badge fits both lines inside the face height and refreshes identity without hover", function()
    local d = F.loadSettings({})
    assert(F.applySettings(d))
    local badge = F.panel.moodIcon
    local face = badge.texture
    local name, level = badge.petName, badge.petLevel
    assert(name.lastPoint[2] == face.layoutWidth + F.panelMetrics.gap)
    assert(name.lastPoint[2] == level.lastPoint[2] and name.lastPoint[3] == 0)
    assert(-level.lastPoint[3] == name.layoutHeight)
    assert(name.layoutHeight + level.layoutHeight == face.layoutHeight and badge.layoutHeight == face.layoutHeight)
    assert(name.lastPoint[2] + name.layoutWidth == badge.layoutWidth)
    assert(badge.health.lastPoint[2] == badge and badge.health.lastPoint[3] == "TOPLEFT")
    assert(level.layoutWidth + F.panelMetrics.gap + badge.health.layoutWidth == name.layoutWidth)
    assert(badge.health.layoutHeight == 5 and badge.health.layoutHeight <= level.layoutHeight)
    local newName, newLevel = "Bear", 29
    local oldName, oldLevel = UnitName, UnitLevel
    UnitName = function() return newName end
    UnitLevel = function() return newLevel end
    event("UNIT_NAME_UPDATE", "pet")
    flush()
    assert(name:GetText() == "Bear" and level:GetText() == "Lv. 29")
    newLevel = 30
    event("UNIT_LEVEL", "pet")
    flush()
    assert(level:GetText() == "Lv. 30")
    newName, newLevel = secret, -1
    F.refresh()
    assert(name:GetText() == "" and level:GetText() == "")
    UnitName, UnitLevel = oldName, oldLevel
    exists = false
    F.refresh()
    assert(name:GetText() == "" and level:GetText() == "")
    exists = true
end)
test("Follow mirrors the native slot binding through rebinds, moves and missing slots", function()
    local binds = { BONUSACTIONBUTTON2="CTRL-2", BONUSACTIONBUTTON7="SHIFT-F" }
    GetBindingKey = function(command) return binds[command] end
    GetBindingText = function(key, short)
        if key == "CTRL-2" then return short and "c-2" or "Ctrl+2" end
        assert(key == "SHIFT-F")
        return short and "s-F" or "Shift+F"
    end
    local old2, old7 = slots[2], slots[7]
    slots[2] = {"PET_ACTION_FOLLOW", "PET_FOLLOW_TEXTURE", true}
    local d = F.copy(F.db)
    d.showRecall = true
    assert(F.applySettings(d))
    local b = F.panel.commands[2]
    assert(b.text:GetText() == "Follow" and b.hotkey:GetText() == "c-2")
    b.scripts.OnEnter(b)
    assert(GameTooltip:GetText() == "Follow (Ctrl+2)")
    binds.BONUSACTIONBUTTON2 = nil
    event("UPDATE_BINDINGS")
    flush()
    assert(b.hotkey:GetText() == "" and not b.bindingText)
    slots[2], slots[7] = old2, {"PET_COMMAND_FOLLOW", "PET_FOLLOW_TEXTURE", true}
    event("PET_BAR_UPDATE")
    flush()
    assert(b.hotkey:GetText() == "s-F" and b.bindingText == "Shift+F")
    slots[7][2] = secret
    F.refresh()
    assert(b.hotkey:GetText() == "")
    slots[7] = old7
    F.refresh()
    assert(b.hotkey:GetText() == "" and b.attributes["*macrotext1"] == "/petfollow [@pet,exists,nodead]")
end)
test("the three secure command buttons follow native bindings and allow explicit addon shortcuts", function()
    local d = F.loadSettings({})
    assert(F.applySettings(d))
    local old1, old7 = slots[1], slots[7]
    slots[1] = {"PET_ACTION_ATTACK", "PET_ATTACK_TEXTURE", true}
    slots[7] = {"PET_ACTION_WAIT", "PET_WAIT_TEXTURE", true}
    local keys = {BONUSACTIONBUTTON1="CTRL-1", BONUSACTIONBUTTON7="CTRL-7", ["CLICK ForeverPetModesFollow:LeftButton"]="F6"}
    GetBindingKey = function(command) return keys[command] end
    GetBindingText = function(key) return key end
    F.refresh()
    local attack, follow, stay = unpack(F.panel.commands)
    assert(attack.globalName == "ForeverPetModesAttack" and stay.globalName == "ForeverPetModesStay")
    assert(attack.hotkey:GetText() == "CTRL-1" and stay.hotkey:GetText() == "CTRL-7" and follow.hotkey:GetText() == "F6")
    assert(attack.attributes["*macrotext1"] == "/petattack [@target,harm,nodead,pet]")
    assert(stay.attributes["*macrotext1"] == "/petstay [@pet,exists,nodead]")
    assert(attack.lastPoint[2] < follow.lastPoint[2] and follow.lastPoint[2] < stay.lastPoint[2])
    slots[1], slots[7] = old1, old7
end)
test("the badge health bar updates on pet health events and clears for unreadable health", function()
    local bar = F.panel.moodIcon.health
    local original = UnitHealthPercent
    UnitHealthPercent = function() return 0.38 end
    event("UNIT_HEALTH", "pet")
    flush()
    assert(bar.shown and bar.minimum == 0 and bar.maximum == 1 and bar.value == 0.38)
    UnitHealthPercent = function() return secret end
    F.refresh()
    assert(bar.shown and bar.value == secret)
    exists = false
    F.refresh()
    assert(not bar.shown)
    exists = true
    UnitHealthPercent = original
end)
test("learned care spells use secure contextual visibility and refresh when trained", function()
    local names = {[883]="Call Pet", [982]="Revive Pet", [136]="Mend Pet", [6991]="Feed Pet"}
    local learned = {[883]=true, [982]=true, [6991]=true}
    local original = C_Spell.GetSpellName
    C_Spell.GetSpellName = function(id) return names[id] or original(id) end
    C_SpellBook.IsSpellKnown = function(id) return learned[id] end
    event("SPELLS_CHANGED")
    local primary, feed, revive = unpack(F.panel.care)
    assert(F.panel.careRow.shown and primary.careMacro == "/cast [@pet,exists,dead] Revive Pet; [nopet] Call Pet")
    assert(revive.condition == "[nopet] show; hide")
    assert(primary.petcare == "[@pet,exists,dead] Revive; [nopet] Call; Pet care")
    assert(not feed.attributes["*type1"] and feed.scripts.PostClick == F.toggleFoodPicker)
    assert(feed.condition == "[@pet,exists,nodead,nocombat] show; hide")
    C_SpellBook.FindSpellBookSlotForSpell = function(spell) if spell == names[136] then return 12 end end
    event("SPELLS_CHANGED")
    assert(primary.careMacro == "/cast [@pet,exists,dead] Revive Pet; [@pet,exists,nodead] Mend Pet; [nopet] Call Pet")
    for _, caption in ipairs({"Mend", "Revive", "Call"}) do
        primary.scripts.OnAttributeChanged(primary, "state-petcare", caption)
        assert(primary.text:GetText() == caption)
    end
    combat = true
    event("SPELLS_CHANGED")
    combat = false
    local d = F.copy(F.db)
    d.showCare = false
    assert(F.applySettings(d) and not F.panel.careRow.shown and not feed.attributes["*type1"])
    C_Spell.GetSpellName = original
    C_SpellBook.IsSpellKnown = function() return false end
    C_SpellBook.FindSpellBookSlotForSpell = function() end
end)
test("favorite keybindings migrate, reassign and release their old actions", function()
    local d = F.loadSettings({profiles={{label="Solo"}, {label="Dungeon"}, {label="Raid"}}})
    assert(d.profiles[1].favorite == "1" and d.profiles[2].favorite == "2" and d.profiles[3].favorite == "None")
    assert(F.applySettings(d))
    F.openSettings()
    press("Raid")
    press("Advanced")
    press("None")
    press("Save")
    assert(F.db.profiles[3].favorite == "1" and F.db.profiles[1].favorite == "None")
    local button
    for _, b in ipairs(frames) do if b.globalName == "ForeverPetModesFavorite1" then button = b end end
    assert(button and button.profile == F.db.profiles[3])
    button.scripts.PreClick(button)
    assert(button.attributes.macrotext1 and button.attributes.macrotext1:find("nocombat,nomod",1,true))
    F.openSettings()
    press("Raid")
    press("Remove profile")
    press("Save")
    assert(not button.profile and not button.shown and not button.attributes.type1)
    button.scripts.PreClick(button)
    button.scripts.PostClick(button)
    assert(not button.attributes.type1)
end)
test("compact profile rows share clickable seams and preserve explicit wider gaps", function()
    local d = F.loadSettings({})
    d.width, d.title = 75, false
    for i = 3, 6 do
        d.profiles[i] = F.copy(d.profiles[1])
        d.profiles[i].favorite = "None"
    end
    for _, spacing in ipairs({0, 4, 12}) do
        d.spacing = spacing
        assert(F.applySettings(d))
        local profileButtons = {}
        for _, b in ipairs(frames) do
            if b.shown and b.profile then profileButtons[b.profile] = b end
        end
        for i, profile in ipairs(d.profiles) do
            local b = profileButtons[profile]
            if i == 4 or i == 6 then
                assert(b.layoutWidth == d.width)
            else
                local nextButton = profileButtons[d.profiles[i + 1]]
                local gutter = nextButton.lastPoint[2] - b.lastPoint[2] - b.layoutWidth
                assert(gutter == (spacing <= F.panelMetrics.gap and 0 or spacing))
            end
        end
    end
end)
test("the compact player layout aligns identity, commands and care as rows are toggled", function()
    local m, p = F.panelMetrics, F.panel
    local d = F.loadSettings({})
    d.width, d.height, d.title, d.showCare = 75, 32, false, true
    local original = C_Spell.GetSpellName
    C_Spell.GetSpellName = function(id) return id == 136 and "Mend Pet" or original(id) end
    C_SpellBook.IsSpellKnown = function(id) return id == 136 end
    for _, badge in ipairs({true, false}) do
        for _, commands in ipairs({true, false}) do
            d.showHappiness, d.showRecall = badge, commands
            assert(F.applySettings(d))
            local top = p.dragStrip.layoutHeight
            if badge then
                assert(-p.moodIcon.lastPoint[3] == top)
                top = top + m.moodSize + m.gap
            end
            if commands then
                local attack = p.commands[1]
                assert(-attack.lastPoint[3] == top and attack.lastPoint[2] == p.careRow.lastPoint[2])
                assert(-attack.text.lastPoint[3] >= -attack.hotkey.lastPoint[3] + attack.hotkey.layoutHeight)
                top = top + d.height + m.gap
            end
            assert(p.careRow.shown and -p.careRow.lastPoint[3] == top)
            assert(p.petColumnBottom == top + p.careRow.layoutHeight)
            assert(p.careRow.layoutHeight >= 24 and p.layoutHeight >= p.petColumnBottom + m.padding)
        end
    end
    C_Spell.GetSpellName = original
    C_SpellBook.IsSpellKnown = function() return false end
end)
test("folding changes width alone with care, commands and badge in every combination", function()
    local d = F.loadSettings({})
    local original, known = C_Spell.GetSpellName, C_SpellBook.IsSpellKnown
    C_Spell.GetSpellName = function(id) return id == 883 and "Call Pet" or original(id) end
    C_SpellBook.IsSpellKnown = function(id) return id == 883 end
    d.hideNoPet = true
    for _, care in ipairs({true, false}) do
        for _, commands in ipairs({true, false}) do
            for _, badge in ipairs({true, false}) do
                d.showCare, d.showRecall, d.showHappiness = care, commands, badge
                d.petControlsCollapsed = false
                assert(F.applySettings(d))
                local p = F.panel
                local height, width, footer = p.layoutHeight, p.layoutWidth, p.footer.layoutHeight
                assert((p.condition:find("[nopet] hide", 1, true) == nil) == care)
                d.petControlsCollapsed = true
                assert(F.applySettings(d))
                assert(p.layoutHeight == height and p.footer.layoutHeight == footer)
                assert((p.layoutWidth < width) == (care or commands or badge))
            end
        end
    end
    C_Spell.GetSpellName, C_SpellBook.IsSpellKnown = original, known
end)
test("context menus bind and unbind native, profile and shared care shortcuts", function()
    local d = F.loadSettings({})
    local original, known = C_Spell.GetSpellName, C_SpellBook.IsSpellKnown
    C_Spell.GetSpellName = function(id) return id == 136 and "Mend Pet" or original(id) end
    C_SpellBook.IsSpellKnown = function(id) return id == 136 end
    assert(F.applySettings(d))
    local owner = {["CTRL-2"]="BONUSACTIONBUTTON2", F8="OPENALLBAGS"}
    local saves, items = 0, {}
    GetBindingKey = function(action)
        local keys = {}
        for key, command in pairs(owner) do if command == action then keys[#keys+1] = key end end
        return unpack(keys)
    end
    GetBindingAction = function(key) return owner[key] or "" end
    GetBindingText = function(key) return key end
    SetBinding = function(key, action) assert(not combat) owner[key] = action return true end
    GetCurrentBindingSet = function() return 2 end
    SaveBindings = function(set) assert(set == 2) saves = saves + 1 end
    GetConvertedKeyOrButton = function(key) return key end
    IsKeyPressIgnoredForBinding = function(key) return key == "LSHIFT" end
    CreateKeyChordStringUsingMetaKeyState = function(key) return key end
    MenuUtil = {CreateContextMenu=function(button, populate)
        items = {}
        local menu = {CreateTitle=function(_, title) items[title]=true end}
        function menu:CreateButton(label, fn)
            local item = widget("Button")
            item.click = fn
            items[label] = item
            return item
        end
        populate(button, menu)
    end}
    local follow = F.panel.commands[2]
    local old = slots[2]
    slots[2] = {"PET_ACTION_FOLLOW", "PET_FOLLOW_TEXTURE", true}
    local function menu(button) button.scripts.OnMouseUp(button, "RightButton") end
    menu(follow)
    assert(items["Pet bar slot 2"])
    items["Unbind CTRL-2"].click()
    assert(not owner["CTRL-2"] and saves == 1)
    menu(follow)
    items["Bind a key…"].click()
    local frame
    for _, f in ipairs(frames) do if f.prompt and f.replace then frame = f end end
    frame.scripts.OnKeyDown(frame, "F8")
    assert(frame.replace.shown and owner.F8 == "OPENALLBAGS")
    frame.replace.scripts.OnClick()
    assert(owner.F8 == "BONUSACTIONBUTTON2" and saves == 2)
    menu(follow)
    slots[2] = old
    items["Unbind F8"].click()
    assert(owner.F8 == "BONUSACTIONBUTTON2")
    local p = F.panel.care[1]
    menu(p)
    items["Bind a key…"].click()
    frame.scripts.OnKeyDown(frame, "F9")
    assert(owner.F9 == "CLICK ForeverPetModesPetCare:LeftButton")
    local profile
    for _, f in ipairs(frames) do if f.profile == d.profiles[1] then profile = f end end
    local serial = F.clickSerial
    profile.scripts.PreClick(profile, "RightButton")
    profile.scripts.PostClick(profile, "RightButton")
    assert(F.clickSerial == serial)
    menu(profile)
    items["Bind a key…"].click()
    frame.scripts.OnKeyDown(frame, "ESCAPE")
    assert(not frame.shown and saves == 3)
    menu(profile)
    items["Bind a key…"].click()
    frame.scripts.OnKeyDown(frame, "F10")
    assert(owner.F10 == profile.binding)
    menu(profile)
    combat = true
    items["Unbind F10"].click()
    combat = false
    assert(owner.F10 == profile.binding)
    d = F.copy(F.db)
    d.profiles[3] = F.copy(d.profiles[1])
    d.profiles[3].bindingID, d.profiles[3].favorite = nil, "None"
    assert(F.applySettings(d))
    local personal = "CLICK ForeverPetModesProfile" .. d.profiles[3].bindingID .. ":LeftButton"
    owner.F11 = personal
    d = F.copy(F.db)
    d.profiles[3].favorite = "3"
    assert(F.applySettings(d))
    local alias
    for _, b in ipairs(frames) do if b.binding == personal and b.profile == d.profiles[3] then alias = b end end
    assert(alias and alias.shown)
    d = F.copy(F.db)
    table.remove(d.profiles, 3)
    assert(F.applySettings(d) and not owner.F11 and not alias.profile and owner.F10 == profile.binding)
    C_Spell.GetSpellName, C_SpellBook.IsSpellKnown = original, known
end)
test("custom profile binding names survive reordering, reload and deletion of a neighbor", function()
    local d = F.loadSettings({profiles={{}, {}, {label="Raid"}, {label="Travel"}}})
    assert(F.applySettings(d))
    local travel = d.profiles[4].bindingID
    assert(travel ~= d.profiles[3].bindingID)
    table.remove(d.profiles, 3)
    d = F.loadSettings(d)
    assert(F.applySettings(d) and d.profiles[3].bindingID == travel)
    for _, f in ipairs(frames) do
        if f.profile == d.profiles[3] then
            assert(f.binding == "CLICK ForeverPetModesProfile" .. travel .. ":LeftButton")
            return
        end
    end
    error("custom profile button missing")
end)
test("pet XP fills below health, updates on player pet XP events and hides when unavailable", function()
    assert(F.applySettings(F.loadSettings({})))
    local badge = F.panel.moodIcon
    local current, required = 0, 600
    GetPetExperience = function() return current, required end
    event("UNIT_PET_EXPERIENCE", "player")
    flush()
    assert(badge.xp.shown and badge.xp.maximum == 600 and badge.xp.value == 0)
    assert(badge.xp.layoutWidth == badge.health.layoutWidth and badge.xp.lastPoint[2] == badge.health)
    current = 250
    event("UNIT_PET_EXPERIENCE", "player")
    flush()
    assert(badge.xp.value == 250)
    required = 0
    F.refresh()
    assert(not badge.xp.shown and badge.health.shown)
    required = secret
    F.refresh()
    assert(not badge.xp.shown)
    GetPetExperience = nil
end)
test("the summon card replaces the full panel for an absent pet and respects every visibility filter", function()
    local d = F.loadSettings({})
    local original, known = C_Spell.GetSpellName, C_SpellBook.IsSpellKnown
    C_Spell.GetSpellName = function(id) return ({[883]="Call Pet", [982]="Revive Pet"})[id] or original(id) end
    C_SpellBook.IsSpellKnown = function() return true end
    d.hideNoPet, d.petControlsCollapsed = true, true
    assert(F.applySettings(d))
    local p, card = F.panel, F.panel.callCard
    -- The pet-existence condition keeps a present dead pet on the normal Revive panel.
    assert(p.condition == "[@pet,noexists] hide; show" and card.condition == "[@pet,noexists] show; hide")
    assert(card.layoutWidth < p.layoutWidth and card.layoutHeight == 44)
    assert(card.binding == p.care[1].binding and card.scripts.OnMouseUp)
    assert(card.attributes["*macrotext1"] == "/cast [mod:shift,@pet,noexists] Revive Pet; [@pet,noexists] Call Pet")
    d.hideCombat = true
    assert(F.applySettings(d) and card.condition == "[combat] hide; [@pet,noexists] show; hide")
    d.showMinimap, d.panelHidden = true, true
    assert(F.applySettings(d) and p.condition == "hide" and card.condition == "hide")
    d.panelHidden, d.instance = false, "inside"
    inside = false
    assert(F.applySettings(d) and card.condition == "hide")
    d.instance, d.showCare = "any", false
    assert(F.applySettings(d) and card.condition == "hide" and not card.attributes["*type1"])
    C_Spell.GetSpellName, C_SpellBook.IsSpellKnown = original, known
end)
test("summon card uses the current stable portrait and remembers this character's pet across dismissal", function()
    local card = F.panel.callCard
    local stable = {name="Bear", displayID=42, icon=10}
    local previousName = UnitName
    exists = false
    C_StableInfo = { GetStablePetInfo=function(slot) assert(slot == 1) return stable end }
    SetPortraitTextureFromCreatureDisplayID = function(texture, id) texture.portraitID = id end
    F.refreshCallCard()
    assert(card.text:GetText() == "Call Bear" and card.icon.portraitID == 42)
    stable = nil
    F.refreshCallCard()
    assert(card.text:GetText() == "Call Bear" and ForeverPetModesLastPet.displayID == 42)
    exists = true
    UnitName = function() return "Moss" end
    stable = {name="Bear", displayID=42}
    F.refreshCallCard()
    assert(card.text:GetText() == "Call Moss" and not ForeverPetModesLastPet.displayID)
    exists, stable, ForeverPetModesLastPet = false, nil, nil
    F.refreshCallCard()
    assert(card.text:GetText() == "Call Pet")
    UnitName, exists, C_StableInfo = previousName, true, nil
end)
test("spare height separates status groups and yields to wrapping without shifting them on collapse", function()
    local originalName, known, indicatorRows = C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, F.indicatorRows
    C_Spell.GetSpellName = function(id) return id == 136 and "Mend Pet" or originalName(id) end
    C_SpellBook.IsSpellKnown = function(id) return id == 136 end
    local rows = {{name="Growl", spell={on=true}, rules={}}, {name="Claw", spell={on=true}, rules={}}}
    F.indicatorRows = function() return rows end
    local d = F.loadSettings({})
    d.title, d.width, d.height = false, 75, 32
    assert(F.applySettings(d))
    local p, m = F.panel, F.panelMetrics
    local height, inset = p.layoutHeight, p.statusInset
    assert(inset > 0 and p.status.lastPoint[3] == -inset)
    assert(p.abilities.lastPoint[2] == p.status and p.abilities.lastPoint[5] == -(m.gap + inset))
    assert(p.chips[1].parent == p.abilities and p.chips[1].y == p.chips[2].y)
    assert(height == p.petColumnBottom + m.gripSize)
    d.petControlsCollapsed = true
    assert(F.applySettings(d) and p.layoutHeight == height and p.statusInset == inset)
    for i = 3, 8 do rows[i] = {name="Long ability name " .. i, spell={on=true}, rules={}} end
    F.refresh()
    assert(p.statusInset == 0 and p.layoutHeight > height)
    assert(p.chips[4].y == p.chips[3].y and p.chips[3].y - p.chips[1].y == m.gap + m.chipHeight)
    rows = {}
    F.refresh()
    assert(not p.chips[1].shown and p.layoutHeight == height)
    C_Spell.GetSpellName, C_SpellBook.IsSpellKnown, F.indicatorRows = originalName, known, indicatorRows
end)
test("Feed opens bag choices beneath the panel and targets only the selected edible stack", function()
    local d = F.loadSettings({})
    local spellName, known = C_Spell.GetSpellName, C_SpellBook.IsSpellKnown
    C_Spell.GetSpellName = function(id) return id == 6991 and "Feed Pet" or spellName(id) end
    C_SpellBook.IsSpellKnown = function(id) return id == 6991 end
    F.applySettings(d)
    local bag = {
        {itemID=100, stackCount=2, iconFileID=900},
        {itemID=101, stackCount=3, iconFileID=901},
        {itemID=100, stackCount=5, iconFileID=900},
        {itemID=102, stackCount=4, isLocked=true},
        {itemID=103, stackCount=1, iconFileID=903},
    }
    C_Container = {
        GetContainerNumSlots=function(id) return id == 0 and #bag or 0 end,
        GetContainerItemInfo=function(id, slot) return id == 0 and bag[slot] or nil end
    }
    C_PetInfo.CanPetEatItem = function(id) return id ~= 101 end
    GetCursorInfo = function() end
    SpellIsTargeting = function() return false end
    local p = F.panel
    function p:GetWidth() return self.layoutWidth end
    local feed = p.care[2]
    feed.scripts.PostClick(feed, "RightButton")
    assert(not p.foodPicker)
    feed.scripts.PostClick(feed, "LeftButton")
    local tray = p.foodPicker
    assert(tray.shown and tray.parent == feed and tray.lastPoint[2] == p and tray.lastPoint[3] == "BOTTOMLEFT")
    local first, second = unpack(tray.choices)
    assert(#tray.choices == 2 and first.food.id == 100 and first.count:GetText() == 7 and second.food.id == 103)
    assert(not feed.attributes["*type1"] and not first.attributes["*type1"])
    bag[1].itemID = 101
    first.scripts.PreClick(first)
    assert(not first.attributes["*type1"])
    first.scripts.PostClick(first)
    assert(tray.shown and first.food.slot == 3 and first.count:GetText() == 5)
    first.scripts.OnMouseDown(first)
    bag[3].itemID = 104
    tray.scripts.OnEvent(tray)
    flush()
    first.scripts.PreClick(first)
    assert(first.food.id == 104 and not first.attributes["*type1"])
    first.scripts.PostClick(first)
    combat = true
    first.scripts.PreClick(first)
    assert(not first.attributes["*type1"])
    combat = false
    second.scripts.PreClick(second)
    assert(second.attributes["*type1"] == "spell" and second.attributes["*spell1"] == 6991)
    assert(second.attributes["*target-bag1"] == 0 and second.attributes["*target-slot1"] == 5)
    second.scripts.PostClick(second)
    assert(not tray.shown and not second.attributes["*target-slot1"] and not second.attributes["*type1"])
    bag = {}
    feed.scripts.PostClick(feed, "LeftButton")
    assert(tray.message.shown and tray.message:GetText():find("No suitable food", 1, true))
    for i = 1, 45 do bag[i] = {itemID=i+200, stackCount=1, iconFileID=i} end
    tray.scripts.OnEvent(tray)
    flush()
    assert(tray.next.shown and tray.next.enabled)
    tray.next.scripts.OnClick()
    assert(tray.page == 2 and first.food.id > 201 and tray.prev.enabled)
    dead = true
    tray.scripts.OnEvent(tray)
    flush()
    assert(not tray.shown)
    dead = false
    C_Spell.GetSpellName, C_SpellBook.IsSpellKnown = spellName, known
end)
test("stance artwork and long skill names retain a distinct readable state", function()
    local p, rows = F.panel, F.indicatorRows
    PET_DEFENSIVE_TEXTURE = "Interface\\Icons\\Ability_Defend"
    F.indicatorRows = function() return {{name=string.rep("Growl", 30), id=2649, spell={on=false, icon=132270}, rules={}}} end
    F.paintIndicators(p, {stance="Defensive"}, {})
    local chip = p.chips[1]
    assert(p.status:GetText():find(PET_DEFENSIVE_TEXTURE, 1, true))
    assert(chip.layoutWidth <= p.contentWidth and chip.text.layoutWidth < chip.layoutWidth)
    assert(chip.value:GetText() == "OFF" and chip.value.lastPoint[1] == "RIGHT")
    F.indicatorRows, PET_DEFENSIVE_TEXTURE = rows, nil
end)
test("skills form equal columns and preserve name or icon and state in each display mode", function()
    local original = F.indicatorRows
    local rows = {}
    for i, name in ipairs({"Growl", "Claw", "Dash", "Prowl", "Long ability name"}) do
        rows[i] = {name=name, id=i, spell={on=i % 2 == 1}, rules={}}
    end
    F.indicatorRows = function() return rows end
    local d = F.loadSettings({})
    local p, gap = F.panel, F.panelMetrics.gap
    local function check(mode, buttonWidth, columns)
        d.skillDisplay, d.width = mode, buttonWidth
        assert(F.applySettings(d))
        local width = p.chips[1].layoutWidth
        for i, row in ipairs(rows) do
            local chip = p.chips[i]
            assert(chip.layoutWidth == width and chip.x + width <= p.contentWidth + 0.001)
            assert(chip.x == ((i - 1) % columns) * (width + gap))
            assert(chip.y == math.floor((i - 1) / columns) * (F.panelMetrics.chipHeight + gap))
            assert(chip.text.shown == (mode ~= "Icon only") and chip.icon.shown == (mode ~= "Name only"))
            assert(chip.value:GetText() == (row.spell.on and "ON" or "OFF"))
        end
    end
    check("Icon and name", 75, 2)
    check("Icon and name", 150, 4)
    check("Icon only", 75, 3)
    check("Name only", 100, 3)
    rows[2].spell = nil
    F.refresh()
    assert(p.chips[2].value:GetText() == "Unavailable" and p.chips[1].width == p.chips[2].width)
    F.indicatorRows = original
end)
test("skill display choices save, cancel and default to both for old or invalid settings", function()
    for _, invalid in ipairs({false, "", "Neither"}) do
        assert(F.loadSettings({skillDisplay=invalid}).skillDisplay == "Icon and name")
    end
    assert(F.applySettings(F.loadSettings({})))
    F.openSettings()
    press("Icon and name")
    press("Save")
    assert(F.loadSettings(ForeverPetModesDB).skillDisplay == "Icon only")
    F.openSettings()
    press("Icon only")
    press("Cancel")
    assert(F.db.skillDisplay == "Icon only")
    F.openSettings()
    press("Icon only")
    press("Save")
    assert(F.loadSettings(ForeverPetModesDB).skillDisplay == "Name only")
end)
test("resize grip preserves the top left, reflows skills and saves size across folding and reload", function()
    local d = F.loadSettings({})
    d.width, d.height, d.title, d.scale = 75, 32, false, 1.25
    local original = F.indicatorRows
    F.indicatorRows = function() return {{name="Growl", rules={}}, {name="Claw", rules={}}, {name="Bite", rules={}}} end
    assert(F.applySettings(d))
    local p, grip = F.panel, F.panel.resizeGrip
    function p:GetLeft() return 125 end
    function p:GetTop() return 540 end
    function p:GetWidth() return self.layoutWidth end
    function p:GetHeight() return self.layoutHeight end
    function UIParent:GetEffectiveScale() return 1 end
    function UIParent:GetLeft() return 0 end
    function UIParent:GetRight() return 1200 end
    function UIParent:GetTop() return 800 end
    function UIParent:GetBottom() return 0 end
    local w, h, col = p.layoutWidth, p.layoutHeight, p.contentWidth
    assert(p.chips[2].y > 0 and grip.shown)
    cursorX, cursorY = 500, 500
    grip.scripts.OnDragStart(grip)
    cursorX, cursorY = 750, 425
    grip.scripts.OnUpdate(grip, 0.05)
    assert(p.layoutWidth == w + 200 and p.layoutHeight == h + 60)
    assert(p.chips[2].y == 0 and p.contentWidth == col + 200)
    assert(d.position.point == "TOPLEFT" and d.position.relative == "TOPLEFT")
    assert(d.position.x == 125 and d.position.y == -100)
    grip.scripts.OnDragStop(grip)
    assert(not grip.scripts.OnUpdate)
    F.togglePetControls()
    assert(p.layoutHeight == h + 60 and p.layoutWidth < w + 200 and p.contentWidth == col + 200)
    assert(F.applySettings(F.loadSettings(ForeverPetModesDB)))
    assert(F.db.columnWidth == col + 200 and F.db.minPanelHeight == h + 60)
    grip.scripts.OnClick(grip, "RightButton")
    assert(p.contentWidth == col and p.layoutHeight == h)
    grip.scripts.OnDragStart(grip)
    combat = true
    grip.scripts.OnUpdate(grip, 0.05)
    grip.scripts.OnDragStart(grip)
    assert(not grip.scripts.OnUpdate and F.db.columnWidth == 0)
    combat = false
    F.indicatorRows = original
end)
test("the movement gutter spans the top and stays clear of buttons with either title setting", function()
    local d, p = F.loadSettings({}), F.panel
    local started
    function p:StartMoving() started = true end
    for _, title in ipairs({false, true}) do
        d.title = title
        F.applySettings(d)
        local strip = p.dragStrip
        assert(strip.shown and strip.layoutHeight >= 20 and strip.mark.shown == not title)
        assert(strip.lastPoint[1] == "TOPRIGHT" and strip.layoutHeight <= -p.moodIcon.lastPoint[3])
        started = false
        strip.scripts.OnDragStart(strip)
        strip.scripts.OnDragStop(strip)
        assert(started and d.position.point == "BOTTOMLEFT")
    end
    d.locked, started = true, false
    F.applySettings(d)
    p.dragStrip.scripts.OnDragStart(p.dragStrip)
    p.resizeGrip.scripts.OnDragStart(p.resizeGrip)
    assert(not started and not p.resizeGrip.scripts.OnUpdate and not p.resizeGrip.shown and not p.dragStrip.shown)
end)
local function badgeText(badge)
    local times = {}
    for _, lane in ipairs(badge.lanes) do
        if lane.fill.shown then times[#times + 1] = lane.label:GetText() end
    end
    return badge.count:GetText() .. "  " .. table.concat(times, " · ")
end
test("hawk badge reconciles actual summons, cast order, death and reloading in either layout", function()
    local d = F.loadSettings({})
    assert(F.applySettings(d))
    local p, t = F.panel, F.panel.hawkTracker
    local badge = t.badges[1]
    local function notify(event, ...) t.scripts.OnEvent(t, event, ...) end
    local function text() return badgeText(badge) end
    local width, height = p.layoutWidth, p.layoutHeight
    assert(not badge.shown and badge.parent == p and t.badges[2].parent == p.callCard)
    hawkTime = 100
    notify("UNIT_SPELLCAST_SUCCEEDED", "player", "cast1", 1293241)
    assert(text() == "1/2  ~18s")
    assert(badge.lastPoint[2] == p.bg and badge.lastPoint[3] == "BOTTOMLEFT")
    assert(badge.lanes[2].label:GetText() == "—" and not badge.lanes[2].fill.shown)
    summons[3] = {true, "Faucon", 100.5, 18, 123, 1, 1293241}
    hawkTime = 101
    notify("PLAYER_TOTEM_UPDATE", 3)
    assert(text() == "1/2  18s")
    hawkTime = 107
    summons[2] = {true, "Faucon", 107, 18, 123, 1, 1293525}
    notify("PLAYER_TOTEM_UPDATE", 2)
    notify("UNIT_SPELLCAST_SUCCEEDED", "player", "cast2", 1293525)
    assert(text() == "2/2  12s · 18s")
    assert(badge.lanes[1].label.layoutWidth == badge.lanes[2].label.layoutWidth)
    assert(badge.lanes[1].fill.layoutWidth < badge.lanes[2].fill.layoutWidth)
    assert(p.layoutWidth == width and p.layoutHeight == height)
    d.petControlsCollapsed = true
    assert(F.applySettings(d) and p.layoutHeight == height and text() == "2/2  12s · 18s")
    summons[3] = {true, "Unrelated summon", 107, 20, 789, 1, 456}
    notify("PLAYER_TOTEM_UPDATE", 3)
    assert(text() == "1/2  18s")
    notify("PLAYER_ENTERING_WORLD")
    assert(text() == "1/2  18s")
    summons = {}
    notify("PLAYER_TOTEM_UPDATE", 2)
    assert(not badge.shown and not t.shown)
end)
test("restricted hawk timers expire independently and only successful player hawk casts count", function()
    local t = F.panel.hawkTracker
    local function cast(id, unit) t.scripts.OnEvent(t, "UNIT_SPELLCAST_SUCCEEDED", unit or "player", secret, id) end
    local function text() return badgeText(t.badges[1]) end
    combat = true
    summons[1] = {secret, secret, secret, secret, secret, secret, secret}
    hawkTime = 200
    cast(1293241, "party1")
    cast(1293241, secret)
    cast(secret)
    cast(3044)
    assert(not t.shown)
    cast(1293241)
    cast(1293241)
    assert(text() == "1/2  ~18s")
    hawkTime = 206
    cast(1293526)
    hawkTime = 212
    cast(1293527)
    assert(text() == "2/2  ~12s · ~18s")
    hawkTime = 224
    t.scripts.OnUpdate(t, 1)
    assert(text() == "1/2  ~6s")
    hawkTime = 230
    t.scripts.OnUpdate(t, 1)
    assert(not t.shown and not t.badges[1].shown)
    cast(1293241)
    cast(2641)
    assert(not t.shown)
    cast(1293241)
    t.scripts.OnEvent(t, "PLAYER_DEAD")
    assert(not t.shown)
    combat, summons = false, {}
    cast(1293241)
    local d = F.copy(F.db)
    d.showHawks = false
    assert(F.applySettings(d) and not t.enabled and not t.shown)
    playerClass, d.showHawks, d.huntersOnly = "WARLOCK", true, false
    assert(F.applySettings(d) and not t.enabled)
    playerClass = "HUNTER"
end)
test("hawk tab follows Feed and moves above the panel at the bottom of the screen", function()
    local p = F.panel
    assert(F.applySettings(F.loadSettings({})))
    local t, tray = p.hawkTracker, assert(p.foodPicker)
    local badge = t.badges[1]
    local width, height = p.layoutWidth, p.layoutHeight
    local bottom, visible = 100, false
    local oldVisible, oldBottom = tray.IsVisible, tray.GetBottom
    tray.IsVisible = function() return visible end
    tray.GetBottom = function() return bottom end
    t.scripts.OnEvent(t, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast3", 1293241)
    assert(badge.lastPoint[2] == p.bg)
    visible = true
    t.scripts.OnUpdate(t, 0.2)
    assert(badge.lastPoint[2] == tray and badge.lastPoint[5] < 0)
    bottom = 1
    t.scripts.OnUpdate(t, 0.2)
    assert(badge.lastPoint[2] == p and badge.lastPoint[3] == "TOPLEFT" and badge.lastPoint[5] > 0)
    visible = false
    t.scripts.OnUpdate(t, 0.2)
    assert(badge.lastPoint[2] == p.bg and p.layoutWidth == width and p.layoutHeight == height)
    assert(badgeText(t.badges[2]) == badgeText(badge))
    tray.IsVisible, tray.GetBottom = oldVisible, oldBottom
end)
test("dragging a hawk tab saves its own scaled screen position and right-click restores docking", function()
    local p, d = F.panel, F.loadSettings({})
    assert(F.applySettings(d))
    local t = p.hawkTracker
    t.scripts.OnEvent(t, "PLAYER_DEAD")
    local badge, card = unpack(t.badges)
    function UIParent:GetWidth() return 1200 end
    function UIParent:GetHeight() return 800 end
    function badge:GetEffectiveScale() return 0.5 end
    function badge:GetCenter() return 900, 600 end
    local pPoint, pWidth, pHeight = p.lastPoint, p.layoutWidth, p.layoutHeight
    SlashCmdList.FOREVERPETMODES("movehawks")
    assert(badge.shown and badge.count:GetText() == "0/2")
    badge.scripts.OnDragStart(badge)
    assert(badge.dragging)
    local before = badge.lastPoint
    t.scripts.OnUpdate(t, 0.2)
    assert(before == badge.lastPoint)
    badge.scripts.OnDragStop(badge)
    assert(not badge.dragging and F.db.hawkPosition.x == 0.375 and F.db.hawkPosition.y == 0.375)
    assert(p.lastPoint == pPoint and p.layoutWidth == pWidth and p.layoutHeight == pHeight)
    t.scripts.OnUpdate(t, 0.2)
    assert(not badge.shown)
    local restored = F.loadSettings(ForeverPetModesDB)
    restored.petControlsCollapsed = true
    assert(F.applySettings(restored))
    hawkTime = hawkTime + 6
    t.scripts.OnEvent(t, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast4", 1293241)
    assert(badge.lastPoint[2] == UIParent and badge.lastPoint[4] == 900 and badge.lastPoint[5] == 600)
    assert(card.lastPoint[2] == UIParent and card.lastPoint[4] == 450 and card.lastPoint[5] == 300)
    combat = true
    badge.scripts.OnDragStart(badge)
    card.scripts.OnClick(card, "RightButton")
    assert(not badge.dragging and F.db.hawkPosition.x == 0.375)
    combat = false
    F.openSettings()
    card.scripts.OnClick(card, "RightButton")
    press("Save")
    assert(not F.loadSettings(ForeverPetModesDB).hawkPosition.x)
    assert(badge.lastPoint[2] == p.bg and card.lastPoint[2] == p.callCard)
    assert(not F.loadSettings({hawkPosition={x=0.3, y=2}}).hawkPosition.x)
    t.scripts.OnEvent(t, "PLAYER_DEAD")
    F.db.locked = true
    badge.scripts.OnDragStart(badge)
    assert(not badge.dragging)
    SlashCmdList.FOREVERPETMODES("movehawks")
    badge.scripts.OnDragStart(badge)
    assert(badge.dragging)
    combat = true
    t.scripts.OnEvent(t, "PLAYER_REGEN_DISABLED")
    combat = false
    assert(not badge.dragging and not badge.shown)
end)
print(count .. " tests passed")
