local GLOBAL = GLOBAL
----------------OPTOELECTRONIC CIRCUIT CHANGES: START------------
-------------------------------------------------------
-- Remove Goggles Overlay (ONLY BLOCK WHEN NOT WEARING GOGGLES)
-------------------------------------------------------
AddClassPostConstruct("widgets/gogglesover", function (self)
    local old_ToggleGoggles = self.ToggleGoggles

    local function UpdateState(self)
        local owner = self.owner

        local has_goggles = owner ~= nil
            and owner.replica ~= nil
            and owner.replica.inventory ~= nil
            and owner.replica.inventory:EquipHasTag("goggles")

        if self.bg ~= nil then
            if has_goggles then
                -- restaurar visual
                self.bg:Show()
            else
                self.bg:Hide()
            end
        end
    end

    function self:ToggleGoggles(show)
        old_ToggleGoggles(self, show)
        UpdateState(self)
    end

    -- REACTIVIDAD AL EQUIPAR/DESEQUIPAR GAFAS
    if self.owner ~= nil then
        self.inst:ListenForEvent("equip", function()
            UpdateState(self)
        end, self.owner)

        self.inst:ListenForEvent("unequip", function()
            UpdateState(self)
        end, self.owner)
    end
end)

---------------------------------------------------
-- CONDITION
---------------------------------------------------
local function NightvisionCircuitSkill(wx)
    if wx == nil or not wx:IsValid() then return end

    local playervision = wx.components.playervision

    if playervision == nil then
        return
    end

    local pv = wx.components.playervision
    if pv == nil then return end

    local should_enable = HasSkill(wx, "wx78_circuitry_betabuffs_1") and HasActiveModule(wx, "nightvision")
        and HasCharge(wx)

    if should_enable then
        -- preserve original function once
        if wx._memot_old_HasGoggleVision == nil then
            wx._memot_old_HasGoggleVision = playervision.HasGoggleVision
        end

        -- force goggles vision
        playervision.HasGoggleVision = function (self)
            return true
        end

        -- IMPORTANT:
        -- keep this enabled so storm overlays
        -- are repositioned correctly
        if playervision.ForceGoggleVision ~= nil then
            playervision:ForceGoggleVision(true)
        end

        ---------------------------------------------------
    -- RESTORE ORIGINAL BEHAVIOR
    ---------------------------------------------------
    else
        if wx._memot_old_HasGoggleVision ~= nil then
            playervision.HasGoggleVision = wx._memot_old_HasGoggleVision

            wx._memot_old_HasGoggleVision = nil
        end

        if playervision.ForceGoggleVision ~= nil then
            playervision:ForceGoggleVision(false)
        end
    end
end
----------------OPTOELECTRONIC CIRCUIT CHANGES: END------------
-------------------------------------------------------
-- INIT 
-------------------------------------------------------
AddPrefabPostInit("wx78", function (inst)
    if not GLOBAL.TheWorld.ismastersim then return end

    inst:DoPeriodicTask(0.5, function ()
        NightvisionCircuitSkill(inst)
    end)
end)
