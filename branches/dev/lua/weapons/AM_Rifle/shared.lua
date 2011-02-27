
// Variables that are used on both client and server

SWEP.Author			= "Kafouille"
SWEP.Contact		= ""
SWEP.Purpose		= "Making holes in various materials"
SWEP.Instructions	= "ACF AMR"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.ViewModel			= "models/weapons/v_sniper.mdl"
SWEP.WorldModel			= "models/weapons/w_sniper.mdl"

SWEP.Weight				= 10

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 25
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "CombineCannon"
SWEP.Primary.UserData = {}
	SWEP.Primary.UserData["Id"] = "14.5mmMG"
	SWEP.Primary.UserData["Type"] = "AP"
	SWEP.Primary.UserData["PropLength"] = 6
	SWEP.Primary.UserData["ProjLength"] = 10
	SWEP.Primary.UserData["Data5"] = 0.6
	SWEP.Primary.UserData["Data6"] = 0
	SWEP.Primary.UserData["Data7"] = 0
	SWEP.Primary.UserData["Data8"] = 0
	SWEP.Primary.UserData["Data9"] = 0
	SWEP.Primary.UserData["Data10"] = 0

SWEP.Primary.Inaccuracy				= 5								--Base spray

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.IronSightsPos 			= Vector( -5.85 , -7 , 1.2 )		--Lateral, Depth, Vertical
SWEP.IronSightsAng 			= Vector( 0, -1, 0 )				--Pitch, Yaw, Roll

function SWEP:Initialize()
	self:ResetVars()
	
	self.Primary.BulletData		= {}
	self.Sway = Angle(0,0,0)

	self.ConvertData = ACF.RoundTypes[self.Primary.UserData["Type"]]["convert"]		--Call the correct function for this round type to convert user input data into ballistics data
	self.Primary.BulletData = self:ConvertData( self.Primary.UserData )	--Put the results into the BulletData table

	if ( SERVER ) then 
		self:SetWeaponHoldType("ar2")
		self.Owner:GiveAmmo( self.Primary.DefaultClip, self.Primary.Ammo )	
	end

end

function SWEP:PrimaryAttack()

	if !self:CanPrimaryAttack() then return end
	
	local MuzzlePos = self.Owner:GetShootPos()
	local MuzzleVec = self.Owner:GetAimVector()
	local Speed = self.Primary.BulletData["MuzzleVel"]
	local Modifiers = self:CalculateModifiers()
	local Recoil = (self.Primary.BulletData["ProjMass"] * self.Primary.BulletData["MuzzleVel"] + self.Primary.BulletData["PropMass"] * 3000)/self.Weight
	self:ApplyRecoil(math.min(Recoil,50))
	
	if CLIENT then return end
			
	if ( self.RoundType != "Empty" ) then

		local Inaccuracy = VectorRand() / 360 * self.Inaccuracy * Modifiers
		local Flight = (MuzzleVec+Inaccuracy):GetNormalized() * Speed * 39.37
		
		self.Primary.BulletData["Pos"] = MuzzlePos
		self.Primary.BulletData["Flight"] = (MuzzleVec+Inaccuracy):GetNormalized() * Speed * 39.37 + self:GetVelocity()
		self.Primary.BulletData["Owner"] = self.Owner
		self.Primary.BulletData["Gun"] = self.Owner
		self.CreateShell = ACF.RoundTypes[self.Primary.BulletData["Type"]]["create"]
		self:CreateShell( self.Primary.BulletData )
		
		self:MuzzleEffect( MuzzlePos , MuzzleVec:Angle() )
		self:TakePrimaryAmmo(1)
	
	end
	
end

function SWEP:CreateShell()
	--This gets overwritten by the ammo function
end

function SWEP:MuzzleEffect()
 
 	self:EmitSound("weapons/AMR/sniper_fire.wav")
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:MuzzleFlash()
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	
end

function SWEP:ApplyRecoil(Recoil)
	
	if self.OwnerIsNPC then return end
	
	local Mod = self:CalculateModifiers()
	local RecoilAng = Angle( Recoil*Mod*math.Rand(-1,-0.25), Recoil*Mod*math.Rand(-0.25,0.25), 0)

	if CLIENT then
		self.Sway = self.Sway + Angle( Mod*math.Rand(-1+self.Sway.p,1-self.Sway.p)/1000, Mod*math.Rand(-1+self.Sway.y,1-self.Sway.y)/1000, 0)
		print(self.Sway)
		self.Owner:SetEyeAngles(self.Owner:EyeAngles() + RecoilAng + self.Sway)
	else
		self.Owner:ViewPunch(RecoilAng*1.5)
	end
	
end

-- Acuracy/recoil modifiers
function SWEP:CalculateModifiers()

	local modifier = 1

	if self.Owner:KeyDown(IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT) then
		modifier = modifier*2
	end
	
	if not self.Owner:IsOnGround() then
		modifier = modifier*2 --You can't be jumping and crouching at the same time, so return here
	return modifier end
	
	if self.Owner:Crouching() then 
		modifier = modifier*0.5
	end
		
	return modifier

end

function SWEP:Think()	

	if self.Owner:KeyDown(IN_USE) and !self.Loaded then
		self:CrateReload()
	end
	
	self:ApplyRecoil(0)
	
	if not self.Owner:IsOnGround() then
		self:ResetVars()
	end
	if self.OwnerIsNPC or (SERVER and not self.Owner:IsListenServerHost()) or not self.Weapon:GetNetworkedBool("Ironsights", false) then return end
		
	self:NextThink( CurTime()+0.1 )
	
end

function SWEP:SecondaryAttack()

	
end

function SWEP:Reload()
	
	if  ( self.Weapon:Clip1() < self.Primary.ClipSize && self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 ) then
	
		self.Weapon:EmitSound("weapons/AMR/sniper_reload.wav",350,110)
		self.Weapon:DefaultReload(ACT_VM_RELOAD)
		
	end
	
end

function SWEP:CrateReload()

	local ViewTr = { }
		ViewTr.start = self.Owner:GetShootPos()
		ViewTr.endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector()*128
		ViewTr.filter = {self.Owner, self.Weapon}
	local ViewRes = util.TraceLine(ViewTr)					--Trace to see if it will hit anything
	
	if SERVER then	
		local AmmoEnt = ViewRes.Entity
		if AmmoEnt and AmmoEnt:IsValid() and AmmoEnt.Ammo > 0 and AmmoEnt.RoundId == "14.5mmMG" then
			local CurAmmo = self.Owner:GetAmmoCount( self.Primary.Ammo )
			local Transfert = math.min(AmmoEnt.Ammo, self.Primary.DefaultClip-CurAmmo)
			AmmoEnt.Ammo = AmmoEnt.Ammo - Transfert
			self.Owner:GiveAmmo( Transfert, self.Primary.Ammo )
			
			self.BulletData = AmmoEnt.BulletData
			
			return true	
		end
	end
	
end

/*---------------------------------------------------------
   Name: ShouldDropOnDie
   Desc: Should this weapon be dropped when its owner dies?
---------------------------------------------------------*/
function SWEP:ShouldDropOnDie()
	return true
end

function SWEP:ResetVars()
	
	self.LastViewTime = CurTime()
	if self.Owner then
		self.OwnerIsNPC = self.Owner:IsNPC() -- This ought to be better than getting it every time we fire
	end
	
end

-- We need to call ResetVars() on these functions so we don't whip out a weapon with scope mode or insane recoil right of the bat or whatnot
function SWEP:Holster(wep) 		self:ResetVars() return true end
function SWEP:Equip(NewOwner) 	self:ResetVars() return true end
function SWEP:OnRemove() 		self:ResetVars() return true end
function SWEP:OnDrop() 			self:ResetVars() return true end
function SWEP:OwnerChanged() 	self:ResetVars() return true end
function SWEP:OnRestore() 		self:ResetVars() return true end
