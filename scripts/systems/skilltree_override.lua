local GLOBAL = GLOBAL
local SKILLTREE_DEFS = require("prefabs/skilltree_defs").SKILLTREE_DEFS
local L = GLOBAL.L

local wx = SKILLTREE_DEFS ~= nil and SKILLTREE_DEFS.wx78 or nil
local skill_strings = L ~= nil and L.SKILLTREE ~= nil and L.SKILLTREE.WX78 or nil

if wx ~= nil and skill_strings ~= nil then
    if GetModConfigData("quickplugging") ~= false then
        local skill = wx.wx78_circuitry_betterunplug
        if skill ~= nil then
            skill.title = skill_strings.WX78_BETTER_UNPLUG_TITLE or skill.title
            skill.desc = skill_strings.WX78_BETTER_UNPLUG_DESC or skill.desc
        end
    end

    if GetModConfigData("spatializer") ~= false then
        local skill = wx.wx78_circuitry_gammabuffs_2
        if skill ~= nil then
            skill.title = skill_strings.WX78_GAMMA_CIRCUIT_BUFFS_2_TITLE or skill.title
            skill.desc = skill_strings.WX78_GAMMA_CIRCUIT_BUFFS_2_DESC or skill.desc
        end
    end
end
