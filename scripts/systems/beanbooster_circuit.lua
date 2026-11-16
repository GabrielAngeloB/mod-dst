local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING

-- Moistened Nutribrick.
TUNING.WX78_FOODBRICK_NUTRIENTS = { 16, 16, 0 }

local fertilizer_defs = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
if fertilizer_defs ~= nil and fertilizer_defs.wx78_foodbrick ~= nil then
    fertilizer_defs.wx78_foodbrick.nutrients = { 16, 16, 0 }
end

----------------------------------------------------------------
-- Current DST WX-78 module code reads this tuning when it registers
-- the BEE_CIRCUIT charge source on wx78_shield.
----------------------------------------------------------------
local wx78_tuning = TUNING.SKILLS ~= nil and TUNING.SKILLS.WX78 or nil
if wx78_tuning ~= nil
    and type(wx78_tuning.BEE_SHIELD_REGEN_PER_SECOND) == "number" then
    wx78_tuning.BEE_SHIELD_REGEN_PER_SECOND = 0.5
else
    print("[D'WX-78] Beanbooster: WX-78 shield regeneration tuning was not found.")
end

-- Permit shield regeneration during combat, but not while hurt.
-- Preserve the stock updating and full-shield checks.
AddComponentPostInit("wx78_shield", function(self)
    local function IsHurt(inst)
        return inst ~= nil
            and inst.components ~= nil
            and inst.components.health ~= nil
            and inst.components.health:IsHurt()
    end

    function self:UpdateCanShieldCharge()
        self.canshieldcharge = self.updating
            and self.currentshield < self.maxshield
            and not IsHurt(self.inst)
    end
end)
