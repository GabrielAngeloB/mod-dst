local GLOBAL = GLOBAL

AddComponentPostInit("upgrademoduleowner", function(self)
    local old_can_use = self.CanUseModule
    if old_can_use ~= nil then
        self.CanUseModule = function(self, module, ...)
            if module == "lightmodule_beam" then
                return false
            end
            return old_can_use(self, module, ...)
        end
    end

    local old_activate = self.ActivateModule
    if old_activate ~= nil then
        self.ActivateModule = function(self, module, ...)
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

local function ReadLightValue(light, getter_name, fallback)
    local getter = light[getter_name]
    if type(getter) == "function" then
        local value = getter(light)
        if type(value) == "number" then
            return value
        end
    end
    return fallback
end

local function CaptureLight(light)
    local colour = { 1, 1, 1 }
    if type(light.GetColour) == "function" then
        local r, g, b = light:GetColour()
        if r ~= nil and g ~= nil and b ~= nil then
            colour = { r, g, b }
        end
    end

    return {
        colour = colour,
        intensity = ReadLightValue(light, "GetIntensity", 0.9),
        radius = ReadLightValue(light, "GetRadius", 0.5),
        falloff = ReadLightValue(light, "GetFalloff", 0.5),
    }
end

local function RestoreLight(light, original)
    if original == nil then
        return
    end

    light:SetColour(original.colour[1], original.colour[2], original.colour[3])
    light:SetIntensity(original.intensity)
    light:SetRadius(original.radius)
    light:SetFalloff(original.falloff)
end

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    local skill = "wx78_circuitry_betabuffs_2"
    local colour = { 180 / 255, 195 / 255, 150 / 255 }

    local base_radius = 2
    local base_intensity = 0.6
    local falloff = 1
    local radius_per_module = 1

    local applied = false
    local original_light = nil

    local function GetActiveLightModules(wx)
        return GetActiveModuleCount(wx, "light")
            + GetActiveModuleCount(wx, "light2")
    end

    inst:DoPeriodicTask(0.1, function()
        local light = inst.Light
        if light == nil then
            return
        end

        local active_modules = GetActiveLightModules(inst)
        local should_apply = HasSkill(inst, skill)
            and HasCharge(inst)
            and active_modules > 0

        if not should_apply then
            if applied then
                RestoreLight(light, original_light)
                applied = false
                original_light = nil
            end
            return
        end

        if not applied then
            original_light = CaptureLight(light)
        end

        light:SetColour(colour[1], colour[2], colour[3])
        light:SetIntensity(base_intensity)
        light:SetRadius(base_radius + active_modules * radius_per_module)
        light:SetFalloff(falloff)
        applied = true
    end)
end)
