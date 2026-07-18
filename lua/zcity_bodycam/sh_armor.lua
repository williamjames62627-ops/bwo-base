ZCBodycam = ZCBodycam or {}

local Config = ZCBodycam.Config
if not Config then return end

local armorDataByType = {}
local spawnmenuRefreshQueued = false

local function cameraData(cameraType)
    return Config.Cameras and Config.Cameras[cameraType]
end

local function cameraTypeFromArmorTable(armors)
    if not istable(armors) then return end

    local equippedKey = armors[Config.ArmorSlot]
    if isstring(equippedKey) then
        return Config.CameraTypeByArmorKey[equippedKey]
    end


    for _, armorKey in pairs(armors) do
        if isstring(armorKey) and Config.CameraTypeByArmorKey[armorKey] then
            return Config.CameraTypeByArmorKey[armorKey]
        end
    end
end

function ZCBodycam.GetEquippedCameraType(ent)
    if not IsValid(ent) then return end

    local direct = cameraTypeFromArmorTable(ent.armors)
    if direct then return direct end

    if type(ent.GetNetVar) == "function" then
        local networked = cameraTypeFromArmorTable(ent:GetNetVar("Armor", nil))
        if networked then return networked end
    end

    if CLIENT then
        local predicted = cameraTypeFromArmorTable(ent.PredictedArmor)
        if predicted then return predicted end
    end

    if CLIENT and Config.EquippedTypeNetworkString then
        local networkedType = ent:GetNWString(Config.EquippedTypeNetworkString, "")
        if networkedType ~= "" and cameraData(networkedType) then
            return networkedType
        end
    end
end

function ZCBodycam.HasEquippedArmor(ent)
    if not Config.RequireEquippedArmor then return true end
    return ZCBodycam.GetEquippedCameraType(ent) ~= nil
end

function ZCBodycam.CharacterHasEquippedArmor(owner, character)
    if ZCBodycam.HasEquippedArmor(owner) then return true end
    if IsValid(character) and character ~= owner then
        return ZCBodycam.HasEquippedArmor(character)
    end
    return false
end

function ZCBodycam.GetCharacterCameraType(owner, character)
    return ZCBodycam.GetEquippedCameraType(owner) or
        (IsValid(character) and ZCBodycam.GetEquippedCameraType(character)) or nil
end

local function makeArmorData(cameraType)
    if armorDataByType[cameraType] then return armorDataByType[cameraType] end

    local camera = cameraData(cameraType)
    if not camera then return end

    local data = {
        Config.ArmorSlot,
        camera.WorldModel or Config.ArmorWorldModel,
        Vector(0, 0, 0),
        Angle(0, 0, 0),

        protection = 0,
        bone = "ValveBiped.Bip01_Spine2",

        model = "",
        femPos = Vector(0, 0, 0),
        scale = 1,
        femscale = 1,
        effect = "Impact",
        surfaceprop = 67,
        mass = camera.Mass or Config.ArmorMass or 0.35,
        ScrappersSlot = "Other",
        norender = true,
        nobonemerge = true,
        ZCBodycamType = cameraType
    }

    armorDataByType[cameraType] = data
    return data
end

local function materialExists(path)
    return CLIENT and isstring(path) and path ~= "" and
        file.Exists("materials/" .. path, "GAME")
end

local function getArmorIcon(cameraType)
    local camera = cameraData(cameraType)
    if not camera then return Config.ArmorFallbackIcon end

    if materialExists(camera.Icon) then
        return camera.Icon
    end

    if materialExists(camera.LegacyIcon) then
        return camera.LegacyIcon
    end

    return Config.ArmorFallbackIcon or camera.Icon
end

local function queueSpawnmenuRefresh()
    if not CLIENT or spawnmenuRefreshQueued or not IsValid(g_SpawnMenu) or g_SpawnMenu:IsVisible() then return end

    spawnmenuRefreshQueued = true
    timer.Simple(0, function()
        spawnmenuRefreshQueued = false
        RunConsoleCommand("spawnmenu_reload")
    end)
end

local function registerSpawnmenuEntry(cameraType, allowRefresh)
    if not CLIENT or not list or type(list.Set) ~= "function" then return false end

    local camera = cameraData(cameraType)
    if not camera then return false end

    local allEntries = type(list.Get) == "function" and list.Get("SpawnableEntities") or nil
    local old = istable(allEntries) and allEntries[camera.EntityClass] or nil
    local icon = getArmorIcon(cameraType)
    local category = camera.Category or Config.ArmorCategory or "ZCity Other"
    local changed = not istable(old) or
        old.Category ~= category or
        old.PrintName ~= camera.Name or
        old.IconOverride ~= icon

    list.Set("SpawnableEntities", camera.EntityClass, {
        PrintName = camera.Name,
        ClassName = camera.EntityClass,
        Category = category,
        AdminOnly = false,
        IconOverride = icon
    })

    if changed and allowRefresh then
        queueSpawnmenuRefresh()
    end

    return true
end

local function registerArmorEntity(cameraType, data)
    local camera = cameraData(cameraType)
    if not camera then return false end

    registerSpawnmenuEntry(cameraType, true)

    if not scripted_ents or type(scripted_ents.Register) ~= "function" then return false end
    if type(scripted_ents.GetStored) == "function" and not scripted_ents.GetStored("armor_base") then
        return false
    end

    local worldModel = camera.WorldModel or Config.ArmorWorldModel
    local armor = {
        Base = "armor_base",
        Type = "anim",
        PrintName = camera.Name,
        Category = camera.Category or Config.ArmorCategory or "ZCity Other",
        Spawnable = true,
        AdminOnly = false,
        IsZPickup = true,

        name = camera.ArmorKey,
        Model = worldModel,
        WorldModel = worldModel,
        PhysModel = worldModel,
        armor = data,
        placement = Config.ArmorSlot,
        IconOverride = getArmorIcon(cameraType),
        ZCBodycamArmor = true,
        ZCBodycamType = cameraType
    }

    if CLIENT then
        armor.Draw = function(self)
            if ZCBodycam and type(ZCBodycam.DrawDroppedBodycam) == "function" then
                ZCBodycam.DrawDroppedBodycam(self, cameraType)
                return
            end

            self:DrawModel()
        end
    end

    scripted_ents.Register(armor, camera.EntityClass)
    registerSpawnmenuEntry(cameraType, true)
    return true
end

function ZCBodycam.RegisterArmorItems()
    if not hg or not istable(hg.armor) then return false end

    hg.armor[Config.ArmorSlot] = hg.armor[Config.ArmorSlot] or {}
    hg.armorNames = hg.armorNames or {}
    hg.armorIcons = hg.armorIcons or {}

    local registeredAny = false

    for _, cameraType in ipairs(Config.CameraOrder or {}) do
        local camera = cameraData(cameraType)
        local data = makeArmorData(cameraType)
        if camera and data then
            hg.armor[Config.ArmorSlot][camera.ArmorKey] = data
            hg.armorNames[camera.ArmorKey] = camera.Name
            hg.armorIcons[camera.ArmorKey] = getArmorIcon(cameraType)

            if CLIENT and language and type(language.Add) == "function" then
                language.Add(camera.ArmorKey, camera.Name)
                language.Add(camera.EntityClass, camera.Name)
            end

            registerArmorEntity(cameraType, data)
            registeredAny = true
        end
    end

    return registeredAny
end


ZCBodycam.RegisterArmorItem = ZCBodycam.RegisterArmorItems

hook.Add("HomigradRun", "ZCBodycam_RegisterArmorAfterZCity", function()
    timer.Simple(0, ZCBodycam.RegisterArmorItems)
end)

hook.Add("Initialize", "ZCBodycam_RegisterArmorInitialize", function()
    timer.Simple(0, ZCBodycam.RegisterArmorItems)
end)

hook.Add("OnReloaded", "ZCBodycam_RegisterArmorReload", function()
    timer.Simple(0, ZCBodycam.RegisterArmorItems)
end)

if CLIENT then
    hook.Add("PopulateEntities", "ZCBodycam_EnsureOtherCategoryEntry", function()
        for _, cameraType in ipairs(Config.CameraOrder or {}) do
            registerSpawnmenuEntry(cameraType, false)
        end
    end)

    concommand.Add("zc_bodycam_refresh_spawnmenu", function()
        for _, cameraType in ipairs(Config.CameraOrder or {}) do
            registerSpawnmenuEntry(cameraType, false)
        end
        RunConsoleCommand("spawnmenu_reload")
    end, nil, "Rebuild the spawnmenu entry for Axon Flex 2.")
end

timer.Create("ZCBodycam_KeepArmorRegistered", 2, 0, function()
    local needsRegistration = false

    for _, cameraType in ipairs(Config.CameraOrder or {}) do
        registerSpawnmenuEntry(cameraType, true)

        local camera = cameraData(cameraType)
        if camera and hg and istable(hg.armor) then
            local slot = hg.armor[Config.ArmorSlot]
            local stored = scripted_ents and scripted_ents.GetStored and
                scripted_ents.GetStored(camera.EntityClass)
            local storedTable = stored and (stored.t or stored)

            if not istable(slot) or slot[camera.ArmorKey] ~= makeArmorData(cameraType) or
                not storedTable or storedTable.ZCBodycamArmor ~= true or
                storedTable.ZCBodycamType ~= cameraType then
                needsRegistration = true
            end
        end
    end

    if needsRegistration then
        ZCBodycam.RegisterArmorItems()
    end
end)

for _, cameraType in ipairs(Config.CameraOrder or {}) do
    registerSpawnmenuEntry(cameraType, false)
    registerArmorEntity(cameraType, makeArmorData(cameraType))
end
ZCBodycam.RegisterArmorItems()
