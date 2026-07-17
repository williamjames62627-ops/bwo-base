ZCBodycam = ZCBodycam or {}

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("zcity_bodycam/sh_config.lua")
    AddCSLuaFile("zcity_bodycam/sh_armor.lua")
    AddCSLuaFile("zcity_bodycam/cl_bodycam.lua")

    resource.AddFile("sound/zcity_bodycam/axonbody.mp3")
    resource.AddFile("sound/zcity_bodycam/axonbody_off.mp3")
    resource.AddFile("sound/zcity_bodycam/wind_loop.wav")
    resource.AddFile("sound/zcity_bodycam/engine_hum_loop.wav")

    local materialFiles = {
        "zcity_bodycam/axonbody.png",
        "zcity_bodycam/axon_body.png"
    }

    for _, path in ipairs(materialFiles) do
        if file.Exists("materials/" .. path, "GAME") then
            resource.AddFile("materials/" .. path)
        end
    end
end

include("zcity_bodycam/sh_config.lua")
include("zcity_bodycam/sh_armor.lua")

if SERVER then
    include("zcity_bodycam/sv_bodycam.lua")
else
    include("zcity_bodycam/cl_bodycam.lua")
end
