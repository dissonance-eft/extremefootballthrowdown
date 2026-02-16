
local MAT_RED = Material("red_rhinos")
local MAT_BLUE = Material("blue_bulls")

-- Create fonts for team select screen
surface.CreateFont("EFTTeamSelectTitle", {
	font = "Patua One",
	size = 72,
	weight = 500,
	antialias = true
})

surface.CreateFont("EFTTeamSelectName", {
	font = "Patua One",
	size = 44,
	weight = 500,
	antialias = true
})

surface.CreateFont("EFTTeamSelectScore", {
	font = "Patua One",
	size = 56,
	weight = 500,
	antialias = true
})

surface.CreateFont("EFTTeamSelectPlayer", {
	font = "Patua One",
	size = 22,
	weight = 400,
	antialias = true
})

surface.CreateFont("EFTTeamSelectHint", {
	font = "Patua One",
	size = 24,
	weight = 400,
	antialias = true
})

surface.CreateFont("EFTTeamSelectSpectator", {
	font = "Patua One",
	size = 28,
	weight = 400,
	antialias = true
})

local function CreatePlayerRows(parent, teamid, startY)
	local players = team.GetPlayers(teamid)
	if #players == 0 then return end
	
	local y = startY
	for _, ply in ipairs(players) do
		-- Calculate centering
		surface.SetFont("EFTTeamSelectPlayer")
		local tw, th = surface.GetTextSize(ply:Name())
		local totalW = 32 + 8 + tw
		local startX = (parent:GetWide() - totalW) / 2
		
		local av = vgui.Create("AvatarImage", parent)
		av:SetSize(32, 32)
		av:SetPos(startX, y)
		av:SetPlayer(ply, 32)
		
		local lbl = vgui.Create("DLabel", parent)
		lbl:SetText(ply:Name())
		lbl:SetFont("EFTTeamSelectPlayer")
		lbl:SetColor(color_white)
		lbl:SetPos(startX + 40, y)
		lbl:SetSize(tw + 10, 32)
		lbl:SetContentAlignment(4) -- Left Center
		
		y = y + 36
	end
end

function GM:ShowTeam()
	-- Don't show team select during map voting or end of game
	if GetGlobalBool("InGamemodeVote", false) or GetGlobalBool("IsEndOfGame", false) then
		return
	end
	
	if IsValid(self.TeamSelectFrame) then self.TeamSelectFrame:Remove() end

	local w, h = ScrW(), ScrH()
	local frame = vgui.Create("DFrame")
	frame:SetTitle("")
	frame:SetSize(w, h)
	frame:Center()
	frame:MakePopup()
	frame:SetDraggable(false)
	frame:ShowCloseButton(false) -- Hide close button, use ESC instead
	frame:SetKeyboardInputEnabled(true) -- Capture keyboard
	frame.Paint = function(s, w, h)
		Derma_DrawBackgroundBlur(s, 0)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
		
		draw.SimpleText("Choose a Team", "EFTTeamSelectTitle", w/2, 50, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		
		-- Show hint text at bottom
		local hintText = "Press ESC to close"
		draw.SimpleText(hintText, "EFTTeamSelectHint", w/2, h - 30, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	-- Handle ESC key to close the menu
	frame.OnKeyCodePressed = function(self, key)
		if key == KEY_ESCAPE then
			self:Close()
			return true
		end
	end
	
	self.TeamSelectFrame = frame

	local teamW = 500
	local teamH = h * 0.65
	local yPos = h * 0.15
	local logoSize = 250

	-- RED TEAM (Left)
	local redBtn = vgui.Create("DButton", frame)
	redBtn:SetPos(w/2 - teamW - 60, yPos)
	redBtn:SetSize(teamW, teamH)
	redBtn:SetText("")
	redBtn.Paint = function(s, w, h)
		-- Background (Hover effect)
		draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and Color(80, 25, 25, 220) or Color(50, 10, 10, 180))
		
		-- Logo
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(MAT_RED)
		surface.DrawTexturedRect(w/2 - logoSize/2, 30, logoSize, logoSize)

		-- Name
		draw.SimpleText("Red Rhinos", "EFTTeamSelectName", w/2, 30 + logoSize + 15, team.GetColor(TEAM_RED), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		
		-- Score
		draw.SimpleText(team.GetScore(TEAM_RED), "EFTTeamSelectScore", w/2, 30 + logoSize + 70, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
	redBtn.DoClick = function()
		RunConsoleCommand("changeteam", TEAM_RED)
		frame:Close()
	end
	
	-- Player List Red
	CreatePlayerRows(redBtn, TEAM_RED, 30 + logoSize + 140)


	-- BLUE TEAM (Right)
	local blueBtn = vgui.Create("DButton", frame)
	blueBtn:SetPos(w/2 + 60, yPos)
	blueBtn:SetSize(teamW, teamH)
	blueBtn:SetText("")
	blueBtn.Paint = function(s, w, h)
		-- Background (Hover effect)
		draw.RoundedBox(12, 0, 0, w, h, s:IsHovered() and Color(25, 25, 80, 220) or Color(10, 10, 50, 180))
		
		-- Logo
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(MAT_BLUE)
		surface.DrawTexturedRect(w/2 - logoSize/2, 30, logoSize, logoSize)

		-- Name
		draw.SimpleText("Blue Bulls", "EFTTeamSelectName", w/2, 30 + logoSize + 15, team.GetColor(TEAM_BLUE), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		
		-- Score
		draw.SimpleText(team.GetScore(TEAM_BLUE), "EFTTeamSelectScore", w/2, 30 + logoSize + 70, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
	blueBtn.DoClick = function()
		RunConsoleCommand("changeteam", TEAM_BLUE)
		frame:Close()
	end
	
	-- Player List Blue
	CreatePlayerRows(blueBtn, TEAM_BLUE, 30 + logoSize + 140)


	-- SPECTATOR (Bottom)
	local specBtn = vgui.Create("DButton", frame)
	specBtn:SetSize(280, 50)
	specBtn:SetPos(w/2 - 140, h - 110)
	specBtn:SetText("")
	specBtn.Paint = function(s, bw, bh)
		draw.RoundedBox(8, 0, 0, bw, bh, s:IsHovered() and Color(80, 80, 80, 200) or Color(50, 50, 50, 180))
		draw.SimpleText("Spectator", "EFTTeamSelectSpectator", bw/2, bh/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	specBtn.DoClick = function()
		RunConsoleCommand("changeteam", TEAM_SPECTATOR)
		frame:Close()
	end
	
end

-- Block the game menu from opening while team select is visible
hook.Add("OnPauseMenuShow", "EFT_BlockPauseForTeamSelect", function()
	if GAMEMODE and IsValid(GAMEMODE.TeamSelectFrame) then
		-- Close the team select instead of opening game menu
		GAMEMODE.TeamSelectFrame:Close()
		return false -- Block the pause menu
	end
end)
