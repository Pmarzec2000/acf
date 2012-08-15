TOOL.Category = "Conna's Tools"
TOOL.Name = "#Rotator Tool"
TOOL.Command = nil
TOOL.ConfigName	= ""

// ConVars

TOOL.ClientConVar["P"] = "0"
TOOL.ClientConVar["Y"] = "0"
TOOL.ClientConVar["R"] = "0"

// Client

if (CLIENT) then
	language.Add("Tool_rotator_name", "Rotator Tool")
	language.Add("Tool_rotator_desc", "Set an entity's angles")
	language.Add("Tool_rotator_0", "Left click to set the entity's angles and Right click to get an entity's angles")

	language.Add("Undone_rotator", "Undone Rotator")
end

// Message

function TOOL:Message(Text)
	if SERVER then
		self:GetOwner():SendLua("GAMEMODE:AddNotify('"..Text.."', NOTIFY_GENERIC, 10)")
		self:GetOwner():SendLua("surface.PlaySound('ambient/water/drip"..math.random(1, 4)..".wav')")
	end
end

// Left click

function TOOL:LeftClick(Trace)
	if (Trace.Entity && Trace.Entity:IsPlayer()) then return false end
	
	if (SERVER && !util.IsValidPhysicsObject(Trace.Entity, Trace.PhysicsBone)) then return false end
	
	if (CLIENT) then return true end
	
	if not (Trace.Entity) then return false end
	
	local Player = self:GetOwner()
	
	local P	= self:GetClientNumber("P") 
	local Y	= self:GetClientNumber("Y")
	local R	= self:GetClientNumber("R")
	
	local Backup = Trace.Entity:GetAngles()
	
	Trace.Entity:SetAngles(Angle(P, Y, R))
	
	local function Function(Undo, Entity, Angles)
		if (Entity:IsValid()) then
			Entity:SetAngles(Angles)
		end
	end
	
	undo.Create("rotator")
		undo.SetPlayer(Player)
		undo.AddFunction(Function, Trace.Entity, Backup)
	undo.Finish()
	
	self:Message("Entities angles set to: "..P..", "..Y..", "..R.."!")
	
	return true
end

// Right click

function TOOL:RightClick(Trace)
	if !Trace.Entity then return false end
	
	if Trace.Entity:IsPlayer() then return false end
	
	if CLIENT then return true end
	
	local Angles = Trace.Entity:GetAngles()
	
	local Player = self:GetOwner()
	
	Player:ConCommand("rotator_P "..Angles.p.."\n")
	Player:ConCommand("rotator_Y "..Angles.y.."\n")
	Player:ConCommand("rotator_R "..Angles.r.."\n")
	
	self:Message("Angles extracted from entity: "..Angles.p..", "..Angles.y..", "..Angles.r.."!")
	
	return true
end

// Build CPanel

function TOOL.BuildCPanel(Panel)
	Panel:AddControl("Header", {Text = "#Tool_rotator_name", Description = "#Tool_rotator_desc"})
	
	Panel:AddControl("Slider",  {Label	= "#Pitch", Type = "Integer", Min = 1, Max = 360, Command = "rotator_P"})
	
	Panel:AddControl("Slider",  {Label	= "#Yaw", Type = "Integer", Min = 1, Max = 360, Command = "rotator_Y"})
	
	Panel:AddControl("Slider",  {Label	= "#Roll", Type = "Integer", Min = 1, Max = 360, Command = "rotator_R"})
end