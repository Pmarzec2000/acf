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
	self.WireDebugName = "ACF ViewPod"

end  

function MakeACF_ViewPod(Owner, Pos, Angle, Id)

	if not Owner:CheckLimit("_acf_misc") then return false end
	
	local Ent = ents.Create("acf_viewpod")
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
	
	undo.Create("ACF ViewPod")
		undo.AddEntity( Ent )
		undo.SetPlayer( Owner )
	undo.Finish()
		
	return Ent
end
list.Set( "ACFCvars", "acf_viewpod" , {"id"} )
duplicator.RegisterEntityClass("acf_viewpod", MakeACF_ViewPod, "Pos", "Angle", "Id")

function ENT:Link( Target )

	if ( !Target or Target:GetClass() != "prop_vehicle_prisoner_pod" ) then return ("Only links to pods !") end

	self.Pod = Target
	
	self:EmitSound("weapons/357/357_reload4.wav",500,100)

	return false
	
end

function ENT:Unlink( Target )

	self.Pod = nil
	return true
	
end

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

function ENT:Stabilise()
	
	if self.Pod:IsValid() then
		self.Driver = self.Pod:GetDriver()
		if self.Driver and self.Driver:IsValid() then
			self.Stabilised = true
			self.Driver:SetNWEntity("ACFViewPod",self.Pod)
			umsg.Start( "ACFViewReset" )
				umsg.Angle( self.Driver:EyeAngles() )
			umsg.End()
		end
	end
	
end

function ENT:Stop()

	self.Stabilised = false
	if self.Driver and self.Driver:IsValid() then
		self.Driver:SetNWEntity("ACFViewPod",NullEntity())
		self.Driver = nil
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

	local info = {}
	local entids = {}
	if self.Pod:IsValid() then
		table.insert(entids, self.Pod:EntIndex())
	end
	info.entities = entids
	if info.entities then
		duplicator.StoreEntityModifier( self.Entity, "ACFLink", info )
	end
	
	//Wire dupe info
	local DupeInfo = WireLib.BuildDupeInfo(self.Entity)
	if(DupeInfo) then
		duplicator.StoreEntityModifier(self.Entity,"WireDupeInfo",DupeInfo)
	end
	
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )

	if (Ent.EntityMods) and (Ent.EntityMods.ACFLink) and (Ent.EntityMods.ACFLink.entities) then
		local Link = Ent.EntityMods.ACFLink
		if Link.entities and table.Count(Link.entities) > 0 then
			for _,EntID in pairs(Link.entities) do
				local Pod = CreatedEntities[ EntID ]
				if Pod and Pod:IsValid() then
					self:Link( Pod )
				end
			end
		end
		Ent.EntityMods.ACFLink = nil
	end
	
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


