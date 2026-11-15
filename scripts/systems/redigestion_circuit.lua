local GLOBAL = GLOBAL

local HUNGER_TABLES = {
    0.5,  -- 1 active module = 50% of negative effects remain
    0.25, -- 2 active modules = 25% remain
    0.00  -- 3 active modules = immunity
}

local function GetDigestionModules(inst)
    return math.min(GetActiveModuleCount(inst, "digestion"), #HUNGER_TABLES)
end

local function ShouldNegateFoodPenalty(inst)
    return HasSkill(inst, "wx78_circuitry_gammabuffs_1")
        and GetDigestionModules(inst) > 0
        and HasCharge(inst)
end

local function DigestionStatsNegate(inst, health_delta, hunger_delta, sanity_delta, food, feeder)
    if not ShouldNegateFoodPenalty(inst) then
        return health_delta, hunger_delta, sanity_delta
    end

    local modifier = HUNGER_TABLES[GetDigestionModules(inst)]
    if modifier == nil then
        return health_delta, hunger_delta, sanity_delta
    end

    if health_delta < 0 then
        health_delta = health_delta * modifier
    end

    if hunger_delta < 0 then
        hunger_delta = hunger_delta * modifier
    end

    if sanity_delta < 0 then
        sanity_delta = sanity_delta * modifier
    end

    return health_delta, hunger_delta, sanity_delta
end

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function()
        local eater = inst.components ~= nil and inst.components.eater or nil
        if eater == nil then
            return
        end

        -- Preserve a custom modifier installed by another mod.
        local old_fn = eater.custom_stats_mod_fn
        eater.custom_stats_mod_fn = function(eater_inst, health_delta, hunger_delta, sanity_delta, food, feeder)
            if old_fn ~= nil then
                health_delta, hunger_delta, sanity_delta =
                    old_fn(eater_inst, health_delta, hunger_delta, sanity_delta, food, feeder)
            end

            return DigestionStatsNegate(
                eater_inst, health_delta, hunger_delta, sanity_delta, food, feeder
            )
        end
    end)
end)
