local GLOBAL = GLOBAL
local STRINGS = GLOBAL.STRINGS
local L = GLOBAL.L

local scrapbookdata = require("screens/redux/scrapbookdata")

local function SetRecipeDependencies(prefab, dependencies)
    local entry = scrapbookdata ~= nil and scrapbookdata[prefab] or nil
    if entry ~= nil then
        entry.deps = dependencies
    end
end

if GetModConfigData("recipes") ~= false then
    SetRecipeDependencies("wx78module_chess", { "trinket_6", "scandata" })
    SetRecipeDependencies("wx78module_nightvision", { "mole", "wormlight", "scandata" })
    SetRecipeDependencies("wx78module_light", { "fireflies", "scandata" })
    SetRecipeDependencies("wx78module_light2", { "lightbulb", "scandata", "wx78module_light" })
    SetRecipeDependencies("wx78module_stacksize", { "wagpunk_bits", "transistor", "scandata" })
    SetRecipeDependencies("wx78module_shielding", { "scandata", "armorsnurtleshell" })
end

local function GetScrapbookInfo(key)
    local specialinfo = L ~= nil and L.SCRAPBOOK ~= nil and L.SCRAPBOOK.SPECIALINFO or nil
    return specialinfo ~= nil and specialinfo[key] or nil
end

local function SetScrapbookInfo(key)
    local destination = STRINGS ~= nil and STRINGS.SCRAPBOOK ~= nil
        and STRINGS.SCRAPBOOK.SPECIALINFO or nil
    local value = GetScrapbookInfo(key)

    if destination ~= nil and value ~= nil then
        destination[key] = value
    end
end

local function SetSkillTreeString(key)
    local source = L ~= nil and L.SKILLTREE ~= nil and L.SKILLTREE.WX78 or nil
    local destination = STRINGS ~= nil and STRINGS.SKILLTREE ~= nil
        and STRINGS.SKILLTREE.WX78 or nil

    if source ~= nil and destination ~= nil and source[key] ~= nil then
        destination[key] = source[key]
    end
end

if GetModConfigData("quickplugging") ~= false then
    SetSkillTreeString("WX78_BETTER_UNPLUG_TITLE")
    SetSkillTreeString("WX78_BETTER_UNPLUG_DESC")
end

if GetModConfigData("thermal") ~= false then
    SetScrapbookInfo("WX78MODULE_HEAT")
end

if GetModConfigData("nightvision") ~= false then
    SetScrapbookInfo("WX78MODULE_NIGHTVISION")
end

if GetModConfigData("refrigerant") ~= false then
    SetScrapbookInfo("WX78MODULE_COLD")
end

if GetModConfigData("illumination") ~= false then
    SetScrapbookInfo("WX78MODULE_LIGHT")
    SetScrapbookInfo("WX78MODULE_LIGHT2")
end

if GetModConfigData("chorusbox") ~= false then
    SetScrapbookInfo("WX78MODULE_MUSIC")
end

if GetModConfigData("processing") ~= false then
    SetScrapbookInfo("WX78MODULE_BEE")
    SetScrapbookInfo("WX78MODULE_MAXSANITY1")
    SetScrapbookInfo("WX78MODULE_MAXSANITY")
end

if GetModConfigData("hardy") ~= false then
    SetScrapbookInfo("WX78MODULE_MAXHEALTH2")
    SetScrapbookInfo("WX78MODULE_MAXHEALTH")
end

if GetModConfigData("rangebooster") ~= false then
    SetScrapbookInfo("WX78MODULE_RADAR")
end

if GetModConfigData("spatializer") ~= false then
    SetScrapbookInfo("WX78MODULE_STACKSIZE")
    SetSkillTreeString("WX78_GAMMA_CIRCUIT_BUFFS_2_TITLE")
    SetSkillTreeString("WX78_GAMMA_CIRCUIT_BUFFS_2_DESC")
end

if GetModConfigData("screech") ~= false then
    SetScrapbookInfo("WX78MODULE_SCREECH")
end

if GetModConfigData("redigestion") ~= false then
    SetScrapbookInfo("WX78MODULE_DIGESTION")
end

if GetModConfigData("blocking") ~= false then
    SetScrapbookInfo("WX78MODULE_SHIELDING")
end

if GetModConfigData("scans") ~= false then
    SetScrapbookInfo("WX78MODULE_SPIN")
    SetScrapbookInfo("WX78MODULE_MAXHUNGER1")
end
