-- Run from the repository root with Lua 5.1. These fixtures do not execute WoW macros.
local F, count = {}, 0
local slots, exists, dead, combat, bar, inside, secret = {}, true, false, false, true, false, {}
local frames, callbacks, chat = {}, {}, {}
local strict = { SetAttribute=true, SetSize=true, SetPoint=true, ClearAllPoints=true, SetScale=true,
    StartMoving=true, StopMovingOrSizing=true, Show=true, Hide=true }
local methods = {}
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
function CreateFrame(kind, _, parent, template)
    local w = widget(kind, parent, template)
    w.protected = template == "InsecureActionButtonTemplate" or template == "SecureHandlerStateTemplate"
    assert(not (combat and w.protected))
    frames[#frames+1] = w
    return w
end
function methods:CreateTexture() return widget("Texture", self) end
function methods:CreateFontString() return widget("FontString", self) end
function methods:SetText(v) self.textValue = v end
function methods:GetText() return self.textValue end
function methods:Show() assert(not (combat and self.protected)) self.shown = true end
function methods:Hide() assert(not (combat and self.protected)) self.shown = false end
function methods:SetShown(v) self.shown = v end
function methods:IsShown() return self.shown end
function methods:SetScript(k, f) self.scripts[k] = f end
function methods:SetAttribute(k, v) assert(not combat) self.attributes[k] = v end
function methods:GetPoint() return "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 120, 140 end
function RegisterStateDriver(w, _, cond) assert(not combat) w.condition = cond end
function UnitExists() return exists end
function UnitIsDeadOrGhost() return dead end
function PetHasActionBar() return bar end
function GetPetActionInfo(i) return unpack(slots[i] or {}, 1, 7) end
function InCombatLockdown() return combat end
function IsInInstance() return inside end
function IsModifierKeyDown() return false end
function issecretvalue(v) return v == secret end
function GetBuildInfo() return "1.60.1", "71037", "", 16001 end
C_Spell = { GetSpellName=function(id) if id == 2649 then return "Knurren" end end }
C_Timer = { After=function(_, fn) callbacks[#callbacks+1] = fn end }
DEFAULT_CHAT_FRAME = { AddMessage=function(_, msg) chat[#chat+1] = msg end }
UIParent, SlashCmdList, UISpecialFrames, NUM_PET_ACTION_SLOTS = {}, {}, {}, 10
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
test("login builds profiles and matches a localized higher rank", function()
    event("ADDON_LOADED", "ForeverPetModes")
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
test("native rejection reports the remaining step instead of a success", function()
    soloButton.scripts.PostClick(soloButton)
    flush()
    assert(chat[#chat]:find("Select Defensive", 1, true))
    assert(chat[#chat]:find("Right-click Knurren", 1, true))
    assert(not soloButton.mark.shown)
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
    assert(not dungeonButton.mark.shown and not dungeonButton.attributes.type1)
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
    assert(chat[#chat]:find("in combat", 1, true))
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
test("corrupt fields recover without dropping adjacent valid edits", function()
    local d = F.loadSettings({ width=-1, height=54, inactive="zzzzzz", position={},
        profiles={ { rules="old", color=false, label="Keep me" }, false } })
    assert(d.width == 100 and d.height == 54 and d.position.point == "CENTER")
    assert(d.profiles[1].label == "Keep me" and d.profiles[1].rules[1].id == 2649)
    assert(d.profiles[2].stance == "Passive")
end)
print(count .. " tests passed")
