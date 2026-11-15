local TUNING = GLOBAL.TUNING

-- The current WX-78 module implementation reads this nested tuning value.
-- Keep a stronger value supplied by another mod instead of lowering it.
local wx_tuning = TUNING.SKILLS ~= nil and TUNING.SKILLS.WX78 or nil
if wx_tuning ~= nil then
    wx_tuning.BEE_SHIELD_REGEN_PER_SECOND = math.max(
        wx_tuning.BEE_SHIELD_REGEN_PER_SECOND or 0,
        0.5
    )
end

-- Beanbooster: allow shield charging during combat, but not while WX-78 is hurt.
AddComponentPostInit("wx78_shield", function(self)
    local function IsHurt(inst)
        return inst ~= nil
            and inst.components ~= nil
            and inst.components.health ~= nil
            and inst.components.health:IsHurt()
            or false
    end

    function self:UpdateCanShieldCharge()
        self.canshieldcharge = self.updating
            and self.currentshield < self.maxshield
            and not IsHurt(self.inst)
    end
end)
