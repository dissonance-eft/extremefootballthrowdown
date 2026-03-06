/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity - UI), C-009 (Status Info)

-- F1: Controls / MOTD screen

surface.CreateFont("EFTHelpTitle", {
	font = "Patua One",
	size = 72,
	weight = 500,
	antialias = true
})

surface.CreateFont("EFTHelpSection", {
	font = "Patua One",
	size = 26,
	weight = 500,
	antialias = true
})

surface.CreateFont("EFTHelpBody", {
	font = "Patua One",
	size = 28,
	weight = 400,
	antialias = true
})

surface.CreateFont("EFTHelpWIPHead", {
	font = "Patua One",
	size = 30,
	weight = 500,
	antialias = true
})

surface.CreateFont("EFTHelpWIPBody", {
	font = "Patua One",
	size = 24,
	weight = 400,
	antialias = true
})

surface.CreateFont("EFTHelpHint", {
	font = "Patua One",
	size = 20,
	weight = 400,
	antialias = true
})

local COLOR_WHITE   = Color(255, 255, 255, 255)
local COLOR_DIM     = Color(190, 190, 190, 255)
local COLOR_ORANGE  = Color(255, 165,  40, 255)
local COLOR_YELLOW  = Color(255, 220,  60, 255)
local COLOR_DARK    = Color(  0,   0,   0, 210)
local COLOR_PANEL   = Color( 20,  20,  20, 200)
local COLOR_DIVIDER = Color( 80,  80,  80, 180)

local function MakeLabel(parent, x, y, w, h, text, font, color, wrap)
	local lbl = vgui.Create("DLabel", parent)
	lbl:SetPos(x, y)
	lbl:SetSize(w, h)
	lbl:SetText(text)
	lbl:SetFont(font)
	lbl:SetColor(color)
	if wrap then
		lbl:SetWrap(true)
		lbl:SetAutoStretchVertical(true)
	end
	return lbl
end

function GM:ShowHelp()
	if IsValid(self.HelpFrame) then self.HelpFrame:Remove() end

	local sw, sh = ScrW(), ScrH()
	local pad     = math.Round(sw * 0.07)
	local colGap  = 16
	local colW    = (sw - pad * 2 - colGap) / 2

	local frame = vgui.Create("DFrame")
	frame:SetTitle("")
	frame:SetSize(sw, sh)
	frame:Center()
	frame:MakePopup()
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:SetKeyboardInputEnabled(true)

	frame.Paint = function(s, w, h)
		Derma_DrawBackgroundBlur(s, 0)
		surface.SetDrawColor(COLOR_DARK)
		surface.DrawRect(0, 0, w, h)
		draw.SimpleText("EXTREME FOOTBALL THROWDOWN", "EFTHelpTitle",
			w / 2, 44, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		surface.SetDrawColor(COLOR_DIVIDER)
		surface.DrawRect(pad, 76, w - pad * 2, 1)
	end

	-- ESC is intercepted by GMod before VGUI receives it; detect the game menu
	-- opening and close ourselves (and dismiss the menu) so ESC feels correct.
	frame.Think = function(s)
		if gui.IsGameUIVisible() then
			gui.HideGameUI()
			s:Close()
		end
	end

	frame.OnKeyCodePressed = function(s, key)
		if key == KEY_F1 then
			s:Close()
			return true
		end
	end

	self.HelpFrame = frame

	-- ── WIP NOTICE ──────────────────────────────────────────────────────────
	local noticeY = 88
	local notice = vgui.Create("DPanel", frame)
	notice:SetPos(pad, noticeY)
	notice:SetSize(sw - pad * 2, 90)
	notice.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(120, 70, 0, 160))
		surface.SetDrawColor(COLOR_ORANGE)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end

	MakeLabel(notice, 0,  8, sw - pad * 2,     32, "⚠  WORK IN PROGRESS",
		"EFTHelpWIPHead", COLOR_ORANGE, false):SetContentAlignment(5)
	MakeLabel(notice, 20, 44, sw - pad * 2 - 40, 36,
		"This gamemode is undergoing active updates and bug fixes. " ..
		"Bot behaviour will vary by map — this is being worked on.",
		"EFTHelpWIPBody", COLOR_YELLOW, true)

	-- ── COLUMNS ─────────────────────────────────────────────────────────────
	local colY   = noticeY + 90 + 20
	local colH   = sh - colY - 50

	-- LEFT: Controls
	local ctrlPanel = vgui.Create("DPanel", frame)
	ctrlPanel:SetPos(pad, colY)
	ctrlPanel:SetSize(colW, colH)
	ctrlPanel.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_PANEL)
	end

	local controls = {
		{ header = "CONTROLS" },
		{ key = "W / A / S / D",            action = "Move"                          },
		{ key = "SPACE",                     action = "Jump"                          },
		{ sep = true },
		{ key = "LEFT CLICK",                action = "Punch"                         },
		{ key = "RIGHT CLICK",               action = "Throw  (hold = charge)"        },
		{ key = "MOUSE  (while throwing)",   action = "Aim angle"                     },
		{ sep = true },
		{ key = "F1",                        action = "This screen"                   },
		{ key = "F2",                        action = "Team select"                   },
		{ key = "TAB",                       action = "Scoreboard"                    },
	}

	local lineH  = 34
	local sepH   = 12
	local innerW = colW - 32
	local cy = 16
	for _, row in ipairs(controls) do
		if row.header then
			MakeLabel(ctrlPanel, 0, cy, colW, lineH, row.header,
				"EFTHelpSection", COLOR_ORANGE, false):SetContentAlignment(5)
			cy = cy + lineH + 4
			-- underline
			local ul = vgui.Create("DPanel", ctrlPanel)
			ul:SetPos(16, cy); ul:SetSize(colW - 32, 1)
			ul.Paint = function(s, w, h) surface.SetDrawColor(COLOR_DIVIDER) surface.DrawRect(0,0,w,h) end
			cy = cy + 8
		elseif row.sep then
			cy = cy + sepH
		else
			local lbl = MakeLabel(ctrlPanel, 16, cy, innerW, lineH,
				row.key .. "   —   " .. row.action, "EFTHelpBody", COLOR_DIM, false)
			cy = cy + lineH
		end
	end

	-- RIGHT: How to Play
	local rulesPanel = vgui.Create("DPanel", frame)
	rulesPanel:SetPos(pad + colW + colGap, colY)
	rulesPanel:SetSize(colW, colH)
	rulesPanel.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_PANEL)
	end

	local rules = {
		{ header = "HOW TO PLAY" },
		{ text = "Get the ball into the enemy goal to score." },
		{ text = "Carry the ball or throw it to teammates downfield." },
		{ text = "Punch opponents to knock them down and force a fumble." },
		{ text = "A knocked-down carrier drops the ball — either team can grab it." },
		{ text = "The ball resets to centre after each goal." },
		{ text = "First team to the score limit wins." },
		{ sep = true },
		{ header = "KNOWN ISSUES" },
		{ text = "Bots may struggle on maps without a nav mesh." },
		{ text = "Run nav_generate in-game (sandbox mode works) to fix bot pathing." },
	}

	local ry = 16
	local rInnerW = colW - 32
	for _, row in ipairs(rules) do
		if row.header then
			MakeLabel(rulesPanel, 0, ry, colW, lineH, row.header,
				"EFTHelpSection", COLOR_ORANGE, false):SetContentAlignment(5)
			ry = ry + lineH + 4
			local ul = vgui.Create("DPanel", rulesPanel)
			ul:SetPos(16, ry); ul:SetSize(colW - 32, 1)
			ul.Paint = function(s, w, h) surface.SetDrawColor(COLOR_DIVIDER) surface.DrawRect(0,0,w,h) end
			ry = ry + 8
		elseif row.sep then
			ry = ry + sepH + 4
		else
			local lbl = MakeLabel(rulesPanel, 16, ry, rInnerW, lineH * 2,
				"• " .. row.text, "EFTHelpBody", COLOR_DIM, true)
			ry = ry + lineH + 10
		end
	end

	-- ── CLOSE HINT ──────────────────────────────────────────────────────────
	MakeLabel(frame, 0, sh - 32, sw, 24, "Press F1 or ESC to close",
		"EFTHelpHint", COLOR_DIM, false):SetContentAlignment(5)
end
