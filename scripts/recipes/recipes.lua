------------------------------------------------------------
-- recipe changes
------------------------------------------------------------
local GLOBAL = GLOBAL
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH

------------------------------------------------------------

AddRecipePostInit("wx78module_stacksize", function (recipe)
    recipe.ingredients = { Ingredient("scandata", 8), Ingredient("wagpunk_bits", 1), Ingredient("transistor", 1) }
    recipe.level = TECH.ROBOTMODULECRAFT_ONE
    recipe.builder_tag = "upgrademoduleowner"
end)

AddRecipePostInit("wx78module_light", function (recipe)
    recipe.ingredients = { Ingredient("scandata", 4), Ingredient("fireflies", 1) }
    recipe.level = TECH.ROBOTMODULECRAFT_ONE
    recipe.builder_tag = "upgrademoduleowner"
end)

AddRecipePostInit("wx78module_light2", function (recipe)
    recipe.ingredients = { Ingredient("scandata", 3), Ingredient("lightbulb", 1), Ingredient("wx78module_light", 1) }
    recipe.level = TECH.ROBOTMODULECRAFT_ONE
    recipe.builder_tag = "upgrademoduleowner"
end)

AddRecipePostInit("wx78module_nightvision", function (recipe)
    recipe.ingredients = { Ingredient("scandata", 8), Ingredient("mole", 1), Ingredient("wormlight", 1) }
    recipe.level = TECH.ROBOTMODULECRAFT_ONE
    recipe.builder_tag = "upgrademoduleowner"
end)

AddRecipePostInit("wx78module_shielding", function (recipe)
    recipe.ingredients = { Ingredient("scandata", 4), Ingredient("armorsnurtleshell", 1) }
    recipe.level = TECH.ROBOTMODULECRAFT_ONE
    recipe.builder_tag = "upgrademoduleowner"
end)

AddRecipePostInit("wx78module_chess", function (recipe)
    recipe.ingredients = { Ingredient("scandata", 3), Ingredient("trinket_6", 1) }
    recipe.level = TECH.ROBOTMODULECRAFT_ONE
    recipe.builder_tag = "upgrademoduleowner"
end)

AddRecipePostInit("wx78module_maxhealth2", function (recipe)
    -- Mantém as 4 Bio Data, adiciona 3 Ouros e troca as glândulas por 1 Gema Vermelha
    recipe.ingredients = { Ingredient("scandata", 6), Ingredient("goldnugget", 3), Ingredient("redgem", 1) }
    recipe.level = TECH.ROBOTMODULECRAFT_ONE
    recipe.builder_tag = "upgrademoduleowner"
end)

AddRecipePostInit("wx78module_taser", function (recipe)
    -- Altere os ingredientes abaixo para a sua nova receita
    recipe.ingredients = { Ingredient("scandata", 6), Ingredient("goatmilk", 2), Ingredient("transistor", 2) }
    recipe.level = TECH.ROBOTMODULECRAFT_ONE
    recipe.builder_tag = "upgrademoduleowner"
end)

AddRecipePostInit("wx78_shadowdrone_debuffer", function(recipe)
    recipe.ingredients =
    {
        Ingredient("nightmarefuel", 4),
        Ingredient("transistor", 4),
    }

    recipe.level = TECH.LOST
    recipe.builder_tag = "upgrademoduleowner"
end)