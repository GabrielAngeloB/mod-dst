local GLOBAL = GLOBAL

----------------RANGEBOOSTER CIRCUIT CHANGES: START-------------
local MIN_CAM_DIST = 50

--detectar caves
local function IsCaveWorld()
    return GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld:HasTag("cave")
end

-----------------------------------------------------------------
-- CHECK: radar module + skill active
-----------------------------------------------------------------
local function RangeboosterCircuitSkill(inst)
    if inst == nil then
        return false
    end

    local module = HasActiveModule(inst, "radar")
    local skill = HasSkill(inst, "wx78_circuitry_betabuffs_1")
    local charge = HasCharge(inst)

    return module and skill and charge
end

----------------------------------------------------------------------
-- CAMERA DISTANCE
----------------------------------------------------------------------
local function GetEffectiveCameraDistance(inst)
    local base = 0

    if GLOBAL.TheCamera ~= nil then
        base = GLOBAL.TheCamera.GetRawMaxDistance
            and GLOBAL.TheCamera:GetRawMaxDistance()
            or GLOBAL.TheCamera.distance
            or 0
    end

    local extra = 0

    if inst.player_classified ~= nil
        and inst.player_classified.cameraextramaxdist ~= nil then
        extra = inst.player_classified.cameraextramaxdist:value() or 0
    end

    local result = math.max(MIN_CAM_DIST, base + extra)

    -- FIX CAVES: ya que la cámara esta fija en caves, forzar comportamiento consistente con la superficie
    if IsCaveWorld() then
        result = result + 10
    end

    return result
end

----------------------------------------------------------------------
-- REVEAL
----------------------------------------------------------------------
local function RevealArea(inst, radius, step)
    local pos = inst:GetPosition()

    local RING_COUNT = 1
    local ring_step = radius / RING_COUNT

    for i = 1, RING_COUNT do
        local r = ring_step * i

        for theta = 0, GLOBAL.PI2, step do
            local x = pos.x + r * math.cos(theta)
            local z = pos.z + r * math.sin(theta)

            inst.player_classified.MapExplorer:RevealArea(x, 0, z)
        end
    end
end

AddModRPCHandler(modname, "RevealArea", RevealArea)

----------------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------------
local function TryReveal(inst)
    if not RangeboosterCircuitSkill(inst) then
        return
    end

    local camera_distance = GetEffectiveCameraDistance(inst)

    -- en caves el mínimo no puede bloquear todo
    if camera_distance <= MIN_CAM_DIST then
        if not IsCaveWorld() then
            return
        end
        -- en caves seguimos, aunque esté en el límite
    end

    local radius = (camera_distance - MIN_CAM_DIST) * 0.7
    local num_steps = math.max(24, camera_distance * 0.45)
    local step = GLOBAL.PI2 / num_steps

    SendModRPCToServer(GetModRPC(modname, "RevealArea"), radius, step)

    last_camera_distance = camera_distance
end
----------------RANGEBOOSTER CIRCUIT CHANGES: END-------------

----------------------------------------------------------------------
-- ATTACH
----------------------------------------------------------------------
local function ModifyMapExplorer(inst)
    inst:DoPeriodicTask(0.12, TryReveal)
end

AddPlayerPostInit(ModifyMapExplorer)