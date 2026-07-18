CreateConVar("zcitysuffering_threshold", "60", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Minimum pain value to trigger suffering sounds.")
CreateConVar("zcitysuffering_blacklist_classes", "Gordon,headcrabzombie,furry", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Comma-separated list of player classes that are immune to suffering sounds.")
CreateConVar("zcitysuffering_restrictcommunication", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "When 1, suffering players cannot speak and their chat becomes pain screams.")
CreateConVar("zcitysuffering_combineplayerclasses", "Combine,Metrocop", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Comma-separated list of player classes that use combine suffering sounds.")
if not table.HasValue then
    function table.HasValue(tbl, val)
        for _, v in ipairs(tbl) do
            if v == val then return true end
        end
        return false
    end
end
local sufferingBlacklistCache = nil
local combineClassesCache = nil
local function UpdateBlacklistCache()
    local str = GetConVarString("zcitysuffering_blacklist_classes")
    local tbl = {}
    for class in string.gmatch(str, "[^,]+") do
        local trimmed = class:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(tbl, string.lower(trimmed))
        end
    end
    sufferingBlacklistCache = tbl
end
local function UpdateCombineClassesCache()
    local str = GetConVarString("zcitysuffering_combineplayerclasses")
    local tbl = {}
    for class in string.gmatch(str, "[^,]+") do
        local trimmed = class:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(tbl, string.lower(trimmed))
        end
    end
    combineClassesCache = tbl
end
UpdateBlacklistCache()
UpdateCombineClassesCache()

cvars.AddChangeCallback("zcitysuffering_blacklist_classes", function(name, old, new)
    UpdateBlacklistCache()
end)
cvars.AddChangeCallback("zcitysuffering_combineplayerclasses", function(name, old, new)
    UpdateCombineClassesCache()
end)
local function GetBlacklistTable()
    return sufferingBlacklistCache or {}
end
local function GetCombineClassesTable()
    return combineClassesCache or {}
end
local function IsPlayerSuffering(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local org = ply.organism
    if not org then return false end
    local blacklist = GetBlacklistTable()
    local plyClass = string.lower(ply.PlayerClassName or "")
    local plyModel = ply:GetModel() and string.lower(ply:GetModel()) or ""
    local function isBlacklisted(className, modelName)
        for _, banned in ipairs(blacklist) do
            if className == banned then return true end
        end
        return false
    end
    if isBlacklisted(plyClass, plyModel) then
        return false
    end
    local canBreathe = true
    if org.o2 and org.o2[1] then
        canBreathe = org.o2[1] > 15
    end
    local threshold = GetConVarNumber("zcitysuffering_threshold")
    return ply:Alive() and
           not org.otrub and
           org.pain > threshold and
           not ply:IsOnFire() and
           ply:WaterLevel() < 3 and
           canBreathe
end
hook.Add("HG_OnPlayerClassChanged", "SufferingRefreshOnClassChange", function(ply, oldClass, newClass)
    if not IsValid(ply) then return end
    timer.Simple(0, function()
        if IsValid(ply) then
            local isSuff = IsPlayerSuffering(ply)
            ply:SetNWBool("IsSuffering", isSuff)
            if not isSuff then
                stopSufferingSoundImmediate(ply)
            end
        end
    end)
end)
if SERVER then
    local maleSounds   = {}
    local femaleSounds = {}
    local combineSounds = {}
    local soundsAvailable = false
    local fallbackMale   = "vo/npc/male01/pain07.wav"
    local fallbackFemale = "vo/npc/female01/pain09.wav"
    local fallbackCombine = "vo/npc/male01/pain07.wav"
    local function IsSoundFile(fname)
        local ext = string.sub(fname, -4):lower()
        return ext == ".wav" or ext == ".mp3"
    end
    local function RescanSufferingSounds()
        local newMale   = {}
        local newFemale = {}
        local newCombine = {}
        local malePaths = {
            "zcitysuffering/male/",
            "sound/zcitysuffering/male/",
            "zcitysuffering/male",
        }
        local femalePaths = {
            "zcitysuffering/female/",
            "sound/zcitysuffering/female/",
            "zcitysuffering/female",
        }
        local combinePaths = {
            "zcitysuffering/combine/",
            "sound/zcitysuffering/combine/",
            "zcitysuffering/combine",
        }
        for _, path in ipairs(malePaths) do
            local files, _ = file.Find(path .. "*.wav", "GAME")
            if files then
                for _, f in ipairs(files) do
                    if IsSoundFile(f) then
                        local cleanPath = path:gsub("^sound/", "")
                        if cleanPath:sub(-1) ~= "/" then cleanPath = cleanPath .. "/" end
                        table.insert(newMale, cleanPath .. f)
                    end
                end
            end
            local mp3files, _ = file.Find(path .. "*.mp3", "GAME")
            if mp3files then
                for _, f in ipairs(mp3files) do
                    if IsSoundFile(f) then
                        local cleanPath = path:gsub("^sound/", "")
                        if cleanPath:sub(-1) ~= "/" then cleanPath = cleanPath .. "/" end
                        table.insert(newMale, cleanPath .. f)
                    end
                end
            end
        end
        for _, path in ipairs(femalePaths) do
            local files, _ = file.Find(path .. "*.wav", "GAME")
            if files then
                for _, f in ipairs(files) do
                    if IsSoundFile(f) then
                        local cleanPath = path:gsub("^sound/", "")
                        if cleanPath:sub(-1) ~= "/" then cleanPath = cleanPath .. "/" end
                        table.insert(newFemale, cleanPath .. f)
                    end
                end
            end
            local mp3files, _ = file.Find(path .. "*.mp3", "GAME")
            if mp3files then
                for _, f in ipairs(mp3files) do
                    if IsSoundFile(f) then
                        local cleanPath = path:gsub("^sound/", "")
                        if cleanPath:sub(-1) ~= "/" then cleanPath = cleanPath .. "/" end
                        table.insert(newFemale, cleanPath .. f)
                    end
                end
            end
        end
        for _, path in ipairs(combinePaths) do
            local files, _ = file.Find(path .. "*.wav", "GAME")
            if files then
                for _, f in ipairs(files) do
                    if IsSoundFile(f) then
                        local cleanPath = path:gsub("^sound/", "")
                        if cleanPath:sub(-1) ~= "/" then cleanPath = cleanPath .. "/" end
                        table.insert(newCombine, cleanPath .. f)
                    end
                end
            end
            local mp3files, _ = file.Find(path .. "*.mp3", "GAME")
            if mp3files then
                for _, f in ipairs(mp3files) do
                    if IsSoundFile(f) then
                        local cleanPath = path:gsub("^sound/", "")
                        if cleanPath:sub(-1) ~= "/" then cleanPath = cleanPath .. "/" end
                        table.insert(newCombine, cleanPath .. f)
                    end
                end
            end
        end
        local function unique(tbl)
            local seen = {}
            local out = {}
            for _, v in ipairs(tbl) do
                if not seen[v] then
                    seen[v] = true
                    table.insert(out, v)
                end
            end
            return out
        end
        local finalMale = unique(newMale)
        local finalFemale = unique(newFemale)
        local finalCombine = unique(newCombine)
        for i = #maleSounds, 1, -1 do maleSounds[i] = nil end
        for i = #femaleSounds, 1, -1 do femaleSounds[i] = nil end
        for i = #combineSounds, 1, -1 do combineSounds[i] = nil end
        for _, v in ipairs(finalMale) do table.insert(maleSounds, v) end
        for _, v in ipairs(finalFemale) do table.insert(femaleSounds, v) end
        for _, v in ipairs(finalCombine) do table.insert(combineSounds, v) end
        for _, path in ipairs(maleSounds) do util.PrecacheSound(path) end
        for _, path in ipairs(femaleSounds) do util.PrecacheSound(path) end
        for _, path in ipairs(combineSounds) do util.PrecacheSound(path) end
        soundsAvailable = (#maleSounds > 0 or #femaleSounds > 0 or #combineSounds > 0)
    end
    local scanAttempts = 0
    local function AttemptScan()
        RescanSufferingSounds()
        if not soundsAvailable and scanAttempts < 10 then
            scanAttempts = scanAttempts + 1
            timer.Simple(1.0, AttemptScan)
        end
    end
    timer.Simple(0.5, AttemptScan)
    util.PrecacheSound(fallbackMale)
    util.PrecacheSound(fallbackFemale)
    util.PrecacheSound(fallbackCombine)
    local sufferingSounds = {}
    local function stopSufferingSoundImmediate(ply)
        local data = sufferingSounds[ply]
        if data then
            if IsValid(data.ent) then
                data.ent:StopSound(data.soundPath)
            end
            if data.timer then
                timer.Remove(data.timer)
            end
        end
        sufferingSounds[ply] = nil
        if IsValid(ply) then
            ply.lastSufferingSoundTime = 0
            ply:SetNWBool("IsSuffering", false)
        end
    end
    local function checkAndStop(ply)
        local data = sufferingSounds[ply]
        if not data then return end
        if not IsPlayerSuffering(ply) then
            stopSufferingSoundImmediate(ply)
            return
        end
        if data.ent ~= ply then
            stopSufferingSoundImmediate(ply)
            return
        end
    end
    timer.Create("SufferingConditionCheck", 0.1, 0, function()
        for ply, _ in pairs(sufferingSounds) do
            if IsValid(ply) then
                checkAndStop(ply)
            else
                sufferingSounds[ply] = nil
            end
        end
    end)
    timer.Create("ServerSufferingCheck", 0.5, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) then continue end
            local isSuff = IsPlayerSuffering(ply)
            ply:SetNWBool("IsSuffering", isSuff)
            if not isSuff then continue end
            local lastTime = ply.lastSufferingSoundTime or 0
            if CurTime() < lastTime then continue end
            if sufferingSounds[ply] then continue end
            local plyClass = string.lower(ply.PlayerClassName or "")
            local combineClasses = GetCombineClassesTable()
            local isCombine = false
            for _, c in ipairs(combineClasses) do
                if plyClass == c then
                    isCombine = true
                    break
                end
            end
            local isFemale = ThatPlyIsFemale(ply)
            local soundPath
            local useFallback = false
            local soundTable
            if isCombine then
                soundTable = combineSounds
                if #soundTable == 0 then useFallback = true end
            else
                soundTable = isFemale and femaleSounds or maleSounds
                if #soundTable == 0 then useFallback = true end
            end
            if useFallback then
                if isCombine then
                    soundPath = fallbackCombine
                else
                    soundPath = isFemale and fallbackFemale or fallbackMale
                end
            else
                soundPath = soundTable[math.random(1, #soundTable)]
            end
            local muffed = ply.armors and ply.armors["face"] == "mask2"
            local volume = muffed and 65 or 75
            local pitch
            if isCombine and isFemale then
                pitch = 130
            else
                pitch = ply.VoicePitch or 100
            end
            local dsp = muffed and 16 or 0
            if useFallback then
                volume = volume + 5
            end
            ply:EmitSound(soundPath, volume, pitch, 1, CHAN_AUTO, 0, dsp)
            local duration = SoundDuration(soundPath)
            if duration <= 0 then duration = 3 end
            local timerName = "SufferingSoundClear_" .. ply:EntIndex()
            sufferingSounds[ply] = {
                soundPath = soundPath,
                ent = ply,
                timer = timerName
            }
            timer.Create(timerName, duration, 1, function()
                if IsValid(ply) and sufferingSounds[ply] then
                    sufferingSounds[ply] = nil
                end
            end)
            ply.lastSufferingSoundTime = CurTime() + duration + math.random(0.2, 0.3)
        end
    end)
    hook.Add("PlayerDeath", "SufferingStopOnDeath", function(ply)
        if IsValid(ply) then ply:SetNWBool("IsSuffering", false) end
        stopSufferingSoundImmediate(ply)
    end)
    hook.Add("HG_OnOtrub", "SufferingStopOnOtrub", function(ply)
        if IsValid(ply) then ply:SetNWBool("IsSuffering", false) end
        stopSufferingSoundImmediate(ply)
    end)
    hook.Add("OnEntityWaterLevelChanged", "SufferingStopOnWater", function(ent, old, new)
        if ent:IsPlayer() and new >= 3 then
            ent.sufferingLoopEnabled = nil
            if IsValid(ent) then ent:SetNWBool("IsSuffering", false) end
            stopSufferingSoundImmediate(ent)
        end
    end)
    hook.Add("PreHomigradDamage", "SufferingStopOnFire", function(ent, dmgInfo)
        if ent:IsPlayer() and dmgInfo:IsDamageType(DMG_BURN) then
            timer.Simple(0.1, function()
                if IsValid(ent) and ent:IsOnFire() then
                    ent.sufferingLoopEnabled = nil
                    ent:SetNWBool("IsSuffering", false)
                    stopSufferingSoundImmediate(ent)
                end
            end)
        end
    end)
    hook.Add("Fake Up", "SufferingStopOnGetup", function(ply, ragdoll)
        if IsValid(ply) then
            ply:SetNWBool("IsSuffering", false)
            stopSufferingSoundImmediate(ply)
        end
    end)
    hook.Add("Player Spawn", "SufferingStopOnSpawn", function(ply)
        if IsValid(ply) then
            ply:SetNWBool("IsSuffering", false)
            stopSufferingSoundImmediate(ply)
        end
    end)
    hook.Add("PlayerDisconnected", "SufferingCleanup", function(ply)
        stopSufferingSoundImmediate(ply)
    end)
    concommand.Add("zcitysuffering_threshold", function(ply, cmd, args)
        if not IsValid(ply) then return end
        if not ply:IsAdmin() then ply:ChatPrint("No permission.") return end
        if #args < 1 then ply:ChatPrint("Usage: zcitysuffering_threshold <value>") return end
        local value = tonumber(args[1])
        if not value then ply:ChatPrint("Invalid number.") return end
        RunConsoleCommand("zcitysuffering_threshold", tostring(value))
        ply:ChatPrint("Suffering sound threshold set to " .. value)
    end)
    concommand.Add("zcitysuffering_blacklist_classes", function(ply, cmd, args)
        if not IsValid(ply) then return end
        if not ply:IsAdmin() then ply:ChatPrint("No permission.") return end
        local blacklist = GetBlacklistTable()
        if #blacklist == 0 then ply:ChatPrint("No classes blacklisted.")
        else ply:ChatPrint("Blacklisted: " .. table.concat(blacklist, ", ")) end
    end)
    concommand.Add("zcitysuffering_restrictcommunication", function(ply, cmd, args)
        if not IsValid(ply) then return end
        if not ply:IsAdmin() then ply:ChatPrint("No permission.") return end
        if #args < 1 then
            local current = GetConVarNumber("zcitysuffering_restrictcommunication")
            ply:ChatPrint("Current restrictcommunication value: " .. current)
            return
        end
        local val = tonumber(args[1])
        if val ~= 0 and val ~= 1 then
            ply:ChatPrint("Usage: zcitysuffering_restrictcommunication <0|1>")
            return
        end
        RunConsoleCommand("zcitysuffering_restrictcommunication", tostring(val))
        ply:ChatPrint("Suffering communication restriction set to " .. val)
    end)
    concommand.Add("zcitysuffering_combineplayerclasses", function(ply, cmd, args)
        if not IsValid(ply) then return end
        if not ply:IsAdmin() then ply:ChatPrint("No permission.") return end
        if #args == 0 then
            local list = GetCombineClassesTable()
            if #list == 0 then
                ply:ChatPrint("No combine classes set.")
            else
                ply:ChatPrint("Combine classes: " .. table.concat(list, ", "))
            end
            return
        end
        local newList = table.concat(args, ",")
        RunConsoleCommand("zcitysuffering_combineplayerclasses", newList)
        ply:ChatPrint("Combine player classes set to: " .. newList)
    end)
    hook.Add("HG_PlayerSay", "SufferingRestrictChat", function(ply, text)
        if GetConVarNumber("zcitysuffering_restrictcommunication") ~= 1 then return end
        if not IsPlayerSuffering(ply) then return end
        if hg.sharp_pain and #hg.sharp_pain > 0 then
            text[1] = hg.sharp_pain[math.random(#hg.sharp_pain)]
        else
            text[1] = "AAAAAGH!"
        end
    end)
    hook.Add("HG_PlayerCanHearPlayersVoice", "SufferingRestrictVoice", function(listener, speaker)
        if GetConVarNumber("zcitysuffering_restrictcommunication") ~= 1 then return end
        if IsPlayerSuffering(speaker) then
            return false, false
        end
    end)
end
if CLIENT then
    local function IsPlayerSufferingClient(ply)
        return IsValid(ply) and ply:GetNWBool("IsSuffering", false)
    end
    hook.Add("radialOptions", "SufferingRadialOverride", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local isSuff = IsPlayerSufferingClient(ply)
        for i, opt in ipairs(hg.radialOptions) do
            if opt[2] and (string.find(opt[2], "Yell in pain") or string.find(opt[2], "Moan in pain") or string.find(opt[2], "Do Phrase")) then
                if isSuff then
                    local randomSharpPain = hg.sharp_pain and hg.sharp_pain[math.random(#hg.sharp_pain)] or "AAAAAGH"
                    hg.radialOptions[i] = { [1] = function() end, [2] = randomSharpPain, no_submenu = true }
                else
                    if opt._original then
                        opt[1] = opt._original
                        opt[2] = opt._original_text or opt[2]
                        opt.no_submenu = nil
                    end
                end
                break
            end
        end
        if isSuff then
            for i, opt in ipairs(hg.radialOptions) do
                if opt[2] and (string.find(opt[2], "AA") or opt[2] == "Sharppain randomly") then
                    opt.no_submenu = true
                end
            end
        end
    end, 1)
    local function IsLocalPlayerBlacklisted()
        local ply = LocalPlayer()
        if not IsValid(ply) then return false end
        local blacklistStr = GetConVarString("zcitysuffering_blacklist_classes")
        local plyClass = string.lower(ply.PlayerClassName or "")
        local plyModel = string.lower(ply:GetModel() or "")
        for banned in string.gmatch(blacklistStr, "[^,]+") do
            banned = string.lower(banned:match("^%s*(.-)%s*$"))
            if banned ~= "" then
                if plyClass == banned or
                   (plyClass ~= "" and string.find(plyClass, banned, 1, true)) or
                   (plyModel ~= "" and string.find(plyModel, banned, 1, true)) then
                    return true
                end
            end
        end
        return false
    end
    local originalHgPhrase = concommand.GetTable()["hg_phrase"]
    concommand.Add("hg_phrase", function(ply, cmd, args)
        ply = ply or LocalPlayer()
        if not IsValid(ply) then return end
        local isSuff = IsPlayerSufferingClient(ply)
        if isSuff and not IsLocalPlayerBlacklisted() then
            return
        end
        if originalHgPhrase then
            originalHgPhrase(ply, cmd, args)
        else
            local gender = ThatPlyIsFemale(ply) and 2 or 1
            local i = (#args > 0 and math.Clamp(tonumber(args[1]), 1, #phrases[gender])) or math.random(#phrases[gender])
            if #args < 2 and #args ~= 0 then return end
            local num = (#args > 1 and math.Clamp(tonumber(args[2]), phrases[gender][tonumber(i)][3], phrases[gender][tonumber(i)][4])) or math.random(phrases[gender][tonumber(i)][3], phrases[gender][tonumber(i)][4])
            net.Start("hg_phrase")
            net.WriteInt(i, 8)
            net.WriteInt(num, 8)
            net.SendToServer()
        end
    end)
end