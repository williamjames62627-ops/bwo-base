ZCBodycam = ZCBodycam or {}

local Config = ZCBodycam.Config
local Net = ZCBodycam.Net

util.AddNetworkString(Net.Request)
util.AddNetworkString(Net.Apply)
util.AddNetworkString(Net.ClientFailure)

local enabled = CreateConVar(
    "zc_bodycam_sv_enabled",
    "1",
    {FCVAR_ARCHIVE, FCVAR_REPLICATED},
    "Allow players to use the Z-City bodycam recorder.",
    0,
    1
)

local function sendState(ply, state)
    if not IsValid(ply) then return end

    net.Start(Net.Apply)
        net.WriteBool(state)
    net.Send(ply)
end

local function timerName(ply)
    return "ZCBodycam_Press_" .. ply:EntIndex()
end

local function deathTimerName(ply)
    return "ZCBodycam_DeathStop_" .. ply:EntIndex()
end

local function getCurrentCharacter(ply)
    if not IsValid(ply) then return end

    if hg and type(hg.GetCurrentCharacter) == "function" then
        local character = hg.GetCurrentCharacter(ply)
        if IsValid(character) and character ~= ply then
            return character
        end
    end



    if not ply:Alive() then
        local deathRagdoll = ply:GetNWEntity("RagdollDeath", NULL)
        if IsValid(deathRagdoll) then return deathRagdoll end
    end

    local fakeRagdoll = ply:GetNWEntity("FakeRagdoll", NULL)
    if IsValid(fakeRagdoll) then return fakeRagdoll end

    return ply
end

local function resolveEquippedCameraType(ply, character)
    if not Config.RequireEquippedArmor then
        return Config.DefaultCameraType
    end

    if type(ZCBodycam.GetEquippedCameraType) ~= "function" then return end

    local cameraType = ZCBodycam.GetEquippedCameraType(ply)
    if cameraType then return cameraType end

    if IsValid(character) and character ~= ply then
        return ZCBodycam.GetEquippedCameraType(character)
    end
end

local function isKnownCameraType(cameraType)
    return isstring(cameraType) and Config.Cameras and Config.Cameras[cameraType] ~= nil
end

local function setMirroredEquipmentState(ent, equipped, cameraType)
    if not IsValid(ent) then return end

    local networkType = cameraType or ""

    if Config.EquippedNetworkBool and
        ent:GetNWBool(Config.EquippedNetworkBool, false) ~= equipped then
        ent:SetNWBool(Config.EquippedNetworkBool, equipped)
    end

    if Config.EquippedTypeNetworkString and
        ent:GetNWString(Config.EquippedTypeNetworkString, "") ~= networkType then
        ent:SetNWString(Config.EquippedTypeNetworkString, networkType)
    end
end

local function syncEquippedState(ply)
    if not IsValid(ply) then return false end

    local now = CurTime()
    local character = getCurrentCharacter(ply)
    local cameraType = resolveEquippedCameraType(ply, character)

    if cameraType then
        ply.ZCBodycamLastEquippedType = cameraType
        ply.ZCBodycamLastEquippedAt = now
    elseif ply:GetNWBool(Config.NetworkBool, false) then
        local deathTailActive = (ply.ZCBodycamDeathStopAt or 0) > now
        local grace = math.max(tonumber(Config.EquipmentTransitionGrace) or 0, 0)
        local transitionActive = grace > 0 and
            (now - (ply.ZCBodycamLastEquippedAt or -math.huge)) <= grace
        local cachedType = ply.ZCBodycamLastEquippedType

        if (deathTailActive or transitionActive) and isKnownCameraType(cachedType) then
            cameraType = cachedType
        end
    end

    local equipped = cameraType ~= nil
    setMirroredEquipmentState(ply, equipped, cameraType)

    if IsValid(character) and character ~= ply then
        setMirroredEquipmentState(character, equipped, cameraType)
    end

    return equipped, cameraType, character
end

ZCBodycam.SyncEquippedState = syncEquippedState

local function invalidatePending(ply)
    if not IsValid(ply) then return end

    ply.ZCBodycamToken = (ply.ZCBodycamToken or 0) + 1
    ply.ZCBodycamPending = nil
    timer.Remove(timerName(ply))
end

local function clearDeathStop(ply)
    if not IsValid(ply) then return end

    ply.ZCBodycamDeathToken = (ply.ZCBodycamDeathToken or 0) + 1
    ply.ZCBodycamDeathStopAt = nil
    timer.Remove(deathTimerName(ply))
end

local function forceStop(ply, tellClient)
    if not IsValid(ply) then return end

    invalidatePending(ply)
    clearDeathStop(ply)

    if ply:GetNWBool(Config.NetworkBool, false) then
        ply:SetNWBool(Config.NetworkBool, false)
        hook.Run("ZCBodycamStateChanged", ply, false, true)
    end

    if tellClient then
        sendState(ply, false)
    end
end

ZCBodycam.ForceStop = forceStop

local function scheduleDeathStop(ply)
    if not IsValid(ply) then return end

    invalidatePending(ply)

    if not ply:GetNWBool(Config.NetworkBool, false) then
        clearDeathStop(ply)
        return
    end

    local delay = math.max(tonumber(Config.DeathRecordingDelay) or 4, 0)
    if delay <= 0 then
        forceStop(ply, true)
        return
    end

    timer.Remove(deathTimerName(ply))
    local token = (ply.ZCBodycamDeathToken or 0) + 1
    ply.ZCBodycamDeathToken = token
    ply.ZCBodycamDeathStopAt = CurTime() + delay


    syncEquippedState(ply)

    timer.Create(deathTimerName(ply), delay, 1, function()
        if not IsValid(ply) or ply.ZCBodycamDeathToken ~= token then return end
        forceStop(ply, true)
    end)
end

local function canToggle(ply)
    if not enabled:GetBool() then return false end
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not ply:Alive() then return false end

    local recording = ply:GetNWBool(Config.NetworkBool, false)
    if not recording and Config.RequireEquippedArmor and not syncEquippedState(ply) then
        return false
    end

    if ply.ZCBodycamPending then return false end
    if (ply.ZCBodycamNextUse or 0) > CurTime() then return false end
    if not hg or type(hg.RunZManipAnim) ~= "function" then return false end

    local character = getCurrentCharacter(ply)
    if IsValid(character) and character ~= ply then return false end

    if hook.Run("ZCBodycamCanUse", ply) == false then return false end
    return true
end

function ZCBodycam.RequestToggle(ply)
    if not canToggle(ply) then return end

    local targetState = not ply:GetNWBool(Config.NetworkBool, false)
    local token = (ply.ZCBodycamToken or 0) + 1

    ply.ZCBodycamToken = token
    ply.ZCBodycamPending = true
    ply.ZCBodycamNextUse = CurTime() + Config.CommandCooldown

    hg.RunZManipAnim(
        ply,
        Config.AnimationName,
        false,
        Config.AnimationDuration,
        {}
    )

    timer.Create(timerName(ply), Config.PressTime, 1, function()
        if not IsValid(ply) or ply.ZCBodycamToken ~= token then return end

        ply.ZCBodycamPending = nil

        if not ply:Alive() then
            forceStop(ply, true)
            return
        end

        local _, cameraType = syncEquippedState(ply)
        if targetState and Config.RequireEquippedArmor and not cameraType then
            forceStop(ply, true)
            return
        end

        clearDeathStop(ply)
        ply:SetNWBool(Config.NetworkBool, targetState)
        sendState(ply, targetState)

        cameraType = cameraType or Config.DefaultCameraType
        local camera = Config.Cameras and Config.Cameras[cameraType]
        local soundPath = targetState and
            ((camera and camera.SoundOn) or Config.SoundOn) or
            ((camera and camera.SoundOff) or Config.SoundOff)

        ply:EmitSound(
            soundPath,
            Config.SoundLevel,
            100,
            1,
            CHAN_AUTO
        )

        hook.Run("ZCBodycamStateChanged", ply, targetState, false)
    end)
end

net.Receive(Net.Request, function(_, ply)
    ZCBodycam.RequestToggle(ply)
end)

net.Receive(Net.ClientFailure, function(_, ply)
    net.ReadString()

    if not ply:GetNWBool(Config.NetworkBool, false) then return end
    forceStop(ply, true)
end)

timer.Create("ZCBodycam_EquippedArmorMonitor", 0.20, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local equipped = syncEquippedState(ply)
        local deathTailActive = (ply.ZCBodycamDeathStopAt or 0) > CurTime()

        if Config.RequireEquippedArmor and
            ply:GetNWBool(Config.NetworkBool, false) and
            not deathTailActive and
            not equipped then
            forceStop(ply, true)
        end
    end
end)

hook.Add("PlayerSay", "ZCBodycam_ChatCommand", function(ply, text)
    local command = string.Trim(string.lower(text or ""))
    if command ~= "!bodycam" and command ~= "/bodycam" then return end

    ZCBodycam.RequestToggle(ply)
    return ""
end)

hook.Add("PlayerInitialSpawn", "ZCBodycam_ResetInitial", function(ply)
    ply:SetNWBool(Config.NetworkBool, false)
    ply.ZCBodycamLastEquippedType = nil
    ply.ZCBodycamLastEquippedAt = nil
    ply.ZCBodycamDeathStopAt = nil

    if Config.EquippedNetworkBool then
        ply:SetNWBool(Config.EquippedNetworkBool, false)
    end
    if Config.EquippedTypeNetworkString then
        ply:SetNWString(Config.EquippedTypeNetworkString, "")
    end
end)

hook.Add("PlayerSpawn", "ZCBodycam_ResetSpawn", function(ply)
    forceStop(ply, true)
    timer.Simple(0, function()
        if IsValid(ply) then syncEquippedState(ply) end
    end)
end)

hook.Add("PlayerDeath", "ZCBodycam_FinishOnDeath", function(ply)
    scheduleDeathStop(ply)
end)

hook.Add("PlayerDisconnected", "ZCBodycam_RemovePending", function(ply)
    invalidatePending(ply)
    clearDeathStop(ply)
end)
