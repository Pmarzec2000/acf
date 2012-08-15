local cvar = CreateClientConVar("max_clips_per_prop" , 3 , true , false )
local max = cvar:GetInt()
local GetProps = ents.FindByClass
local render = render
local entm = _R.Entity
local vec_none , vec_norm = Vector(0,0,0) , Vector(1,1,1)

cvars.AddChangeCallback( "max_clips_per_prop" ,function(_,_,new)
	max = tonumber(new) or 0
	for k , v in pairs( GetProps("prop_physics") ) do
		if max < #v.ClipData then
			v.ClipPlaneDrawn = max
		else
			v.ClipPlaneDrawn = #v.ClipData
		end
	end	
end)

local n , inside , r , g , b , a , enabled

local function RenderOverride(self)
	if self.ClipData and IsValid(self) and self.Clipped then

		enabled = render.EnableClipping( true )

		r,g,b,a = entm.GetColor( self )

		render.SetColorModulation(r/255,g/255,b/255)
		render.SetBlend(a/255)
		for i = 1 , self.ClipPlaneDrawn do
			inside = self.ClipData[i][3]
			
			n = entm.LocalToWorldAngles(self ,self.ClipData[i][1]):Forward()
			
			render.PushCustomClipPlane(n, (entm.LocalToWorld(self ,self.ClipData[i][4])+n*self.ClipData[i][2] ):Dot(n))

		end

		entm.SetModelScale(self ,vec_norm)
		entm.SetupBones( self )		
		entm.DrawModel( self )
		if inside then
			render.CullMode(MATERIAL_CULLMODE_CW)
				entm.DrawModel( self )
			render.CullMode(MATERIAL_CULLMODE_CCW)
		end
		for i = 1 , self.ClipPlaneDrawn do
			render.PopCustomClipPlane()
		end											
		entm.SetModelScale( self , vec_none )

		render.SetBlend(1)
		render.SetColorModulation(1,1,1)
		render.EnableClipping( enabled )
	end
	
end

local function AddPropClip( um )

	local Entity , n , d , inside , new = um:ReadEntity() , Angle(um:ReadFloat() , um:ReadFloat() , um:ReadFloat() ) , um:ReadFloat() , um:ReadBool() ,um:ReadBool()
	if !IsValid(Entity) or !n or !d then return end
	Entity:SetModelScale(Vector() * 0 )

	Entity.ClipData = Entity.ClipData or {}
	Entity.Clipped = true
		
	local offset
	if new then
		offset = Entity:OBBCenter()
	else
		offset = Vector()
	end
	Entity.ClipData[ #Entity.ClipData + 1] = {n,d,inside, offset}
	if !Entity.ClipPlaneDrawn then
		Entity.ClipPlaneDrawn = 1
	end
	if #Entity.ClipData <= max then
		Entity.ClipPlaneDrawn = #Entity.ClipData
	end
	timer.Simple(0.1 , function()
		Entity.RenderOverride = RenderOverride
	end)
end
usermessage.Hook("visual_clip_newclip" , AddPropClip)

local function ResetClip(um)
	local ent = um:ReadEntity()
	if !IsValid(ent) then return end
	ent.ClipData = ent.ClipData or {}
	local count = #ent.ClipData
	ent.ClipData[ count ] = nil
	ent.ClipPlaneDrawn = #ent.ClipData
	if count == 1 then
		ent:SetNoDraw(false)
		ent:SetModelScale(Vector()*1)
		ent.ClipData = {}
		ent.Clipped = false
		ent.RenderOverrride = nil
	end
end
usermessage.Hook("visual_clip_reset" , ResetClip)


hook.Add("InitPostEntity" , "RequestClips" , function()
	timer.Simple( 5 , function() RunConsoleCommand( "cliptool_request_clips" ) end)
end)

MsgN("clipping reloaded")
concommand.Add("reload_clipping" , function( ply , cmd , arg )
	include("autorun/client/clipping.lua")
end)