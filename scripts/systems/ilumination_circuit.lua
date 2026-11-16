local GLOBAL = GLOBAL

AddComponentPostInit("upgrademoduleowner", function(self)
    local old_can_use = self.CanUseModule
    if old_can_use ~= nil then
        function self:CanUseModule(module, ...)
            if module == "lightmodule_beam" then
                return false
            end
            return old_can_use(self, module, ...)
        end
    end

    local old_activate = self.ActivateModule
    if old_activate ~= nil then
        function self:ActivateModule(module, ...)
            if module == "lightmodule_beam" then
                return false
            end
            return old_activate(self, module, ...)
        end
    end
end)

AddPrefabPostInit("wx78_lightbeam", function(inst)
    inst:DoTaskInTime(0, function()
        if inst:IsValid() then
            inst:Remove()
        end
    end)
end)

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    local SKILL = "wx78_circuitry_betabuffs_2"
    local COLOR = { 180 / 255, 195 / 255, 150 / 255 }

    local BASE_RADIUS = 2
    local BASE_INTENSITY = 0.6
    local FALLOFF = 1
    local RADIUS_PER_MODULE = 1

    local applied = false
    local original_light = nil

    local function CaptureOriginalLight(light)
        if light == nil or light.GetColour == nil
            or light.GetIntensity == nil or light.GetRadius == nil
            or light.GetFalloff == nil then
            return nil
        end

        local r, g, b = light:GetColour()
        return {
            r = r,
            g = g,
            b = b,
            intensity = light:GetIntensity(),
            radius = light:GetRadius(),
            falloff = light:GetFalloff(),
            enabled = light.IsEnabled ~= nil and light:IsEnabled() or false,
        }
    end

    local function RestoreOriginalLight(light)
        if light == nil or original_light == nil then
            return
        end

        light:SetColour(original_light.r, original_light.g, original_light.b)
        light:SetIntensity(original_light.intensity)
        light:SetRadius(original_light.radius)
        light:SetFalloff(original_light.falloff)
        light:Enable(original_light.enabled)
    end

    local function GetActiveLightModules(wx)
        return GetActiveModuleCount(wx, "light")
            + GetActiveModuleCount(wx, "light2")
    end

    local function ApplyLight()
        if not inst:IsValid() or inst.Light == nil then
            return
        end

        local active_modules = GetActiveLightModules(inst)
        local should_apply = HasSkill(inst, SKILL)
            and HasCharge(inst)
            and active_modules > 0

        if should_apply then
            if not applied then
                original_light = CaptureOriginalLight(inst.Light)
            end

            inst.Light:SetColour(COLOR[1], COLOR[2], COLOR[3])
            inst.Light:SetIntensity(BASE_INTENSITY)
            inst.Light:SetRadius(BASE_RADIUS + active_modules * RADIUS_PER_MODULE)
            inst.Light:SetFalloff(FALLOFF)
            inst.Light:Enable(true)

            applied = true
        elseif applied then
            RestoreOriginalLight(inst.Light)
            applied = false
            original_light = nil
        end
    end

    inst:DoTaskInTime(0, ApplyLight)
    inst:DoPeriodicTask(0.25, ApplyLight)
end)
