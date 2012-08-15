/*
Weight STool 1.21
	by Spoco
*/

TOOL.Category		= "Construction"
TOOL.Name			= "#ACF MultiTool"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["set"] = "1"
TOOL.ClientConVar["thick"] = "1"
if CLIENT then
	language.Add( "Tool_acf_weight_name", "Weight Tool" )
	language.Add( "Tool_acf_weight_desc", "Sets objects weight" )
	language.Add( "Tool_acf_weight_0", "Primary: Set   Secondary: Copy   Reload: Set weight according to thickness   E + Click: Get total mass of a constrained contraption" )
	language.Add( "Tool_acf_weight_set", "Weight:" )
	language.Add( "Tool_acf_weight_set_desc", "Set the weight" )
	language.Add( "Tool_acf_weight_thick" , "Armour Thickness")
	language.Add( "Tool_acf_weight_thick_desc" , "Set A thickness and the weight will be scaled" )
	language.Add( "Tool_acf_weight_zeromass", "Mass must be above 0!" )
end

if SERVER and not Weights then Weights = {} end

local function SetMass( Player, Entity, Data )
	if not SERVER then return end

	if Data.Mass then
		local physobj = Entity:GetPhysicsObject()
		if physobj:IsValid() then physobj:SetMass(Data.Mass) end
	end
	
	duplicator.StoreEntityModifier( Entity, "mass", Data )
end

duplicator.RegisterEntityModifier( "mass", SetMass )

local function IsReallyValid(trace)
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsPlayer() then return false end
	if SERVER and not trace.Entity:GetPhysicsObject():IsValid() then return false end
	return true
end

function TOOL:LeftClick( trace )
	if CLIENT and IsReallyValid(trace) then return true end
	if not IsReallyValid(trace) then return false end
	if self:GetOwner():KeyDown(IN_USE) then
		local mass = 0
		for ent , v in pairs( constraint.GetAllConstrainedEntities(trace.Entity) ) do
			if IsValid(ent) and ent != NULL then
				local phys = ent:GetPhysicsObject()
				mass = mass + phys:GetMass()
			end
		end
		self:GetOwner():PrintMessage(HUD_PRINTCENTER , "Total Mass is: "..tostring(mass) )
		return true
	end

	if not Weights[trace.Entity:GetModel()] then 
		Weights[trace.Entity:GetModel()] = trace.Entity:GetPhysicsObject():GetMass() 
	end
	local mass = tonumber(self:GetClientInfo("set"))
	
	if mass > 0 then
		SetMass( self:GetOwner(), trace.Entity, { Mass = mass } )
	else 
		umsg.Start("ACF_WeightSTool_1", self:GetOwner()) 
		umsg.End()
	end
	self.updateacf = true
	
	return true;
end

function TOOL:RightClick( trace )
	if CLIENT and IsReallyValid(trace) then return true end
	if not IsReallyValid(trace) then return end
	
	local mass = trace.Entity:GetPhysicsObject():GetMass()
	self:GetOwner():ConCommand("acf_weight_set "..mass);
	self.updateacf = true
	return true;
end

function TOOL:Reload( trace )
	if CLIENT then return false end;
	if not IsReallyValid(trace) then return false end
	local pl = self:GetOwner()
	local Ent = trace.Entity
	local Millimeter = tonumber(self:GetClientInfo("thick"))
	local Size = Ent:OBBMaxs() - Ent:OBBMins()
	local Aera = ((Size.x * Size.y)+(Size.x * Size.z)+(Size.y * Size.z)) * 6.45

	local Mass = Millimeter * 0.78 * Aera / 1000

	if Mass > 50000 then
		pl:PrintMessage(HUD_PRINTCENTER , "Armour set too high, weight exceeded 50 000 kg's")
		return
	end

	SetMass( pl , Ent , { Mass = Mass } )
	
	self.Weapon:EmitSound( Sound( "Airboat.FireGunRevDown" )	)
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos )
		effectdata:SetNormal( trace.HitNormal )
		effectdata:SetEntity( trace.Entity )
		effectdata:SetAttachment( trace.PhysicsBone )
	util.Effect( "selection_indicator", effectdata )	
	
	local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos )
		effectdata:SetStart( pl:GetShootPos() )
		effectdata:SetAttachment( 1 )
		effectdata:SetEntity( self.Weapon )
	util.Effect( "ToolTracer", effectdata )
	self.updateacf = true
	return false
end


function TOOL:Think()
	if CLIENT then return end;
	local pl = self:GetOwner()
	local wep = pl:GetActiveWeapon()
	if not wep:IsValid() or wep:GetClass() != "gmod_tool" or pl:GetInfo("gmod_toolmode") != "acf_weight" then return end
	local trace = pl:GetEyeTrace()
	if IsReallyValid(trace) then pl:SetNetworkedFloat("WeightMass", trace.Entity:GetPhysicsObject():GetMass()) end
	

	local ent = trace.Entity
	if ent != self.lastent or self.updateacf then
		local valid = ACF_Check( ent )
			if valid then
				self.Weapon:SetNetworkedInt( "HP", ent.ACF.Health )
				self.Weapon:SetNetworkedInt( "Armour", ent.ACF.Armour )
				self.Weapon:SetNetworkedInt( "MaxHP", ent.ACF.MaxHealth )
				self.Weapon:SetNetworkedInt( "MaxArmour", ent.ACF.MaxArmour )
			end
		self.lastent = ent
		self.updateacf = false
	end
	if ent:IsWorld() and !self.updateacf then
		self.Weapon:SetNetworkedInt( "HP", 0 )
		self.Weapon:SetNetworkedInt( "Armour", 0 )
		self.Weapon:SetNetworkedInt( "MaxHP", 0 )
		self.Weapon:SetNetworkedInt( "MaxArmour", 0 )
		self.updateacf = true
	end
end

function TOOL.BuildCPanel( cp )
	cp:AddControl( "Header", { Text = "#Tool_acf_weight_name", Description	= "#Tool_acf_weight_desc" }  )

	local params = { Label = "#Presets", MenuButton = 1, Folder = "weight", Options = {}, CVars = {} }
	
	params.Options.default = { acf_weight_set = 1 }
	table.insert( params.CVars, "acf_weight_set" )
	
	cp:AddControl("ComboBox", params )
	cp:AddControl("Slider", { Label = "#Tool_acf_weight_set", Type = "Numeric", Min = "1", Max = "50000", Command = "acf_weight_set" } )

	cp:AddControl("Header", {Text = "Armour Thickness Setting" , Description = "#Tool_acf_weight_thick_desc" } )
	cp:AddControl("Slider", { Label = "#Tool_acf_weight_thick", Type = "Numeric", Min = "1", Max = "2000", Command = "acf_weight_thick" } )
end

if CLIENT then
	
	local TipColor = Color( 250, 250, 200, 255 )

	surface.CreateFont( "coolvetica", 24, 500, true, false, "GModWorldtip" )

	local function DrawWeightTip()
		local pl = LocalPlayer()
		local wep = pl:GetActiveWeapon()
		if not wep:IsValid() or wep:GetClass() != "gmod_tool" or pl:GetInfo("gmod_toolmode") != "acf_weight" then return end
		local trace = pl:GetEyeTrace()
		if not IsReallyValid(trace) then return end
		
		local mass = LocalPlayer():GetNetworkedFloat("WeightMass") or 0
		local text = "Weight: "..mass
	
		local pos = (trace.Entity:LocalToWorld(trace.Entity:OBBCenter())):ToScreen()
		
		local black = Color( 0, 0, 0, 255 )
		local tipcol = Color( TipColor.r, TipColor.g, TipColor.b, 255 )
		
		local x = 0
		local y = 0
		local padding = 10
		local offset = 50
		
		surface.SetFont( "GModWorldtip" )
		local w, h = surface.GetTextSize( text )
		
		x = pos.x - w 
		y = pos.y - h 
		
		x = x - offset
		y = y - offset

		draw.RoundedBox( 8, x-padding-2, y-padding-2, w+padding*2+4, h+padding*2+4, black )
		
		
		local verts = {}
		verts[1] = { x=x+w/1.5-2, y=y+h+2 }
		verts[2] = { x=x+w+2, y=y+h/2-1 }
		verts[3] = { x=pos.x-offset/2+2, y=pos.y-offset/2+2 }
		
		draw.NoTexture()
		surface.SetDrawColor( 0, 0, 0, tipcol.a )
		surface.DrawPoly( verts )
		
		
		draw.RoundedBox( 8, x-padding, y-padding, w+padding*2, h+padding*2, tipcol )
		
		local verts = {}
		verts[1] = { x=x+w/1.5, y=y+h }
		verts[2] = { x=x+w, y=y+h/2 }
		verts[3] = { x=pos.x-offset/2, y=pos.y-offset/2 }
		
		draw.NoTexture()
		surface.SetDrawColor( tipcol.r, tipcol.g, tipcol.b, tipcol.a )
		surface.DrawPoly( verts )
		
		
		draw.DrawText( text, "GModWorldtip", x + w/2, y, black, TEXT_ALIGN_CENTER )
	end
	
	hook.Add("HUDPaint", "ACF_WeightWorldTip", DrawWeightTip)
	
	local function ZMass()
		LocalPlayer():ConCommand("weight_set 1")
		GAMEMODE:AddNotify("#Tool_weight_zeromass", NOTIFY_ERROR, 6);
		surface.PlaySound( "buttons/button10.wav" )
	end
	usermessage.Hook("ACF_WeightSTool_1", ZMass)

	function TOOL:RenderToolScreen()
		local Health = math.floor((self.Weapon:GetNetworkedBool("HP")or 0) *10)/10 
		local MaxHealth = math.floor((self.Weapon:GetNetworkedBool("MaxHP")or 0) * 10)/10
		local Armour = math.floor((self.Weapon:GetNetworkedBool("Armour")or 0) *100)/100
		local MaxArmour = math.floor((self.Weapon:GetNetworkedBool("MaxArmour")or 0) *100)/100
		
		local HealthTxt = Health.."/"..MaxHealth.."\n"
		local ArmourTxt = Armour.."/"..MaxArmour.."\n"
		
		local HealthPercent = (Health/MaxHealth) * 226
		local ArmourPercent = (Armour/MaxArmour) * 226



		
		cam.Start2D()
			render.Clear(0,0,0,0)
			local Flicker = 255
			surface.SetDrawColor(255,255,255,Flicker)
			local tex=surface.GetTextureID(	"models/props_combine/combine_interface_disp")
			surface.SetTexture(tex) 
			surface.DrawTexturedRect(0, 0, 256, 256)
			surface.SetDrawColor(255,255,255,255)

			surface.SetFont("TorchFont")
			local w, h = surface.GetTextSize(" ")
			
			draw.SimpleTextOutlined("ACF Stats", "TorchFont", 128, 30, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
			
			draw.RoundedBox( 6, 10, 83, 236, 64, Color(200, 200, 200, Flicker))
			if Armour != 0 and MaxArmour != 0 then
				draw.RoundedBox( 6, 15, 88, ArmourPercent , 54, Color(0, 0, 200, Flicker))
			end
			
			draw.RoundedBox( 6, 10, 183, 236, 64, Color(200, 200, 200, Flicker))
			if Health != 0 and MaxHealth != 0 then
				draw.RoundedBox( 6, 15, 188, HealthPercent , 54, Color(200, 0, 0, Flicker))
			end
			
			draw.SimpleTextOutlined("Armour", "TorchFont", 128, 100, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
				draw.SimpleTextOutlined(ArmourTxt, "TorchFont", 128, 150, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
			
			draw.SimpleTextOutlined("Health", "TorchFont", 128, 200, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
			draw.SimpleTextOutlined(HealthTxt, "TorchFont", 128, 250, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
		cam.End2D()
	end
end






