AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include('shared.lua')

function ENT:Initialize()
		
	self.IsMaster = true
	self.Pod = nil
	self.Driver = nil
	self.Stabilised = false

	self.Inputs = Wire_CreateInputs( self.Entity, { "Stabilise" } )
	self.Outputs = WireLib.CreateOutputs( self.Entity, { "Ready" } )
	self.WireDebugName = "ACF Track"

end  

function MakeACF_ViewPod(Owner, Pos, Angle, Id)

	if not Owner:CheckLimit("_acf_misc") then return false end
	
	local Ent = ents.Create("acf_track")
	local List = list.Get("ACFEnts")
	local Classes = list.Get("ACFClasses")
	
	if not Ent:IsValid() then return false end
	Ent:SetAngles(Angle)
	Ent:SetPos(Pos)
	Ent:Spawn()
	
	Ent.Model = List["Sensors"][Id]["model"]

	Ent:SetPlayer(Owner)
	Ent.Owner = Owner
	Ent:SetModel( Ent.Model )	
	
	Ent:PhysicsInit( SOLID_VPHYSICS )      	
	Ent:SetMoveType( MOVETYPE_VPHYSICS )     	
	Ent:SetSolid( SOLID_VPHYSICS )
	
	undo.Create("ACF Track")
		undo.AddEntity( Ent )
		undo.SetPlayer( Owner )
	undo.Finish()
		
	return Ent
end
list.Set( "ACFCvars", "acf_viewpod" , {"id"} )
duplicator.RegisterEntityClass("acf_viewpod", MakeACF_ViewPod, "Pos", "Angle", "Id")

function ENT:TriggerInput( iname , value )

	if (iname == "Stabilise") then
		if value > 0 then
			if not self.Stabilised then
				self:Stabilise()
			end
		else
			self:Stop()
		end
	end		

end

function ENT:Think()

	if self.Pod and self.Pod:GetDriver() != self.Driver then
		self:Stop()
	end
	
	self.Entity:NextThink(CurTime() + 1)
	return true
	
end

function ENT:PreEntityCopy()
	
	//Wire dupe info
	local DupeInfo = WireLib.BuildDupeInfo(self.Entity)
	if(DupeInfo) then
		duplicator.StoreEntityModifier(self.Entity,"WireDupeInfo",DupeInfo)
	end
	
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	
	//Wire dupe info
	if(Ent.EntityMods and Ent.EntityMods.WireDupeInfo) then
		WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end

end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end


