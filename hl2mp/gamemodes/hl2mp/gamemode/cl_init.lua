GM.CCVar = {}

GM.CCVar.playermodel = CreateConVar( "cl_hl2mp_playermodel", "police", { FCVAR_ARCHIVE, FCVAR_USERINFO }, "Half-Life 2: Deathmatch free-for-all playermodel" )
GM.CCVar.playermodel_rebel = CreateConVar( "cl_hl2mp_playermodel_rebel", "male10", { FCVAR_ARCHIVE, FCVAR_USERINFO }, "Half-Life 2: Deathmatch rebel playermodel" )
GM.CCVar.playermodel_combine = CreateConVar( "cl_hl2mp_playermodel_combine", "combine", { FCVAR_ARCHIVE, FCVAR_USERINFO }, "Half-Life 2: Deathmatch combine playermodel" )
GM.CCVar.team = CreateConVar( "cl_hl2mp_team", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO }, "Half-Life 2: Deathmatch desired team (0 for automatic based on cl_hl2mp_playermodel, 1 for rebel, 2 for combine)" )
GM.CCVar.mapinfo = CreateConVar( "cl_hl2mp_mapinfo", 1, FCVAR_ARCHIVE, "Should the map info box be visible at all times, or only when viewing scoreboard?" )
GM.CCVar.ffascoreboard = CreateConVar( "cl_hl2mp_ffascoreboard", 1, FCVAR_ARCHIVE, "If enabled, the scoreboard will put players of both teams in the same list during free-for-all matches" )

include( "shared.lua" )
include( "player.lua" )
include( "cl_hud.lua" )
include( "player_class/player_combine.lua" )
include( "player_class/player_rebel.lua" )

DEFINE_BASECLASS( "gamemode_base" )
