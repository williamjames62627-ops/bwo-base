AddCSLuaFile()


ENT.Base = "base_point"
ENT.Type = "point"


if CLIENT then return end


function ENT:SetItem( item )
	
	self.HL2MP_Item = item
	
end

function ENT:GetItem()
	
	return self.HL2MP_Item
	
end

function ENT:SetIsWeapon( isweapon )
	
	self.HL2MP_IsWeapon = isweapon
	self.HL2MP_RespawnTimeConvar = GetConVar( isweapon == true and "sv_hl2mp_weapon_respawn" or "sv_hl2mp_item_respawn" )
	
end

function ENT:GetIsWeapon()
	
	return self.HL2MP_IsWeapon or false
	
end

function ENT:SetPickedUp( pickedup )
	
	self.HL2MP_PickedUp = pickedup
	
end

function ENT:GetPickedUp()
	
	return self.HL2MP_PickedUp or false
	
end

function ENT:SetNextPickup( nextpickup )
	
	self.HL2MP_NextPickup = nextpickup
	
end

function ENT:GetNextPickup()
	
	return self.HL2MP_NextPickup or 0
	
end

function ENT:SetItemEntity( itementity )
	
	self.HL2MP_ItemEntity = itementity
	
end

function ENT:GetItemEntity()
	
	return self.HL2MP_ItemEntity
	
end

function ENT:IsActive()
	
	return CurTime() >= self:GetNextPickup()
	
end

function ENT:GetRespawnTime()
	
	local convar = self.HL2MP_RespawnTimeConvar or GetConVar( "sv_hl2mp_item_respawn" )
	
	return convar:GetFloat()
	
end

function ENT:KeyValue( key, value )
	
	if key == "item" then
		
		self:SetItem( value )
		
	end
	
end


function ENT:Think()
	
	local item = self:GetItem()
	if item ~= nil and item ~= "" then
		
		local ent = self:GetItemEntity()
		if IsValid( ent ) == true and IsValid( ent:GetOwner() ) ~= true then
			
			self:SetNextPickup( CurTime() + self:GetRespawnTime() )
			
		elseif CurTime() > self:GetNextPickup() then
			
			local convert = hook.Run( "ConvertItemClass", item )
			if convert ~= nil and convert ~= "" then item = convert end
			
			local newent = ents.Create( item )
			newent:SetPos( self:GetPos() )
			newent:SetAngles( self:GetAngles() )
			newent:Spawn()
			self:SetItemEntity( newent )
			
			self:SetNextPickup( CurTime() + self:GetRespawnTime() )
			
		end
		
	end
	
end