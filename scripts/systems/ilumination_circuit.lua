local GLOBAL = GLOBAL
----------------------------------------------------------------
-- LIGHTMODULE CHANGES
----------------------------------------------------------------
----------------------------------------------------------------
-- LIGHTMODULE_BEAM block
----------------------------------------------------------------
AddComponentPostInit("upgrademoduleowner", function(self)
    local _CanUseModule = self.CanUseModule
    if _CanUseModule then
        self.CanUseModule = function(self, module, ...)
            if module == "lightmodule_beam" then
                return false
            end

            return _CanUseModule(self, module, ...)
        end
    end

    local _ActivateModule = self.ActivateModule
    if _ActivateModule then
        self.ActivateModule = function(self, module, ...)
            if module == "lightmodule_beam" then
                return false
            end

            return _ActivateModule(self, module, ...)
        end
    end
end)

----------------------------------------------------------------
-- REMOVE LIGHTBEAM
----------------------------------------------------------------
AddPrefabPostInit("wx78_lightbeam", function(inst)
    inst:DoTaskInTime(0, function()
        inst:Remove()
    end)
end)

----------------------------------------------------------------
-- WX78 LIGHT OVERRIDE
----------------------------------------------------------------
AddPrefabPostInit("wx78", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    local SKILL = "wx78_circuitry_betabuffs_2"

    local COLOR = { 180 / 255, 195 / 255, 150 / 255 }

    local BASE_RADIUS = 2
    local BASE_INTENSITY = 0.6
    local FALLOFF = 1
    local RADIUS_PER_MODULE = 1

    local applied = false

    --------------------------------------------------------
    -- MODULE COUNT
    --------------------------------------------------------
    local function GetActiveLightModules(inst)
        local owner = inst.components.upgrademoduleowner

        if owner == nil then
            return 0
        end

        local count = 0

        for _, module in ipairs(owner:GetAllModules()) do
            if (module.prefab == "wx78module_light"
                or module.prefab == "wx78module_light2")
                and module.components ~= nil
                and module.components.upgrademodule ~= nil
                and module.components.upgrademodule.activated then

                count = count + 1
            end
        end

        return count
    end

    --------------------------------------------------------
    -- LIGHT UPDATE
    --------------------------------------------------------
    inst:DoPeriodicTask(0.1, function()
        if inst.Light == nil then
            return
        end

        ----------------------------------------------------
        -- CONDITIONS
        ----------------------------------------------------
        if not HasSkill(inst, SKILL) or not HasCharge(inst) then
            if applied then
                inst.Light:SetColour(1, 1, 1)
                inst.Light:SetIntensity(0.9)
                inst.Light:SetRadius(0.5)
                inst.Light:SetFalloff(0.5)

                applied = false
            end

            return
        end

        ----------------------------------------------------
        -- ACTIVE MODULES
        ----------------------------------------------------
        local active_modules = GetActiveLightModules(inst)

        if active_modules <= 0 then
            if applied then
                inst.Light:SetColour(1, 1, 1)
                inst.Light:SetIntensity(0.9)
                inst.Light:SetRadius(0.5)
                inst.Light:SetFalloff(0.5)

                applied = false
            end

            return
        end

        ----------------------------------------------------
        -- STACK
        ----------------------------------------------------
        local radius = BASE_RADIUS + (active_modules * RADIUS_PER_MODULE)

        ----------------------------------------------------
        -- APPLY
        ----------------------------------------------------
        inst.Light:SetColour(COLOR[1], COLOR[2], COLOR[3])
        inst.Light:SetIntensity(BASE_INTENSITY)
        inst.Light:SetRadius(radius)
        inst.Light:SetFalloff(FALLOFF)

        applied = true
    end)
end)