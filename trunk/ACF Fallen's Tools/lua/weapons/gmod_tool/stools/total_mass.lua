TOOL.Category		= "Construction"
TOOL.Name			= "#ACF Total Mass"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["masstext"] = "0"
TOOL.ClientConVar["gravtext"] = "0"
TOOL.ClientConVar["drawindicator"] = "0"
TOOL.ClientConVar["size"] = "1"

if CLIENT then
	language.Add( "Tool_total_mass_name", "ACF Total Mass Tool" )
	language.Add( "Tool_total_mass_desc", "Get total mass and mass center of a contraption" )
	language.Add( "Tool_total_mass_0", "Primary: Select (+Use to select constrained entities, +Shift to radius select +Reload to clear selection)   Secondary: Get total mass   Reload: Get centre of gravity for contraption" )
	//language.Add( "Tool_total_mass_radius", "Radius Select" )
	//language.Add( "Tool_total_mass_radius_desc", "Select props within a certain radius" )
end
local Ents = {}

local function DoColorEffect( tab )
	if CLIENT or !tab then return end

	for ent , v in pairs( tab ) do
		if IsValid( ent ) and !ent:IsWorld() then
			if !ent:GetPhysicsObject():IsValid() then
				tab[ent] = nil
			else
				local col = Color(ent:GetColor())
				if v.r != col.r or v.g != col.g or v.b != col.b or v.a != col.a then
					tab[ent] = col
					ent:SetColor( 100 , 0 , 0 , 100 )

				end
			end
		end
	end
	return tab
end

function TOOL:LeftClick( trace )
	if CLIENT then return true end
	local ent = trace.Entity


	if Ents[ ent ] then
		local col = Ents[ ent ]
		ent:SetColor( col.r , col.g , col.b , col.a )
		Ents[ ent ] = nil
		return true
	end

	if self:GetOwner():KeyDown( IN_USE ) then
		local tab = constraint.GetAllConstrainedEntities( ent )
		for Ent , col in pairs(tab) do
			if Ents[ Ent ] then
				tab[Ent] = nil
			end
		end
		Ents = table.Merge( DoColorEffect(tab) , Ents)

		
	//elseif self:GetOwner():KeyDown( IN_SPEED ) then
	//	PrintTable(ents.FindInSphere( trace.HitPos , tonumber(self:GetClientInfo("radius")) or 100 ))
	//	Ents = DoColorEffect( {} )
	else
		if IsValid( ent ) and !ent:IsWorld() then
			Ents[ ent ] = Color( ent:GetColor() )
			ent:SetColor( 100 , 0 , 0 , 100 )
		end
	end
	
	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return true end
	local mass = 0
	for ent , color in pairs( Ents ) do
		if IsValid(ent) then
			mass = mass + ent:GetPhysicsObject():GetMass()
			ent:SetColor(color.r , color.g , color.b , color.a )
		end
	end
	Ents = {}
	self:GetOwner():PrintMessage(HUD_PRINTCENTER , "Total Constrained Mass is: "..tostring(mass) )
	if tobool(self:GetClientInfo("masstext")) then
		umsg.Start( "total_mass_settext" , self:GetOwner() )
			umsg.String( tostring( mass ) )
		umsg.End()
	end
	return true
end

function TOOL:Reload( trace )
	if CLIENT then return true end
	if !IsValid(trace.Entity) or trace.Entity:IsWorld() then return end 
	local mass = 0
	local pos = Vector(0)
	for ent , color in pairs( Ents ) do
		if IsValid(ent) then
			local parent = ent:GetParent()
			if parent == NULL then
				local phys = ent:GetPhysicsObject()
				mass = mass + phys:GetMass()
				pos = pos + ent:LocalToWorld(phys:GetMassCenter()) * phys:GetMass()
			end
			ent:SetColor(color.r , color.g , color.b , color.a )
		end
	end
	local Centre_Grav = pos / mass
	local localpos = trace.Entity:WorldToLocal(Centre_Grav)

	self:GetOwner():PrintMessage(HUD_PRINTCENTER , "Total Physical Mass is: "..tostring(mass) )

	if tobool(self:GetClientInfo("gravtext")) then
		umsg.Start( "total_mass_settext" , self:GetOwner() )
			local text = tostring(localpos):gsub(" " , " , " )
			umsg.String( text )
		umsg.End()
	end

	umsg.Start( "total_mass_indicatorpos" , self:GetOwner() )
		umsg.Entity( trace.Entity )
		umsg.Float(localpos.x)
		umsg.Float(localpos.y)
		umsg.Float(localpos.z)
		umsg.Float( tonumber(self:GetClientInfo("drawindicator")) or 0 )
	umsg.End()

	self.SWEP:DoShootEffect( trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone, false )
	Ents = {}
	return true
end

if CLIENT then
	function TOOL.BuildCPanel( cp )
		cp:AddControl("CheckBox", { Label = "Set clipboard text to total mass?", Command = "total_mass_masstext" } )
		cp:AddControl("CheckBox", { Label = "Set clipboard text to centre of gravity?", Command = "total_mass_gravtext" } )

		local pnl = cp:AddControl("Slider", { Label = "Drawing time", Type = "Numeric", Min = "1", Max = "60", Command = "total_mass_drawindicator" } )
		pnl:SetToolTip("This value is to set how long the centre of gravity indicator will draw for (In seconds)")

		local pnl = cp:AddControl("Slider", { Label = "Indicator size", Type = "Numeric", Min = "1", Max = "100", Command = "total_mass_size" } )
		pnl:SetToolTip("This value is to set how big the indicator is")
	end
	local function GetText( um )
		SetClipboardText( um:ReadString() )
	end
	usermessage.Hook( "total_mass_settext" , GetText)

	local Ent , pos , Draw = NULL , Vector(0) , false
	local function GetDisplaypos( um )
		Ent = um:ReadEntity()
		pos = Vector( um:ReadFloat() , um:ReadFloat() , um:ReadFloat() )
		local length = um:ReadFloat()
		hook.Add("PostDrawOpaqueRenderables" , "Total_Mass.Indicator" , DrawIndicator )
		if length > 0 then
			timer.Simple(length , function()
				hook.Remove("PostDrawOpaqueRenderables" , "Total_Mass.Indicator")
			end)
		else
			hook.Remove("PostDrawOpaqueRenderables" , "Total_Mass.Indicator")
		end
	end
	usermessage.Hook( "total_mass_indicatorpos" , GetDisplaypos )

	local scale = 1
	cvars.AddChangeCallback("total_mass_size",function(_,_,new)
		scale = tonumber( new )
	end)

	local cube = NewMesh()
	cube:BuildFromTriangles(MeshCube( 2 , 2 , Vector(0) ))
	local matr = Material("models/debug/debugwhite")
	local function DrawIndicator()
		if Ent==NULL or !IsValid(Ent) then return end
		local mat = Matrix()
	    mat:Translate( Ent:LocalToWorld( pos ) );
	    mat:Rotate( Ent:GetAngles() );
	    mat:Scale( Vector() * scale );

		render.ResetModelLighting(1,1,1);
	    render.SetMaterial( matr);
	    cam.PushModelMatrix( mat );
	        cube:Draw()
	    cam.PopModelMatrix()
	end
end
