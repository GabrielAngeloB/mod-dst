local GLOBAL = GLOBAL

local MIN_CAM_DIST = 50
local MAX_REVEAL_RADIUS = 120
local MIN_REVEAL_STEP = 0.10
local MAX_REVEAL_STEP = 0.50
local SERVER_RPC_COOLDOWN = 1.5
local CLIENT_SEND_INTERVAL = 2.0

local function IsCaveWorld()
    return GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld:HasTag("cave")
end

local function IsFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function CanUseRangebooster(player)
    return player ~= nil
        and player:IsValid()
        and player.prefab == "wx78"
        and HasActiveModule(player, "radar")
        and HasSkill(player, "wx78_circuitry_betabuffs_1")
        and HasCharge(player)
end

-- Server-authoritative map reveal. Client parameters are validated/clamped.
local function RevealArea(player, radius, step)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim
        or not CanUseRangebooster(player)
        or not IsFiniteNumber(radius)
        or not IsFiniteNumber(step) then
        return
    end

    local now = GLOBAL.GetTime()
    if player._wx78_rangebooster_last_reveal ~= nil
        and now - player._wx78_rangebooster_last_reveal < SERVER_RPC_COOLDOWN then
        return
    end

    local classified = player.player_classified
    local explorer = classified ~= nil and classified.MapExplorer or nil
    if explorer == nil then
        return
    end

    radius = math.clamp(radius, 0, MAX_REVEAL_RADIUS)
    step = math.clamp(step, MIN_REVEAL_STEP, MAX_REVEAL_STEP)
    if radius <= 0 then
        return
    end

    player._wx78_rangebooster_last_reveal = now

    local x, _, z = player.Transform:GetWorldPosition()
    for theta = 0, GLOBAL.PI2, step do
        explorer:RevealArea(
            x + radius * math.cos(theta),
            0,
            z + radius * math.sin(theta)
        )
    end
end

AddModRPCHandler(modname, "RevealArea", RevealArea)

local function GetEffectiveCameraDistance(inst)
    local camera = GLOBAL.TheCamera
    if camera == nil then
        return 0
    end

    local base = 0
    if camera.GetRawMaxDistance ~= nil then
        base = camera:GetRawMaxDistance() or 0
    else
        base = camera.distance or 0
    end

    local extra = 0
    local classified = inst.player_classified
    if classified ~= nil and classified.cameraextramaxdist ~= nil then
        extra = classified.cameraextramaxdist:value() or 0
    end

    local result = math.max(MIN_CAM_DIST, base + extra)
    if IsCaveWorld() then
        result = result + 10
    end
    return result
end

local function TryReveal(inst)
    if inst == nil or not inst:IsValid() then
        return
    end

    local camera_distance = GetEffectiveCameraDistance(inst)
    if camera_distance <= 0 then
        return
    end

    local radius = math.clamp(
        (camera_distance - MIN_CAM_DIST) * 0.7,
        0,
        MAX_REVEAL_RADIUS
    )
    if radius <= 0 then
        return
    end

    local now = GLOBAL.GetTime()
    if inst._wx78_rangebooster_last_send ~= nil
        and now - inst._wx78_rangebooster_last_send < CLIENT_SEND_INTERVAL then
        return
    end

    local num_steps = math.max(24, math.min(64, math.floor(camera_distance * 0.45)))
    local step = GLOBAL.PI2 / num_steps
    inst._wx78_rangebooster_last_send = now

    -- Listen-server host reveals locally; remote clients use the RPC.
    if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastersim then
        RevealArea(inst, radius, step)
    else
        SendModRPCToServer(GetModRPC(modname, "RevealArea"), radius, step)
    end
end

AddPlayerPostInit(function(inst)
    if inst.prefab ~= "wx78" then
        return
    end

    -- Dedicated servers have no camera, so TryReveal exits without work.
    inst:DoPeriodicTask(CLIENT_SEND_INTERVAL, TryReveal)
end)
