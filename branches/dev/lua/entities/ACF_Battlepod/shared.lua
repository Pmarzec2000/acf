ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "ACF Pod Base"
ENT.Author = "Kafouille"

hook.Add( "Move", "ACF Battlepod", function( ply, data )
	if not ValidEntity( ply ) then return end
	if ply:GetNWBool("in_acf_pod") then
		print("Hooked")
		local Seat = ply:GetNWEntity("acf_pod")
		if ValidEntity( Seat ) then
			data:SetVelocity( Seat:GetVelocity() )
			ply:SetAngles( Seat:GetAngles() )
		return true
		end
	end
end)

hook.Add("SetupMove", "ACF Battlepod", function( Driver, data )
	if not ValidEntity( ply ) then return end
	if ply:GetNWBool("in_acf_pod") then
		local Seat = ply:GetNWEntity("acf_pod")
		if ValidEntity( Seat ) then
			local AngPos = Seat:GetAttachment( Seat:LookupAttachment("vehicle_feet_passenger0") )
			data:SetVelocity( Seat:GetVelocity() )
			data:SetOrigin( AngPos.Pos+AngPos.Ang:Up()*25-Vector(0,0,64) )
			return true
		end
	end
end)
