GM.Bot = {}

GM.Bot.List = {}

GM.Bot.Names = {
	
	[ TEAM_REBEL ] = {
		
		{ name = "Alyx Vance", model = "alyx" },
		{ name = "Arne Magnusson", model = "magnusson" },
		{ name = "Barney Calhoun", model = "barney" },
		{ name = "Dog" },
		{ name = "Eli Vance", model = "eli" },
		{ name = "Father Grigori", model = "monk" },
		{ name = "Gordon Freeman" },
		{ name = "Isaac Kleiner", model = "kleiner" },
		{ name = "Lamarr" },
		{ name = "Laszlo" },
		{ name = "Odessa Cubbage", model = "odessa" },
		{ name = "Uriah" },
		
	},
	[ TEAM_COMBINE ] = {
		
		{ name = "Advisor" },
		{ name = "Civil Protection", model = "police" },
		{ name = "Combine Elite", model = "combineelite" },
		{ name = "Judith Mossman", model = "mossman" },
		{ name = "Metrocop", model = "police" },
		{ name = "Overwatch", model = "policefem" },
		{ name = "Scanner" },
		{ name = "Stalker" },
		{ name = "Strider" },
		{ name = "Synth", model = "stripped" },
		{ name = "Wallace Breen", model = "breen" },
		{ name = "Zombine", model = "zombine" },
		
	},
	
}

GM.Bot.SKILL = {
	
	VERYEASY = 0,
	EASY = 1,
	NORMAL = 2,
	HARD = 3,
	VERYHARD = 4,
	IMPOSSIBLE = 5,
	
}

GM.Bot.Skill = {
	
	[ GM.Bot.SKILL.VERYEASY ] = {
		
		FOV = 40, -- enemy detection field of view
		TurnSpeed = 1, -- aim turn speed when there's no target
		TurnSpeedTarget = 2, -- same as above, but when there's an active target
		TurnSpeedOffTarget = 3, -- same as above, but when the active target hasn't been directly aimed at recently
		TurnSpeedObstructed = 3, -- same as above, but when obstructed by a prop
		TargetCheckRate = 1, -- how often to check for a new target
		TargetForgetTime = 1, -- how long without seeing target to forget about it
		WeaponSwitchRate = 5, -- how often to check if weapon should be switched
		SemiAutoFireRate = 1, -- how fast weapons like the pistol should fire
		ShootOnTargetTime = 5, -- how long after aiming directly at a target to consider them still aimed at
		AimSpread = 40, -- how many degrees of random spread to apply to aiming when there's no target
		AimSpreadTarget = 20, -- same as above, but when there's an active target
		AimSpreadRate = 1, -- how often to generate a new random spread
		ObstructionCheckRate = 1, -- how often to check for props blocking the path
		RoamingChance = 0.2, -- odds of roaming to a random part of the map instead of looking for items
		ChaseMinHealth = 90, -- chase enemies if health is at least this
		
	},
	[ GM.Bot.SKILL.EASY ] = {
		
		FOV = 60,
		TurnSpeed = 2,
		TurnSpeedTarget = 2.5,
		TurnSpeedOffTarget = 4,
		TurnSpeedObstructed = 4,
		TargetCheckRate = 1,
		TargetForgetTime = 2,
		WeaponSwitchRate = 5,
		SemiAutoFireRate = 0.8,
		ShootOnTargetTime = 5,
		AimSpread = 40,
		AimSpreadTarget = 10,
		AimSpreadRate = 1,
		ObstructionCheckRate = 0.5,
		RoamingChance = 0.15,
		ChaseMinHealth = 80,
		
	},
	[ GM.Bot.SKILL.NORMAL ] = {
		
		FOV = 75,
		TurnSpeed = 2,
		TurnSpeedTarget = 4,
		TurnSpeedOffTarget = 5,
		TurnSpeedObstructed = 5,
		TargetCheckRate = 1,
		TargetForgetTime = 3,
		WeaponSwitchRate = 3,
		SemiAutoFireRate = 0.35,
		ShootOnTargetTime = 4,
		AimSpread = 30,
		AimSpreadTarget = 3,
		AimSpreadRate = 1,
		ObstructionCheckRate = 0.1,
		RoamingChance = 0.1,
		ChaseMinHealth = 70,
		
	},
	[ GM.Bot.SKILL.HARD ] = {
		
		FOV = 90,
		TurnSpeed = 2,
		TurnSpeedTarget = 5,
		TurnSpeedOffTarget = 7,
		TurnSpeedObstructed = 30,
		TargetCheckRate = 0.75,
		TargetForgetTime = 3,
		WeaponSwitchRate = 3,
		SemiAutoFireRate = 0.2,
		ShootOnTargetTime = 3,
		AimSpread = 20,
		AimSpreadTarget = 1,
		AimSpreadRate = 1,
		ObstructionCheckRate = 0.1,
		RoamingChance = 0.05,
		ChaseMinHealth = 60,
		
	},
	[ GM.Bot.SKILL.VERYHARD ] = {
		
		FOV = 100,
		TurnSpeed = 3,
		TurnSpeedTarget = 10,
		TurnSpeedOffTarget = 12,
		TurnSpeedObstructed = 50,
		TargetCheckRate = 0.5,
		TargetForgetTime = 3,
		WeaponSwitchRate = 1,
		SemiAutoFireRate = 0.1,
		ShootOnTargetTime = 3,
		AimSpread = 20,
		AimSpreadTarget = 0.7,
		AimSpreadRate = 1,
		ObstructionCheckRate = 0.1,
		RoamingChance = 0.025,
		ChaseMinHealth = 50,
		
	},
	[ GM.Bot.SKILL.IMPOSSIBLE ] = {
		
		FOV = 360,
		TurnSpeed = 2,
		TurnSpeedTarget = 10000,
		TurnSpeedOffTarget = 10000,
		TurnSpeedObstructed = 10000,
		TargetCheckRate = 0.25,
		TargetForgetTime = 3,
		WeaponSwitchRate = 0.1,
		SemiAutoFireRate = 0.05,
		ShootOnTargetTime = 3,
		AimSpread = 0,
		AimSpreadTarget = 0,
		AimSpreadRate = 1,
		ObstructionCheckRate = 0.1,
		RoamingChance = 0.01,
		ChaseMinHealth = 40,
		
	},
	
}

function GM.Bot:GetSkill()
	
	return self.Skill[ math.Clamp( GAMEMODE.CVar.bot_skill:GetInt(), 0, 5 ) ]
	
end

local navspawnclass = {
	
	"info_player_deathmatch",
	"info_player_teamspawn",
	"info_player_terrorist",
	"info_player_counterterrorist",
	"info_player_allies",
	"info_player_axis",
	
}

function GM.Bot:Create( teamid, name, model, forcemodel )
	
	local specialplayermodel = GAMEMODE.CVar.bot_specialplayermodel:GetInt()
	
	if ( navmesh.IsLoaded() ~= true or #navmesh.GetAllNavAreas() == 0 ) and self.HasWarnedAboutNav ~= true then
		
		local msg
		if GAMEMODE.CVar.bot_generatenav:GetBool() == true then
			
			msg = "This map has no navmesh, beginning automatic generation."
			
			--navmesh.ClearWalkableSeeds()
			
			--[[
			local rspawn = team.GetSpawnPoints( TEAM_REBEL )
			if rspawn ~= nil then
				
				for k, v in ipairs( rspawn ) do
					
					if IsValid( v ) == true then navmesh.AddWalkableSeed( v:GetPos(), Vector( 0, 0, 1 ) ) end
					
				end
				
			end
			
			local cspawn = team.GetSpawnPoints( TEAM_COMBINE )
			if cspawn ~= nil then
				
				for k, v in ipairs( cspawn ) do
					
					if IsValid( v ) == true then navmesh.AddWalkableSeed( v:GetPos(), Vector( 0, 0, 1 ) ) end
					
				end
				
			end
			]]--
			
			for k, v in ipairs( navspawnclass ) do
				
				for k_, v_ in ipairs( ents.FindByClass( v ) ) do navmesh.AddWalkableSeed( v_:GetPos(), Vector( 0, 0, 1 ) ) end
				
			end
			
			navmesh.BeginGeneration()
			
		else
			
			msg = "!!!!!\nWarning: This map has no navmesh, bots will not be able to move properly!\n!!!!!"
			
		end
		
		print( msg )
		PrintMessage( HUD_PRINTTALK, msg )
		self.HasWarnedAboutNav = true
		
	end
	
	if teamid == nil then
		
		local botteam = GAMEMODE.CVar.bot_team:GetInt()
		if botteam == 1 then teamid = TEAM_REBEL
		elseif botteam == 2 then teamid = TEAM_COMBINE
		else teamid = team.NumPlayers( TEAM_REBEL ) >= team.NumPlayers( TEAM_COMBINE ) and TEAM_COMBINE or TEAM_REBEL end
		
	end
	
	if name == nil then
		
		local names = self.Names[ teamid ] or self.Names[ TEAM_COMBINE ]
		
		local plys = player.GetAll()
		
		-- try to find an unused name
		local nameid = math.random( #names )
		for i = 0, #names - 1 do
			
			local namefree = true
			
			local index = ( ( nameid + i - 1 ) % #names ) + 1
			
			local n = names[ index ]
			for k, v in ipairs( plys ) do if v:Nick() == n.name .. " (Bot)" then namefree = false break end end
			
			if namefree == true then nameid = index break end
			
		end
		name = names[ nameid ].name
		if model == nil and specialplayermodel > 0 then model = names[ nameid ].model end
		
	end
	
	local bot = player.CreateNextBot( name .. " (Bot)" )
	if IsValid( bot ) ~= true then return end
	
	bot.HL2MP_BotData = {
		
		Bot = bot,
		PlayerColor = Vector( math.random(), math.random(), math.random() ),
		WeaponColor = Vector( math.random(), math.random(), math.random() ),
		GetSkill = function() return self:GetSkill() end,
		
	}
	bot.HL2MP_ForceTeam = teamid
	
	local allplayermodels = GAMEMODE.CVar.bot_allplayermodels:GetBool()
	
	if allplayermodels == true or specialplayermodel > 1 then forcemodel = true end
	
	if model ~= nil then
		
		if forcemodel == true then bot.HL2MP_ForcePlayerModel = model
		elseif specialplayermodel == 1 and GAMEMODE.ModelTeam[ model ] == teamid then
			
			bot.HL2MP_ForcePlayerModel = model
			
		end
		
	end
	
	if bot.HL2MP_ForcePlayerModel == nil then
		
		if GAMEMODE.CVar.bot_allplayermodels:GetBool() == true then
			
			local models = {}
			for k, v in pairs( player_manager.AllValidModels() ) do table.insert( models, k ) end
			bot.HL2MP_ForcePlayerModel = models[ math.random( #models ) ]
			
		else
			
			local models = teamid == TEAM_REBEL and GAMEMODE.Models_Rebel or GAMEMODE.Models_Combine
			bot.HL2MP_ForcePlayerModel = models[ math.random( #models ) ]
			
		end
		
	end
	
	table.insert( self.List, bot )
	
	GAMEMODE:PlayerSetTeamModel( bot )
	bot:KillSilent()
	bot:Spawn()
	
	--bot:SetFOV( bot.HL2MP_BotData:GetSkill().FOV, 0, game.GetWorld() )
	bot:SetFOV( 90, 0, game.GetWorld() )
	
	return bot
	
end

function GM.Bot:Kick( bot, reason )
	
	bot = bot or self.List[ #self.List ]
	if IsValid( bot ) ~= true then return end
	
	table.RemoveByValue( self.List, bot )
	bot:Kick( reason )
	
	return bot
	
end



function GM.Bot:CheckVisible( bot, target )
	
	local tpos = target:GetPos() + target:OBBCenter()
	local tdir = ( tpos - bot:EyePos() ):GetNormalized()
	if bot:GetAimVector():Dot( tdir ) < 1 - ( bot.HL2MP_BotData:GetSkill().FOV / 180 ) then return false end
	
	return bot:Visible( target )
	
end

function GM.Bot:GetTarget( bot )
	
	local targets
	if GAMEMODE.CVar.teamplay:GetBool() == true then targets = team.GetPlayers( bot:Team() == TEAM_REBEL and TEAM_COMBINE or TEAM_REBEL )
	else targets = player.GetAll() end
	
	local pos = bot:GetPos()
	
	local target
	local dist
	
	--find the nearest visible target
	for k, v in pairs( targets ) do
		
		if v ~= bot and GAMEMODE:IsPlayerAlive( v ) == true and self:CheckVisible( bot, v ) == true then
			
			local d = pos:DistToSqr( v:GetPos() )
			if dist == nil or d < dist then
				
				target = v
				dist = d
				
			end
			
		end
		
	end
	
	return target
	
end

function GM.Bot:HandleTarget( bot, cmd )
	
	local curtime = CurTime()
	
	local data = bot.HL2MP_BotData
	if data.LastTargetCheck ~= nil and curtime < data.LastTargetCheck + 1 then return end
	
	if IsValid( data.Target ) ~= true then
		
		data.Target = self:GetTarget( bot )
		if IsValid( data.Target ) == true then data.LastOnTarget = nil end
		
	elseif GAMEMODE:IsPlayerAlive( data.Target ) ~= true then
		
		data.Target = nil
		data.LastOnTarget = nil
		
	elseif self:CheckVisible( bot, data.Target ) ~= true then
		
		data.Target = nil
		
	end
	
	data.LastTargetCheck = curtime
	
end



GM.Bot.WeaponPriority = {
	
	"weapon_egon",
	"weapon_snark",
	"weapon_rpg",
	"weapon_rpg_hl1",
	"weapon_357",
	"weapon_357_hl1",
	"weapon_gauss",
	"weapon_crossbow",
	"weapon_crossbow_hl1",
	"weapon_ar2",
	"weapon_smg1",
	"weapon_mp5_hl1",
	"weapon_pistol",
	"weapon_glock_hl1",
	"weapon_hornetgun",
	"weapon_crowbar",
	"weapon_stunstick",
	"weapon_crowbar_hl1",
	
}

GM.Bot.ShotgunWeapons = {
	
	"weapon_shotgun",
	"weapon_shotgun_hl1",
	
}
GM.Bot.IsShotgunWeapon = {}
for k, v in ipairs( GM.Bot.ShotgunWeapons ) do GM.Bot.IsShotgunWeapon[ v ] = true end

GM.Bot.MeleeWeapons = {
	
	"weapon_crowbar",
	"weapon_stunstick",
	"weapon_crowbar_hl1",
	
}
GM.Bot.IsMeleeWeapon = {}
for k, v in ipairs( GM.Bot.MeleeWeapons ) do GM.Bot.IsMeleeWeapon[ v ] = true end

GM.Bot.ShotgunDistance = 256
GM.Bot.MeleeDistance = 96



function GM.Bot:HandleWeapon( bot, cmd )
	
	local data = bot.HL2MP_BotData
	
	local curtime = CurTime()
	
	if IsValid( data.ObstructionTarget ) == true then
		
		if data.ObstructionDoor == true then
			
			-- try to open doors
			if data.LastDoorUse == nil or curtime > data.LastDoorUse + 1 then
				
				cmd:AddKey( IN_USE )
				data.LastDoorUse = curtime
				
			end
			
		else
			
			-- try to push away obstructions
			local wep = bot:GetWeapon( "weapon_physcannon" )
			for k, v in ipairs( self.MeleeWeapons ) do
				
				if IsValid( wep ) == true then break end
				wep = bot:GetWeapon( v )
				
			end
			if IsValid( wep ) == true then
				
				if bot:GetActiveWeapon() ~= wep then cmd:SelectWeapon( wep ) end
				cmd:AddKey( IN_ATTACK )
				
				local pos = data.ObstructionTarget:GetPos() + data.ObstructionTarget:OBBCenter()
				
				data.AimTargetAng = ( pos - bot:EyePos() ):Angle()
				
				data.LastWeaponSwitch = nil -- force a weapon switch as early as possible
				
				return
				
			end
			
		end
		
	end
	
	local skill = data:GetSkill()
	
	local forgot = data.LastHadTarget == nil or curtime > data.LastHadTarget + skill.TargetForgetTime
	
	if forgot ~= true and data.TargetLastPos ~= nil then data.AimTargetAng = ( data.TargetLastPos - bot:EyePos() ):Angle() end
	
	local hastarget = IsValid( data.Target )
	
	if data.LastWeaponSwitch == nil or curtime > data.LastWeaponSwitch + skill.WeaponSwitchRate then
		
		local shotgun
		for k, v in ipairs( self.ShotgunWeapons ) do
			
			shotgun = bot:GetWeapon( v )
			if IsValid( shotgun ) == true then break end
			
		end
		
		if IsValid( shotgun ) == true and shotgun:HasAmmo() == true and hastarget == true and data.Target:GetPos():DistToSqr( bot:GetShootPos() ) <= self.ShotgunDistance ^ 2 then
			
			cmd:SelectWeapon( shotgun )
			
		else
			
			for k, v in ipairs( self.WeaponPriority ) do
				
				local wep = bot:GetWeapon( v )
				if IsValid( wep ) == true and wep:HasAmmo() == true then cmd:SelectWeapon( wep ) break end
				
			end
			
		end
		
		data.LastWeaponSwitch = curtime
		
	end
	
	local wep = bot:GetActiveWeapon()
	if IsValid( wep ) ~= true then return end
	
	local class = wep:GetClass()
	
	local tr = bot:GetEyeTrace()
	
	-- don't shoot unless the target has been aimed at recently
	-- (so they don't shoot the rpg into a wall when they start targeting an enemy that shot them from behind)
	if hastarget == true and tr.Entity == data.Target then
		
		if self.IsMeleeWeapon[ class ] ~= true or tr.HitPos:DistToSqr( tr.StartPos ) <= self.MeleeDistance ^ 2 then
			
			data.LastOnTarget = curtime
			
		end
		
	end
	local ontarget = data.LastOnTarget ~= nil and curtime < data.LastOnTarget + skill.ShootOnTargetTime
	
	if hastarget == true and ontarget == true and bot:GetAmmoCount( wep:GetSecondaryAmmoType() ) > 0 then cmd:AddKey( IN_ATTACK2 ) end
	
	-- manually tap the pistol otherwise it shoots slow
	local semirate = skill.SemiAutoFireRate
	local holdfire = class ~= "weapon_pistol" or curtime % semirate < semirate / 2
	
	if hastarget == true and ontarget == true and holdfire == true then cmd:AddKey( IN_ATTACK )
	elseif forgot == true and wep:Clip1() < wep:GetMaxClip1() then cmd:AddKey( IN_RELOAD ) end
	
end

function GM.Bot:HandleAimSpread( bot, cmd )
	
	local curtime = CurTime()
	
	local data = bot.HL2MP_BotData
	local skill = data:GetSkill()
	
	if data.AimSpread ~= nil and data.LastAimSpreadTime ~= nil and curtime < data.LastAimSpreadTime + skill.AimSpreadRate then return end
	
	data.LastAimSpreadTime = curtime
	
	local forgot = data.LastHadTarget == nil or curtime > data.LastHadTarget + skill.TargetForgetTime
	
	local spread = forgot ~= true and skill.AimSpreadTarget or skill.AimSpread
	data.AimSpread = Angle( math.random( -spread, spread ) / 4, math.random( -spread, spread ), 0 )
	
end



local stepheight = 32
local jumpheight = 512
local jumppenalty = 5
local deathheight = 2000
local maxage = 20
local chaseage = 1

local function pathgen( area, from, ladder, elevator, length )
	
	if IsValid( from ) ~= true then return 0 end
	
	local dist = 0
	
	if IsValid( ladder ) == true then dist = ladder:GetLength()
	elseif length > 0 then dist = length
	else dist = ( area:GetCenter() - from:GetCenter() ):GetLength() end
	
	local cost = dist + from:GetCostSoFar()
	
	local z = from:ComputeAdjacentConnectionHeightChange( area )
	if z >= stepheight then
		
		if z >= jumpheight then return -1 end
		
		cost = cost + ( jumppenalty * dist )
		
	elseif z < -deathheight then return -1 end
	
	return cost
	
end

local function shouldtargetammo( ammo )
	
	return function( bot )
		
		if GAMEMODE.CVar.limitammo:GetBool() == false then return true end
		
		local ammoid = game.GetAmmoID( ammo )
		
		return bot:GetAmmoCount( ammoid ) < game.GetAmmoMax( ammoid )
		
	end
	
end
GM.Bot.ShouldTargetItem = {
	
	-- HL2
	[ "item_ammo_ar2" ] = shouldtargetammo( "AR2" ),
	[ "item_ammo_ar2_large" ] = shouldtargetammo( "AR2" ),
	[ "item_ammo_ar2_altfire" ] = shouldtargetammo( "AR2AltFire" ),
	[ "item_ammo_pistol" ] = shouldtargetammo( "Pistol" ),
	[ "item_ammo_smg1" ] = shouldtargetammo( "SMG1" ),
	[ "item_ammo_357" ] = shouldtargetammo( "357" ),
	[ "item_ammo_crossbow" ] = shouldtargetammo( "XBowBolt" ),
	[ "item_box_buckshot" ] = shouldtargetammo( "Buckshot" ),
	[ "item_rpg_round" ] = shouldtargetammo( "RPG_Round" ),
	[ "item_ammo_smg1_grenade" ] = shouldtargetammo( "SMG1_Grenade" ),
	
	[ "item_healthkit" ] = function( bot ) return bot:Health() < bot:GetMaxHealth() end,
	[ "item_healthvial" ] = function( bot ) return bot:Health() < bot:GetMaxHealth() end,
	[ "item_battery" ] = function( bot ) return bot:Armor() < bot:GetMaxArmor() end,
	
	-- HL1
	[ "ammo_357" ] = shouldtargetammo( "357Round" ),
	[ "ammo_crossbow" ] = shouldtargetammo( "XBoxBoltHL1" ),
	[ "ammo_glockclip" ] = shouldtargetammo( "9mmRound" ),
	[ "ammo_9mmbox" ] = shouldtargetammo( "9mmRound" ),
	[ "ammo_mp5clip" ] = shouldtargetammo( "9mmRound" ),
	[ "ammo_mp5grenades" ] = shouldtargetammo( "MP5_Grenade" ),
	[ "ammo_rpgclip" ] = shouldtargetammo( "RPG_Rocket" ),
	[ "ammo_buckshot" ] = shouldtargetammo( "BuckshotHL1" ),
	[ "ammo_gaussclip" ] = shouldtargetammo( "Uranium" ),
	
}

local function hasnav( pos )
	
	--return navmesh.GetNavArea( pos, 32 ) ~= nil
	
	local area = navmesh.GetNearestNavArea( pos, false, 64, false, true )
	
	return area ~= nil and math.abs( area:GetZ( pos ) - pos.z ) <= 32
	
end

function GM.Bot:GetItemTarget( bot )
	
	local pos = bot:GetPos()
	
	local target
	local dist
	
	-- look for ammo and health if necessary
	local items = ents.FindByClass( "item_*" )
	for k, v in ipairs( items ) do
		
		local shouldtarget = self.ShouldTargetItem[ v:GetClass() ]
		if IsValid( v:GetOwner() ) ~= true and shouldtarget ~= nil and shouldtarget( bot ) == true then
			
			local vpos = v:GetPos()
			local d = pos:DistToSqr( vpos )
			if dist == nil or d < dist then
				
				if hasnav( vpos ) == true then
					
					target = v
					dist = d
					
				end
				
			end
			
		end
		
	end
	
	-- search for weapons the bot doesn't already own
	local weapons = ents.FindByClass( "weapon_*" )
	for k, v in ipairs( weapons ) do
		
		if IsValid( v:GetOwner() ) ~= true and v:IsWeapon() == true and bot:HasWeapon( v:GetClass() ) ~= true then
			
			local vpos = v:GetPos()
			local d = pos:DistToSqr( vpos )
			if dist == nil or d < dist then
				
				if hasnav( vpos ) == true then
					
					target = v
					dist = d
					
				end
				
			end
			
		end
		
	end
	
	return target
	
	--[[
	local items = table.Add( ents.FindByClass( "item_*" ), ents.FindByClass( "weapon_*" ) )
	
	return items[ math.random( #items ) ]
	]]--
	
end

local doorclass = {
	
	[ "func_door" ] = true,
	[ "func_door_rotating" ] = true,
	[ "prop_door_rotating" ] = true,
	
}

function GM.Bot:GetObstructionTarget( bot, dir )
	
	local add = Vector( 2, 2, 2 )
	local pos = bot:GetPos()
	
	local tr = util.TraceHull( {
		
		start = pos,
		endpos = pos + dir,
		mins = bot:OBBMins() - add,
		maxs = bot:OBBMaxs() + add,
		--[[
		filter = function( ent )
			
			if ent == bot then return false end
			if ent:IsPlayer() == true then return false end
			if ent:Health() <= 0 and ( ent:IsFlagSet( FL_FROZEN ) == true or ent:GetMoveType() ~= MOVETYPE_VPHYSICS or IsValid( ent:GetPhysicsObject() ) ~= true ) then return false end
			
			return true
			
		end,
		]]--
		--filter = bot,
		filter = function( ent )
			
			return ent:IsPlayer() ~= true and ent:GetOwner() ~= bot and ( ent:Health() > 0 or ent:GetMoveType() == MOVETYPE_VPHYSICS )
			
		end,
		ignoreworld = true,
		
	} )
	if IsValid( tr.Entity ) == true then return tr.Entity, false end
	
	add = Vector( 1, 1, 1 )
	
	local tr = util.TraceHull( {
		
		start = pos,
		endpos = pos + dir,
		mins = bot:OBBMins() - add,
		maxs = bot:OBBMaxs() + add,
		filter = function( ent )
			
			return doorclass[ ent:GetClass() ] == true
			
		end,
		ignoreworld = true,
		
	} )
	if IsValid( tr.Entity ) == true then return tr.Entity, true end
	
end

function GM.Bot:HandleMovement( bot, cmd )
	
	local data = bot.HL2MP_BotData
	local skill = data:GetSkill()
	
	if IsValid( data.ItemTarget ) ~= true then
		
		data.ItemTarget = self:GetItemTarget( bot )
		if IsValid( data.ItemTarget ) == true then self.Path = nil end
		
	elseif IsValid( data.ItemTarget:GetOwner() ) == true then
		
		data.ItemTarget = nil
		
	end
	
	local chase = IsValid( data.Target ) == true and bot:Health() >= skill.ChaseMinHealth
	if IsValid( data.Path ) ~= true or data.Path:GetAge() >= ( chase == true and chaseage or maxage ) then
		
		if chase == true then
			
			local tol = 256
			local wep = bot:GetActiveWeapon()
			local class
			if IsValid( wep ) == true then class = wep:GetClass() end
			if self.IsMeleeWeapon[ class ] == true then tol = 32 end
			
			data.Path = Path( "Follow" )
			data.Path:SetGoalTolerance( tol )
			data.Path:Compute( bot, data.TargetLastPos, pathgen )
			
		elseif IsValid( data.ItemTarget ) == true and math.random() >= skill.RoamingChance then
			
			data.Path = Path( "Follow" )
			data.Path:SetGoalTolerance( 32 )
			data.Path:Compute( bot, data.ItemTarget:GetPos(), pathgen )
			
		else
			
			local areas = navmesh.GetAllNavAreas()
			local area = areas[ math.random( #areas ) ]
			if IsValid( area ) == true then
				
				data.Path = Path( "Follow" )
				data.Path:SetGoalTolerance( 32 )
				data.Path:Compute( bot, area:GetRandomPoint(), pathgen )
				
			end
			
		end
		
	elseif IsValid( data.Path ) == true then
		
		local curtime = CurTime()
		
		local age = data.Path:GetAge()
		
		local pos = bot:GetPos()
		
		local goal = data.Path:GetCurrentGoal()
		
		local dist = pos:DistToSqr( goal.pos )
		
		if bot:GetMoveType() == MOVETYPE_LADDER then
			
			if data.LadderTime == nil then
				
				data.LadderTime = curtime
				data.LadderPos = pos
				
			elseif curtime > data.LadderTime + 1 then
				
				if pos == data.LadderPos then cmd:AddKey( IN_JUMP ) end
				data.LadderTime = curtime
				data.LadderPos = pos
				
			end
			
			data.AimTargetAng = goal.forward:Angle()
			cmd:SetForwardMove( 1000 )
			cmd:AddKey( IN_FORWARD )
			
			data.Path:Update( bot )
			
			return
			
		else
			
			data.LadderPos = nil
			data.LadderTime = nil
			
		end
		
		local viewang = dist > 16 ^ 2 and ( goal.pos - pos ):Angle() or Angle( 0, 0, 0 )
		
		cmd:SetViewAngles( viewang )
		cmd:SetForwardMove( 1000 + ( math.cos( age * 4 ) * 1050 ) )
		cmd:SetSideMove( math.sin( age * 5 ) * 500 )
		
		if IsValid( goal.area ) == true and goal.area:HasAttributes( NAV_MESH_CROUCH ) == true then cmd:AddKey( IN_DUCK ) end
		
		if goal.type >= 1 and goal.type <= 3 and bot:IsOnGround() == true and age % 2 < 1 then data.LastJump = curtime cmd:AddKey( IN_JUMP )
		else viewang.p = 0 end
		
		local onground = bot:IsOnGround()
		if onground == true then data.LastOnGround = curtime end
		
		if onground ~= true and ( ( data.LastOnGround ~= nil and curtime > data.LastOnGround + 0.25 ) or ( data.LastJump ~= nil and curtime < data.LastJump + 0.25 ) ) then cmd:AddKey( IN_DUCK )
		elseif ( curtime - ( data.SpawnTime or 0 ) ) % 20 < 4 and ( GAMEMODE.CVar.aux:GetBool() ~= true or bot:GetAUX() > 20 ) then cmd:AddKey( IN_SPEED ) end
		
		--data.Path:Draw()
		data.Path:Update( bot )
		
		local tol = data.Path:GetGoalTolerance()
		local lastseg = data.Path:LastSegment()
		if lastseg ~= nil and goal.distanceFromStart == lastseg.distanceFromStart and bot:GetPos():DistToSqr( goal.pos ) < tol * tol then data.Path:Invalidate() end
		
		if data.AimTargetAng == nil then data.AimTargetAng = viewang end
		
		-- check for obstructions
		if data.LastObstructionCheck == nil or curtime > data.LastObstructionCheck + skill.ObstructionCheckRate then
			
			data.LastObstructionCheck = curtime
			
			data.ObstructionTarget, data.ObstructionDoor = self:GetObstructionTarget( bot, viewang:Forward() )
			
		end
		
	end
	
end



function GM.Bot:StartCommand( bot, cmd )
	
	cmd:ClearMovement()
	cmd:ClearButtons()
	
	if GAMEMODE:IsPlayerAlive( bot ) ~= true or bot:IsFrozen() == true then return end
	
	local curtime = CurTime()
	
	local data = bot.HL2MP_BotData
	
	data.AimTargetAng = nil
	
	self:HandleTarget( bot, cmd )
	
	local hastarget = IsValid( data.Target )
	if hastarget == true then
		
		data.TargetLastPos = data.Target:GetPos() + data.Target:OBBCenter()
		data.LastHadTarget = curtime
		
	end
	
	self:HandleWeapon( bot, cmd )
	
	self:HandleAimSpread( bot, cmd )
	
	self:HandleMovement( bot, cmd )
	
	if data.AimTargetAng ~= nil then
		
		local ang = data.AimTargetAng
		local curang = bot:EyeAngles()
		
		local skill = data:GetSkill()
		
		local turnspeed = skill.TurnSpeed
		if IsValid( data.ObstructionTarget ) == true then turnspeed = skill.TurnSpeedObstructed
		elseif hastarget == true then
			
			local ontarget = data.LastOnTarget ~= nil and curtime < data.LastOnTarget + skill.ShootOnTargetTime
			turnspeed = ontarget == true and skill.TurnSpeedTarget or skill.TurnSpeedOffTarget
			
		end
		
		local eyeang = LerpAngle( math.Clamp( turnspeed * FrameTime(), 0, 1 ), curang, ang + data.AimSpread )
		eyeang.p = math.Clamp( eyeang.p, -89, 89 )
		
		bot:SetEyeAngles( eyeang )
		
	end
	
	local spawntime = curtime - data.SpawnTime
	if spawntime < 1 and bot:GetMoveType() == MOVETYPE_LADDER and spawntime % 0.5 < 0.25 then
		
		-- mash the jump key in case a bot dies on a ladder and gets stuck for some reason?
		cmd:AddKey( IN_JUMP )
		
	end
	
end



local enemyteam = {
	
	[ TEAM_REBEL ] = TEAM_COMBINE,
	[ TEAM_COMBINE ] = TEAM_REBEL,
	
}

local lastcreate = -9999

function GM.Bot:Think()
	
	for i = #self.List, 1, -1 do
		
		local bot = self.List[ i ]
		if IsValid( bot ) ~= true then table.remove( self.List, i )
		elseif bot:Alive() ~= true then
			
			bot.HL2MP_BotData.Path = nil
			bot.HL2MP_BotData.LastOnGround = nil
			
			GAMEMODE:PlayerDeathThink( bot ) -- dead bots don't call this for some reason
			
		end
		
	end
	
	local botteam = GAMEMODE.CVar.bot_team:GetInt()
	local forceteam
	if botteam == 1 then forceteam = TEAM_REBEL elseif botteam == 2 then forceteam = TEAM_COMBINE end
	
	local totalmaxplayers = game.MaxPlayers()
	local maxplayers = forceteam == nil and math.floor( totalmaxplayers / 2 ) or totalmaxplayers
	local freeslots = GAMEMODE.CVar.bot_free_slots:GetInt()
	local quota = GAMEMODE.CVar.bot_quota:GetInt()
	
	if totalmaxplayers == 1 and quota > 0 and self.HasWarnedAboutSingleplayer ~= true then
		
		local ply = player.GetAll()[ 1 ]
		if IsValid( ply ) == true and ply:Team() ~= TEAM_SPECTATOR then
			
			local msg = "!!!!!\nWarning: Bots need player slots, they will not work in singleplayer! Raise maxplayers or bots will not be able to spawn!\n!!!!!"
			
			print( msg )
			PrintMessage( HUD_PRINTTALK, msg )
			self.HasWarnedAboutSingleplayer = true
			
		end
		
	end
	
	local curtime = CurTime()
	
	-- fill the quota
	if #self.List < quota and curtime > lastcreate + 0.1 and player.GetCount() < totalmaxplayers then
		
		-- wait for a human to join and spawn first
		local humans = player.GetHumans()
		if #humans > 0 then
			
			local nonspec = false
			for k, v in ipairs( humans ) do if v:Team() ~= TEAM_SPECTATOR then nonspec = true break end end
			
			if nonspec == true then
				
				if forceteam ~= nil then
					
					if team.NumPlayers( forceteam ) < maxplayers - freeslots then
						
						self:Create()
						lastcreate = curtime
						
					end
					
				else
					
					local rcount = team.NumPlayers( TEAM_REBEL )
					local ccount = team.NumPlayers( TEAM_COMBINE )
					
					local teamid = rcount >= ccount and TEAM_COMBINE or TEAM_REBEL
					if team.NumPlayers( teamid ) < maxplayers - freeslots then
						
						self:Create( teamid )
						lastcreate = curtime
						
					end
					
				end
				
			end
			
		end
		
	end
	
	if #self.List <= 0 then return end
	
	-- kick excess bots
	for teamid = TEAM_REBEL, TEAM_COMBINE do
		
		local count = team.NumPlayers( teamid )
		local ecount = team.NumPlayers( enemyteam[ teamid ] )
		
		if count > maxplayers - freeslots or ( forceteam == nil and count - 1 > ecount ) then
			
			local kick
			local score
			
			for k, v in ipairs( self.List ) do
				
				local frags = v:Frags()
				if v:Team() == teamid and ( score == nil or frags < score ) then
					
					kick = v
					score = frags
					
				end
				
			end
			
			if kick ~= nil then self:Kick( kick, "" ) end
			
		end
		
	end
	
	if #self.List > quota then
		
		local kick
		local score
		
		for k, v in ipairs( self.List ) do
			
			local frags = v:Frags()
			if score == nil or frags < score then
				
				kick = v
				score = frags
				
			end
			
		end
		
		if kick ~= nil then self:Kick( kick, "Bot quota exceeded" ) end
		
	end
	
end



function GM.Bot:OnDamaged( bot, dmg )
	
	local attacker = dmg:GetAttacker()
	if IsValid( attacker ) ~= true or attacker == bot or attacker:IsPlayer() ~= true then return end
	
	local data = bot.HL2MP_BotData
	if data.Target == nil then data.Target = attacker end
	
end
