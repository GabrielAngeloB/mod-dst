local GLOBAL = GLOBAL

----------------REFRIGERANT CIRCUIT CHANGES: START------------
-- Refrigerant circuit freezes attackers + applies slow scaling
---------------------------------------------------------------

local COLD_SKILL = "wx78_circuitry_betabuffs_1"
local FREEZE_PER_MODULE = 1.25

-------------------------------------------------------
--                   SLOW CONFIG
-------------------------------------------------------

local SLOW_TAG = "wx78_refrigerant_slow"
local SLOW_DURATION = 5
local SLOW_MULT = 49 / 90

-------------------------------------------------------
--                   ICE MAKER CONFIG
-------------------------------------------------------

local ICE_TIMER = 25

-------------------------------------------------------
--                   FREEZE COLOR fx
-------------------------------------------------------

local FREEZE_COLOUR = { 82 / 255, 115 / 255, 124 / 255, 0 }

local function PushColour(inst, r, g, b, a)
    if inst.components ~= nil and inst.components.colouradder ~= nil then
        inst.components.colouradder:PushColour("wx78_refrigerant_slow", r, g, b, a)
    elseif inst.AnimState ~= nil then
        inst.AnimState:SetAddColour(r, g, b, a)
    end
end

local function PopColour(inst)
    if inst.components ~= nil and inst.components.colouradder ~= nil then
        inst.components.colouradder:PopColour("wx78_refrigerant_slow")
    elseif inst.AnimState ~= nil then
        inst.AnimState:SetAddColour(0, 0, 0, 0)
    end
end

-------------------------------------------------------
--                   MODULE COUNT
-------------------------------------------------------

local function GetColdModules(inst)
    local owner = inst.components.upgrademoduleowner
    if owner == nil then
        return 0
    end
    return GetActiveModuleCount(inst, "cold")
end

-------------------------------------------------------
--                   ICE MAKER
-------------------------------------------------------

local function CanMakeIce(inst)
    return HasSkill(inst, COLD_SKILL) and GetColdModules(inst) > 0 and HasCharge(inst)
end

local function StopIceMaker(inst)
    if inst.icemakertask ~= nil then
        inst.icemakertask:Cancel()
        inst.icemakertask = nil
    end
end

local function UpdateIceMaker(inst)
    local moisture = inst.components.moisture
    local can_run = CanMakeIce(inst)
        and moisture ~= nil
        and moisture:GetMoisture() > 0

    if not can_run then
        StopIceMaker(inst)
        return
    end

    if inst.icemakertask == nil then
        inst.icemakertask = inst:DoPeriodicTask(ICE_TIMER, function(wx)
            local wx_moisture = wx.components.moisture
            if not CanMakeIce(wx) or wx_moisture == nil
                or wx_moisture:GetMoisture() <= 0 then
                StopIceMaker(wx)
                return
            end

            local modules = GetColdModules(wx)
            local x, y, z = wx.Transform:GetWorldPosition()

            for _ = 1, modules do
                local ice = SpawnPrefab("ice")
                if ice ~= nil then
                    ice.Transform:SetPosition(x, y, z)
                    if wx.SoundEmitter ~= nil then
                        wx.SoundEmitter:PlaySound("dontstarve_DLC001/common/iceboulder_smash")
                    end
                    Launch(ice, wx, 1.3)
                end
            end
        end)
    end
end
-------------------------------------------------------
--                   FREEZE EFFECT
-------------------------------------------------------

local function FreezeAttacker(inst, attacker)
    if attacker == nil then return end
    if attacker.components == nil or attacker.components.freezable == nil then return end

    local modules = GetColdModules(inst)
    if modules <= 0 then return end

    attacker.components.freezable:AddColdness(FREEZE_PER_MODULE * modules)
    attacker.components.freezable:SpawnShatterFX()
end

-------------------------------------------------------
--                   SLOW EFFECT
-------------------------------------------------------

local function ApplySlow(inst, attacker)
    if attacker == nil then return end
    if attacker.components == nil or attacker.components.locomotor == nil then return end

    local data = attacker._wx78_slow_data

    if data == nil then
        data = { task = nil, endtime = nil }

        attacker._wx78_slow_data = data
    end

    data.endtime = GetTime() + SLOW_DURATION

    local modules = GetColdModules(inst)
    if modules <= 0 then return end

    local mult = SLOW_MULT ^ modules

    attacker.components.locomotor:SetExternalSpeedMultiplier(attacker, SLOW_TAG, mult)

    local function UpdateColour()
        local d = attacker._wx78_slow_data
        if d == nil then return end

        local t = d.endtime - GetTime()

        if t <= 0 then
            PopColour(attacker)

            attacker.components.locomotor:RemoveExternalSpeedMultiplier(attacker, SLOW_TAG)
            attacker._wx78_slow_data = nil
            return
        end

        local percent = math.clamp(t / SLOW_DURATION, 0, 1)

        PushColour(
            attacker, FREEZE_COLOUR[1] * percent, FREEZE_COLOUR[2] * percent, FREEZE_COLOUR[3] * percent,
            FREEZE_COLOUR[4] * percent
        )

        d.task = attacker:DoTaskInTime(0.2, UpdateColour)
    end

    if data.task ~= nil then
        data.task:Cancel()
    end

    UpdateColour()
end

-------------------------------------------------------
--                   CONDITIONS
-------------------------------------------------------

local function ShouldFreeze(inst)
    return HasSkill(inst, COLD_SKILL) and GetColdModules(inst) > 0 and HasCharge(inst)
end

-------------------------------------------------------
--                   ATTACK EVENT
-------------------------------------------------------

local function OnColdAttacked(inst, data)
    if data == nil or data.attacker == nil then
        return
    end

    if not ShouldFreeze(inst) then
        return
    end

    FreezeAttacker(inst, data.attacker)
    ApplySlow(inst, data.attacker)
end

-------------------------------------------------------
--                   HOOK
-------------------------------------------------------

local function HookCold(inst)
    if inst._cold_hooked then
        return
    end

    inst._cold_hooked = true

    inst:ListenForEvent("attacked", function (_, data)
        OnColdAttacked(inst, data)
    end)

    inst:ListenForEvent("moisturedelta", function()
        UpdateIceMaker(inst)
    end)

    -- Skill, charge and module activation can change without moisture events.
    inst._wx_ice_maker_watch = inst:DoPeriodicTask(1, UpdateIceMaker)
    UpdateIceMaker(inst)
end

-------------------------------------------------------
--                   INIT
-------------------------------------------------------

AddPrefabPostInit("wx78", function (inst)
    if not GLOBAL.TheNet:GetIsServer() then
        return
    end

    inst:DoTaskInTime(0, function ()
        HookCold(inst)
    end)
end)
