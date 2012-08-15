TOOL.Category = "Construction"
TOOL.Name = "#ACF Fading Door"
TOOL.Command = nil
TOOL.ConfigName = ""

// Tables

local FadingDoor = {}

// ConVars

TOOL.ClientConVar["Key"] = "5"
TOOL.ClientConVar["Toggle"] = "0"
TOOL.ClientConVar["Inversed"] = "0"

// Message

function TOOL:Message(Text)
	if SERVER then
		self:GetOwner():SendLua("GAMEMODE:AddNotify('"..Text.."', NOTIFY_GENERIC, 10)")
		self:GetOwner():SendLua("surface.PlaySound('ambient/water/drip"..math.random(1, 4)..".wav')")
	end
end

// Client

if (CLIENT) then
	language.Add("Tool_fadingdoor_name", "Fading Door Tool")
	language.Add("Tool_fadingdoor_desc", "Creates doors which can fade to allow access")
	language.Add("Tool_fadingdoor_0", "Click on an entity to make it a Fading Door")
	
	language.Add("Undone_fadingdoor", "Undone Fading Door")
end

// Left click

local function CreateFadingDoor( Player, Entity, Data )
	
	if(!SERVER) then return false end
	// Remove previous
	
	if (Entity.FadingDoor) then
		FadingDoor.Deactivate(Entity)
		
		numpad.Remove(Entity.FadingDoor.Down)
		numpad.Remove(Entity.FadingDoor.Up)
	end
	
	// Set new variables
	
	Entity.FadingDoor        = {}
	
	Entity.FadingDoor.Active = false
	
	Entity.FadingDoor.Toggle = (Data.Toggle != 0)
	
	// Is it inversed
	
	if (Data.Inverse == 1) then
		FadingDoor.Activate(Entity)
	end
	
	Entity.FadingDoor.Down = numpad.OnDown(Player, Data.Key, "FadingDoor.Pressed", Entity, true)
	Entity.FadingDoor.Up   = numpad.OnUp(Player, Data.Key, "FadingDoor.Pressed", Entity, false)
	
	local function Function(Undo, Entity)
		if (Entity.FadingDoor) then
			FadingDoor.Deactivate(Entity)
			
			numpad.Remove(Entity.FadingDoor.Down)
			numpad.Remove(Entity.FadingDoor.Up)
			
			local Data = {}
			duplicator.ClearEntityModifier( Entity, "Fading Door" )
			
			return true
		end
	end
	
	undo.Create("Fading Door")
		undo.AddFunction(Function, Entity)
		undo.SetPlayer(Player)
	undo.Finish()
	
	local Number = 0
	
	if (Entity.FadingDoor.Active) then
		Number = 1
	end
	
	/*if WireAddon then
	
		Entity.Inputs = Wire_CreateInputs( Entity, { "Activate" } )
		Entity.Outputs = Wire_CreateOutputs( Entity, { "Active" } )
		function Entity:TriggerInput( iname , value )
			if ( iname == "Activate"  ) then
				if !Entity:IsValid() then return end
				if (Entity.FadingDoor.Toggle) then
					if (value != 0) then
						if (Entity.FadingDoor.Active) then
							FadingDoor.Deactivate(Entity)
						else
							FadingDoor.Activate(Entity)
						end
					end
				else
					if (value != 0) then
						FadingDoor.Activate(Entity)
					else
						FadingDoor.Deactivate(Entity)
					end
				end
			end
		end
		
	end*/
	
	Player:PrintMessage(HUD_PRINTTALK, "Fading Door has been created, press "..Data.Key.." to fade it!")
	duplicator.StoreEntityModifier( Entity, "Fading Door", Data )
	
end
duplicator.RegisterEntityModifier( "Fading Door", CreateFadingDoor )

function TOOL:LeftClick(Trace)
	if Trace.Entity then
		if !Trace.Entity:IsValid() or Trace.Entity:IsPlayer() or Trace.HitWorld or Trace.Entity:IsNPC() then
			return false
		end
	end
	
	if(CLIENT) then
		return true
	end
	
	if(!SERVER) then return false end
	// Locals
	local Player = self:GetOwner()	
	local Entity = Trace.Entity
	
	// Keys
	local Data = {}
	Data.Key = self:GetClientNumber("Key")
	Data.Toggle = self:GetClientNumber("Toggle")
	Data.Inverse = self:GetClientNumber("Inversed")
	
	CreateFadingDoor(Player, Entity , Data)
	
	return true
end

// Activate

function FadingDoor.Activate(Entity)
	if (Entity.FadingDoor.Active) then return end
	
	Entity.FadingDoor.Material = Entity:GetMaterial()
	
	Entity:SetMaterial("models/Effects/vol_light001.vtf")
	Entity:DrawShadow(false)
	Entity:SetNotSolid(true)
	Entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	
	Entity.FadingDoor.Active = true
	
	/*if WireAddon then
		Wire_TriggerOutput(Entity, "Active", 1)
	end*/
end

// Deactivate

function FadingDoor.Deactivate(Entity)
	local Material = Entity.FadingDoor.Material or ""
	
	Entity:SetMaterial(Material)
	Entity:DrawShadow(true)
	Entity:SetNotSolid(false)
	if ( Entity.CollisionGroup == COLLISION_GROUP_WORLD ) then  --Nocollide right click compatibility
		Entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
	else
		Entity:SetCollisionGroup(COLLISION_GROUP_NONE)
	end	
	Entity.FadingDoor.Active = false
	
	/*if WireAddon then
		Wire_TriggerOutput(Entity, "Active", 0)
	end*/
end

// Pressed key

function TOOL.Pressed(Player, Entity, Key, IDX)
	if !Entity:IsValid() then return end
	
	if (Entity.FadingDoor.Toggle) then
		if (Key) then
			if (Entity.FadingDoor.Active) then
				FadingDoor.Deactivate(Entity)
			else
				FadingDoor.Activate(Entity)
			end
		end
	else
		if (Key) then
			FadingDoor.Activate(Entity)
		else
			FadingDoor.Deactivate(Entity)
		end
	end
end

// Server

if (SERVER) then
	numpad.Register("FadingDoor.Pressed", TOOL.Pressed)
end

// Build CPanel

function TOOL.BuildCPanel(Panel)
	Panel:AddControl("Header", {Text = "#Tool_fadingdoor_name", Description	= "#Tool_fadingdoor_desc"})
	
	Panel:AddControl("CheckBox", {Label = "Inversed (Start Activated)", Command = "fadingdoor_Inversed"})
	
	Panel:AddControl("CheckBox", {Label = "Toggle", Command = "fadingdoor_Toggle"})
	
	Panel:AddControl("Numpad", {Label = "Button", ButtonSize = "22", Command = "fadingdoor_Key"})
end