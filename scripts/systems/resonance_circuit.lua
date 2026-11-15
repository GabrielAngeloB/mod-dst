--------------------------------------------------------------------------
-- CIRCUIT RESONANCE - ENGINE
--------------------------------------------------------------------------
local GLOBAL = GLOBAL
local Defs = require("resonance/wx_resonance_defs")
local Effects = require("resonance/wx_resonance_effects")

local EVAL_PERIOD = 0.5
local QUIET_AFTER_SPAWN = 5
local SPEECH_DEBOUNCE = 3

local function IsConfigEnabled(name)
    return GetModConfigData(name) ~= false
end

local AVAILABLE = Defs.GetAvailable(IsConfigEnabled)
if #AVAILABLE == 0 then
    return
end

local function AppendScrapbook()
    local specialinfo = GLOBAL.STRINGS ~= nil
        and GLOBAL.STRINGS.SCRAPBOOK ~= nil
        and GLOBAL.STRINGS.SCRAPBOOK.SPECIALINFO or nil
    if specialinfo == nil then
        return
    end

    local strings = Defs.GetStrings()
    if strings.SCRAPBOOK_HEADER == nil or strings.SCRAPBOOK_LINE == nil then
        return
    end

    local lines_by_module = {}
    for _, res in ipairs(AVAILABLE) do
        for i = 1, 2 do
            local own = res.circuits[i]
            local partner = res.circuits[3 - i]
            local line = GLOBAL.string.format(
                strings.SCRAPBOOK_LINE,
                Defs.GetText(res, "NAME"),
                Defs.GetCircuitName(partner),
                Defs.GetText(res, "DESC")
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
            specialinfo[key] = specialinfo[key] .. "\n\n"
                .. strings.SCRAPBOOK_HEADER .. "\n"
                .. table.concat(lines, "\n")
        end
    end
end

AppendScrapbook()

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

local function Evaluate(inst)
    local wanted = {}

    if not IsAlive(inst) or not HasCharge(inst) then
        return wanted
    end

    local online = {}
    local function IsOnline(key)
        if online[key] == nil then
            online[key] = IsCircuitOnline(inst, Defs.CIRCUITS[key])
        end
        return online[key]
    end

    for _, res in ipairs(AVAILABLE) do
        if IsOnline(res.circuits[1]) and IsOnline(res.circuits[2]) then
            wanted[res.id] = true
        end
    end

    return wanted
end

local function Announce(inst, res, active)
    local talker = inst.components.talker
    if talker == nil or GLOBAL.GetTime() < inst._wx_resonance_quiet_until then
        return
    end

    local now = GLOBAL.GetTime()
    local last = inst._wx_resonance_spoke[res.id]
    if last ~= nil and now - last < SPEECH_DEBOUNCE then
        return
    end
    inst._wx_resonance_spoke[res.id] = now

    local strings = Defs.GetStrings()
    local template = active and strings.SPEECH_ON or strings.SPEECH_OFF
    if template ~= nil then
        talker:Say(GLOBAL.string.format(template, Defs.GetText(res, "NAME")))
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

            if effect ~= nil and effect.disable ~= nil then
                effect.disable(inst)
            end
            if not silent then
                Announce(inst, res, false)
            end
        elseif want and not has then
            inst._wx_resonances[res.id] = true
            changed = true

            if effect ~= nil and effect.enable ~= nil then
                effect.enable(inst)
            end
            Announce(inst, res, true)
        end
    end

    if changed and inst._wx_resonance_mask ~= nil then
        inst._wx_resonance_mask:set(Defs.EncodeMask(inst._wx_resonances))
    end
end

local function InitServer(inst)
    inst._wx_resonances = {}
    inst._wx_resonance_spoke = {}
    inst._wx_resonance_quiet_until = GLOBAL.GetTime() + QUIET_AFTER_SPAWN

    inst:DoPeriodicTask(EVAL_PERIOD, Refresh)
    inst:ListenForEvent("death", Refresh)
end

AddPrefabPostInit("wx78", function(inst)
    inst._wx_resonance_mask = GLOBAL.net_ushortint(
        inst.GUID, "wx78_resonance.mask", "wx78_resonance_dirty"
    )

    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    InitServer(inst)
end)

if GetModConfigData("resonance_hud") ~= false then
    AddClassPostConstruct("widgets/controls", function(self)
        if self.owner == nil or self.owner.prefab ~= "wx78" then
            return
        end

        local ResonancePanel = require("widgets/wx_resonance_panel")
        self.wx_resonance_panel = self:AddChild(ResonancePanel(self.owner))
    end)
end
