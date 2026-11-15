local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING

local day_time = TUNING.DAY_TIME_DEFAULT
TUNING.WX78_MUSIC_DAPPERNESS = 100 / (day_time * 1.98)

local EXTRA_TAGS = { "monkey", "tallbird", "guard", "frog", "wx_disguised" }

local function ChorusboxCircuitSkill(wx)
    if wx == nil or not wx:IsValid() then
        return
    end

    local active = HasSkill(wx, "wx78_circuitry_betabuffs_1")
        and HasActiveModule(wx, "music")
        and HasCharge(wx)

    wx._dwx78_chorusbox_owned_tags = wx._dwx78_chorusbox_owned_tags or {}
    local owned = wx._dwx78_chorusbox_owned_tags

    for _, tag in ipairs(EXTRA_TAGS) do
        if active then
            if not wx:HasTag(tag) then
                wx:AddTag(tag)
                owned[tag] = true
            end
        elseif owned[tag] then
            wx:RemoveTag(tag)
            owned[tag] = nil
        end
    end
end

AddPlayerPostInit(function(inst)
    if inst.prefab ~= "wx78" or GLOBAL.TheWorld == nil
        or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoPeriodicTask(0.5, function()
        ChorusboxCircuitSkill(inst)
    end)
    inst:DoTaskInTime(0, function()
        ChorusboxCircuitSkill(inst)
    end)
end)

local function AddRetargetIgnore(prefab)
    AddPrefabPostInit(prefab, function(inst)
        if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim
            or inst.components == nil or inst.components.combat == nil then
            return
        end

        local combat = inst.components.combat
        local old_ret = combat.targetfn
        if old_ret == nil then
            return
        end

        combat:SetRetargetFunction(3, function(creature)
            local target = old_ret(creature)
            if target ~= nil and target:HasTag("wx_disguised") then
                return nil
            end
            return target
        end)
    end)
end

local function AddDisguiseNoAggro(prefab)
    AddPrefabPostInit(prefab, function(inst)
        if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim
            or inst.components == nil or inst.components.combat == nil then
            return
        end

        local original = inst.components.combat.noaggrotags or {}
        local tags = {}
        local found = false

        for _, tag in ipairs(original) do
            tags[#tags + 1] = tag
            if tag == "wx_disguised" then
                found = true
            end
        end

        if not found then
            tags[#tags + 1] = "wx_disguised"
        end

        inst.components.combat:SetNoAggroTags(tags)
    end)
end

AddRetargetIgnore("frog")
AddRetargetIgnore("lunarfrog")
AddRetargetIgnore("merm")
AddDisguiseNoAggro("pigman")
AddDisguiseNoAggro("pigguard")
