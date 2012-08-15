local norm , d = Angle(0,0,0) , 0 

cvars.AddChangeCallback("visual_p",function(_,_,new)
	norm.p = tonumber(new) or 0	
end)
cvars.AddChangeCallback("visual_y",function(_,_,new)
	norm.y = tonumber(new) or 0
end)
cvars.AddChangeCallback("visual_distance",function(_,_,new)
	d = tonumber(new) or 0	
end)
cvars.AddChangeCallback("visual_adv_distance",function(_,_,new)
	d = tonumber(new) or 0		
end)

concommand.Add("visual_adv_reset",function()
	norm = Angle(0,0,0)
	RunConsoleCommand("visual_adv_distance" , 0)
end)
concommand.Add("visual_reset",function()
	RunConsoleCommand("visual_p",0)
	RunConsoleCommand("visual_y",0)
	RunConsoleCommand("visual_distance",0)
end)

local function ClipData( um )
	norm = Angle(um:ReadFloat() , um:ReadFloat() , um:ReadFloat())
	d = um:ReadFloat()
	RunConsoleCommand("visual_adv_distance",d)
end
usermessage.Hook("visual_clip_data" , ClipData)



local halfmodel1 = ClientsideModel("error.mdl")
halfmodel1:SetNoDraw(true)
local halfmodel2 = ClientsideModel("error.mdl")
halfmodel2:SetNoDraw(true)


local last = NULL
local function drawpreview()
	local e = LocalPlayer():GetEyeTraceNoCursor().Entity
	if last == e and IsValid(e) then 
		e:SetModelScale(Vector(0))
		e.Clipped = false
	else
		if IsValid(last) then
			last:SetModelScale(Vector())
			last.Clipped = true
		end
		last = NULL
	end

	if !ValidEntity(LocalPlayer()) or !ValidEntity(e) or !LocalPlayer():Alive() or !ValidEntity(LocalPlayer():GetActiveWeapon())then return end
	if LocalPlayer():GetActiveWeapon():GetClass() != "gmod_tool" or (GetConVarString("gmod_toolmode") != "visual_adv" and GetConVarString("gmod_toolmode") != "visual") or e:IsPlayer() or e:IsWorld() or !LocalPlayer():Alive() then
		if IsValid(last) then	
			last:SetModelScale(Vector())
			last.Clipped = true
		end 
		last = NULL
		return
	end	

	last = e
	if halfmodel1:GetModel() != e:GetModel() then
		halfmodel1:SetModel(e:GetModel() )
		halfmodel2:SetModel(e:GetModel() )
	end
	local e_pos = e:LocalToWorld( e:OBBCenter() )

	halfmodel1:SetPos(e:GetPos())
	halfmodel1:SetAngles(e:GetAngles())
	halfmodel2:SetPos(e:GetPos())
	halfmodel2:SetAngles(e:GetAngles())

	local n = -e:LocalToWorldAngles(norm):Forward()


	render.EnableClipping(true)
	render.SetColorModulation(0,1000,0)			
	render.PushCustomClipPlane(-n, -n:Dot(e_pos-n*d) ) -- n , 
		halfmodel2:DrawModel()
	render.PopCustomClipPlane()	

	render.SetColorModulation(1000,0,0)			
	render.PushCustomClipPlane(n, n:Dot(e_pos-n*d) ) -- n , 
		halfmodel1:DrawModel()
	render.PopCustomClipPlane()
	render.SetColorModulation(1,1,1)		
	render.EnableClipping(false)
	
end
hook.Add("PostDrawOpaqueRenderables" , "VisualClip.Preview" , drawpreview )