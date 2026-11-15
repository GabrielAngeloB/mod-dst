name = "D'WX-78 Improved Circuits"
description = "DST rework and quality-of-life changes for WX-78 circuits.\n" ..
"• Resonance: small bonuses for six active circuit pairs, with an optional HUD.\n" ..
"• Redigestion: reduces negative health, hunger and sanity effects from food.\n" ..
"• Blocking, Hardy, Processing, Chorusbox and other circuit adjustments.\n" ..
"• Drone, scanning, recipes and world-system improvements."

author = "Deurus"
version = "0.1.39"
forumthread = ""

api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

all_clients_require_mod = true
client_only_mod = false
-- This package includes shared simulation logic and client-side HUD code.
-- Disable the stale Workshop manifest so newly added Lua files can be required.
forcemanifest = false
server_filter_tags = {"wx78", "circuit", "improvement"}

icon_atlas = "modicon.xml"
icon = "modicon.tex"



local function Header(title)
    return {
        name = "",
        label = title,
        hover = "",
        options = { { description = "", data = false } },
        default = false
    }
end

local function SkipSpace()
    return {
        name = "",
        label = "",
        hover = "",
        options = { { description = "", data = false } },
        default = false
    }
end

local function BinaryConfig(name, label, hover, default)
    return {
        name = name,
        label = label,
        hover = hover,
        options = {
            { description = "Enable", data = true, hover = "Enabled" },
            { description = "Disable", data = false, hover = "Disabled" }
        },
        default = default
    }
end

-------------------------------------------------------
-- CONFIG OPTIONS
-------------------------------------------------------

configuration_options =
{
    Header("LANGUAGE"),

    {
        name = "language",
        label = "Language",
        hover = "Select mod language",
        options =
        {
            { description = "English", data = "en", hover = "Default language" },
            { description = "Español", data = "es", hover = "Español Neutro" },
            { description = "Português", data = "pt_br", hover = "Português Brasil" },
            { description = "简体中文", data = "zh_cn", hover = "简体中文" },
        },
        default = "en",
    },

    SkipSpace(),

    Header("WORLD SYSTEMS"),

    BinaryConfig("tumbleweed", "Tumbleweed Extra Loot", "Enable/Disable Small chance of Down feathers on tumbleweed loot", true),
    BinaryConfig("recipes", "Recipes System", "Enable/Disable New recipes for Circuits", true),

    SkipSpace(),

    Header("DRONE QoL"),

    BinaryConfig("rotomapper", "Roto-Mapper Drone", "Enable/Disable Drone arrival speech/sound", true),
    BinaryConfig("scans", "Drone Scans", "Enable/Disable New scans", true),

    SkipSpace(),

    Header("SKILL EFFECT CHANGES"),

    BinaryConfig("screech", "Sonic-Invoker Circuit", "Enables/Disables Extra skill effect for Sonic Invoker Circuit", true),
    BinaryConfig("redigestion", "Redigestion Circuit", "Enables/Disables Extra skill effect for Redigestion Circuit", true),
    BinaryConfig("blocking", "Blocking Circuit", "Enables/Disables Extra skill effect + Rework for Blocking  Circuit", true),
    BinaryConfig("hardy", "Hardy Circuit", "Enables/Disables Skill effect Rework for all Hardy Circuits", true),
    BinaryConfig("processing", "Processing Circuit", "Enables/Disables Extra skill effect for all Processing Circuits", true),
    BinaryConfig("beanbooster", "Beanbooster Circuit", "Enables/Disables Shield regeneration Buff for Beanbooster Circuit", true),
    BinaryConfig("chorusbox", "Chorusbox Circuit", "Enables/Disables Extra skill effect + Buff for Chorusbox Circuits", true),
    BinaryConfig("nightvision", "Nightvision Circuit", "Enables/Disables Extra skill effect for Optoelectronic Circuit", true),
    BinaryConfig("rangebooster", "Range Booster", "Enables/Disables Extra skill effect for Rangebooster Circuits", true),
    BinaryConfig("thermal", "Thermal Circuit", "Enables/Disables Extra skill effect for Thermal Circuit", true),
    BinaryConfig("refrigerant", "Refrigerant Circuit", "Enables/Disables Extra skill effect for Refrigerant Circuits", true),
    BinaryConfig("spatializer", "Spatializer Circuit", "Enables/Disables Skill effect for Spatializer Circuit", true),
    BinaryConfig("illumination", "Illumination Circuit", "Enables/Disables Skill effect Rework for all Illumination Circuits", true),
     BinaryConfig("quickplugging", "Right to Modify Skill", "Enables/Disables Recycle+Repair circuits and Plug+Unplug circuits 50% faster.", true),

    SkipSpace(),

    Header("CIRCUIT RESONANCE"),

    BinaryConfig("resonance", "Circuit Resonance", "Enables/Disables the small bonuses gained when specific circuit pairs are active together (needs the circuits' own options enabled).", true),
    BinaryConfig("resonance_hud", "Resonance HUD", "Shows/Hides the on-screen panel listing the active resonances and their effects.", true),

    SkipSpace(),

    Header("OTHER CHANGES"),
}