BWOCompatibility = BWOCompatibility or {}

-- compatibility wrappers

local getGameVersion = function()
    return getCore():getGameVersion():getMajor()
end

BWOCompatibility.GetSandboxOptionVars = function(square)
    local vars = {}
    if getGameVersion() >= 42 then
        table.insert (vars, {"KeyLootNew", 0, 0.3})
        table.insert (vars, {"MaximumLooted", 0, 70})
        table.insert (vars, {"FoodLootNew", 1.4, 0.3})
        table.insert (vars, {"CannedFoodLootNew", 1.2, 0.3})
        table.insert (vars, {"LiteratureLootNew", 1.2, 0.3})
        table.insert (vars, {"SurvivalGearsLootNew", 1.2, 0.3})
        table.insert (vars, {"MedicalLootNew", 1.2, 0.3})
        table.insert (vars, {"WeaponLootNew", 1.2, 0.3})
        table.insert (vars, {"RangedWeaponLootNew", 1.2, 0.3})
        table.insert (vars, {"AmmoLootNew", 1.6, 0.5})
        table.insert (vars, {"MechanicsLootNew", 1.2, 0.3})
        table.insert (vars, {"OtherLootNew", 1.2, 0.3})
        table.insert (vars, {"ClothingLootNew", 1.2, 0.3})
        table.insert (vars, {"ContainerLootNew", 1.2, 0.3})
        table.insert (vars, {"MementoLootNew", 1.2, 0.3})
        table.insert (vars, {"MediaLootNew", 1.2, 0.3})
        table.insert (vars, {"CookwareLootNew", 1.2, 0.3})
        table.insert (vars, {"MaterialLootNew", 1.2, 0.3})
        table.insert (vars, {"FarmingLootNew", 1.2, 0.3})
        table.insert (vars, {"ToolLootNew", 1.2, 0.3})
        table.insert (vars, {"MaximumRatIndex", 0, 50})
    else
        table.insert (vars, {"FoodLoot", 1.4, 0.3})
        table.insert (vars, {"CannedFoodLoot", 1.2, 0.3})
        table.insert (vars, {"LiteratureLoot", 1.2, 0.3})
        table.insert (vars, {"SurvivalGearsLoot", 1.2, 0.3})
        table.insert (vars, {"MedicalLoot", 1.2, 0.3})
        table.insert (vars, {"WeaponLoot", 1.2, 0.3})
        table.insert (vars, {"RangedWeaponLoot", 1.2, 0.3})
        table.insert (vars, {"AmmoLoot", 1.6, 0.5})
        table.insert (vars, {"MechanicsLoot", 1.2, 0.3})
        table.insert (vars, {"OtherLoot", 1.2, 0.3})
    end
    return vars
end

BWOCompatibility.GetFlier = function()
    local item
    if getGameVersion() >= 42 then
        item = BanditCompatibility.InstanceItem("Base.Flier")
        item:setName("Flier: CDC URGENT PUBLIC NOTICE")
        local md = item:getModData()
        md.printMedia = "CDC1"
    else
        local txt = "URGENT PUBLIC NOTICE\nIMMEDIATE ACTION REQUIRED\n"
        txt = txt .. "The CDC has declared an imminent contamination hazard in your area. \n\n"
        txt = txt .. "To ensure your safety:\n"
        txt = txt .. "You required to wear approved hazmat suits at all times. \n"
        txt = txt .. "Proceed immediately to underground levels such as basements, shelters, or designated safe zones.\n\n"
        txt = txt .. "Stay alert. Stay protected. Together, we can ensure our safety.\n"
        item = BanditCompatibility.InstanceItem("Base.Notebook")
        item:setName("Flier: CDC URGENT PUBLIC NOTICE")
        item:setCustomName(true)
        item:addPage(1, txt)
    end
    return item
end

BanditCompatibility.HaveRoofFull = function(square)
    if getGameVersion() >= 42 then
        return square:haveRoofFull()
    else
        -- no implementation found
        return true
    end
end

BWOCompatibility.AddVehicle = function(btype, dir, square)
    local vehicle
    if getGameVersion() >= 42 then
        vehicle = addVehicle(btype, square:getX(), square:getY(), square:getZ())
    else
        vehicle = addVehicleDebug(btype, dir, nil, square)
    end
    return vehicle
end

BWOCompatibility.GetCarType = function(carType)
    if getGameVersion() < 42 then
        local map = {}
        map["Base.StepVan_LouisvilleSWAT"] = "Base.PickUpVanLightsPolice"
        if map[carType] then
            return map[carType]
        end
    end
    return carType
end