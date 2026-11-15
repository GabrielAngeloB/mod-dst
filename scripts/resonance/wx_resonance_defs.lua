--------------------------------------------------------------------------
-- CIRCUIT RESONANCE - SHARED DEFINITIONS
--
-- Pure data + tiny helpers. This file is loaded with `require` on the
-- server (engine/effects) AND on clients (HUD), so it must never depend on
-- the mod environment (no HasActiveModule, no GetModConfigData, ...).
--
-- To add/rebalance a resonance:
--   1. add its numbers to M.TUNING
--   2. add an entry to M.RESONANCES (unique id + unique bit, never reuse a bit)
--   3. implement it in resonance/wx_resonance_effects.lua (same id)
--   4. add its texts to RESONANCE.ENTRIES in all stringlocalization_*.lua
--------------------------------------------------------------------------

local GLOBAL = GLOBAL or _G
local global_pcall = GLOBAL.pcall
local global_table = GLOBAL.table
local unpack = GLOBAL.unpack or (global_table ~= nil and global_table.unpack or nil)

local function ProtectedCall(fn, ...)
    if type(global_pcall) == "function" then
        return global_pcall(fn, ...)
    end

    -- Fallback for restricted mod environments where pcall is not exported.
    return true, fn(...)
end

local M = {}

--------------------------------------------------------------------------
-- CIRCUIT FAMILIES
--
-- A family is "online" when at least ONE of its modules is plugged in AND
-- activated (powered), the player owns the skill that enables that circuit's
-- effect in this mod, and WX-78 has charge. Skills/config keys mirror the
-- gating already used by each circuit file (noted on the right).
--------------------------------------------------------------------------
M.CIRCUITS = {
    thermal        = { modules = { "heat" },                   skill = "wx78_circuitry_betabuffs_1",  config = "thermal"      }, -- thermal_circuit.lua
    refrigerant    = { modules = { "cold" },                   skill = "wx78_circuitry_betabuffs_1",  config = "refrigerant"  }, -- refrigerant_circuit.lua
    sonic          = { modules = { "screech" },                skill = "wx78_circuitry_gammabuffs_1", config = "screech"      }, -- screech_circuit.lua
    chorusbox      = { modules = { "music" },                  skill = "wx78_circuitry_betabuffs_1",  config = "chorusbox"    }, -- chorusbox_circuit.lua
    optoelectronic = { modules = { "nightvision" },            skill = "wx78_circuitry_betabuffs_1",  config = "nightvision"  }, -- nightvision_circuit.lua
    rangebooster   = { modules = { "radar" },                  skill = "wx78_circuitry_betabuffs_1",  config = "rangebooster" }, -- rangebooster_circuit.lua
    blocking       = { modules = { "shielding" },              skill = "wx78_circuitry_gammabuffs_2", config = "blocking"     }, -- blocking_circuit.lua
    hardy          = { modules = { "maxhealth", "maxhealth2" }, skill = "wx78_circuitry_alphabuffs_1", config = "hardy"        }, -- hardy_circuit.lua
    illumination   = { modules = { "light", "light2" },        skill = "wx78_circuitry_betabuffs_2",  config = "illumination" }, -- ilumination_circuit.lua
}

--------------------------------------------------------------------------
-- TUNING (single source of truth: effects AND displayed texts use these)
--------------------------------------------------------------------------
M.TUNING = {
    thermal_equilibrium = { HEAL_PER_SECOND = 0.3, TICK = 0.5 },
    sonic_harmony       = { SELF_SANITY = 2, ALLY_SANITY = 1, ALLY_RADIUS = 12, COOLDOWN = 15 },
    night_scout         = { SPEED_BONUS = 0.05, TICK = 0.5 },
    adaptive_plating    = { DAMAGE_TAKEN_MULT = 0.85, DURATION = 3 },
    echolocation        = { REVEAL_RADIUS = 30, RINGS = 3, POINTS_PER_RING = 8, COOLDOWN = 20 },
    hearth_glow         = { HUNGER_BURN_MULT = 0.95, TICK = 0.5 },
}

local T = M.TUNING

local function pct(x)
    return math.floor(x * 100 + 0.5)
end

--------------------------------------------------------------------------
-- RESONANCES
--   bit    : position in the network bitmask (0..15). NEVER reuse/renumber.
--   values : numbers injected (in order) into the %s of the localized texts.
--------------------------------------------------------------------------
M.RESONANCES = {
    {
        id = "thermal_equilibrium", bit = 0, circuits = { "thermal", "refrigerant" },
        values = { T.thermal_equilibrium.HEAL_PER_SECOND },
    },
    {
        id = "sonic_harmony", bit = 1, circuits = { "sonic", "chorusbox" },
        values = {
            T.sonic_harmony.SELF_SANITY, T.sonic_harmony.ALLY_SANITY,
            T.sonic_harmony.ALLY_RADIUS, T.sonic_harmony.COOLDOWN,
        },
    },
    {
        id = "night_scout", bit = 2, circuits = { "optoelectronic", "rangebooster" },
        values = { pct(T.night_scout.SPEED_BONUS) },
    },
    {
        id = "adaptive_plating", bit = 3, circuits = { "blocking", "hardy" },
        values = { pct(1 - T.adaptive_plating.DAMAGE_TAKEN_MULT), T.adaptive_plating.DURATION },
    },
    {
        id = "echolocation", bit = 4, circuits = { "sonic", "rangebooster" },
        values = { T.echolocation.COOLDOWN },
    },
    {
        id = "hearth_glow", bit = 5, circuits = { "thermal", "illumination" },
        values = { pct(1 - T.hearth_glow.HUNGER_BURN_MULT) },
    },
}

--------------------------------------------------------------------------
-- AVAILABILITY (respects the per-circuit config toggles of the mod)
--------------------------------------------------------------------------
function M.GetAvailable(is_enabled)
    local list = {}
    for _, res in ipairs(M.RESONANCES) do
        local a = M.CIRCUITS[res.circuits[1]]
        local b = M.CIRCUITS[res.circuits[2]]
        if is_enabled(a.config) and is_enabled(b.config) then
            list[#list + 1] = res
        end
    end
    return list
end

--------------------------------------------------------------------------
-- NETWORK BITMASK (no bit library: plain arithmetic)
--------------------------------------------------------------------------
function M.EncodeMask(active)
    local mask = 0
    for _, res in ipairs(M.RESONANCES) do
        if active[res.id] then
            mask = mask + math.floor(2 ^ res.bit)
        end
    end
    return mask
end

function M.IsInMask(mask, res)
    return math.floor((mask or 0) / math.floor(2 ^ res.bit)) % 2 == 1
end

--------------------------------------------------------------------------
-- TEXTS
--------------------------------------------------------------------------
function M.GetStrings()
    local L = GLOBAL.rawget(GLOBAL, "L")
    if L ~= nil and L.RESONANCE ~= nil then
        return L.RESONANCE
    end

    local ok, en = ProtectedCall(require, "stringlocalization_en")
    if ok and type(en) == "table" and en.RESONANCE ~= nil then
        return en.RESONANCE
    end

    return {}
end

-- field: "NAME" | "SHORT" | "DESC"
function M.GetText(res, field)
    local strings = M.GetStrings()
    local entry = strings.ENTRIES ~= nil and strings.ENTRIES[res.id] or nil
    local fmt = entry ~= nil and entry[field] or nil

    if fmt == nil then
        return res.id
    end

    local ok, text = ProtectedCall(GLOBAL.string.format, fmt, unpack(res.values))
    return ok and text or fmt
end

function M.GetCircuitName(key)
    local strings = M.GetStrings()
    return (strings.CIRCUITS ~= nil and strings.CIRCUITS[key]) or key
end

return M
