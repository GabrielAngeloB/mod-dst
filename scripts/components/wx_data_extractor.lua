local WX_Data_Extractor = Class(function(self, inst)
    self.inst = inst
end)

local function SafeGetRecipe(prefab)
    if AllRecipes and AllRecipes[prefab] then
        return AllRecipes[prefab]
    end
    return nil
end

function WX_Data_Extractor:BreakDown(target, doer)

    if target == nil or target.prefab == nil then
        return false
    end

    local owner = target.components.inventoryitem
        and target.components.inventoryitem:GetGrandOwner()

    local receiver = (owner ~= nil and owner.components.inventory)
        or (owner ~= nil and owner.components.container)
        or nil

    local pt = (receiver ~= nil and self.inst:GetPosition()) or doer:GetPosition()

    -- SAFE recipe access
    local recipe = SafeGetRecipe(target.prefab)

    if recipe == nil or recipe.ingredients == nil then
        return false
    end

    for _, ing in pairs(recipe.ingredients) do
        if ing ~= nil and ing.type == "scandata" then

            -- HALF, rounded down to integer
            local amount = math.floor(((ing.amount or ing.quantity or 0) / 2))

            for i = 1, amount do
                local item = SpawnPrefab("scandata")

                if receiver ~= nil then
                    receiver:GiveItem(item, nil, pt)
                else
                    item.Transform:SetPosition(pt:Get())
                end
            end
        end
    end

    target:Remove()
    return true
end

return WX_Data_Extractor