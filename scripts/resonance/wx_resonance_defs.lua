--------------------------------------------------------------------------
-- CIRCUIT RESONANCE - SHARED DEFINITIONS
--
-- This module is loaded on both server and clients. Keep it data-oriented:
-- no mod configuration reads and no server-only entity operations here.
--------------------------------------------------------------------------

local GLOBAL = GLOBAL
local M = {}

M.CIRCUITS = {
    thermal        = { modules = { "heat" },                   skill = "wx78_circuitry_betabuffs_1",  config = "thermal"      },
    refrigerant    = { modules = { "cold" },                   skill = "wx78_circuitry_betabuffs_1",  config = "refrigerant"  },
    sonic          = { modules = { "screech" },                skill = "wx78_circuitry_gammabuffs_1", config = "screech"      },
    chorusbox      = { modules = { "music" },                  skill = "wx78_circuitry_betabuffs_1",  config = "chorusbox"    },
    optoelectronic = { modules = { "nightvision" },            skill = "wx78_circuitry_betabuffs_1",  config = "nightvision"  },
    rangebooster   = { modules = { "radar" },                  skill = "wx78_circuitry_betabuffs_1",  config = "rangebooster" },
    blocking       = { modules = { "shielding" },              skill = "wx78_circuitry_gammabuffs_2", config = "blocking"     },
    hardy          = { modules = { "maxhealth", "maxhealth2" }, skill = "wx78_circuitry_alphabuffs_1", config = "hardy"        },
    illumination   = { modules = { "light", "light2" },         skill = "wx78_circuitry_betabuffs_2",  config = "illumination" },
}

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

function M.GetAvailable(is_enabled)
    local list = {}
    for _, res in ipairs(M.RESONANCES) do
        local first = M.CIRCUITS[res.circuits[1]]
        local second = M.CIRCUITS[res.circuits[2]]
        if first ~= nil and second ~= nil
            and is_enabled(first.config) and is_enabled(second.config) then
            list[#list + 1] = res
        end
    end
    return list
end

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

function M.GetStrings()
    local strings = GLOBAL.L
    return strings ~= nil and strings.RESONANCE or {}
end

-- Replaces only the %s placeholders used by the translations. Escaped %% is
-- preserved as a literal percent sign without relying on unpack or pcall.
function M.GetText(res, field)
    local strings = M.GetStrings()
    local entries = strings.ENTRIES
    local entry = entries ~= nil and entries[res.id] or nil
    local formatted = entry ~= nil and entry[field] or nil

    if formatted == nil then
        return res.id
    end

    local marker = string.char(1)
    local text = formatted:gsub("%%%%", marker)
    local index = 0
    text = text:gsub("%%s", function()
        index = index + 1
        local value = res.values ~= nil and res.values[index] or ""
        return value
    end)

    return text:gsub(marker, function()
        return "%"
    end)
end

function M.GetCircuitName(key)
    local strings = M.GetStrings()
    return strings.CIRCUITS ~= nil and strings.CIRCUITS[key] or key
end

return M
