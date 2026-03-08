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
	-- Columns: narrow Controls | wide How to Play | narrow Emotes
	-- Middle gets ~45% so rules have breathing room; sides split the rest equally.
	local colY    = noticeY + 90 + 20
	local colH    = sh - colY - 50
	local totalW  = sw - pad * 2
	local colMidW = math.floor(totalW * 0.45)
	local colSideW = math.floor((totalW - colMidW - colGap * 2) / 2)

	-- LEFT: Controls
	local ctrlPanel = vgui.Create("DPanel", frame)
	ctrlPanel:SetPos(pad, colY)
	ctrlPanel:SetSize(colSideW, colH)
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
	local innerW = colSideW - 32
	local cy = 16
	for _, row in ipairs(controls) do
		if row.header then
			MakeLabel(ctrlPanel, 0, cy, colSideW, lineH, row.header,
				"EFTHelpSection", COLOR_ORANGE, false):SetContentAlignment(5)
			cy = cy + lineH + 4
			local ul = vgui.Create("DPanel", ctrlPanel)
			ul:SetPos(16, cy); ul:SetSize(colSideW - 32, 1)
			ul.Paint = function(s, w, h) surface.SetDrawColor(COLOR_DIVIDER) surface.DrawRect(0,0,w,h) end
			cy = cy + 8
		elseif row.sep then
			cy = cy + sepH
		else
			MakeLabel(ctrlPanel, 16, cy, innerW, lineH,
				row.key .. "   —   " .. row.action, "EFTHelpBody", COLOR_DIM, false)
			cy = cy + lineH
		end
	end

	-- MIDDLE: How to Play (wider — rules need room to breathe)
	local rulesPanel = vgui.Create("DPanel", frame)
	rulesPanel:SetPos(pad + colSideW + colGap, colY)
	rulesPanel:SetSize(colMidW, colH)
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
	}

	local ry = 16
	local rInnerW = colMidW - 32
	for _, row in ipairs(rules) do
		if row.header then
			MakeLabel(rulesPanel, 0, ry, colMidW, lineH, row.header,
				"EFTHelpSection", COLOR_ORANGE, false):SetContentAlignment(5)
			ry = ry + lineH + 4
			local ul = vgui.Create("DPanel", rulesPanel)
			ul:SetPos(16, ry); ul:SetSize(colMidW - 32, 1)
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

	-- RIGHT: Emotes (scrollable vertical list)
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
	emotePanel:SetPos(pad + colSideW + colGap + colMidW + colGap, colY)
	emotePanel:SetSize(colSideW, colH)
	emotePanel.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_PANEL)
	end

	MakeLabel(emotePanel, 0, 8, colSideW, lineH, "EMOTES",
		"EFTHelpSection", COLOR_ORANGE, false):SetContentAlignment(5)
	local eHeaderY = lineH + 4
	local ul2 = vgui.Create("DPanel", emotePanel)
	ul2:SetPos(16, eHeaderY); ul2:SetSize(colSideW - 32, 1)
	ul2.Paint = function(s, w, h) surface.SetDrawColor(COLOR_DIVIDER) surface.DrawRect(0,0,w,h) end

	MakeLabel(emotePanel, 0, eHeaderY + 6, colSideW, 22,
		"type in chat to play  (text is hidden)",
		"EFTHelpWIPBody", COLOR_DIM, false):SetContentAlignment(5)

	local scroll = vgui.Create("DScrollPanel", emotePanel)
	local scrollY = eHeaderY + 32
	scroll:SetPos(10, scrollY)
	scroll:SetSize(colSideW - 20, colH - scrollY - 10)

	local canvas = scroll:GetCanvas()
	local entryH = 28
	for i, name in ipairs(emoteNames) do
		local lbl = vgui.Create("DLabel", canvas)
		lbl:SetFont("EFTHelpWIPBody")
		lbl:SetText(name)
		lbl:SetColor(COLOR_DIM)
		lbl:SetPos(12, (i - 1) * entryH)
		lbl:SetSize(colSideW - 40, entryH)
	end
	canvas:SetTall(#emoteNames * entryH + 4)

	-- ── CLOSE HINT ──────────────────────────────────────────────────────────
	MakeLabel(frame, 0, sh - 32, sw, 24, "Press F1 or ESC to close",
		"EFTHelpHint", COLOR_DIM, false):SetContentAlignment(5)
end
