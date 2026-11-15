local GLOBAL = GLOBAL

-------------------------------------------------------
-- LOAD LOCALIZATION
-------------------------------------------------------
local lang = GetModConfigData("language") or "en"

local LANG_MAP = {
    en = "stringlocalization_en",
    es = "stringlocalization_es",
    pt_br = "stringlocalization_pt_br",
    zh_cn = "stringlocalization_ch",
}

GLOBAL.L = require(LANG_MAP[lang] or "stringlocalization_en")

modimport("scripts/systems/strings_override.lua")
modimport("scripts/systems/skilltree_override.lua")

-------------------------------------------------------
-- HELPERS
-------------------------------------------------------
local function IsEnabled(name)
    local val = GetModConfigData(name)
    return val ~= false
end

-------------------------------------------------------
-- LOAD SYSTEMS (CONFIG ENABLE/DISABLE)
-------------------------------------------------------

if IsEnabled("tumbleweed") then
    modimport("scripts/world/tumbleweed.lua")
end

if IsEnabled("recipes") then
    modimport("scripts/recipes/recipes.lua")
end

if IsEnabled("rotomapper") then
    modimport("scripts/drone/rotomapper.lua")
end

if IsEnabled("scans") then
    modimport("scripts/drone/scans.lua")
end

modimport("scripts/helpers.lua")

if IsEnabled("screech") then
    modimport("scripts/systems/screech_circuit.lua")
end

if IsEnabled("redigestion") then
    modimport("scripts/systems/redigestion_circuit.lua")
end

if IsEnabled("blocking") then
    modimport("scripts/systems/blocking_circuit.lua")
end

if IsEnabled("hardy") then
    modimport("scripts/systems/hardy_circuit.lua")
end

if IsEnabled("processing") then
    modimport("scripts/systems/processing_circuit.lua")
end

if IsEnabled("beanbooster") then
    modimport("scripts/systems/beanbooster_circuit.lua")
end

if IsEnabled("chorusbox") then
    modimport("scripts/systems/chorusbox_circuit.lua")
end

if IsEnabled("nightvision") then
    modimport("scripts/systems/nightvision_circuit.lua")
end

if IsEnabled("rangebooster") then
    modimport("scripts/systems/rangebooster_circuit.lua")
end

if IsEnabled("thermal") then
    modimport("scripts/systems/thermal_circuit.lua")
end

if IsEnabled("refrigerant") then
    modimport("scripts/systems/refrigerant_circuit.lua")
end

if IsEnabled("spatializer") then
    modimport("scripts/systems/spatializer_circuit.lua")
end

if IsEnabled("illumination") then
    modimport("scripts/systems/ilumination_circuit.lua")
end

if IsEnabled("resonance") then
    modimport("scripts/systems/resonance_circuit.lua")
end

if IsEnabled("quickplugging") then
    modimport("scripts/components/wx_data_extractor.lua")
    modimport("scripts/systems/wx78_quickplugging.lua")
end


-- Fuel Oil is omitted from this package: its three referenced implementation files are absent.

-- GLOBAL.setfenv(1, env)

-- --------------------------------------------------------------------
-- -- GLOBAL IMPORTS 
-- --------------------------------------------------------------------
-- local GLOBAL = GLOBAL

-- local AddAction = GLOBAL.AddAction
-- local ACTIONS = GLOBAL.ACTIONS
-- local AddComponentAction = GLOBAL.AddComponentAction
-- local ActionHandler = GLOBAL.ActionHandler
-- local AddStategraphPostInit = GLOBAL.AddStategraphPostInit

-- --------------------------------------------------------------------
-- -- ACTION
-- --------------------------------------------------------------------
-- local WX78_CHESS_TOGGLE = AddAction("WX78_CHESS_TOGGLE", "Chess Toggle", function(act)
--     local inst = act.doer
--     if inst == nil then return false end

--     inst._chess_module_state = not inst._chess_module_state

--     if inst.components.talker then
--         inst.components.talker:Say(
--             inst._chess_module_state and "activated" or "deactivated"
--         )
--     end

--     print("[WX78 DEBUG] STATE:", inst._chess_module_state)
--     return true
-- end)

-- ACTIONS.WX78_CHESS_TOGGLE = WX78_CHESS_TOGGLE

-- --------------------------------------------------------------------
-- -- HACER QUE APAREZCA EN RIGHT CLICK 
-- --------------------------------------------------------------------
-- AddComponentAction("INVENTORY", "upgrademoduleowner", function(inst, doer, actions, right)
--     if not right then return end
--     if doer == nil then return end
--     if doer.prefab ~= "wx78" then return end
--     if doer.components == nil then return end

--     local comp = doer.components.upgrademoduleowner
--     if comp == nil then return end

--     if comp:GetModuleTypeCount("chess") > 0 and comp.charge_level > 0 then
--         table.insert(actions, ACTIONS.WX78_CHESS_TOGGLE)
--     end
-- end)

-- --------------------------------------------------------------------
-- -- STATEGRAPH SAFE HOOK
-- --------------------------------------------------------------------
-- AddStategraphPostInit("wilson", function(sg)
--     if sg.actionhandlers[ACTIONS.WX78_CHESS_TOGGLE] == nil then
--         sg.actionhandlers[ACTIONS.WX78_CHESS_TOGGLE] =
--             ActionHandler(ACTIONS.WX78_CHESS_TOGGLE, "doshortaction")
--     end
-- end)

-- AddStategraphPostInit("wilson_client", function(sg)
--     if sg.actionhandlers[ACTIONS.WX78_CHESS_TOGGLE] == nil then
--         sg.actionhandlers[ACTIONS.WX78_CHESS_TOGGLE] =
--             ActionHandler(ACTIONS.WX78_CHESS_TOGGLE, "doshortaction")
--     end
-- end)
-- 
-- 
