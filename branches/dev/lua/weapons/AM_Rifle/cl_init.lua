
include('shared.lua')

SWEP.PrintName			= "ACF Antimaterial Rifle"			
SWEP.Slot				= 3
SWEP.SlotPos			= 3
SWEP.DrawAmmo			= true
SWEP.DrawCrosshair		= true
SWEP.IconLetter			= "b"

-- mostly garry's code
-- function SWEP:GetViewModelPosition(pos, ang)

	-- if not self.IronSightsPos then return pos, ang end

	-- local bIron = self.Weapon:GetNetworkedBool("Ironsights")
	-- if bIron ~= self.bLastIron then -- Are we toggling ironsights?
	
		-- self.bLastIron = bIron 
		-- self.fIronTime = CurTime()
		
		-- if bIron then 
			-- self.SwayScale 	= 0.3
			-- self.BobScale 	= 0.1
		-- else 
			-- self.SwayScale 	= 1.0
			-- self.BobScale 	= 1.0
		-- end
	
	-- end
	
	-- local fIronTime = self.fIronTime or 0

	-- if not bIron and (fIronTime < CurTime() - self.ZoomTime) then 
		-- return pos, ang 
	-- end
	
	-- local Mul = 1.0 -- we scale the model pos by this value so we can interpolate between ironsight/normal view
	
	-- if fIronTime > CurTime() - self.ZoomTime then
	
		-- Mul = math.Clamp((CurTime() - fIronTime) / self.ZoomTime, 0, 1)
		-- if not bIron then Mul = 1 - Mul end
	
	-- end

	-- local Offset	= self.IronSightsPos
	
	-- if self.IronSightsAng then
	
		-- ang = ang*1
		-- ang:RotateAroundAxis(ang:Right(), 		self.IronSightsAng.x * Mul)
		-- ang:RotateAroundAxis(ang:Up(), 			self.IronSightsAng.y * Mul)
		-- ang:RotateAroundAxis(ang:Forward(), 	self.IronSightsAng.z * Mul)
	
	-- end
	
	-- local Right 	= ang:Right()
	-- local Up 		= ang:Up()
	-- local Forward 	= ang:Forward()

	-- pos = pos + Offset.x * Right * Mul
	-- pos = pos + Offset.y * Forward * Mul
	-- pos = pos + Offset.z * Up * Mul

	-- return pos, ang
	
-- end

-- This function handles player FOV clientside.  It is used for scope and ironsight zooming.
-- function SWEP:TranslateFOV(current_fov)

	-- local fScopeZoom = self.Weapon:GetNetworkedFloat("ScopeZoom")
	-- if self.Weapon:GetNetworkedBool("Scope") then return current_fov/fScopeZoom end
	
	-- local bIron = self.Weapon:GetNetworkedBool("Ironsights")
	-- if bIron ~= self.bLastIron then -- Do the same thing as in CalcViewModel.  I don't know why this works, but it does.
	
		-- self.bLastIron = bIron 
		-- self.fIronTime = CurTime()

	-- end
	
	-- local fIronTime = self.fIronTime or 0

	-- if not bIron and (fIronTime < CurTime() - self.ZoomTime) then 
		-- return current_fov
	-- end
	
	-- local Mul = 1.0 -- More interpolating shit
	
	-- if fIronTime > CurTime() - self.ZoomTime then
	
		-- Mul = math.Clamp((CurTime() - fIronTime) / self.ZoomTime, 0, 1)
		-- if not bIron then Mul = 1 - Mul end
	
	-- end

	-- current_fov = current_fov*(1 + Mul/self.IronSightZoom - Mul)

	-- return current_fov

-- end

