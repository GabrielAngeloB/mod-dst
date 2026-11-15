local GLOBAL = GLOBAL
local SANITY_THRESHOLD = 0.72758

local function HasProcessingModule(wx)
    return HasActiveModule(wx, "maxsanity")
        or HasActiveModule(wx, "maxsanity1")
        or HasActiveModule(wx, "bee")
end

local function ShouldEnableFastBuilder(wx)
    if wx == nil or not wx:IsValid() then
        return false
    end

    local sanity = wx.components ~= nil and wx.components.sanity or nil
    local low_sanity = sanity ~= nil and sanity:GetPercent() <= SANITY_THRESHOLD

    return not low_sanity
        and HasProcessingModule(wx)
        and HasSkill(wx, "wx78_circuitry_alphabuffs_2")
        and HasCharge(wx)
end

local function UpdateFastBuilder(wx)
    if wx == nil or not wx:IsValid() then
        return
    end

    local should_enable = ShouldEnableFastBuilder(wx)
    local owns_tag = wx._dwx78_fastbuilder_tag_owned == true

    if should_enable then
        if not wx:HasTag("fastbuilder") then
            wx:AddTag("fastbuilder")
            wx._dwx78_fastbuilder_tag_owned = true

            if wx.components.talker ~= nil then
                wx.components.talker:Say(GLOBAL.L.SPEECH.FASTBUILDER_ENABLED)
            end
        end
    elseif owns_tag then
        wx:RemoveTag("fastbuilder")
        wx._dwx78_fastbuilder_tag_owned = nil

        local sanity = wx.components ~= nil and wx.components.sanity or nil
        if sanity ~= nil and sanity:GetPercent() <= SANITY_THRESHOLD
            and wx.components.talker ~= nil then
            wx.components.talker:Say(GLOBAL.L.SPEECH.FASTBUILDER_DISABLED)
        end
    end
end

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("sanitydelta", function()
        UpdateFastBuilder(inst)
    end)

    inst:DoTaskInTime(0, function()
        UpdateFastBuilder(inst)
    end)

    -- Circuit activation, charge and skill state do not all emit sanitydelta.
    inst:DoPeriodicTask(0.5, UpdateFastBuilder)
end)
