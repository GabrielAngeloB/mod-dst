local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING
local tonumber = GLOBAL.tonumber or function(value)
    return type(value) == "number" and value or 0
end

TUNING.WX78_SHIELDING_ARMOR = 0

local function IsWXBlocking(inst)
    return inst ~= nil and inst.prefab == "wx78" and inst:HasTag("wx_shielding")
end

AddComponentPostInit("combat", function(self)
    local old_get_attacked = self.GetAttacked
    if old_get_attacked == nil then
        return
    end

    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        local inst = self.inst

        if IsWXBlocking(inst) then
            local real_damage = tonumber(damage) or 0

            if inst.SoundEmitter ~= nil then
                inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_mech_lrg_sharp")
            end

            if inst.sg ~= nil and inst.sg.mem ~= nil then
                inst.sg.mem.wx78shieldingdamage =
                    (inst.sg.mem.wx78shieldingdamage or 0) + real_damage

                if inst.sg.mem.wx78shieldingdamage >= 100 then
                    inst.sg.mem.wx78shieldingdamage = 0
                    inst.sg:GoToState("wx_shield_pst")
                end
            end

            inst:PushEvent("blocked", {
                attacker = attacker,
                damage = 0,
                spdamage = nil,
                original_damage = real_damage
            })
            return false
        end

        return old_get_attacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
    end
end)

local function CanUseBlockingCircuit(wx)
    return wx ~= nil and wx:IsValid()
        and HasActiveModule(wx, "shielding")
        and HasSkill(wx, "wx78_circuitry_gammabuffs_2")
        and HasCharge(wx)
end

local function ApplyShieldingCooldownReduction()
    -- This is a game-wide TUNING value in the current WX-78 implementation;
    -- it cannot be changed per player through the public component API.
    TUNING.WX78_SHIELDING_COOLDOWN = 10
end

local function ApplyBlockingTags(inst)
    if not inst:HasTag("heavybody") then
        inst:AddTag("heavybody")
        inst._dwx78_added_heavybody = true
    end
end

local function RemoveBlockingTags(inst)
    if inst._dwx78_added_heavybody then
        inst:RemoveTag("heavybody")
        inst._dwx78_added_heavybody = nil
    end
end

local function CanUseTaserCircuit(wx)
    return wx ~= nil and wx:IsValid()
        and HasActiveModule(wx, "taser")
        and HasCharge(wx)
end

local function UpdateTaserBonusDamage(inst)
    local combat = inst.components ~= nil and inst.components.combat or nil
    local modifiers = combat ~= nil and combat.externaldamagemultipliers or nil
    if modifiers == nil then
        return
    end

    if CanUseTaserCircuit(inst) then
        modifiers:SetModifier(inst, 1.25, "taser_damage_bonus")
    else
        modifiers:RemoveModifier(inst, "taser_damage_bonus")
    end
end

GLOBAL.TUNING.WX78_ZAPDRONE_RANGE = 25
GLOBAL.TUNING.WX78_ZAPDRONE_MAX_RANGE = 40

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("newstate", function()
        if CanUseBlockingCircuit(inst) then
            ApplyShieldingCooldownReduction()
        end
    end)

    inst:DoPeriodicTask(0.5, function()
        if not CanUseBlockingCircuit(inst) then
            RemoveBlockingTags(inst)
        else
            ApplyBlockingTags(inst)
        end
        UpdateTaserBonusDamage(inst)
    end)
end)
