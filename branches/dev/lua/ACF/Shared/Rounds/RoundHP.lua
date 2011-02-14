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
	
	local Data = {}
	local ServerData = {}
	local GUIData = {}
	
	if not PlayerData["PropLength"] then PlayerData["PropLength"] = 0 end
	if not PlayerData["ProjLength"] then PlayerData["ProjLength"] = 0 end
	if not PlayerData["Data5"] then PlayerData["Data5"] = 0 end
	if not PlayerData["Data10"] then PlayerData["Data10"] = 0 end
	
	local BulletMax = ACF.Weapons["Guns"][PlayerData["Id"]]["round"]
	GUIData["MaxTotalLength"] = BulletMax["maxlength"]
		
	Data["Caliber"] = ACF.Weapons["Guns"][PlayerData["Id"]]["caliber"]
	Data["FrAera"] = 3.1416 * (Data["Caliber"]/2)^2
	
	Data["Tracer"] = 0
	if PlayerData["Data10"]*1 > 0 then	--Check for tracer
		Data["Tracer"] = math.min(5/Data["Caliber"],2.5) --Tracer space calcs
	end
	
	local PropMax = (BulletMax["propweight"]*1000/ACF.PDensity) / Data["FrAera"]	--Current casing absolute max propellant capacity
	local CurLength = (PlayerData["ProjLength"] + math.min(PlayerData["PropLength"],PropMax) + Data["Tracer"])
	GUIData["MinPropLength"] = 0.01
	GUIData["MaxPropLength"] = math.max(math.min(GUIData["MaxTotalLength"]-CurLength+PlayerData["PropLength"], PropMax),GUIData["MinPropLength"]) --Check if the desired prop lenght fits in the case and doesn't exceed the gun max
	
	GUIData["MinProjLength"] = Data["Caliber"]*1.5
	GUIData["MaxProjLength"] = math.max(GUIData["MaxTotalLength"]-CurLength+PlayerData["ProjLength"],GUIData["MinProjLength"]) --Check if the desired proj lenght fits in the case
	
	local Ratio = math.min( (GUIData["MaxTotalLength"] - Data["Tracer"])/(PlayerData["ProjLength"] + math.min(PlayerData["PropLength"],PropMax)) , 1 ) --This is to check the current ratio between elements if i need to clamp it
	Data["ProjLength"] = math.Clamp(PlayerData["ProjLength"]*Ratio,GUIData["MinProjLength"],GUIData["MaxProjLength"])
	Data["PropLength"] = math.Clamp(PlayerData["PropLength"]*Ratio,GUIData["MinPropLength"],GUIData["MaxPropLength"])
	
	GUIData["MinCavLength"] = 0
	GUIData["MaxCavLength"] = Data["ProjLength"]*0.5 --Maximum Cavity length determined after the real max projectile lenght is certain
	Data["CavLength"] = math.min(PlayerData["Data5"],GUIData["MaxCavLength"])
	
	Data["PropMass"] = Data["FrAera"] * (Data["PropLength"]*ACF.PDensity/1000) --Volume of the case as a cylinder * Powder density converted from g to kg
	Data["ProjMass"] = Data["FrAera"] * ((Data["ProjLength"]-Data["CavLength"])*7.9/1000) --Volume of the projectile as a cylinder * fraction missing due to hollow point (Data5) * density of steel
	Data["ShovePower"] = 0.3 + (Data["CavLength"]/Data["ProjLength"])
	Data["PenAera"] = (3.1416 * (Data["Caliber"]/2 + Data["CavLength"])^2)^ACF.PenAreaMod
	Data["DragCoef"] = ((Data["FrAera"]/10000)/Data["ProjMass"])
	Data["MuzzleVel"] = ACF_MuzzleVelocity( Data["PropMass"], Data["ProjMass"], Data["Caliber"] )
	
	Data["RoundVolume"] = Data["FrAera"] * (Data["ProjLength"] + Data["PropLength"])	
	Data["BoomPower"] = Data["PropMass"]

	if SERVER then --Only the crates need this part
		ServerData["Id"] = PlayerData["Id"]
		ServerData["Type"] = PlayerData["Type"]
		return table.Merge(Data,ServerData)
	end
	
	if CLIENT then --Only tthe GUI needs this part
		local Energy = ACF_Kinetic( Data["MuzzleVel"]*39.37 , Data["ProjMass"], ACF.RoundTypes[PlayerData["Type"]]["limitvel"] )
		GUIData["MaxKETransfert"] = Energy.Kinetic*Data["ShovePower"]
		GUIData["MaxPen"] = (Energy.Penetration/Data["PenAera"])*ACF.KEtoRHA
		return table.Merge(Data,GUIData)
	end
	
end

--GUI stuff after this
function ACF_HPGUICreate( Panel, Table )

	acfmenupanel:AmmoSelect()
		
	acfmenupanel:AmmoSlider("PropLength",0,0,1000,3, "Propellant Length", "")	--Propellant Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength",0,0,1000,3, "Projectile Length", "")	--Projectile Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("CavLength",0,0,1000,2, "Hollow Point Length", "")--Hollow Point Cavity Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "")			--Tracer checkbox (Name, Title, Desc)
	
	acfmenupanel:AmmoText("VelocityDisplay", "")	--Proj muzzle velocity (Name, Desc)
	acfmenupanel:AmmoText("PenetrationDisplay", "")	--Proj muzzle penetration (Name, Desc)
	acfmenupanel:AmmoText("KEDisplay", "")			--Proj muzzle KE (Name, Desc)
	
	ACF_HPGUIUpdate( Panel, nil )
	
end

function ACF_HPGUIUpdate( Panel, Table )
	
	local PlayerData = {}
		PlayerData["Id"] = acfmenupanel.AmmoData["Data"]["id"]			--AmmoSelect GUI
		PlayerData["Type"] = "HP"										--Hardcoded, match ACFRoundTypes table index
		PlayerData["PropLength"] = acfmenupanel.AmmoData["PropLength"]	--PropLength slider
		PlayerData["ProjLength"] = acfmenupanel.AmmoData["ProjLength"]	--ProjLength slider
		PlayerData["Data5"] = acfmenupanel.AmmoData["CavLength"]
		--PlayerData["Data6"] = acfmenupanel.AmmoData[Name]		--Not used
		--PlayerData["Data7"] = acfmenupanel.AmmoData[Name]		--Not used
		--PlayerData["Data8"] = acfmenupanel.AmmoData[Name]		--Not used
		--PlayerData["Data9"] = acfmenupanel.AmmoData[Name]		--Not used
		local Tracer = 0
		if acfmenupanel.AmmoData["Tracer"] then Tracer = 1 end
		PlayerData["Data10"] = Tracer				--Tracer
	
	local Data = ACF_HPConvert( Panel, PlayerData )
	
	RunConsoleCommand( "acfmenu_data1", acfmenupanel.AmmoData["Data"]["id"] )
	RunConsoleCommand( "acfmenu_data2", "HP" )					--Hardcoded, match ACFRoundTypes table index
	RunConsoleCommand( "acfmenu_data3", Data.PropLength )		--For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand( "acfmenu_data4", Data.ProjLength )		--And Data4 total round mass
	RunConsoleCommand( "acfmenu_data5", Data.CavLength )
	RunConsoleCommand( "acfmenu_data10", Data.Tracer )
	
	acfmenupanel:AmmoSlider("PropLength",Data.PropLength,Data.MinPropLength,Data["MaxTotalLength"],3, "Propellant Length", "Propellant Mass : "..(math.floor(Data.PropMass*1000)).." g" )	--Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength",Data.ProjLength,Data.MinProjLength,Data["MaxTotalLength"],3, "Projectile Length", "Projectile Mass : "..(math.floor(Data.ProjMass*1000)).." g")	--Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	
	acfmenupanel:AmmoSlider("CavLength",Data.CavLength,Data.MinCavLength,Data.MaxCavLength,2, "Hollow Point Length", "Expanded caliber : "..(math.floor(Data.Caliber*10 + Data.CavLength*20)).." mm")--Hollow Point Cavity Slider (Name, Min, Max, Decimals, Title, Desc)
	
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : "..(math.floor(Data.Tracer*10)/10).."cm\n", "" )			--Tracer checkbox (Name, Title, Desc)
	
	acfmenupanel:AmmoText("VelocityDisplay", "Muzzle Velocity : "..math.floor(Data.MuzzleVel*ACF.VelScale).." m\s")	--Proj muzzle velocity (Name, Desc)
	acfmenupanel:AmmoText("PenetrationDisplay", "Maximum Penetration : "..math.floor(Data.MaxPen).." mm RHA")	--Proj muzzle penetration (Name, Desc)
	acfmenupanel:AmmoText("KEDisplay", "Kinetic Energy Transfered : "..math.floor(Data.MaxKETransfert).." KJ")			--Proj muzzle KE (Name, Desc)	
		
end
