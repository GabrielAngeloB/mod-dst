-------------------------------------------------------
-- MODULE HELPERS
-------------------------------------------------------
function GetActiveModuleCount(inst, module_name)
    if inst == nil or inst.components == nil then
        return 0
    end

    local owner = inst.components.upgrademoduleowner
    if owner == nil or owner.GetAllModules == nil then
        return 0
    end

    local target = "wx78module_" .. module_name
    local count = 0

    for _, module in ipairs(owner:GetAllModules()) do
        local upgrade = module ~= nil and module.components ~= nil
            and module.components.upgrademodule or nil

        if module ~= nil and module.prefab == target
            and upgrade ~= nil and upgrade.activated == true then
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

    return skilltree ~= nil and skilltree:IsActivated(skill_name)
end

-------------------------------------------------------
-- CHARGE CHECK
-------------------------------------------------------
function HasCharge(inst)
    local owner = inst ~= nil and inst.components ~= nil
        and inst.components.upgrademoduleowner or nil

    return owner ~= nil and owner.GetChargeLevel ~= nil
        and owner:GetChargeLevel() > 0
end
