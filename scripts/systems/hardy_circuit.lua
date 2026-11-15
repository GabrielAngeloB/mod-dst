local GLOBAL = GLOBAL

------------------------------------------------------------
-- ARMOR DURABILITY RETENTION
------------------------------------------------------------
AddComponentPostInit("armor", function(self)
    local old_TakeDamage = self.TakeDamage
    if old_TakeDamage == nil then
        return
    end

    function self:TakeDamage(damage_amount, ...)
        if type(damage_amount) == "number" and damage_amount > 0 then
            local item = self.inst
            local owner = item.components ~= nil and item.components.inventoryitem ~= nil
                and item.components.inventoryitem.owner or nil

            if owner ~= nil and owner.prefab == "wx78"
                and HasSkill(owner, "wx78_circuitry_alphabuffs_1") then
                local small_modules = GetActiveModuleCount(owner, "maxhealth")
                local big_modules = GetActiveModuleCount(owner, "maxhealth2")

                local reduction = 0
                if small_modules >= 1 then
                    reduction = reduction + 0.05
                end
                if small_modules >= 2 then
                    reduction = reduction + 0.025
                end
                if big_modules >= 1 then
                    reduction = reduction + 0.20
                end
                if big_modules >= 2 then
                    reduction = reduction + 0.10
                end

                if reduction > 0 then
                    damage_amount = damage_amount * math.max(0, 1 - reduction)
                end
            end
        end

        return old_TakeDamage(self, damage_amount, ...)
    end
end)
