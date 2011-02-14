function PANEL:Init( )

	acfmenupanel = self.Panel
		
	// height
	self:SetTall( surface.ScreenHeight() - 120 )

	//Weapon Select	
	
	self.WeaponSelect = vgui.Create( "DTree", self )

	self.Classes = ACF.Classes
	self.WeaponData = ACF.Weapons
	local Guns = self.WeaponSelect:AddNode( "Guns" )
	for ClassID,Class in pairs(self.Classes["GunClass"]) do
	
		local SubNode = Guns:AddNode( Class.name or "No Name" )
		
		for Type, Ent in pairs(self.WeaponData["Guns"]) do	
			if Ent.gunclass == ClassID then
				local EndNode = SubNode:AddNode( Ent.name or "No Name" )
				EndNode.mytable = Ent
				function EndNode:DoClick()
					RunConsoleCommand( "acfmenu_type", self.mytable.type )
					acfmenupanel:UpdateDisplay( self.mytable )
				end
				EndNode.Icon:SetImage( "gui/silkicons/newspaper" )
			end
		end
		
	end

	self.RoundAttribs = list.Get("ACFRoundTypes")
	local Ammo = self.WeaponSelect:AddNode( "Ammo" )
	for AmmoID,AmmoTable in pairs(self.RoundAttribs) do
		
		if AmmoTable.gunclass == ClassID then
			local EndNode = Ammo:AddNode( AmmoTable.name or "No Name" )
			EndNode.mytable = AmmoTable
			function EndNode:DoClick()
				RunConsoleCommand( "acfmenu_type", self.mytable.type )
				acfmenupanel:UpdateDisplay( self.mytable )
			end
			EndNode.Icon:SetImage( "gui/silkicons/newspaper" )
		end
		
	end
	
	local Mobility = self.WeaponSelect:AddNode( "Mobility" )
	for MobilityID,MobilityTable in pairs(self.WeaponData["Mobility"]) do
		
		local EndNode = Mobility:AddNode( MobilityTable.name or "No Name" )
		EndNode.mytable = MobilityTable
		function EndNode:DoClick()
			RunConsoleCommand( "acfmenu_type", self.mytable.type )
			acfmenupanel:UpdateDisplay( self.mytable )
		end
		EndNode.Icon:SetImage( "gui/silkicons/newspaper" )
		
	end
	
	local Sensors = self.WeaponSelect:AddNode( "Sensors" )
	for SensorsID,SensorsTable in pairs(self.WeaponData["Sensors"]) do
		
		local EndNode = Sensors:AddNode( SensorsTable.name or "No Name" )
		EndNode.mytable = SensorsTable
		function EndNode:DoClick()
			RunConsoleCommand( "acfmenu_type", self.mytable.type )
			acfmenupanel:UpdateDisplay( self.mytable )
		end
		EndNode.Icon:SetImage( "gui/silkicons/newspaper" )
		
	end

	local DefaultTable = { self.WeaponData["Guns"] }
	
end

/*------------------------------------
	Think
------------------------------------*/
function PANEL:Think( )

end

function PANEL:UpdateDisplay( Table )
	
	RunConsoleCommand( "acfmenu_id", Table.id or 0 )
	
	--If a previous display exists, erase it
	if ( acfmenupanel.CustomDisplay ) then
		acfmenupanel.CustomDisplay:Clear(true)
		acfmenupanel.CustomDisplay = nil
		acfmenupanel.CData = nil
	end
	--Create the space to display the custom data
	acfmenupanel.CustomDisplay = vgui.Create( "DPanelList", acfmenupanel )	
		acfmenupanel.CustomDisplay:SetSpacing( 5 )
		acfmenupanel.CustomDisplay:EnableHorizontal( false ) 
		acfmenupanel.CustomDisplay:EnableVerticalScrollbar( false ) 
		acfmenupanel.CustomDisplay:SetSize( acfmenupanel:GetWide(), acfmenupanel:GetTall() )
	
	if not acfmenupanel["CData"] then
		--Create a table for the display to store data
		acfmenupanel["CData"] = {}	
	end
		
	acfmenupanel.CreateAttribs = Table.guicreate
	acfmenupanel.UpdateAttribs = Table.guiupdate
	acfmenupanel:CreateAttribs( Table )
	
	acfmenupanel:PerformLayout()

end

function PANEL:CreateAttribs( Table )
	--You overwrite this with your own function, defined in the ammo definition file, so each ammotype creates it's own menu
end

function PANEL:UpdateAttribs( Table )
	--You overwrite this with your own function, defined in the ammo definition file, so each ammotype creates it's own menu
end

function PANEL:PerformLayout()
	
	--Starting positions
	local vspacing = 10
	local ypos = 0
	
	--Selection Tree panel
	acfmenupanel.WeaponSelect:SetPos( 0, ypos )
	acfmenupanel.WeaponSelect:SetSize( acfmenupanel:GetWide(), 165 )
	ypos = acfmenupanel.WeaponSelect.Y + acfmenupanel.WeaponSelect:GetTall() + vspacing
	
	if acfmenupanel.CustomDisplay then
		--Custom panel
		acfmenupanel.CustomDisplay:SetPos( 0, ypos )
		acfmenupanel.CustomDisplay:SetSize( acfmenupanel:GetWide(), 800 )
		ypos = acfmenupanel.CustomDisplay.Y + acfmenupanel.CustomDisplay:GetTall() + vspacing
	end
	
end

function PANEL:AmmoSelect()
	
	if not acfmenupanel.CustomDisplay then return end
	
	if not acfmenupanel.AmmoData then
		acfmenupanel.AmmoData = {}
			acfmenupanel.AmmoData["Id"] = "Ammo2x4x4"
			acfmenupanel.AmmoData["Type"] = "Ammo"
			acfmenupanel.AmmoData["Data"] = acfmenupanel.WeaponData["Guns"]["12.7mmMG"]["round"]
	end
	
	--Creating the ammo crate selection
	acfmenupanel.CData.CrateSelect = vgui.Create( "DMultiChoice", acfmenupanel.CustomDisplay )	--Every display and slider is placed in the Round table so it gets trashed when selecting a new round type
		acfmenupanel.CData.CrateSelect:SetSize(100, 30)
		table.SortByMember(acfmenupanel.WeaponData["Ammo"],"caliber")
		for Key, Value in pairs( acfmenupanel.WeaponData["Ammo"] ) do
			acfmenupanel.CData.CrateSelect:AddChoice( Value.id , Key )
		end
		acfmenupanel.CData.CrateSelect.OnSelect = function( index , value , data )
			RunConsoleCommand( "acfmenu_id", data )
		end
		acfmenupanel.CData.CrateSelect:SetText(acfmenupanel.AmmoData["Id"])
		RunConsoleCommand( "acfmenu_id", acfmenupanel.AmmoData["Id"] )
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.CrateSelect )
	
	--Create the caliber selection display
	acfmenupanel.CData.CaliberSelect = vgui.Create( "DMultiChoice", acfmenupanel.CustomDisplay )	
		acfmenupanel.CData.CaliberSelect:SetSize(100, 30)
		for Key, Value in pairs( acfmenupanel.WeaponData["Guns"] ) do
			acfmenupanel.CData.CaliberSelect:AddChoice( Value.id , Key )
		end
		acfmenupanel.CData.CaliberSelect.OnSelect = function( index , value , data )
			acfmenupanel.AmmoData["Data"] = acfmenupanel.WeaponData["Guns"][data]["round"]
			self:UpdateAttribs()
		end
		acfmenupanel.CData.CaliberSelect:SetText(acfmenupanel.AmmoData["Data"]["id"])
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.CaliberSelect )
	
	--Create the round schematic
	acfmenupanel.CData.PropSchem = vgui.Create( "DShape", acfmenupanel.CustomDisplay )
		acfmenupanel.CData.PropSchem:SetType("Rect")
		acfmenupanel.CData.PropSchem:SetSize( 100, 20 )
		acfmenupanel.CData.PropSchem:SetColor( 255, 255, 255, 255 )
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.PropSchem )
	
	acfmenupanel.CData.LengthDisplay = vgui.Create( "DLabel", acfmenupanel.CustomDisplay )
		acfmenupanel.CData.LengthDisplay:SetText( "" )
		acfmenupanel.CData.LengthDisplay:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.LengthDisplay )
	
end

function PANEL:AmmoSlider(Name, Value, Min, Max, Decimals, Title, Desc) --Variable name in the table, Value, Min value, Max Value, slider text title, slider decimeals, description text below slider 

	if not acfmenupanel["CData"][Name] then
		acfmenupanel["CData"][Name] = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel["CData"][Name]:SetText( Title )
			acfmenupanel["CData"][Name]:SetMin( 0 )
			acfmenupanel["CData"][Name]:SetMax( 1000 )
			acfmenupanel["CData"][Name]:SetDecimals( Decimals )
			if acfmenupanel.AmmoData[Name] then
				acfmenupanel["CData"][Name]:SetValue(acfmenupanel.AmmoData[Name])
			end
			acfmenupanel["CData"][Name].OnValueChanged = function( slider, val )
				if acfmenupanel.AmmoData[Name] != val then
					acfmenupanel.AmmoData[Name] = val
					self:UpdateAttribs( Name )
				end
			end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel["CData"][Name] )
	end
	acfmenupanel["CData"][Name]:SetMin( Min ) 
	acfmenupanel["CData"][Name]:SetMax( Max )
	acfmenupanel["CData"][Name]:SetValue( Value )
	
	if not acfmenupanel["CData"][Name.."_text"] and Desc then
		acfmenupanel["CData"][Name.."_text"] = vgui.Create( "DLabel" )
			acfmenupanel["CData"][Name.."_text"]:SetText( Desc or "" )
			acfmenupanel["CData"][Name.."_text"]:SizeToContents()
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel["CData"][Name.."_text"] )
	end
	acfmenupanel["CData"][Name.."_text"]:SetText( Desc )
	acfmenupanel["CData"][Name.."_text"]:SizeToContents()
	
end

function PANEL:AmmoCheckbox(Name, Title, Desc) --Variable name in the table, slider text title, slider decimeals, description text below slider 

	if not acfmenupanel["CData"][Name] then
		acfmenupanel["CData"][Name] = vgui.Create( "DCheckBoxLabel" )
			acfmenupanel["CData"][Name]:SetText( Title or "" )
			acfmenupanel["CData"][Name]:SizeToContents()
			if acfmenupanel.AmmoData[Name] != nil then
				acfmenupanel["CData"][Name]:SetChecked(acfmenupanel.AmmoData[Name])
			else
				acfmenupanel.AmmoData[Name] = false
			end
			acfmenupanel["CData"][Name].OnChange = function( check, bval )
				acfmenupanel.AmmoData[Name] = bval
				self:UpdateAttribs( {Name, bval} )
			end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel["CData"][Name] )
	end
	acfmenupanel["CData"][Name]:SetText( Title )
	
	
	if not acfmenupanel["CData"][Name.."_text"] and Desc then
		acfmenupanel["CData"][Name.."_text"] = vgui.Create( "DLabel" )
			acfmenupanel["CData"][Name.."_text"]:SetText( Desc or "" )
			acfmenupanel["CData"][Name.."_text"]:SizeToContents()
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel["CData"][Name.."_text"] )
	end
	acfmenupanel["CData"][Name.."_text"]:SetText( Desc )
	acfmenupanel["CData"][Name.."_text"]:SizeToContents()
	
end

function PANEL:AmmoText(Name, Desc)

	if not acfmenupanel["CData"][Name.."_text"] then
		acfmenupanel["CData"][Name.."_text"] = vgui.Create( "DLabel" )
			acfmenupanel["CData"][Name.."_text"]:SetText( Desc or "" )
			acfmenupanel["CData"][Name.."_text"]:SizeToContents()
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel["CData"][Name.."_text"] )
	end
	acfmenupanel["CData"][Name.."_text"]:SetText( Desc )
	acfmenupanel["CData"][Name.."_text"]:SizeToContents()

end