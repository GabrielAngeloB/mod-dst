local GLOBAL = GLOBAL

local NEGATIVE_DELTA_MULTIPLIERS = {
    0.50, -- 1 active module: 50% of the penalty remains.
    0.25, -- 2 active modules: 25% remains.
    0.00, -- 3 active modules: immunity to negative stat deltas.
}

local function ShouldNegateFoodPenalty(inst)
    return HasSkill(inst, "wx78_circuitry_gammabuffs_1")
        and HasActiveModule(inst, "digestion")
        and HasCharge(inst)
end

local function DigestionStatsNegate(inst, health_delta, hunger_delta, sanity_delta, food, feeder)
    if not ShouldNegateFoodPenalty(inst) then
        return health_delta, hunger_delta, sanity_delta
    end

    local modules = math.min(
        GetActiveModuleCount(inst, "digestion"),
        #NEGATIVE_DELTA_MULTIPLIERS
    )
    local multiplier = NEGATIVE_DELTA_MULTIPLIERS[modules]

    if multiplier == nil then
        return health_delta, hunger_delta, sanity_delta
    end

    if health_delta < 0 then
        health_delta = health_delta * multiplier
    end
    if hunger_delta < 0 then
        hunger_delta = hunger_delta * multiplier
    end
    if sanity_delta < 0 then
        sanity_delta = sanity_delta * multiplier
    end

    return health_delta, hunger_delta, sanity_delta
end

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function()
        if inst:IsValid() and inst.components.eater ~= nil then
            inst.components.eater.custom_stats_mod_fn = DigestionStatsNegate
        end
    end)
end)
