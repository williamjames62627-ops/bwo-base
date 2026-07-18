DEFINE_BASECLASS( "gamemode_base" )



if CLIENT then
	
	GM.CCVar.playercolor = CreateConVar( "cl_playercolor", "0.24 0.34 0.41", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	GM.CCVar.weaponcolor = CreateConVar( "cl_weaponcolor", "0.30 1.80 2.10", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	
end



function GM:IsPlayerAlive( ply )
	
	local teamid = ply:Team()
	return ply:Alive() == true and ( teamid == TEAM_REBEL or teamid == TEAM_COMBINE )
	
end



----
-- Player AUX
----

local playermeta = FindMetaTable( "Player" )
function playermeta:GetAUX()
	
	return self:GetNWInt( "aux" )
	
end
function playermeta:SetAUX( aux )
	
	self:SetNWInt( "aux", aux )
	
end
function playermeta:GetMaxAUX()
	
	return self:GetNWInt( "maxaux" )
	
end
function playermeta:SetMaxAUX( aux )
	
	self:SetNWInt( "maxaux", aux )
	
end

function GM:HandlePlayerAUX( ply, mv )
	
	local aux = ply:GetAUX()
	local maxaux = ply:GetMaxAUX()
	
	local speed = ply:GetWalkSpeed()
	
	if aux > maxaux then if SERVER then ply:SetAUX( maxaux ) end
	elseif aux < 0 then if SERVER then ply:SetAUX( 0 ) end
	elseif mv:KeyPressed( IN_SPEED ) == true then
		
		if aux > 20 then
			
			if SERVER then ply:SetAUX( aux - 20 ) end
			speed = ply:GetRunSpeed()
			
			if CLIENT then surface.PlaySound( "player/suit_sprint.wav" ) end
			
		elseif CLIENT then surface.PlaySound( "player/suit_denydevice.wav" ) end
		
	elseif mv:KeyDown( IN_SPEED ) == true and mv:GetVelocity():LengthSqr() ~= 0 then
		
		if aux > 0 then speed = ply:GetRunSpeed() end
		if SERVER then ply:SetAUX( aux - ( FrameTime() * 60 ) ) end
		
	elseif aux < maxaux then if SERVER then ply:SetAUX( math.min( aux + ( FrameTime() * 30 ), maxaux ) ) end end
	
	if ply:Crouching() == true then speed = speed * ply:GetCrouchedWalkSpeed() end
	
	mv:SetMaxClientSpeed( speed )
	mv:SetMaxSpeed( speed )
	
	if SERVER then ply:SetSuitPower( ( ply:GetAUX() / ply:GetMaxAUX() ) * 100 ) end
	
end

function GM:PlayerTick( ply, mv )
	
	if ply:Team() == TEAM_SPECTATOR then if SERVER then self:PlayerSpectateTick( ply, mv ) end return end
	
	if self.CVar.aux:GetBool() ~= true then return end
	if self:IsPlayerAlive( ply ) ~= true then return end
	
	self:HandlePlayerAUX( ply, mv )
	
end



----
-- Player damage
----

local hitgroups = {
	
	[ HITGROUP_HEAD ] = GM.CVar.dmg_head,
	[ HITGROUP_CHEST ] = GM.CVar.dmg_chest,
	[ HITGROUP_STOMACH ] = GM.CVar.dmg_stomach,
	[ HITGROUP_LEFTARM ] = GM.CVar.dmg_arm,
	[ HITGROUP_RIGHTARM ] = GM.CVar.dmg_arm,
	[ HITGROUP_LEFTLEG ] = GM.CVar.dmg_leg,
	[ HITGROUP_RIGHTLEG ] = GM.CVar.dmg_leg,
	[ HITGROUP_GEAR ] = GM.CVar.dmg_stomach,
	
}
local dmgmult = {
	
	[ "weapon_crowbar" ] = 25 / 10,
	[ "weapon_stunstick" ] = 40 / 10,
	[ "weapon_pistol" ] = 8 / 12,
	[ "weapon_smg1" ] = 5 / 12,
	[ "weapon_shotgun" ] = 9 / 4,
	
}

function GM:ScalePlayerDamage( ply, hit, dmg )
	
	if self.CVar.gmoddamage:GetBool() ~= true then
		
		local a = dmg:GetAttacker()
		if IsValid( a ) == true and a:IsPlayer() == true then
			
			local weapon = dmg:GetInflictor()
			if IsValid( weapon ) ~= true or weapon == a then weapon = a:GetActiveWeapon() end
			if IsValid( weapon ) ~= true then return end
			
			local weaponmult = dmgmult[ weapon:GetClass() ]
			if weaponmult ~= nil then dmg:ScaleDamage( weaponmult ) end
			
		end
		
	end
	
	local hitmult = hitgroups[ hit ]
	if hitmult ~= nil then dmg:ScaleDamage( hitmult:GetFloat() ) end
	
end



if CLIENT then return end



----
-- Spectate
----

function GM:PlayerSpawnAsSpectator( ply )
	
	BaseClass.PlayerSpawnAsSpectator( self, ply ) 
	
	ply:SetMoveType( MOVETYPE_NOCLIP )
	
end

concommand.Add( "cl_hl2mp_spectate", function( ply, cmd, args, arg )
	
	if IsValid( ply ) ~= true then return end
	
	local shouldspec = args[ 1 ] == nil or tobool( args[ 1 ] )
	if shouldspec == ( ply:Team() == TEAM_SPECTATOR ) then return end
	
	if shouldspec == true then
		
		if ply:Alive() == true then ply:Kill() end
		ply:SetTeam( TEAM_SPECTATOR )
		
	else
		
		hook.Run( "PlayerSetTeamModel", ply )
		ply:UnSpectate()
		ply:KillSilent()
		--ply:Spawn()
		
	end
	
end )

local function setspectarget( ply, index )
	
	local rcount = team.NumPlayers( TEAM_REBEL )
	local teamid = index > rcount and TEAM_COMBINE or TEAM_REBEL
	if teamid == TEAM_COMBINE then index = index - rcount end
	
	local ent = team.GetPlayers( teamid )[ index ]
	
	ply:SpectateEntity( ent )
	ply:SetupHands( ent )
	ply:SetMoveType( MOVETYPE_NOCLIP )
	
end

function GM:PlayerSpectateTick( ply, mv )
	
	local maxindex = team.NumPlayers( TEAM_REBEL ) + team.NumPlayers( TEAM_COMBINE )
	
	local obs = ply:GetObserverMode()
	
	if ply.HL2MP_SpecIndex == nil or ply.HL2MP_SpecIndex > maxindex or ply.HL2MP_SpecIndex < 1 then
		
		ply.HL2MP_SpecIndex = 1
		if obs ~= OBS_MODE_ROAMING then setspectarget( ply, ply.HL2MP_SpecIndex ) end
		
	end
	
	if obs ~= OBS_MODE_ROAMING then
		
		if mv:KeyPressed( IN_ATTACK ) == true then
			
			ply.HL2MP_SpecIndex = ply.HL2MP_SpecIndex + 1
			if ply.HL2MP_SpecIndex > maxindex then ply.HL2MP_SpecIndex = 1 end
			setspectarget( ply, ply.HL2MP_SpecIndex )
			
		elseif mv:KeyPressed( IN_ATTACK2 ) == true then
			
			ply.HL2MP_SpecIndex = ply.HL2MP_SpecIndex - 1
			if ply.HL2MP_SpecIndex < 1 then ply.HL2MP_SpecIndex = maxindex end
			setspectarget( ply, ply.HL2MP_SpecIndex )
			
		end
		
		-- make the player properly follow their target otherwise things like sound may not work
		local target = ply:GetObserverTarget()
		if IsValid( target ) == true then mv:SetOrigin( target:EyePos() ) end
		
	elseif mv:KeyPressed( IN_ATTACK ) == true or mv:KeyPressed( IN_ATTACK2 ) == true then
		
		ply:SetObserverMode( OBS_MODE_CHASE )
		setspectarget( ply, ply.HL2MP_SpecIndex )
		
	end
	
	if mv:KeyPressed( IN_JUMP ) == true then
		
		ply:SetObserverMode( ( ( obs - 3 ) % 3 ) + 4 )
		if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
			
			setspectarget( ply, ply.HL2MP_SpecIndex )
			
		end
		
	end
	
end



----
-- Player spawn
----

GM.TeamSpawnPoints = {}
GM.TeamSpawnPointsExtra = {}
GM.FFASpawnPoints = nil
GM.FFASpawnPointsExtra = nil
GM.SpecSpawnPoints = nil

function GM:PlayerSelectTeamSpawn( teamid, ply )
	
	local extraspawns = self.CVar.extraspawns:GetBool()
	local spawntbl = extraspawns == true and self.TeamSpawnPointsExtra or self.TeamSpawnPoints
	
	local spawns = spawntbl[ teamid ]
	if spawns == nil then
		
		if teamid == TEAM_REBEL then
			
			spawns = ents.FindByClass( "info_player_rebel" )
			
			if extraspawns == true then
				
				for k, v in ipairs( ents.FindByClass( "info_player_teamspawn" ) ) do
					
					if v:GetInternalVariable( "TeamNum" ) == 2 then table.insert( spawns, v ) end -- TF2 RED spawns
					
				end
				for k, v in ipairs( ents.FindByClass( "info_player_terrorist" ) ) do table.insert( spawns, v ) end -- CS T spawns
				for k, v in ipairs( ents.FindByClass( "info_player_allies" ) ) do table.insert( spawns, v ) end -- DOD allies spawns
				
			end
			
			if #spawns == 0 then spawns = ents.FindByClass( "info_player_deathmatch" ) end
			--if #spawns == 0 then spawns = { ents.FindByClass( "info_player_start" )[ 1 ] } end
			
		elseif teamid == TEAM_COMBINE then
			
			spawns = ents.FindByClass( "info_player_combine" )
			
			if extraspawns == true then
				
				for k, v in ipairs( ents.FindByClass( "info_player_teamspawn" ) ) do
					
					if v:GetInternalVariable( "TeamNum" ) == 3 then table.insert( spawns, v ) end -- TF2 BLU spawns
					
				end
				for k, v in ipairs( ents.FindByClass( "info_player_counterterrorist" ) ) do table.insert( spawns, v ) end -- CS CT spawns
				for k, v in ipairs( ents.FindByClass( "info_player_axis" ) ) do table.insert( spawns, v ) end -- DOD axis spawns
				
			end
			
			if #spawns == 0 then spawns = ents.FindByClass( "info_player_deathmatch" ) end
			--if #spawns == 0 then spawns = { ents.FindByClass( "info_player_start" )[ 1 ] } end
			
		else spawns = { ents.FindByClass( "info_player_start" )[ 1 ] } end
		
		spawntbl[ teamid ] = spawns
		
	end
	
	local count = #spawns
	if count <= 1 then return spawns[ 1 ] end
	
	local spawnpoint = nil
	
	local start = math.random( count ) - 1
	for i = 1, count do
		
		spawnpoint = spawns[ start + 1 ]
		if hook.Run( "IsSpawnpointSuitable", ply, spawnpoint, i == count ) == true then break end
		
		start = ( start + 1 ) % count
		
	end
	
	return spawnpoint
	
end

function GM:PlayerSelectSpawn( ply, transition )
	
	local extraspawns = self.CVar.extraspawns:GetBool()
	
	local plyteam = ply:Team()
	if plyteam == TEAM_SPECTATOR then
		
		local spawns = self.SpecSpawnPoints
		if spawns == nil then
			
			spawns = ents.FindByClass( "info_player_start" )
			if extraspawns == true then
				
				local found = false
				for k, v in ipairs( ents.FindByClass( "info_player_teamspawn" ) ) do
					
					if v:GetInternalVariable( "TeamNum" ) == 1 then
						
						if found ~= true then spawns = {} found = true end
						table.insert( spawns, v )
						
					end
					
				end
				for k, v in ipairs( ents.FindByClass( "info_observer_point" ) ) do
					
					if found ~= true then spawns = {} found = true end
					table.insert( spawns, v )
					
				end
				
			end
			
			self.SpecSpawnPoints = spawns
			
		end
		
		local count = #spawns
		if count > 0 then return spawns[ math.random( count ) ] end
		
	end
	
	if transition == true then return end
	
	if self.CVar.teamplay:GetBool() == true then
		
		local spawnpoint = self:PlayerSelectTeamSpawn( plyteam, ply )
		if spawnpoint ~= nil then return spawnpoint end
		
	end
	
	local spawns = extraspawns == true and self.FFASpawnPointsExtra or self.FFASpawnPoints
	if spawns == nil then
		
		spawns = ents.FindByClass( "info_player_deathmatch" )
		--if #spawns == 0 then spawns = { ents.FindByClass( "info_player_start" )[ 1 ] } end
		
		if extraspawns == true then
			
			if #spawns == 0 then
				
				for k, v in ipairs( ents.FindByClass( "info_player_teamspawn" ) ) do
					
					local teamnum = v:GetInternalVariable( "TeamNum" )
					if teamnum == 2 then table.insert( spawns, v ) -- TF2 RED spawns
					elseif teamnum == 3 then table.insert( spawns, v ) end -- TF2 BLU spawns
					
				end
				for k, v in ipairs( ents.FindByClass( "info_player_terrorist" ) ) do table.insert( spawns, v ) end -- CS T spawns
				for k, v in ipairs( ents.FindByClass( "info_player_counterterrorist" ) ) do table.insert( spawns, v ) end -- CS CT spawns
				for k, v in ipairs( ents.FindByClass( "info_player_allies" ) ) do table.insert( spawns, v ) end -- DOD allies spawns
				for k, v in ipairs( ents.FindByClass( "info_player_axis" ) ) do table.insert( spawns, v ) end -- DOD axis spawns
				
			end
			
			self.FFASpawnPointsExtra = spawns
			
		else
			
			self.FFASpawnPoints = spawns
			
		end
		
	end
	
	local count = #spawns
	if count == 0 then return BaseClass.PlayerSelectSpawn( self, ply, transition )
	elseif count == 1 then return spawns[ 1 ] end
	
	local spawnpoint = nil
	
	local start = math.random( count ) - 1
	for i = 1, count do
		
		spawnpoint = spawns[ start + 1 ]
		if hook.Run( "IsSpawnpointSuitable", ply, spawnpoint, i == count ) == true then break end
		
		start = ( start + 1 ) % count
		
	end
	
	return spawnpoint
	
end

function GM:PlayerInitialSpawn( ply )
	
	if self:GetGameState() == STATE_WAITINGFORPLAYER then self:SetGameState( STATE_ACTIVE ) end
	
	ply:SetCustomCollisionCheck( true )
	
	ply:SetTeam( TEAM_SPECTATOR )
	self:PlayerSpawnAsSpectator( ply )
	
	--BaseClass.PlayerInitialSpawn( self, ply )
	
end

function GM:PlayerSetTeamModel( ply )
	
	local allplayermodels = self.CVar.allplayermodels:GetBool()
	
	if ply.HL2MP_ForcePlayerModel == nil and self.CVar.teamplay:GetBool() == true then
		
		local desiredteam = ply.HL2MP_ForceDesiredTeam or ply:GetInfoNum( "cl_hl2mp_team", 0 )
		if desiredteam == TEAM_REBEL then
			
			local playermodel = ply:GetInfo( "cl_hl2mp_playermodel_rebel" )
			if allplayermodels == true or self.ModelTeam[ playermodel ] == TEAM_REBEL or self.ModelTeam[ playermodel ] == TEAM_FFA then
				
				ply:SetModel( player_manager.TranslatePlayerModel( playermodel ) )
				ply:SetTeam( TEAM_REBEL )
				player_manager.SetPlayerClass( ply, "player_rebel" )
				
				return
				
			end
			
		elseif desiredteam == TEAM_COMBINE then
			
			local playermodel = ply:GetInfo( "cl_hl2mp_playermodel_combine" )
			if allplayermodels == true or self.ModelTeam[ playermodel ] == TEAM_COMBINE or self.ModelTeam[ playermodel ] == TEAM_FFA then
				
				ply:SetModel( player_manager.TranslatePlayerModel( playermodel ) )
				ply:SetTeam( TEAM_COMBINE )
				player_manager.SetPlayerClass( ply, "player_combine" )
				
				return
				
			end
			
		end
		
	end
	
	local playermodel = ply.HL2MP_ForcePlayerModel or ply:GetInfo( "cl_hl2mp_playermodel" )
	local team = ply.HL2MP_ForceTeam or self.ModelTeam[ playermodel ]
	if team == TEAM_REBEL then
		
		ply:SetModel( player_manager.TranslatePlayerModel( playermodel ) )
		ply:SetTeam( TEAM_REBEL )
		player_manager.SetPlayerClass( ply, "player_rebel" )
		
	elseif team == TEAM_COMBINE or allplayermodels == true then
		
		ply:SetModel( player_manager.TranslatePlayerModel( playermodel ) )
		ply:SetTeam( TEAM_COMBINE )
		player_manager.SetPlayerClass( ply, "player_combine" )
		
	else
		
		ply:SetModel( player_manager.TranslatePlayerModel( self.Models_Combine[ 1 ] ) )
		ply:SetTeam( TEAM_COMBINE )
		player_manager.SetPlayerClass( ply, "player_combine" )
		
	end
	
end

function GM:PlayerSpawn( ply )
	
	if ply:Team() == TEAM_SPECTATOR then return self:PlayerSpawnAsSpectator( ply )
	else ply:UnSpectate() end
	
	hook.Run( "PlayerSetTeamModel", ply )
	
	ply:SetMaxAUX( self.CVar.maxaux:GetInt() )
	ply:SetAUX( self.CVar.maxaux:GetInt() )
	
	local teamcolor = team.GetColor( ply:Team() ):ToVector()
	
	--local pcolor = Vector( 0.24, 0.34, 0.41 )
	local pcolor = teamcolor
	if self.CVar.playercolor:GetBool() == true then
		
		pcolor = ply.HL2MP_BotData ~= nil and ply.HL2MP_BotData.PlayerColor or Vector( ply:GetInfo( "cl_playercolor" ) )
		
	end
	ply:SetPlayerColor( pcolor )
	
	--local wcolor = Vector( 0.3, 1.8, 2.1 )
	local wcolor = teamcolor
	if self.CVar.weaponcolor:GetBool() == true then
		
		wcolor = ply.HL2MP_BotData ~= nil and ply.HL2MP_BotData.WeaponColor or Vector( ply:GetInfo( "cl_weaponcolor" ) )
		if wcolor:Length() == 0 then wcolor = Vector( 0.001, 0.001, 0.001 ) end
		
	end
	ply:SetWeaponColor( wcolor )
	
	ply:SetMoveType( MOVETYPE_WALK )
	
	BaseClass.PlayerSpawn( self, ply )
	
	if ply:IsBot() == true and ply.HL2MP_BotData ~= nil then ply.HL2MP_BotData.SpawnTime = CurTime() end
	
end

function GM:PlayerSetModel( ply )
end



----
-- Player death/damage
----

function GM:DoPlayerDeath( ply, attacker, dmg )
	
	ply:CreateRagdoll()
	ply:AddDeaths( 1 )
	
	if IsValid( attacker ) == true and attacker:IsPlayer() == true then
		
		local ateam = attacker:Team()
		
		attacker:AddFrags( attacker == ply and -1 or 1 )
		--team.AddScore( ateam, attacker == ply and -1 or 1 )
		if attacker ~= ply then team.AddScore( ateam, 1 ) end
		
		local fraglimit = self.CVar.fraglimit:GetInt()
		if fraglimit <= 0 then return end
		
		local teamplay = self.CVar.teamplay:GetBool()
		if teamplay ~= true and attacker:Frags() >= fraglimit then
			
			self:EndRound()
			
		elseif teamplay == true and team.GetScore( ateam ) >= fraglimit then
			
			self:EndRound()
			
		end
		
	end
	
	if ply:IsBot() == true and ply.HL2MP_BotData ~= nil then ply.HL2MP_BotData.DeathTime = CurTime() end
	
end

function GM:PlayerDeathThink( ply )
	
	if self:GetGameState() == STATE_ENDGAME then return end
	
	if ply.NextSpawnTime ~= nil and ply.NextSpawnTime > CurTime() then return end
	
	if ply:IsBot() == true or ply:KeyPressed( IN_ATTACK ) == true or ply:KeyPressed( IN_ATTACK2 ) == true or ply:KeyPressed( IN_JUMP ) == true then
		
		local teamid = ply:Team()
		if teamid == TEAM_REBEL or teamid == TEAM_COMBINE then hook.Run( "PlayerSetTeamModel", ply ) end
		ply:Spawn()
		
	end
	
end

function GM:PlayerShouldTakeDamage( ply, attacker )
	
	if self.CVar.teamplay:GetBool() == true and attacker:IsPlayer() == true and ply ~= attacker then
		
		return ply:Team() ~= attacker:Team()
		
	else
		
		return self:IsPlayerAlive( ply )
		
	end
	
end

function GM:GetFallDamage( ply, speed )
	
	return self.CVar.falldamage:GetBool() == true and ( 0.012 * speed ) or 0
	
end

function GM:PostEntityTakeDamage( ent, dmg, took )
	
	if took == true and ent:IsPlayer() == true and ent:IsBot() == true and ent.HL2MP_BotData ~= nil then self.Bot:OnDamaged( ent, dmg ) end
	
end

function GM:CanPlayerSuicide( ply )
	
	return self:IsPlayerAlive( ply )
	
end



----
-- Player misc
----

function GM:PlayerSwitchFlashlight( ply, enabled )
	
	if self.CVar.flashlight:GetBool() == false or self:IsPlayerAlive( ply ) ~= true then return enabled ~= true end
	
	return true
	
end

function GM:PlayerFootstep( ply, pos, foot, sound, volume, filter )
	
	if self.CVar.footsteps:GetBool() ~= false then
		
		if ply:Team() ~= TEAM_COMBINE then
			
			ply:EmitSound( "player/footsteps/concrete" .. math.random( 1, 4 ) .. ".wav", 75, 100, volume )
			
		else
			
			ply:EmitSound( "npc/combine_soldier/gear" .. math.random( 1, 6 ) .. ".wav", 75, 100, volume )
			
		end
		
	end
	
	return true
	
end

function GM:PlayerShouldTaunt( ply, act )
	
	if self:IsPlayerAlive( ply ) ~= true then return false end
	
	return self.CVar.taunts:GetBool()
	
end

function GM:StartCommand( ply, ... )
	
	if ply:IsBot() == true and ply.HL2MP_BotData ~= nil then return self.Bot:StartCommand( ply, ... ) end
	
	--return BaseClass.StartCommand( self, ply, ... )
	
end

local cheats = GetConVar( "sv_cheats" )
function GM:PlayerNoClip( ply, state )
	
	return cheats:GetBool()
	
end

function GM:CanPlayerEnterVehicle( ply, veh, role )
	
	return self:IsPlayerAlive( ply )
	
end

function GM:PlayerUse( ply, ent )
	
	return self:IsPlayerAlive( ply )
	
end

function GM:PlayerCanJoinTeam( ply, teamid )
	
	return false
	
end

function GM:PlayerRequestTeam( ply, teamid )
	
	return false
	
end

function GM:PlayerSpray( ply )
	
	return self:IsPlayerAlive( ply ) ~= true
	
end



----
-- Item/weapon pickup
----

local function CheckAmmo( ply, ammotype )
	
	if GAMEMODE.CVar.limitammo:GetBool() == false then return false end
	
	return ply:GetAmmoCount( ammotype ) >= game.GetAmmoMax( ammotype )
	
end

local function CheckSetAmmo( ply, ammotype )
	
	if GAMEMODE.CVar.limitammo:GetBool() == false then return end
	
	if ply:GetAmmoCount( ammotype ) > game.GetAmmoMax( ammotype ) then
		
		ply:SetAmmo( game.GetAmmoMax( ammotype ), ammotype )
		
	end
	
end

function GM:PlayerCanPickupWeapon( ply, wep )
	
	if self:IsPlayerAlive( ply ) ~= true then return false end
	
	if self.CVar.weaponstay:GetBool() == false then
		
		if CheckAmmo( ply, wep:GetPrimaryAmmoType() ) == false or ply:HasWeapon( wep:GetClass() ) == false then
			
			if ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) == 9999 then return false end
			
			if ply:HasWeapon( wep:GetClass() ) == false and wep:GetClass() ~= "weapon_slam" then self:EntityRemoved( wep ) end
			local wepammo = wep:GetPrimaryAmmoType()
			timer.Simple( 0, function() if IsValid( ply ) == true then CheckSetAmmo( ply, wepammo ) end end )
			wep.hl2mp_grabbedbyplayer = true
			return true
			
		elseif wep:GetPrimaryAmmoType() == -1 and ply:HasWeapon( wep:GetClass() ) == false then
			
			wep.hl2mp_grabbedbyplayer = true
			self:EntityRemoved( wep )
			return true
			
		else
			
			return false
			
		end
		
	else
		
		if ply:HasWeapon( wep:GetClass() ) == true then
			
			return false
			
		elseif CheckAmmo( ply, wep:GetPrimaryAmmoType() ) == false or ply:HasWeapon( wep:GetClass() ) == false then
			
			if ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) == 9999 then return false end
			
			wep.hl2mp_grabbedbyplayer = true
			self:EntityRemoved( wep )
			local wepammo = wep:GetPrimaryAmmoType()
			timer.Simple( 0, function() if IsValid( ply ) == true then CheckSetAmmo( ply, wepammo ) end end )
			return true
			
		else
			
			return false
			
		end
		
	end
	
	return true
	
end


local function AmmoPickup( ammo )
	
	return function( ply )
		
		if CheckAmmo( ply, game.GetAmmoID( ammo ) ) ~= true then
			
			timer.Simple( 0, function() if IsValid( ply ) == true then CheckSetAmmo( ply, game.GetAmmoID( ammo ) ) end end )
			return true
			
		end
		
		return false
		
	end
	
end
GM.ItemTable = {
	
	-- HL2
	[ "item_ammo_ar2" ] = AmmoPickup( "AR2" ),
	[ "item_ammo_ar2_large" ] = AmmoPickup( "AR2" ),
	[ "item_ammo_ar2_altfire" ] = AmmoPickup( "AR2AltFire" ),
	[ "item_ammo_pistol" ] = AmmoPickup( "Pistol" ),
	[ "item_ammo_smg1" ] = AmmoPickup( "SMG1" ),
	[ "item_ammo_357" ] = AmmoPickup( "357" ),
	[ "item_ammo_crossbow" ] = AmmoPickup( "XBowBolt" ),
	[ "item_box_buckshot" ] = AmmoPickup( "Buckshot" ),
	[ "item_rpg_round" ] = AmmoPickup( "RPG_Round" ),
	[ "item_ammo_smg1_grenade" ] = AmmoPickup( "SMG1_Grenade" ),
	
	[ "item_healthkit" ] = function( ply ) return ply:Health() < ply:GetMaxHealth() end,
	[ "item_healthvial" ] = function( ply ) return ply:Health() < ply:GetMaxHealth() end,
	[ "item_battery" ] = function( ply ) return ply:Armor() < ply:GetMaxArmor() end,
	
	-- HL1
	[ "ammo_357" ] = AmmoPickup( "357Round" ),
	[ "ammo_crossbow" ] = AmmoPickup( "XBoxBoltHL1" ),
	[ "ammo_glockclip" ] = AmmoPickup( "9mmRound" ),
	[ "ammo_9mmbox" ] = AmmoPickup( "9mmRound" ),
	[ "ammo_mp5clip" ] = AmmoPickup( "9mmRound" ),
	[ "ammo_mp5grenades" ] = AmmoPickup( "MP5_Grenade" ),
	[ "ammo_rpgclip" ] = AmmoPickup( "RPG_Rocket" ),
	[ "ammo_buckshot" ] = AmmoPickup( "BuckshotHL1" ),
	[ "ammo_gaussclip" ] = AmmoPickup( "Uranium" ),
	
}

function GM:PlayerCanPickupItem( ply, item )
	
	if self:IsPlayerAlive( ply ) ~= true then return false end
	
	if self.ItemTable[ item:GetClass() ] ~= nil then return self.ItemTable[ item:GetClass() ]( ply ) end
	
	return true
	
end
