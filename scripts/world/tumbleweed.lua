
local GLOBAL = GLOBAL
---------------------------------------------------------
--TUMBLEWEED DROPS GOOSE FEATHER
-----------------------------------------------------------

local feather_pool = { "feather_crow", "feather_robin", "feather_robin_winter", "feather_canary", "goose_feather" }

local vanilla_feathers = {
    feather_crow = true,
    feather_robin = true,
    feather_robin_winter = true,
    feather_canary = true
}

local function AddGooseFeather(inst)
    if not GLOBAL.TheWorld or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function (inst)
        if inst.loot == nil then
            return
        end

        for i = 1, #inst.loot do
            local item = inst.loot[i]

            -- just if it is a vanilla feather, replace it with a random one from the pool (including goose feather)
            if vanilla_feathers[item] then
                -- reroll
                inst.loot[i] = feather_pool[math.random(#feather_pool)]
            end
        end
    end)
end

AddPrefabPostInit("tumbleweed", AddGooseFeather)