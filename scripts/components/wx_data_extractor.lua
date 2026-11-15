local WX_Data_Extractor = Class(function(self, inst)
    self.inst = inst
end)

local function SafeGetRecipe(prefab)
    return AllRecipes ~= nil and AllRecipes[prefab] or nil
end

local function GetReceiver(target, doer)
    local owner = target.components ~= nil
        and target.components.inventoryitem ~= nil
        and target.components.inventoryitem:GetGrandOwner()
        or nil

    if owner == nil then
        owner = doer
    end

    if owner == nil or owner.components == nil then
        return nil
    end

    return owner.components.inventory or owner.components.container
end

local function GiveScandata(receiver, item, position)
    if item == nil then
        return false
    end

    if receiver ~= nil and receiver.GiveItem ~= nil then
        receiver:GiveItem(item, nil, position)
    elseif item.Transform ~= nil then
        item.Transform:SetPosition(position:Get())
    else
        item:Remove()
        return false
    end

    return true
end

function WX_Data_Extractor:BreakDown(target, doer)
    if target == nil or target.prefab == nil
        or doer == nil or not doer:IsValid() then
        return false
    end

    local recipe = SafeGetRecipe(target.prefab)
    if recipe == nil or recipe.ingredients == nil then
        return false
    end

    local receiver = GetReceiver(target, doer)
    local position = self.inst ~= nil and self.inst:IsValid()
        and self.inst:GetPosition() or doer:GetPosition()

    local recovered = 0
    for _, ingredient in pairs(recipe.ingredients) do
        if ingredient ~= nil and ingredient.type == "scandata" then
            local amount = math.floor(
                ((ingredient.amount or ingredient.quantity or 0) / 2)
            )

            for _ = 1, amount do
                local item = SpawnPrefab("scandata")
                if GiveScandata(receiver, item, position) then
                    recovered = recovered + 1
                end
            end
        end
    end

    if recovered <= 0 then
        return false
    end

    target:Remove()
    return true
end

return WX_Data_Extractor
