local GLOBAL = GLOBAL

-----------------REDIGESTION CIRCUIT CHANGES: START-------------
-------------------------------------------------------
-- REDIGESTION CIRCUIT Skill:
-------------------------------------------------------

local HUNGER_TABLES = {
    0.5,  -- 1 module = 50% negative effects
    0.25, -- 2 modules = 75%
    0.00  -- 3 modules = immunity
}

-------------------------------------------------------
-- MODULE COUNT
-------------------------------------------------------
local function GetDigestionModules(inst)
    return inst._digestion_modules or 0
end

-------------------------------------------------------
-- CONDITIONS
-------------------------------------------------------
local function ShouldNegateFoodPenalty(inst)
    return HasSkill(inst, "wx78_circuitry_gammabuffs_1")
        and HasActiveModule(inst, "digestion")
        and HasCharge(inst)
end

-------------------------------------------------------
-- FOOD NEGATION FUNCTION
-------------------------------------------------------
local function DigestionStatsNegate(inst, health_delta, hunger_delta, sanity_delta, food, feeder)

    ---------------------------------------------------
    -- CONDITIONS
    ---------------------------------------------------
    if not ShouldNegateFoodPenalty(inst) then
        return health_delta, hunger_delta, sanity_delta
    end

    local modules = GetDigestionModules(inst)
    local modifier = HUNGER_TABLES[modules]

    if modifier == nil then
        return health_delta, hunger_delta, sanity_delta
    end

    ---------------------------------------------------
    -- NEGATIVE HEALTH
    ---------------------------------------------------
    if health_delta < 0 then
        health_delta = health_delta * modifier
    end

    ---------------------------------------------------
    -- NEGATIVE HUNGER
    ---------------------------------------------------
    if hunger_delta < 0 then
        hunger_delta = hunger_delta * modifier
    end

    ---------------------------------------------------
    -- NEGATIVE SANITY
    ---------------------------------------------------
    if sanity_delta < 0 then
        sanity_delta = sanity_delta * modifier
    end

    return health_delta, hunger_delta, sanity_delta
end
-----------------REDIGESTION CIRCUIT CHANGES: END-------------

-------------------------------------------------------
-- HOOK
-------------------------------------------------------
AddPrefabPostInit("wx78", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function()
        if inst.components.eater ~= nil then
            inst.components.eater.custom_stats_mod_fn = DigestionStatsNegate
        end
    end)
end)