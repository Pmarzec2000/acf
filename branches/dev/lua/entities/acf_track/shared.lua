ENT.Type            = "anim"
ENT.Base            = "base_gmodentity"

ENT.PrintName       = "ACF Tank Tracks"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function ENT:GetOverlayText()
	local name = self.Entity:GetNetworkedString("WireName")
	local txt = name or ""
	if (not SinglePlayer()) then
		local PlayerName = self:GetPlayerName()
		txt = txt .. "\n(" .. PlayerName .. ")"
	end
	if(name and name ~= "") then
	    if (txt == "") then
	        return "- "..name.." -"
	    end
	    return "- "..name.." -\n"..txt
	end
	return txt
end