-- EFT Custom Scoreboard
-- Clean replacement for Fretta scoreboard

local MAT_RED = Material("red_rhinos")
local MAT_BLUE = Material("blue_bulls")

-- Fonts (scaled up 25%)
surface.CreateFont("EFTScoreboardTitle", {
	font = "Patua One",
	size = 60,
	weight = 500,
	antialias = true
})

surface.CreateFont("EFTScoreboardTeam", {
	font = "Patua One",
	size = 60,
	weight = 500,
	antialias = true
})

surface.CreateFont("EFTScoreboardScore", {
	font = "Patua One",
	size = 80,
	weight = 700,
	antialias = true
})

surface.CreateFont("EFTScoreboardPlayer", {
	font = "Patua One",
	size = 22,
	weight = 400,
	antialias = true
})

surface.CreateFont("EFTScoreboardHeader", {
	font = "Patua One",
	size = 18,
	weight = 400,
	antialias = true
})

surface.CreateFont("EFTScoreboardSubtitle", {
	font = "Patua One",
	size = 20,
	weight = 400,
	antialias = true
})

local PANEL = {}

function PANEL:Init()
	-- Scaled up: wider and 2x taller
	self:SetSize(1200, 900)
	self:Center()
	self:MakePopup()
	self:SetKeyboardInputEnabled(false)
	self:SetMouseInputEnabled(true)
	
	self.RedPlayers = {}
	self.BluePlayers = {}
	self.RedScroll = 0
	self.BlueScroll = 0
	self.MaxVisiblePlayers = 15 -- Max players shown per team before scrolling
end

function PANEL:Think()
	-- Update player lists
	self.RedPlayers = team.GetPlayers(TEAM_RED)
	self.BluePlayers = team.GetPlayers(TEAM_BLUE)
	self.Spectators = team.GetPlayers(TEAM_SPECTATOR)
end

function PANEL:OnMouseWheeled(delta)
	-- Determine which team panel the mouse is over
	local mx, my = self:CursorPos()
	local w = self:GetWide()
	
	if mx < w/2 then
		-- Red team
		self.RedScroll = math.Clamp(self.RedScroll - delta, 0, math.max(0, #self.RedPlayers - self.MaxVisiblePlayers))
	else
		-- Blue team
		self.BlueScroll = math.Clamp(self.BlueScroll - delta, 0, math.max(0, #self.BluePlayers - self.MaxVisiblePlayers))
	end
end

function PANEL:DrawPlayerRow(ply, x, y, w, isLocal)
	local rowH = 36
	
	-- Background
	local bgColor = isLocal and Color(255, 255, 255, 40) or Color(0, 0, 0, 80)
	draw.RoundedBox(4, x, y, w, rowH, bgColor)
	
	-- Avatar
	if not ply.ScoreboardAvatar then
		ply.ScoreboardAvatar = vgui.Create("AvatarImage", self)
		ply.ScoreboardAvatar:SetSize(32, 32)
		ply.ScoreboardAvatar:SetPlayer(ply, 64)
	end
	ply.ScoreboardAvatar:SetPos(x + 6, y + 2)
	ply.ScoreboardAvatar:SetVisible(true)
	
	-- Name
	draw.SimpleText(ply:Name(), "EFTScoreboardPlayer", x + 46, y + rowH/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	
	-- Goals (using custom NWInt or Frags)
	local goals = ply:GetNWInt("Goals", 0)
	draw.SimpleText(goals, "EFTScoreboardPlayer", x + w - 150, y + rowH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	-- Tackles
	local tackles = ply:GetNWInt("Tackles", 0)
	draw.SimpleText(tackles, "EFTScoreboardPlayer", x + w - 85, y + rowH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	-- Ping
	draw.SimpleText(ply:Ping(), "EFTScoreboardPlayer", x + w - 25, y + rowH/2, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	return rowH + 4
end

function PANEL:Paint(w, h)
	-- Background blur
	Derma_DrawBackgroundBlur(self, 0)
	
	-- Main background
	draw.RoundedBox(16, 0, 0, w, h, Color(20, 20, 25, 245))
	
	-- Title
	draw.SimpleText(GetHostName(), "EFTScoreboardTitle", w/2, 25, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("Extreme Football Throwdown", "EFTScoreboardSubtitle", w/2, 85, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	
	local teamW = (w - 80) / 2
	local teamStartY = 130
	local logoSize = 100
	
	-- RED TEAM PANEL
	local redX = 25
	draw.RoundedBox(10, redX, teamStartY, teamW, h - teamStartY - 30, Color(100, 30, 30, 150))
	
	-- Red Logo & Score
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(MAT_RED)
	surface.DrawTexturedRect(redX + 20, teamStartY + 15, logoSize, logoSize)
	
	-- Team name centered between logo and score
	local teamNameCenterX = redX + logoSize + 40 + (teamW - logoSize - 120) / 2
	draw.SimpleText("Red Rhinos", "EFTScoreboardTeam", teamNameCenterX, teamStartY + 45, team.GetColor(TEAM_RED), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(team.GetScore(TEAM_RED), "EFTScoreboardScore", redX + teamW - 40, teamStartY + 55, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	
	-- Red Headers
	local headerY = teamStartY + logoSize + 30
	draw.SimpleText("Player", "EFTScoreboardHeader", redX + 46, headerY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("Goals", "EFTScoreboardHeader", redX + teamW - 150, headerY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("Tackles", "EFTScoreboardHeader", redX + teamW - 85, headerY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("Ping", "EFTScoreboardHeader", redX + teamW - 25, headerY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	
	-- Red Players (with scroll support)
	local playerY = headerY + 28
	local redStart = self.RedScroll + 1
	local redEnd = math.min(#self.RedPlayers, self.RedScroll + self.MaxVisiblePlayers)
	
	if self.RedScroll > 0 then
		draw.SimpleText("▲ " .. self.RedScroll .. " more", "EFTScoreboardHeader", redX + teamW/2, playerY - 5, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end
	
	for i = redStart, redEnd do
		local ply = self.RedPlayers[i]
		if ply then
			playerY = playerY + self:DrawPlayerRow(ply, redX + 8, playerY, teamW - 16, ply == LocalPlayer())
		end
	end
	
	if redEnd < #self.RedPlayers then
		draw.SimpleText("▼ " .. (#self.RedPlayers - redEnd) .. " more", "EFTScoreboardHeader", redX + teamW/2, playerY + 5, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
	
	-- BLUE TEAM PANEL
	local blueX = w/2 + 15
	draw.RoundedBox(10, blueX, teamStartY, teamW, h - teamStartY - 30, Color(30, 30, 100, 150))
	
	-- Blue Logo & Score
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(MAT_BLUE)
	surface.DrawTexturedRect(blueX + 20, teamStartY + 15, logoSize, logoSize)
	
	-- Team name centered between logo and score
	local blueNameCenterX = blueX + logoSize + 40 + (teamW - logoSize - 120) / 2
	draw.SimpleText("Blue Bulls", "EFTScoreboardTeam", blueNameCenterX, teamStartY + 45, team.GetColor(TEAM_BLUE), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(team.GetScore(TEAM_BLUE), "EFTScoreboardScore", blueX + teamW - 40, teamStartY + 55, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	
	-- Blue Headers
	draw.SimpleText("Player", "EFTScoreboardHeader", blueX + 46, headerY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("Goals", "EFTScoreboardHeader", blueX + teamW - 150, headerY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("Tackles", "EFTScoreboardHeader", blueX + teamW - 85, headerY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("Ping", "EFTScoreboardHeader", blueX + teamW - 25, headerY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	
	-- Blue Players (with scroll support)
	playerY = headerY + 28
	local blueStart = self.BlueScroll + 1
	local blueEnd = math.min(#self.BluePlayers, self.BlueScroll + self.MaxVisiblePlayers)
	
	if self.BlueScroll > 0 then
		draw.SimpleText("▲ " .. self.BlueScroll .. " more", "EFTScoreboardHeader", blueX + teamW/2, playerY - 5, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end
	
	for i = blueStart, blueEnd do
		local ply = self.BluePlayers[i]
		if ply then
			playerY = playerY + self:DrawPlayerRow(ply, blueX + 8, playerY, teamW - 16, ply == LocalPlayer())
		end
	end
	
	if blueEnd < #self.BluePlayers then
		draw.SimpleText("▼ " .. (#self.BluePlayers - blueEnd) .. " more", "EFTScoreboardHeader", blueX + teamW/2, playerY + 5, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
	
	-- Spectators (bottom)
	if self.Spectators and #self.Spectators > 0 then
		local specNames = {}
		for _, ply in ipairs(self.Spectators) do
			table.insert(specNames, ply:Name())
		end
		draw.SimpleText("Spectators: " .. table.concat(specNames, ", "), "EFTScoreboardHeader", w/2, h - 15, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end
end

function PANEL:OnRemove()
	-- Clean up avatar images
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply.ScoreboardAvatar) then
			ply.ScoreboardAvatar:Remove()
			ply.ScoreboardAvatar = nil
		end
	end
end

vgui.Register("EFTScoreboard", PANEL, "DPanel")

-- Scoreboard hooks
local g_Scoreboard = nil

function GM:ScoreboardShow()
	if not IsValid(g_Scoreboard) then
		g_Scoreboard = vgui.Create("EFTScoreboard")
	end
	g_Scoreboard:SetVisible(true)
	g_Scoreboard:MakePopup()
	g_Scoreboard:SetKeyboardInputEnabled(false)
	return true
end

function GM:ScoreboardHide()
	if IsValid(g_Scoreboard) then
		g_Scoreboard:SetVisible(false)
	end
	return true
end
