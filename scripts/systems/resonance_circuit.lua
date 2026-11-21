--------------------------------------------------------------------------
-- CIRCUIT RESONANCE - ENGINE
--
-- Special bonuses that appear when two specific circuits are online at the
-- same time. This file only decides WHEN a resonance is active; WHAT it does
-- lives in resonance/wx_resonance_effects.lua and WHICH pairs exist (plus
-- their numbers) in resonance/wx_resonance_defs.lua.
--
-- A circuit is "online" when: a module of its family is plugged in and
-- activated (HasActiveModule), WX-78 has charge (HasCharge) and the skill that
-- unlocks the circuit's effect in this mod is owned (HasSkill) - exactly the
-- same helpers/gating the individual circuits use (see helpers.lua).
--
-- Each resonance is a boolean: it is either active or not, so it can never
-- stack with itself (several modules of one family still count once).
--
-- Multiplayer: everything is per-player and server-authoritative. Clients only
-- receive a tiny bitmask (net var) used to draw the HUD panel.
--------------------------------------------------------------------------

local GLOBAL = GLOBAL
local global_pcall = GLOBAL.pcall
local global_tostring = GLOBAL.tostring
local Defs = require("resonance/wx_resonance_defs")

local function ProtectedCall(fn, ...)
    if type(global_pcall) == "function" then
        return global_pcall(fn, ...)
    end
    return true, fn(...)
end

local function ErrorString(err)
    if type(err) == "string" then
        return err
    end
    return type(global_tostring) == "function"
        and global_tostring(err) or "<unavailable error details>"
end

local EVAL_PERIOD = 0.5          -- seconds between requirement checks (same cadence as other circuits)
local QUIET_AFTER_SPAWN = 5      -- no speech right after spawning/loading (modules are still powering up)
local SPEECH_DEBOUNCE = 3        -- minimum seconds between two messages about the same resonance
local TRIGGER_DEBOUNCE = 4       -- same, for the shout of an elite effect firing

local RESONANCE_BY_ID = {}
for _, res in ipairs(Defs.RESONANCES) do
    RESONANCE_BY_ID[res.id] = res
end

local function IsConfigEnabled(name)
    return GetModConfigData(name) ~= false
end

-- Only resonances whose two circuits are enabled in the mod options.
local AVAILABLE = Defs.GetAvailable(IsConfigEnabled)
if #AVAILABLE == 0 then
    return
end

--------------------------------------------------------------------------
-- SCRAPBOOK: append the resonances to the entry of every involved circuit
-- (additive; runtime-only, no existing string file is edited for this).
--------------------------------------------------------------------------
local function AppendScrapbook()
    local specialinfo = GLOBAL.STRINGS ~= nil and GLOBAL.STRINGS.SCRAPBOOK ~= nil
        and GLOBAL.STRINGS.SCRAPBOOK.SPECIALINFO or nil
    if specialinfo == nil then
        return
    end

    local S = Defs.GetStrings()
    if S.SCRAPBOOK_HEADER == nil or S.SCRAPBOOK_LINE == nil then
        return
    end

    local lines_by_module = {}
    for _, res in ipairs(AVAILABLE) do
        for i = 1, 2 do
            local own = res.circuits[i]
            local partner = res.circuits[3 - i]
            local line = string.format(
                S.SCRAPBOOK_LINE,
                Defs.GetText(res, "NAME"),
                Defs.GetCircuitName(partner),
                Defs.GetText(res, "SHORT") -- keep scrapbook pages readable
            )

            for _, module_name in ipairs(Defs.CIRCUITS[own].modules) do
                lines_by_module[module_name] = lines_by_module[module_name] or {}
                table.insert(lines_by_module[module_name], line)
            end
        end
    end

    for module_name, lines in pairs(lines_by_module) do
        local key = "WX78MODULE_" .. string.upper(module_name)
        if type(specialinfo[key]) == "string" then
            specialinfo[key] = specialinfo[key] .. "\n\n" .. S.SCRAPBOOK_HEADER .. "\n" .. table.concat(lines, "\n")
        end
    end
end

local scrapbook_ok, scrapbook_err = ProtectedCall(AppendScrapbook)
if not scrapbook_ok then
    print("[WX-78 Resonance] Scrapbook update failed: " .. ErrorString(scrapbook_err))
end

--------------------------------------------------------------------------
-- SERVER LOGIC
--------------------------------------------------------------------------
local Effects = nil

local function IsAlive(inst)
    return inst:IsValid()
        and not inst:HasTag("playerghost")
        and not (inst.components.health ~= nil and inst.components.health:IsDead())
end

local function IsCircuitOnline(inst, circuit)
    if circuit.skill ~= nil and not HasSkill(inst, circuit.skill) then
        return false
    end

    for _, module_name in ipairs(circuit.modules) do
        if HasActiveModule(inst, module_name) then
            return true
        end
    end

    return false
end

-- Returns { [resonance id] = true } for every resonance whose requirements are met right now.
local function Evaluate(inst)
    local wanted = {}

    if not IsAlive(inst) or not HasCharge(inst) then
        return wanted
    end

    local online = {}
    local function Online(key)
        local value = online[key]
        if value == nil then
            value = IsCircuitOnline(inst, Defs.CIRCUITS[key])
            online[key] = value
        end
        return value
    end

    for _, res in ipairs(AVAILABLE) do
        if Online(res.circuits[1]) and Online(res.circuits[2]) then
            wanted[res.id] = true
        end
    end

    return wanted
end

local function Announce(inst, res, active)
    local talker = inst.components.talker
    if talker == nil then
        return
    end

    local now = GLOBAL.GetTime()
    if now < inst._wx_resonance_quiet_until then
        return
    end

    local last = inst._wx_resonance_spoke[res.id]
    if last ~= nil and now - last < SPEECH_DEBOUNCE then
        return
    end
    inst._wx_resonance_spoke[res.id] = now

    local S = Defs.GetStrings()
    local template = active and S.SPEECH_ON or S.SPEECH_OFF
    if template ~= nil then
        talker:Say(string.format(template, Defs.GetText(res, "NAME")))
    end
end


-- Called by elite effects the moment they fire.
local function Trigger(inst, id)
    local res = RESONANCE_BY_ID[id]
    local talker = inst.components.talker
    if res == nil or talker == nil then return end

    local now = GLOBAL.GetTime()
    local last = inst._wx_resonance_triggered[id]
    if last ~= nil and now - last < TRIGGER_DEBOUNCE then return end
    inst._wx_resonance_triggered[id] = now

    local S = Defs.GetStrings()
    if S.SPEECH_TRIGGER ~= nil then
        talker:Say(string.format(S.SPEECH_TRIGGER, Defs.GetText(res, "NAME")))
    end
end

-- Bitmask of active resonances that are ready to act. Effects without a
-- cooldown or arming state are considered ready.
local function ComputeReadyMask(inst)
    local ready = {}
    for id in pairs(inst._wx_resonances) do
        local effect = Effects[id]
        local is_ready = true
        if effect ~= nil and effect.ready ~= nil then
            local ok, value = ProtectedCall(effect.ready, inst)
            is_ready = not ok or value == true
        end
        if is_ready then ready[id] = true end
    end
    return Defs.EncodeMask(ready)
end

local function SafeCall(fn, inst, res, action)
    local ok, err = ProtectedCall(fn, inst)
    if not ok then
        print("[WX-78 Resonance] error while trying to " .. action .. " '" .. res.id .. "': " .. ErrorString(err))
    end
end

local function Refresh(inst)
    if not inst:IsValid() then
        return
    end

    local wanted = Evaluate(inst)
    local silent = not IsAlive(inst)
    local changed = false

    for _, res in ipairs(AVAILABLE) do
        local want = wanted[res.id] == true
        local has = inst._wx_resonances[res.id] == true
        local effect = Effects[res.id]

        if has and not want then
            inst._wx_resonances[res.id] = nil
            changed = true
            if effect ~= nil then
                SafeCall(effect.disable, inst, res, "disable")
            end
            if not silent then
                Announce(inst, res, false)
            end
        elseif want and not has then
            inst._wx_resonances[res.id] = true
            changed = true
            if effect ~= nil then
                SafeCall(effect.enable, inst, res, "enable")
            end
            Announce(inst, res, true)
        end
    end

    if changed then
        inst._wx_resonance_mask:set(Defs.EncodeMask(inst._wx_resonances))
    end

    local ready_mask = ComputeReadyMask(inst)
    if ready_mask ~= inst._wx_resonance_ready:value() then
        inst._wx_resonance_ready:set(ready_mask)
    end
end

local function InitServer(inst)
    if Effects == nil then
        Effects = require("resonance/wx_resonance_effects")
        Effects.SetServices({
            GetActiveModuleCount = GetActiveModuleCount,
            Trigger = Trigger,
        })
    end

    inst._wx_resonances = {}
    inst._wx_resonance_spoke = {}
    inst._wx_resonance_triggered = {}
    inst._wx_resonance_quiet_until = GLOBAL.GetTime() + QUIET_AFTER_SPAWN

    inst:DoPeriodicTask(EVAL_PERIOD, Refresh)
    inst:ListenForEvent("death", Refresh)
    inst:ListenForEvent("energylevelupdate", Refresh)
end

--------------------------------------------------------------------------
-- WX-78 HOOK (server + clients: the net var must exist on both sides)
--------------------------------------------------------------------------
AddPrefabPostInit("wx78", function(inst)
    inst._wx_resonance_mask = GLOBAL.net_ushortint(inst.GUID, "wx78_resonance.mask", "wx78_resonance_dirty")
    inst._wx_resonance_ready = GLOBAL.net_ushortint(inst.GUID, "wx78_resonance.ready", "wx78_resonance_ready_dirty")

    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    InitServer(inst)
end)

--------------------------------------------------------------------------
-- HUD (clients): panel listing the active resonances and their effects
--------------------------------------------------------------------------
if GetModConfigData("resonance_hud") ~= false then
    AddClassPostConstruct("widgets/controls", function(self)
        if self.owner == nil or self.owner.prefab ~= "wx78" then
            return
        end

        -- A UI problem must never take the HUD (or the game) down: worst case the panel is skipped.
        local ok, err = ProtectedCall(function()
            local ResonancePanel = require("widgets/wx_resonance_panel")
            self.wx_resonance_panel = self:AddChild(ResonancePanel(self.owner))
        end)
        if not ok then
            print("[WX-78 Resonance] HUD panel disabled: " .. ErrorString(err))
        end
    end)
end
