name = "Take Your Time"
description = "Configure the length of the day and the pace of hunger, fire, growth, insulation, spoilage, equipment decay, monster timers and sanity."
author = "wlayton27/Sirus — DST compatibility update"
version = "2.0.4"
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = true
client_only_mod = false
restart_required = false

icon_atlas = "dayspeed.xml"
icon = "dayspeed.tex"
forumthread = ""

-- modinfo.lua runs in a restricted environment where standard globals such as tostring/table may be absent.
local number_text = {
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99"
}

local function NumberOptions(minimum, maximum, suffix)
    local options = {}
    for value = minimum, maximum do
        local label = number_text[value]
        if suffix ~= nil then
            label = label .. suffix
        end
        options[#options + 1] = {
            description = label,
            data = number_text[value],
        }
    end
    return options
end

local master_options = {
    { description = "Disabled — use individual settings", data = "0" },
}
for value = 3, 99 do
    master_options[#master_options + 1] = {
        description = number_text[value] .. " minutes/day — override all categories",
        data = number_text[value],
    }
end

configuration_options = {
    {
        name = "xspeed",
        label = "Master Speed Control",
        hover = "Disabled lets each category use its own setting. Any enabled value overrides all category settings.",
        options = master_options,

        default = "0",
    },
    {
        name = "dspeed",
        label = "Day Length (Minutes per Full Cycle)",
        options = NumberOptions(1, 99, " min/day"),
        default = "21",
    },
    {
        name = "hspeed",
        label = "Hunger Rate (Minutes per 75 Hunger)",
        options = NumberOptions(1, 99, " min"),
        default = "21",
    },
    {
        name = "fspeed",
        label = "Fire and Fuel Duration",
        options = NumberOptions(1, 99, " min"),
        default = "21",
    },
    {
        name = "rspeed",
        label = "Growth, Regrowth, Cooking and Drying",
        options = NumberOptions(1, 99, " min"),
        default = "21",
    },
    {
        name = "ispeed",
        label = "Insulation Duration",
        options = NumberOptions(1, 99, " min"),
        default = "21",
    },
    {
        name = "sspeed",
        label = "Food and Organic Spoilage",
        options = NumberOptions(1, 99, " min"),
        default = "21",
    },
    {
        name = "pspeed",
        label = "Equipment and Clothing Perish Rate",
        options = NumberOptions(1, 99, " min"),
        default = "21",
    },
    {
        name = "mspeed",
        label = "Creature, Monster and Spawn Timers",
        options = NumberOptions(1, 99, " min"),
        default = "21",
    },
    {
        name = "nspeed",
        label = "Sanity Drain and Gain Rate",
        options = NumberOptions(1, 99, " min"),
        default = "21",
    },
    {
        name = "asfreq",
        label = "Autosave Frequency",
        options = {
            { description = "8 Minutes", data = "0" },
            { description = "Frequent (1/8 day)", data = "1/8" },
            { description = "Often (1/3 day)", data = "1/3" },
            { description = "Daily", data = "1" },
            { description = "Every 5 Days", data = "5" },
            { description = "Every 20 Days", data = "20" },
            { description = "Every 60 Days", data = "60" },
        },
        default = "0",
    },
}
