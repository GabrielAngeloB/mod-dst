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
-- SERVICES PROVIDED BY THE ENGINE MODULE (loaded in the mod environment)
--------------------------------------------------------------------------
local services = {}

function M.SetServices(new_services)
    services = new_services or {}
end

local function GetModuleCount(inst, name)
    return services.GetActiveModuleCount ~= nil
        and services.GetActiveModuleCount(inst, name) or 0
end

local function Trigger(inst, id)
    if services.Trigger ~= nil then
        services.Trigger(inst, id)
    end
end


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


--------------------------------------------------------------------------
-- ELITE TIER
--------------------------------------------------------------------------

local THREAT_MUST_TAGS = { "_combat" }
local THREAT_CANT_TAGS = { "INLIMBO", "player", "companion", "wall", "structure", "FX", "NOCLICK" }

local function CooldownReady(state, cooldown)
    return state.last_fire == nil or GetTime() - state.last_fire >= cooldown
end

local function FindThreats(inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    local threats = {}

    for _, target in ipairs(TheSim:FindEntities(x, y, z, radius, THREAT_MUST_TAGS, THREAT_CANT_TAGS)) do
        local combat = target.components ~= nil and target.components.combat or nil
        if target ~= inst and combat ~= nil and (target:HasTag("hostile") or combat.target == inst) then
            threats[#threats + 1] = target
        end
    end

    return threats, x, y, z
end

local function Blast(inst, threats, damage, knockback, max_targets, radius)
    local hit = 0
    for _, target in ipairs(threats) do
        if hit >= max_targets then break end
        if target:IsValid() and target.components ~= nil and target.components.combat ~= nil then
            target.components.combat:GetAttacked(inst, damage)
            hit = hit + 1
            if target:IsValid() then
                target:PushEvent("knockback", {
                    knocker = inst,
                    radius = radius + 4,
                    strengthmult = knockback,
                })
            end
        end
    end
    return hit
end

local function SpawnFX(prefab, x, y, z)
    local fx = SpawnPrefab(prefab)
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
    end
end

--------------------------------------------------------------------------
-- 7. ABSOLUTE ZERO (Refrigerant + Blocking)
--------------------------------------------------------------------------
local function AbsoluteZeroNova(inst, state, absorbed)
    local t = T.absolute_zero
    if not CooldownReady(state, t.COOLDOWN) then return end

    local threats = FindThreats(inst, t.RADIUS)
    local coldness = t.BASE_COLDNESS
        + t.BONUS_COLDNESS * math.min(absorbed, t.ABSORB_CAP) / t.ABSORB_CAP
    local affected = 0

    for _, target in ipairs(threats) do
        local freezable = target.components.freezable
        if freezable ~= nil then
            freezable:AddColdness(coldness)
            if freezable.SpawnShatterFX ~= nil then
                freezable:SpawnShatterFX()
            end
            affected = affected + 1
        end
    end

    if affected == 0 then return end
    state.last_fire = GetTime()
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/iceboulder_smash")
    end
    Trigger(inst, "absolute_zero")
end

local function AbsoluteZeroOnBlocked(inst, data)
    local state = GetState(inst, "absolute_zero")
    state.blocks = (state.blocks or 0) + 1
    state.absorbed = (state.absorbed or 0) + (data ~= nil and data.original_damage or 0)
end

local function AbsoluteZeroOnState(inst)
    local state = GetState(inst, "absolute_zero")
    local shielding = inst:HasTag("wx_shielding")
    local was_shielding = state.was_shielding
    state.was_shielding = shielding

    if shielding and not was_shielding then
        state.blocks, state.absorbed = 0, 0
    elseif was_shielding and not shielding then
        local blocks, absorbed = state.blocks or 0, state.absorbed or 0
        state.blocks, state.absorbed = 0, 0
        if blocks > 0 then
            AbsoluteZeroNova(inst, state, absorbed)
        end
    end
end

M.absolute_zero = {
    enable = function(inst)
        local state = GetState(inst, "absolute_zero")
        state.was_shielding = inst:HasTag("wx_shielding")
        state.blocks, state.absorbed = 0, 0
        StartListener(inst, state, "blocked", AbsoluteZeroOnBlocked)
        StartListener(inst, state, "newstate", AbsoluteZeroOnState)
    end,
    disable = function(inst)
        local state = GetState(inst, "absolute_zero")
        StopListeners(inst, state)
        state.was_shielding = nil
        state.blocks, state.absorbed = 0, 0
    end,
    ready = function(inst)
        return CooldownReady(GetState(inst, "absolute_zero"), T.absolute_zero.COOLDOWN)
    end,
}

--------------------------------------------------------------------------
-- 8. SUPERNOVA (Thermal + Sonic-Invoker)
--------------------------------------------------------------------------
local function SupernovaAction(inst)
    local t = T.supernova
    local temperature = inst.components.temperature
    if temperature == nil or temperature.current == nil or temperature.current < t.MIN_TEMP then
        return false
    end

    local threats, x, y, z = FindThreats(inst, t.RADIUS)
    if #threats == 0 then return false end

    local damage = t.DAMAGE
    if GetModuleCount(inst, "heat") >= 2 then
        damage = damage + t.EXTRA_MODULE_DAMAGE
    end

    if Blast(inst, threats, damage, t.KNOCKBACK, t.MAX_TARGETS, t.RADIUS) == 0 then
        return false
    end

    temperature:SetTemperature(t.COOLED_TEMP)
    SpawnFX("explode_small", x, y, z)
    Trigger(inst, "supernova")
end

local function SupernovaOnState(inst, data)
    if not IsSonicWaveStart(data) then return end
    local state = GetState(inst, "supernova")
    if not CooldownReady(state, T.supernova.COOLDOWN) then return end
    if SupernovaAction(inst) ~= false then
        state.last_fire = GetTime()
    end
end

M.supernova = {
    enable = function(inst)
        StartListener(inst, GetState(inst, "supernova"), "newstate", SupernovaOnState)
    end,
    disable = function(inst)
        StopListeners(inst, GetState(inst, "supernova"))
    end,
    ready = function(inst)
        local temperature = inst.components.temperature
        return CooldownReady(GetState(inst, "supernova"), T.supernova.COOLDOWN)
            and temperature ~= nil and temperature.current ~= nil
            and temperature.current >= T.supernova.MIN_TEMP
    end,
}

--------------------------------------------------------------------------
-- 9. FURY HYMN (Thermal + Chorusbox)
--------------------------------------------------------------------------
local FURY_MUST_TAGS = { "player" }
local FURY_CANT_TAGS = { "playerghost", "INLIMBO" }

local function FuryKey(inst)
    return "wx_resonance_fury_hymn_" .. tostring(inst.GUID)
end

local function FuryRelease(state, member)
    local task = state.members ~= nil and state.members[member] or nil
    if task ~= nil then
        task:Cancel()
        state.members[member] = nil
    end
    if not member:IsValid() then return end

    local key = state.modifier_key
    local combat = member.components ~= nil and member.components.combat or nil
    if combat ~= nil and combat.externaldamagemultipliers ~= nil then
        combat.externaldamagemultipliers:RemoveModifier(member, key)
    end
    local locomotor = member.components ~= nil and member.components.locomotor or nil
    if locomotor ~= nil then
        locomotor:RemoveExternalSpeedMultiplier(member, key)
    end
end

local function FuryApply(state, member, is_self)
    local t = T.fury_hymn
    local key = state.modifier_key
    local combat = member.components ~= nil and member.components.combat or nil
    local locomotor = member.components ~= nil and member.components.locomotor or nil

    if not is_self and combat ~= nil and combat.externaldamagemultipliers ~= nil then
        combat.externaldamagemultipliers:SetModifier(member, 1 + t.DAMAGE_BONUS, key)
    end
    if locomotor ~= nil then
        locomotor:SetExternalSpeedMultiplier(member, key, 1 + t.SPEED_BONUS)
    end

    if state.members[member] ~= nil then
        state.members[member]:Cancel()
    end
    state.members[member] = member:DoTaskInTime(t.LINGER, function()
        FuryRelease(state, member)
    end)
end

local function FuryTick(inst)
    local t = T.fury_hymn
    local state = GetState(inst, "fury_hymn")
    local temperature = inst.components.temperature
    state.members = state.members or {}

    for member, task in pairs(state.members) do
        if not member:IsValid() then
            if task ~= nil then task:Cancel() end
            state.members[member] = nil
        end
    end

    if temperature == nil or temperature.current == nil or temperature.current < t.MIN_TEMP then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    for _, member in ipairs(TheSim:FindEntities(x, y, z, t.RADIUS, FURY_MUST_TAGS, FURY_CANT_TAGS)) do
        if member.components.health == nil or not member.components.health:IsDead() then
            FuryApply(state, member, member == inst)
        end
    end
end

M.fury_hymn = {
    enable = function(inst)
        local state = GetState(inst, "fury_hymn")
        state.modifier_key = FuryKey(inst)
        state.members = state.members or {}
        StopTask(state, "task")
        state.task = inst:DoPeriodicTask(T.fury_hymn.TICK, FuryTick)
        FuryTick(inst)
    end,
    disable = function(inst)
        local state = GetState(inst, "fury_hymn")
        StopTask(state, "task")
        if state.members ~= nil then
            for member in pairs(state.members) do
                FuryRelease(state, member)
            end
            state.members = nil
        end
        state.modifier_key = nil
    end,
    ready = function(inst)
        local temperature = inst.components.temperature
        return temperature ~= nil and temperature.current ~= nil
            and temperature.current >= T.fury_hymn.MIN_TEMP
    end,
}

--------------------------------------------------------------------------
-- 10. GHOST PROTOCOL (Chorusbox + Range Booster)
--------------------------------------------------------------------------
local function GhostKey(inst)
    return "wx_resonance_ghost_protocol_" .. tostring(inst.GUID)
end

local function GhostClearAmbush(inst, state)
    StopTask(state, "ambush_timeout")
    state.ambush_pending = false
    local combat = inst.components.combat
    if combat ~= nil and combat.externaldamagemultipliers ~= nil then
        combat.externaldamagemultipliers:RemoveModifier(inst, state.modifier_key)
    end
end

local function GhostBreak(inst, state, preserve_ambush)
    local was_ghosted = state.ghosted == true
    state.ghosted = false
    state.still = 0

    if state.added_stealth_tag and inst:HasTag("stealth") then
        inst:RemoveTag("stealth")
    end
    state.added_stealth_tag = false

    if state.tinted and inst.AnimState ~= nil then
        inst.AnimState:SetMultColour(1, 1, 1, 1)
    end
    state.tinted = false

    if preserve_ambush and was_ghosted then
        state.ambush_pending = true
        StopTask(state, "ambush_timeout")
        state.ambush_timeout = inst:DoTaskInTime(5, function()
            GhostClearAmbush(inst, state)
        end)
    elseif not preserve_ambush then
        GhostClearAmbush(inst, state)
    end
end

local function GhostEnter(inst, state)
    local t = T.ghost_protocol
    local combat = inst.components.combat
    state.ghosted = true
    state.clear_ticks = 0

    if combat ~= nil and combat.externaldamagemultipliers ~= nil then
        combat.externaldamagemultipliers:SetModifier(inst, t.AMBUSH_MULT, state.modifier_key)
    end
    if not inst:HasTag("stealth") then
        inst:AddTag("stealth")
        state.added_stealth_tag = true
    else
        state.added_stealth_tag = false
    end
    if inst.AnimState ~= nil then
        inst.AnimState:SetMultColour(1, 1, 1, t.ALPHA)
        state.tinted = true
    end
    Trigger(inst, "ghost_protocol")
end

local function GhostClearAggro(inst, radius)
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, creature in ipairs(TheSim:FindEntities(x, y, z, radius, { "_combat" }, { "INLIMBO" })) do
        if creature.components.combat ~= nil and creature.components.combat.target == inst then
            creature.components.combat:SetTarget(nil)
        end
    end
end

local function GhostTick(inst)
    local t = T.ghost_protocol
    local state = GetState(inst, "ghost_protocol")
    local x, _, z = inst.Transform:GetWorldPosition()

    if state.px ~= nil then
        local dx, dz = x - state.px, z - state.pz
        if dx * dx + dz * dz > t.MOVE_EPSILON * t.MOVE_EPSILON then
            state.still = 0
            if state.ghosted then
                GhostBreak(inst, state, false)
            elseif state.ambush_pending then
                GhostClearAmbush(inst, state)
            end
        else
            state.still = (state.still or 0) + t.TICK
        end
    end
    state.px, state.pz = x, z

    if state.ghosted then
        state.clear_ticks = (state.clear_ticks or 0) + 1
        if state.clear_ticks % 2 == 0 then
            GhostClearAggro(inst, t.CLEAR_RADIUS)
        end
    elseif not state.ambush_pending
        and (state.still or 0) >= (IsDarkWorld() and t.STILL_TIME_DARK or t.STILL_TIME) then
        GhostEnter(inst, state)
    end
end

local function GhostOnAttack(inst)
    local state = GetState(inst, "ghost_protocol")
    if state.ghosted then
        GhostBreak(inst, state, true)
    else
        state.still = 0
        if state.ambush_pending then
            GhostClearAmbush(inst, state)
        end
    end
end

local function GhostOnAttackResolved(inst)
    local state = GetState(inst, "ghost_protocol")
    if state.ambush_pending then
        GhostClearAmbush(inst, state)
    end
end

local function GhostOnDisturbed(inst)
    GhostBreak(inst, GetState(inst, "ghost_protocol"), false)
end

M.ghost_protocol = {
    enable = function(inst)
        local state = GetState(inst, "ghost_protocol")
        state.modifier_key = GhostKey(inst)
        state.still, state.px, state.pz = 0, nil, nil
        StopTask(state, "task")
        state.task = inst:DoPeriodicTask(T.ghost_protocol.TICK, GhostTick)
        StartListener(inst, state, "attacked", GhostOnDisturbed)
        StartListener(inst, state, "onattackother", GhostOnAttack)
        StartListener(inst, state, "onhitother", GhostOnAttackResolved)
        StartListener(inst, state, "onmissother", GhostOnAttackResolved)
    end,
    disable = function(inst)
        local state = GetState(inst, "ghost_protocol")
        StopTask(state, "task")
        StopListeners(inst, state)
        GhostBreak(inst, state, false)
        state.still, state.px, state.pz = 0, nil, nil
        state.modifier_key = nil
    end,
    ready = function(inst)
        return GetState(inst, "ghost_protocol").ghosted == true
    end,
}

--------------------------------------------------------------------------
-- 11. PHOENIX PROTOCOL (Hardy + Thermal)
--------------------------------------------------------------------------
local function PhoenixEndInvincibility(inst, state)
    StopTask(state, "invulnerable")
    local health = inst.components.health
    if state.invincibility_owned and health ~= nil and health.SetInvincible ~= nil then
        health:SetInvincible(false)
    end
    state.invincibility_owned = false
end

local function PhoenixDisarm(inst, state)
    if not state.armed then return end
    state.armed = false
    local health = inst.components.health
    if health ~= nil and state.min_applied then
        health:SetMinHealth(state.previous_min or 0)
    end
    state.min_applied = false
end

local function PhoenixRise(inst, state)
    local t = T.phoenix_protocol
    local health = inst.components.health
    if health == nil then return end

    state.last_fire = GetTime()
    PhoenixDisarm(inst, state)
    health:SetPercent(t.REVIVE_PERCENT)

    local was_invincible = health.IsInvincible ~= nil
        and health:IsInvincible() or health.invincible == true
    if health.SetInvincible ~= nil and not was_invincible then
        health:SetInvincible(true)
        state.invincibility_owned = true
        StopTask(state, "invulnerable")
        state.invulnerable = inst:DoTaskInTime(t.INVINCIBLE, function()
            PhoenixEndInvincibility(inst, state)
        end)
    else
        state.invincibility_owned = false
    end

    local threats, x, y, z = FindThreats(inst, t.RADIUS)
    Blast(inst, threats, t.DAMAGE, 1.5, t.MAX_TARGETS, t.RADIUS)
    SpawnFX("explode_small", x, y, z)
    Trigger(inst, "phoenix_protocol")
end

local function PhoenixArm(inst, state)
    local health = inst.components.health
    if health == nil or state.armed then return end

    state.armed = true
    if health.SetMinHealth ~= nil then
        state.previous_min = health.minhealth
        health:SetMinHealth(math.max(state.previous_min or 0, T.phoenix_protocol.MIN_HEALTH))
        state.min_applied = true
    end

    if not health:IsDead() and health:GetPercent() <= T.phoenix_protocol.TRIGGER_PERCENT then
        PhoenixRise(inst, state)
    end
end

local function PhoenixOnHealthDelta(inst)
    local state = GetState(inst, "phoenix_protocol")
    local health = inst.components.health
    if state.armed and health ~= nil and not health:IsDead()
        and health:GetPercent() <= T.phoenix_protocol.TRIGGER_PERCENT then
        PhoenixRise(inst, state)
    end
end

local function PhoenixTick(inst)
    local state = GetState(inst, "phoenix_protocol")
    local health = inst.components.health
    if not state.armed and health ~= nil and not health:IsDead()
        and CooldownReady(state, T.phoenix_protocol.COOLDOWN) then
        PhoenixArm(inst, state)
    end
end

M.phoenix_protocol = {
    enable = function(inst)
        local state = GetState(inst, "phoenix_protocol")
        StopTask(state, "task")
        state.task = inst:DoPeriodicTask(T.phoenix_protocol.TICK, PhoenixTick)
        StartListener(inst, state, "healthdelta", PhoenixOnHealthDelta)
        PhoenixTick(inst)
    end,
    disable = function(inst)
        local state = GetState(inst, "phoenix_protocol")
        StopTask(state, "task")
        StopListeners(inst, state)
        PhoenixDisarm(inst, state)
        PhoenixEndInvincibility(inst, state)
    end,
    ready = function(inst)
        return CooldownReady(GetState(inst, "phoenix_protocol"), T.phoenix_protocol.COOLDOWN)
    end,
}

--------------------------------------------------------------------------
-- 12. TRACTOR BEAM (Spatializer + Range Booster)
--------------------------------------------------------------------------
local function TractorSnapshotTarget(inst, data)
    local target = data ~= nil and data.target or nil
    if target == nil or target == inst or not target:IsValid() then return end

    local state = GetState(inst, "tractor_beam")
    state.pending_targets = state.pending_targets or {}
    local previous = state.pending_targets[target]
    if previous ~= nil and previous.expire ~= nil then
        previous.expire:Cancel()
    end

    local x, y, z = target.Transform:GetWorldPosition()
    local before = {}
    for _, item in ipairs(TheSim:FindEntities(x, y, z, T.tractor_beam.RADIUS, { "_inventoryitem" }, { "INLIMBO", "NOCLICK", "FX", "heavy" })) do
        before[item] = true
    end

    local snapshot = { x = x, y = y, z = z, before = before }
    state.pending_targets[target] = snapshot
    snapshot.expire = inst:DoTaskInTime(T.tractor_beam.SNAPSHOT_TIMEOUT, function()
        if state.pending_targets ~= nil and state.pending_targets[target] == snapshot then
            state.pending_targets[target] = nil
        end
    end)
end

local function TryGiveTractorLoot(inst, item)
    local inventory = inst.components.inventory
    if inventory == nil or item == nil or not item:IsValid() then return false end

    local source_position = item:GetPosition()

    -- First use the normal inventory path, including its regular stacking and
    -- specialized-container handling. If it cannot take the item, the explicit
    -- powered-Spatializer fallback below gets another chance.
    if inventory:GiveItem(item, nil, source_position) then
        return true
    end

    local inventoryitem = item.components ~= nil and item.components.inventoryitem or nil
    if not item:IsValid() or inventoryitem == nil or inventoryitem.owner ~= nil then
        return true -- it was stacked, transferred or otherwise consumed
    end

    -- Spatializer storage is a locked wx78_inventorycontainer item in a
    -- special inventory slot, not the normal overflow container.
    for slot = 1, inventory:GetNumSlots() do
        local storage = inventory:GetItemInSlot(slot)
        local container = storage ~= nil and storage.prefab == "wx78_inventorycontainer"
            and storage.components ~= nil and storage.components.container or nil

        if container ~= nil and container.canbeopened
            and container:GiveItem(item, nil, source_position, false) then
            return true
        end

        if not item:IsValid() then
            return true
        end

        inventoryitem = item.components ~= nil and item.components.inventoryitem or nil
        if inventoryitem == nil or inventoryitem.owner ~= nil then
            return true
        end
    end

    return false
end

local function TractorSweep(inst, x, y, z, before)
    local inventory = inst.components.inventory
    if inventory == nil or not inst:IsValid() then return end

    local t = T.tractor_beam
    local attempted = 0
    for _, item in ipairs(TheSim:FindEntities(x, y, z, t.RADIUS, { "_inventoryitem" }, { "INLIMBO", "NOCLICK", "FX", "heavy" })) do
        if attempted >= t.MAX_ITEMS then break end

        local inventoryitem = item.components ~= nil and item.components.inventoryitem or nil
        if not before[item] and inventoryitem ~= nil
            and inventoryitem.owner == nil and inventoryitem.canbepickedup ~= false then
            attempted = attempted + 1
            TryGiveTractorLoot(inst, item)
        end
    end
end

local function TractorOnKilled(inst, data)
    local victim = data ~= nil and data.victim or nil
    if victim == nil then return end

    local state = GetState(inst, "tractor_beam")
    local snapshot = state.pending_targets ~= nil and state.pending_targets[victim] or nil
    if snapshot == nil then return end

    state.pending_targets[victim] = nil
    if snapshot.expire ~= nil then snapshot.expire:Cancel() end

    state.sweeps = state.sweeps or {}
    for _, delay in ipairs(T.tractor_beam.SWEEPS) do
        local task
        task = inst:DoTaskInTime(delay, function()
            state.sweeps[task] = nil
            TractorSweep(inst, snapshot.x, snapshot.y, snapshot.z, snapshot.before)
        end)
        state.sweeps[task] = true
    end
end

M.tractor_beam = {
    enable = function(inst)
        local state = GetState(inst, "tractor_beam")
        state.pending_targets = state.pending_targets or {}
        StartListener(inst, state, "onattackother", TractorSnapshotTarget)
        StartListener(inst, state, "onareaattackother", TractorSnapshotTarget)
        StartListener(inst, state, "killed", TractorOnKilled)
    end,
    disable = function(inst)
        local state = GetState(inst, "tractor_beam")
        StopListeners(inst, state)
        if state.pending_targets ~= nil then
            for target, snapshot in pairs(state.pending_targets) do
                if snapshot.expire ~= nil then snapshot.expire:Cancel() end
                state.pending_targets[target] = nil
            end
        end
        if state.sweeps ~= nil then
            for task in pairs(state.sweeps) do task:Cancel() end
            state.sweeps = nil
        end
    end,
}


return M
