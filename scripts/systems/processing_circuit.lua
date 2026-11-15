
local GLOBAL = GLOBAL

----------------BEANBOOSTER CIRCUIT CHANGES: START-------------
local function ProcessingcircuitSkill(wx)
    if wx == nil or not wx:IsValid() then
        return
    end

    -------------------------------------------------------
    -- CONDITIONS
    -------------------------------------------------------
    local sanity = wx.components.sanity
    local low_sanity = sanity and sanity:GetPercent() <= 0.72758 

    local module = 
    HasActiveModule(wx, "maxsanity") or 
    HasActiveModule(wx, "maxsanity1") or 
    HasActiveModule(wx, "bee")

    local skill = HasSkill(wx, "wx78_circuitry_alphabuffs_2")
    local charge = HasCharge(wx)

    -------------------------------------------------------
    -- ENABLE / DISABLE FAST BUILDER
    -------------------------------------------------------
    if module and skill and charge then
        -- LOW SANITY = DISABLE
        if low_sanity then
            if wx:HasTag("fastbuilder") then
                wx:RemoveTag("fastbuilder")

                if wx.components.talker then
                    wx.components.talker:Say(GLOBAL.L.SPEECH.FASTBUILDER_DISABLED)
                end
            end

            -- NORMAL SANITY = ENABLE
        else
            if not wx:HasTag("fastbuilder") then
                wx:AddTag("fastbuilder")

                if wx.components.talker then
                    wx.components.talker:Say(GLOBAL.L.SPEECH.FASTBUILDER_ENABLED)
                end
            end
        end
    else
        -------------------------------------------------------
        -- REMOVE IF CONDITIONS FAIL
        -------------------------------------------------------
        if wx:HasTag("fastbuilder") then
            wx:RemoveTag("fastbuilder")
        end
    end
end
----------------BEANBOOSTER CIRCUIT CHANGES: END-------------

-------------------------------------------------------
-- HOOK
-------------------------------------------------------
AddPrefabPostInit("wx78", function (inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("sanitydelta", function ()
        ProcessingcircuitSkill(inst)
    end)

    inst:DoTaskInTime(0, function ()
        ProcessingcircuitSkill(inst)
    end)
end)
