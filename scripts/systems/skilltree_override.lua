local skilltree_defs = require("prefabs/skilltree_defs")
local wx = skilltree_defs ~= nil and skilltree_defs.SKILLTREE_DEFS ~= nil
    and skilltree_defs.SKILLTREE_DEFS.wx78 or nil
local L = GLOBAL.L
local wx_strings = L ~= nil and L.SKILLTREE ~= nil and L.SKILLTREE.WX78 or nil

local function OverrideSkill(name, title_key, desc_key)
    local skill = wx ~= nil and wx[name] or nil
    if skill == nil or wx_strings == nil then
        return
    end

    if wx_strings[title_key] ~= nil then
        skill.title = wx_strings[title_key]
    end
    if wx_strings[desc_key] ~= nil then
        skill.desc = wx_strings[desc_key]
    end
end

OverrideSkill(
    "wx78_circuitry_betterunplug",
    "WX78_BETTER_UNPLUG_TITLE",
    "WX78_BETTER_UNPLUG_DESC"
)

OverrideSkill(
    "wx78_circuitry_gammabuffs_2",
    "WX78_GAMMA_CIRCUIT_BUFFS_2_TITLE",
    "WX78_GAMMA_CIRCUIT_BUFFS_2_DESC"
)
