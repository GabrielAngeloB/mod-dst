--------------------------------------------------------------------------
-- CIRCUIT RESONANCE - HUD PANEL (client)
--
-- Small panel that lists the active resonances and their effects. It reads
-- the bitmask replicated by the server (owner._wx_resonance_mask) and only
-- rebuilds its texts when that mask changes. Hidden when nothing is active.
--
-- If it overlaps another HUD element in your setup, tweak the layout
-- constants below, or disable it with the "Resonance HUD" mod option.
--------------------------------------------------------------------------

local Widget = require("widgets/widget")
local Text = require("widgets/text")
local GLOBAL = GLOBAL or _G
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

-- Layout (screen units, anchored to the top-left corner of the screen)
local OFFSET_X = 110
local OFFSET_Y = -40
local WIDTH = 300

local TITLE_SIZE = 16
local NAME_SIZE = 20
local DESC_SIZE = 16

local TITLE_H = 22
local NAME_H = 22
local DESC_LINE_H = 18
local ENTRY_GAP = 8

local COLOUR_TITLE = { 0.7, 0.7, 0.7, 0.85 }
local COLOUR_NAME = { 0.45, 0.85, 1, 1 }
local COLOUR_DESC = { 0.88, 0.88, 0.88, 0.95 }

-- Rough number of text lines the description will wrap into (no font metrics
-- are available here): CJK glyphs are about twice as wide as latin ones.
local function EstimateLines(str)
    local is_cjk = str:find("[\227-\233]") ~= nil
    local chars = is_cjk and math.ceil(#str / 3) or #str
    local per_line = is_cjk and 17 or 42
    return math.max(1, math.min(3, math.ceil(chars / per_line)))
end

local function SetupText(text, height)
    text:SetHAlign(ANCHOR_LEFT)
    text:SetVAlign(ANCHOR_TOP)
    text:SetRegionSize(WIDTH, height)
    text:EnableWordWrap(true)
end

local WXResonancePanel = Class(Widget, function(self, owner)
    Widget._ctor(self, "WXResonancePanel")

    self.owner = owner
    self.shown_mask = nil
    self.entries = {}

    self:SetHAnchor(ANCHOR_LEFT)
    self:SetVAnchor(ANCHOR_TOP)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetPosition(OFFSET_X, OFFSET_Y, 0)

    self.title = self:AddChild(Text(NEWFONT_OUTLINE, TITLE_SIZE, "", COLOUR_TITLE))
    SetupText(self.title, TITLE_H)

    self:Hide()
    self:StartUpdating()
end)

function WXResonancePanel:GetEntry(res)
    local entry = self.entries[res.id]
    if entry == nil then
        entry = {
            name = self:AddChild(Text(NEWFONT_OUTLINE, NAME_SIZE, "", COLOUR_NAME)),
            desc = self:AddChild(Text(NEWFONT_OUTLINE, DESC_SIZE, "", COLOUR_DESC)),
        }
        SetupText(entry.name, NAME_H)
        SetupText(entry.desc, DESC_LINE_H)
        entry.name:Hide()
        entry.desc:Hide()
        self.entries[res.id] = entry
    end
    return entry
end

-- Places a left-aligned text so its top edge sits `top` units below the panel origin.
local function PlaceText(text, top, height)
    text:SetRegionSize(WIDTH, height)
    text:SetPosition(WIDTH / 2, -(top + height / 2), 0)
end

function WXResonancePanel:Refresh(mask)
    local strings = Defs.GetStrings()
    local top = 0
    local any = false

    self.title:SetString(strings.TITLE or "")
    PlaceText(self.title, top, TITLE_H)
    top = top + TITLE_H

    for _, res in ipairs(Defs.RESONANCES) do
        local entry = self:GetEntry(res)

        if Defs.IsInMask(mask, res) then
            any = true

            local desc = Defs.GetText(res, "SHORT")
            local desc_h = EstimateLines(desc) * DESC_LINE_H

            entry.name:SetString(Defs.GetText(res, "NAME"))
            PlaceText(entry.name, top, NAME_H)
            top = top + NAME_H

            entry.desc:SetString(desc)
            PlaceText(entry.desc, top, desc_h)
            top = top + desc_h + ENTRY_GAP

            entry.name:Show()
            entry.desc:Show()
        else
            entry.name:Hide()
            entry.desc:Hide()
        end
    end

    if any then
        self:Show()
    else
        self:Hide()
    end
end

function WXResonancePanel:OnUpdate(dt)
    local netvar = self.owner ~= nil and self.owner._wx_resonance_mask or nil
    local mask = netvar ~= nil and netvar:value() or 0

    if mask ~= self.shown_mask then
        self.shown_mask = mask

        local ok, err = ProtectedCall(self.Refresh, self, mask)
        if not ok then
            -- Stop updating instead of erroring every frame.
            print("[WX-78 Resonance] HUD panel stopped: " .. ErrorString(err))
            self:Hide()
            self:StopUpdating()
        end
    end
end

return WXResonancePanel
