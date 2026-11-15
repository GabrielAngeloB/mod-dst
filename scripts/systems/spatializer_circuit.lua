local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING


local function GetHeatModules(inst)
    local owner = inst.components.upgrademoduleowner
    if owner == nil then
        return 0
    end

    local count = owner:GetModuleTypeCount("heat")

    if count <= 0
        or not HasActiveModule(inst, "heat")
        or not HasCharge(inst) then
        return 0
    end

    return count
end

-------------------------------------------------------
-- WX CONTAINER PATCH
-------------------------------------------------------
AddPrefabPostInit("wx78_inventorycontainer", function (inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function ()
        if inst.components.preserver == nil then
            return
        end

        local old_fn = inst.components.preserver.perish_rate_multiplier

        inst.components.preserver:SetPerishRateMultiplier(function (container, item)
            ---------------------------------------------------
                -- OWNER CHECK
                ---------------------------------------------------
            local owner = container.components.inventoryitem and container.components.inventoryitem.owner

            ---------------------------------------------------
                -- CONDITIONS
                ---------------------------------------------------
            if owner == nil or not HasActiveModule(owner, "stacksize")
                or not HasSkill(owner, "wx78_circuitry_gammabuffs_2") or not HasCharge(owner) then
                ---------------------------------------------------
                    -- RETURN ORIGINAL BEHAVIOR
                    ---------------------------------------------------
                if type(old_fn) == "function" then
                    return old_fn(container, item) or 1
                elseif type(old_fn) == "number" then
                    return old_fn
                end

                return 1
            end

            local base = 1

            ---------------------------------------------------
                -- ORIGINAL WX RATE
                ---------------------------------------------------
            if type(old_fn) == "function" then
                base = old_fn(container, item) or 1
            elseif type(old_fn) == "number" then
                base = old_fn
            end

            local bonus = TUNING.WX78_PERISH_RATE_MODULELEAN or 0.25

            ---------------------------------------------------
                -- HOT MODULES
                ---------------------------------------------------
            if base > 1 then
                return base + bonus
            end

            ---------------------------------------------------
                -- COLD MODULES
                ---------------------------------------------------
            if base < 1 then
                local extra = 0

                if item ~= nil and (item.prefab == "ice" or item.prefab == "hambat") then
                    extra = 0.25
                end

                return math.max(0, base - bonus - extra)
            end

            ---------------------------------------------------
                -- NORMAL (SIN MÓDULOS)
                ---------------------------------------------------
            return 1
        end)
    end)
end)


-------------------------------------------------------
-- WX CONTAINER HEAT PATCH
-------------------------------------------------------
AddPrefabPostInit("wx78_inventorycontainer", function(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoPeriodicTask(1, function()

        local owner = inst.components.inventoryitem
            and inst.components.inventoryitem.owner

        if owner == nil
            or owner.prefab ~= "wx78"
            or not HasActiveModule(owner, "stacksize")
            or not HasSkill(owner, "wx78_circuitry_gammabuffs_2")
            or not HasCharge(owner) then
            return
        end


        local heatmods = GetHeatModules(owner)

        if heatmods <= 0 then
            return
        end


        local heat_rate = 0.25 * heatmods


        local inventory = inst.components.container

        if inventory ~= nil then

            for _, item in pairs(inventory.slots) do

                if item ~= nil
                    and item.components.fumaroletool ~= nil
                    and item.components.inventoryitemtemperature ~= nil then

                    local temp = item.components.inventoryitemtemperature

                    temp:SetTemperature(math.min(
                        temp.temperature + heat_rate,
                        temp.maxtemp or TUNING.MAX_ENTITY_TEMP
                    ))
                end
            end
        end

    end)

end)