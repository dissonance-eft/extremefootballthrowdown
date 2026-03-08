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
	local emoteH = 150
	local colH   = sh - colY - 50 - emoteH - 12

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
		{ text = "Touch the ball to pick it up — possession is automatic, no button needed." },
		{ text = "Carry or throw the ball into the enemy goal to score." },
		{ text = "Tackle by running into opponents at speed — this knocks them down and strips the ball." },
		{ text = "Momentum and staying upright are everything. Build speed before engaging." },
		{ text = "The ball is always live after a fumble — anyone can grab it instantly." },
		{ text = "Passing leaves you standing still and exposed. Use it when you have space." },
		{ text = "First to 10 goals wins, or highest score after 15 minutes." },
		{ sep = true },
		{ header = "KNOWN ISSUES" },
		{ text = "Bots currently have navigation issues on some maps — this is being fixed." },
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

	-- ── EMOTES ──────────────────────────────────────────────────────────────
	-- Type any trigger word in chat to play the sound (hidden from chat log).
	local emoteNames = {
		"adultvirgin","aightbet","aightbet2","allahackbar","ayaya","bigbraintime",
		"bleaugh","brostraightup","dsplaugh","eahhh","fuckyou","getdahwatah",
		"gotchabitch","goteem","hahashutup","happymeal","honk","icanfly",
		"interiorcrocodile","jjonahlaugh","kawhilaugh","letmein","lottadamage",
		"marioscream","nani","nemomine","ohyesdaddy","oof","panpakapan",
		"pickedwronghouse","pufferfish","quack","rdjrscream","resettheball",
		"shannonlaugh","smellbeef","smoovehaha","smoovesplash","stahp",
		"stephenbullshit","stephentickmeoff","stopit","stupidbitch","surferbaaa",
		"thisistorture","tophead","whatchasay","whatspoppin","whattheschnitzel",
		"whenwillyoulearn","whyrunning","whyyoualwayslyin","xpshutdown","xpstartup",
		"yeahboi","yeet","yodel","youeatallmybeans","yourenotmydad","yourethebest",
		-- NoxiousNet legacy
		"ael","almostharvestingseason","awthatstoobad","bikehorn","breakyourlegs",
		"cheesybakedpotato","drinkfromyourskull","feeltoburn","femfarquaad",
		"gabegaben","gabethanks","gabewtw","gank","givemethebutter","gogalo",
		"greatatyourjunes","imthecoolest","imthegreatest","killthemall",
		"laff1","laff2","laff3","laff4","laff5","lag2","lesstalkmoreraid",
		"luigiimhome","malefarquaad","noidontwantthat","obeyyourthirst",
		"obeyyourthirstsync","oldesttrick","sanic1","sanic2","sanic3","sanic4",
		"shazbot","smokedyourbutt","taunt04","thanksgivingblowout","wttsuom",
		"youbastards","youbrokemygrill",
		-- Passthrough (shows in chat + plays sound)
		"thanks",
	}
	table.sort(emoteNames)

	local emotePanel = vgui.Create("DPanel", frame)
	emotePanel:SetPos(pad, colY + colH + 12)
	emotePanel:SetSize(sw - pad * 2, emoteH)
	emotePanel.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_PANEL)
	end

	MakeLabel(emotePanel, 0, 8, sw - pad * 2, 28,
		"EMOTES  —  type trigger word in chat to play (text is hidden)",
		"EFTHelpSection", COLOR_ORANGE, false):SetContentAlignment(5)

	local scroll = vgui.Create("DScrollPanel", emotePanel)
	scroll:SetPos(10, 42)
	scroll:SetSize(sw - pad * 2 - 20, emoteH - 52)

	local canvas = scroll:GetCanvas()
	local chipFont = "EFTHelpWIPBody"
	local chipPadX, chipPadY = 8, 4
	local chipH = 26
	local cx, cy = 0, 0
	local rowH = chipH + chipPadY

	for _, name in ipairs(emoteNames) do
		local chip = vgui.Create("DLabel", canvas)
		chip:SetFont(chipFont)
		chip:SetText(name)
		chip:SizeToContents()
		local cw = chip:GetWide() + chipPadX * 2

		if cx + cw > (sw - pad * 2 - 20) and cx > 0 then
			cx = 0
			cy = cy + rowH
		end

		chip:SetPos(cx + chipPadX, cy + chipPadY / 2)
		chip:SetSize(chip:GetWide(), chipH)
		chip:SetColor(COLOR_DIM)
		cx = cx + cw + 6
	end

	canvas:SetTall(cy + rowH + 4)

	-- ── CLOSE HINT ──────────────────────────────────────────────────────────
	MakeLabel(frame, 0, sh - 32, sw, 24, "Press F1 or ESC to close",
		"EFTHelpHint", COLOR_DIM, false):SetContentAlignment(5)
end
