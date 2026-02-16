-- gamemode/cl_hud.lua
-- Restored Original Fretta-Style HUD

function GM:HUDPaint()
	self.BaseClass:HUDPaint()
	
	-- Draw the custom EFT HUD layers (defined in cl_init.lua)
	if self.OnHUDPaint then self:OnHUDPaint() end
end

function GM:HUDNeedsUpdate()
	-- If the HUD is vgui based, we don't need to return true here
	-- unless we're using the old pre-fretta HUD system.
	return false 
end

function GM:OnHUDUpdated()
end

function GM:RefreshHUD()
	if IsValid(self.HudLayout) then self.HudLayout:Remove() end
	
	self.HudLayout = vgui.Create("DHudLayout")

	if IsValid(self.HudLayout) then
		local bar = vgui.Create("DHudBar")
		self.HudLayout:AddItem(bar)


		-- Health and Ammo removed per user request (files missing)
		-- local ammo = vgui.Create("DHudAmmo")
		-- bar:AddItem(ammo)
		
		-- local health = vgui.Create("DHudHealth")
		-- bar:AddItem(health)
		
		local time = vgui.Create("DHudCountdown")
		self.HudLayout:AddItem(time)
	end
end

hook.Add("InitPostEntity", "EFT_CreateHUD", function()
	GAMEMODE:RefreshHUD()
end)

-- If refreshed mid-game
if IsValid(LocalPlayer()) then
	GAMEMODE:RefreshHUD()
end
