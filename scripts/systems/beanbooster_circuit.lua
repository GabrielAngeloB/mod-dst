local TUNING = GLOBAL.TUNING


-- Moistened Nutribrick
TUNING.WX78_FOODBRICK_NUTRIENTS = {16, 16, 0}

local defs = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
defs.wx78_foodbrick.nutrients = {16, 16, 0}

----------------BEANBOOSTER CIRCUIT CHANGES: START-------------
-- BEANBOOSTER CIRCUIT: allow charging during combat but blocked if HP is not full + Now regenerate shield faster
----------------------------------------------------------------
TUNING.BEE_SHIELD_REGEN_PER_SECOND = 0.5
AddComponentPostInit("wx78_shield", function (self)
    local function IsHurt(inst)
        return inst.components.health and inst.components.health:IsHurt() or false
    end

    function self:UpdateCanShieldCharge()
        self.canshieldcharge = self.updating and self.currentshield < self.maxshield and not IsHurt(self.inst)
    end
end)
------------------BEANBOOSTER CIRCUIT CHANGES: END-------------