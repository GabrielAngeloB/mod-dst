

local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING
----------------THERMAL CIRCUIT CHANGES: START------------
-------------------------------------------------------------------
--                              CONFIG
-------------------------------------------------------------------
local HEAT_TARGET = 71
local DAMAGE_TEMP = 65
local HEAT_HOLD_TIME = 1.5

local HEAT_PER_MODULE = 7
local COOLING_PER_SECOND = 0.35

-------------------------------------------------------------------
--                            MODULES / SKILL 
-------------------------------------------------------------------
local function GetHeatModules(inst)
    local owner = inst.components.upgrademoduleowner
    if owner == nil then
        return 0
    end

    local count = GetActiveModuleCount(inst, "heat")

    if count <= 0
        or not HasActiveModule(inst, "heat")
        or not HasCharge(inst) then
        return 0
    end

    return count
end

local function HasHeatSkill(inst)
    return HasSkill(inst, "wx78_circuitry_betabuffs_1")
end

-------------------------------------------------------------------
--                              SPEECH
-------------------------------------------------------------------
local function UpdateHeatSpeech(inst)
    local temp = inst.components.temperature
    if temp == nil then return end

    local heatmods = GetHeatModules(inst)

    if heatmods <= 0 or not HasHeatSkill(inst) then
        inst._wx_overclock_state = false
        return
    end

    local is_overclock = temp.current >= DAMAGE_TEMP

    if is_overclock and not inst._wx_overclock_state then
        inst._wx_overclock_state = true
        if inst.components.talker then
            inst.components.talker:Say(GLOBAL.L.SPEECH.OVERCLOCK_ON)
        end
    end

    if not is_overclock and inst._wx_overclock_state then
        inst._wx_overclock_state = false
        if inst.components.talker then
            inst.components.talker:Say(GLOBAL.L.SPEECH.OVERCLOCK_OFF)
        end
    end
end

-------------------------------------------------------------------
--                      DAMAGE
-------------------------------------------------------------------
local DAMAGE_MODIFIER_KEY = "dwx78_thermal_overheat"

local function UpdateDamage(inst)
    local combat = inst.components.combat
    local temp = inst.components.temperature
    if combat == nil or temp == nil or combat.externaldamagemultipliers == nil then
        return
    end

    local heatmods = GetHeatModules(inst)
    local multiplier = 1

    if heatmods > 0 and HasHeatSkill(inst) and temp.current >= DAMAGE_TEMP then
        multiplier = heatmods >= 2 and 1.50 or 1.25
    end

    -- Use a keyed SourceModifierList entry instead of overwriting the shared
    -- combat.damagemultiplier field, so other mods' damage bonuses survive.
    if multiplier > 1 then
        combat.externaldamagemultipliers:SetModifier(inst, multiplier, DAMAGE_MODIFIER_KEY)
    else
        combat.externaldamagemultipliers:RemoveModifier(inst, DAMAGE_MODIFIER_KEY)
    end
end

-------------------------------------------------------------------
--                  OVERHEAT DAMAGE
-------------------------------------------------------------------
local function UpdateOverheat(inst)
    local temp = inst.components.temperature
    if temp == nil then return end

    local heatmods = GetHeatModules(inst)

    if heatmods >= 2 and HasHeatSkill(inst) then
        temp:SetOverheatHurtRate(TUNING.WILSON_HEALTH / 60)
    else
        -- Keep the default single-module/no-module rate when the skill or
        -- circuit requirements are not active.
        temp:SetOverheatHurtRate(TUNING.WILSON_HEALTH / 120)
    end
end

-------------------------------------------------------------------
--                      ATTACK HEAT
-------------------------------------------------------------------
local function AddAttackHeat(inst)
    local temp = inst.components.temperature
    if temp == nil then return end

    local heatmods = GetHeatModules(inst)
    if heatmods <= 0 then return end

    inst._wx_last_attack_time = GLOBAL.GetTime()

    local gain = HEAT_PER_MODULE * heatmods

    -- Use the temperature component API and track the heat actually applied.
    local before = temp.current
    temp:DoDelta(gain)

    if temp.current > HEAT_TARGET then
        temp:SetTemperature(HEAT_TARGET)
    end

    local applied_heat = math.max(0, temp.current - before)
    inst._wx_module_heat = (inst._wx_module_heat or 0) + applied_heat
end

-------------------------------------------------------------------
--                  HEAT CONTROLLER
-------------------------------------------------------------------
local function StartHeatController(inst)
    if inst._wx_heat_task ~= nil then return end

    inst._wx_heat_task = inst:DoPeriodicTask(0.1, function ()
        local temp = inst.components.temperature
        if temp == nil then return end

        local heatmods = GetHeatModules(inst)

        if not HasHeatSkill(inst) or heatmods <= 0 then
            UpdateDamage(inst)
            UpdateHeatSpeech(inst)
            return
        end

        -- init tracking
        inst._wx_last_temp = inst._wx_last_temp or temp.current
        inst._wx_heat_rising = inst._wx_heat_rising or false
        inst._wx_module_heat = inst._wx_module_heat or 0

        -- detect temperature trend
        if temp.current > inst._wx_last_temp then
            inst._wx_heat_rising = true
        elseif temp.current < inst._wx_last_temp then
            inst._wx_heat_rising = false
        end

        inst._wx_last_temp = temp.current

        local last = inst._wx_last_attack_time or 0
        local time_since = GLOBAL.GetTime() - last

        if time_since <= HEAT_HOLD_TIME then
            if temp.current > HEAT_TARGET then
                temp:SetTemperature(HEAT_TARGET)
            end
        else
            -- SOLO enfriar si el calor viene del sistema de módulos
            if inst._wx_module_heat and inst._wx_module_heat > 0 then
                if not inst._wx_heat_rising then
                    local decay = COOLING_PER_SECOND

                    local actual_decay = math.min(decay, math.max(0, temp.current))
                    temp:DoDelta(-actual_decay, true)

                    -- Reduce only the heat contributed by this circuit.
                    inst._wx_module_heat = math.max(0, inst._wx_module_heat - actual_decay)
                end
            end
        end

        -- Keep the controller alive at 0°C so later attacks can add heat
        -- without requiring a second initialization.
        if temp.current <= 0 then
            temp:SetTemperature(0)
            inst._wx_module_heat = 0
        end

        UpdateDamage(inst)
        UpdateHeatSpeech(inst)
    end)
end

-------------------------------------------------------------------
--                      ATTACK EVENT
-------------------------------------------------------------------
local function OnAttack(inst)
    if not HasHeatSkill(inst) then return end
    if GetHeatModules(inst) <= 0 then return end

    AddAttackHeat(inst)
end

-------------------------------------------------------------------
--                      HOOK
-------------------------------------------------------------------
local function Hook(inst)
    if inst._wx_heat_hooked then return end
    inst._wx_heat_hooked = true

    inst:ListenForEvent("onattackother", function ()
        OnAttack(inst)
    end)

    StartHeatController(inst)

    inst:DoPeriodicTask(0.5, function ()
        UpdateDamage(inst)
        UpdateOverheat(inst)
        UpdateHeatSpeech(inst)
    end)
end
----------------THERMAL CIRCUIT CHANGES: END------------
-------------------------------------------------------------------
--                      INIT
-------------------------------------------------------------------
AddPrefabPostInit("wx78", function(inst)
    if not GLOBAL.TheNet:GetIsServer() then return end

    inst:DoTaskInTime(0, function ()
        Hook(inst)
    end)
end)


AddComponentPostInit("inventoryitemtemperature", function(self)

    local old_UpdateTemperature = self.UpdateTemperature

    function self:UpdateTemperature(dt)

        local item = self.inst

        local owner = item.components.inventoryitem ~= nil
            and item.components.inventoryitem.owner
            or nil

        if owner ~= nil
            and owner.components.inventory ~= nil
            and item.components.fumaroletool ~= nil
            and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == item then

            local heatmods = 0

            if owner.prefab == "wx78" then
                heatmods = GetHeatModules(owner)
            end

            if heatmods > 0 then
                local heat_rate = 0.25 * heatmods
                -- 1 módulo = 0.3
                -- 2 módulos = 0.6

                self:SetTemperature(math.min(
                    self.temperature + heat_rate * dt,
                    self.maxtemp or TUNING.MAX_ENTITY_TEMP
                ))

                return true
            end
        end

        return old_UpdateTemperature(self, dt)
    end

end)