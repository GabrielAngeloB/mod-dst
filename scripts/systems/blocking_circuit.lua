local GLOBAL = GLOBAL
local TUNING = GLOBAL.TUNING

local tonumber = GLOBAL.tonumber or function(v) return type(v) == "number" and v or 0 end

----------------------------------------------------------------
-- ============================================================
-- 1. SHIELDING CIRCUIT (BLOCKING)
-- ============================================================
----------------------------------------------------------------
TUNING.WX78_SHIELDING_ARMOR = 0
-- Global cooldown tuning is configured once when this option is loaded.
TUNING.WX78_SHIELDING_COOLDOWN = 10

local function IsWXBlocking(inst)
    return inst ~= nil and inst.prefab == "wx78" and inst:HasTag("wx_shielding")
end

AddComponentPostInit("combat", function(self)
    local _old = self.GetAttacked

    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        local inst = self.inst

        if IsWXBlocking(inst) then
            local real_damage = tonumber(damage) or 0

            if inst.SoundEmitter ~= nil then
                inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_mech_lrg_sharp")
            end

            if inst.sg and inst.sg.mem then
                local mem = inst.sg.mem
                mem.wx78shieldingdamage = (mem.wx78shieldingdamage or 0) + real_damage

                if mem.wx78shieldingdamage >= 100 then
                    mem.wx78shieldingdamage = 0
                    inst.sg:GoToState("wx_shield_pst")
                end
            end

            inst:PushEvent("blocked", {
                attacker = attacker,
                damage = 0,
                spdamage = nil,
                original_damage = real_damage
            })

            return false
        end

        return _old(self, attacker, damage, weapon, stimuli, spdamage, ...)
    end
end)

local function CanUseBlockingCircuit(wx)
    if wx == nil or not wx:IsValid() then return false end
    return HasActiveModule(wx, "shielding") and HasSkill(wx, "wx78_circuitry_gammabuffs_2") and HasCharge(wx)
end

local function ApplyBlockingTags(inst)
    if not inst:HasTag("heavybody") then
        inst:AddTag("heavybody")
        inst._dwx78_added_heavybody = true
    end
end

local function RemoveBlockingTags(inst)
    if inst._dwx78_added_heavybody and inst:HasTag("heavybody") then
        inst:RemoveTag("heavybody")
    end
    inst._dwx78_added_heavybody = nil
end


----------------------------------------------------------------
-- ============================================================
-- 2. TASER CIRCUIT (+25% DANO BRUTO)
-- ============================================================
----------------------------------------------------------------
local function CanUseTaserCircuit(wx)
    if wx == nil or not wx:IsValid() then return false end
    return HasActiveModule(wx, "taser") and HasCharge(wx)
end

local function UpdateTaserBonusDamage(inst)
    if not inst.components.combat then return end

    if CanUseTaserCircuit(inst) then
        inst.components.combat.externaldamagemultipliers:SetModifier(inst, 1.25, "taser_damage_bonus")
    else
        inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "taser_damage_bonus")
    end
end


-- ============================================================
-- 3. ZAP DRONE (DANO E ALCANCE)
-- ============================================================
----------------------------------------------------------------
-- A Klei guarda os status das habilidades do WX-78 na tabela WX78_SKILLS.
-- Nós sobrescrevemos os valores originais aqui direto na raiz do mod.

-- Alcance para o drone começar a atirar
GLOBAL.TUNING.WX78_ZAPDRONE_RANGE = 25

-- Alcance máximo que o drone persegue antes de voltar
GLOBAL.TUNING.WX78_ZAPDRONE_MAX_RANGE = 40


----------------------------------------------------------------
-- ============================================================
-- 4. MASTER HOOK (INICIALIZAÇÃO DO WX-78)
-- ============================================================
----------------------------------------------------------------
AddPrefabPostInit("wx78", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

-- Loop de checagem física (Roda a cada 0.5s)
    inst:DoPeriodicTask(0.5, function()
        
        -- 1. Gerencia as tags de peso do Shielding
        if not CanUseBlockingCircuit(inst) then
            RemoveBlockingTags(inst)
        else
            ApplyBlockingTags(inst)
        end

        -- 2. Gerencia o bônus de dano bruto de 25% do Taser
        UpdateTaserBonusDamage(inst)
        
    end)
end)