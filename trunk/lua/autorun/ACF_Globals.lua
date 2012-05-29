ACF = {}
ACF.AmmoTypes = {}
ACF.MenuFunc = {}
print("ACF Loaded")

ACF.Threshold = 150	--Health Divisor
ACF.PartialPenPenalty = 5 --Exponent for the damage penalty for partial penetration
ACF.PenAreaMod = 0.85
ACF.KinFudgeFactor = 2.1	--True kinetic would be 2, over that it's speed biaised, below it's mass biaised
ACF.KEtoRHA = 0.25		--Empirical conversion from (kinetic energy in KJ)/(Aera in Cm2) to RHA penetration
ACF.GroundtoRHA = 0.05		--How much mm of steel is a mm of ground worth (Real soil is about 0.15
ACF.KEtoSpall = 1
ACF.AmmoMod = 1			-- Ammo modifier. 1 is 1x the amount of ammo
ACF.ArmorMod = 1

ACF.HEPower = 6000		--HE Filler power per KG in KJ
ACF.HEDensity = 1.65	--HE Filler density (That's TNT density)
ACF.HEFrag = 1500		--Mean fragment number for equal weight TNT and casing
ACF.HEBlastPen = 0.4	--Blast penetration exponent based of HE power

ACF.HEATMVScale = 0.73	--Filler KE to HEAT slug KE conversion expotential

ACF.DragDiv = 40		--Drag fudge factor
ACF.VelScale = 1		--Scale factor for the shell velocities in the game world
-- local PhysEnv = physenv.GetPerformanceSettings()
ACF.PhysMaxVel = 4000

ACF.PBase = 1050		--1KG of propellant produces this much KE at the muzzle, in kj
ACF.PScale = 1	--Gun Propellant power expotential
ACF.MVScale = 0.5  --Propellant to MV convertion expotential
ACF.PDensity = 1.6	--Gun propellant density (Real powders go from 0.7 to 1.6, i'm using higher densities to simulate case bottlenecking)

ACF.Year = 1945

CreateConVar('sbox_max_acf_gun', 12)
CreateConVar('sbox_max_acf_ammo', 32)
CreateConVar('sbox_max_acf_misc', 32)

AddCSLuaFile( "ACF_Globals.lua" )
AddCSLuaFile( "ACF/Client/cl_ACFBallistics.lua" )
AddCSLuaFile( "ACF/Client/cl_ACFMenu_GUI.lua" )

AddCSLuaFile( "ACF/Client/cl_ACFBallistics.lua" )
AddCSLuaFile( "ACF/Client/cl_ACFMenu_GUI.lua" )

if (SERVER) then

	include("ACF/Server/sv_ACFBase.lua")
	include("ACF/Server/sv_ACFDamage.lua")
	include("ACF/Server/sv_ACFBallistics.lua")
	
elseif (CLIENT) then

	include("ACF/Client/cl_ACFBallistics.lua")
	--include("ACF/Client/cl_ACFMenu_GUI.lua")
	
end

include("ACF/Shared/Rounds/RoundAP.lua")
include("ACF/Shared/Rounds/RoundAPHE.lua")
include("ACF/Shared/Rounds/RoundHE.lua")
include("ACF/Shared/Rounds/RoundHEAT.lua")
include("ACF/Shared/Rounds/RoundHP.lua")
include("ACF/Shared/Rounds/RoundRefill.lua")
include("ACF/Shared/Rounds/RoundFunctions.lua")

include("ACF/Shared/ACFGunList.lua")
include("ACF/Shared/ACFMobilityList.lua")
include("ACF/Shared/ACFSensorList.lua")

ACF.Weapons = list.Get("ACFEnts")
	
ACF.Classes = list.Get("ACFClasses")

ACF.RoundTypes = list.Get("ACFRoundTypes")

ACF.IdRounds = list.Get("ACFIdRounds")	--Lookup tables so i can get rounds classes from clientside with just an integer

PrecacheParticleSystem("tracer_tail_white")
for Class,Table in pairs(ACF.Classes["GunClass"]) do
	PrecacheParticleSystem(Table["muzzleflash"])
end

function ACF_MuzzleVelocity( Propellant, Mass, Caliber )

	local PEnergy = ACF.PBase * ((1+Propellant)^ACF.PScale-1)
	local Speed = ((PEnergy*2000/Mass)^ACF.MVScale)
	local Final = Speed -- - Speed * math.Clamp(Speed/2000,0,0.5)

	return Final
end

function ACF_Kinetic( Speed , Mass, LimitVel )
	
	LimitVel = LimitVel or 99999
	Speed = Speed/39.37
	
	local Energy = {}
		Energy.Kinetic = ((Mass) * ((Speed)^2))/2000 --Energy in KiloJoules
		Energy.Momentum = (Speed * Mass)
		
		local KE = (Mass * (Speed^ACF.KinFudgeFactor))/2000 + Energy.Momentum
		Energy.Penetration = math.max( KE - (math.max(Speed-LimitVel,0)^2)/(LimitVel*5) * (KE/200)^0.95 , KE*0.1 )
		--Energy.Penetration = math.max( KE - (math.max(Speed-LimitVel,0)^2)/(LimitVel*5) * (KE/200)^0.95 , KE*0.1 )
		--Energy.Penetration = math.max(Energy.Momentum^ACF.KinFudgeFactor - math.max(Speed-LimitVel,0)/(LimitVel*5) * Energy.Momentum , Energy.Momentum*0.1)
	
	return Energy
end

-- New healthmod/armormod/ammomod cvars
CreateConVar("acf_healthmod", 1)
CreateConVar("acf_armormod", 1)
CreateConVar("acf_ammomod", 1)

function ACF_CVarChangeCallback(CVar, Prev, New)
	if( CVar == "acf_healthmod" ) then
		ACF.Threshold = 150 / math.max(New, 0.01)
		print ("Health Mod changed to a factor of " .. New)
	elseif( CVar == "acf_armormod" ) then
		ACF.ArmorMod = 1 * math.max(New, 0)
		print ("Armor Mod changed to a factor of " .. New)
	elseif( CVar == "acf_ammomod" ) then
		ACF.AmmoMod = 1 * math.max(New, 0.01)
		print ("Ammo Mod changed to a factor of " .. New)
	end	
end

cvars.AddChangeCallback("acf_healthmod", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_armormod", ACF_CVarChangeCallback)
cvars.AddChangeCallback("acf_ammomod", ACF_CVarChangeCallback)