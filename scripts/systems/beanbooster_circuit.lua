local TUNING = GLOBAL.TUNING

-------------------------------------------------------
-- MOISTENED NUTRIBRICK
-------------------------------------------------------
TUNING.WX78_FOODBRICK_NUTRIENTS = { 16, 16, 0 }

local fertilizer_defs = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
if fertilizer_defs ~= nil and fertilizer_defs.wx78_foodbrick ~= nil then
    fertilizer_defs.wx78_foodbrick.nutrients = { 16, 16, 0 }
end

-------------------------------------------------------
-- BEANBOOSTER CIRCUIT
-------------------------------------------------------
-- The active DST WX-78 module code reads the nested tuning key below.
-- Preserve a higher value from another mod rather than reducing it.
local wx_tuning = TUNING.SKILLS ~= nil and TUNING.SKILLS.WX78 or nil
if wx_tuning ~= nil then
    wx_tuning.BEE_SHIELD_REGEN_PER_SECOND = math.max(
        wx_tuning.BEE_SHIELD_REGEN_PER_SECOND or 0,
        0.5
    )
end

-- Keep the original behavior: Beanbooster shield charges in combat, but not
-- while WX-78 is hurt.
AddComponentPostInit("wx78_shield", function(self)
    function self:UpdateCanShieldCharge()
        local health = self.inst.components ~= nil and self.inst.components.health or nil
        local is_hurt = health ~= nil and health:IsHurt() or false

        self.canshieldcharge = self.updating
            and self.currentshield < self.maxshield
            and not is_hurt
    end
end)
