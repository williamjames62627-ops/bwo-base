ZCBodycam = ZCBodycam or {}

local Config = ZCBodycam.Config
local Net = ZCBodycam.Net

local cvarWidth = CreateClientConVar(
    "zc_bodycam_video_width", "512", true, false,
    "Bodycam recording width. Height follows the current screen aspect ratio.", 320, 1920
)
local cvarFPS = CreateClientConVar(
    "zc_bodycam_video_fps", "36", true, false,
    "Bodycam recording frame rate.", 10, 60
)
local cvarBitrate = CreateClientConVar(
    "zc_bodycam_video_bitrate", "16384", true, false,
    "VP8 recording bitrate.", 8192, 1048576
)
local cvarQuality = CreateClientConVar(
    "zc_bodycam_video_quality", "0", true, false,
    "VP8 recording quality value (0 low, 1 high).", 0, 1
)
local cvarSound = CreateClientConVar(
    "zc_bodycam_video_sound", "1", true, false,
    "Record game sound in the bodycam file.", 0, 1
)
local cvarAudioRealism = CreateClientConVar(
    "zc_bodycam_audio_realism", "1", true, false,
    "Enable bodycam microphone clipping, occlusion, wind and vehicle hum.", 0, 1
)
local cvarAudioWind = CreateClientConVar(
    "zc_bodycam_audio_wind", "1", true, false,
    "Add speed-dependent wind noise while recording.", 0, 1
)
local cvarAudioVehicle = CreateClientConVar(
    "zc_bodycam_audio_vehicle", "1", true, false,
    "Add a speed-dependent vehicle cabin/engine hum while recording.", 0, 1
)
local cvarAudioIntensity = CreateClientConVar(
    "zc_bodycam_audio_intensity", "1", true, false,
    "Overall bodycam microphone effects multiplier.", 0, 2
)
local cvarAudioClipDistance = CreateClientConVar(
    "zc_bodycam_audio_clip_distance", "900", true, false,
    "Maximum distance at which a gunshot can overload the bodycam microphone.", 200, 3000
)
local cvarOverlay = CreateClientConVar(
    "zc_bodycam_video_overlay", "1", true, false,
    "Draw the equipped camera timestamp overlay into the recorded video.", 0, 1
)
local cvarOverlaySerial = CreateClientConVar(
    "zc_bodycam_overlay_serial", "X83057575", true, false,
    "Serial string shown in the Axon Flex 2 overlay."
)
local cvarModel = CreateClientConVar(
    "zc_bodycam_model", Config.CustomModel or "", true, false,
    "Optional custom Source .mdl path for Axon Flex 2. Empty uses the built-in procedural camera."
)
local cvarModelScale = CreateClientConVar(
    "zc_bodycam_model_scale", tostring(Config.CustomModelScale or 1), true, false,
    "Scale for the optional custom Axon Flex 2 model.", 0.01, 10
)
local cvarMotionIntensity = CreateClientConVar(
    "zc_bodycam_motion_intensity", "1.45", true, false,
    "Overall bodycam shake multiplier.", 0.25, 3.5
)
local cvarBreathing = CreateClientConVar(
    "zc_bodycam_motion_breathing", "1.55", true, false,
    "Breathing and hand-tremor multiplier.", 0, 4
)
local cvarSharpMotion = CreateClientConVar(
    "zc_bodycam_motion_sharp", "2.35", true, false,
    "Sharp turn, camera snap and acceleration jerk multiplier.", 0, 5
)
local cvarMountPhysics = CreateClientConVar(
    "zc_bodycam_motion_mount_physics", "1", true, false,
    "Physical chest-mount spring response to acceleration, ragdoll rotation and impacts.", 0, 2.5
)
local cvarPerformanceMode = CreateClientConVar(
    "zc_bodycam_performance_mode", "2", true, false,
    "Recording performance mode: 0 full rate, 1 balanced, 2 maximum FPS.", 0, 2
)
local cvarCaptureDistance = CreateClientConVar(
    "zc_bodycam_capture_distance", "7000", true, false,
    "Maximum bodycam recording render distance. Set 0 to use the map default.", 0, 30000
)

local cvarRecordRevision = CreateClientConVar(
    "zc_bodycam_record_defaults_revision", "0", true, false,
    "Internal video preset migration revision."
)
local cvarDrawLocal = CreateClientConVar(
    "zc_bodycam_draw_local", "1", true, false,
    "Draw your own worn bodycam on the first-person/third-person body.", 0, 1
)

local RECORD_DEFAULTS_REVISION = 11
local RECORDING_AUDIO_DSP = 56
local AUDIO_DSP_COVERED = 30
local AUDIO_DSP_GROUND = 31
local AUDIO_DSP_GUN_RECOVERY = 32
local AUDIO_DSP_GUN_CLIP = 38
local AUDIO_DSP_VEHICLE = 58
local MOTION_INTENSITY = 2.18
local MOTION_TURN = 2.72
local MOTION_STEPS = 2.08
local MOTION_BREATHING = 1.62
local MOTION_TRANSLATION = 1.72
local MOTION_TREMOR = 1.58

local function getCurrentCharacter(ply)
    if hg and type(hg.GetCurrentCharacter) == "function" then
        local character = hg.GetCurrentCharacter(ply)
        if IsValid(character) and character ~= ply then return character end
    end



    if IsValid(ply) and not ply:Alive() then
        local deathRagdoll = ply:GetNWEntity("RagdollDeath", NULL)
        if IsValid(deathRagdoll) then return deathRagdoll end
    end

    if IsValid(ply) then
        local fakeRagdoll = ply:GetNWEntity("FakeRagdoll", NULL)
        if IsValid(fakeRagdoll) then return fakeRagdoll end
    end

    return ply
end

local renderingBodycamCapture = false
ZCBodycam.RenderingCapture = false
-- Public compatibility state for addons that use clientside spatial audio (NPC Voice Chat).
-- The recorder captures the normal engine mix; this flag lets those addons avoid muting
-- or replacing their channels while a bodycam file is being written.
ZCBodycam.Recording = false
ZCBodycam.RecordingAudio = false

local function getCameraData(cameraType)
    return Config.Cameras and Config.Cameras[cameraType or Config.DefaultCameraType] or
        (Config.Cameras and Config.Cameras[Config.DefaultCameraType])
end

local function isKnownCameraType(cameraType)
    return isstring(cameraType) and Config.Cameras and Config.Cameras[cameraType] ~= nil
end

local function getCameraTypeFor(owner, character)
    if not Config.RequireEquippedArmor then
        return Config.DefaultCameraType
    end

    if type(ZCBodycam.GetCharacterCameraType) == "function" then
        local cameraType = ZCBodycam.GetCharacterCameraType(owner, character)
        if cameraType then return cameraType end
    end

    if IsValid(owner) and Config.EquippedTypeNetworkString then
        local cameraType = owner:GetNWString(Config.EquippedTypeNetworkString, "")
        if cameraType ~= "" and isKnownCameraType(cameraType) then return cameraType end
    end

    if IsValid(character) and Config.EquippedTypeNetworkString then
        local cameraType = character:GetNWString(Config.EquippedTypeNetworkString, "")
        if cameraType ~= "" and isKnownCameraType(cameraType) then return cameraType end
    end
end

local function isBodycamEquippedForClient(owner, character)
    if not Config.RequireEquippedArmor then return true end
    if getCameraTypeFor(owner, character) then return true end

    if IsValid(owner) and Config.EquippedNetworkBool and
        owner:GetNWBool(Config.EquippedNetworkBool, false) then
        return true
    end

    if IsValid(character) and Config.EquippedNetworkBool and
        character:GetNWBool(Config.EquippedNetworkBool, false) then
        return true
    end

    return false
end

local function getPlacement(cameraType)
    local camera = getCameraData(cameraType)
    local value = camera and camera.BodyPosition or Vector(5, 8.6, 1)
    local angles = camera and camera.BodyAngles or angle_zero
    return Vector(value.x, value.y, value.z), Angle(angles.p, angles.y, angles.r)
end

local function getButtonOffset(cameraType)
    local camera = getCameraData(cameraType)
    local value = camera and camera.ButtonOffset or Vector(-1.02, 0.72, 0)
    return Vector(value.x, value.y, value.z)
end

local function migrateRecordingDefaults()
    local currentRevision = cvarRecordRevision:GetInt()
    if currentRevision >= RECORD_DEFAULTS_REVISION then return end



    if currentRevision < 7 then
        RunConsoleCommand("zc_bodycam_video_width", "512")
        RunConsoleCommand("zc_bodycam_video_fps", "36")
        RunConsoleCommand("zc_bodycam_video_bitrate", "16384")
        RunConsoleCommand("zc_bodycam_video_quality", "0")
        RunConsoleCommand("zc_bodycam_motion_intensity", "1.45")
        RunConsoleCommand("zc_bodycam_motion_breathing", "1.55")
        RunConsoleCommand("zc_bodycam_motion_sharp", "2.35")
        RunConsoleCommand("zc_bodycam_performance_mode", "2")
        RunConsoleCommand("zc_bodycam_capture_distance", "7000")
    end

    if currentRevision < 10 and cvarPerformanceMode:GetInt() == 1 then
        RunConsoleCommand("zc_bodycam_performance_mode", "2")
    end

    if currentRevision < 11 and cvarFPS:GetInt() <= 30 then
        RunConsoleCommand("zc_bodycam_video_fps", "36")
    end



    RunConsoleCommand("zc_bodycam_record_defaults_revision", tostring(RECORD_DEFAULTS_REVISION))
end

timer.Simple(0, migrateRecordingDefaults)

local function getBodycamTransform(ent, cameraType)
    if not IsValid(ent) then return end

    local matrix
    for _, boneName in ipairs(Config.BoneCandidates) do
        local bone = ent:LookupBone(boneName)
        if bone and bone >= 0 then
            matrix = ent:GetBoneMatrix(bone)
            if matrix then break end
        end
    end

    if not matrix then
        ent:SetupBones()
        for _, boneName in ipairs(Config.BoneCandidates) do
            local bone = ent:LookupBone(boneName)
            if bone and bone >= 0 then
                matrix = ent:GetBoneMatrix(bone)
                if matrix then break end
            end
        end
    end

    if not matrix then return end

    cameraType = cameraType or getCameraTypeFor(ent, ent) or Config.DefaultCameraType
    local localPos, localAng = getPlacement(cameraType)
    local worldPos, worldAng = LocalToWorld(
        localPos,
        localAng,
        matrix:GetTranslation(),
        matrix:GetAngles()
    )
    return worldPos, worldAng, cameraType
end

ZCBodycam.GetBodycamTransform = getBodycamTransform

local function getBodycamButtonWorld(ent, cameraType)
    local cameraPos, cameraAng, resolvedType = getBodycamTransform(ent, cameraType)
    if not cameraPos then return end

    local buttonPos = LocalToWorld(getButtonOffset(resolvedType), angle_zero, cameraPos, cameraAng)
    return buttonPos, cameraAng, cameraPos, resolvedType
end

ZCBodycam.GetBodycamButtonWorld = getBodycamButtonWorld

local function rotateAngle(baseAng, offsetAng)
    local ang = Angle(baseAng.p, baseAng.y, baseAng.r)
    ang:RotateAroundAxis(ang:Right(), offsetAng.p or 0)
    ang:RotateAroundAxis(ang:Up(), offsetAng.y or 0)
    ang:RotateAroundAxis(ang:Forward(), offsetAng.r or 0)
    return ang
end

local motionState = {
    initialized = false,
    lastTime = 0,
    lastBasePos = Vector(0, 0, 0),
    lastBaseAng = Angle(0, 0, 0),
    lastEyeAng = Angle(0, 0, 0),
    lastMountVelocity = Vector(0, 0, 0),
    lastMountAcceleration = Vector(0, 0, 0),
    lastAngularRate = Vector(0, 0, 0),
    lastCharacter = NULL,
    lastGrounded = true,
    lastVerticalVelocity = 0,
    moveAmount = 0,
    stepPhase = 0,
    footstepKick = 0,
    footstepSide = 1,
    landingKick = 0,
    landingSide = 1,
    jumpKick = 0,
    turnKick = Vector(0, 0, 0),
    turnPositionKick = Vector(0, 0, 0),
    angleOffset = Vector(0, 0, 0),
    angleVelocity = Vector(0, 0, 0),
    positionOffset = Vector(0, 0, 0),
    positionVelocity = Vector(0, 0, 0)
}

local zeroMotionVector = Vector(0, 0, 0)

local function copyVector(value)
    return Vector(value.x, value.y, value.z)
end

local function copyAngle(value)
    return Angle(value.p, value.y, value.r)
end

local function resetBodycamMotion()
    motionState.initialized = false
    motionState.lastTime = 0
    motionState.moveAmount = 0
    motionState.stepPhase = 0
    motionState.footstepKick = 0
    motionState.landingKick = 0
    motionState.jumpKick = 0
    motionState.turnKick = Vector(0, 0, 0)
    motionState.turnPositionKick = Vector(0, 0, 0)
    motionState.angleOffset = Vector(0, 0, 0)
    motionState.angleVelocity = Vector(0, 0, 0)
    motionState.positionOffset = Vector(0, 0, 0)
    motionState.positionVelocity = Vector(0, 0, 0)
    motionState.lastMountVelocity = Vector(0, 0, 0)
    motionState.lastMountAcceleration = Vector(0, 0, 0)
    motionState.lastAngularRate = Vector(0, 0, 0)
    motionState.lastCharacter = NULL
end

ZCBodycam.ResetBodycamMotion = resetBodycamMotion

local function springVector(current, velocity, target, stiffness, damping, dt)
    local acceleration = (target - current) * stiffness - velocity * damping
    velocity = velocity + acceleration * dt
    current = current + velocity * dt
    return current, velocity
end

local function clampVectorLength(value, maxLength)
    local length = value:Length()
    if length > maxLength and length > 0 then
        return value * (maxLength / length)
    end
    return value
end

local function getChestPhysicsObject(ent)
    if not IsValid(ent) or not isfunction(ent.TranslateBoneToPhysBone) then return end

    for _, boneName in ipairs(Config.BoneCandidates or {}) do
        local bone = ent:LookupBone(boneName)
        if bone and bone >= 0 then
            local physBone = ent:TranslateBoneToPhysBone(bone)
            if physBone and physBone >= 0 then
                local phys = ent:GetPhysicsObjectNum(physBone)
                if IsValid(phys) then return phys end
            end
        end
    end
end

local function getMotionSource(ply, character)
    if IsValid(character) and character ~= ply then
        return character, getChestPhysicsObject(character)
    end

    if IsValid(ply) and ply:InVehicle() then
        local vehicle = ply:GetVehicle()
        if IsValid(vehicle) then
            local phys = vehicle:GetPhysicsObject()
            return vehicle, IsValid(phys) and phys or nil
        end
    end

    return ply, nil
end

local function sampleMountMotion(ply, character, basePos, baseAng, dt)
    local source, phys = getMotionSource(ply, character)
    local sourceVelocity = IsValid(source) and source:GetVelocity() or zeroMotionVector
    local angularVelocity

    if IsValid(phys) then
        if isfunction(phys.GetVelocityAtPoint) then
            local ok, velocityAtPoint = pcall(phys.GetVelocityAtPoint, phys, basePos)
            if ok and isvector(velocityAtPoint) then
                sourceVelocity = velocityAtPoint
            end
        else
            sourceVelocity = phys:GetVelocity()
        end

        if isfunction(phys.GetAngleVelocity) then
            angularVelocity = phys:GetAngleVelocity()
        end
    end

    local kinematicVelocity = (basePos - motionState.lastBasePos) / math.max(dt, 0.001)
    kinematicVelocity = clampVectorLength(kinematicVelocity, 3200)

    local blend = 0.14
    if IsValid(character) and character ~= ply then
        blend = 0.58
    elseif IsValid(ply) and ply:InVehicle() then
        blend = 0.34
    end

    local mountVelocity = LerpVector(blend, sourceVelocity, kinematicVelocity)

    local measuredAngular = Vector(
        math.AngleDifference(baseAng.p, motionState.lastBaseAng.p) / dt,
        math.AngleDifference(baseAng.y, motionState.lastBaseAng.y) / dt,
        math.AngleDifference(baseAng.r, motionState.lastBaseAng.r) / dt
    )

    if isvector(angularVelocity) then
        local angularWorld = isfunction(phys.LocalToWorldVector) and
            phys:LocalToWorldVector(angularVelocity) or angularVelocity
        local physicalLocal = Vector(
            angularWorld:Dot(baseAng:Right()),
            angularWorld:Dot(baseAng:Up()),
            angularWorld:Dot(baseAng:Forward())
        )
        measuredAngular = LerpVector(0.62, measuredAngular, physicalLocal)
    end

    measuredAngular.x = math.Clamp(measuredAngular.x, -900, 900)
    measuredAngular.y = math.Clamp(measuredAngular.y, -900, 900)
    measuredAngular.z = math.Clamp(measuredAngular.z, -1100, 1100)

    return mountVelocity, measuredAngular
end

local function buildBaseBodycamPose(ply)
    local character = getCurrentCharacter(ply)
    if not IsValid(character) then return end

    if not isBodycamEquippedForClient(ply, character) then
        return
    end

    local cameraType = getCameraTypeFor(ply, character) or Config.DefaultCameraType
    local camera = getCameraData(cameraType)
    local pos, ang = getBodycamTransform(character, cameraType)
    if not pos or not camera then return end

    local viewOffset = camera.ViewPosition or Vector(0.72, 0.95, 0)
    local viewAngles = camera.ViewAngles or Angle(0, 90, 0)
    local viewPos = LocalToWorld(viewOffset, angle_zero, pos, ang)
    local rawViewAng = rotateAngle(ang, viewAngles)
    local viewAng = rawViewAng:Forward():Angle()
    viewAng.r = camera.ViewRoll or 0

    return viewPos, viewAng, cameraType, camera, character
end

local function initializeBodycamMotion(ply, character, basePos, baseAng, now)
    motionState.initialized = true
    motionState.lastTime = now
    motionState.lastBasePos = copyVector(basePos)
    motionState.lastBaseAng = copyAngle(baseAng)
    motionState.lastEyeAng = IsValid(ply) and copyAngle(ply:EyeAngles()) or copyAngle(baseAng)
    motionState.lastCharacter = character
    motionState.lastGrounded = IsValid(ply) and ply:IsOnGround() or true

    local mountVelocity, angularRate = sampleMountMotion(ply, character, basePos, baseAng, 1 / 60)
    motionState.lastMountVelocity = copyVector(mountVelocity)
    motionState.lastMountAcceleration = Vector(0, 0, 0)
    motionState.lastAngularRate = copyVector(angularRate)
    motionState.lastVerticalVelocity = mountVelocity.z
end

local function updateBodycamMotion(ply, character, basePos, baseAng)
    local now = SysTime()
    local eyeAng = ply:EyeAngles()

    if not motionState.initialized then
        initializeBodycamMotion(ply, character, basePos, baseAng, now)
        return zeroMotionVector, zeroMotionVector
    end

    local rawDt = now - motionState.lastTime
    if rawDt <= 0 then
        return motionState.positionOffset, motionState.angleOffset
    end

    if rawDt > 0.25 or
        basePos:DistToSqr(motionState.lastBasePos) > (96 * 96) or
        motionState.lastCharacter ~= character then
        resetBodycamMotion()
        initializeBodycamMotion(ply, character, basePos, baseAng, now)
        return zeroMotionVector, zeroMotionVector
    end

    local dt = math.Clamp(rawDt, 1 / 240, 0.05)
    local physicalCharacter = IsValid(character) and character ~= ply
    local onGround = not physicalCharacter and ply:IsOnGround()
    local inVehicle = ply:InVehicle()
    local crouching = not physicalCharacter and ply:Crouching()

    local mountVelocity, physicalAngularRate = sampleMountMotion(ply, character, basePos, baseAng, dt)
    local acceleration = (mountVelocity - motionState.lastMountVelocity) / dt
    acceleration = clampVectorLength(acceleration, 4200)
    local jerk = (acceleration - motionState.lastMountAcceleration) / dt
    jerk = clampVectorLength(jerk, 36000)

    local forward = baseAng:Forward()
    local right = baseAng:Right()
    local up = baseAng:Up()
    local groundSpeed = mountVelocity:Length2D()
    local forwardAccel = math.Clamp(acceleration:Dot(forward), -3000, 3000)
    local rightAccel = math.Clamp(acceleration:Dot(right), -3000, 3000)
    local verticalAccel = math.Clamp(acceleration:Dot(up), -3200, 3200)
    local forwardJerk = math.Clamp(jerk:Dot(forward), -24000, 24000)
    local rightJerk = math.Clamp(jerk:Dot(right), -24000, 24000)
    local verticalJerk = math.Clamp(jerk:Dot(up), -26000, 26000)

    local eyeYawDelta = math.AngleDifference(eyeAng.y, motionState.lastEyeAng.y)
    local eyePitchDelta = math.AngleDifference(eyeAng.p, motionState.lastEyeAng.p)
    local eyeYawRate = eyeYawDelta / dt
    local eyePitchRate = eyePitchDelta / dt

    local viewInfluence = physicalCharacter and 0 or (inVehicle and 0.10 or 0.28)
    local angularRate = Vector(
        physicalAngularRate.x * (1 - viewInfluence) + eyePitchRate * viewInfluence,
        physicalAngularRate.y * (1 - viewInfluence) + eyeYawRate * viewInfluence,
        physicalAngularRate.z
    )
    angularRate.x = math.Clamp(angularRate.x, -760, 760)
    angularRate.y = math.Clamp(angularRate.y, -760, 760)
    angularRate.z = math.Clamp(angularRate.z, -980, 980)

    local angularAcceleration = (angularRate - motionState.lastAngularRate) / dt
    angularAcceleration.x = math.Clamp(angularAcceleration.x, -6200, 6200)
    angularAcceleration.y = math.Clamp(angularAcceleration.y, -6200, 6200)
    angularAcceleration.z = math.Clamp(angularAcceleration.z, -7600, 7600)

    local wantedMove = 0
    if onGround and not inVehicle and groundSpeed > 8 then
        wantedMove = math.Clamp(groundSpeed / 245, 0, 1.5)
    end

    local moveBlend = 1 - math.exp(-dt * 9)
    motionState.moveAmount = Lerp(moveBlend, motionState.moveAmount, wantedMove)

    if wantedMove > 0.01 then
        local strideFrequency = 1.55 + math.Clamp(groundSpeed / 320, 0, 1) * 1.55
        motionState.stepPhase = motionState.stepPhase + dt * math.pi * 2 * strideFrequency
    end

    if onGround and not motionState.lastGrounded and motionState.lastVerticalVelocity < -105 then
        motionState.landingKick = math.Clamp((-motionState.lastVerticalVelocity - 70) / 300, 0.22, 1.7)
        motionState.landingSide = rightAccel >= 0 and 1 or -1
    elseif not onGround and motionState.lastGrounded and mountVelocity.z > 80 then
        motionState.jumpKick = math.Clamp((mountVelocity.z - 55) / 245, 0.12, 0.9)
    end

    motionState.footstepKick = motionState.footstepKick * math.exp(-dt * 10)
    motionState.landingKick = motionState.landingKick * math.exp(-dt * 5.7)
    motionState.jumpKick = motionState.jumpKick * math.exp(-dt * 6.8)

    local intensity = MOTION_INTENSITY * cvarMotionIntensity:GetFloat()
    local turnStrength = MOTION_TURN
    local stepStrength = MOTION_STEPS
    local breathingStrength = MOTION_BREATHING * cvarBreathing:GetFloat()
    local translationStrength = MOTION_TRANSLATION
    local sharpStrength = cvarSharpMotion:GetFloat()
    local mountStrength = cvarMountPhysics:GetFloat()

    local crouchScale = crouching and 0.68 or 1
    local moveAmount = motionState.moveAmount * crouchScale
    local phase = motionState.stepPhase
    local stepWave = math.sin(phase)
    local stepDouble = math.sin(phase * 2)
    local stepImpact = math.abs(math.sin(phase))

    local organism = ply.organism or {}
    local pulse = isnumber(organism.pulse) and organism.pulse or 70
    local stressScale = 1 + math.Clamp((pulse - 75) / 110, 0, 0.85)
    local weapon = ply:GetActiveWeapon()
    local aiming = ply:KeyDown(IN_ATTACK2)
    if IsValid(weapon) and type(weapon.IsZoom) == "function" then
        local ok, zoomed = pcall(weapon.IsZoom, weapon)
        aiming = aiming or (ok and zoomed)
    end
    local aimTremor = aiming and 1.32 or 1

    local breathWave = math.sin(now * 1.42)
    local breathSecondary = math.sin(now * 0.72 + 0.9)
    local breathPulse = math.sin(now * 2.84 + 0.35) * 0.35

    local tremorScale = MOTION_TREMOR * breathingStrength * stressScale * aimTremor
    local microPitch = (
        math.sin(now * 8.7 + 0.3) +
        math.sin(now * 13.9 + 1.1) * 0.75 +
        math.sin(now * 21.7 + 2.4) * 0.35
    ) * 0.032 * tremorScale
    local microYaw = (
        math.sin(now * 7.5 + 2.0) +
        math.sin(now * 16.8) * 0.70 +
        math.sin(now * 24.1 + 0.8) * 0.30
    ) * 0.025 * tremorScale
    local microRoll = (
        math.sin(now * 9.8 + 1.7) +
        math.sin(now * 19.3 + 0.2) * 0.75 +
        math.sin(now * 27.4 + 1.3) * 0.25
    ) * 0.030 * tremorScale



    if inVehicle then
        local vehicleAmount = math.Clamp(groundSpeed / 850, 0, 1)
        local engineFrequency = 18 + vehicleAmount * 19
        microPitch = microPitch + math.sin(now * engineFrequency) * (0.055 + vehicleAmount * 0.09)
        microYaw = microYaw + math.sin(now * (engineFrequency * 1.31) + 0.2) * (0.028 + vehicleAmount * 0.05)
        microRoll = microRoll + math.sin(now * (engineFrequency * 0.83) + 0.6) * (0.045 + vehicleAmount * 0.08)
    end

    local turnActivity = math.Clamp(
        math.abs(angularRate.y) / 360
            + math.abs(angularRate.x) / 280
            + math.abs(angularAcceleration.y) / 5200
            + math.abs(angularAcceleration.x) / 4400,
        0,
        2.25
    )

    local turnImpulse = Vector(
        math.Clamp(-eyePitchDelta * 0.34 - angularAcceleration.x * dt * 0.0015, -1.7, 1.7),
        math.Clamp(-eyeYawDelta * 0.22 - angularAcceleration.y * dt * 0.0009, -1.35, 1.35),
        math.Clamp(-eyeYawDelta * 0.48 - angularAcceleration.y * dt * 0.0017, -2.4, 2.4)
    ) * sharpStrength * (physicalCharacter and 0 or 1)

    motionState.turnKick = motionState.turnKick + turnImpulse
    motionState.turnKick.x = math.Clamp(motionState.turnKick.x, -5.8, 5.8)
    motionState.turnKick.y = math.Clamp(motionState.turnKick.y, -4.5, 4.5)
    motionState.turnKick.z = math.Clamp(motionState.turnKick.z, -8.0, 8.0)

    local translationImpulse = Vector(
        math.Clamp(-eyePitchDelta * 0.0045, -0.055, 0.055),
        math.Clamp(-eyeYawDelta * 0.0055, -0.070, 0.070),
        math.Clamp((math.abs(eyeYawDelta) + math.abs(eyePitchDelta)) * -0.0019, -0.055, 0)
    ) * sharpStrength * (physicalCharacter and 0 or 1)
    motionState.turnPositionKick = clampVectorLength(motionState.turnPositionKick + translationImpulse, 0.30)

    local snapDecay = math.exp(-dt * (18.5 + turnActivity * 6.5))
    motionState.turnKick = motionState.turnKick * snapDecay
    motionState.turnPositionKick = motionState.turnPositionKick * math.exp(-dt * 18.0)



    local deltaVelocity = mountVelocity - motionState.lastMountVelocity
    local impactSpeed = deltaVelocity:Length()
    if impactSpeed > 58 and mountStrength > 0 then
        local localDelta = Vector(
            deltaVelocity:Dot(forward),
            deltaVelocity:Dot(right),
            deltaVelocity:Dot(up)
        )
        local impact = math.Clamp((impactSpeed - 58) / 440, 0, 2.1) * mountStrength

        motionState.angleVelocity = motionState.angleVelocity + Vector(
            math.Clamp((-localDelta.z * 0.042 - localDelta.x * 0.016) * impact, -34, 34),
            math.Clamp((-localDelta.y * 0.025) * impact, -26, 26),
            math.Clamp((-localDelta.y * 0.057 - localDelta.z * 0.012) * impact, -46, 46)
        )
        motionState.positionVelocity = motionState.positionVelocity + Vector(
            math.Clamp(-localDelta.x * 0.0034 * impact, -2.8, 2.8),
            math.Clamp(-localDelta.y * 0.0038 * impact, -3.0, 3.0),
            math.Clamp(-localDelta.z * 0.0030 * impact, -2.7, 2.7)
        )
    end

    local mountRattle = Vector(
        math.Clamp(-angularAcceleration.x * 0.00052 - verticalJerk * 0.000018, -3.0, 3.0),
        math.Clamp(-angularAcceleration.y * 0.00038 - rightJerk * 0.000013, -2.2, 2.2),
        math.Clamp(-angularAcceleration.z * 0.00062 - rightJerk * 0.000024, -4.0, 4.0)
    ) * mountStrength

    local angleTarget = Vector(
        (-angularRate.x * 0.0050 * turnStrength)
            + (-forwardAccel * 0.00098 * mountStrength)
            + (-forwardJerk * 0.000020 * mountStrength)
            + (stepDouble * 0.36 * moveAmount * stepStrength)
            + ((breathWave + breathPulse) * 0.115 * breathingStrength)
            + (motionState.footstepKick * 0.58 * stepStrength)
            + (motionState.landingKick * 2.15 * stepStrength)
            - (motionState.jumpKick * 0.76 * stepStrength)
            + microPitch
            + mountRattle.x,
        (-angularRate.y * 0.0025 * turnStrength)
            + (-rightAccel * 0.00034 * mountStrength)
            + (stepWave * 0.19 * moveAmount * stepStrength)
            + microYaw
            + mountRattle.y,
        (-angularRate.y * 0.0072 * turnStrength)
            + (-angularRate.z * 0.0045 * mountStrength)
            + (-rightAccel * 0.00118 * mountStrength)
            + (-rightJerk * 0.000021 * mountStrength)
            + (stepWave * 0.82 * moveAmount * stepStrength)
            + (motionState.footstepSide * motionState.footstepKick * 0.44 * stepStrength)
            + (motionState.landingSide * motionState.landingKick * 0.68 * stepStrength)
            + (breathSecondary * 0.070 * breathingStrength)
            + microRoll
            + mountRattle.z
    ) * intensity

    local positionTarget = Vector(
        math.Clamp(-forwardAccel * 0.000125 * mountStrength, -0.34, 0.34)
            + math.Clamp(-forwardJerk * 0.0000045 * mountStrength, -0.10, 0.10)
            + (stepDouble * 0.028 * moveAmount * stepStrength)
            + ((breathWave + breathPulse) * 0.018 * breathingStrength),
        math.Clamp(-rightAccel * 0.000135 * mountStrength, -0.36, 0.36)
            + math.Clamp(-rightJerk * 0.0000048 * mountStrength, -0.11, 0.11)
            + (stepWave * 0.050 * moveAmount * stepStrength)
            + (motionState.footstepSide * motionState.footstepKick * 0.024 * stepStrength),
        math.Clamp(-verticalAccel * 0.000105 * mountStrength, -0.30, 0.30)
            + math.Clamp(-verticalJerk * 0.0000038 * mountStrength, -0.10, 0.10)
            - (stepImpact * 0.078 * moveAmount * stepStrength)
            + (stepDouble * 0.025 * moveAmount * stepStrength)
            + (breathWave * 0.026 * breathingStrength)
            - (motionState.footstepKick * 0.060 * stepStrength)
            - (motionState.landingKick * 0.180 * stepStrength)
            + (motionState.jumpKick * 0.070 * stepStrength)
    ) * (intensity * translationStrength)



    motionState.angleOffset, motionState.angleVelocity = springVector(
        motionState.angleOffset,
        motionState.angleVelocity,
        angleTarget,
        164,
        17.5,
        dt
    )
    motionState.positionOffset, motionState.positionVelocity = springVector(
        motionState.positionOffset,
        motionState.positionVelocity,
        positionTarget,
        178,
        18.8,
        dt
    )

    motionState.angleOffset.x = math.Clamp(motionState.angleOffset.x, -14, 14)
    motionState.angleOffset.y = math.Clamp(motionState.angleOffset.y, -10, 10)
    motionState.angleOffset.z = math.Clamp(motionState.angleOffset.z, -17, 17)
    motionState.positionOffset = clampVectorLength(motionState.positionOffset, 1.42)

    local finalAngleOffset = motionState.angleOffset + motionState.turnKick
    finalAngleOffset.x = math.Clamp(finalAngleOffset.x, -18, 18)
    finalAngleOffset.y = math.Clamp(finalAngleOffset.y, -13, 13)
    finalAngleOffset.z = math.Clamp(finalAngleOffset.z, -22, 22)
    local finalPositionOffset = clampVectorLength(
        motionState.positionOffset + motionState.turnPositionKick,
        1.58
    )

    motionState.lastTime = now
    motionState.lastBasePos = copyVector(basePos)
    motionState.lastBaseAng = copyAngle(baseAng)
    motionState.lastEyeAng = copyAngle(eyeAng)
    motionState.lastMountVelocity = copyVector(mountVelocity)
    motionState.lastMountAcceleration = copyVector(acceleration)
    motionState.lastAngularRate = copyVector(angularRate)
    motionState.lastCharacter = character
    motionState.lastGrounded = onGround
    motionState.lastVerticalVelocity = mountVelocity.z

    return finalPositionOffset, finalAngleOffset
end

hook.Add("PlayerFootstep", "ZCBodycam_RealisticFootstepMotion", function(ply, _, foot)
    if ply ~= LocalPlayer() then return end
    if not ply:GetNWBool(Config.NetworkBool, false) then return end

    local speedAmount = math.Clamp(ply:GetVelocity():Length2D() / 300, 0, 1)
    motionState.footstepKick = math.max(motionState.footstepKick, 0.58 + speedAmount * 0.67)
    motionState.footstepSide = foot == 0 and -1 or 1
end)

local function getBodycamView(ply)
    local viewPos, viewAng, cameraType, camera, character = buildBaseBodycamPose(ply)
    if not viewPos or not camera then return end

    local positionOffset, angleOffset = updateBodycamMotion(ply, character, viewPos, viewAng)

    viewPos = viewPos
        + viewAng:Forward() * positionOffset.x
        + viewAng:Right() * positionOffset.y
        + viewAng:Up() * positionOffset.z

    local finalAng = Angle(viewAng.p, viewAng.y, viewAng.r)
    finalAng:RotateAroundAxis(finalAng:Right(), angleOffset.x)
    finalAng:RotateAroundAxis(finalAng:Up(), angleOffset.y)
    finalAng:RotateAroundAxis(finalAng:Forward(), angleOffset.z)

    local breathingFov = math.sin(SysTime() * 1.42) * 0.22 * cvarBreathing:GetFloat()

    return {
        origin = viewPos,
        angles = finalAng,
        fov = (camera.ViewFOV or 88) + breathingFov,
        znear = camera.ViewNear or 3.25,
        drawhud = false,
        drawviewmodel = false,
        drawviewer = false,
        dopostprocess = false,
        bloomtone = false,
        zcCameraType = cameraType
    }
end

ZCBodycam.GetBodycamView = getBodycamView

local function smoothStep(value)
    value = math.Clamp(value, 0, 1)
    return value * value * (3 - 2 * value)
end

local function reachAmount(time)
    if time < 0.12 then
        return 0
    elseif time < 0.40 then
        return smoothStep((time - 0.12) / 0.28)
    elseif time < 0.58 then
        return 1
    elseif time < 0.90 then
        return 1 - smoothStep((time - 0.58) / 0.32)
    end

    return 0
end

local function findPressFingerMatrix(animationModel)
    for _, boneName in ipairs(Config.PressFingerBones or {}) do
        local bone = animationModel:LookupBone(boneName)
        if bone and bone >= 0 then
            local matrix = animationModel:GetBoneMatrix(bone)
            if matrix then return matrix end
        end
    end
end

local function bodycamAnimationDraw(ent, ply, animationModel, time)
    if not IsValid(ent) or not IsValid(animationModel) then return end

    local targetPos, cameraAng = getBodycamButtonWorld(ent)
    if not targetPos then return end

    local handBone = animationModel:LookupBone("ValveBiped.Bip01_L_Hand")
    if not handBone or handBone < 0 then return end

    local handMatrix = animationModel:GetBoneMatrix(handBone)
    if not handMatrix then return end

    local amount = reachAmount(time)
    if amount <= 0 then return end

    local handPos = handMatrix:GetTranslation()
    local desiredHandPos
    local fingerMatrix = findPressFingerMatrix(animationModel)

    if fingerMatrix then

        desiredHandPos = handPos + (targetPos - fingerMatrix:GetTranslation())
    else

        desiredHandPos = targetPos + cameraAng:Right() * (Config.HandFallbackDistance or 3)
    end

    handMatrix:SetTranslation(LerpVector(amount, handPos, desiredHandPos))

    if hg and type(hg.bone_apply_matrix) == "function" then
        hg.bone_apply_matrix(animationModel, handBone, handMatrix)
    else
        animationModel:SetBoneMatrix(handBone, handMatrix)
    end
end

local animationDefinition = {
    mdl = Config.AnimationModel,
    seq = Config.AnimationSequence,
    playTime = Config.AnimationDuration,
    timeAdjust = 1,
    otherData = {
        posAdjust = Vector(1, 0, -2),
        angClamps = {{-75}, {55}}
    },
    drawFunc = bodycamAnimationDraw
}

local function registerZManipAnimation()
    if not hg or not istable(hg.ZManipAnims) then return false end

    if hg.ZManipAnims[Config.AnimationName] ~= animationDefinition then
        hg.ZManipAnims[Config.AnimationName] = animationDefinition
    end

    return true
end

hook.Add("HomigradRun", "ZCBodycam_RegisterAfterHomigrad", function()
    timer.Simple(0, registerZManipAnimation)
end)

hook.Add("OnReloaded", "ZCBodycam_RegisterAfterReload", function()
    timer.Simple(0, registerZManipAnimation)
end)

timer.Create("ZCBodycam_KeepZManipRegistered", 1, 0, registerZManipAnimation)
registerZManipAnimation()

local customModels = setmetatable({}, {__mode = "k"})

local function removeCustomModel(owner)
    local entry = customModels[owner]
    if entry and IsValid(entry.entity) then
        entry.entity:Remove()
    end
    customModels[owner] = nil
end

local function removeAllCustomModels()
    for owner, entry in pairs(customModels) do
        if entry and IsValid(entry.entity) then
            entry.entity:Remove()
        end
        customModels[owner] = nil
    end
end

local function drawCustomModel(owner, pos, ang, cameraType)
    local camera = getCameraData(cameraType)
    if not camera or camera.CustomModelAllowed == false then
        removeCustomModel(owner)
        return false
    end

    local path = string.Trim(cvarModel:GetString() or "")
    if path == "" or not util.IsValidModel(path) then return false end

    local entry = customModels[owner]
    if not entry or not IsValid(entry.entity) or entry.path ~= path then
        removeCustomModel(owner)

        local model = ClientsideModel(path, RENDERGROUP_OPAQUE)
        if not IsValid(model) then return false end

        model:SetNoDraw(true)
        entry = {entity = model, path = path}
        customModels[owner] = entry
    end

    local model = entry.entity
    model:SetModelScale(cvarModelScale:GetFloat(), 0)
    model:SetRenderOrigin(pos)
    model:SetRenderAngles(ang)
    model:SetupBones()
    model:DrawModel()
    return true
end

local darkBody = Color(26, 28, 30, 255)
local midBody = Color(34, 37, 40, 255)
local frontBody = Color(45, 49, 53, 255)
local edgeBody = Color(62, 66, 70, 255)
local lensBody = Color(7, 9, 11, 255)
local lensGlass = Color(42, 72, 92, 120)
local clipBody = Color(16, 17, 18, 255)
local detailDark = Color(15, 16, 17, 255)
local ledOff = Color(45, 65, 55, 255)
local ledOn = Color(240, 35, 35, 255)

local function drawLocalBox(basePos, baseAng, offset, mins, maxs, color)
    local pos, ang = LocalToWorld(offset, angle_zero, basePos, baseAng)
    render.DrawBox(pos, ang, mins, maxs, color, true)
end

local function drawAxonBodycam(pos, ang, recordingState, camera)
    render.SetColorMaterial()

    local s = camera and camera.ProceduralScale or 0.86
    local function SV(x, y, z) return Vector(x * s, y * s, z * s) end

    render.DrawBox(pos, ang, SV(-2.25, -0.62, -1.48), SV(2.25, 0.62, 1.48), darkBody, true)
    drawLocalBox(pos, ang, SV(0, 0, 0), SV(-2.45, -0.32, -1.63), SV(2.45, 0.32, 1.63), midBody)

    drawLocalBox(pos, ang, SV(0, -0.88, 0), SV(-1.88, -0.18, -1.12), SV(1.88, 0.18, 1.12), clipBody)
    drawLocalBox(pos, ang, SV(0, -0.42, 0), SV(-1.98, -0.10, -1.26), SV(1.98, 0.10, 1.26), midBody)
    drawLocalBox(pos, ang, SV(0, -1.08, 0), SV(-1.05, -0.08, -0.78), SV(1.05, 0.08, 0.78), detailDark)

    drawLocalBox(pos, ang, SV(-2.32, 0, 0), SV(-0.10, -0.48, -1.32), SV(0.10, 0.48, 1.32), edgeBody)
    drawLocalBox(pos, ang, SV(2.32, 0, 0), SV(-0.10, -0.48, -1.32), SV(0.10, 0.48, 1.32), edgeBody)
    for _, x in ipairs({-2.52, 2.52}) do
        for _, z in ipairs({-0.72, 0, 0.72}) do
            drawLocalBox(pos, ang, SV(x, 0.02, z), SV(-0.05, -0.36, -0.16), SV(0.05, 0.36, 0.16), detailDark)
        end
    end

    drawLocalBox(pos, ang, SV(0, 0.73, 0), SV(-1.98, -0.12, -1.24), SV(1.98, 0.12, 1.24), frontBody)
    drawLocalBox(pos, ang, SV(-1.22, 0.72, -0.96), SV(-0.65, -0.11, -0.20), SV(0.65, 0.11, 0.20), edgeBody)
    drawLocalBox(pos, ang, SV(-1.22, 0.72, 0.96), SV(-0.65, -0.11, -0.20), SV(0.65, 0.11, 0.20), edgeBody)
    drawLocalBox(pos, ang, SV(1.32, 0.72, 0), SV(-0.82, -0.11, -1.10), SV(0.82, 0.11, 1.10), edgeBody)

    drawLocalBox(pos, ang, SV(0.92, 0.95, 0), SV(-0.56, -0.18, -0.62), SV(0.56, 0.18, 0.62), lensBody)
    drawLocalBox(pos, ang, SV(0.92, 1.12, 0), SV(-0.74, -0.08, -0.80), SV(0.74, 0.08, 0.80), edgeBody)
    drawLocalBox(pos, ang, SV(0.92, 1.20, 0), SV(-0.54, -0.06, -0.58), SV(0.54, 0.06, 0.58), detailDark)
    drawLocalBox(pos, ang, SV(0.92, 1.27, 0), SV(-0.40, -0.03, -0.44), SV(0.40, 0.03, 0.44), lensGlass)

    drawLocalBox(pos, ang, SV(1.66, 0.88, -0.86), SV(-0.17, -0.12, -0.17), SV(0.17, 0.12, 0.17), recordingState and ledOn or ledOff)
    drawLocalBox(pos, ang, SV(1.56, 0.88, 0.80), SV(-0.08, -0.08, -0.08), SV(0.08, 0.08, 0.08), detailDark)
    drawLocalBox(pos, ang, SV(-0.78, 0.90, 0), SV(-0.62, -0.10, -0.30), SV(0.62, 0.10, 0.30), frontBody)

    drawLocalBox(pos, ang, getButtonOffset("axon_flex_2"), SV(-0.26, -0.12, -0.58), SV(0.26, 0.12, 0.58), detailDark)
    drawLocalBox(pos, ang, getButtonOffset("axon_flex_2") + SV(0.08, 0.10, 0), SV(-0.13, -0.06, -0.27), SV(0.13, 0.06, 0.27), edgeBody)
end

local function getModelRenderTransform(pos, ang, camera)
    if not camera then return pos, ang end

    local renderPos = pos
    local positionOffset = camera.ModelPosition
    if isvector(positionOffset) then
        renderPos = LocalToWorld(positionOffset, angle_zero, pos, ang)
    end

    local renderAng = ang
    local angleOffset = camera.ModelAngles
    if isangle(angleOffset) then
        renderAng = rotateAngle(ang, angleOffset)
    end

    return renderPos, renderAng
end

local function drawProceduralBodycam(pos, ang, recordingState, cameraType)
    local camera = getCameraData(cameraType)
    local renderPos, renderAng = getModelRenderTransform(pos, ang, camera)
    drawAxonBodycam(renderPos, renderAng, recordingState, camera)
end

ZCBodycam.DrawProceduralBodycam = drawProceduralBodycam

function ZCBodycam.DrawDroppedBodycam(ent, cameraType)
    if not IsValid(ent) then return end

    cameraType = cameraType or ent.ZCBodycamType or Config.DefaultCameraType
    drawProceduralBodycam(ent:GetPos(), ent:GetAngles(), false, cameraType)
end

local function shouldDrawFor(owner, character)
    if not IsValid(owner) or not IsValid(character) then return false end
    if not isBodycamEquippedForClient(owner, character) then return false end

    if not Config.ShowWhenOff and not owner:GetNWBool(Config.NetworkBool, false) then return false end

    if renderingBodycamCapture and owner == LocalPlayer() then return false end

    if owner == LocalPlayer() and not cvarDrawLocal:GetBool() then return false end

    if character:GetNoDraw() and owner ~= LocalPlayer() then return false end

    return EyePos():DistToSqr(character:GetPos()) <= (Config.DrawDistance * Config.DrawDistance)
end

hook.Add("PostDrawOpaqueRenderables", "ZCBodycam_DrawChestCamera", function(drawingDepth, drawingSkybox, drawing3DSkybox)
    if drawingDepth or drawingSkybox or drawing3DSkybox then return end

    for _, ply in ipairs(player.GetAll()) do
        local character = getCurrentCharacter(ply)
        if shouldDrawFor(ply, character) then
            local cameraType = getCameraTypeFor(ply, character) or Config.DefaultCameraType
            local pos, ang = getBodycamTransform(character, cameraType)
            if pos then
                if not drawCustomModel(ply, pos, ang, cameraType) then
                    drawProceduralBodycam(pos, ang, ply:GetNWBool(Config.NetworkBool, false), cameraType)
                end
            end
        end
    end
end)

cvars.AddChangeCallback("zc_bodycam_model", function()
    removeAllCustomModels()
end, "ZCBodycam_CustomModelChanged")

hook.Add("EntityRemoved", "ZCBodycam_RemoveClientModel", function(ent)
    if ent:IsPlayer() then
        removeCustomModel(ent)
    end
end)

surface.CreateFont("ZCBodycam_RecordMonoLarge", {
    font = "Consolas",
    size = 20,
    weight = 700,
    antialias = true
})

surface.CreateFont("ZCBodycam_RecordMonoSmall", {
    font = "Consolas",
    size = 17,
    weight = 700,
    antialias = true
})

local recording = {
    writer = nil,
    active = false,
    stopping = false,
    startedAt = 0,
    captureAfter = 0,
    nextFrameAt = 0,
    frameInterval = 0,
    fileName = nil,
    width = 0,
    height = 0,
    fps = 0,
    rt = nil,
    rtName = nil,
    lastFrameAt = 0,
    lastCaptureFrame = -1000,
    captureCost = 0,
    capturedFrames = 0
}

local captureProfiles = {
    [0] = {fps = 60, minFPS = 30, frameGap = 1, budget = 1, maxWidth = 1920, maxDistance = 30000},
    [1] = {fps = 40, minFPS = 30, frameGap = 1, budget = 0.62, maxWidth = 512, maxDistance = 5000},
    [2] = {fps = 36, minFPS = 30, frameGap = 1, budget = 0.52, maxWidth = 448, maxDistance = 4200}
}

local function getCaptureProfile()
    return captureProfiles[math.Clamp(cvarPerformanceMode:GetInt(), 0, 2)] or captureProfiles[2]
end

local recordingAudio = {
    active = false,
    previousDSP = "1",
    desiredDSP = RECORDING_AUDIO_DSP,
    captureWindow = false,
    gunClipUntil = 0,
    gunRecoveryUntil = 0,
    nextEnvironmentUpdate = 0,
    cameraPos = nil,
    lensCovered = false,
    groundMuffled = false,
    wind = nil,
    engine = nil,
    windVolume = 0,
    windPitch = 100,
    engineVolume = 0,
    enginePitch = 100
}

local function applyPlayerDSPNow(dsp, fastReset)
    local ply = LocalPlayer()
    if IsValid(ply) and type(ply.SetDSP) == "function" then
        pcall(ply.SetDSP, ply, dsp, fastReset == true)
    end
end

local function setDesiredRecordingDSP(dsp)
    if not recordingAudio.active then return end
    recordingAudio.desiredDSP = dsp
end

local function createRecordingLoop(path)
    local ply = LocalPlayer()
    if not IsValid(ply) or not file.Exists("sound/" .. path, "GAME") then return end

    local patch = CreateSound(ply, path)
    if not patch then return end
    pcall(patch.PlayEx, patch, 0, 100)
    return patch
end

local function stopRecordingLoop(patch)
    if patch then pcall(patch.Stop, patch) end
end

local function updateLoop(patch, volume, pitch, fadeTime)
    if not patch then return end
    pcall(patch.ChangeVolume, patch, math.Clamp(volume, 0, 1), fadeTime or 0.12)
    pcall(patch.ChangePitch, patch, math.Clamp(math.Round(pitch), 45, 180), fadeTime or 0.12)
end




local function shouldCaptureNPCVoiceAudio()
    return CLIENT and NPCVC and istable(NPCVC.SoundEmitters) and #NPCVC.SoundEmitters > 0
end

local function ensureRecordingAudioMux()
    if not recording.writer or type(recording.writer.SetRecordSound) ~= "function" then return end

    -- NPC Voice Chat uses clientside IAudioChannels. They are part of the
    -- engine mix only when the WebM writer is explicitly told to capture sound.
    -- Keep this enabled while NPCVC is active, even if the bodycam audio cvar
    -- was changed after recording started.
    if cvarSound:GetBool() or shouldCaptureNPCVoiceAudio() then
        pcall(recording.writer.SetRecordSound, recording.writer, true)
        ZCBodycam.RecordingAudio = true
    end
end

local function beginRecordingAudioCaptureWindow()
    if not recordingAudio.active or not (cvarSound:GetBool() or shouldCaptureNPCVoiceAudio()) then return end
    ensureRecordingAudioMux()

    local dsp = tonumber(recordingAudio.desiredDSP) or RECORDING_AUDIO_DSP
    applyPlayerDSPNow(dsp, false)
    updateLoop(recordingAudio.wind, recordingAudio.windVolume or 0, recordingAudio.windPitch or 100, 0)
    updateLoop(recordingAudio.engine, recordingAudio.engineVolume or 0, recordingAudio.enginePitch or 100, 0)
    recordingAudio.captureWindow = true
end

local function endRecordingAudioCaptureWindow()
    if not recordingAudio.captureWindow then return end

    updateLoop(recordingAudio.wind, 0, recordingAudio.windPitch or 100, 0)
    updateLoop(recordingAudio.engine, 0, recordingAudio.enginePitch or 100, 0)
    applyPlayerDSPNow(tonumber(recordingAudio.previousDSP) or 1, true)
    recordingAudio.captureWindow = false
end

local function ensureRecordingLoops()
    if not recordingAudio.wind then
        recordingAudio.wind = createRecordingLoop(Config.WindLoopSound or "zcity_bodycam/wind_loop.wav")
    end
    if not recordingAudio.engine then
        recordingAudio.engine = createRecordingLoop(Config.EngineLoopSound or "zcity_bodycam/engine_hum_loop.wav")
    end
end

local function traceMicrophoneOcclusion(ply, character, cameraPos, cameraAng)
    local forward = cameraAng:Forward()
    local trace = util.TraceHull({
        start = cameraPos + forward * 0.35,
        endpos = cameraPos + forward * 18,
        mins = Vector(-0.8, -0.8, -0.8),
        maxs = Vector(0.8, 0.8, 0.8),
        mask = MASK_SOLID,


        filter = ply
    })

    local distance = trace.Hit and cameraPos:Distance(trace.HitPos) or math.huge
    local facingDown = forward.z < -0.28
    local groundMuffled = trace.Hit and facingDown and distance <= 13 and trace.HitNormal.z > 0.30
    local covered = trace.Hit and distance <= 5.2 and not groundMuffled

    local networkName = Config.ClothingMuffleNetworkBool
    if networkName and networkName ~= "" then
        covered = covered or ply:GetNWBool(networkName, false)
        if IsValid(character) and character ~= ply then
            covered = covered or character:GetNWBool(networkName, false)
        end
    end

    return covered, groundMuffled
end

local function getAudioMotionSpeed(ply, character)
    if IsValid(ply) and ply:InVehicle() then
        local vehicle = ply:GetVehicle()
        if IsValid(vehicle) then return vehicle:GetVelocity():Length() end
    end

    if IsValid(character) and character ~= ply then
        local phys = getChestPhysicsObject(character)
        if IsValid(phys) then return phys:GetVelocity():Length() end
        return character:GetVelocity():Length()
    end

    return IsValid(ply) and ply:GetVelocity():Length() or 0
end

local function chooseRecordingDSP(now, inVehicle)
    if now < recordingAudio.gunClipUntil then return AUDIO_DSP_GUN_CLIP end
    if now < recordingAudio.gunRecoveryUntil then return AUDIO_DSP_GUN_RECOVERY end
    if recordingAudio.groundMuffled then return AUDIO_DSP_GROUND end
    if recordingAudio.lensCovered then return AUDIO_DSP_COVERED end
    if inVehicle then return AUDIO_DSP_VEHICLE end
    return RECORDING_AUDIO_DSP
end

local function updateRecordingAudioEnvironment()
    if not recordingAudio.active or not cvarSound:GetBool() then return end

    if not cvarAudioRealism:GetBool() then
        setDesiredRecordingDSP(RECORDING_AUDIO_DSP)
        recordingAudio.windVolume = 0
        recordingAudio.windPitch = 100
        recordingAudio.engineVolume = 0
        recordingAudio.enginePitch = 100
        if not recordingAudio.captureWindow then
            updateLoop(recordingAudio.wind, 0, 100, 0)
            updateLoop(recordingAudio.engine, 0, 100, 0)
        end
        return
    end

    local now = SysTime()
    if now < recordingAudio.nextEnvironmentUpdate then return end
    recordingAudio.nextEnvironmentUpdate = now + 0.05

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local cameraPos, cameraAng, _, _, character = buildBaseBodycamPose(ply)
    if not cameraPos then
        cameraPos = ply:EyePos()
        cameraAng = ply:EyeAngles()
        character = getCurrentCharacter(ply)
    end

    recordingAudio.cameraPos = cameraPos
    recordingAudio.lensCovered, recordingAudio.groundMuffled =
        traceMicrophoneOcclusion(ply, character, cameraPos, cameraAng)

    local speed = getAudioMotionSpeed(ply, character)
    local inVehicle = ply:InVehicle()
    local intensity = cvarAudioIntensity:GetFloat()
    local muffleScale = (recordingAudio.lensCovered or recordingAudio.groundMuffled) and 0.38 or 1

    ensureRecordingLoops()

    local windAmount = math.Clamp((speed - 155) / 920, 0, 1)
    if inVehicle then windAmount = windAmount * 0.42 end
    if not cvarAudioWind:GetBool() then windAmount = 0 end
    local windVolume = windAmount * 0.31 * intensity * muffleScale
    local windPitch = 78 + windAmount * 52
    recordingAudio.windVolume = windVolume
    recordingAudio.windPitch = windPitch

    local engineAmount = 0
    if inVehicle and cvarAudioVehicle:GetBool() then
        engineAmount = 0.24 + math.Clamp(speed / 1100, 0, 1) * 0.34
    end
    local engineVolume = engineAmount * intensity * muffleScale
    local enginePitch = 72 + math.Clamp(speed / 1000, 0, 1) * 58
    recordingAudio.engineVolume = engineVolume
    recordingAudio.enginePitch = enginePitch



    if not recordingAudio.captureWindow then
        updateLoop(recordingAudio.wind, 0, windPitch, 0)
        updateLoop(recordingAudio.engine, 0, enginePitch, 0)
    end

    setDesiredRecordingDSP(chooseRecordingDSP(now, inVehicle))
end

local function applyRecordingAudioFilter()
    if recordingAudio.active or not cvarSound:GetBool() then return end

    local dsp = GetConVar("dsp_player")
    recordingAudio.previousDSP = dsp and dsp:GetString() or "1"
    recordingAudio.active = true
    recordingAudio.desiredDSP = RECORDING_AUDIO_DSP
    recordingAudio.captureWindow = false
    recordingAudio.gunClipUntil = 0
    recordingAudio.gunRecoveryUntil = 0
    recordingAudio.nextEnvironmentUpdate = 0
    recordingAudio.windVolume = 0
    recordingAudio.windPitch = 100
    recordingAudio.engineVolume = 0
    recordingAudio.enginePitch = 100
    ensureRecordingLoops()
    updateLoop(recordingAudio.wind, 0, 100, 0)
    updateLoop(recordingAudio.engine, 0, 100, 0)
    applyPlayerDSPNow(tonumber(recordingAudio.previousDSP) or 1, true)
    updateRecordingAudioEnvironment()
end

local function restoreRecordingAudioFilter()
    if not recordingAudio.active then return end

    endRecordingAudioCaptureWindow()
    stopRecordingLoop(recordingAudio.wind)
    stopRecordingLoop(recordingAudio.engine)
    recordingAudio.wind = nil
    recordingAudio.engine = nil

    local previous = tonumber(recordingAudio.previousDSP) or 1
    RunConsoleCommand("dsp_player", tostring(previous))
    applyPlayerDSPNow(previous, true)

    recordingAudio.active = false
    recordingAudio.previousDSP = "1"
    recordingAudio.desiredDSP = RECORDING_AUDIO_DSP
    recordingAudio.captureWindow = false
    recordingAudio.cameraPos = nil
    recordingAudio.lensCovered = false
    recordingAudio.groundMuffled = false
    recordingAudio.windVolume = 0
    recordingAudio.engineVolume = 0
end

local gunshotIncludePatterns = {
    "gunshot", "firearm", "weapon_fire", "weapons/", ".single", "_single",
    "shoot", "shotgun", "pistol", "rifle", "smg", "sniper", "revolver",
    "explode", "explosion", "grenade"
}
local gunshotExcludePatterns = {
    "reload", "deploy", "holster", "empty", "dryfire", "mag", "bolt",
    "cock", "pump", "shell", "equip", "draw", "pickup", "drop",

    "distant", "distance", "_dist", "/dist", "far", "tail", "echo",
    "reflect", "reverb"
}

local function isClippingSound(data)
    local name = string.lower(tostring(data.OriginalSoundName or data.SoundName or ""))
    if name == "" or string.find(name, "zcity_bodycam/", 1, true) then return false end

    for _, pattern in ipairs(gunshotExcludePatterns) do
        if string.find(name, pattern, 1, true) then return false end
    end

    for _, pattern in ipairs(gunshotIncludePatterns) do
        if string.find(name, pattern, 1, true) then return true end
    end

    local ent = data.Entity
    return IsValid(ent) and ent:IsWeapon() and data.Channel == CHAN_WEAPON
end

hook.Add("EntityEmitSound", "ZCBodycam_RecordMicClipping", function(data)
    if not recordingAudio.active or not cvarAudioRealism:GetBool() then return end
    if not isClippingSound(data) then return end

    local soundName = string.lower(tostring(data.OriginalSoundName or data.SoundName or ""))
    local isExplosion = string.find(soundName, "explo", 1, true) ~= nil
    local origin = data.Pos
    if not isvector(origin) and IsValid(data.Entity) then origin = data.Entity:GetPos() end

    local listener = recordingAudio.cameraPos or EyePos()
    local clipDistance = math.Clamp(cvarAudioClipDistance:GetFloat(), 200, 3000)
    if isExplosion then clipDistance = math.max(clipDistance, 1400) end
    if isvector(origin) and origin:DistToSqr(listener) > (clipDistance * clipDistance) then return end

    local now = SysTime()
    recordingAudio.gunClipUntil = math.max(recordingAudio.gunClipUntil, now + (isExplosion and 0.14 or 0.075))
    recordingAudio.gunRecoveryUntil = math.max(recordingAudio.gunRecoveryUntil, now + (isExplosion and 0.62 or 0.30))



end)

hook.Add("Think", "ZCBodycam_UpdateRecordingAudio", updateRecordingAudioEnvironment)

local function safeFilePart(value)
    value = tostring(value or "unknown")
    value = string.gsub(value, "[^%w_%-]", "_")
    return string.sub(value, 1, 70)
end

local function makeFileName()
    local stamp = os.date("%Y-%m-%d_%H-%M-%S")
    local map = safeFilePart(game.GetMap())
    local steamID = IsValid(LocalPlayer()) and safeFilePart(LocalPlayer():SteamID64()) or "local"
    return "zcity_bodycam_" .. stamp .. "_" .. map .. "_" .. steamID
end

local function calculateDimensions()
    local profile = getCaptureProfile()
    local width = math.Clamp(math.Round(cvarWidth:GetFloat()), 320, profile.maxWidth)
    width = width - (width % 2)

    local screenWidth = math.max(ScrW(), 1)
    local height = math.Round(ScrH() * (width / screenWidth))
    height = math.Clamp(height, 180, 1080)
    height = height - (height % 2)

    return width, height
end

local function sendRecordingFailure(errorText)
    net.Start(Net.ClientFailure)
        net.WriteString(string.sub(tostring(errorText or "unknown error"), 1, 220))
    net.SendToServer()
end

local function resetRecordingState()
    ZCBodycam.Recording = false
    ZCBodycam.RecordingAudio = false
    resetBodycamMotion()
    recording.writer = nil
    recording.active = false
    recording.stopping = false
    recording.startedAt = 0
    recording.captureAfter = 0
    recording.nextFrameAt = 0
    recording.frameInterval = 0
    recording.fileName = nil
    recording.width = 0
    recording.height = 0
    recording.fps = 0
    recording.rt = nil
    recording.rtName = nil
    recording.lastFrameAt = 0
    recording.lastCaptureFrame = -1000
    recording.captureCost = 0
    recording.capturedFrames = 0
end

local function finishRecording()
    if not recording.writer then
        restoreRecordingAudioFilter()
        resetRecordingState()
        return
    end

    local writer = recording.writer
    resetRecordingState()
    pcall(function() writer:Finish() end)
    restoreRecordingAudioFilter()
end

local function ensureCaptureTarget(width, height)
    local targetName = string.format("zc_bodycam_rt_%dx%d", width, height)
    if recording.rt and recording.rtName == targetName then return recording.rt end

    recording.rtName = targetName
    recording.rt = GetRenderTargetEx(
        targetName,
        width,
        height,
        RT_SIZE_OFFSCREEN,
        MATERIAL_RT_DEPTH_SEPARATE,
        bit.bor(2, 256),
        0,
        IMAGE_FORMAT_RGBA8888
    )

    return recording.rt
end

local function startRecording()
    if recording.writer then return true end

    resetBodycamMotion()

    if not video or type(video.Record) ~= "function" then
        sendRecordingFailure("video.Record unavailable")
        return false
    end

    local width, height = calculateDimensions()
    local profile = getCaptureProfile()
    local fps = math.min(math.Clamp(math.Round(cvarFPS:GetFloat()), 10, 60), profile.fps)
    local fileName = makeFileName()

    ensureCaptureTarget(width, height)

    local settings = {
        name = fileName,
        container = "webm",
        video = "vp8",
        audio = "vorbis",
        quality = math.Clamp(cvarQuality:GetFloat(), 0, 1),
        bitrate = math.Clamp(math.Round(cvarBitrate:GetFloat()), 8192, 1048576),
        width = width,
        height = height,
        fps = fps,
        lockfps = false
    }

    local recordOk, writer, errorText = pcall(video.Record, settings)
    if not recordOk then
        errorText = writer
        writer = nil
    end

    if not writer then
        errorText = errorText or "video.Record failed"
        sendRecordingFailure(errorText)
        return false
    end

    local soundOk, soundError = pcall(function()
        writer:SetRecordSound(cvarSound:GetBool())
    end)

    if not soundOk then
        pcall(function() writer:Finish() end)
        sendRecordingFailure(soundError)
        return false
    end

    recording.writer = writer
    recording.active = true
    -- Keep the engine mixer enabled so NPC Voice Chat's 3D channels are included.
    ZCBodycam.Recording = true
    ZCBodycam.RecordingAudio = cvarSound:GetBool()
    recording.stopping = false
    recording.startedAt = SysTime()
    recording.frameInterval = 1 / fps
    recording.captureAfter = recording.startedAt + (Config.WriterWarmup or 0)
    recording.nextFrameAt = recording.captureAfter
    recording.fileName = fileName
    recording.width = width
    recording.height = height
    recording.fps = fps
    recording.lastFrameAt = recording.captureAfter
    recording.lastCaptureFrame = FrameNumber() - 10
    recording.captureCost = 0
    recording.capturedFrames = 0
    applyRecordingAudioFilter()

    return true
end

local function stopRecording()
    if not recording.writer or recording.stopping then return end

    recording.stopping = true
    recording.active = false

    timer.Remove("ZCBodycam_FinalizeRecording")
    timer.Create("ZCBodycam_FinalizeRecording", Config.StopFinalizeDelay, 1, function()
        finishRecording()
    end)
end

local function formatAxonTimestamp()
    local base = os.date("!%Y-%m-%d T%H:%M:%S")
    local milliseconds = math.floor((SysTime() * 1000) % 1000)
    return string.format("%s.%03dZ", base, milliseconds)
end


local function drawShadowedText(text, font, x, y, color, xAlign, yAlign)
    draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 220), xAlign, yAlign)
    draw.SimpleText(text, font, x, y, color, xAlign, yAlign)
end

local function drawWarningTriangle(x, y, size)
    surface.SetDrawColor(240, 212, 49, 255)
    draw.NoTexture()
    surface.DrawPoly({
        {x = x + size * 0.50, y = y},
        {x = x + size, y = y + size * 0.90},
        {x = x, y = y + size * 0.90}
    })

    drawShadowedText("!", "ZCBodycam_RecordMonoSmall", x + size * 0.5, y + size * 0.19, Color(30, 28, 16), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local overlayIconMaterial
local overlayIconPath

local function getOverlayIconMaterial(camera)
    local path = string.Trim((camera and camera.OverlayIcon) or Config.OverlayIcon or Config.ArmorIcon or "")
    if path == "" then return end
    if not file.Exists("materials/" .. path, "GAME") then return end

    if not overlayIconMaterial or overlayIconPath ~= path then
        overlayIconPath = path
        overlayIconMaterial = Material(path, "smooth")
    end

    if overlayIconMaterial and not overlayIconMaterial:IsError() then
        return overlayIconMaterial
    end
end

local function drawAxonOverlayIcon(x, y, size, camera)
    local icon = getOverlayIconMaterial(camera)
    if not icon then
        drawWarningTriangle(x, y, size)
        return
    end

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(icon)
    surface.DrawTexturedRect(x, y, size, size)
end

local function drawAxonCaptureOverlay(width, height, camera)
    local scale = math.max(0.75, width / 854)
    local margin = math.floor(14 * scale)
    local lineGap = math.floor(18 * scale)
    local iconSize = math.floor(36 * scale)
    local iconGap = math.floor(8 * scale)
    local textColor = Color(235, 235, 235, 255)

    local line1 = formatAxonTimestamp()
    local line2 = "AXON FLEX 2 " .. string.Trim(cvarOverlaySerial:GetString() or "X83057575")

    local iconX = width - margin - iconSize
    local iconY = margin - 1
    local textRight = iconX - iconGap

    drawShadowedText(line1, "ZCBodycam_RecordMonoSmall", textRight, margin, textColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    drawShadowedText(line2, "ZCBodycam_RecordMonoSmall", textRight, margin + lineGap, textColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    drawAxonOverlayIcon(iconX, iconY, iconSize, camera)
end

local function drawCaptureOverlay(width, height, cameraType)
    if not cvarOverlay:GetBool() then return end
    drawAxonCaptureOverlay(width, height, getCameraData(cameraType))
end

local function suspendZCityRenderSceneOverride()
    local allHooks = hook.GetTable()
    local renderSceneHooks = allHooks and allHooks.RenderScene
    local callback = renderSceneHooks and renderSceneHooks.jopa
    if not isfunction(callback) then return end

    hook.Remove("RenderScene", "jopa")
    return callback
end

local function restoreZCityRenderSceneOverride(callback)
    if isfunction(callback) then
        hook.Add("RenderScene", "jopa", callback)
    end
end

local function getMinimumCaptureFrameGap()
    return getCaptureProfile().frameGap
end

local function getAdaptiveCaptureInterval()
    local profile = getCaptureProfile()
    local captureFPS = math.min(math.max(recording.fps, 1), profile.fps)
    local interval = 1 / math.max(captureFPS, 1)

    if recording.captureCost > 0 and profile.budget < 1 then
        interval = math.max(interval, recording.captureCost / profile.budget)
    end

    local minimumFPS = math.min(profile.minFPS or captureFPS, captureFPS)
    local slowestInterval = 1 / math.max(minimumFPS, 1)
    return math.Clamp(interval, recording.frameInterval, slowestInterval)
end

local function getCaptureDuration(now)
    local fallback = recording.frameInterval > 0 and recording.frameInterval or (1 / math.max(recording.fps, 1))
    if recording.lastFrameAt <= 0 then return fallback end
    return math.Clamp(now - recording.lastFrameAt, 1 / 240, 0.25)
end

local function captureVideoFrame()
    if not recording.writer or not recording.active then return end

    local captureStartedAt = SysTime()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local view = getBodycamView(ply)
    if not view then return end

    local rt = ensureCaptureTarget(recording.width, recording.height)
    if not rt then
        finishRecording()
        sendRecordingFailure("render target creation failed")
        return
    end



    view.x = 0
    view.y = 0
    view.w = recording.width
    view.h = recording.height
    view.aspect = recording.width / math.max(recording.height, 1)
    view.aspectratio = view.aspect
    view.drawmonitors = false

    local captureDistance = cvarCaptureDistance:GetFloat()
    if captureDistance > 0 then
        view.zfar = math.min(captureDistance, getCaptureProfile().maxDistance)
    end

    render.PushRenderTarget(rt, 0, 0, recording.width, recording.height)
    render.SetScissorRect(0, 0, 0, 0, false)
    render.SetStencilEnable(false)
    render.SetBlend(1)
    render.Clear(0, 0, 0, 255, true, true)
    render.ClearDepth()

    local suspendedRenderScene = suspendZCityRenderSceneOverride()
    renderingBodycamCapture = true
    ZCBodycam.RenderingCapture = true
    local viewOk, viewError = pcall(render.RenderView, view)
    renderingBodycamCapture = false
    ZCBodycam.RenderingCapture = false
    restoreZCityRenderSceneOverride(suspendedRenderScene)



    render.SetScissorRect(0, 0, 0, 0, false)
    render.SetStencilEnable(false)
    render.SetBlend(1)
    render.SetViewPort(0, 0, recording.width, recording.height)

    if not viewOk then
        render.PopRenderTarget()
        finishRecording()
        sendRecordingFailure(viewError)
        return
    end

    cam.Start2D()
        drawCaptureOverlay(recording.width, recording.height, view.zcCameraType)
    cam.End2D()

    local capturedAt = SysTime()
    local frameDuration = getCaptureDuration(capturedAt)
    ensureRecordingAudioMux()
    beginRecordingAudioCaptureWindow()
    local ok, errorText = pcall(function()
        -- The second argument must be true for the video writer to mux the current
        -- engine audio buffer into the frame. With false, the WebM is silent even
        -- when SetRecordSound(true) is enabled.
        recording.writer:AddFrame(frameDuration, true)
    end)
    endRecordingAudioCaptureWindow()

    recording.lastFrameAt = capturedAt
    recording.lastCaptureFrame = FrameNumber()
    recording.capturedFrames = recording.capturedFrames + 1
    render.PopRenderTarget()

    local captureCost = math.max(SysTime() - captureStartedAt, 0)
    if recording.captureCost <= 0 then
        recording.captureCost = captureCost
    else
        recording.captureCost = Lerp(0.12, recording.captureCost, captureCost)
    end

    if not ok then
        finishRecording()
        sendRecordingFailure(errorText)
    end
end

hook.Add("DrawOverlay", "ZCBodycam_CaptureFrames", function()
    if not recording.writer or not recording.active then return end

    local now = SysTime()
    if now < recording.captureAfter or now < recording.nextFrameAt then return end

    local frameGap = FrameNumber() - recording.lastCaptureFrame
    if frameGap < getMinimumCaptureFrameGap() then return end

    captureVideoFrame()

    local interval = getAdaptiveCaptureInterval()
    recording.nextFrameAt = now + interval
end)

net.Receive(Net.Apply, function()
    local state = net.ReadBool()

    if state then
        startRecording()
    else
        stopRecording()
    end
end)

local function syncRecordingWithServer()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if ply:GetNWBool(Config.NetworkBool, false) then
        if not recording.writer then startRecording() end
    elseif recording.writer then
        stopRecording()
    end
end

hook.Add("InitPostEntity", "ZCBodycam_SyncInitialState", function()
    timer.Simple(1, syncRecordingWithServer)
end)

timer.Simple(1, syncRecordingWithServer)

concommand.Add(Config.Command, function()
    if not IsValid(LocalPlayer()) then return end

    registerZManipAnimation()
    net.Start(Net.Request)
    net.SendToServer()
end, nil, "Toggle the Z-City bodycam. Example: bind b zc_bodycam_toggle")

hook.Add("ShutDown", "ZCBodycam_FinishOnShutdown", function()
    timer.Remove("ZCBodycam_FinalizeRecording")
    finishRecording()
    removeAllCustomModels()
end)

hook.Add("OnReloaded", "ZCBodycam_FinishOnLuaReload", function()
    finishRecording()
end)
