local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING

-- Global cooldown tuning is configured once when this option is loaded.
TUNING.WX78_SCREECH_COOLDOWN = 10

--------------------------------------------------------------------------
-- WX78 Screech Aggro Fix (GATED BY CIRCUIT CONDITIONS)
-- Only runs if module + skill + charge are active
--------------------------------------------------------------------------

local CLEAR_DIST = 25
local MUST_TAGS = { "_combat" }
local CANT_TAGS = { "INLIMBO" }

-------------------------------------------------------
-- CONDITION GATE
-------------------------------------------------------
local function CanUseScreechCircuit(wx)
    if wx == nil or not wx:IsValid() then
        return false
    end

    return HasActiveModule(wx, "screech")
        and HasSkill(wx, "wx78_circuitry_gammabuffs_1")
        and HasCharge(wx)
end

-------------------------------------------------------
-- AGGRO CLEAR
-------------------------------------------------------
local function ClearNearbyAggro(player)
    local x, y, z = player.Transform:GetWorldPosition()

    local ents = GLOBAL.TheSim:FindEntities(
        x, y, z,
        CLEAR_DIST,
        MUST_TAGS,
        CANT_TAGS
    )

    for _, v in ipairs(ents) do
        if v.components.combat
        and v.components.combat.target == player then
            v.components.combat:SetTarget(nil)
        end
    end
end

-------------------------------------------------------
-- CORE EFFECT
-------------------------------------------------------
local function StartScreechAggroProtection(inst)
    if inst._screechaggrotask ~= nil then
        inst._screechaggrotask:Cancel()
        inst._screechaggrotask = nil
    end

    local elapsed = 0
    local duration = 1
    local interval = 0.1

    inst._screechaggrotask = inst:DoPeriodicTask(interval, function()

        if not inst:IsValid() then
            return
        end

        ClearNearbyAggro(inst)

        elapsed = elapsed + interval

        if elapsed >= duration then
            if inst._screechaggrotask ~= nil then
                inst._screechaggrotask:Cancel()
                inst._screechaggrotask = nil
            end
        end
    end)
end

-------------------------------------------------------
-- HOOK
-------------------------------------------------------
AddPlayerPostInit(function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("newstate", function(inst, data)

        -- HARD GATE: if conditions fail, NOTHING HAPPENS
        if not CanUseScreechCircuit(inst) then
            return
        end
        -- The cooldown tuning is configured once at mod load.

if data ~= nil and data.statename == "wx_screech_pre" then
            StartScreechAggroProtection(inst)
        end
    end)
end)