-- Regression checks for the standard and elite resonance tier.
-- Run from the repository root with Lua 5.1.

package.path = "./scripts/?.lua;" .. package.path

local locales = {
    "stringlocalization_en",
    "stringlocalization_pt_br",
    "stringlocalization_es",
    "stringlocalization_ch",
}

_G.L = require("stringlocalization_en")

local Defs = require("resonance/wx_resonance_defs")
local Effects = require("resonance/wx_resonance_effects")

assert(#Defs.RESONANCES == 12, "expected six standard and six elite resonances")
assert(#Defs.GetAvailable(function() return true end) == 12,
    "all resonances should be available when all options are enabled")
assert(#Defs.GetAvailable(function(name) return name ~= Defs.ELITE_OPTION end) == 6,
    "disabling elite resonances must preserve the six standard resonances")
assert(Defs.TUNING.tractor_beam.SNAPSHOT_TIMEOUT > 0,
    "Tractor Beam snapshot timeout must be configured")

local ids, bits = {}, {}
for _, res in ipairs(Defs.RESONANCES) do
    assert(not ids[res.id], "duplicate resonance id: " .. tostring(res.id))
    assert(not bits[res.bit], "duplicate resonance bit: " .. tostring(res.bit))
    assert(res.bit >= 0 and res.bit <= 15, "resonance bit does not fit net_ushortint mask")
    ids[res.id], bits[res.bit] = true, true

    assert(Defs.CIRCUITS[res.circuits[1]] ~= nil, "unknown first circuit in " .. res.id)
    assert(Defs.CIRCUITS[res.circuits[2]] ~= nil, "unknown second circuit in " .. res.id)
    assert(type(Effects[res.id]) == "table", "missing effect implementation: " .. res.id)
    assert(type(Effects[res.id].enable) == "function", "missing enable handler: " .. res.id)
    assert(type(Effects[res.id].disable) == "function", "missing disable handler: " .. res.id)
end

assert(Effects.SetServices ~= nil, "engine/effects service bridge is missing")

local effects_file = assert(io.open("scripts/resonance/wx_resonance_effects.lua", "r"))
local effects_source = effects_file:read("*a")
effects_file:close()
assert(effects_source:find('StartListener(inst, state, "onattackother", TractorSnapshotTarget)', 1, true),
    "Tractor Beam must snapshot items before the primary attack")
assert(effects_source:find('StartListener(inst, state, "onareaattackother", TractorSnapshotTarget)', 1, true),
    "Tractor Beam must snapshot items before area attacks")
assert(effects_source:find('T.tractor_beam.SNAPSHOT_TIMEOUT', 1, true),
    "Tractor Beam must expire stale target snapshots")
assert(effects_source:find('storage.prefab == "wx78_inventorycontainer"', 1, true),
    "Tractor Beam must locate WX-78's special Spatializer storage")
assert(effects_source:find('container:GiveItem(item, nil, source_position, false)', 1, true),
    "Tractor Beam must explicitly fall back to the powered Spatializer storage")
assert(effects_source:find('inventory:GiveItem(item, nil, source_position, false)', 1, true),
    "Tractor Beam must try regular inventory slots without dropping on failure")
assert(not effects_source:find("inventory:IsFull()", 1, true),
    "Tractor Beam must not skip specialized/overflow storage when regular slots are full")

-- Every locale must provide all names, HUD summaries and format-safe descriptions.
for _, locale in ipairs(locales) do
    _G.L = require(locale)
    local strings = _G.L.RESONANCE

    assert(strings ~= nil, locale .. " has no RESONANCE table")
    assert(strings.SPEECH_TRIGGER ~= nil, locale .. " has no trigger speech")
    assert(strings.STATE_RECHARGING ~= nil, locale .. " has no recharge label")
    assert(strings.STATE_STANDBY ~= nil, locale .. " has no standby label")
    assert(strings.CIRCUITS.spatializer ~= nil, locale .. " has no Spatializer circuit name")

    for _, res in ipairs(Defs.RESONANCES) do
        assert(strings.ENTRIES[res.id] ~= nil, locale .. " is missing " .. res.id)
        local short = Defs.GetText(res, "SHORT")
        local desc = Defs.GetText(res, "DESC")
        assert(type(short) == "string" and not short:find("%%s"), locale .. " has invalid SHORT for " .. res.id)
        assert(type(desc) == "string" and not desc:find("%%s"), locale .. " has invalid DESC for " .. res.id)
    end
end

-- Exercise Ghost Protocol's timing contract: its damage modifier must survive
-- attack launch and only be removed after the hit/miss result is reported.
local clock = 0
_G.GetTime = function() return clock end
_G.TheWorld = {
    state = { isnight = false },
    HasTag = function() return false end,
}
_G.TheSim = { FindEntities = function() return {} end }

local function NewTask(callback)
    return {
        callback = callback,
        cancelled = false,
        Cancel = function(self) self.cancelled = true end,
    }
end

local modifiers, handlers, tags = {}, {}, {}
local fake_alpha = 1
local fake = {
    GUID = 123,
    components = {
        combat = {
            externaldamagemultipliers = {
                SetModifier = function(_, source, value, key) modifiers[key] = value end,
                RemoveModifier = function(_, source, key) modifiers[key] = nil end,
            },
        },
    },
    Transform = {
        GetWorldPosition = function() return 0, 0, 0 end,
    },
    AnimState = {
        SetMultColour = function(_, r, g, b, a) fake_alpha = a end,
    },
}

function fake:IsValid() return true end
function fake:HasTag(tag) return tags[tag] == true end
function fake:AddTag(tag) tags[tag] = true end
function fake:RemoveTag(tag) tags[tag] = nil end
function fake:DoPeriodicTask(period, callback)
    self.periodic = NewTask(callback)
    self.periodic.period = period
    return self.periodic
end
function fake:DoTaskInTime(delay, callback)
    local task = NewTask(callback)
    task.delay = delay
    return task
end
function fake:ListenForEvent(event, callback) handlers[event] = callback end
function fake:RemoveEventCallback(event, callback)
    if handlers[event] == callback then handlers[event] = nil end
end

Effects.SetServices({
    GetActiveModuleCount = function() return 1 end,
    Trigger = function() end,
})

Effects.ghost_protocol.enable(fake)
for _ = 1, 20 do
    clock = clock + 0.25
    fake.periodic.callback(fake)
end

local ghost_key = "wx_resonance_ghost_protocol_123"
assert(fake:HasTag("stealth"), "Ghost Protocol should add stealth after standing still")
assert(modifiers[ghost_key] == 1.5, "Ghost Protocol should install the ambush multiplier")
assert(Effects.ghost_protocol.ready(fake), "Ghost Protocol should report ready while hidden")

handlers.onattackother(fake, { target = {} })
assert(not fake:HasTag("stealth"), "attack launch should immediately end stealth")
assert(modifiers[ghost_key] == 1.5,
    "attack launch must not remove the multiplier before damage is calculated")
assert(fake._wx_resonance_state.ghost_protocol.ambush_pending,
    "ambush should remain pending until the attack resolves")

handlers.onhitother(fake, { target = {} })
assert(modifiers[ghost_key] == nil, "successful hit should consume the ambush multiplier")
assert(not fake._wx_resonance_state.ghost_protocol.ambush_pending,
    "successful hit should clear pending ambush state")

for _ = 1, 20 do
    clock = clock + 0.25
    fake.periodic.callback(fake)
end
assert(fake:HasTag("stealth"), "Ghost Protocol should be able to re-enter stealth")
handlers.onattackother(fake, { target = {} })
assert(modifiers[ghost_key] == 1.5, "second ambush should be prepared")
handlers.attacked(fake, { attacker = {} })
assert(modifiers[ghost_key] == nil, "being attacked should immediately clear the ambush multiplier")

Effects.ghost_protocol.disable(fake)
assert(not fake:HasTag("stealth"), "disabling Ghost Protocol should restore stealth tag state")
assert(modifiers[ghost_key] == nil, "disabling Ghost Protocol should clear its damage modifier")

print("Elite resonance definition, localization and Ghost Protocol regression tests passed.")
