-- Take Your Time — DST compatibility update.
-- TUNING values are adjusted before the world and its components are created.
-- A full in-game restart is required after changing these options.

-- DST runs modmain.lua in a restricted environment. Standard Lua functions
-- must be obtained through GLOBAL instead of assumed to exist as bare globals.
local GLOBAL = GLOBAL
local tonumber = GLOBAL.tonumber
local type = GLOBAL.type
local ipairs = GLOBAL.ipairs
local pairs = GLOBAL.pairs
local string = GLOBAL.string
local print = GLOBAL.print
local TUNING = GLOBAL.TUNING

local DEFAULT_DAY_MINUTES = 8
local DEFAULT_SEGMENT_SECONDS = 30
local DEFAULT_CATEGORY_MINUTES = 21

local function ReadNumberConfig(name, default, minimum, maximum)
    local value = tonumber(GetModConfigData(name))
    if value == nil then
        value = default
    end

    if value < minimum then
        value = minimum
    elseif value > maximum then
        value = maximum
    end

    return value
end

local master_minutes = ReadNumberConfig("xspeed", 0, 0, 99)

local function GetMinutes(option_name)
    if master_minutes > 0 then
        return master_minutes
    end

    return ReadNumberConfig(option_name, DEFAULT_CATEGORY_MINUTES, 1, 99)
end

local minutes = {
    day = GetMinutes("dspeed"),
    hunger = GetMinutes("hspeed"),
    fire = GetMinutes("fspeed"),
    growth = GetMinutes("rspeed"),
    insulation = GetMinutes("ispeed"),
    spoilage = GetMinutes("sspeed"),
    equipment = GetMinutes("pspeed"),
    creatures = GetMinutes("mspeed"),
    sanity = GetMinutes("nspeed"),
}

local function ScaleNumber(key, factor)
    local value = TUNING[key]
    if type(value) == "number" then
        TUNING[key] = value * factor
    end
end

local function ScaleNumbers(keys, factor)
    for _, key in ipairs(keys) do
        ScaleNumber(key, factor)
    end
end

local function ScaleNestedNumbers(value, factor)
    if type(value) ~= "table" then
        return
    end

    for key, child in pairs(value) do
        if type(child) == "number" then
            value[key] = child * factor
        elseif type(child) == "table" then
            ScaleNestedNumbers(child, factor)
        end
    end
end

local function ScaleTable(key, factor)
    ScaleNestedNumbers(TUNING[key], factor)
end

-- Some newer tuning groups mix durations with non-time values. Scale only
-- explicitly identified nested timer fields instead of touching the whole table.
local function ScalePath(path, factor)
    local parent = TUNING
    for index = 1, #path - 1 do
        if type(parent) ~= "table" then
            return
        end
        parent = parent[path[index]]
    end

    if type(parent) == "table" then
        local key = path[#path]
        if type(parent[key]) == "number" then
            parent[key] = parent[key] * factor
        end
    end
end

local function ScalePaths(paths, factor)
    for _, path in ipairs(paths) do
        ScalePath(path, factor)
    end
end

local function ScaleRate(key, factor)
    -- These constants describe a rate (per second), so a longer configured
    -- duration means a smaller rate.
    if factor > 0 then
        ScaleNumber(key, 1 / factor)
    end
end

local function ScaleRates(keys, factor)
    for _, key in ipairs(keys) do
        ScaleRate(key, factor)
    end
end

local function Ratio(category)
    return minutes[category] / DEFAULT_DAY_MINUTES
end

-- World clock. DST's clock component reads SEG_TIME and the default segment
-- counts when it is constructed. A full cycle always contains 16 segments.
local day_scale = Ratio("day")
local segment_time = DEFAULT_SEGMENT_SECONDS * day_scale
local total_day_time = segment_time * 16
local day_time = segment_time * 10
local dusk_time = segment_time * 4
local night_time = segment_time * 2

TUNING.SEG_TIME = segment_time
TUNING.TOTAL_DAY_TIME = total_day_time
TUNING.DAY_SEGS_DEFAULT = 10
TUNING.DUSK_SEGS_DEFAULT = 4
TUNING.NIGHT_SEGS_DEFAULT = 2
TUNING.DAY_TIME_DEFAULT = day_time
TUNING.DUSK_TIME_DEFAULT = dusk_time
TUNING.NIGHT_TIME_DEFAULT = night_time
TUNING.DEMO_TIME = total_day_time * 2 + day_time * 0.2
TUNING.ITEM_DROP_TIME = segment_time

-- Smaller world-clock-driven timers that were part of the original mod.
ScaleNumbers({
    "MIN_LEAF_CHANGE_TIME", "MAX_LEAF_CHANGE_TIME",
    "MIN_SWAY_FX_FREQUENCY", "MAX_SWAY_FX_FREQUENCY", "SWAY_FX_FREQUENCY",
    "MIN_RABBIT_HOLE_TRANSITION_TIME", "MAX_RABBIT_HOLE_TRANSITION_TIME",
}, day_scale)

-- Autosave intervals are expressed in simulation seconds.
local autosave_choice = GetModConfigData("asfreq")
if autosave_choice == "1/8" then
    TUNING.AUTOSAVE_INTERVAL = total_day_time / 8
elseif autosave_choice == "1/3" then
    TUNING.AUTOSAVE_INTERVAL = total_day_time / 3
elseif autosave_choice == "1" then
    TUNING.AUTOSAVE_INTERVAL = total_day_time
elseif autosave_choice == "5" then
    TUNING.AUTOSAVE_INTERVAL = total_day_time * 5
elseif autosave_choice == "20" then
    TUNING.AUTOSAVE_INTERVAL = total_day_time * 20
elseif autosave_choice == "60" then
    TUNING.AUTOSAVE_INTERVAL = total_day_time * 60
else
    TUNING.AUTOSAVE_INTERVAL = 480
end

-- Hunger: the vanilla tuning value consumes 75 hunger per 8-minute day.
TUNING.WILSON_HUNGER_RATE = 75 / (60 * minutes.hunger)

-- Fire, fuel and light durations. This list includes the Flingomatic fuel
-- capacity, which the old DST branch accidentally left at vanilla duration.
ScaleNumbers({
    "TINY_FUEL", "SMALL_FUEL", "MED_FUEL", "MED_LARGE_FUEL", "LARGE_FUEL", "HUGE_FUEL",
    "TINY_BURNTIME", "SMALL_BURNTIME", "MED_BURNTIME", "LARGE_BURNTIME",
    "TREE_BURN_TIME",
    "CAMPFIRE_FUEL_MAX", "CAMPFIRE_FUEL_START",
    "COLDFIRE_FUEL_MAX", "COLDFIRE_FUEL_START",
    "ROCKLIGHT_FUEL_MAX",
    "FIREPIT_FUEL_MAX", "FIREPIT_FUEL_START",
    "COLDFIREPIT_FUEL_MAX", "COLDFIREPIT_FUEL_START",
    "PIGTORCH_FUEL_MAX", "NIGHTLIGHT_FUEL_MAX", "NIGHTLIGHT_FUEL_START",
    "TORCH_FUEL", "NIGHTSTICK_FUEL", "LIGHTER_FUEL",
    "MINERHAT_LIGHTTIME", "LANTERN_LIGHTTIME",
    "MINIFAN_FUEL", "COMPASS_FUEL",
    "FIRESUPPRESSOR_MAX_FUEL_TIME",
    "WILDFIRE_RETRY_TIME", "MIN_SMOLDER_TIME", "MAX_SMOLDER_TIME",
    "MINIBOATLANTERN_LIGHTTIME", "MAST_LAMP_LIGHTTIME",
    "WINONA_TELEBRELLA_MAX_FUEL_TIME", "WINONA_TELEBRELLA_TELEPORT_FUEL",
    "WINONA_STORAGE_ROBOT_FUEL", "WINONA_REMOTE_FUEL",
    "WINONA_BATTERY_LOW_MAX_FUEL_TIME", "WINONA_BATTERY_HIGH_MAX_FUEL_TIME",
    "BERNIE_FUEL", "BERNIE_DECAY_TIME", "STORAGE_ROBOT_FUEL",
}, Ratio("fire"))

-- Growth, regrowth, farming, mushroom farms, drying and cooking.
ScaleNumbers({
    "SEEDS_GROW_TIME",
    "POOP_FERTILIZE", "GUANO_FERTILIZE", "GLOMMERFUEL_FERTILIZE", "PIG_MIN_POOP_PERIOD",
    "SPOILEDFOOD_FERTILIZE", "TREEGROWTH_FERTILIZE",
    "SOILAMENDER_FERTILIZE_LOW", "SOILAMENDER_FERTILIZE_MED", "SOILAMENDER_FERTILIZE_HIGH",
    "MUSHROOMFARM_FULL_GROW_TIME",
    "GRASS_REGROW_TIME", "SAPLING_REGROW_TIME", "MARSHBUSH_REGROW_TIME",
    "CACTUS_REGROW_TIME", "FLOWER_CAVE_REGROW_TIME", "LICHEN_REGROW_TIME",
    "BERRY_REGROW_TIME", "BERRY_REGROW_INCREASE", "BERRY_REGROW_VARIANCE",
    "BERRY_JUICY_REGROW_TIME", "BERRY_JUICY_REGROW_INCREASE", "BERRY_JUICY_REGROW_VARIANCE",
    "REEDS_REGROW_TIME", "CAVE_BANANA_GROW_TIME",
    "FISH_RESPAWN_TIME", "BEEHIVE_RELEASE_TIME", "BEEHIVE_REGEN_TIME",
    "BEEBOX_RELEASE_TIME", "BEEBOX_HONEY_TIME", "BEEBOX_REGEN_TIME",
    "DRY_SUPERFAST", "DRY_VERYFAST", "DRY_FAST", "DRY_MED", "BASE_COOK_TIME",
    "FLOWER_CAVE_RECHARGE_TIME", "CROP_DARK_WITHER_TIME",
    "MIN_TUMBLEWEED_SPAWN_PERIOD", "MAX_TUMBLEWEED_SPAWN_PERIOD", "TUMBLEWEED_REGEN_PERIOD",
    "LEAFPILE_TIME_TO_GROW", "LEAFPILE_TIME_TO_GROW_VARIANCE",
    "RABBIT_RESPAWN_TIME", "OASISLAKE_FISH_RESPAWN_TIME",
    "COMPOSTWRAP_FERTILIZE", "COMPOSTINGBIN_COMPOSTING_TIME_MIN",
    "COMPOSTINGBIN_COMPOSTING_TIME_MAX", "COMPOST_FERTILIZE",
    "FORGETMELOTS_RESPAWNER_MIN", "FORGETMELOTS_RESPAWNER_VAR",
    "WEED_TILLWEED_DEBRIS_TIME_MIN", "WEED_TILLWEED_DEBRIS_TIME_VAR",
    "FARM_PLOW_DRILLING_DURATION", "WORMWOOD_FERTILIZER_BLOOM_TIME_MOD",
    "WORMWOOD_BLOOM_STAGE_DURATION", "WORMWOOD_BLOOM_FULL_DURATION",
    "WORMWOOD_BLOOM_FULL_MAX_DURATION", "WORMWOOD_BLOOM_PLANTS_WARNING_TIME_LOW",
    "WORMWOOD_BLOOM_PLANTS_WARNING_TIME_MED",
    "LIGHTFLIER_FLOWER_REGROW_TIME", "LIGHTFLIER_FLOWER_REGROWTH_TIME",
    "MUSHSPORE_DENSITY_CHECK_TIME", "MUSHSPORE_DENSITY_CHECK_VAR",
    "ACIDRAIN_MUSHTREE_PHASE_TIME", "ANCIENTFRUIT_GEM_HATCH_TIME",
}, Ratio("growth"))
ScaleTable("EVERGREEN_GROW_TIME", Ratio("growth"))
ScaleTable("PINECONE_GROWTIME", Ratio("growth"))
ScaleTable("DECIDUOUS_GROW_TIME", Ratio("growth"))
ScaleTable("ACORN_GROWTIME", Ratio("growth"))
ScaleTable("BABYBEEFALO_GROW_TIME", Ratio("growth"))
ScaleTable("MARBLESHRUB_GROW_TIME", Ratio("growth"))
ScaleTable("TWIGGY_TREE_GROW_TIME", Ratio("growth"))
ScaleTable("ANCIENTTREE_GROW_TIME", Ratio("growth"))
ScalePaths({
    { "WATERPLANT", "GROW_TIME" },
    { "WATERPLANT", "GROW_VARIANCE" },
    { "WATERPLANT", "REBIRTH_TIME" },
    { "WATERPLANT", "POLLEN_RESETTIME" },
    { "WATERPLANT", "PINK_POLLEN_RESETTIME" },
    { "WATERPLANT", "POLLEN_RESETVARIANCE" },
    { "LIGHTFLIER_FLOWER", "REGROW_TIME" },
    { "LIGHTFLIER_FLOWER", "REGROWTH", "TIME" },
    { "CARRAT_GYM", "TRAINING_TIME" },
}, Ratio("growth"))

-- Insulation values are documented by DST as additional time before freezing.
ScaleNumbers({
    "INSULATION_TINY", "INSULATION_SMALL", "INSULATION_MED",
    "INSULATION_MED_LARGE", "INSULATION_LARGE", "INSULATION_PER_BEARD_BIT",
    "CAVE_INSULATION_BONUS", "DUSK_INSULATION_BONUS", "NIGHT_INSULATION_BONUS",
    "SMALLBIRD_HATCH_FAIL_TIME",
}, Ratio("insulation"))

-- Food and organic spoilage. Keeping this list separate from equipment decay
-- means Crock Pot foods and fresh ingredients follow the spoilage setting.
ScaleNumbers({
    "PERISH_ONE_DAY", "PERISH_TWO_DAY", "PERISH_SUPERFAST", "PERISH_FAST",
    "PERISH_FASTISH", "PERISH_MED", "PERISH_SLOW", "PERISH_PRESERVED", "PERISH_SUPERSLOW",
    "BIRD_PERISH_TIME", "BUTTERFLY_PERISH_TIME", "MOONBUTTERFLY_PERISH_TIME", "RABBIT_PERISH_TIME",
    "MUSHSPORE_PERISH_TIME", "MOONSPORE_PERISH_TIME",
}, Ratio("spoilage"))
ScalePath({ "CARRAT", "PERISH_TIME" }, Ratio("spoilage"))

-- Equipment and clothing durability/perish durations.
ScaleNumbers({
    "SPIDERHAT_PERISHTIME", "ONEMANBAND_PERISHTIME",
    "GRASS_UMBRELLA_PERISHTIME", "UMBRELLA_PERISHTIME", "EYEBRELLA_PERISHTIME",
    "STRAWHAT_PERISHTIME", "EARMUFF_PERISHTIME", "WINTERHAT_PERISHTIME",
    "BEEFALOHAT_PERISHTIME", "TRUNKVEST_PERISHTIME", "REFLECTIVEVEST_PERISHTIME",
    "HAWAIIANSHIRT_PERISHTIME", "SWEATERVEST_PERISHTIME", "HUNGERBELT_PERISHTIME",
    "BEARGERVEST_PERISHTIME", "RAINCOAT_PERISHTIME", "WALRUSHAT_PERISHTIME",
    "FEATHERHAT_PERISHTIME", "TOPHAT_PERISHTIME", "ICEHAT_PERISHTIME",
    "MOLEHAT_PERISHTIME", "RAINHAT_PERISHTIME", "CATCOONHAT_PERISHTIME",
    "GOGGLES_PERISHTIME", "NUTRIENTSGOGGLESHAT_PERISHTIME", "WALTERHAT_PERISHTIME",
    "BLUEAMULET_FUEL", "PURPLEAMULET_FUEL", "YELLOWAMULET_FUEL",
    "SEWINGKIT_REPAIR_VALUE", "SEWING_TAPE_REPAIR_VALUE",
    "YELLOWSTAFF_STAR_DURATION", "OPALSTAFF_STAR_DURATION",
    "SCRAP_MONOCLEHAT_PERISHTIME", "MUSHROOMHAT_SPORE_TIME",
    "MUSHROOMHAT_MOONSPORE_TIME", "MUSHROOMHAT_MOONSPORE_TIME_VARIANCE",
    "MUSHROOMHAT_MOONSPORE_RETALIATION_SPORE_DELAY",
    "CURSED_TRINKET_LIFETIME", "ANCIENTTREE_NIGHTVISION_FRUIT_BUFF_DURATION",
    "BOAT_REPAIR_KELP_REPAIR_TIME_SMALL_LEAK", "BOAT_REPAIR_KELP_REPAIR_TIME_MED_LEAK",
}, Ratio("equipment"))

-- Creature timers, natural respawns, loyalty and monster events.
ScaleNumbers({
    "PIG_LOYALTY_MAXTIME", "PIG_LOYALTY_PER_HUNGER",
    "SPIDER_LOYALTY_MAXTIME", "SPIDER_LOYALTY_PER_HUNGER",
    "BEEFALO_MATING_SEASON_BABYDELAY", "BEEFALO_MATING_SEASON_BABYDELAY_VARIANCE",
    "LIGHTNING_GOAT_MATING_SEASON_BABYDELAY", "LIGHTNING_GOAT_MATING_SEASON_BABYDELAY_VARIANCE",
    "RABBIT_CARROT_LOYALTY", "WALRUS_REGEN_PERIOD",
    "PENGUIN_MATING_SEASON_BABYDELAY", "PENGUIN_MATING_SEASON_BABYDELAY_VARIANCE",
    "PENGUIN_HUNGER", "PENGUIN_STARVE_TIME",
    "LUREPLANT_HIBERNATE_TIME", "LUREPLANT_SPAWNTIME", "LUREPLANT_SPAWNTIME_VARIANCE",
    "TEENBIRD_STARVE_TIME", "TEENBIRD_GROW_TIME",
    "SMALLBIRD_STARVE_TIME", "SMALLBIRD_GROW_TIME", "SMALLBIRD_HATCH_TIME",
    "CHESTER_RESPAWN_TIME",
    "SPIDERDEN_REGEN_TIME", "HOUNDMOUND_REGEN_TIME", "HOUNDMOUND_RELEASE_TIME",
    "POND_REGEN_TIME", "POND_SPAWN_TIME", "POND_RETURN_TIME",
    "MIN_SPRING_SMALL_BIRD_SPAWN_TIME", "MAX_SPRING_SMALL_BIRD_SPAWN_TIME",
    "FROG_POND_REGEN_TIME", "FROG_POND_SPAWN_TIME",
    "MOSQUITO_POND_REGEN_TIME", "MOSQUITO_POND_SPAWN_TIME",
    "SPIDERQUEEN_MINWANDERTIME", "HUNT_COOLDOWN", "HUNT_COOLDOWNDEVIATION", "HUNT_SPRING_RESET_TIME",
    "MOLE_RESPAWN_TIME", "ROCKY_SPAWN_DELAY", "ROCKY_LOYALTY",
    "MOOSE_EGG_HATCH_TIMER", "DRAGONFLY_SLEEP_WHEN_SATISFIED_TIME",
    "BEARGER_SLEEP_WHEN_SATISFIED_TIME", "DECID_MONSTER_DURATION",
    "BUTTERFLY_SPAWN_TIME",
    "CATCOONDEN_REGEN_TIME", "CATCOONDEN_RELEASE_TIME", "CATCOON_LOYALTY_MAXTIME",
    "CATCOON_LOYALTY_PER_ITEM", "CATCOON_MIN_HAIRBALL_TIME_FRIENDLY",
    "CATCOON_MAX_HAIRBALL_TIME_FRIENDLY", "CATCOON_MIN_HAIRBALL_TIME_BASE",
    "CATCOON_MAX_HAIRBALL_TIME_BASE", "MIN_HAIRBALL_NEUTRAL_INTERVAL", "MAX_HAIRBALL_NEUTRAL_INTERVAL",
    "ROCKY_BOSS_SPAWNDELAY_BASE", "ROCKY_BOSS_SPAWNDELAY_RANDOM",
    "ROCKY_BOSS_SPAWNDELAY_RETRY_BASE", "ROCKY_BOSS_SPAWNDELAY_RETRY_RANDOM",
    "BATBOSSCAVE_REGEN_PERIOD", "HN_MONSTER_HEALTH_REGEN_PERIOD",
    "BATCAVE_REGEN_PERIOD", "BATCAVE_SPAWN_PERIOD",
    "CAVE_ENTRANCE_BATS_REGEN_PERIOD", "CAVE_ENTRANCE_BATS_SPAWN_PERIOD",
    "BEEQUEEN_RESPAWN_TIME", "DRAGONFLY_RESPAWN_TIME", "TOADSTOOL_RESPAWN_TIME",
    "SHADOWWAXWELL_LIFETIME", "SHADOWWAXWELL_PROTECTOR_DURATION", "SHADOWWAXWELL_WORKER_DURATION",
    "WOBSTER_DEN_REGEN_PERIOD", "WOBSTER_DEN_SPAWN_PERIOD",
    "MERMHOUSE_REGEN_TIME", "MERMHOUSE_RELEASE_TIME",
    "MERMWATCHTOWER_REGEN_TIME", "MERMWATCHTOWER_RELEASE_TIME",
    "MERM_GUARD_LOYALTY_MAXTIME", "MERM_GUARD_LOYALTY_PER_HUNGER",
    "MERM_KING_HUNGER_KILL_TIME",
    "KLAUSSACK_EVENT_RESPAWN_TIME", "KLAUSSACK_RESPAWN_DELAY",
    "KLAUSSACK_SPAWN_DELAY", "KLAUSSACK_SPAWN_DELAY_VARIANCE",
    "BUZZARD_REGEN_PERIOD", "BUZZARD_SPAWN_PERIOD", "BUZZARD_SPAWN_VARIANCE",
    "LORDFRUITFLY_INITIALSPAWN_TIME", "LORDFRUITFLY_RESPAWN_TIME",
    "LORDFRUITFLY_CROP_ROTTED_ADVANCE_TIME",
    "MALBATROSS_SPAWNDELAY_BASE", "MALBATROSS_SPAWNDELAY_RANDOM",
    "DUSTMOTHDEN_REPAIR_TIME", "DUSTMOTHDEN_REGEN_TIME", "DUSTMOTHDEN_RELEASE_TIME",
    "MUSHGNOME_RELEASE_TIME", "MUSHGNOME_REGEN_TIME",
    "NIGHTMARELIGHT_RELEASE_TIME", "NIGHTMARELIGHT_REGEN_TIME",
    "NIGHTMAREFISSURE_RELEASE_TIME", "NIGHTMAREFISSURE_REGEN_TIME",
    "COOKIECUTTER_SPAWNER_REGEN_TIME", "COOKIECUTTER_SPAWNER_RELEASE_TIME",
    "SPIDERDEN_GROW_TIME_QUEEN", "OTTERDEN_REGEN_PERIOD", "OTTERDEN_SPAWN_PERIOD",
    "OTTER_EAT_DELAY", "WATER_TURTLE_MATING_SEASON_BABYDELAY",
    "WATER_TURTLE_MATING_SEASON_BABYDELAY_VARIANCE", "KITCOON_LOYALTY_MAX",
}, Ratio("creatures"))
ScaleTable("SPIDERDEN_GROW_TIME", Ratio("creatures"))
ScalePaths({
    { "WOBSTER", "SURVIVE_TIME" },
    { "WATERPLANT", "FISH_SPAWN", "REGEN_PERIOD" },
    { "WATERPLANT", "FISH_SPAWN", "WHITE_REGEN_PERIOD" },
    { "CARRAT", "EMERGED_TIME_LIMIT" },
    { "DUSTMOTH", "DUSTABLE_RESET_TIME" },
    { "DUSTMOTH", "DUSTABLE_RESET_TIME_VARIANCE" },
    { "ARCHIVE_SECURITY", "REGEN_TIME" },
    { "ARCHIVE_SECURITY", "RELEASE_TIME" },
    { "WAVEYJONES", "RESPAWN_TIMER" },
}, Ratio("creatures"))
ScaleRate("ROCKY_GROW_RATE", Ratio("creatures"))
ScaleRate("ROCKY_ACIDRAIN_SHRINK_RATE", Ratio("creatures"))
ScaleRate("MERM_KING_HUNGER_RATE", Ratio("creatures"))

-- Sanity constants are rates rather than durations: increase the configured
-- minutes to reduce the amount gained/lost per real second.
ScaleRates({
    "SANITY_DAY_GAIN",
    "SANITY_NIGHT_LIGHT", "SANITY_NIGHT_MID", "SANITY_NIGHT_DARK",
    "SANITY_LUNACY_DAY_GAIN", "SANITY_LUNACY_NIGHT_DARK", "SANITY_GHOST_PLAYER_DRAIN",
    "SANITYAURA_TINY", "SANITYAURA_SMALL_TINY", "SANITYAURA_SMALL",
    "SANITYAURA_MED", "SANITYAURA_LARGE", "SANITYAURA_HUGE", "SANITYAURA_SUPERHUGE",
    "DAPPERNESS_TINY", "DAPPERNESS_SMALL", "DAPPERNESS_MED", "DAPPERNESS_MED_LARGE",
    "DAPPERNESS_LARGE", "DAPPERNESS_HUGE", "DAPPERNESS_SUPERHUGE",
    "MOISTURE_SANITY_PENALTY_MAX", "CRAZINESS_TINY", "CRAZINESS_SMALL", "CRAZINESS_MED",
}, Ratio("sanity"))

print(string.format(
    "[Take Your Time 2.0.4] Loaded. Day: %d min; hunger: %d; fire: %d; growth: %d; insulation: %d; spoilage: %d; equipment: %d; creatures: %d; sanity: %d.",
    minutes.day, minutes.hunger, minutes.fire, minutes.growth,
    minutes.insulation, minutes.spoilage, minutes.equipment, minutes.creatures, minutes.sanity
))
