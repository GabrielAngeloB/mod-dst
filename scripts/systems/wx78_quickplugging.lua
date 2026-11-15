local GLOBAL = GLOBAL

local MATERIAL_SCANDATA = "scandata"

-------------------------------------------------------------------
-- SKILL CHECK
-------------------------------------------------------------------
local function HasSkill(inst, skill)
    return inst
        and inst.components
        and inst.components.skilltreeupdater
        and inst.components.skilltreeupdater:IsActivated(skill)
end

local function CANREPAIR(wx)
    if wx == nil or not wx:IsValid() then
        return false
    end

    return HasSkill(wx, "wx78_circuitry_betterunplug")
end

-------------------------------------------------------------------
-- VALOR DE REPARACIÓN
-------------------------------------------------------------------
local function GetRepairValue()
    return math.max((TUNING.WX78_MODULE_USES or 0) * 0.25, 0)
end

-------------------------------------------------------------------
-- SCANDATA: REPAIR ITEM (RIGHT CLICK FUNCTION)
-------------------------------------------------------------------
AddPrefabPostInit("scandata", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.repairer == nil then
        inst:AddComponent("repairer")
    end

    local repairer = inst.components.repairer

    repairer.repairmaterial = MATERIAL_SCANDATA
    repairer.repairaction = ACTIONS.REPAIR
    repairer.finiteusesrepairvalue = GetRepairValue()

    -- Hace que el sistema lo reconozca correctamente como material válido
    repairer.strong = true
end)

-------------------------------------------------------------------
-- HABILITAR ACCIÓN REPAIR SOLO SI TIENE LA SKILL
-------------------------------------------------------------------
AddComponentAction("USEITEM", "repairer", function(inst, doer, target, actions)
    if inst ~= nil
        and inst.prefab == "scandata"
        and doer ~= nil
        and doer.prefab == "wx78"
        and CANREPAIR(doer)
    then
        table.insert(actions, ACTIONS.REPAIR)
    end
end)

-------------------------------------------------------------------
-- MÓDULOS WX-78: REPAIR
-------------------------------------------------------------------
local function PatchModule(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.repairable == nil then
        inst:AddComponent("repairable")
    end

    local repairable = inst.components.repairable

    repairable.repairmaterial = MATERIAL_SCANDATA
    repairable.repairaction = ACTIONS.REPAIR

    repairable.onrepaired = function(inst)
        local owner = inst.components.upgrademodule
            and inst.components.upgrademodule.target

        if owner
            and owner.components
            and owner.components.upgrademoduleowner
        then
            owner.components.upgrademoduleowner:UpdateActivatedModules()
        end
    end

    if inst.components.finiteuses ~= nil then
        repairable:SetFiniteUsesRepairable(true)
    end
end

-------------------------------------------------------------------
-- APLICAR A TODOS LOS MÓDULOS WX-78
-------------------------------------------------------------------
local moduledefs = require("wx78_moduledefs").module_definitions

for _, def in ipairs(moduledefs) do
    AddPrefabPostInit("wx78module_" .. def.name, PatchModule)
end
-------------------------------------------------------------------
-- Circuit Extractor Break down modules
-------------------------------------------------------------------

GLOBAL.setmetatable(env,{
    __index = function(t,k)
        return GLOBAL.rawget(GLOBAL,k)
    end
})

-------------------------------------------------------------------
-- SKILL CHECK
-------------------------------------------------------------------

local function CanDismantle(wx)
    if wx == nil or not wx:IsValid() then
        return false
    end

    return HasSkill(wx, "wx78_circuitry_betterunplug")
end

-------------------------------------------------------------------
-- PREFAB INIT
-------------------------------------------------------------------

AddPrefabPostInit("wx78_moduleremover", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if not inst.components.wx_data_extractor then
        inst:AddComponent("wx_data_extractor")
    end
end)

-------------------------------------------------------------------
-- ACTION
-------------------------------------------------------------------

local BREAK_DOWN_MODULE = Action({
    priority = 4,
    mount_valid = true,
})

BREAK_DOWN_MODULE.id = "BREAK_DOWN_MODULE"
BREAK_DOWN_MODULE.str = GLOBAL.L.ACTION.DISMANTLER

AddAction(BREAK_DOWN_MODULE)

BREAK_DOWN_MODULE.fn = function(act)

    local extractor = act.invobject
    local target = act.target
    local doer = act.doer

    -- Bloquea la acción si no tiene la skill
    if not CanDismantle(doer) then
        return false
    end

    if extractor
    and extractor.components.wx_data_extractor
    and target
    and target.components.upgrademodule then

        return extractor.components.wx_data_extractor:BreakDown(
            target,
            doer
        )
    end

    return false
end

-------------------------------------------------------------------
-- RIGHT CLICK PICKER
-------------------------------------------------------------------

AddComponentAction("USEITEM", "wx_data_extractor",
function(inst, doer, target, actions, right)

    if not right then
        return
    end

  
    if not CanDismantle(doer) then
        return
    end

    if doer
        and doer:HasTag("upgrademoduleowner")
        and target
        and target.prefab
        and target.prefab:find("wx78module_") then

        table.insert(actions, ACTIONS.BREAK_DOWN_MODULE)
    end
end)

-------------------------------------------------------------------
-- STATEGRAPH
-------------------------------------------------------------------

AddStategraphActionHandler(
    "wilson",
    ActionHandler(
        BREAK_DOWN_MODULE,
        "dolongaction"
    )
)

AddStategraphActionHandler(
    "wilson_client",
    ActionHandler(
        BREAK_DOWN_MODULE,
        "dolongaction"
    )
)
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

local function FasterunplugCircuit(wx)
    if wx == nil or not wx:IsValid() then
        return false
    end

    return HasSkill(wx, "wx78_circuitry_betterunplug")
end

-------------------------------------------------------
-- STATEGRAPH PATCH
-------------------------------------------------------
AddStategraphPostInit("wilson", function(sg)

    -------------------------------------------------------
    -- CONFIG
    -------------------------------------------------------
    local REMOVE_SPEED = 1.5
    local INSERT_SPEED = 1.5

    -------------------------------------------------------
    -- SAFE ANIMATION SPEED
    -------------------------------------------------------
    local function SetSpeed(inst, speed)
        if inst ~= nil and inst.AnimState ~= nil then
            inst.AnimState:SetDeltaTimeMultiplier(speed)
        end
    end

    local function ResetSpeed(inst)
        if inst ~= nil and inst.AnimState ~= nil then
            inst.AnimState:SetDeltaTimeMultiplier(1)
        end
    end

    -------------------------------------------------------
    -- WRAPPER SAFE
    -------------------------------------------------------
    local function wrap(state, speed)
        if sg.states[state] == nil then
            return
        end

        local old_onenter = sg.states[state].onenter
        sg.states[state].onenter = function(inst, ...)

            -- with skill
            if FasterunplugCircuit(inst) then
                SetSpeed(inst, speed)
            end

            if old_onenter then
                return old_onenter(inst, ...)
            end
        end

        local old_onexit = sg.states[state].onexit
        sg.states[state].onexit = function(inst, ...)

            --reset without skill
            if FasterunplugCircuit(inst) then
                ResetSpeed(inst)
            end

            if old_onexit then
                return old_onexit(inst, ...)
            end
        end
    end

    -------------------------------------------------------
    -- REMOVE (más rápido)
    -------------------------------------------------------
    wrap("start_removing_module", REMOVE_SPEED)
    wrap("removing_module", REMOVE_SPEED)
    wrap("unplug_module", REMOVE_SPEED)

    -------------------------------------------------------
    -- INSERT
    -------------------------------------------------------
    wrap("start_plugging_module", INSERT_SPEED)
    wrap("plugging_module", INSERT_SPEED)
    wrap("plug_module", INSERT_SPEED)

end)