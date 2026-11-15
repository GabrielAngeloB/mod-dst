local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING

local HEAT_TARGET = 71
local DAMAGE_TEMP = 65
local HEAT_HOLD_TIME = 1.5

local HEAT_PER_MODULE = 7
local COOLING_PER_SECOND = 0.35
local HEAT_CONTROLLER_INTERVAL = 0.1

local DAMAGE_MODIFIER_KEY = "dwx78_thermal_overheat"

local function GetHeatModules(inst)
    local count = GetActiveModuleCount(inst, "heat")
    -- Preserve the original Thermal circuit gate: its effects require charge.
    return count > 0 and HasCharge(inst) and count or 0
end

local function HasHeatSkill(inst)
    return HasSkill(inst, "wx78_circuitry_betabuffs_1")
end

local function UpdateHeatSpeech(inst)
    local temp = inst.components ~= nil and inst.components.temperature or nil
    if temp == nil then
        return
    end

    local heatmods = GetHeatModules(inst)
    if heatmods <= 0 or not HasHeatSkill(inst) then
        inst._wx_overclock_state = false
        return
    end

    local is_overclock = temp.current >= DAMAGE_TEMP
    if is_overclock and not inst._wx_overclock_state then
        inst._wx_overclock_state = true
        if inst.components.talker ~= nil and GLOBAL.L.SPEECH.OVERCLOCK_ON ~= nil then
            inst.components.talker:Say(GLOBAL.L.SPEECH.OVERCLOCK_ON)
        end
    elseif not is_overclock and inst._wx_overclock_state then
        inst._wx_overclock_state = false
        if inst.components.talker ~= nil and GLOBAL.L.SPEECH.OVERCLOCK_OFF ~= nil then
            inst.components.talker:Say(GLOBAL.L.SPEECH.OVERCLOCK_OFF)
        end
    end
end

local function UpdateDamage(inst)
    local combat = inst.components ~= nil and inst.components.combat or nil
    local temp = inst.components ~= nil and inst.components.temperature or nil
    local modifiers = combat ~= nil and combat.externaldamagemultipliers or nil
    if modifiers == nil or temp == nil then
        return
    end

    local heatmods = GetHeatModules(inst)
    local multiplier = 1
    if heatmods > 0 and HasHeatSkill(inst) and temp.current >= DAMAGE_TEMP then
        multiplier = heatmods >= 2 and 1.50 or 1.25
    end

    if multiplier > 1 then
        modifiers:SetModifier(inst, multiplier, DAMAGE_MODIFIER_KEY)
    else
        modifiers:RemoveModifier(inst, DAMAGE_MODIFIER_KEY)
    end
end

local function UpdateOverheat(inst)
    local temp = inst.components ~= nil and inst.components.temperature or nil
    if temp == nil then
        return
    end

    if not inst._wx_overheat_rate_saved then
        inst._wx_overheat_rate_saved = true
        inst._wx_original_overheat_hurt_rate = temp.overheathurtrate
    end

    local heatmods = GetHeatModules(inst)
    -- Original behavior changes the overheat rate with active, charged modules.
    if heatmods > 0 then
        local rate = heatmods >= 2
            and TUNING.WILSON_HEALTH / 60
            or TUNING.WILSON_HEALTH / 120

        if temp.overheathurtrate ~= rate then
            temp:SetOverheatHurtRate(rate)
        end
        inst._wx_overheat_rate_modified = true
    elseif inst._wx_overheat_rate_modified then
        temp:SetOverheatHurtRate(inst._wx_original_overheat_hurt_rate)
        inst._wx_overheat_rate_modified = nil
    end
end

local function AddAttackHeat(inst)
    local temp = inst.components ~= nil and inst.components.temperature or nil
    local heatmods = GetHeatModules(inst)
    if temp == nil or heatmods <= 0 then
        return
    end

    inst._wx_last_attack_time = GLOBAL.GetTime()
    local gain = HEAT_PER_MODULE * heatmods
    inst._wx_module_heat = gain

    if temp.current + gain >= HEAT_TARGET then
        temp:SetTemperature(HEAT_TARGET)
    else
        temp:DoDelta(gain)
    end
end

local function StartHeatController(inst)
    if inst._wx_heat_task ~= nil then
        return
    end

    inst._wx_heat_task = inst:DoPeriodicTask(HEAT_CONTROLLER_INTERVAL, function()
        local temp = inst.components ~= nil and inst.components.temperature or nil
        if temp == nil then
            return
        end

        local heatmods = GetHeatModules(inst)
        if heatmods <= 0 or not HasHeatSkill(inst) then
            inst._wx_module_heat = 0
            inst._wx_last_temp = temp.current
            inst._wx_heat_rising = false
            UpdateDamage(inst)
            UpdateHeatSpeech(inst)
            return
        end

        inst._wx_last_temp = inst._wx_last_temp or temp.current
        inst._wx_module_heat = inst._wx_module_heat or 0

        if temp.current > inst._wx_last_temp then
            inst._wx_heat_rising = true
        elseif temp.current < inst._wx_last_temp then
            inst._wx_heat_rising = false
        end
        inst._wx_last_temp = temp.current

        local last_attack = inst._wx_last_attack_time or 0
        local time_since = GLOBAL.GetTime() - last_attack

        if time_since <= HEAT_HOLD_TIME then
            if temp.current > HEAT_TARGET then
                temp:SetTemperature(HEAT_TARGET)
            end
        elseif inst._wx_module_heat > 0 and not inst._wx_heat_rising then
            -- The amount cooled per tick is scaled by the task interval.
            -- The task stays alive at 0 so a later attack can heat WX-78 again.
            local decay = math.min(
                COOLING_PER_SECOND * HEAT_CONTROLLER_INTERVAL,
                inst._wx_module_heat,
                math.max(0, temp.current)
            )

            if decay > 0 then
                temp:SetTemperature(math.max(0, temp.current - decay))
                inst._wx_module_heat = math.max(0, inst._wx_module_heat - decay)
            end
        end

        UpdateDamage(inst)
        UpdateHeatSpeech(inst)
    end)
end

local function OnAttack(inst)
    if HasHeatSkill(inst) and GetHeatModules(inst) > 0 then
        AddAttackHeat(inst)
    end
end

local function Hook(inst)
    if inst._wx_heat_hooked then
        return
    end
    inst._wx_heat_hooked = true

    inst:ListenForEvent("onattackother", function()
        OnAttack(inst)
    end)

    StartHeatController(inst)
    inst:DoPeriodicTask(0.5, function()
        UpdateDamage(inst)
        UpdateOverheat(inst)
        UpdateHeatSpeech(inst)
    end)
end

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function()
        Hook(inst)
    end)
end)

AddComponentPostInit("inventoryitemtemperature", function(self)
    local old_UpdateTemperature = self.UpdateTemperature
    if old_UpdateTemperature == nil then
        return
    end

    function self:UpdateTemperature(dt)
        local item = self.inst
        local owner = item.components ~= nil and item.components.inventoryitem ~= nil
            and item.components.inventoryitem.owner or nil

        if owner ~= nil and owner.components ~= nil
            and owner.components.inventory ~= nil
            and item.components.fumaroletool ~= nil
            and owner.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS) == item
            and owner.prefab == "wx78" then

            local heatmods = GetHeatModules(owner)
            if heatmods > 0 then
                local heat_rate = 0.25 * heatmods
                self:SetTemperature(math.min(
                    self.temperature + heat_rate * (dt or 0),
                    self.maxtemp or TUNING.MAX_ENTITY_TEMP
                ))
                return true
            end
        end

        return old_UpdateTemperature(self, dt)
    end
end)
