-------------------------------------------------------
-- SHARED WX-78 HELPERS
-------------------------------------------------------

local function GetModuleOwner(inst)
    if inst == nil or inst.components == nil then
        return nil
    end

    return inst.components.upgrademoduleowner
end

-------------------------------------------------------
-- MODULE CHECKS
-------------------------------------------------------
function GetActiveModuleCount(inst, module_name)
    local owner = GetModuleOwner(inst)
    if owner == nil or owner.GetAllModules == nil then
        return 0
    end

    local prefab_name = "wx78module_" .. module_name
    local count = 0

    for _, module in ipairs(owner:GetAllModules() or {}) do
        local upgrade = module ~= nil
            and module.components ~= nil
            and module.components.upgrademodule
            or nil

        if module ~= nil and module.prefab == prefab_name
            and upgrade ~= nil and upgrade.activated then
            count = count + 1
        end
    end

    return count
end

function HasActiveModule(inst, module_name)
    return GetActiveModuleCount(inst, module_name) > 0
end

-------------------------------------------------------
-- SKILL CHECK
-------------------------------------------------------
function HasSkill(inst, skill_name)
    local skilltree = inst ~= nil and inst.components ~= nil
        and inst.components.skilltreeupdater or nil

    return skilltree ~= nil
        and skilltree.IsActivated ~= nil
        and skilltree:IsActivated(skill_name)
        or false
end

-------------------------------------------------------
-- CHARGE CHECK
-------------------------------------------------------
function HasCharge(inst)
    local owner = GetModuleOwner(inst)
    if owner == nil or owner.GetChargeLevel == nil then
        return false
    end

    return (owner:GetChargeLevel() or 0) > 0
end
