AddCSLuaFile( "ACF/Shared/Rounds/RoundHP.lua" )

local DefTable = {}
	DefTable.type = "Ammo"										--Tells the spawn menu what entity to spawn
	DefTable.name = "Hollow Point"								--Human readable name
	DefTable.model = "models/munitions/round_100mm_shot.mdl"	--Shell flight model
	DefTable.desc = "A solid shell with a soft point, meant to flatten against armour"
	DefTable.netid = 3											--Unique ammotype ID for network transmission

	DefTable.limitvel = 400										--Most efficient penetration speed in m/s
	DefTable.ricochet = 85										--Base ricochet angle
	
	DefTable.create = function( Gun, BulletData ) ACF_APCreate( Gun, BulletData ) end --Uses basic AP function
	DefTable.convert = function( Crate, Table ) local Result = ACF_HPConvert( Crate, Table ) return Result end --Uses custom function
	
	DefTable.propimpact = function( Bullet, Index, Target, HitNormal, HitPos ) local Result = ACF_APPropImpact( Bullet, Index, Target, HitNormal, HitPos ) return Result end --Uses basic AP function
	DefTable.worldimpact = function( Bullet, Index, HitPos, HitNormal ) ACF_APWorldImpact( Bullet, Index, HitPos, HitNormal ) end --Uses basic AP function
	DefTable.endflight = function( Bullet, Index, HitPos, HitNormal ) ACF_APEndFlight( Bullet, Index, HitPos, HitNormal ) end --Uses basic AP function
	
	DefTable.endeffect = function( Effect, Pos, Flight, RoundMass, FillerMass ) ACF_APEndEffect( Effect, Pos, Flight, RoundMass, FillerMass ) end --Uses basic AP function
	DefTable.pierceeffect = function( Effect, Pos, Flight, RoundMass, FillerMass ) ACF_APPierceEffect( Effect, Pos, Flight, RoundMass, FillerMass ) end --Uses basic AP function
	DefTable.ricocheteffect = function( Effect, Pos, Flight, RoundMass, FillerMass ) ACF_APRicochetEffect( Effect, Pos, Flight, RoundMass, FillerMass ) end --Uses basic AP function
	
	DefTable.guicreate = function( Panel, Table ) ACF_HPGUICreate( Panel, Table ) end	--References the function to use to draw that round menu, must use custom function
	DefTable.guiupdate = function( Panel, Table ) ACF_HPGUIUpdate( Panel, Table ) end	--References the function to use to update that round menu, must use custom function

list.Set( "ACFRoundTypes", "HP", DefTable )  --Set the round properties
list.Set( "ACFIdRounds", 3 , "HP" ) --Index must equal the ID entry in the table above, Data must equal the index of the table above


function ACF_HPConvert( Crate, PlayerData )		--Function to convert the player's slider data into the complete round data
	
	local BulletData = {}
		BulletData["Id"] = PlayerData["Id"]
		BulletData["Type"] = PlayerData["Type"]
		
		BulletData["Caliber"] = ACF.Weapons["Guns"][PlayerData["Id"]]["caliber"]
		BulletData["FrAera"] = 3.1416 * (BulletData["Caliber"]/2)^2
		BulletData["PropMass"] = BulletData["FrAera"] * (PlayerData["PropLenght"]*ACF.PDensity/1000) --Volume of the case as a cylinder * Powder density converted from g to kg
		local BulletMax = ACF.Weapons["Guns"][PlayerData["Id"]]["round"]
		
		PlayerData["ProjLenght"] = math.max(PlayerData["ProjLenght"],BulletData["Caliber"]*1.5)
		
		BulletData["Tracer"] = 0
		if PlayerData["Data10"]*1 > 0 then	--Check for tracer
			BulletData["Tracer"] = math.min(5/BulletData["Caliber"],2.5)
		end
		
		if ( BulletData["PropMass"] > BulletMax["propweight"] ) then	--These 3 if statements are checking if the round fits into parameters and to fail gracefully if not
			PlayerData["PropLenght"] = (BulletMax["propweight"]*1000/ACF.PDensity) / (BulletData["FrAera"])
			BulletData["PropMass"] = BulletData["FrAera"] * (PlayerData["PropLenght"]*ACF.PDensity/1000)
		end	
		
		if ( (PlayerData["ProjLenght"] + PlayerData["PropLenght"] + BulletData["Tracer"]) > BulletMax["maxlength"] ) then
			local Ratio = BulletMax["maxlength"]/(PlayerData["ProjLenght"] + PlayerData["PropLenght"] + BulletData["Tracer"])
			PlayerData["ProjLenght"] = PlayerData["ProjLenght"] * Ratio
			PlayerData["PropLenght"] = PlayerData["PropLenght"] * Ratio
		end
		
		BulletData["CavLenght"] = math.min(PlayerData["Data5"],PlayerData["ProjLenght"]*0.5) --Expantion factor
		BulletData["PenAera"] = (3.1416 * (BulletData["Caliber"]/2 + BulletData["CavLenght"])^2)^ACF.PenAreaMod
		
		BulletData["RoundVolume"] = BulletData["FrAera"] * (PlayerData["ProjLenght"] + PlayerData["PropLenght"])	
		BulletData["ProjMass"] = BulletData["FrAera"] * ((PlayerData["ProjLenght"]-BulletData["CavLenght"])*7.9/1000) --Volume of the projectile as a cylinder * streamline factor (Data5) * density of steel
		
		BulletData["DragCoef"] = ((BulletData["FrAera"]/10000)/BulletData["ProjMass"])
		BulletData["MuzzleVel"] = ACF_MuzzleVelocity( BulletData["PropMass"], BulletData["ProjMass"], BulletData["Caliber"] )
		BulletData["BoomPower"] = BulletData["PropMass"]
		BulletData["ShovePower"] = 0.3 + (BulletData["CavLenght"]/PlayerData["ProjLenght"])
	
	return BulletData
	
end

--GUI stuff after this
function ACF_HPGUICreate( Panel, Table )

	acfmenupanel.CData["Id"] = "AmmoMedium"
	acfmenupanel.CData["Type"] = "Ammo"

	if not acfmenupanel.AmmoData then
		acfmenupanel.AmmoData = {}
			acfmenupanel.AmmoData["PropLength"] = 0
			acfmenupanel.AmmoData["ProjLength"] = 0
			acfmenupanel.AmmoData["Data"] = acfmenupanel.WeaponData["Guns"]["12.7mmMG"]["round"]
	end
	
	--Creating the ammo crate selection
	acfmenupanel.CData.CrateSelect = vgui.Create( "DMultiChoice" )	--Every display and slider is placed in the Round table so it gets trashed when selecting a new round type
		acfmenupanel.CData.CrateSelect:SetSize(100, 30)
		table.SortByMember(acfmenupanel.WeaponData["Ammo"],"caliber")
		for Key, Value in pairs( acfmenupanel.WeaponData["Ammo"] ) do
			acfmenupanel.CData.CrateSelect:AddChoice( Value.id , Key )
		end
		acfmenupanel.CData.CrateSelect.OnSelect = function( index , value , data )
			RunConsoleCommand( "acfmenu_id", data )
		end
		if acfmenupanel.CData["Id"] then
			acfmenupanel.CData.CrateSelect:SetText(acfmenupanel.CData["Id"])
			RunConsoleCommand( "acfmenu_id", acfmenupanel.CData["Id"] )
		else
			acfmenupanel.CData.CrateSelect:SetText("AmmoSmall")
			RunConsoleCommand( "acfmenu_id", "AmmoSmall" )
		end
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.CrateSelect )	
	
	--Create the caliber selection display
	acfmenupanel.CData.CaliberSelect = vgui.Create( "DMultiChoice" )	
		acfmenupanel.CData.CaliberSelect:SetSize(100, 30)
		for Key, Value in pairs( acfmenupanel.WeaponData["Guns"] ) do
			acfmenupanel.CData.CaliberSelect:AddChoice( Value.id , Key )
		end
		acfmenupanel.CData.CaliberSelect.OnSelect = function( index , value , data )
			acfmenupanel.AmmoData = {}
				acfmenupanel.AmmoData["PropLength"] = 0
				acfmenupanel.AmmoData["ProjLength"] = 0
				acfmenupanel.AmmoData["CavLength"] = 0
				acfmenupanel.AmmoData["Tracer"] = false
				acfmenupanel.AmmoData["Data"] = acfmenupanel.WeaponData["Guns"][data]["round"]
			ACF_HPGUIUpdate()
		end
		acfmenupanel.CData.CaliberSelect:SetText(acfmenupanel.AmmoData["Data"]["id"])
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.CaliberSelect )	
	
	acfmenupanel.CData.lengthDisplay = vgui.Create( "DLabel" )
		acfmenupanel.CData.lengthDisplay:SetText( "" )
		acfmenupanel.CData.lengthDisplay:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.lengthDisplay )
	
	--Create the round schematic
	acfmenupanel.CData.PropSchem = vgui.Create( "DShape" )
		acfmenupanel.CData.PropSchem:SetType("Rect")
		acfmenupanel.CData.PropSchem:SetSize( 100, 20 )
		acfmenupanel.CData.PropSchem:SetColor( 255, 255, 255, 255 )
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.PropSchem )
	
	--Create the value sliders	
	
	--Propellant Lenght Slider
	acfmenupanel.CData.SetPropLength = vgui.Create( "DNumSlider" )
		acfmenupanel.CData.SetPropLength:SetText( "Propellant length" )
		acfmenupanel.CData.SetPropLength:SetMin( 0 )
		acfmenupanel.CData.SetPropLength:SetMax( 1000 )
		acfmenupanel.CData.SetPropLength:SetDecimals( 3 )
		if acfmenupanel.AmmoData["PropLength"] then
			acfmenupanel.CData.SetPropLength:SetValue(acfmenupanel.AmmoData["PropLength"])
		end
		acfmenupanel.CData.SetPropLength.OnValueChanged = function( slider, val )
			if acfmenupanel.AmmoData["PropLength"] != val then
				ACF_HPGUIUpdate()
			end
		end
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.SetPropLength )
	
	acfmenupanel.CData.PropellantWeight = vgui.Create( "DLabel" )
		acfmenupanel.CData.PropellantWeight:SetText( "" )
		acfmenupanel.CData.PropellantWeight:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.PropellantWeight )
	
	--Projectile Lenght Slider
	acfmenupanel.CData.SetProjLength = vgui.Create( "DNumSlider" )
		acfmenupanel.CData.SetProjLength:SetText( "Projectile length" )
		acfmenupanel.CData.SetProjLength:SetMin( 0 )
		acfmenupanel.CData.SetProjLength:SetMax( 1000 )
		acfmenupanel.CData.SetProjLength:SetDecimals( 3 )
		if acfmenupanel.AmmoData["ProjLength"] then
			acfmenupanel.CData.SetProjLength:SetValue(acfmenupanel.AmmoData["ProjLength"])
		end
		acfmenupanel.CData.SetProjLength.OnValueChanged = function( slider, val )
			if acfmenupanel.AmmoData["ProjLength"] != val then
				ACF_HPGUIUpdate()
			end
		end
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.SetProjLength )
	
	--Hollow Point Cavity Slider
	acfmenupanel.CData.SetCavLength = vgui.Create( "DNumSlider" )
		acfmenupanel.CData.SetCavLength:SetText( "Hollow point cavity length" )
		acfmenupanel.CData.SetCavLength:SetMin( 0 )
		acfmenupanel.CData.SetCavLength:SetMax( 1000 )
		acfmenupanel.CData.SetCavLength:SetDecimals( 3 )
		if acfmenupanel.AmmoData["CavLength"] then
			acfmenupanel.CData.SetCavLength:SetValue(acfmenupanel.AmmoData["CavLength"])
		end
		acfmenupanel.CData.SetCavLength.OnValueChanged = function( slider, val )
			if acfmenupanel.AmmoData["CavLength"] != val then
				ACF_HPGUIUpdate()
			end
		end
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.SetCavLength )
	
	--Tracer checkbox
	acfmenupanel.CData.SetTracer = vgui.Create( "DCheckBoxLabel" )
		acfmenupanel.CData.SetTracer:SetText( "Tracer" )
		acfmenupanel.CData.SetTracer:SizeToContents()
		if acfmenupanel.AmmoData["Tracer"] != nil then
			acfmenupanel.CData.SetTracer:SetChecked(acfmenupanel.AmmoData["Tracer"])
		end
		acfmenupanel.CData.SetTracer.OnChange = function( check, bval )
			acfmenupanel.AmmoData["Tracer"] = bval
			ACF_HPGUIUpdate()
		end
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.SetTracer )
	
	acfmenupanel.CData.ProjWeight = vgui.Create( "DLabel" )
		acfmenupanel.CData.ProjWeight:SetText( "" )
		acfmenupanel.CData.ProjWeight:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.ProjWeight )	
	
	acfmenupanel.CData.ProjRadius = vgui.Create( "DLabel" )
		acfmenupanel.CData.ProjRadius:SetText( "" )
		acfmenupanel.CData.ProjRadius:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.ProjRadius )

	acfmenupanel.CData.VelocityDisplay = vgui.Create( "DLabel" )
		acfmenupanel.CData.VelocityDisplay:SetText( "" )
		acfmenupanel.CData.VelocityDisplay:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.VelocityDisplay )
	
	acfmenupanel.CData.PenetrationDisplay = vgui.Create( "DLabel" )
		acfmenupanel.CData.PenetrationDisplay:SetText( "" )
		acfmenupanel.CData.PenetrationDisplay:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.PenetrationDisplay )
	
	acfmenupanel.CData.KEDisplay = vgui.Create( "DLabel" )
		acfmenupanel.CData.KEDisplay:SetText( "" )
		acfmenupanel.CData.KEDisplay:SizeToContents()
	acfmenupanel.CustomDisplay:AddItem( acfmenupanel.CData.KEDisplay )
	
	ACF_HPGUIUpdate( Panel, Table )

end

function ACF_HPGUIUpdate( Panel, Table )
	
	local Caliber = acfmenupanel.WeaponData["Guns"][acfmenupanel.AmmoData["Data"]["id"]]["caliber"]

	local PropWeight = 3.1416*(Caliber/2)^2 * (acfmenupanel.AmmoData["PropLength"]*ACF.PDensity/1000) --Volume of the case as a cylinder * Powder density converted from g to kg
	local TracerLenght = 0
	if acfmenupanel.AmmoData["Tracer"] then
		TracerLenght = math.min(5/Caliber,2.5)
	end
	local Freelength = acfmenupanel.AmmoData["Data"]["maxlength"] - (acfmenupanel.AmmoData["ProjLength"] + acfmenupanel.AmmoData["PropLength"] + TracerLenght)
	
	local MinPropLength = 0.01
	local MaxPropLength = math.min( (acfmenupanel.AmmoData["Data"]["propweight"]*1000/ACF.PDensity) / (3.1416*(Caliber/2)^2) , acfmenupanel.AmmoData["PropLength"]+Freelength )
	local ClampProp = math.floor(math.Clamp(acfmenupanel.CData.SetPropLength:GetValue()*1000,MinPropLength*1000,MaxPropLength*1000))/1000
	acfmenupanel.CData.SetPropLength:SetMin( MinPropLength ) 
	acfmenupanel.CData.SetPropLength:SetMax( MaxPropLength )
	acfmenupanel.AmmoData["PropLength"] = ClampProp

	local MinProjLength = Caliber*1.5
	local MaxProjLength = math.min(acfmenupanel.AmmoData["ProjLength"]+Freelength,acfmenupanel.AmmoData["Data"]["maxlength"])
	local ClampProj = math.floor(math.Clamp(acfmenupanel.CData.SetProjLength:GetValue()*1000,MinProjLength*1000,MaxProjLength*1000))/1000
	acfmenupanel.CData.SetProjLength:SetMin( MinProjLength ) 
	acfmenupanel.CData.SetProjLength:SetMax( MaxProjLength )
	acfmenupanel.AmmoData["ProjLength"] = ClampProj	
	
	local MinCavLength = 0
	local MaxCavLength = ClampProj*0.5
	local ClampCav = math.floor(math.Clamp(acfmenupanel.CData.SetCavLength:GetValue()*1000,MinCavLength*1000,MaxCavLength*1000))/1000
	acfmenupanel.CData.SetCavLength:SetMin( MinCavLength ) 
	acfmenupanel.CData.SetCavLength:SetMax( MaxCavLength )
	acfmenupanel.AmmoData["CavLength"] = ClampCav	
	
	local ProjWeight = 3.1416*(Caliber/2)^2 * ((ClampProj-ClampCav)*7.9/1000) --Volume of the projectile as a cylinder * streamline factor * density of steel
	
	--Set the values on the sliders if they have changed.
	if acfmenupanel.CData.SetPropLength:GetValue() != ClampProp then acfmenupanel.CData.SetPropLength:SetValue( ClampProp ) return end
	if acfmenupanel.CData.SetProjLength:GetValue() != ClampProj then acfmenupanel.CData.SetProjLength:SetValue( ClampProj ) return end	
	if acfmenupanel.CData.SetCavLength:GetValue() != ClampCav then acfmenupanel.CData.SetCavLength:SetValue( ClampCav ) return end	
	
	RunConsoleCommand( "acfmenu_data1", acfmenupanel.AmmoData["Data"]["id"] )
	RunConsoleCommand( "acfmenu_data2", "HP" )
	RunConsoleCommand( "acfmenu_data3", ClampProp )		--For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand( "acfmenu_data4", ClampProj )		--And Data4 total round mass
	RunConsoleCommand( "acfmenu_data5", ClampCav )
	RunConsoleCommand( "acfmenu_data10", TracerLenght )
	
	acfmenupanel.CData.lengthDisplay:SetText( "Total Round length : "..(math.floor((acfmenupanel.AmmoData["Data"]["maxlength"] - Freelength)*1000)/1000).."cm/"..acfmenupanel.AmmoData["Data"]["maxlength"].."cm" )
	acfmenupanel.CData.lengthDisplay:SizeToContents()
	
	acfmenupanel.CData.PropSchem:SetSize( 100, 20 )
	
	acfmenupanel.CData.SetTracer:SetText( "Tracer : "..(math.floor(math.min(5/Caliber,2.5)*100)/100).."cm\n" )
	
	acfmenupanel.CData.PropellantWeight:SetText( "Propellant Weight : "..(math.floor(PropWeight*1000)).." g" )
	acfmenupanel.CData.PropellantWeight:SizeToContents()
	
	acfmenupanel.CData.ProjWeight:SetText( "Projectile Weight : "..(math.floor(ProjWeight*1000)).." g" )
	acfmenupanel.CData.ProjWeight:SizeToContents()
	
	local Radius = (Caliber + ClampCav*2)	--Calculating the "Pankake factor"
	acfmenupanel.CData.ProjRadius:SetText( "Expanded Caliber : "..(math.floor(Radius*1000)).." mm" )
	acfmenupanel.CData.ProjRadius:SizeToContents()
	
	local Velocity = ACF_MuzzleVelocity( PropWeight, ProjWeight, acfmenupanel.WeaponData["Guns"][acfmenupanel.AmmoData["Data"]["id"]]["caliber"] )
	acfmenupanel.CData.VelocityDisplay:SetText( "Muzzle Velocity : "..math.floor(Velocity*ACF.VelScale).." m\s" )
	acfmenupanel.CData.VelocityDisplay:SizeToContents()
	
	local Energy = ACF_Kinetic( Velocity*39.37 , ProjWeight, ACF.RoundTypes["HP"]["limitvel"] )
	local Aera = (( 3.1416*(Caliber/2)^2 )^ACF.PenAreaMod)*2
	local Penetration = (Energy.Penetration/Aera)*ACF.KEtoRHA
	acfmenupanel.CData.PenetrationDisplay:SetText( "Maximum Penetration : "..math.floor(Penetration).." mm RHA" )
	acfmenupanel.CData.PenetrationDisplay:SizeToContents()
	
	acfmenupanel.CData.KEDisplay:SetText( "Kinetic Energy : "..math.floor(Energy.Kinetic).." KJ" )
	acfmenupanel.CData.KEDisplay:SizeToContents()
	
	acfmenupanel.CustomDisplay:PerformLayout()
	
end
