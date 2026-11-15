local GLOBAL = GLOBAL

--------------------------------------------------------------------------
-- WX-78 DRONE SCOUT QoL: ARRIVAL MESSAGE
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- 1. PATCH MAPDELIVERABLE TO DISTINGUISH ARRIVAL VS STOP/CANCEL
--------------------------------------------------------------------------

AddComponentPostInit("mapdeliverable", function(self)
    ----------------------------------------------------------------------
    -- A) Wrap OnUpdate:
    -- If delivery naturally finishes (t >= len), mark as real arrival
    ----------------------------------------------------------------------
    if not self._wx78_onupdate_patched then
        self._wx78_onupdate_patched = true

        local old_onupdate = self.OnUpdate
        self.OnUpdate = function(comp, dt)
            -- justo antes de que OnUpdate original resetee todo y llame onstopdeliveryfn,
            -- detectamos si esta actualización va a completar la entrega
            if comp.t and comp.len and (comp.t + dt) >= comp.len then
                comp._wx78_arrived = true
            else
                comp._wx78_arrived = false
            end

            return old_onupdate(comp, dt)
        end
    end

    ----------------------------------------------------------------------
    -- B) Wrap Stop:
    -- If delivery is manually stopped/cancelled/reassigned, NOT an arrival
    ----------------------------------------------------------------------
    if not self._wx78_stop_patched then
        self._wx78_stop_patched = true

        local old_stop = self.Stop
        self.Stop = function(comp, ...)
            comp._wx78_arrived = false
            return old_stop(comp, ...)
        end
    end

    ----------------------------------------------------------------------
    -- C) Wrap SendToPoint:
    -- Save owner and mark delivery as active
    ----------------------------------------------------------------------
    if not self._wx78_sendtopoint_patched then
        self._wx78_sendtopoint_patched = true

        local old_send = self.SendToPoint
        self.SendToPoint = function(comp, pt, doer)
            local drone = comp.inst

            -- nuevo envío = por defecto todavía NO ha llegado
            comp._wx78_arrived = false

            local success, reason = old_send(comp, pt, doer)

            -- solo marcar si el envío realmente arrancó
            if success then
                comp._wx78_delivery_active = true

                if doer then
                    drone._wx78_owner = doer
                end
            end

            return success, reason
        end
    end
end)

--------------------------------------------------------------------------
-- 2. SHOW MESSAGE ONLY ON REAL ARRIVAL
--------------------------------------------------------------------------

AddPrefabPostInit("wx78_drone_scout", function(inst)
    inst:DoTaskInTime(0, function()
        if not inst.components or not inst.components.mapdeliverable then
            return
        end

        local comp = inst.components.mapdeliverable
        local oldfn = comp.onstopdeliveryfn

        comp:SetOnStopDeliveryFn(function(drone)
            -- primero lógica original
            if oldfn then
                oldfn(drone)
            end

            -- si no había entrega activa, no hacer nada
            if not comp._wx78_delivery_active then
                return
            end

            -- solo mostrar si el stop fue por llegada real
            if not comp._wx78_arrived then
                comp._wx78_delivery_active = false
                return
            end

            comp._wx78_delivery_active = false
            comp._wx78_arrived = false

            local owner = drone._wx78_owner
            if owner and owner:IsValid() and owner.components and owner.components.talker then
                if owner.SoundEmitter then
                    owner.SoundEmitter:PlaySound("dontstarve/HUD/Together_HUD/learn_map")
                end
                owner.components.talker:Say(GLOBAL.L.SPEECH.DRONE_ARRIVED)
            end
        end)
    end)
end)

-- ---Messing around with the line of rotomapper
-- AddClassPostConstruct("screens/mapscreen", function(self)

--     local old_fn = self.ProcessLMBDecorations_MAPSCOUT_MAP
--     if old_fn == nil then
--         return
--     end

--     self.ProcessLMBDecorations_MAPSCOUT_MAP = function(self, lmb, fresh)

--         old_fn(self, lmb, fresh)

--         local data = self.decorationdata
--         if data == nil or data.lmbents == nil then
--             return
--         end

--         local ents = data.lmbents

--         --------------------------------------------------------
--         -- LÍNEA PRINCIPAL (FORZAR LONGITUD REAL CONSISTENTE)
--         --------------------------------------------------------
--         local decor2 = ents[2]
--         if decor2 ~= nil and decor2.centerbar ~= nil then

--             local bar = decor2.centerbar

--             if bar ~= nil then
--                 local sx, sy = bar:GetSize()

--                 -- NO usar w del UI, forzar consistencia visual
--                 local fixed_height = 3.0

--                 -- mantener escala base del sistema pero evitar “corte”
--                 bar:SetSize(sx, fixed_height)
--             end
--         end

--         --------------------------------------------------------
--         -- BORDE (SIN DESFASE DE LONGITUD)
--         --------------------------------------------------------
--         local decor4 = ents[4]
--         if decor4 ~= nil then
--             local sx, sy = decor4:GetSize()

--             if sx ~= nil then
--                 decor4:SetSize(sx, 6.0)
--             end
--         end

--     end
-- end)