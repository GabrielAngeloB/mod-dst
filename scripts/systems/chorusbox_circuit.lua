
local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING

----------------CHORUSBOX CIRCUIT CHANGES: START-------------
local day_time = TUNING.DAY_TIME_DEFAULT
TUNING.WX78_MUSIC_DAPPERNESS = 100 / (day_time * 1.98)

-------------------------------------------------------------
-- WX78 TAG SYSTEM
-------------------------------------------------------------

local EXTRA_TAGS = { "monkey", "tallbird", "guard", "frog", "wx_disguised" }

-------------------------------------------------------------
-- CHECK ACTIVE MUSIC MODULES 
--------------------------------------------------------------
local function ChorusboxCircuitSkill(wx)
    if wx == nil or not wx:IsValid() then return end

    local skill = HasSkill(wx, "wx78_circuitry_betabuffs_1")
    local module = HasActiveModule(wx, "music")
    local charge = HasCharge(wx)
    local enabled = skill and module and charge

    wx._dwx78_chorusbox_added_tags = wx._dwx78_chorusbox_added_tags or {}

    for _, tag in ipairs(EXTRA_TAGS) do
        if enabled then
            if not wx:HasTag(tag) then
                wx:AddTag(tag)
                wx._dwx78_chorusbox_added_tags[tag] = true
            end
        elseif wx._dwx78_chorusbox_added_tags[tag] then
            if wx:HasTag(tag) then
                wx:RemoveTag(tag)
            end
            wx._dwx78_chorusbox_added_tags[tag] = nil
        end
    end
end

-------------------------------------------------------------
-- PLAYER INIT
-------------------------------------------------------------

AddPlayerPostInit(function (inst)
    if inst.prefab ~= "wx78" then
        return
    end

    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    local function Update()
        ChorusboxCircuitSkill(inst)
    end
    ------------------------------------------------
    -- SAFETY REFRESH
    ------------------------------------------------
    inst:DoPeriodicTask(0.5, Update)

    inst:DoTaskInTime(0, Update)
end)

-------------------------------------------------------------
-- RETARGET IGNORE (SAFE BASE)
-------------------------------------------------------------

local function AddRetargetIgnore(prefab)
    AddPrefabPostInit(prefab, function (inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end

        if inst.components.combat == nil then
            return
        end

        local old_ret = inst.components.combat.targetfn

        inst.components.combat:SetRetargetFunction(3, function (inst)
            local target = old_ret ~= nil and old_ret(inst) or nil

            if target ~= nil and target:HasTag("wx_disguised") then
                return nil
            end

            return target
        end)
    end)
end

-------------------------------------------------------------
-- NO AGGRO TAGS
-------------------------------------------------------------
local function AddDisguiseNoAggro(prefab)
    AddPrefabPostInit(prefab, function (inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end

        if inst.components.combat == nil then
            return
        end

        local tags = inst.components.combat.noaggrotags or {}

        local found = false

        for _, tag in ipairs(tags) do
            if tag == "wx_disguised" then
                found = true
                break
            end
        end

        if not found then
            table.insert(tags, "wx_disguised")
        end

        inst.components.combat:SetNoAggroTags(tags)
    end)
end

-------------------------------------------------------------
-- APPLY FIXES
-------------------------------------------------------------

AddRetargetIgnore("frog")
AddRetargetIgnore("lunarfrog")
AddRetargetIgnore("merm")
AddDisguiseNoAggro("pigman")
AddDisguiseNoAggro("pigguard")