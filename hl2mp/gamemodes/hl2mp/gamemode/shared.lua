DEFINE_BASECLASS( "gamemode_base" )
DeriveGamemode( "base" )

GM.Name = "Half-Life 2: Deathmatch"
GM.Author = "AwfulRanger"
GM.Email = nil
GM.Website = nil
GM.IsSandboxDerived = false

STATE_ERROR = -1
STATE_WAITINGFORPLAYER = 0
STATE_STARTING = 1
STATE_ACTIVE = 2
STATE_ENDGAME = 3

TEAM_REBEL = 1
TEAM_COMBINE = 2
TEAM_FFA = 3
TEAM_NONE = -1



----
-- Convars
----

GM.CVar = {}
local function addcvar( name, def, desc )
	
	GM.CVar[ name ] = CreateConVar( "sv_hl2mp_" .. name, def, FCVAR_REPLICATED, desc )
	
end

addcvar( "teamplay", 0, "Disable for free for all, enable for team deathmatch" )
addcvar( "timelimit", 30, "How long (in minutes) until the map switches (0 for unlimited)" )
addcvar( "fraglimit", 0, "How many kills until map switches (0 for unlimited)" )
addcvar( "weapon_respawn", 20, "How long until weapons respawn" )
addcvar( "item_respawn", 30, "How long until items such as ammo respawn" )
addcvar( "limitammo", 1, "Enable to limit max ammo, disable to set max ammo to 9999" )
addcvar( "weaponstay", 0, "Disable obtaining ammo by picking up weapons" )
addcvar( "flashlight", 0, "Allow players to turn on flashlight" )
addcvar( "footsteps", 1, "Make footstep sound when player move" )
addcvar( "aux", 1, "Enable AUX to limit sprinting" )
addcvar( "maxaux", 300, "300 for 5 seconds of AUX (seconds * 60)" )
addcvar( "falldamage", 0, "Take fall damage when falling high enough" )
addcvar( "taunts", 0, "Allow players to taunt" )
addcvar( "teamcollide", 1, "Enable teammate collisions" )
addcvar( "hevhands", 0, "Use HEV suit hands instead of the hands defined by the playermodel" )
addcvar( "playercolor", 1, "Allow players to set the color of their model" )
addcvar( "weaponcolor", 1, "Allow players to set the color of their weapon" )
addcvar( "allplayermodels", 0, "Allow players to use any playermodel" )
addcvar( "gmoddamage", 0, "Enable default Garry's Mod weapon damage" )
addcvar( "dmg_head", 2, "Damage multiplier for the head" )
addcvar( "dmg_chest", 1, "Damage multiplier for the chest" )
addcvar( "dmg_stomach", 1, "Damage multiplier for the stomach" )
addcvar( "dmg_arm", 1, "Damage multiplier for the arm" )
addcvar( "dmg_leg", 1, "Damage multiplier for the leg" )
addcvar( "hl1", 0, "Use HL1 weapons and items (requires Half-Life: Source to be mounted)" )
addcvar( "extraspawns", 1, "Use spawnpoints from other games (rebels will use the spawns of RED in TF2 maps, T in CS maps, allies in DOD maps, combine will spawn as the opposite team)" )
addcvar( "bot_quota", 0, "Maximum amount of bots to keep in the server" )
addcvar( "bot_free_slots", 1, "Minimum amount of free slots to leave unoccupied by bots per team" )
addcvar( "bot_skill", 2, "Bot skill (0 = very easy, 1 = easy, 2 = normal, 3 = hard, 4 = very hard, 5 = impossible)" )
addcvar( "bot_team", 0, "What team the bots should join (0 = whichever has less players, 1 = rebels, 2 = combine)" )
addcvar( "bot_allplayermodels", 0, "Allow bots to use any playermodel" )
addcvar( "bot_specialplayermodel", 1, "Make certain bots use playermodels corresponding to their name (0 = disabled, 1 = respect sv_hl2mp_bot_allplayermodels, 2 = ignore all restrictions)" )
addcvar( "bot_generatenav", 0, "Automatically generate a navigation mesh for bots if the current map is missing one" )

concommand.Add( "sv_hl2mp_endround", function()
	
	GAMEMODE:EndRound()
	
end, nil, "Force the round to end and the map to change", FCVAR_SERVER_CAN_EXECUTE )



----
-- Playermodels
----

GM.Models_Rebel = {
	
	--[[
	Model( "models/player/group03/female_01.mdl" ),
	Model( "models/player/group03/female_02.mdl" ),
	Model( "models/player/group03/female_03.mdl" ),
	Model( "models/player/group03/female_04.mdl" ),
	Model( "models/player/group03/female_05.mdl" ),
	Model( "models/player/group03/female_06.mdl" ),
	
	Model( "models/player/group03/male_01.mdl" ),
	Model( "models/player/group03/male_02.mdl" ),
	Model( "models/player/group03/male_03.mdl" ),
	Model( "models/player/group03/male_04.mdl" ),
	Model( "models/player/group03/male_05.mdl" ),
	Model( "models/player/group03/male_06.mdl" ),
	Model( "models/player/group03/male_07.mdl" ),
	Model( "models/player/group03/male_08.mdl" ),
	Model( "models/player/group03/male_09.mdl" ),
	]]--
	
}

GM.Models_Combine = {
	
	--[[
	Model( "models/player/combine_soldier.mdl" ),
	Model( "models/player/combine_soldier_prisonguard.mdl" ),
	Model( "models/player/combine_super_soldier.mdl" ),
	Model( "models/player/police.mdl" ),
	Model( "models/player/police_fem.mdl" ),
	]]--
	
}

GM.ModelTeam = {}

function GM:SetupTeamPlayerModels( rebel, combine )
	
	-- Rebel
	table.insert( rebel, "female07" )
	table.insert( rebel, "female08" )
	table.insert( rebel, "female09" )
	table.insert( rebel, "female10" )
	table.insert( rebel, "female11" )
	table.insert( rebel, "female12" )
	table.insert( rebel, "male10" )
	table.insert( rebel, "male11" )
	table.insert( rebel, "male12" )
	table.insert( rebel, "male13" )
	table.insert( rebel, "male14" )
	table.insert( rebel, "male15" )
	table.insert( rebel, "male16" )
	table.insert( rebel, "male17" )
	table.insert( rebel, "male18" )
	
	-- Combine
	table.insert( combine, "combine" )
	table.insert( combine, "combineelite" )
	table.insert( combine, "combineprison" )
	table.insert( combine, "police" )
	table.insert( combine, "policefem" )
	
end


----
-- Round
----

GM.MapWeapons = GM.MapWeapons or {}
GM.MapItems = GM.MapItems or {}

function GM:SetGameState( state ) SetGlobalInt( "hl2mp_gamestate", state ) end
function GM:GetGameState() return GetGlobalInt( "hl2mp_gamestate" ) end

function GM:SetStartTime( time ) SetGlobalFloat( "hl2mp_starttime", time ) end
function GM:GetStartTime() return GetGlobalFloat( "hl2mp_starttime" ) end

function GM:StartRound()
	
	if CLIENT then return end
	
	self:SetStartTime( CurTime() )
	
	self:SetGameState( STATE_STARTING )
	game.CleanUpMap()
	if team.NumPlayers( TEAM_REBEL ) > 0 or team.NumPlayers( TEAM_COMBINE ) > 0 then self:SetGameState( STATE_ACTIVE )
	else self:SetGameState( STATE_WAITINGFORPLAYER ) end
	
	for k, p in ipairs( player.GetAll() ) do p:Spawn() end
	
	if self.CVar.timelimit:GetFloat() == 0 then self.TimeLimit = 0
	else self.TimeLimit = ( self.CVar.timelimit:GetFloat() * 60 ) + self:GetStartTime() end
	
end

function GM:EndRound()
	
	if CLIENT then return end
	
	self:SetGameState( STATE_ENDGAME )
	
	for k, p in ipairs( player.GetAll() ) do
		
		p:Freeze( true )
		p:SendLua( "GAMEMODE:ScoreboardShow()" )
		
	end
	
	timer.Simple( 10, function() game.LoadNextMap() end )
	
end



function GM:Initialize()
	
	hook.Run( "SetupTeamPlayerModels", GAMEMODE.Models_Rebel, GAMEMODE.Models_Combine )
	
	for k, v in ipairs( GAMEMODE.Models_Rebel ) do if GAMEMODE.ModelTeam[ v ] == nil then GAMEMODE.ModelTeam[ v ] = TEAM_REBEL end end
	for k, v in ipairs( GAMEMODE.Models_Combine ) do if GAMEMODE.ModelTeam[ v ] == nil then GAMEMODE.ModelTeam[ v ] = TEAM_COMBINE end end
	
	if SERVER then
		
		self:SetStartTime( CurTime() )
		self:SetGameState( STATE_WAITINGFORPLAYER )
		if self.CVar.timelimit:GetFloat() == 0 then self.TimeLimit = 0
		else self.TimeLimit = ( self.CVar.timelimit:GetFloat() * 60 ) + self:GetStartTime() end
		
	else timer.Simple( 0, function() self:ShowHelp() end ) end
	
end

function GM:CreateTeams()
	
	team.SetUp( TEAM_REBEL, "Rebel", Color( 255, 100, 50 ), true )
	team.SetUp( TEAM_COMBINE, "Combine", Color( 100, 50, 255 ), true )
	
	team.SetSpawnPoint( TEAM_REBEL, { "info_player_rebel", "info_player_deathmatch" } )
	team.SetSpawnPoint( TEAM_COMBINE, { "info_player_combine", "info_player_deathmatch" } )
	
end

function GM:Think()
	
	if CLIENT then return end
	
	self.TimeLimit = self:GetStartTime() + ( self.CVar.timelimit:GetFloat() * 60 )
	
	self.Bot:Think()
	
	local gamestate = self:GetGameState()
	if gamestate ~= STATE_ERROR and gamestate ~= STATE_ENDGAME and self.CVar.timelimit:GetFloat() ~= 0 and CurTime() > self.TimeLimit then
		
		self:EndRound()
		
	end
	
end

function GM:ShouldCollide( ent1, ent2 )
	
	if self.CVar.teamcollide:GetBool() == false and IsValid( ent1 ) == true and IsValid( ent2 ) == true and ent1:IsPlayer() == true and ent2:IsPlayer() == true and ent1:Team() == ent2:Team() then return false end
	
	return BaseClass.ShouldCollide( self, ent1, ent2 )
	
end
