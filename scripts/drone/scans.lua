---------------------------------------------------
-- Scan creature changes
---------------------------------------------------

local wx78_moduledefs = require("wx78_moduledefs")
local oldfn = wx78_moduledefs.GetCreatureScanDataDefinition

function wx78_moduledefs.GetCreatureScanDataDefinition(ent_or_id)
    local prefab = type(ent_or_id) == "table" and ent_or_id.prefab or ent_or_id

    if prefab == "spider_healer" then
        return nil, "spider_healer"
    end

    if prefab == "squid" then
        return nil, "squid"
    end

    if type(oldfn) == "function" then
        return oldfn(ent_or_id)
    end

    return nil
end

---------------------------------------------------
-- SCAN DEFINITIONS
---------------------------------------------------

wx78_moduledefs.AddCreatureScanDataDefinition("tallbird", "radar", 2)
wx78_moduledefs.AddCreatureScanDataDefinition("lightcrab", "light2", 3)
wx78_moduledefs.AddCreatureScanDataDefinition("hutch", "light2", 3)
wx78_moduledefs.AddCreatureScanDataDefinition("spiderqueen", "maxhealth2", 4)
wx78_moduledefs.AddCreatureScanDataDefinition("worm", "nightvision", 4)
wx78_moduledefs.AddCreatureScanDataDefinition("krampus", "stacksize", 8)
wx78_moduledefs.AddCreatureScanDataDefinition("mushgnome", "spin", 2)
wx78_moduledefs.AddCreatureScanDataDefinition("squid", "spin", 2)
wx78_moduledefs.AddCreatureScanDataDefinition("buzzard", "maxhunger1", 2)
