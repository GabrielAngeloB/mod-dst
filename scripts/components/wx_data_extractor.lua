local GLOBAL = GLOBAL

local WX_Data_Extractor = Class(function(self, inst)
    self.inst = inst
end)

local function SafeGetRecipe(prefab)
    local recipes = GLOBAL.AllRecipes or AllRecipes
    return recipes ~= nil and recipes[prefab] or nil
end

local function GetScandataYield(recipe)
    if recipe == nil or recipe.ingredients == nil then
        return 0
    end

    local required = 0
    for _, ingredient in pairs(recipe.ingredients) do
        if ingredient ~= nil and ingredient.type == "scandata" then
            local amount = ingredient.amount or ingredient.quantity or 0
            if type(amount) == "number" and amount > 0 then
                required = required + amount
            end
        end
    end

    -- Refund half the total Scandata cost, rounded down. Never consume a
    -- module if the recipe would produce no Scandata at all.
    return math.floor(required / 2)
end

function WX_Data_Extractor:BreakDown(target, doer)
    if target == nil or not target:IsValid()
        or target.prefab == nil or doer == nil or not doer:IsValid() then
        return false
    end

    local inventoryitem = target.components ~= nil
        and target.components.inventoryitem or nil
    local owner = inventoryitem ~= nil and inventoryitem:GetGrandOwner() or nil
    local owner_components = owner ~= nil and owner.components or nil

    local receiver = owner_components ~= nil
        and (owner_components.inventory or owner_components.container)
        or nil

    local position_source = receiver ~= nil and self.inst or doer
    local position = position_source:GetPosition()

    local recipe = SafeGetRecipe(target.prefab)
    local yield = GetScandataYield(recipe)
    if yield <= 0 then
        return false
    end

    -- Create all refund items before delivering any of them. If the prefab is
    -- unavailable, leave the module intact and clean up the partial batch.
    local items = {}
    for i = 1, yield do
        local item = GLOBAL.SpawnPrefab("scandata")
        if item == nil then
            for _, spawned in ipairs(items) do
                if spawned:IsValid() then
                    spawned:Remove()
                end
            end
            return false
        end
        items[i] = item
    end

    for _, item in ipairs(items) do
        if receiver ~= nil and type(receiver.GiveItem) == "function" then
            receiver:GiveItem(item, nil, position)
        elseif item.Transform ~= nil then
            item.Transform:SetPosition(position:Get())
        else
            item:Remove()
        end
    end

    target:Remove()
    return true
end

return WX_Data_Extractor
