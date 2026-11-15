local GLOBAL = GLOBAL
local MIN_CAM_DIST = 50
local MAX_REVEAL_RADIUS = 80
local MIN_REVEAL_POINTS = 24
local MAX_REVEAL_POINTS = 72
local SERVER_REQUEST_INTERVAL = 0.5
local TWO_PI = GLOBAL.PI2 or (2 * math.pi)

local function CanRevealForPlayer(player)
    return player ~= nil
        and player:IsValid()
        and player.prefab == "wx78"
        and HasActiveModule(player, "radar")
        and HasSkill(player, "wx78_circuitry_betabuffs_1")
        and HasCharge(player)
end

-- RPC arguments are untrusted. All gameplay requirements are checked again
-- against the authoritative server-side player before the map is revealed.
local function RevealArea(player, requested_radius, requested_step)
    if not CanRevealForPlayer(player) then
        return
    end

    if type(requested_radius) ~= "number"
        or requested_radius ~= requested_radius
        or requested_radius == math.huge
        or requested_radius == -math.huge then
        return
    end

    local now = GLOBAL.GetTime()
    if player._dwx78_range_last_request ~= nil
        and now - player._dwx78_range_last_request < SERVER_REQUEST_INTERVAL then
        return
    end
    player._dwx78_range_last_request = now

    local classified = player.player_classified
    local explorer = classified ~= nil and classified.MapExplorer or nil
    if explorer == nil or explorer.RevealArea == nil then
        return
    end

    local radius = math.max(0, math.min(MAX_REVEAL_RADIUS, requested_radius))
    if radius <= 0 then
        return
    end

    local points = MIN_REVEAL_POINTS
    if type(requested_step) == "number"
        and requested_step > 0
        and requested_step < math.huge then
        points = math.floor(TWO_PI / requested_step + 0.5)
    end
    points = math.max(MIN_REVEAL_POINTS, math.min(MAX_REVEAL_POINTS, points))
    local step = TWO_PI / points

    local x, _, z = player.Transform:GetWorldPosition()
    explorer:RevealArea(x, 0, z)

    for i = 0, points - 1 do
        local angle = i * step
        explorer:RevealArea(
            x + radius * math.cos(angle),
            0,
            z + radius * math.sin(angle)
        )
    end
end

AddModRPCHandler(modname, "RevealArea", RevealArea)

local function GetEffectiveCameraDistance()
    local base = 0

    if GLOBAL.TheCamera ~= nil then
        if GLOBAL.TheCamera.GetRawMaxDistance ~= nil then
            base = GLOBAL.TheCamera:GetRawMaxDistance() or 0
        else
            base = GLOBAL.TheCamera.distance or 0
        end
    end

    local extra = 0
    local player = GLOBAL.ThePlayer
    local classified = player ~= nil and player.player_classified or nil
    if classified ~= nil and classified.cameraextramaxdist ~= nil then
        extra = classified.cameraextramaxdist:value() or 0
    end

    return math.max(MIN_CAM_DIST, base + extra)
end

local function TryReveal(inst)
    if inst == nil or not inst:IsValid() or inst.prefab ~= "wx78" then
        return
    end

    -- The server performs authoritative circuit/skill/charge validation.
    -- The client only supplies its current camera-derived reveal radius.
    local camera_distance = GetEffectiveCameraDistance()
    local radius = math.min(
        MAX_REVEAL_RADIUS,
        math.max(0, (camera_distance - MIN_CAM_DIST) * 0.7)
    )

    if radius <= 0 then
        return
    end

    local num_points = math.max(
        MIN_REVEAL_POINTS,
        math.min(MAX_REVEAL_POINTS, math.floor(camera_distance * 0.45))
    )
    local step = TWO_PI / num_points
    SendModRPCToServer(GetModRPC(modname, "RevealArea"), radius, step)
end

local function AttachClientReveal(inst)
    if inst.prefab ~= "wx78" then
        return
    end

    -- AddPlayerPostInit runs in both simulations. Do not schedule client RPCs
    -- from the authoritative server simulation.
    if GLOBAL.TheWorld == nil or GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoPeriodicTask(0.5, TryReveal)
end

AddPlayerPostInit(AttachClientReveal)
