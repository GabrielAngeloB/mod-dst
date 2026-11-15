local GLOBAL = GLOBAL

local COLD_SKILL = "wx78_circuitry_betabuffs_1"
local FREEZE_PER_MODULE = 1.25

local SLOW_TAG = "wx78_refrigerant_slow"
local SLOW_DURATION = 5
local SLOW_MULT = 49 / 90

local ICE_TIMER = 25
local ICE_CHECK_PERIOD = 0.5

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

local function GetColdModules(inst)
    return GetActiveModuleCount(inst, "cold")
end

local function CanMakeIce(inst)
    local moisture = inst.components ~= nil and inst.components.moisture or nil
    return HasSkill(inst, COLD_SKILL)
        and GetColdModules(inst) > 0
        and HasCharge(inst)
        and moisture ~= nil
        and moisture:GetMoisture() > 0
end

local function StopIceMaker(inst)
    if inst._wx78_icemaker_task ~= nil then
        inst._wx78_icemaker_task:Cancel()
        inst._wx78_icemaker_task = nil
    end
end

local function SpawnIce(wx)
    if not CanMakeIce(wx) then
        StopIceMaker(wx)
        return
    end

    local modules = GetColdModules(wx)
    local x, y, z = wx.Transform:GetWorldPosition()

    for i = 1, modules do
        local ice = GLOBAL.SpawnPrefab("ice")
        if ice ~= nil and ice.Transform ~= nil then
            ice.Transform:SetPosition(x, y, z)
            if wx.SoundEmitter ~= nil then
                wx.SoundEmitter:PlaySound("dontstarve_DLC001/common/iceboulder_smash")
            end
            GLOBAL.Launch(ice, wx, 1.3)
        end
    end
end

local function UpdateIceMaker(inst)
    if not CanMakeIce(inst) then
        StopIceMaker(inst)
        return
    end

    if inst._wx78_icemaker_task == nil then
        inst._wx78_icemaker_task = inst:DoPeriodicTask(ICE_TIMER, SpawnIce)
    end
end

local function FreezeAttacker(inst, attacker)
    if attacker == nil or attacker.components == nil
        or attacker.components.freezable == nil then
        return
    end

    local modules = GetColdModules(inst)
    if modules <= 0 then
        return
    end

    attacker.components.freezable:AddColdness(FREEZE_PER_MODULE * modules)
    attacker.components.freezable:SpawnShatterFX()
end

local function ApplySlow(inst, attacker)
    if attacker == nil or not attacker:IsValid()
        or attacker.components == nil
        or attacker.components.locomotor == nil then
        return
    end

    local data = attacker._wx78_slow_data
    if data == nil then
        data = { task = nil, endtime = nil }
        attacker._wx78_slow_data = data
    end

    local modules = GetColdModules(inst)
    if modules <= 0 then
        return
    end

    data.endtime = GLOBAL.GetTime() + SLOW_DURATION
    attacker.components.locomotor:SetExternalSpeedMultiplier(
        attacker, SLOW_TAG, SLOW_MULT ^ modules
    )

    local function UpdateColour()
        local d = attacker._wx78_slow_data
        if d == nil or not attacker:IsValid() then
            return
        end

        local remaining = d.endtime - GLOBAL.GetTime()
        if remaining <= 0 then
            PopColour(attacker)
            if attacker.components ~= nil and attacker.components.locomotor ~= nil then
                attacker.components.locomotor:RemoveExternalSpeedMultiplier(attacker, SLOW_TAG)
            end
            attacker._wx78_slow_data = nil
            return
        end

        local percent = math.max(0, math.min(1, remaining / SLOW_DURATION))
        PushColour(
            attacker,
            FREEZE_COLOUR[1] * percent,
            FREEZE_COLOUR[2] * percent,
            FREEZE_COLOUR[3] * percent,
            FREEZE_COLOUR[4] * percent
        )
        d.task = attacker:DoTaskInTime(0.2, UpdateColour)
    end

    if data.task ~= nil then
        data.task:Cancel()
    end
    UpdateColour()
end

local function ShouldFreeze(inst)
    return HasSkill(inst, COLD_SKILL)
        and GetColdModules(inst) > 0
        and HasCharge(inst)
end

local function OnColdAttacked(inst, data)
    if data == nil or data.attacker == nil or not ShouldFreeze(inst) then
        return
    end

    FreezeAttacker(inst, data.attacker)
    ApplySlow(inst, data.attacker)
end

local function HookCold(inst)
    if inst._cold_hooked then
        return
    end

    inst._cold_hooked = true

    inst:ListenForEvent("attacked", function(_, data)
        OnColdAttacked(inst, data)
    end)

    inst:ListenForEvent("moisturedelta", function()
        UpdateIceMaker(inst)
    end)

    UpdateIceMaker(inst)
    inst:DoPeriodicTask(ICE_CHECK_PERIOD, UpdateIceMaker)
end

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function()
        HookCold(inst)
    end)
end)
