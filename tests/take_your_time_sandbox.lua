-- Regression test for the restricted environment used by DST modmain.lua.
-- Run from the repository root with Lua 5.1.

local function run_mod(config)
    local tuning = {}
    local messages = {}

    local dst_globals = {
        TUNING = tuning,
        tonumber = tonumber,
        type = type,
        ipairs = ipairs,
        pairs = pairs,
        string = string,
        print = function(...)
            messages[#messages + 1] = { ... }
        end,
    }

    local mod_environment = {
        GLOBAL = dst_globals,
        GetModConfigData = function(name)
            return config[name]
        end,
    }

    setmetatable(mod_environment, {
        __index = function(_, name)
            error("Unexpected bare global in restricted mod environment: " .. tostring(name), 2)
        end,
    })

    local chunk, load_error = loadfile("take_your_time/modmain.lua")
    assert(chunk, load_error)
    setfenv(chunk, mod_environment)

    local ok, run_error = pcall(chunk)
    assert(ok, run_error)

    return tuning, messages
end

local default_config = {
    xspeed = "0",
    dspeed = "21",
    hspeed = "21",
    fspeed = "21",
    rspeed = "21",
    ispeed = "21",
    sspeed = "21",
    pspeed = "21",
    mspeed = "21",
    nspeed = "21",
    asfreq = "0",
}

local tuning, messages = run_mod(default_config)

assert(math.abs(tuning.SEG_TIME - 78.75) < 0.000001, "day segment duration should follow dspeed")
assert(math.abs(tuning.TOTAL_DAY_TIME - 1260) < 0.000001, "full day should last 21 minutes")
assert(math.abs(tuning.WILSON_HUNGER_RATE - (75 / (60 * 21))) < 0.000001, "hunger rate should follow hspeed")
assert(tuning.AUTOSAVE_INTERVAL == 480, "default autosave interval should remain 480 seconds")
assert(#messages == 1, "mod should emit one successful-load message")

local master_config = {
    xspeed = "30",
    asfreq = "1/8",
}

local master_tuning = run_mod(master_config)
assert(math.abs(master_tuning.TOTAL_DAY_TIME - 1800) < 0.000001, "master speed should override day duration")
assert(math.abs(master_tuning.WILSON_HUNGER_RATE - (75 / (60 * 30))) < 0.000001, "master speed should override hunger")
assert(master_tuning.AUTOSAVE_INTERVAL == 225, "1/8-day autosave should scale with the configured day")

print("Take Your Time restricted-environment regression tests passed.")
