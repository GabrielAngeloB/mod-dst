local GLOBAL = GLOBAL

--------------------------------------------------------------------------
-- WX78 Screech Aggro Fix (GATED BY CIRCUIT CONDITIONS)
-- Only runs if module + skill + charge are active.
--------------------------------------------------------------------------

local CLEAR_DIST = 25
local MUST_TAGS = { "_combat" }
local CANT_TAGS = { "INLIMBO" }

local function CanUseScreechCircuit(wx)
    return wx ~= nil and wx:IsValid()
        and HasActiveModule(wx, "screech")
        and HasSkill(wx, "wx78_circuitry_gammabuffs_1")
        and HasCharge(wx)
end

-- The vanilla stategraph supplies TUNING.WX78_SCREECH_COOLDOWN when the
-- ability ends. Shorten that call per WX-78 instead of mutating global TUNING.
AddComponentPostInit("wx78_abilitycooldowns", function(self)
    local old_restart = self.RestartAbilityCooldown
    if old_restart == nil then
        return
    end

    function self:RestartAbilityCooldown(ability, duration, ...)
        local player = self.inst
        if ability == "screech" and type(duration) == "number"
            and CanUseScreechCircuit(player) then
            duration = math.min(duration, 10)
        end

        return old_restart(self, ability, duration, ...)
    end
end)

local function ClearNearbyAggro(player)
    local x, y, z = player.Transform:GetWorldPosition()
    local ents = GLOBAL.TheSim:FindEntities(
        x, y, z,
        CLEAR_DIST,
        MUST_TAGS,
        CANT_TAGS
    )

    for _, entity in ipairs(ents) do
        if entity ~= nil and entity.components ~= nil
            and entity.components.combat ~= nil
            and entity.components.combat.target == player then
            entity.components.combat:SetTarget(nil)
        end
    end
end

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
            if inst._screechaggrotask ~= nil then
                inst._screechaggrotask:Cancel()
                inst._screechaggrotask = nil
            end
            return
        end

        if not CanUseScreechCircuit(inst) then
            if inst._screechaggrotask ~= nil then
                inst._screechaggrotask:Cancel()
                inst._screechaggrotask = nil
            end
            return
        end

        ClearNearbyAggro(inst)
        elapsed = elapsed + interval

        if elapsed >= duration and inst._screechaggrotask ~= nil then
            inst._screechaggrotask:Cancel()
            inst._screechaggrotask = nil
        end
    end)
end

AddPlayerPostInit(function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("newstate", function(player, data)
        if not CanUseScreechCircuit(player) then
            return
        end

        if data ~= nil and data.statename == "wx_screech_pre" then
            StartScreechAggroProtection(player)
        end
    end)
end)
