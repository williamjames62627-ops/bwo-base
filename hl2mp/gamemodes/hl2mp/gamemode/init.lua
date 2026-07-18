AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "player.lua" )
AddCSLuaFile( "hl2skin.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "player_class/player_combine.lua" )
AddCSLuaFile( "player_class/player_rebel.lua" )
include( "player_class/player_combine.lua" )
include( "player_class/player_rebel.lua" )
include( "shared.lua" )
include( "player.lua" )
include( "sv_bot.lua" )

DEFINE_BASECLASS( "gamemode_base" )



GM.ItemClasses = {
	
	-- HL2
	[ "item_ammo_357" ] = true,
	[ "item_ammo_357_large" ] = true,
	[ "item_ammo_ar2" ] = true,
	[ "item_ammo_ar2_altfire" ] = true,
	[ "item_ammo_ar2_large" ] = true,
	[ "item_ammo_crossbow" ] = true,
	[ "item_ammo_pistol" ] = true,
	[ "item_ammo_pistol_large" ] = true,
	[ "item_ammo_smg1" ] = true,
	[ "item_ammo_smg1_grenade" ] = true,
	[ "item_ammo_smg1_large" ] = true,
	[ "item_battery" ] = true,
	[ "item_box_buckshot" ] = true,
	[ "item_healthkit" ] = true,
	[ "item_healthvial" ] = true,
	[ "item_rpg_round" ] = true,
	
	-- HL1
	[ "ammo_357" ] = true,
	[ "ammo_crossbow" ] = true,
	[ "ammo_glockclip" ] = true,
	[ "ammo_9mmbox" ] = true,
	[ "ammo_mp5clip" ] = true,
	[ "ammo_mp5grenades" ] = true,
	[ "ammo_rpgclip" ] = true,
	[ "ammo_buckshot" ] = true,
	[ "ammo_gaussclip" ] = true,
	[ "item_longjump" ] = true,
	
}

GM.HL1ItemConvert = {
	
	[ "weapon_357" ] = "weapon_357_hl1",
	[ "weapon_crossbow" ] = "weapon_crossbow_hl1",
	[ "weapon_crowbar" ] = "weapon_crowbar_hl1",
	[ "weapon_glock" ] = "weapon_glock_hl1",
	[ "weapon_mp5" ] = "weapon_mp5_hl1",
	[ "weapon_rpg" ] = "weapon_rpg_hl1",
	[ "weapon_shotgun" ] = "weapon_shotgun_hl1",
	
	
}

-- create dummy hl1 weapons if they don't already exist
if weapons.GetStored( "weapon_glock" ) == nil then weapons.Register( {}, "weapon_glock" ) end
if weapons.GetStored( "weapon_mp5" ) == nil then weapons.Register( {}, "weapon_mp5" ) end

function GM:ConvertItemClass( class )
	
	if self.CVar.hl1:GetBool() == true and IsMounted( "hl1" ) == true then return self.HL1ItemConvert[ class ] end
	
end

function GM:IsEntityItem( ent )
	
	if IsValid( ent ) == true and self.ItemClasses[ ent:GetClass() ] ~= nil then return self.ItemClasses[ ent:GetClass() ] end
	
	return false
	
end

function GM:CreateItemSpawns( force )
	
	local entities = ents.GetAll()
	for i = 1, #entities do
		
		local ent = entities[ i ]
		if IsValid( ent ) == true and IsValid( ent:GetOwner() ) ~= true and ( self:IsEntityItem( ent ) == true or ent:IsWeapon() == true ) and ent:GetNW2Bool( "HL2MP_ItemSpawn" ) ~= true then
			
			local spawn = ents.Create( "hl2mp_itemspawn" )
			if IsValid( spawn ) == true then
				
				spawn:SetPos( ent:GetPos() )
				spawn:SetAngles( ent:GetAngles() )
				spawn:SetItem( ent:GetClass() )
				spawn:SetModel( ent:GetModel() )
				spawn:SetIsWeapon( ent:IsWeapon() )
				spawn:Spawn()
				ent:Remove()
				
			end
			
		end
		
	end
	
end

function GM:PostCleanupMap()
	
	self:CreateItemSpawns()
	
end

function GM:InitPostEntity()
	
	self:CreateItemSpawns()
	
end

function GM:ShowHelp( ply )
	
	ply:SendLua( "GAMEMODE:ShowHelp()" )
	
end

function GM:ShowTeam( ply )
	
	ply:SendLua( "GAMEMODE:ShowTeam()" )
	
end
