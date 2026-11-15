
AddPrefabPostInit("wx78_drone_scout", function (inst)
    inst:DoTaskInTime(0, function ()
        if not inst.components or not inst.components.mapdeliverable then
            return
        end

        local comp = inst.components.mapdeliverable
        local oldfn = comp.onstopdeliveryfn

        comp:SetOnStopDeliveryFn(function (drone)
            -- ejecutar lógica original primero
            if oldfn then
                oldfn(drone)
            end

            -- evitar falsos triggers (inicio/cancel/reassign)
            if not comp._wx78_delivery_active then
                return
            end

            comp._wx78_delivery_active = false

            local owner = drone._wx78_owner

            if owner and owner:IsValid() and owner.components and owner.components.talker then
                owner.components.talker:Say("ROTO-MAPPER: AREA REACHED.")
            end
        end)
    end)
end)
