AddCSLuaFile( "shared.lua" )
 
include('shared.lua')

-- function ENT:SpawnFunction( ply, tr)
	-- local SpawnPos = tr.HitPos + tr.HitNormal * 100
	-- local ent = ents.Create( "ACF_Battlepod" )
	-- ent:SetPos( SpawnPos )
	-- ent:Spawn()
	-- ent:Activate()
	-- return ent
-- end

function ENT:Initialize()
	self:SetModel( "models/Vehicles/pilot_seat.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:PhysWake()
	
	self:SetKeyValue("classname", "prop_vehicle_prisoner_pod")
	self:SetUseType( SIMPLE_USE )
end

function ENT:Use(Driver, caller)
	self:Enter( Driver )
end

function ENT:Enter( Driver )
	if gamemode.Call("CanPlayerEnterVehicle", Driver, self.Entity, 0) then
		if ( self.Driver == nil and Driver:IsValid() ) then
			self.Driver = Driver
			self.Driver:SetMoveType( MOVETYPE_NOCLIP )
			self.Driver:SetPos( self.Entity:GetPos() )
			self.Driver:SetAngles( posang.Ang )
			self.Driver:SetNotSolid( true )
			self.Driver:SetParent( self.Entity )
			self.Driver:SetNWEntity( "acf_pod", self.Entity )
			self.Driver:SetNWBool( "in_acf_pod", true )
		end
	end
end

function ENT:Exit()	
	if ( !self.Driver == nil and self.Driver:IsValid() ) then
		self.Driver:SetParent()
		self.Driver:SetMoveType( MOVETYPE_WALK )
		self.Driver:SetNotSolid( false )
		self.Driver:SetPos( self.Entity:GetPos() + Vector(0,0,80) + (self.Driver:GetAimVector() * 70) )
		self.Driver:SetVelocity( self.Entity:GetVelocity() )
		self.Driver:SetNWEntity( "acf_pod", NULL )
		self.Driver:SetNWBool( "in_acf_pod", false )
		hook.Call( "PlayerLeaveVehicle", gmod.GetGamemode(), self.Driver, self.Entity )
	end
	self.Driver = nil
end

hook.Add( "KeyPress", "ACF Battlepod", function( Driver, Key )
	if not ValidEntity( Driver ) then return end
	if Driver:GetNWBool( "in_acf_pod" ) then
		if Key == IN_USE and ValidEntity( Driver ) then
			Driver:GetNWEntity("acf_pod"):Exit()
		end
	end
end )

hook.Add( "PlayerDeath", "ACF Battlepod", function( Driver )
	if not ValidEntity( Driver ) then return end
	if Driver:GetNWBool( "in_acf_pod" ) then
		if Key == IN_USE and ValidEntity( Driver ) then
			Driver:GetNWEntity("acf_pod"):Exit()
		end
	end
end )

function ENT:OnRemove()
	if ValidEntity( self.Driver ) then
		self:Exit()
	end
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

function ENT:BuildDupeInfo()
	return WireLib.BuildDupeInfo(self.Entity)
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
end

function ENT:PreEntityCopy()
	//build the DupeInfo table and save it as an entity mod
	local DupeInfo = self:BuildDupeInfo()
	if(DupeInfo) then
		duplicator.StoreEntityModifier(self.Entity,"WireDupeInfo",DupeInfo)
	end
end

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	//apply the DupeInfo
	if(Ent.EntityMods and Ent.EntityMods.WireDupeInfo) then
		Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
end

