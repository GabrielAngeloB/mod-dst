
-------------------------------------------------------
-- MODULE CHECK
-------------------------------------------------------
function HasActiveModule(inst, module_name)
    local owner = inst.components.upgrademoduleowner
    if owner == nil then
        return false
    end

    local target = "wx78module_" .. module_name

    for _, mod in ipairs(owner:GetAllModules()) do
        if mod.prefab == target then
            local comp = mod.components and mod.components.upgrademodule
            if comp ~= nil and comp.activated then
                return true
            end
        end
    end

    return false
end

-------------------------------------------------------
-- SKILL CHECK
-------------------------------------------------------
function HasSkill(inst, skill_name)
    local skilltree = inst.components.skilltreeupdater
    return skilltree ~= nil and skilltree:IsActivated(skill_name)
end

-------------------------------------------------------
-- CHARGE CHECK
-------------------------------------------------------
function HasCharge(inst)
    local owner = inst.components.upgrademoduleowner
    if owner == nil then
        return false
    end

    return owner:GetChargeLevel() > 0
end