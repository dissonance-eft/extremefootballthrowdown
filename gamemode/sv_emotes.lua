/// MANIFEST LINKS:
/// Principles: P-080 (Readability - Audio), P-100 (Hype)
-- sv_emotes.lua
-- Handles chat commands to play sound emotes

EmoteSounds = {
	["adultvirgin"] = "adultvirgin.ogg",
	["aightbet"] = "aightbet.ogg",
	["aightbet2"] = "aightbet2.ogg",
	["allahackbar"] = "allahackbar.ogg",
	["ayaya"] = "ayaya.ogg",
	["bigbraintime"] = "bigbraintime.ogg",
	["bleaugh"] = "bleaugh.ogg",
	["brostraightup"] = "brostraightup.ogg",
	["dsplaugh"] = "dsplaugh.ogg",
	["eahhh"] = "eahhh.ogg",
	["fuckyou"] = "fuckyou!.ogg",
	["getdahwatah"] = "getdahwatah.ogg",
	["gotchabitch"] = "gotchabitch.ogg",
	["goteem"] = "goteem.ogg",
	["hahashutup"] = "hahashutup.ogg",
	["happymeal"] = "happymeal.ogg",
	["honk"] = "honk.ogg",
	["icanfly"] = "icanfly.ogg",
	["interiorcrocodile"] = "interiorcrocodile.ogg",
	["jjonahlaugh"] = "jjonahlaugh.ogg",
	["kawhilaugh"] = "kawhilaugh.ogg",
	["letmein"] = "letmein.ogg",
	["lottadamage"] = "lottadamage.ogg",
	["marioscream"] = "marioscream.ogg",
	["nani"] = "nani.ogg",
	["nemomine"] = "nemomine.ogg",
	["ohyesdaddy"] = "ohyesdaddy.ogg",
	["oof"] = "oof.ogg",
	["panpakapan"] = "panpakapan.ogg",
	["pickedwronghouse"] = "pickedwronghouse.ogg",
	["pufferfish"] = "pufferfish.ogg",
	["quack"] = "quack.ogg",
	["rdjrscream"] = "rdjrscream.ogg",
	["resettheball"] = "resettheball.ogg",
	["shannonlaugh"] = "shannonlaugh.ogg",
	["smellbeef"] = "smellbeef.ogg",
	["smoovehaha"] = "smoovehaha.ogg",
	["smoovesplash"] = "smoovesplash.ogg",
	["stahp"] = "stahp.ogg",
	["stephenbullshit"] = "stephenbullshit.ogg",
	["stephentickmeoff"] = "stephentickmeoff.ogg",
	["stopit"] = "stopit.ogg",
	["stupidbitch"] = "stupidbitch.ogg",
	["surferbaaa"] = "surferbaaa.ogg",
	["thisistorture"] = "thisistorture.ogg",
	["tophead"] = "tophead.ogg",
	["whatchasay"] = "whatchasay.ogg",
	["whatspoppin"] = "whatspoppin.ogg",
	["whattheschnitzel"] = "whattheschnitzel.ogg",
	["whenwillyoulearn"] = "whenwillyoulearn.ogg",
	["whyrunning"] = "whyrunning.ogg",
	["whyyoualwayslyin"] = "whyyoualwayslyin.ogg",
	["xpshutdown"] = "xpshutdown.ogg",
	["xpstartup"] = "xpstartup.ogg",
	["yeahboi"] = "yeahboi.ogg",
	["yeet"] = "yeet.ogg",
	["yodel"] = "yodel.ogg",
	["youeatallmybeans"] = "youeatallmybeans.ogg",
	["yourenotmydad"] = "yourenotmydad.ogg",
	["yourethebest"] = "yourethebest.ogg",

	-- NoxiousNet legacy emotes (sound/speach/)
	["ael"] = "speach/ael.ogg",
	["almostharvestingseason"] = "speach/almostharvestingseason.ogg",
	["awthatstoobad"] = "speach/awthatstoobad.ogg",
	["bikehorn"] = "speach/bikehorn.ogg",
	["breakyourlegs"] = "speach/breakyourlegs.ogg",
	["cheesybakedpotato"] = "speach/cheesybakedpotato.ogg",
	["drinkfromyourskull"] = "speach/drinkfromyourskull.ogg",
	["feeltoburn"] = "speach/feeltoburn.ogg",
	["femfarquaad"] = "speach/female_farquadd.ogg",
	["gabegaben"] = "speach/gabe_gaben.ogg",
	["gabethanks"] = "speach/gabe_thanks.ogg",
	["gabewtw"] = "speach/gabe_wtw.ogg",
	["gank"] = "speach/gank.ogg",
	["givemethebutter"] = "speach/givemethebutter.ogg",
	["gogalo"] = "speach/gogalo.ogg",
	["greatatyourjunes"] = "speach/greatatyourjunes.ogg",
	["imthecoolest"] = "speach/imthecoolest.ogg",
	["imthegreatest"] = "speach/imthegreatest.ogg",
	["killthemall"] = "speach/killthemall.ogg",
	["laff1"] = "speach/laff1.ogg",
	["laff2"] = "speach/laff2.ogg",
	["laff3"] = "speach/laff3.ogg",
	["laff4"] = "speach/laff4.ogg",
	["laff5"] = "speach/laff5.ogg",
	["lag2"] = "speach/lag2.ogg",
	["lesstalkmoreraid"] = "speach/lesstalkmoreraid.ogg",
	["luigiimhome"] = "speach/luigiimhome.ogg",
	["malefarquaad"] = "speach/male_farquadd.ogg",
	["noidontwantthat"] = "speach/noidontwantthat.ogg",
	["obeyyourthirst"] = "speach/obeyyourthirst2.ogg",
	["obeyyourthirstsync"] = "speach/obeyyourthirstsync.ogg",
	["oldesttrick"] = "speach/oldesttrickinthebook.ogg",
	["sanic1"] = "speach/sanic1.ogg",
	["sanic2"] = "speach/sanic2.ogg",
	["sanic3"] = "speach/sanic3.ogg",
	["sanic4"] = "speach/sanic4.ogg",
	["shazbot"] = "speach/shazbot.ogg",
	["smokedyourbutt"] = "speach/smokedyourbutt.ogg",
	["taunt04"] = "speach/taunt_04.ogg",
	["thanksgivingblowout"] = "speach/thanksgivingblowout.ogg",
	["wttsuom"] = "speach/wttsuom.ogg",
	["youbastards"] = "speach/youbastards.ogg",
	["youbrokemygrill"] = "speach/youbrokemygrill.ogg"
}

-- Passthrough emotes: play a sound but let the chat text show (natural words/phrases)
local EmotePassthrough = {
    ["thanks"] = "speach/gabe_thanks.ogg",
}

-- Cooldown to prevent spam
local EmoteGenericCooldown = 2.0
local PlayerCooldowns = {}

-- Clean up cooldowns when player disconnects to prevent memory leak
hook.Add("PlayerDisconnected", "EFTEmoteCleanup", function(ply)
	PlayerCooldowns[ply] = nil
end)

hook.Add("PlayerSay", "EFTEmoteChat", function(ply, text, team)
	local cleanText = string.lower(string.Trim(text))

	-- Passthrough emotes: play sound but keep text visible in chat
	local passthroughSound = EmotePassthrough[cleanText]
	if passthroughSound then
		if not (PlayerCooldowns[ply] and CurTime() < PlayerCooldowns[ply]) then
			ply:EmitSound(passthroughSound, 75, 100, 1, CHAN_VOICE)
			PlayerCooldowns[ply] = CurTime() + EmoteGenericCooldown
		end
		return  -- no return value = text shows normally in chat
	end

	-- Standard emotes: play sound and hide trigger text
	local soundFile = EmoteSounds[cleanText]
	if soundFile then
		if PlayerCooldowns[ply] and CurTime() < PlayerCooldowns[ply] then
			return ""  -- still on cooldown: hide text, no sound
		end
		ply:EmitSound(soundFile, 75, 100, 1, CHAN_VOICE)
		PlayerCooldowns[ply] = CurTime() + EmoteGenericCooldown
		return ""
	end
end)
