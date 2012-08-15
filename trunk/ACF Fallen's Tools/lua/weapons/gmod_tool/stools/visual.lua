/*
Visual Clip Tool
	by TGiFallen
	Credits to Ralle105 of facepunch
*/

TOOL.Category		= "Construction"
TOOL.Name			= "#ACF Visual Clip"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["distance"] = "1"
TOOL.ClientConVar["p"] = "0"
TOOL.ClientConVar["y"] = "0"
TOOL.ClientConVar["inside"] = "0"


if CLIENT then
	language.Add( "Tool_visual_name", "Visual Clip Tool" )
	language.Add( "Tool_visual_desc", "Visually Clip Models" )
	language.Add( "Tool_visual_0", "Primary: Create a plane to clip on	Secondary: Clip Model (Do BEFORE you parent)	Reload: Remove Clips" )
end


function TOOL:LeftClick( trace )
	if CLIENT then return true end
	local ent = trace.Entity
	if !ent:IsValid() or ent:IsWorld() or ent:IsPlayer() or ent==NULL then return end
	ent.ClipData = ent.ClipData or {}

	local ind = table.insert(ent.ClipData , {
		n = Angle(self:GetClientInfo("p"),self:GetClientInfo("y"),0),
		d = self:GetClientInfo("distance"),
		inside = tobool( self:GetClientInfo("inside") or false ),
		new = true
	})
	SendPropClip( ent , nil , ind )
	duplicator.StoreEntityModifier( ent , "clips", ent.ClipData )
	if !table.HasValue( Clipped , ent ) then
		Clipped[ #Clipped + 1 ] =  ent
	end
	return true
end

function TOOL:RightClick( trace )

	return true;
end

function TOOL:Reload( trace )
	if CLIENT then return true end
	local ent = trace.Entity
	if !IsValid(ent) then return end
	ent.ClipData = ent.ClipData or {}
	local count = #ent.ClipData
	ent.ClipData[ count ] = nil
	if count == 1 then
		ent.ClipData = {}
		for k , v in pairs(Clipped) do
			if v == ent then
				Clipped[ k ] = nil
			end
		end
	end
	umsg.Start("visual_clip_reset")
		umsg.Entity(ent)
	umsg.End()
	return true
end

if CLIENT then
	function TOOL.BuildCPanel( cp )
		cp:AddControl( "Header", { Text = "#Tool_visual_name", Description	= "#Tool_visual_desc" }  )

		cp:AddControl("Slider", { Label = "Distance", Type = "int", Min = "-100", Max = "100", Command = "visual_distance" } )
		cp:AddControl("Slider", { Label = "Pitch", Type = "int", Min = "-180", Max = "180", Command = "visual_p" } )
		cp:AddControl("Slider", { Label = "Yaw", Type = "int", Min = "-180", Max = "180", Command = "visual_y" } )
		cp:AddControl("Button", {Label = "Reset",Command = "visual_reset"})	
		cp:AddControl("CheckBox" , {Label = "Render inside of prop", Description = "Clicking this will render the inside of the prop", Command = "visual_inside" } )
		cp:AddControl("Slider", { Label = "Max Clips Per Prop", Type = "int", Min = "0", Max = "25", Command = "max_clips_per_prop" } )

	end
end
