local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING

local function GetHeatModules(inst)
    return GetActiveModuleCount(inst, "heat")
end

-------------------------------------------------------
-- WX CONTAINER PATCH
-------------------------------------------------------
AddPrefabPostInit("wx78_inventorycontainer", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function()
        local preserver = inst.components ~= nil and inst.components.preserver or nil
        if preserver == nil then
            return
        end

        local old_fn = preserver.perish_rate_multiplier

        preserver:SetPerishRateMultiplier(function(container, item)
            local owner = container.components ~= nil
                and container.components.inventoryitem ~= nil
                and container.components.inventoryitem.owner or nil

            if owner == nil or not HasActiveModule(owner, "stacksize")
                or not HasSkill(owner, "wx78_circuitry_gammabuffs_2")
                or not HasCharge(owner) then
                if type(old_fn) == "function" then
                    return old_fn(container, item) or 1
                elseif type(old_fn) == "number" then
                    return old_fn
                end
                return 1
            end

            local base = 1
            if type(old_fn) == "function" then
                base = old_fn(container, item) or 1
            elseif type(old_fn) == "number" then
                base = old_fn
            end

            local bonus = TUNING.WX78_PERISH_RATE_MODULELEAN or 0.25
            if base > 1 then
                return base + bonus
            elseif base < 1 then
                local extra = item ~= nil
                    and (item.prefab == "ice" or item.prefab == "hambat")
                    and 0.25 or 0
                return math.max(0, base - bonus - extra)
            end

            return 1
        end)
    end)
end)

-------------------------------------------------------
-- THERMIC TOOLS STORED IN THE WX CONTAINER
-------------------------------------------------------
AddPrefabPostInit("wx78_inventorycontainer", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoPeriodicTask(1, function()
        local owner = inst.components ~= nil and inst.components.inventoryitem ~= nil
            and inst.components.inventoryitem.owner or nil

        if owner == nil or owner.prefab ~= "wx78"
            or not HasActiveModule(owner, "stacksize")
            or not HasSkill(owner, "wx78_circuitry_gammabuffs_2")
            or not HasCharge(owner) then
            return
        end

        local heatmods = GetHeatModules(owner)
        if heatmods <= 0 then
            return
        end

        local inventory = inst.components ~= nil and inst.components.container or nil
        if inventory == nil then
            return
        end

        local heat_rate = 0.25 * heatmods
        for _, item in pairs(inventory.slots) do
            if item ~= nil and item.components ~= nil
                and item.components.fumaroletool ~= nil
                and item.components.inventoryitemtemperature ~= nil then
                local temp = item.components.inventoryitemtemperature
                temp:SetTemperature(math.min(
                    temp.temperature + heat_rate,
                    temp.maxtemp or TUNING.MAX_ENTITY_TEMP
                ))
            end
        end
    end)
end)
