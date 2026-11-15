--------------------------------------------------------------------------
-- CIRCUIT RESONANCE - EFFECTS (server side)
--
-- One entry per resonance id: { enable = fn(inst), disable = fn(inst) }.
--
-- Rules every effect follows:
--   * enable() is idempotent and disable() is always safe (even if never
--     enabled), so the engine can call them on every state transition.
--   * Only keyed modifiers owned by this system are used (never overwrite
--     combat.damagemultiplier, inst.Light, TUNING, ... which other circuits
--     write directly). A keyed modifier is SET, never added, so an effect can
--     never stack with itself.
--   * disable() removes EVERY task / listener / modifier created by enable().
--
-- Numbers come from Defs.TUNING (same source used by the displayed texts).
--------------------------------------------------------------------------

local Defs = require("resonance/wx_resonance_defs")
local T = Defs.TUNING

local M = {}

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local function GetState(inst, id)
    local all = inst._wx_resonance_state
    if all == nil then
        all = {}
        inst._wx_resonance_state = all
    end

    local state = all[id]
    if state == nil then
        state = {}
        all[id] = state
    end

    return state
end

local function StopTask(state, field)
    if state[field] ~= nil then
        state[field]:Cancel()
        state[field] = nil
    end
end

local function StartListener(inst, state, event, fn)
    if state.listeners == nil then
        state.listeners = {}
    end

    if state.listeners[event] ~= nil then
        return
    end

    state.listeners[event] = fn
    inst:ListenForEvent(event, fn)
end

local function StopListeners(inst, state)
    if state.listeners == nil then
        return
    end

    for event, fn in pairs(state.listeners) do
        inst:RemoveEventCallback(event, fn)
    end

    state.listeners = nil
end

-- "Dark" = night on the surface, or anywhere in the caves.
local function IsDarkWorld()
    local world = TheWorld
    return world ~= nil
        and (world:HasTag("cave") or (world.state ~= nil and world.state.isnight == true))
end

-- The sonic wave circuit announces itself through this state (see screech_circuit.lua).
local function IsSonicWaveStart(data)
    return data ~= nil and data.statename == "wx_screech_pre"
end

-- Returns true (and arms the cooldown) when the effect may fire now.
local function TryCooldown(state, cooldown)
    local now = GetTime()
    if state.last_fire ~= nil and now - state.last_fire < cooldown then
        return false
    end

    state.last_fire = now
    return true
end

--------------------------------------------------------------------------
-- 1. THERMAL EQUILIBRIUM (Thermal + Refrigerant)
--    While overheating or freezing, recovers a little health, softening
--    temperature damage. Only acts while hurt AND at a temperature extreme.
--------------------------------------------------------------------------
local function EquilibriumTick(inst)
    local t = T.thermal_equilibrium
    local health = inst.components.health
    local temperature = inst.components.temperature

    if health == nil or temperature == nil or temperature.current == nil then
        return
    end

    if health:IsDead() or not health:IsHurt() then
        return
    end

    local overheat = temperature.overheattemp or TUNING.OVERHEAT_TEMP or 70
    local current = temperature.current

    if current > overheat or current < 0 then
        health:DoDelta(t.HEAL_PER_SECOND * t.TICK, true, "wx_resonance_thermal_equilibrium")
    end
end

M.thermal_equilibrium = {
    enable = function(inst)
        local state = GetState(inst, "thermal_equilibrium")
        StopTask(state, "task")
        state.task = inst:DoPeriodicTask(T.thermal_equilibrium.TICK, EquilibriumTick)
    end,

    disable = function(inst)
        StopTask(GetState(inst, "thermal_equilibrium"), "task")
    end,
}

--------------------------------------------------------------------------
-- 2. SONIC HARMONY (Sonic-Invoker + Chorusbox)
--    Each sonic wave calms the user (and nearby allies) a little.
--------------------------------------------------------------------------
local ALLY_MUST_TAGS = { "player" }
local ALLY_CANT_TAGS = { "playerghost", "INLIMBO" }

local function SonicHarmonyOnState(inst, data)
    if not IsSonicWaveStart(data) then
        return
    end

    local t = T.sonic_harmony
    if not TryCooldown(GetState(inst, "sonic_harmony"), t.COOLDOWN) then
        return
    end

    if inst.components.sanity ~= nil then
        inst.components.sanity:DoDelta(t.SELF_SANITY)
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    for _, ally in ipairs(TheSim:FindEntities(x, y, z, t.ALLY_RADIUS, ALLY_MUST_TAGS, ALLY_CANT_TAGS)) do
        if ally ~= inst
            and ally.components.sanity ~= nil
            and (ally.components.health == nil or not ally.components.health:IsDead()) then
            ally.components.sanity:DoDelta(t.ALLY_SANITY)
        end
    end
end

M.sonic_harmony = {
    enable = function(inst)
        StartListener(inst, GetState(inst, "sonic_harmony"), "newstate", SonicHarmonyOnState)
    end,

    disable = function(inst)
        StopListeners(inst, GetState(inst, "sonic_harmony"))
    end,
}

--------------------------------------------------------------------------
-- 3. NIGHT SCOUT (Optoelectronic + Range Booster)
--    Slightly faster movement in the dark (night / caves).
--------------------------------------------------------------------------
local NIGHT_SCOUT_KEY = "wx_resonance_night_scout"

local function NightScoutSet(inst, state, on)
    local locomotor = inst.components.locomotor
    if locomotor == nil or state.applied == on then
        return
    end

    state.applied = on

    if on then
        locomotor:SetExternalSpeedMultiplier(inst, NIGHT_SCOUT_KEY, 1 + T.night_scout.SPEED_BONUS)
    else
        locomotor:RemoveExternalSpeedMultiplier(inst, NIGHT_SCOUT_KEY)
    end
end

local function NightScoutTick(inst)
    NightScoutSet(inst, GetState(inst, "night_scout"), IsDarkWorld())
end

M.night_scout = {
    enable = function(inst)
        local state = GetState(inst, "night_scout")
        StopTask(state, "task")
        state.task = inst:DoPeriodicTask(T.night_scout.TICK, NightScoutTick)
        NightScoutTick(inst)
    end,

    disable = function(inst)
        local state = GetState(inst, "night_scout")
        StopTask(state, "task")
        NightScoutSet(inst, state, false)
    end,
}

--------------------------------------------------------------------------
-- 4. ADAPTIVE PLATING (Blocking + Hardy)
--    When the block (wx_shielding) ends, the reinforced chassis keeps
--    absorbing impacts for a few seconds.
--------------------------------------------------------------------------
local PLATING_KEY = "wx_resonance_adaptive_plating"

local function PlatingRemove(inst)
    local state = GetState(inst, "adaptive_plating")
    StopTask(state, "expire")

    local combat = inst.components.combat
    if combat ~= nil and combat.externaldamagetakenmultipliers ~= nil then
        combat.externaldamagetakenmultipliers:RemoveModifier(inst, PLATING_KEY)
    end
end

local function PlatingStart(inst)
    local combat = inst.components.combat
    if combat == nil or combat.externaldamagetakenmultipliers == nil then
        return
    end

    local state = GetState(inst, "adaptive_plating")
    StopTask(state, "expire")

    combat.externaldamagetakenmultipliers:SetModifier(inst, T.adaptive_plating.DAMAGE_TAKEN_MULT, PLATING_KEY)
    state.expire = inst:DoTaskInTime(T.adaptive_plating.DURATION, PlatingRemove)
end

local function PlatingOnState(inst)
    local state = GetState(inst, "adaptive_plating")
    local shielding = inst:HasTag("wx_shielding")
    local was_shielding = state.was_shielding

    state.was_shielding = shielding

    if was_shielding and not shielding then
        PlatingStart(inst)
    end
end

M.adaptive_plating = {
    enable = function(inst)
        local state = GetState(inst, "adaptive_plating")
        state.was_shielding = inst:HasTag("wx_shielding")
        StartListener(inst, state, "newstate", PlatingOnState)
    end,

    disable = function(inst)
        local state = GetState(inst, "adaptive_plating")
        StopListeners(inst, state)
        PlatingRemove(inst)
        state.was_shielding = nil
    end,
}

--------------------------------------------------------------------------
-- 5. ECHOLOCATION (Sonic-Invoker + Range Booster)
--    Each sonic wave reveals the map around WX-78 (information only).
--------------------------------------------------------------------------
local function EcholocationReveal(inst)
    local explorer = inst.player_classified ~= nil and inst.player_classified.MapExplorer or nil
    if explorer == nil then
        return
    end

    local t = T.echolocation
    local x, _, z = inst.Transform:GetWorldPosition()

    explorer:RevealArea(x, 0, z)

    for ring = 1, t.RINGS do
        local radius = t.REVEAL_RADIUS * ring / t.RINGS
        local points = t.POINTS_PER_RING * ring

        for i = 0, points - 1 do
            local angle = (i / points) * 2 * math.pi
            explorer:RevealArea(x + radius * math.cos(angle), 0, z + radius * math.sin(angle))
        end
    end
end

local function EcholocationOnState(inst, data)
    if not IsSonicWaveStart(data) then
        return
    end

    if TryCooldown(GetState(inst, "echolocation"), T.echolocation.COOLDOWN) then
        EcholocationReveal(inst)
    end
end

M.echolocation = {
    enable = function(inst)
        StartListener(inst, GetState(inst, "echolocation"), "newstate", EcholocationOnState)
    end,

    disable = function(inst)
        StopListeners(inst, GetState(inst, "echolocation"))
    end,
}

--------------------------------------------------------------------------
-- 6. HEARTH GLOW (Thermal + Illumination)
--    Slightly lower hunger drain in the dark (night / caves).
--------------------------------------------------------------------------
local HEARTH_KEY = "wx_resonance_hearth_glow"

local function HearthSet(inst, state, on)
    local hunger = inst.components.hunger
    if hunger == nil or hunger.burnratemodifiers == nil or state.applied == on then
        return
    end

    state.applied = on

    if on then
        hunger.burnratemodifiers:SetModifier(inst, T.hearth_glow.HUNGER_BURN_MULT, HEARTH_KEY)
    else
        hunger.burnratemodifiers:RemoveModifier(inst, HEARTH_KEY)
    end
end

local function HearthTick(inst)
    HearthSet(inst, GetState(inst, "hearth_glow"), IsDarkWorld())
end

M.hearth_glow = {
    enable = function(inst)
        local state = GetState(inst, "hearth_glow")
        StopTask(state, "task")
        state.task = inst:DoPeriodicTask(T.hearth_glow.TICK, HearthTick)
        HearthTick(inst)
    end,

    disable = function(inst)
        local state = GetState(inst, "hearth_glow")
        StopTask(state, "task")
        HearthSet(inst, state, false)
    end,
}

return M
