AddCSLuaFile()
DEFINE_BASECLASS( "player_default" )


local PLAYER = {}

PLAYER.WalkSpeed = 190
PLAYER.RunSpeed = 320
PLAYER.JumpPower = 150
PLAYER.MaxHealth = 100
PLAYER.StartHealth = 100
PLAYER.StartArmor = 0
PLAYER.TeammateNoCollide = false
PLAYER.AvoidPlayers = false

function PLAYER:Loadout()
	
	self.Player:RemoveAllItems()
	self.Player:RemoveAllAmmo()
	
	if GAMEMODE.CVar.hl1:GetBool() == true and IsMounted( "hl1" ) == true then
		
		self.Player:Give( "weapon_crowbar_hl1" )
		self.Player:Give( "weapon_glock_hl1" )
		self.Player:GiveAmmo( 68, "9mmround", true )
		
	else
		
		self.Player:Give( "weapon_stunstick" )
		
		self.Player:Give( "weapon_physcannon" )
		self.Player:Give( "weapon_pistol" )
		self.Player:Give( "weapon_smg1" )
		self.Player:Give( "weapon_frag" )
		
		self.Player:GiveAmmo( 150, "pistol", true )
		self.Player:GiveAmmo( 45, "smg1", true )
		self.Player:GiveAmmo( 1, "grenade", true )
		
	end
	
end

function PLAYER:GetHandsModel()
	
	if GAMEMODE.CVar.hevhands:GetBool() ~= true then
		
		return player_manager.TranslatePlayerHands( player_manager.TranslateToPlayerModelName( self.Player:GetModel() ) )
		
	else
		
		return { model = "models/weapons/c_arms_hev.mdl", skin = 0, body = "0000000" }
		
	end
	
end


player_manager.RegisterClass( "player_combine", PLAYER, "player_default" )
