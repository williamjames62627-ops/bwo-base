ZCBodycam = ZCBodycam or {}
ZCBodycam.Config = ZCBodycam.Config or {}
ZCBodycam.Net = ZCBodycam.Net or {}

local Config = ZCBodycam.Config
local Net = ZCBodycam.Net

Net.Request = "zc_bodycam_request"
Net.Apply = "zc_bodycam_apply"
Net.ClientFailure = "zc_bodycam_client_failure"

Config.Command = "zc_bodycam_toggle"
Config.NetworkBool = "ZCBodycamOn"
Config.EquippedNetworkBool = "ZCBodycamEquipped"
Config.EquippedTypeNetworkString = "ZCBodycamEquippedType"

Config.AnimationName = "zc_bodycam_toggle"
Config.AnimationModel = "models/zmanip/c_zmanipinteract.mdl"
Config.AnimationSequence = "interact"
Config.AnimationDuration = 1.35
Config.PressTime = 0.58
Config.CommandCooldown = 1.6

Config.SoundOn = "zcity_bodycam/axonbody.mp3"
Config.SoundOff = "zcity_bodycam/axonbody_off.mp3"
Config.SoundLevel = 35
Config.WindLoopSound = "zcity_bodycam/wind_loop.wav"
Config.EngineLoopSound = "zcity_bodycam/engine_hum_loop.wav"

Config.ClothingMuffleNetworkBool = "ZCBodycamClothingMuffled"

Config.RequireEquippedArmor = true
Config.ArmorSlot = "bodycam"
Config.ArmorCategory = "ZCity Other"
Config.ArmorFallbackIcon = "icon16/camera.png"
Config.ArmorWorldModel = "models/items/battery.mdl"
Config.ArmorMass = 0.35
Config.DefaultCameraType = "axon_flex_2"

Config.Cameras = {
    axon_flex_2 = {
        Type = "axon_flex_2",
        ArmorKey = "axon_body",
        Name = "Axon Flex 2",
        EntityClass = "ent_armor_axon_body",
        Icon = "zcity_bodycam/axon_body.png",
        LegacyIcon = "zcity_bodycam/axonbody.png",
        OverlayIcon = "zcity_bodycam/axonbody.png",
        ProceduralStyle = "axon",
        ProceduralScale = 0.86,
        CustomModelAllowed = true,
        BodyPosition = Vector(4.1, 8.600000381469727, -0.30),
        BodyAngles = Angle(0, 0, 0),
        ButtonOffset = Vector(-1.0199999809265137, 0.7200000286102295, 0),
        ViewPosition = Vector(0.72, 0.1, 0),
        ViewAngles = Angle(0, 90, 0),
        ViewRoll = 0,
        ViewFOV = 101,
        ViewNear = 0.25,
        OverlayStyle = "axon"
    },
}

Config.CameraOrder = {"axon_flex_2"}
Config.CameraTypeByArmorKey = {}
for cameraType, cameraData in pairs(Config.Cameras) do
    Config.CameraTypeByArmorKey[cameraData.ArmorKey] = cameraType
end


local defaultCamera = Config.Cameras[Config.DefaultCameraType]
Config.ArmorKey = defaultCamera.ArmorKey
Config.ArmorName = defaultCamera.Name
Config.ArmorEntityClass = defaultCamera.EntityClass
Config.ArmorIcon = defaultCamera.Icon
Config.ArmorLegacyIcon = defaultCamera.LegacyIcon
Config.ArmorPlacement = Config.ArmorSlot
Config.ArmorPrintName = defaultCamera.Name
Config.ProceduralScale = defaultCamera.ProceduralScale
Config.OverlayIcon = defaultCamera.OverlayIcon

Config.CustomModel = ""
Config.CustomModelScale = 0.9
Config.ShowWhenOff = true
Config.DrawDistance = 2500

Config.BoneCandidates = {
    "ValveBiped.Bip01_Spine2",
    "ValveBiped.Bip01_Spine4",
    "ValveBiped.Bip01_Spine1"
}

Config.PressFingerBones = {
    "ValveBiped.Bip01_L_Finger12",
    "ValveBiped.Bip01_L_Finger11",
    "ValveBiped.Bip01_L_Finger1"
}
Config.HandFallbackDistance = 3

Config.StopFinalizeDelay = 0.35
Config.WriterWarmup = 0.12




Config.EquipmentTransitionGrace = 2.5


Config.DeathRecordingDelay = 4
