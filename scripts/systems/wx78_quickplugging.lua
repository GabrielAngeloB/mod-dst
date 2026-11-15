local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING
local MATERIAL_SCANDATA = "scandata"
local ACTIONS = GLOBAL.ACTIONS

local function HasSkill(inst, skill)
    local skilltree = inst ~= nil and inst.components ~= nil
        and inst.components.skilltreeupdater or nil

    return skilltree ~= nil
        and skilltree:IsActivated(skill)
        or false
end

local function CanRepair(wx)
    return wx ~= nil and wx:IsValid()
        and HasSkill(wx, "wx78_circuitry_betterunplug")
end

local function GetRepairValue()
    return math.max((TUNING.WX78_MODULE_USES or 0) * 0.25, 0)
end

AddPrefabPostInit("scandata", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    if inst.components.repairer == nil then
        inst:AddComponent("repairer")
    end

    local repairer = inst.components.repairer
    repairer.repairmaterial = MATERIAL_SCANDATA
    repairer.repairaction = ACTIONS.REPAIR
    repairer.finiteusesrepairvalue = GetRepairValue()
    repairer.strong = true
end)

AddComponentAction("USEITEM", "repairer", function(inst, doer, target, actions)
    if inst ~= nil and inst.prefab == "scandata"
        and doer ~= nil and doer.prefab == "wx78"
        and CanRepair(doer) then
        table.insert(actions, ACTIONS.REPAIR)
    end
end)

local function PatchModule(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    if inst.components.repairable == nil then
        inst:AddComponent("repairable")
    end

    local repairable = inst.components.repairable
    repairable.repairmaterial = MATERIAL_SCANDATA
    repairable.repairaction = ACTIONS.REPAIR

    local old_onrepaired = repairable.onrepaired
    repairable.onrepaired = function(module, ...)
        if old_onrepaired ~= nil then
            old_onrepaired(module, ...)
        end

        local upgrade = module.components ~= nil
            and module.components.upgrademodule or nil
        local owner = upgrade ~= nil and upgrade.target or nil

        if owner ~= nil and owner:IsValid()
            and owner.components ~= nil
            and owner.components.upgrademoduleowner ~= nil then
            owner.components.upgrademoduleowner:UpdateActivatedModules()
        end
    end

    if inst.components.finiteuses ~= nil then
        repairable:SetFiniteUsesRepairable(true)
    end
end

local moduledefs = require("wx78_moduledefs").module_definitions
for _, def in ipairs(moduledefs) do
    AddPrefabPostInit("wx78module_" .. def.name, PatchModule)
end

local function CanDismantle(wx)
    return CanRepair(wx)
end

AddPrefabPostInit("wx78_moduleremover", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    if inst.components.wx_data_extractor == nil then
        inst:AddComponent("wx_data_extractor")
    end
end)

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

    if not CanDismantle(doer) then
        return false
    end

    local component = extractor ~= nil and extractor.components ~= nil
        and extractor.components.wx_data_extractor or nil
    local upgrade = target ~= nil and target.components ~= nil
        and target.components.upgrademodule or nil

    if component == nil or upgrade == nil then
        return false
    end

    return component:BreakDown(target, doer)
end

AddComponentAction("USEITEM", "wx_data_extractor", function(inst, doer, target, actions, right)
    if not right or not CanDismantle(doer) or doer == nil
        or not doer:HasTag("upgrademoduleowner")
        or target == nil or target.prefab == nil then
        return
    end

    if string.find(target.prefab, "wx78module_", 1, true) == 1 then
        table.insert(actions, ACTIONS.BREAK_DOWN_MODULE)
    end
end)

AddStategraphActionHandler(
    "wilson",
    ActionHandler(BREAK_DOWN_MODULE, "dolongaction")
)
AddStategraphActionHandler(
    "wilson_client",
    ActionHandler(BREAK_DOWN_MODULE, "dolongaction")
)

local function FasterUnplugCircuit(wx)
    return CanRepair(wx)
end

local function PatchQuickPlugStategraph(sg)
    local REMOVE_SPEED = 1.5
    local INSERT_SPEED = 1.5

    local function SetSpeed(inst, speed)
        if inst ~= nil and inst.AnimState ~= nil then
            local state = inst.sg ~= nil and inst.sg.statemem or nil
            if state ~= nil and state.dwx78_quickplug_original_speed == nil then
                local getter = inst.AnimState.GetDeltaTimeMultiplier
                state.dwx78_quickplug_original_speed =
                    type(getter) == "function" and getter(inst.AnimState) or 1
            end
            inst.AnimState:SetDeltaTimeMultiplier(speed)
        end
    end

    local function ResetSpeed(inst)
        if inst == nil or inst.AnimState == nil then
            return
        end

        local state = inst.sg ~= nil and inst.sg.statemem or nil
        local original = state ~= nil and state.dwx78_quickplug_original_speed or nil
        inst.AnimState:SetDeltaTimeMultiplier(original or 1)

        if state ~= nil then
            state.dwx78_quickplug_original_speed = nil
        end
    end

    local function Wrap(state_name, speed)
        local state = sg.states[state_name]
        if state == nil then
            return
        end

        local old_onenter = state.onenter
        state.onenter = function(inst, ...)
            if FasterUnplugCircuit(inst) then
                SetSpeed(inst, speed)
            end

            if old_onenter ~= nil then
                return old_onenter(inst, ...)
            end
        end

        local old_onexit = state.onexit
        state.onexit = function(inst, ...)
            -- Always restore if this wrapper changed the animation speed.
            local state_mem = inst.sg ~= nil and inst.sg.statemem or nil
            if state_mem ~= nil and state_mem.dwx78_quickplug_original_speed ~= nil then
                ResetSpeed(inst)
            end

            if old_onexit ~= nil then
                return old_onexit(inst, ...)
            end
        end
    end

    Wrap("start_removing_module", REMOVE_SPEED)
    Wrap("removing_module", REMOVE_SPEED)
    Wrap("unplug_module", REMOVE_SPEED)
    Wrap("start_plugging_module", INSERT_SPEED)
    Wrap("plugging_module", INSERT_SPEED)
    Wrap("plug_module", INSERT_SPEED)
end

AddStategraphPostInit("wilson", PatchQuickPlugStategraph)
AddStategraphPostInit("wilson_client", PatchQuickPlugStategraph)
