include("shared.lua")

ENT.RenderGroup 		= RENDERGROUP_OPAQUE

ENT.AutomaticFrameAdvance = true 

function ENT:Draw()
	self:DoNormalDraw()
	self:DrawModel()
    Wire_Render(self.Entity)
end

function ENT:DoNormalDraw()
	local e = self.Entity
	if (LocalPlayer():GetEyeTrace().Entity == e and EyePos():Distance(e:GetPos()) < 256) then
		if(self:GetOverlayText() ~= "") then
			AddWorldTip(e:EntIndex(),self:GetOverlayText(),0.5,e:GetPos(),e)
		end
	end
end


function ACFGearboxGUICreate( Table )

	if not acfmenupanel.GearboxData then
		acfmenupanel.GearboxData = {}
		if not acfmenupanel.GearboxData[Table.id] then
			acfmenupanel.GearboxData[Table.id] = {}
			acfmenupanel.GearboxData[Table.id]["GearTable"] = {Table.geartable}
		end
	end
	--PrintTable(Table.geartable)
		
	acfmenupanel.CData.Name = vgui.Create( "DLabel", acfmenupanel.CustomDisplay )
		acfmenupanel.CData.Name:SetText( Table.name )
		acfmenupanel.CData.Name:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Name )
	
	acfmenupanel.CData.DisplayModel = vgui.Create( "DModelPanel", acfmenupanel.CustomDisplay )
		acfmenupanel.CData.DisplayModel:SetModel( Table.model )
		acfmenupanel.CData.DisplayModel:SetCamPos( Vector( 70 , 70 , 30 ) )
		acfmenupanel.CData.DisplayModel:SetLookAt( Vector( 0, 0, 0 ) )
		acfmenupanel.CData.DisplayModel:SetFOV( 90 )
		acfmenupanel.CData.DisplayModel:SetSize(acfmenupanel:GetWide(),100)
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.DisplayModel )
	
	acfmenupanel.CData.Desc = vgui.Create( "DLabel", acfmenupanel.CustomDisplay )
		acfmenupanel.CData.Desc:SetText( Table.desc )
		acfmenupanel.CData.Desc:SetSize(acfmenupanel:GetWide(),100)
		acfmenupanel.CData.Desc:SizeToContentsY()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Desc )
	
	acfmenupanel.CData.Weight = vgui.Create( "DLabel", acfmenupanel.CustomDisplay )
		acfmenupanel.CData.Weight:SetText( "Weight : "..Table.weight.."kg" )
		acfmenupanel.CData.Weight:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Weight )
	
	acfmenupanel.CData.Gear10 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
		acfmenupanel.CData.Gear10:SetText( "Reverse" )
		acfmenupanel.CData.Gear10:SetMin( -2 )
		acfmenupanel.CData.Gear10:SetMax( 2 )
		acfmenupanel.CData.Gear10:SetDecimals( 3 )
		acfmenupanel.CData.Gear10.OnValueChanged = function( slider, val )
			acfmenupanel.GearboxData[Table.id]["GearTable"][-1] = val
			RunConsoleCommand( "acfmenu_data10", val )
		end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][-1] then
			acfmenupanel.CData.Gear10:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][-1])
		end
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear10 )
	
	acfmenupanel.CData.Gear1 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
		acfmenupanel.CData.Gear1:SetText( "First" )
		acfmenupanel.CData.Gear1:SetMin( -2 )
		acfmenupanel.CData.Gear1:SetMax( 2 )
		acfmenupanel.CData.Gear1:SetDecimals( 3 )
		acfmenupanel.CData.Gear1.OnValueChanged = function( slider, val )
			acfmenupanel.GearboxData[Table.id]["GearTable"][1] = val
			RunConsoleCommand( "acfmenu_data1", val )
		end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][1] then
			acfmenupanel.CData.Gear1:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][1])
		end
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear1 )
	
	if Table.gears >= 2 then
		acfmenupanel.CData.Gear2 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel.CData.Gear2:SetText( "Second" )
			acfmenupanel.CData.Gear2:SetMin( -2 )
			acfmenupanel.CData.Gear2:SetMax( 2 )
			acfmenupanel.CData.Gear2:SetDecimals( 3 )
			acfmenupanel.CData.Gear2.OnValueChanged = function( slider, val )
				acfmenupanel.GearboxData[Table.id]["GearTable"][2] = val
				RunConsoleCommand( "acfmenu_data2", val )
			end
			if acfmenupanel.GearboxData[Table.id]["GearTable"][2] then
			acfmenupanel.CData.Gear2:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][2])
		end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear2 )
	end
	
	if Table.gears >= 3 then
		acfmenupanel.CData.Gear3 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel.CData.Gear3:SetText( "Third" )
			acfmenupanel.CData.Gear3:SetMin( -2 )
			acfmenupanel.CData.Gear3:SetMax( 2 )
			acfmenupanel.CData.Gear3:SetDecimals( 3 )
			acfmenupanel.CData.Gear3.OnValueChanged = function( slider, val )
				acfmenupanel.GearboxData[Table.id]["GearTable"][3] = val
				RunConsoleCommand( "acfmenu_data3", val )
			end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][3] then
			acfmenupanel.CData.Gear3:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][3])
		end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear3 )
	end
	
	if Table.gears >= 4 then
		acfmenupanel.CData.Gear4 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel.CData.Gear4:SetText( "Fourth" )
			acfmenupanel.CData.Gear4:SetMin( -2 )
			acfmenupanel.CData.Gear4:SetMax( 2 )
			acfmenupanel.CData.Gear4:SetDecimals( 3 )
			acfmenupanel.CData.Gear4.OnValueChanged = function( slider, val )
				acfmenupanel.GearboxData[Table.id]["GearTable"][4] = val
				RunConsoleCommand( "acfmenu_data4", val )
			end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][4] then
			acfmenupanel.CData.Gear4:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][4])
		end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear4 )
	end
	
	if Table.gears >= 5 then
		acfmenupanel.CData.Gear5 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel.CData.Gear5:SetText( "Fifth" )
			acfmenupanel.CData.Gear5:SetMin( -2 )
			acfmenupanel.CData.Gear5:SetMax( 2 )
			acfmenupanel.CData.Gear5:SetDecimals( 3 )
			acfmenupanel.CData.Gear5.OnValueChanged = function( slider, val )
				acfmenupanel.GearboxData[Table.id]["GearTable"][5] = val
				RunConsoleCommand( "acfmenu_data5", val )
			end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][5] then
			acfmenupanel.CData.Gear5:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][5])
		end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear5 )
	end
	
	if Table.gears >= 6 then
		acfmenupanel.CData.Gear6 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel.CData.Gear6:SetText( "Sixth" )
			acfmenupanel.CData.Gear6:SetMin( -2 )
			acfmenupanel.CData.Gear6:SetMax( 2 )
			acfmenupanel.CData.Gear6:SetDecimals( 3 )
			acfmenupanel.CData.Gear6.OnValueChanged = function( slider, val )
				acfmenupanel.GearboxData[Table.id]["GearTable"][6] = val
				RunConsoleCommand( "acfmenu_data6", val )
			end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][6] then
			acfmenupanel.CData.Gear6:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][6])
		end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear6 )
	end
	
	if Table.gears >= 7 then
		acfmenupanel.CData.Gear7 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel.CData.Gear7:SetText( "Seventh" )
			acfmenupanel.CData.Gear7:SetMin( -2 )
			acfmenupanel.CData.Gear7:SetMax( 2 )
			acfmenupanel.CData.Gear7:SetDecimals( 3 )
			acfmenupanel.CData.Gear7.OnValueChanged = function( slider, val )
				acfmenupanel.GearboxData[Table.id]["GearTable"][7] = val
				RunConsoleCommand( "acfmenu_data7", val )
			end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][7] then
			acfmenupanel.CData.Gear7:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][7])
		end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear7 )
	end
	
	if Table.gears >= 8 then
		acfmenupanel.CData.Gear8 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel.CData.Gear8:SetText( "Eighth" )
			acfmenupanel.CData.Gear8:SetMin( -2 )
			acfmenupanel.CData.Gear8:SetMax( 2 )
			acfmenupanel.CData.Gear8:SetDecimals( 3 )
			acfmenupanel.CData.Gear8.OnValueChanged = function( slider, val )
				acfmenupanel.GearboxData[Table.id]["GearTable"][8] = val
				RunConsoleCommand( "acfmenu_data8", val )
			end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][8] then
			acfmenupanel.CData.Gear8:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][8])
		end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear8 )
	end
	
	if Table.gears >= 9 then
		acfmenupanel.CData.Gear9 = vgui.Create( "DNumSlider", acfmenupanel.CustomDisplay )
			acfmenupanel.CData.Gear9:SetText( "Ninth" )
			acfmenupanel.CData.Gear9:SetMin( -2 )
			acfmenupanel.CData.Gear9:SetMax( 2 )
			acfmenupanel.CData.Gear9:SetDecimals( 3 )
			acfmenupanel.CData.Gear9.OnValueChanged = function( slider, val )
				acfmenupanel.GearboxData[Table.id]["GearTable"][9] = val
				RunConsoleCommand( "acfmenu_data9", val )
			end
		if acfmenupanel.GearboxData[Table.id]["GearTable"][9] then
			acfmenupanel.CData.Gear9:SetValue(acfmenupanel.GearboxData[Table.id]["GearTable"][9])
		end
		acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.Gear9 )
	end
	
	acfmenupanel.CustomDisplay:PerformLayout()
	
end

