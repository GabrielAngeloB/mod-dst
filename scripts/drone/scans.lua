
---------------------------------------------------
-- Scan creature changes
---------------------------------------------------
---------------------------------------------------
-- Preserve original function
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

    return oldfn(ent_or_id)
end

---------------------------------------------------
-- SCAN DEFINITIONS 
---------------------------------------------------

-- radar
wx78_moduledefs.AddCreatureScanDataDefinition("tallbird", "radar", 2)

-- light2
wx78_moduledefs.AddCreatureScanDataDefinition("lightcrab", "light2", 3)
wx78_moduledefs.AddCreatureScanDataDefinition("hutch", "light2", 3)

-- maxhealth2
wx78_moduledefs.AddCreatureScanDataDefinition("spiderqueen", "maxhealth2", 4)

-- nightvision
wx78_moduledefs.AddCreatureScanDataDefinition("worm", "nightvision", 4)

-- stacksize
wx78_moduledefs.AddCreatureScanDataDefinition("krampus", "stacksize", 8)

-- Spincycle
wx78_moduledefs.AddCreatureScanDataDefinition("mushgnome", "spin", 2)
wx78_moduledefs.AddCreatureScanDataDefinition("squid", "spin", 2)

-- Gastrogain
wx78_moduledefs.AddCreatureScanDataDefinition("buzzard", "maxhunger1", 2)
