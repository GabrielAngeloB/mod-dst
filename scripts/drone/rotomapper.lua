local GLOBAL = GLOBAL

--------------------------------------------------------------------------
-- WX-78 DRONE SCOUT QoL: ARRIVAL MESSAGE
--------------------------------------------------------------------------

AddComponentPostInit("mapdeliverable", function(self)
    if not self._wx78_onupdate_patched and type(self.OnUpdate) == "function" then
        self._wx78_onupdate_patched = true
        local old_onupdate = self.OnUpdate

        self.OnUpdate = function(comp, dt)
            if type(comp.t) == "number" and type(comp.len) == "number"
                and type(dt) == "number" and comp.t + dt >= comp.len then
                comp._wx78_arrived = true
            else
                comp._wx78_arrived = false
            end

            return old_onupdate(comp, dt)
        end
    end

    if not self._wx78_stop_patched and type(self.Stop) == "function" then
        self._wx78_stop_patched = true
        local old_stop = self.Stop

        self.Stop = function(comp, ...)
            comp._wx78_arrived = false
            return old_stop(comp, ...)
        end
    end

    if not self._wx78_sendtopoint_patched and type(self.SendToPoint) == "function" then
        self._wx78_sendtopoint_patched = true
        local old_send = self.SendToPoint

        self.SendToPoint = function(comp, pt, doer, ...)
            comp._wx78_arrived = false
            local success, reason = old_send(comp, pt, doer, ...)

            if success then
                comp._wx78_delivery_active = true
                if doer ~= nil then
                    comp.inst._wx78_owner = doer
                end
            end

            return success, reason
        end
    end
end)

AddPrefabPostInit("wx78_drone_scout", function(inst)
    inst:DoTaskInTime(0, function()
        if inst.components == nil or inst.components.mapdeliverable == nil then
            return
        end

        local comp = inst.components.mapdeliverable
        if type(comp.SetOnStopDeliveryFn) ~= "function" then
            return
        end

        local oldfn = comp.onstopdeliveryfn
        comp:SetOnStopDeliveryFn(function(drone)
            if oldfn ~= nil then
                oldfn(drone)
            end

            if not comp._wx78_delivery_active then
                return
            end

            if not comp._wx78_arrived then
                comp._wx78_delivery_active = false
                return
            end

            comp._wx78_delivery_active = false
            comp._wx78_arrived = false

            local owner = drone._wx78_owner
            local speech = GLOBAL.L ~= nil and GLOBAL.L.SPEECH or nil
            if owner ~= nil and owner:IsValid()
                and owner.components ~= nil
                and owner.components.talker ~= nil
                and speech ~= nil and speech.DRONE_ARRIVED ~= nil then
                if owner.SoundEmitter ~= nil then
                    owner.SoundEmitter:PlaySound("dontstarve/HUD/Together_HUD/learn_map")
                end
                owner.components.talker:Say(speech.DRONE_ARRIVED)
            end
        end)
    end)
end)
