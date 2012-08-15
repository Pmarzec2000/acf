
TOOL.Category		= "Constraints"
TOOL.Name			= "Multi-UnParent"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_multi_unparent_name", "Multi-UnParent Tool" )
    language.Add( "Tool_multi_unparent_desc", "UnParent multiple props." )
    language.Add( "Tool_multi_unparent_0", "Primary: Select a prop to UnParent. (Use to select all) Secondary: UnParent all selected props. Reload: Clear Targets." )
end
TOOL.enttbl = {}

function TOOL:DoSingleColor( ent , override )
	if !self.enttbl[ent] then
		self.enttbl[ent] = Color(ent:GetColor())
		ent:SetColor(255,255,255,100)
	elseif !override then
		local col = self.enttbl[ent]
		ent:SetColor( col.r , col.g , col.b , col.a )
		self.enttbl[ent] = nil
	end
end


function TOOL:LeftClick( trace )
	if (CLIENT) then return true end
	local ent = trace.Entity
	if !IsValid(ent) then return end
	if ent:IsPlayer() or !util.IsValidPhysicsObject( ent, trace.PhysicsBone ) or ent:IsWorld() then return end
	

	if (self:GetOwner():KeyDown(IN_USE)) then
		for k,v in pairs(constraint.GetAllConstrainedEntities(ent)) do
			self:DoSingleColor( v , true )
		end
	else
		self:DoSingleColor(ent)
	end
	
	return true
end

function TOOL:RightClick( trace )
	if (CLIENT) then return true end
	local ent = trace.Entity
	if !IsValid(ent) then return end
	if ent:IsPlayer() or !util.IsValidPhysicsObject( ent, trace.PhysicsBone ) or ent:IsWorld() or table.Count(self.enttbl) < 1 then return end
	
	local pos , phys
	for prop,v in pairs(self.enttbl) do
		if IsValid(prop) then
			pos = prop:GetPos()
			phys = prop:GetPhysicsObject()
			if phys:IsValid() then
				phys:EnableCollisions(true)
				phys:EnableMotion(false)
				phys:Sleep()
				prop:SetParent()
				prop:SetPos(pos)
				self:DoSingleColor( prop )
			end
		end
	end
	self.enttbl = {}
	return true
end

function TOOL:Reload()
	if (CLIENT) then return false end
	if (table.Count(self.enttbl) < 1) then return end
	for prop,v in pairs(self.enttbl) do
		self:DoSingleColor( prop )
	end
	self.enttbl = {}
	return true
end

