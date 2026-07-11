ZombiePrograms = ZombiePrograms or {}

ZombiePrograms.Babe = {}

ZombiePrograms.Babe.Prepare = function(bandit)
    local tasks = {}

    Bandit.ForceStationary(bandit, false)
  
    return {status=true, next="Main", tasks=tasks}
end

ZombiePrograms.Babe.Main = function(bandit)
    local tasks = {}
    local world = getWorld()
    local cm = world:getClimateManager()
    local cell = getCell()

    local master = BanditPlayer.GetMasterPlayer(bandit)
    
    -- update walktype
    local walkType = "Walk"
    local endurance = 0.00
    local vehicle = master:getVehicle()
    local dist = BanditUtils.DistTo(bandit:getX(), bandit:getY(), master:getX(), master:getY())

    if master:isRunning() or master:isSprinting() or vehicle or dist > 10 then
        walkType = "Run"
        endurance = -0.07
    elseif master:isSneaking() and dist < 12 then
        walkType = "SneakWalk"
        endurance = -0.01
    end

    local outOfAmmo = Bandit.IsOutOfAmmo(bandit)
    if master:isAiming() and not outOfAmmo and dist < 8 then
        walkType = "WalkAim"
        endurance = 0
    end

    local health = bandit:getHealth()
    if health < 0.4 then
        walkType = "Limp"
        endurance = 0
    end 
   
    -- fake npc in vehicle 
    if vehicle and vehicle:isDriver(master) then
        local seat = 1
        local pos = BanditUtils.GetSeatPosition(vehicle, seat)
        if pos then

            local bx, by, bz = bandit:getX(), bandit:getY(), bandit:getZ()
            local dist = BanditUtils.DistTo(bx, by, pos.x, pos.y)

            if dist < 1 then
                local brain = BanditBrain.Get(bandit)
                brain.vehicleId = vehicle:getId()
                Bandit.ForceSyncPart(bandit, brain)
                vehicle:getModData().passengerId = brain.id
                bandit:addLineChatElement("I'm in!", 0, 1, 0)
                --[[
                local npcAesthetics = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, false)
                npcAesthetics:setForename("Driver")
                npcAesthetics:setSurname("Driver")
                npcAesthetics:dressInNamedOutfit("Police")

                -- invisible fake driver that replaces babe
                local square = bandit:getSquare()
                local driver = IsoPlayer.new(cell, npcAesthetics, square:getX(), square:getY(), square:getZ())

                driver:setSceneCulled(false)
                driver:setNPC(true)
                driver:setGodMod(true)
                driver:setInvisible(true)
                driver:setGhostMode(true)
                driver:getModData().BWOBID = brain.id
                master:addLineChatElement("I'm in!", 0, 1, 0)

                local vx = driver:getForwardDirection():getX()
                local vy = driver:getForwardDirection():getY()
                local forwardVector = Vector3f.new(vx, vy, 0)
                
                if vehicle:getChunk() then
                    vehicle:setPassenger(seat, driver, forwardVector)
                    driver:setVehicle(vehicle)
                    driver:setCollidable(false)
                end
                ]]

                master:playSound("VehicleDoorOpen")
                bandit:removeFromSquare()
                bandit:removeFromWorld()
            else
                bandit:addLineChatElement("Wait for me!", 0, 1, 0)
                table.insert(tasks, BanditUtils.GetMoveTask(endurance, pos.x, pos.y, pos.z, walkType, dist))
                return {status=true, next="Main", tasks=tasks}
            end
        end
    end

    -- Babe intention is to generally stay with the player
    -- however, if the enemy is close, the babe should engage
    -- but only if player is not too far, kind of a proactive defense.
    if dist < 20 then
        local closestZombie = BanditUtils.GetClosestZombieLocation(bandit)
        local closestBandit = BanditUtils.GetClosestEnemyBanditLocation(bandit)
        local closestEnemy = closestZombie

        if closestBandit.dist < closestZombie.dist then 
            closestEnemy = closestBandit
        end

        if closestEnemy.dist < 8 then
            walkType = "WalkAim"
            table.insert(tasks, BanditUtils.GetMoveTaskTarget(endurance, closestEnemy.x, closestEnemy.y, closestEnemy.z, closestEnemy.id, closestEnemy.player, walkType, closestEnemy.dist))
            --table.insert(tasks, BanditUtils.GetMoveTask(endurance, closestEnemy.x, closestEnemy.y, closestEnemy.z, walkType, closestEnemy.dist))
            return {status=true, next="Main", tasks=tasks}
        end
    end
    
    -- follow the player.


    local dx = master:getX()
    local dy = master:getY()
    local dz = master:getZ()
    local did = BanditUtils.GetCharacterID(master)

    local distTarget = BanditUtils.DistTo(bandit:getX(), bandit:getY(), dx, dy)

    if distTarget > 1 then
        table.insert(tasks, BanditUtils.GetMoveTaskTarget(endurance, dx, dy, dz, did, true, walkType, distTarget))
        return {status=true, next="Main", tasks=tasks}
    else

        local subTasks = BanditPrograms.Idle(bandit)
        if #subTasks > 0 then
            for _, subTask in pairs(subTasks) do
                table.insert(tasks, subTask)
            end
            return {status=true, next="Main", tasks=tasks}
        end
    end

    return {status=true, next="Main", tasks=tasks}
end

ZombiePrograms.Babe.Guard = function(bandit)
    local tasks = {}

    local subTasks = BanditPrograms.Idle(bandit)
    if #subTasks > 0 then
        for _, subTask in pairs(subTasks) do
            table.insert(tasks, subTask)
        end
        return {status=true, next="Guard", tasks=tasks}
    end

    return {status=true, next="Guard", tasks=tasks}
end

ZombiePrograms.Babe.Base = function(bandit)
    local tasks = {}

    local brain = BanditBrain.Get(bandit)
    local bx = bandit:getX()
    local by = bandit:getY()

    local hx = brain.bornCoords.x
    local hy = brain.bornCoords.y
    local hz = brain.bornCoords.z
    
    local walkType = "Walk"
    local endurance = 0

    local dist = BanditUtils.DistTo(bx, by, hx, hy)
    if dist > 2 then
        table.insert(tasks, BanditUtils.GetMoveTask(endurance, hx, hy, hz, walkType, dist, false))
        return {status=true, next="Base", tasks=tasks}
    else
        return {status=true, next="Guard", tasks=tasks}
    end
    return {status=true, next="Base", tasks=tasks}
end
