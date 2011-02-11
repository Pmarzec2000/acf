AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include('shared.lua')

function ENT:Initialize()
	
	self.Throttle = 0
	self.Active = false
	self.IsMaster = true
	self.GearLink = {}
	self.GearRPM = {}
	self.GearRope = {}
	
	self.LastCheck = 0
	self.Mass = 0
	self.PhysMass = 0
	self.MassRatio = 1
	self.Legal = true
	
	self.Inputs = Wire_CreateInputs( self.Entity, { "Active", "Throttle" } )
	self.Outputs = WireLib.CreateSpecialOutputs( self.Entity, { "RPM", "Torque", "Power", "Entity" , "Mass" , "Physical Mass" }, { "NORMAL" ,"NORMAL" ,"NORMAL" , "ENTITY" , "NORMAL" , "NORMAL" } )
	Wire_TriggerOutput(self.Entity, "Entity", self.Entity)
	self.WireDebugName = "ACF Engine"

end  

function MakeACF_Engine(Owner, Pos, Angle, Id)

	if not Owner:CheckLimit("_acf_misc") then return false end
	
	local Engine = ents.Create("ACF_Engine")
	local List = list.Get("ACFWeapons")
	local Classes = list.Get("ACFClasses")
	if not Engine:IsValid() then return false end
	Engine:SetAngles(Angle)
	Engine:SetPos(Pos)
	Engine:Spawn()

	Engine:SetPlayer(Owner)
	Engine.Owner = Owner
	Engine.Id = Id
	Engine.Model = List["Mobility"][Id]["model"]
	Engine.SoundPath = List["Mobility"][Id]["sound"]
	Engine.Mass = List["Mobility"][Id]["weight"]
	Engine.PeakTorque = List["Mobility"][Id]["torque"]
	Engine.IdleRPM = List["Mobility"][Id]["idlerpm"]
	Engine.PeakMinRPM = List["Mobility"][Id]["peakminrpm"]
	Engine.PeakMaxRPM = List["Mobility"][Id]["peakmaxrpm"]
	Engine.LimitRPM = List["Mobility"][Id]["limitprm"]
	Engine:SetModel( Engine.Model )	
	Engine.Sound = nil
	Engine.RPM = {}
	
	Engine:PhysicsInit( SOLID_VPHYSICS )      	
	Engine:SetMoveType( MOVETYPE_VPHYSICS )     	
	Engine:SetSolid( SOLID_VPHYSICS )

	local phys = Engine:GetPhysicsObject()  	
	if (phys:IsValid()) then 
		phys:SetMass( Engine.Mass ) 
	end
	
	undo.Create("ACF Engine")
		undo.AddEntity( Engine )
		undo.SetPlayer( Owner )
	undo.Finish()
	
	Owner:AddCount("_acf_engine", Engine)
	Owner:AddCleanup( "acfmenu", Engine )
	
	return Engine
end
list.Set( "ACFCvars", "acf_engine" , {"id"} )
duplicator.RegisterEntityClass("acf_engine", MakeACF_Engine, "Pos", "Angle", "Id")

function ENT:TriggerInput( iname , value )

	if (iname == "Throttle") then
		self.Throttle = math.Clamp(value,0,100)/100
	elseif (iname == "Active") then
		if (value > 0 and not self.Active) then
			self.Active = true
			self.Sound = CreateSound(self, self.SoundPath)
			self.Sound:PlayEx(0.5,100)
			self:ACFInit()
		elseif (value <= 0 and self.Active) then
			self.Active = false
			self.RPM = {}
			self.RPM[1] = self.IdleRPM
			if self.Sound then
				self.Sound:Stop()
			end
			self.Sound = nil
		end
	end		


end

function ENT:Think()

	local Time = CurTime()
	
	if self.Active then
			
		if self.Legal then		
			local EngPhys = self:GetPhysicsObject()
			local RPM = self:CalcRPM( EngPhys )
		end
		
		if self.LastCheck > CurTime() then
			self:CheckRopes()
			if self.Entity:GetPhysicsObject():GetMass() <= self.Mass or self.Entity:GetParent():IsValid() then
				self.Legal = false
			else 
				self.Legal = true
			end
			
			self.LastCheck = Time + math.Rand(5,10)
		end
	
	end

	self.Entity:NextThink(Time)
	return true
	
end

function ENT:ACFInit()

	if not constraint.HasConstraints(self) then return end
	
	local Constrained = constraint.GetAllConstrainedEntities(self)
	self.Mass = 0
	self.PhysMass = 0
	
	for _,Ent in pairs(Constrained) do
	
		if validEntity(Ent) then
			local Phys = Ent:GetPhysicsObject()
			
			if Phys and Phys:IsValid() then
				self.Mass = self.Mass + Phys:GetMass()
				local Parent = Ent:GetParent()
				
				if validEntity(Parent) then
					local Constraints = constraint.FindConstraints(Ent, "Weld")
					
					if Constraints then
					
						for Key,Weld in pairs(Constraints) do
							
							if Weld.Ent1 == Parent or Weld.Ent2 == Parent then
								self.PhysMass = self.PhysMass + Phys:GetMass()
							end
							
						end
						
					end
						
				else
					self.PhysMass = self.PhysMass + Phys:GetMass()
				end
				
			end
			
		end
		
	end
	
	self.MassRatio = self.PhysMass/self.Mass
	
	Wire_TriggerOutput(self.Entity, "Mass", math.floor(self.Mass))
	Wire_TriggerOutput(self.Entity, "Physical Mass", math.floor(self.PhysMass))

end

function ENT:CalcRPM( EngPhys )

	local RPM = 0
	local Freespin = true
	local Boxes = table.Count(self.GearLink)
	//The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	for Key, Gearbox in pairs(self.GearLink) do 	--First, let's calculate the gearboxes RPM
		self.GearRPM[Key] = Gearbox:Calc()
		if self.GearRPM[Key] then
			RPM = RPM + self.GearRPM[Key]
			Freespin = false
		end
	end
	
	if Freespin then	--If the engine isn't connceted to any in gear gearbox, calculate the RPM by itself
		RPM = math.max(self.RPM[1] * (1 + (self.Throttle - self.RPM[1]/self.LimitRPM)),self.IdleRPM)
	else	--If it is connected to in gear gearboxes, calculate the RPM by their returns
		RPM = math.max(RPM / Boxes ,self.IdleRPM) or self.IdleRPM	
	end
	
	table.remove( self.RPM, 10 )	--Then we calc a smoothed RPM value for the sound effects
	table.insert( self.RPM, 1, RPM )
	local SmoothRPM = 0
	for Key, RPM in pairs(self.RPM) do
		SmoothRPM = SmoothRPM + (RPM or 0)
	end
	SmoothRPM = SmoothRPM/10

	local Torque = self.Throttle * math.max( self.PeakTorque * math.min( RPM/self.PeakMinRPM , (self.LimitRPM - RPM)/(self.LimitRPM - self.PeakMaxRPM), 1 ),0 ) --Calculate the current torque from RPM
	
	for Key, Gearbox in pairs(self.GearLink) do	--Then give the gearboxes the powa
		Gearbox:Act(Torque*self.MassRatio/Boxes)
	end
	
	local Power = Torque * SmoothRPM / 701.8368
	Wire_TriggerOutput(self.Entity, "Torque", math.floor(Torque))
	Wire_TriggerOutput(self.Entity, "Power", math.floor(Power))
	Wire_TriggerOutput(self.Entity, "RPM", SmoothRPM)
	self.Sound:ChangePitch(math.min(20 + SmoothRPM/50,255))
	self.Sound:ChangeVolume(0.2 + self.Throttle/4)
	
	return RPM
end

function ENT:CheckRopes()
	
	for GearboxKey,Ent in pairs(self.GearLink) do
		local Constraints = constraint.FindConstraints(Ent, "Rope")
		if Constraints then
		
			local Clean = false
			for Key,Rope in pairs(Constraints) do
				if Rope.Ent1 == self.Entity or Rope.Ent2 == self.Entity then
					if Rope.length + Rope.addlength < self.GearRope[GearboxKey]*1.5 then
						Clean = true
					end
				end
			end
			
			if not Clean then
				self:Unlink( Ent )
			end
			
		else
			self:Unlink( Ent )
		end
	end
	
end

function ENT:Link( Target )

	if ( !Target or Target:GetClass() != "acf_gearbox" ) then return ("Can only link to Gearboxes") end
	
	local Duplicate = false
	for Key,Value in pairs(self.GearLink) do
		if Value == Target then
			Duplicate = true
		end
	end
	
	if not Duplicate then
		table.insert(self.GearLink,Target)
		table.insert(Target.Master,self.Entity)
		
		local RopeL = (self.Entity:GetPos()-Target:GetPos()):Length()
		constraint.Rope( self.Entity, Target, 0, 0, Vector(0,0,0), Vector(0,0,0), RopeL, RopeL*0.2, 0, 1, "cable/cable2", false )
		table.insert(self.GearRope,RopeL)
		
		return false
	else
		return ("This Gearbox is already linked to this Engine")
	end
	
	
end

function ENT:Unlink( Target )

	local Success = false
	for Key,Value in pairs(self.GearLink) do
		if Value == Target then
			table.remove(self.GearLink,Key)
			table.remove(self.GearRope,Key)
			Success = true
		end
	end
			
	if Success then
		return false
	else
		return ("Did not find the Gearbox to unlink")
	end
	
end

function ENT:PreEntityCopy()

	//Link Saving
	local info = {}
	local entids = {}
	for Key, Value in pairs(self.GearLink) do					--First clean the table of any invalid entities
		if not Value:IsValid() then
			table.remove(self.GearLink, Value)
		end
	end
	for Key, Value in pairs(self.GearLink) do					--Then save it
		table.insert(entids, Value:EntIndex())
	end
	
	info.entities = entids
	if info.entities then
		duplicator.StoreEntityModifier( self.Entity, "GearLink", info )
	end
	
	//Wire dupe info
	local DupeInfo = WireLib.BuildDupeInfo(self.Entity)
	if(DupeInfo) then
		duplicator.StoreEntityModifier(self.Entity,"WireDupeInfo",DupeInfo)
	end
	
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )

	//Link Pasting
	if (Ent.EntityMods) and (Ent.EntityMods.GearLink) and (Ent.EntityMods.GearLink.entities) then
		local GearLink = Ent.EntityMods.GearLink
		if GearLink.entities and table.Count(GearLink.entities) > 0 then
			for _,ID in pairs(GearLink.entities) do
				local Linked = CreatedEntities[ ID ]
				if Linked and Linked:IsValid() then
					self:Link( Linked )
				end
			end
		end
		Ent.EntityMods.GearLink = nil
	end
	
	//Wire dupe info
	if(Ent.EntityMods and Ent.EntityMods.WireDupeInfo) then
		WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end

end

function ENT:OnRemove()
	if self.Sound then
		self.Sound:Stop()
	end
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end


