local GLOBAL = GLOBAL

local SANITY_THRESHOLD = 0.72758
local MODULE_TYPES = { "maxsanity", "maxsanity1", "bee" }

local function HasProcessingModule(wx)
    for _, module_type in ipairs(MODULE_TYPES) do
        if HasActiveModule(wx, module_type) then
            return true
        end
    end
    return false
end

local function SetProcessingState(wx)
    if wx == nil or not wx:IsValid() then
        return
    end

    local sanity = wx.components ~= nil and wx.components.sanity or nil
    local low_sanity = sanity ~= nil and sanity:GetPercent() <= SANITY_THRESHOLD
    local conditions_met = HasProcessingModule(wx)
        and HasSkill(wx, "wx78_circuitry_alphabuffs_2")
        and HasCharge(wx)

    local should_enable = conditions_met and not low_sanity
    local was_enabled = wx._wx78_processing_fastbuilder_enabled == true
    local owns_tag = wx._wx78_processing_added_fastbuilder == true
    local has_tag = wx:HasTag("fastbuilder")

    if should_enable then
        if not has_tag then
            wx:AddTag("fastbuilder")
            wx._wx78_processing_added_fastbuilder = true
        end

        wx._wx78_processing_fastbuilder_enabled = true
        if not was_enabled and wx.components.talker ~= nil
            and GLOBAL.L ~= nil and GLOBAL.L.SPEECH ~= nil
            and GLOBAL.L.SPEECH.FASTBUILDER_ENABLED ~= nil then
            wx.components.talker:Say(GLOBAL.L.SPEECH.FASTBUILDER_ENABLED)
        end
    else
        if owns_tag and has_tag then
            wx:RemoveTag("fastbuilder")
        end
        wx._wx78_processing_added_fastbuilder = nil
        wx._wx78_processing_fastbuilder_enabled = false

        if was_enabled and low_sanity and wx.components.talker ~= nil
            and GLOBAL.L ~= nil and GLOBAL.L.SPEECH ~= nil
            and GLOBAL.L.SPEECH.FASTBUILDER_DISABLED ~= nil then
            wx.components.talker:Say(GLOBAL.L.SPEECH.FASTBUILDER_DISABLED)
        end
    end
end

AddPrefabPostInit("wx78", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, SetProcessingState)
    inst:DoPeriodicTask(0.5, SetProcessingState)
    inst:ListenForEvent("sanitydelta", SetProcessingState)
    inst:ListenForEvent("energylevelupdate", SetProcessingState)
end)
