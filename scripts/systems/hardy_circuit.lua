local GLOBAL = GLOBAL

------------------------------------------------------------
-- MECÂNICA: RETENÇÃO DE DURABILIDADE DE ARMADURA
------------------------------------------------------------
AddComponentPostInit("armor", function(self)
    -- Salvamos a função original que causa dano à armadura
    local old_TakeDamage = self.TakeDamage

    if old_TakeDamage then
        function self:TakeDamage(damage_amount, ...)
            if damage_amount and damage_amount > 0 then
                -- Descobre quem está vestindo a armadura (capacete ou peitoral)
                local owner = self.inst.components.inventoryitem ~= nil
                    and self.inst.components.inventoryitem.owner
                    or nil

                -- Verifica se é o WX-78
                if owner ~= nil and owner.prefab == "wx78" then

                    -- Checa se ele tem a skill "Alpha Circuits Tinkering I" ativada
                    if owner.components.skilltreeupdater ~= nil
                        and owner.components.skilltreeupdater:IsActivated("wx78_circuitry_alphabuffs_1") then

                        -- Puxa os circuitos instalados
                        local circuits = owner.components.upgrademoduleowner
                        if circuits ~= nil then
                            local small_modules = GetActiveModuleCount(owner, "maxhealth")
                            local big_modules = GetActiveModuleCount(owner, "maxhealth2")

                            -- Calcula a redução de durabilidade
                            local reduction = 0

                            -- Circuitos pequenos (Max Health)
                            if small_modules >= 1 then
                                reduction = reduction + 0.05 -- 5%
                            end
                            if small_modules >= 2 then
                                reduction = reduction + 0.025 -- +2,5% = 7,5%
                            end

                            -- Circuitos grandes (Max Health II)
                            if big_modules >= 1 then
                                reduction = reduction + 0.20 -- 20%
                            end
                            if big_modules >= 2 then
                                reduction = reduction + 0.10 -- +10% = 30%
                            end

                            if reduction > 0 then
                                -- Garante que a redução nunca passe de 100%
                                local mult = math.max(0, 1 - reduction)

                                -- Reduz o dano que a armadura recebe
                                damage_amount = damage_amount * mult
                            end
                        end
                    end
                end
            end

            -- Chama a rotina original com o dano ajustado
            return old_TakeDamage(self, damage_amount, ...)
        end
    end
end)