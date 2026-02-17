/// MANIFEST LINKS:
/// Principles: P-080 (Readability - Audio), P-100 (Hype)
-- sv_emotes.lua
-- Handles chat commands to play sound emotes

local EmoteSounds = {
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
	["yourethebest"] = "yourethebest.ogg"
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
	
	-- Check for match
	local soundFile = EmoteSounds[cleanText]
	if soundFile then
		-- Check cooldown
		if PlayerCooldowns[ply] and CurTime() < PlayerCooldowns[ply] then
			return "" -- Still hide the text, but no sound
		end
		
		-- Play sound at player's location
		ply:EmitSound(soundFile, 75, 100, 1, CHAN_VOICE)
		
		-- Set cooldown
		PlayerCooldowns[ply] = CurTime() + EmoteGenericCooldown
		
		-- Hide the trigger text from chat
		return "" 
	end
end)
