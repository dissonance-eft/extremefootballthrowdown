-- gamemode/cl_hud.lua
/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity), C-009 (Status Info)
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
end

hook.Add("InitPostEntity", "EFT_CreateHUD", function()
	GAMEMODE:RefreshHUD()
end)

-- If refreshed mid-game
-- Hide standard HL2 HUD elements (Health, Suit, Ammo, etc.)
function GM:HUDShouldDraw(name)
	local hidden = {
		["CHudHealth"] = true,
		["CHudBattery"] = true,
		["CHudAmmo"] = true,
		["CHudSecondaryAmmo"] = true,
		["CHudWeaponSelection"] = true,
		["CHudCrosshair"] = true -- We use custom crosshair or third person
	}
	
	if hidden[name] then return false end
	
	-- Fretta base might have its own logic, or we let other things draw
	if self.BaseClass.HUDShouldDraw then
		return self.BaseClass:HUDShouldDraw(name)
	end
	
	return true
end

if IsValid(LocalPlayer()) then
	GAMEMODE:RefreshHUD()
end
