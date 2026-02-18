AddCSLuaFile("cl_init.lua")
/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity), C-001 (Continuous Contest)
AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_globals.lua")
AddCSLuaFile("cl_obj_entity_extend.lua")
AddCSLuaFile("cl_obj_player_extend.lua")
AddCSLuaFile("cl_manifest_data.lua")
AddCSLuaFile("cl_manifest_debug.lua")
AddCSLuaFile("sh_obj_entity_extend.lua")
AddCSLuaFile("sh_obj_player_extend.lua")
AddCSLuaFile("sh_states.lua")
AddCSLuaFile("sh_voice.lua")
AddCSLuaFile("sh_translate.lua")
AddCSLuaFile("sh_animations.lua")
AddCSLuaFile("cl_postprocess.lua")
AddCSLuaFile("cl_draw.lua")
AddCSLuaFile("cl_selectscreen.lua")
AddCSLuaFile("cl_help.lua")
AddCSLuaFile("cl_splashscreen.lua")
AddCSLuaFile("vgui/dex3dnotification.lua")

-- Fretta Content (Client/Shared)
AddCSLuaFile("player_class.lua")
AddCSLuaFile("player_extension.lua")
AddCSLuaFile("class_default.lua")
AddCSLuaFile("player_colours.lua")
AddCSLuaFile("skin.lua")
AddCSLuaFile("cl_gmchanger.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_deathnotice.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_notify.lua")
AddCSLuaFile("vgui/vgui_hudlayout.lua")
AddCSLuaFile("vgui/vgui_hudelement.lua")
AddCSLuaFile("vgui/vgui_hudbase.lua")
AddCSLuaFile("vgui/vgui_hudcommon.lua")
AddCSLuaFile("vgui/vgui_vote.lua")
AddCSLuaFile("vgui/vgui_gamenotice.lua")

AddCSLuaFile("lib/promise.lua")
AddCSLuaFile("lib/class.lua")
AddCSLuaFile("lib/event.lua")
AddCSLuaFile("obj_viewmodel_hud.lua")
AddCSLuaFile("obj_network.lua")
AddCSLuaFile("obj_player.lua")
AddCSLuaFile("obj_ball.lua")
AddCSLuaFile("obj_gamemanager.lua")
AddCSLuaFile("cl_mapvote.lua")

include("sh_globals.lua")
include("shared.lua")

include("sv_obj_player_extend.lua")
include("round_controller.lua")
include("sv_spectator.lua")
include("sv_gmchanger.lua")
include("sv_mapvote.lua")
include("utility.lua")
include("sv_emotes.lua")
include("server/sv_match_recorder.lua") -- Enable Match Recording
include("lib/promise.lua")
include("lib/class.lua")
include("lib/event.lua")
include("obj_bot.lua") -- Define Bot class BEFORE sv_bots.lua uses it!
include("sv_bot_pathfinding.lua")
include("sv_bots.lua") 
include("obj_ball.lua")
include("obj_player.lua")
include("obj_network.lua")
include("obj_gamemanager.lua")
include("sv_security.lua")

function GM:Think()
	GAMEMANAGER:Think()

	self:Base_Think() -- Merged Fretta Think

	for _, pl in pairs(player.GetAll()) do
		if pl:Alive() and pl:GetObserverMode() == OBS_MODE_NONE then
			-- Health regen is now owned by PlayerController
			if pl.Controller then pl.Controller:ThinkHealthRegen() end

			pl:ThinkSelf()
		end
	end
end

function GM:CanEndRoundBasedGame()
	return true
end

function GM:OnEndOfGame(bGamemodeVote)
	for k,v in pairs(player.GetAll()) do
		if v:ShouldBeFrozen() then
			v:Freeze(true)
		end
	end

	GlobalNetwork:Start("eft_endofgame")
		GlobalNetwork:WriteUInt(team.GetScore(TEAM_RED) > team.GetScore(TEAM_BLUE) and TEAM_RED or team.GetScore(TEAM_BLUE) > team.GetScore(TEAM_RED) and TEAM_BLUE or 0, 8)
	GlobalNetwork:Broadcast()
end

-- GM:PreRoundStart moved to GameManager delegation in round_controller.lua

-- Overtime state is now owned by GameManager (single writer for "overtime" global)
function GM:SetOvertime(ot)
	GAMEMANAGER:SetOvertime(ot)
end
GM.SetOverTime = GM.SetOvertime

-- Debug command to force overtime for testing
concommand.Add("eft_force_overtime", function(ply, cmd, args)
	-- Only allow in singleplayer or from server console, or if player is superadmin
	if IsValid(ply) and not ply:IsSuperAdmin() then
		ply:ChatPrint("You must be a superadmin to use this command.")
		return
	end
	
	-- Directly trigger overtime
	GAMEMODE:SetOvertime(true)
	
	if IsValid(ply) then
		ply:ChatPrint("[DEBUG] Overtime triggered!")
	end
	print("[DEBUG] eft_force_overtime: Overtime triggered")
end, nil, "Debug: Force overtime state immediately")

function GM:ReturnBall()
	local ball = self:GetBall()
	if not ball or not ball:IsValid() then return end

	ball:SetPos(self:GetBallHome())
end

function GM:PlayerReady(pl)
end

concommand.Add("initpostentity", function(sender, command, arguments)
	if not sender.DidInitPostEntity then
		sender.DidInitPostEntity = true

		gamemode.Call("PlayerReady", sender)
	end
end)

-- Score-limit check is now owned by GameManager (single writer for game-end logic)
function GM:HasReachedRoundLimit(iNum)
	return GAMEMANAGER:HasReachedRoundLimit(iNum)
end

-- InRound state is now owned by GameManager (single writer for "InRound" global)
function GM:SetInRound(b)
	GAMEMANAGER:SetInRound(b)
end

function GM:AllowPlayerPickup(pl, ent)
	return false
end

function GM:IsSpawnpointSuitable(pl, spawnpointent, bMakeSuitable)
	if bMakeSuitable then
		if pl:Team() == TEAM_SPECTATOR or pl:Team() == TEAM_UNASSIGNED then return true end

		local Pos = spawnpointent:GetPos()
		for k, v in pairs(ents.FindInBox(Pos + Vector(-16, -16, 0), Pos + Vector(16, 16, 72))) do
			if v:IsPlayer() and v:Alive() then
				return false
			end
		end
	end

	return true
end

function GM:PlayerSelectSpawn(pl)
    local teamid = pl:Team()
    local spawns = {}

    -- Select appropriate spawn classes based on team
    if teamid == TEAM_RED then
        table.Add(spawns, ents.FindByClass("info_player_terrorist"))
        table.Add(spawns, ents.FindByClass("info_player_rebel"))
        table.Add(spawns, ents.FindByClass("info_player_red"))
    elseif teamid == TEAM_BLUE then
        table.Add(spawns, ents.FindByClass("info_player_counterterrorist"))
        table.Add(spawns, ents.FindByClass("info_player_combine"))
        table.Add(spawns, ents.FindByClass("info_player_blue"))
    else
        table.Add(spawns, ents.FindByClass("info_player_deathmatch"))
        table.Add(spawns, ents.FindByClass("info_player_start"))
    end

    -- Fallback: if no team spawns found, try generic ones (or opposing ones if map is weird)
    if #spawns == 0 then
        table.Add(spawns, ents.FindByClass("info_player_terrorist"))
        table.Add(spawns, ents.FindByClass("info_player_counterterrorist"))
        table.Add(spawns, ents.FindByClass("info_player_deathmatch"))
        table.Add(spawns, ents.FindByClass("info_player_start"))
    end
	
	local validSpawns = {}
	for _, ent in pairs(spawns) do
        -- Use our extended IsSpawnpointSuitable (bMakeSuitable=true)
        -- We explicitly ignore the player themselves in the check to avoid self-blocking (though unlikely if dead)
		if self:IsSpawnpointSuitable(pl, ent, true) then
			table.insert(validSpawns, ent)
		end
	end

	-- Pick random valid spawn, or fallback to any spawn
	if #validSpawns > 0 then
		return validSpawns[math.random(#validSpawns)]
	end
    
    if #spawns > 0 then
	    return spawns[math.random(#spawns)]
    end
    
    return nil
end




function GM:CanPlayerSuicide(pl)
	-- Anti-Grief: Disable suicide during pre-round
	-- Strictly disable suicide if not in active round
	if not GetGlobalBool("InRound", false) then return false end

	if self.TieBreaker then
		if pl:Alive() and pl:GetState() == STATE_FIGHTER2D and pl:GetStateInteger() ~= STATE_FIGHTER2D_LOSE then
			pl:SetStateInteger(STATE_FIGHTER2D_LOSE)
			pl:SetHealth(1)
			pl:SetStateFloat(CurTime())
		end

		return false
	end

	local ball = self:GetBall()
	if ball:IsValid() and ball:GetCarrier() == pl then
		return false
	end

	if pl:CallStateFunction("NoSuicide") then return false end

	return self:Base_CanPlayerSuicide(pl) -- Merged Fretta
end

function GM:OnRoundResult(result, resulttext)
	-- Score is already added in TeamScored, don't add it again here
	-- team.AddScore(result, 1)  -- REMOVED: Caused double scoring
end

function GM:PlayerSpawn(pl)
	self:Base_PlayerSpawn(pl) -- Merged Fretta

	-- Spawn logic is now owned by PlayerController
	if pl.Controller then pl.Controller:OnSpawn() end

    -- S4 Audio Overhaul: Player Respawn Sound
    -- Only play if the round is active (don't spam on initial connect)
    if self:InRound() and not self:IsWarmUp() then
        local soundPath = "eft/announcer/player_respawn.wav"
        net.Start("eft_localsound")
            net.WriteString(soundPath)
            net.WriteFloat(100) -- Pitch
            net.WriteFloat(1.0) -- Volume
        net.Send(pl)
    end
end

-- Tiebreaker logic is now owned by GameManager
function GM:SetupTieBreaker() GAMEMANAGER:SetupTieBreaker() end
function GM:EndTieBreaker(winnerteamid) GAMEMANAGER:EndTieBreaker(winnerteamid) end

function GM:OnRoundStart(num)
	for _, pl in pairs(player.GetAll()) do
		if pl:GetState() == STATE_PREROUND then
			pl:EndState()
		end
	end

	self.NoFlex = false
end

function GM:PlayerSetModel(pl)
end

function GM:PlayerHurt(victim, attacker, healthremaining, damage)
	-- Damage tracking is now owned by PlayerController
	if victim.Controller then victim.Controller:OnHurt(attacker, healthremaining, damage) end

	self.BaseClass.PlayerHurt(self, victim, attacker, healthremaining, damage) -- GMod Base
end

function GM:PlayerDeath(victim, inflictor, attacker)
	-- Skip death notice for spectators/unassigned
	if victim:Team() == TEAM_SPECTATOR or victim:Team() == TEAM_UNASSIGNED then
		return
	end

    -- Bot Suicide Suppression (User Request)
    -- If a bot dies by suicide/world (inflictor is self or world), do not broadcast death notice
    if victim:IsBot() and (victim == attacker or not IsValid(attacker)) then
		-- Manually handle death housekeeping if needed, or just let DoPlayerDeath handle it
		-- If we skip BaseClass.PlayerDeath, we skip the print and the Net message.
		-- We SHOULD ensure DoPlayerDeath logic (if any) is preserved.
		-- But BaseClass.PlayerDeath mostly just prints.
		victim.NextSpawnTime = CurTime() + 2
		victim.DeathTime = CurTime()
		return -- Skip base call
    end
	
	if attacker == victim or not attacker:IsValid() or not attacker:IsPlayer() then
		local lastattacker = victim:GetLastAttacker()
		if lastattacker and lastattacker:IsValid() and lastattacker:IsPlayer() and lastattacker:Team() ~= victim:Team() then
			inflictor = attacker
			attacker = lastattacker
		end
	end

	self.BaseClass.PlayerDeath(self, victim, inflictor, attacker) -- GMod Base

    -- S4 Audio Overhaul: Player Death Sound
    local soundPath = "eft/announcer/player_dead.wav"
    net.Start("eft_localsound")
        net.WriteString(soundPath)
        net.WriteFloat(100) -- Pitch
        net.WriteFloat(1.0) -- Volume
    net.Send(victim)
end

function GM:DoPlayerDeath(pl, attacker, dmginfo)
	-- Death handling is now owned by PlayerController
	if pl.Controller then pl.Controller:OnKilled(attacker, dmginfo) end
end

function GM:OnDoPlayerDeath(pl, attacker, dmginfo)
end

function GM:PlayerDeathSound()
	return true
end

local alltalk = cvars.Bool 'sv_alltalk'
cvars.RemoveChangeCallback('sv_alltalk', 'eft')
cvars.AddChangeCallback('sv_alltalk', function(cvar, old, new) alltalk = tobool(new) end, 'eft')

function GM:PlayerCanHearPlayersVoice(listener, talker)
    return alltalk or self.TieBreaker or not self:InRound() or listener:Team() == TEAM_SPECTATOR or listener:Team() == TEAM_UNASSIGNED or listener:Team() == talker:Team(), false
end

function GM:SpawnRandomWeaponAtSpawn(class, teamid, silent)
	local spawn = table.Random(team.GetSpawnPoints(teamid))
	if not spawn then return end

	local ent = ents.Create(class)
	if ent:IsValid() then
		ent:SetPos(spawn:GetPos() + Vector(0, 0, 8))
		ent:Spawn()

		if not silent then
			local effectdata = EffectData()
				effectdata:SetOrigin(ent:LocalToWorld(ent:OBBCenter()))
			util.Effect("ballreset", effectdata, true, true)
		end
	end
end

function GM:SpawnRandomWeapon(silent)
	if self.VeryCompetitive or #ents.FindByClass("logic_norandomweapons") > 0 or self.TieBreaker then return end

	local weps = self:GetWeapons()
	if #weps == 0 then return end

	local overtime = self:IsOverTime()

	local maxrandom = 0
	local randpick = {}
	for _, wepclass in pairs(weps) do
		local tab = scripted_ents.GetStored(wepclass)
		if tab then
			if (not overtime or tab.t.AllowDuringOverTime) and (not self.Competitive or tab.t.AllowInCompetitive) then
				local currently_in_play = #ents.FindByClass(wepclass)
				local max_in_play = tab.t.MaxActiveSets
				if max_in_play == nil or currently_in_play < max_in_play * 2 then
					local chance = tab.t.DropChance or 1
					randpick[wepclass] = {maxrandom, maxrandom + chance}
					maxrandom = maxrandom + chance
				end
			end
		end
	end

	local rand = math.Rand(0, maxrandom)
	local class

	for wepclass, v in pairs(randpick) do
		if rand >= v[1] and rand <= v[2] then
			class = wepclass
			break
		end
	end

	if class then
		self:SpawnRandomWeaponAtSpawn(class, TEAM_RED, silent)
		self:SpawnRandomWeaponAtSpawn(class, TEAM_BLUE, silent)
	end
end

function GM:EntityTakeDamage(ent, dmginfo)
	if ent:IsPlayer() then
		if ent:CallStateFunction("EntityTakeDamage", dmginfo) then return end

		if dmginfo:IsExplosionDamage() then
			local attacker = dmginfo:GetAttacker()
			if attacker:IsValid() and attacker:IsPlayer() and attacker:Team() == ent:Team() and ent ~= attacker then
				dmginfo:SetDamage(0)
				dmginfo:ScaleDamage(0)
				return
			end

			if dmginfo:GetDamage() >= 16 then
				ent:Ignite(dmginfo:GetDamage() / 20)
				ent:ThrowFromPosition(dmginfo:GetDamagePosition(), dmginfo:GetDamage() * 10, true, attacker)
			end
		end
	end
end

function GM:OnPlayerKnockedDownBy(pl, knocker)
end

function GM:Initialize()
	util.AddNetworkString("PlayableGamemodes")
	util.AddNetworkString("RoundAddedTime")
	util.AddNetworkString("fretta_teamchange")

	timer.Simple(self.WarmUpLength, function() GAMEMODE:StartRoundBasedGame() GAMEMODE:EndWarmUp() end)

	if self.AutomaticTeamBalance then
		timer.Create("CheckTeamBalance", 30, 0, function() GAMEMODE:CheckTeamBalance() end)
	end

	resource.AddFile("materials/refract_ring.vmt")
	resource.AddFile("materials/ball_halo.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray1.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray2.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray3.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray4.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray5.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray6.vmt")
	resource.AddFile("materials/bot.png")
	resource.AddFile("materials/noxctf/sprite_bloodspray7.vmt")
	resource.AddFile("materials/noxctf/sprite_bloodspray8.vmt")
	resource.AddFile("materials/red_rhinos.vmt")
	resource.AddFile("materials/blue_bulls.vmt")
	resource.AddFile("sound/eft/ballreset.ogg")
	resource.AddFile("sound/eft/bigpole_swing.ogg")

	resource.AddFile("materials/overlays/statuscold.vmt")
    resource.AddWorkshop("2022813030")


	util.AddNetworkString("eft_localsound")
	util.AddNetworkString("eft_endofgame")
	util.AddNetworkString("eft_nearestgoal")
	util.AddNetworkString("eft_teamscored")
	util.AddNetworkString("eft_screencrack")
	util.AddNetworkString("eft_overtime")
	util.AddNetworkString("eft_centermsg")

	self:RegisterWeapons()

	self:PrecacheResources()
end

function GM:InitPostEntity()
	self.BaseClass:InitPostEntity()
	self:RecalculateGoalCenters(TEAM_RED)
	self:RecalculateGoalCenters(TEAM_BLUE)
end

function GM:EndWarmUp()
	for _, pl in pairs(player.GetAll()) do
		pl:SetDeaths(0)
		pl:SetFrags(0)
	end
end

local function gsub_randomsound(a, b) return math.random(a, b) end
function GM:LocalSound(soundfile, targets, pitch, vol)
	soundfile = string.gsub(soundfile, "%?(%d+)%|(%d+)", gsub_randomsound)

	net.Start("eft_localsound")
		net.WriteString(soundfile)
		net.WriteFloat(pitch or 100)
		net.WriteFloat(vol or 1)
	net.Send(targets or player.GetAll())
end

function GM:TeamSound(soundfile, teamid, pitch, vol)
	local targets
	if not teamid then
		targets = player.GetAll()
	elseif teamid == 0 then
		targets = team.GetPlayers(TEAM_UNASSIGNED)
		targets = table.Add(targets, team.GetPlayers(TEAM_SPECTATOR))
	else
		targets = team.GetPlayers(teamid)
	end

	self:LocalSound(soundfile, targets, pitch, vol)
end

function GM:SlowTimeEase(base, rate)
	local timescale = base or 0.1
	local timerate = rate or 0.5
	timer.Create("SlowTime", 0, 0, function()
		timescale = math.min(1, timescale + FrameTime() * timerate)
		game.SetTimeScale(timescale)
		if timescale == 1 then
			timer.Remove("SlowTime")
		end
	end)
end

function GM:SlowTime(timescale, duration)
	timescale = timescale or 0.1

	game.SetTimeScale(timescale)
	timer.Create("SlowTime", (duration or 1) * timescale, 1, function()
		game.SetTimeScale(1)
	end)
end

function GM:PlayerInitialSpawn(pl)
	self:Base_PlayerInitialSpawn(pl) -- Merged Fretta

	-- Ensure controller exists, then delegate initial spawn setup
	if not pl.Controller then pl.Controller = PlayerController(pl) end
	pl.Controller:OnInitialSpawn()
end

-- Removed duplicate OnPlayerChangedTeam definition (567) and kept the one below (618)
-- But wait, I must check if I removed functionality.
-- The deleted one called CollisionRulesChanged.
-- I will add CollisionRulesChanged to the one below.

local NextSwitchFromTeamToSpec = {}
local NumTeamJoins = {}
function GM:PlayerCanJoinTeam(ply, teamid)
	if ply:Team() == teamid then
		ply:ChatPrint( "You're already on that team" )
		return false
	end

	if ply.AutoJoiningTeam then return true end

	local TimeBetweenSwitches = GAMEMODE.Competitive and 5 or GAMEMODE.SecondsBetweenTeamSwitches or 10
	if ply.LastTeamSwitch and RealTime() - ply.LastTeamSwitch < TimeBetweenSwitches then
		ply:ChatPrint( Format( "Please wait %i more seconds before trying to change team again", (TimeBetweenSwitches - (RealTime() - ply.LastTeamSwitch)) + 1 ) )
		return false
	end

	if self.Competitive then return true end

	if team.Joinable(teamid) then
		local uid = ply:UniqueID()
		if ply:Team() == TEAM_SPECTATOR then
			if NextSwitchFromTeamToSpec[uid] and RealTime() < NextSwitchFromTeamToSpec[uid] then
				ply:ChatPrint("You have recently started spectating and cannot rejoin the match so easily. Wait "..math.ceil(ply.NextSwitchFromTeamToSpec - RealTime()).." more seconds.")
				return false
			end
		elseif ply:Team() ~= TEAM_UNASSIGNED then
			if (NumTeamJoins[uid] or 0) > 2 then
				ply:ChatPrint("You cannot swap teams anymore this match.")
				return false
			elseif GAMEMODE.AutomaticTeamBalance then
				local nummyteam = team.NumPlayers(ply:Team())
				local numotherteam = team.NumPlayers(teamid)

				if nummyteam <= numotherteam then
					ply:ChatPrint("You cannot swap teams because it would make them uneven.")
					return false
				end
			end
		end
	end

	return true
end

function GM:OnPlayerChangedTeam(pl, oldteam, newteam)
	self:Base_OnPlayerChangedTeam(pl, oldteam, newteam) -- Merged Fretta

    pl:CollisionRulesChanged() -- Restored from deleted duplicate

	if team.Joinable(newteam) then
		local uid = pl:UniqueID()

		NumTeamJoins[uid] = (NumTeamJoins[uid] or 0) + 1

		if oldteam == TEAM_SPECTATOR then
			NextSwitchFromTeamToSpec[pl:UniqueID()] = GAMEMODE.SecondsBetweenTeamSwitchesFromSpec
		end
	end
end

function GM:OnPreRoundStart(num)
	-- Round result state is cleared by GameManager:ClearRoundResult() in PreRoundStart
	-- No direct SetGlobal calls here — GameManager is single writer

	game.CleanUpMap()

	self:RecalculateGoalCenters(TEAM_RED)
	self:RecalculateGoalCenters(TEAM_BLUE)

	UTIL_StripAllPlayers()
	UTIL_SpawnAllPlayers()

	self.NoFlex = false

	game.SetTimeScale(1)
end

function BroadcastLua(lua)
	for _, pl in pairs(player.GetAll()) do
		pl:SendLua(lua)
	end
end

function GM:BroadcastAction(subject, action, teamnum)
	if type(subject) == "string" then
		if teamnum then
			BroadcastLua(string.format("GAMEMODE:AddTeamPlayerAction(%q, %q, %i)", subject, action, teamnum))
		else
			BroadcastLua(string.format("GAMEMODE:AddPlayerAction(%q, %q)", subject, action))
		end
	else
		BroadcastLua(string.format("GAMEMODE:AddPlayerAction(Entity("..subject:EntIndex().."), %q )", action))
	end
end

-- Legacy wrapper
function GM:TeamScored(teamid, hitter, points, istouch)
	if GameEvents.TeamScored then GameEvents.TeamScored:Invoke(teamid, hitter, points, istouch) end
end

-- Scoring logic is now owned by GameManager:OnTeamScored()
if GameEvents.TeamScored then
	GameEvents.TeamScored:Add(function(teamid, hitter, points, istouch)
		GAMEMANAGER:OnTeamScored(teamid, hitter, points, istouch)
	end)
end

function GM:OnTeamScored(teamid, hitter, points, istouch)
end

GM.ForceEmoteDownload = CreateConVar("eft_downloademoteaddon", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Make clients download a workshop addon containing emotes."):GetBool()
cvars.AddChangeCallback("eft_downloademoteaddon", function(cvar, oldvalue, newvalue)
	GAMEMODE.ForceEmoteDownload = tonumber(newvalue) == 1

	if GAMEMODE.ForceEmoteDownload then
		resource.AddWorkshop("2022813030")
	end
end)

-- MERGED FRETTA CODE (RENAMED TO BASE_)

GM.ReconnectedPlayers = {}

function GM:Base_Think()
	for k,v in pairs( player.GetAll() ) do
		local Class = v:GetPlayerClass()
		if ( Class ) then v:CallClassFunction( "Think" ) end
	end
	if( !GAMEMODE.IsEndOfGame && ( !GAMEMODE.RoundBased || ( GAMEMODE.RoundBased && GAMEMODE:CanEndRoundBasedGame() ) ) && CurTime() >= GAMEMODE.GetTimeLimit() ) then
		GAMEMODE:EndOfGame( true )
	end
end

function GM:Base_CanPlayerSuicide( ply )
	if( ply:Team() == TEAM_UNASSIGNED || ply:Team() == TEAM_SPECTATOR ) then
		return false 
	end
	return !GAMEMODE.NoPlayerSuicide
end 

function GM:PlayerSwitchFlashlight( ply, on ) 
	if ( ply:Team() == TEAM_SPECTATOR || ply:Team() == TEAM_UNASSIGNED || ply:Team() == TEAM_CONNECTING ) then
		return not on
	end
	return ply:CanUseFlashlight()
end

function GM:Base_PlayerInitialSpawn( pl )
	pl:SetTeam( TEAM_SPECTATOR )
	pl:SetPlayerClass( "Spectator" )
	pl.m_bFirstSpawn = true
	pl:UpdateNameColor()
	GAMEMODE:CheckPlayerReconnected( pl )
end

function GM:CheckPlayerReconnected( pl )
	if table.HasValue( GAMEMODE.ReconnectedPlayers, pl:UniqueID() ) then
		GAMEMODE:PlayerReconnected( pl )
	end
end

function GM:PlayerReconnected( pl )
end

function GM:PlayerDisconnected( pl )
	table.insert( GAMEMODE.ReconnectedPlayers, pl:UniqueID() )
end  

function GM:ShowHelp( pl )
	-- F1 now opens team select (swapped from F2)
	pl:SendLua( "GAMEMODE:ShowTeam()" )
end

function GM:ShowTeam( pl )
	-- F2 disabled, use F1 instead
end


function GM:Base_PlayerSpawn( pl ) 
	pl:UpdateNameColor()
	if ( pl.m_bFirstSpawn ) then
		pl.m_bFirstSpawn = nil
		if ( pl:IsBot() ) then
			GAMEMODE:AutoTeam( pl )
			if ( !GAMEMODE.TeamBased && !GAMEMODE.NoAutomaticSpawning ) then
				pl:Spawn()
			end
		else
			pl:StripWeapons()
			GAMEMODE:PlayerSpawnAsSpectator( pl )
			if ( #player.GetAll() > 1 ) then
				pl:Spectate( OBS_MODE_CHASE )
				pl:SpectateEntity( table.Random( player.GetAll() ) )
			end
		end
		return
	end
	pl:CheckPlayerClassOnSpawn()
	if ( GAMEMODE.TeamBased && ( pl:Team() == TEAM_SPECTATOR || pl:Team() == TEAM_UNASSIGNED ) ) then
		GAMEMODE:PlayerSpawnAsSpectator( pl )
		return
	end
	pl:UnSpectate()
	hook.Call( "PlayerLoadout", GAMEMODE, pl )
	hook.Call( "PlayerSetModel", GAMEMODE, pl )
	pl:SetupHands()
	pl:OnSpawn()

    -- S4 Audio Overhaul: Player Respawn Sound
    local soundPath = "eft/announcer/player_respawn.wav"
    net.Start("eft_localsound")
        net.WriteString(soundPath)
        net.WriteFloat(100) -- Pitch
        net.WriteFloat(1.0) -- Volume
    net.Send(pl)
end

function GM:PlayerLoadout( pl )
	pl:CheckPlayerClassOnSpawn()
	pl:OnLoadout()
	local cl_defaultweapon = pl:GetInfo( "cl_defaultweapon" )
	if ( pl:HasWeapon( cl_defaultweapon )  ) then
		pl:SelectWeapon( cl_defaultweapon ) 
	end
end

function GM:AutoTeam( pl )
	if ( !GAMEMODE.AllowAutoTeam ) then return end
	if ( !GAMEMODE.TeamBased ) then return end
	GAMEMODE:PlayerRequestTeam( pl, team.BestAutoJoinTeam() )
end
concommand.Add( "autoteam", function( pl, cmd, args ) hook.Call( "AutoTeam", GAMEMODE, pl ) end )

function GM:PlayerRequestClass( ply, class, disablemessage )
	local Classes = team.GetClass( ply:Team() )
	if (!Classes) then return end
	local RequestedClass = Classes[ class ]
	if (!RequestedClass) then return end
	if ( ply:Alive() && SERVER ) then
		if ( ply.m_SpawnAsClass && ply.m_SpawnAsClass == RequestedClass ) then return end
		ply.m_SpawnAsClass = RequestedClass
		if ( !disablemessage ) then
			ply:ChatPrint( "Your class will change to '".. player_class.GetClassName( RequestedClass ) .. "' when you respawn" )
		end
	else
		self:PlayerJoinClass( ply, RequestedClass )
		ply.m_SpawnAsClass = nil
	end
end
concommand.Add( "changeclass", function( pl, cmd, args ) hook.Call( "PlayerRequestClass", GAMEMODE, pl, tonumber(args[1]) ) end )

local function SeenSplash( ply )
	if ( ply.m_bSeenSplashScreen ) then return end
	ply.m_bSeenSplashScreen = true
	if ( !GAMEMODE.TeamBased && !GAMEMODE.NoAutomaticSpawning ) then
		ply:KillSilent()
	end
end
concommand.Add( "seensplash", SeenSplash )

function GM:PlayerJoinTeam( ply, teamid )
	local iOldTeam = ply:Team()
	if ( ply:Alive() ) then
		if ( iOldTeam == TEAM_SPECTATOR || (iOldTeam == TEAM_UNASSIGNED && GAMEMODE.TeamBased) ) then
			ply:KillSilent()
		else
			ply:Kill()
		end
	end
	ply:SetTeam( teamid )
	ply.LastTeamSwitch = RealTime()
	local Classes = team.GetClass( teamid )
	if ( Classes && #Classes > 1 ) then
		if ( ply:IsBot() || !GAMEMODE.SelectClass ) then
			GAMEMODE:PlayerRequestClass( ply, math.random( 1, #Classes ) )
		else
			ply.m_fnCallAfterClassChoose = function() 
												ply.DeathTime = CurTime()
												GAMEMODE:OnPlayerChangedTeam( ply, iOldTeam, teamid ) 
												ply:EnableRespawn() 
											end
			ply:SendLua( "GAMEMODE:ShowClassChooser( ".. teamid .." )" )
			ply:DisableRespawn()
			ply:SetRandomClass() 
			return
		end
	end
	if ( !Classes || #Classes == 0 ) then
		ply:SetPlayerClass( "Default" )
	end
	if ( Classes && #Classes == 1 ) then
		GAMEMODE:PlayerRequestClass( ply, 1 )
	end
	gamemode.Call("OnPlayerChangedTeam", ply, iOldTeam, teamid )
end

function GM:PlayerJoinClass( ply, classname )
	ply.m_SpawnAsClass = nil
	ply:SetPlayerClass( classname )
	if ( ply.m_fnCallAfterClassChoose ) then
		ply.m_fnCallAfterClassChoose()
		ply.m_fnCallAfterClassChoose = nil
	end
end

function GM:Base_OnPlayerChangedTeam( ply, oldteam, newteam )
	if ( newteam == TEAM_SPECTATOR ) then
		local Pos = ply:EyePos()
		ply:Spawn()
		ply:SetPos( Pos )
	elseif ( oldteam == TEAM_SPECTATOR ) then
		if ( !GAMEMODE.NoAutomaticSpawning ) then
			ply:Spawn()
		end
	elseif ( oldteam ~= TEAM_SPECTATOR ) then
		ply.LastTeamChange = CurTime()
	end
    net.Start( "fretta_teamchange" )
		net.WriteEntity( ply )
		net.WriteUInt( oldteam, 16 )
		net.WriteUInt( newteam, 16 )
    net.Broadcast()
end

function GM:CheckTeamBalance()
	local highest
	for id, tm in pairs( team.GetAllTeams() ) do
		if ( id > 0 && id < 1000 && team.Joinable( id ) ) then
			if ( !highest || team.NumPlayers( id ) > team.NumPlayers( highest ) ) then
				highest = id
			end
		end
	end
	if not highest then return end
	for id, tm in pairs( team.GetAllTeams() ) do
		if ( id ~= highest and id > 0 && id < 1000 && team.Joinable( id ) ) then
			if team.NumPlayers( id ) < team.NumPlayers( highest ) then
				while team.NumPlayers( id ) < team.NumPlayers( highest ) - 1 do
					local ply, reason = GAMEMODE:FindLeastCommittedPlayerOnTeam( highest )
					ply:Kill()
					ply:SetTeam( id )
					PrintMessage(HUD_PRINTTALK, ply:Name().." has been changed to "..team.GetName( id ).." for team balance. ("..reason..")" )
				end
			end
		end
	end
end

function GM:FindLeastCommittedPlayerOnTeam( teamid )
	local worst
	local worstteamswapper
	for k,v in pairs( team.GetPlayers( teamid ) ) do
		if ( v.LastTeamChange && CurTime() < v.LastTeamChange + 180 && (!worstteamswapper || worstteamswapper.LastTeamChange < v.LastTeamChange) ) then
			worstteamswapper = v
		end
		if ( !worst || v:Frags() < worst:Frags() ) then
			worst = v
		end
	end
	if worstteamswapper then
		return worstteamswapper, "They changed teams recently"
	end
	return worst, "Least points on their team"
end

function GM:EndOfGame( bGamemodeVote )
	if GAMEMANAGER.IsEndOfGameFlag then return end
	GAMEMANAGER:SetIsEndOfGame(true)
	GAMEMODE.IsEndOfGame = true -- Legacy field kept for compat
	gamemode.Call("OnEndOfGame", bGamemodeVote);
	if ( bGamemodeVote ) then
		MsgN( "Starting gamemode voting..." )
		PrintMessage( HUD_PRINTTALK, "Starting gamemode voting..." );
		timer.Simple( GAMEMODE.VotingDelay, function() GAMEMODE:StartGamemodeVote() end )
	end
end

function GM:GetWinningFraction()
	if ( !GAMEMODE.GMVoteResults ) then return end
	return GAMEMODE.GMVoteResults.Fraction
end

function GM:PlayerShouldTakeDamage( ply, attacker )
	if ( GAMEMODE.NoPlayerSelfDamage && IsValid( attacker ) && ply == attacker ) then return false end
	if ( GAMEMODE.NoPlayerDamage ) then return false end
	if ( GAMEMODE.NoPlayerTeamDamage && IsValid( attacker ) ) then
		if ( attacker.Team && ply:Team() == attacker:Team() && ply != attacker ) then return false end
	end
	if ( IsValid( attacker ) && attacker:IsPlayer() && GAMEMODE.NoPlayerPlayerDamage ) then return false end
	if ( IsValid( attacker ) && !attacker:IsPlayer() && GAMEMODE.NoNonPlayerPlayerDamage ) then return false end
	return true
end

function GM:PlayerDeathThink( pl )
	pl.DeathTime = pl.DeathTime or CurTime()
	local timeDead = CurTime() - pl.DeathTime
	if ( GAMEMODE.DeathLingerTime > 0 && timeDead > GAMEMODE.DeathLingerTime && ( pl:GetObserverMode() == OBS_MODE_FREEZECAM || pl:GetObserverMode() == OBS_MODE_DEATHCAM ) ) then
		GAMEMODE:BecomeObserver( pl )
	end
	-- Prevent spectators from respawning via keys
	if ( pl:Team() == TEAM_SPECTATOR or pl:Team() == TEAM_UNASSIGNED ) then return end

	if ( GAMEMODE.NoAutomaticSpawning ) then return end
	if ( !pl:CanRespawn() ) then return end
	if ( GAMEMODE.MinimumDeathLength ) then 
		pl:SetNWFloat( "RespawnTime", pl.DeathTime + GAMEMODE.MinimumDeathLength )
		if ( timeDead < pl:GetRespawnTime() ) then
			return
		end
	end
	if ( pl:GetRespawnTime() != 0 && GAMEMODE.MaximumDeathLength != 0 && timeDead > GAMEMODE.MaximumDeathLength ) then
		pl:Spawn()
		return
	end
	if ( pl:KeyPressed( IN_ATTACK ) || pl:KeyPressed( IN_ATTACK2 ) || pl:KeyPressed( IN_JUMP ) ) then
		pl:Spawn()
	end
end

function GM:GetFallDamage( ply, flFallSpeed )
	if ( GAMEMODE.RealisticFallDamage ) then
		return flFallSpeed / 8
	end
	return 10
end

function GM:PostPlayerDeath( ply )
	if ( ply:GetObserverMode() == OBS_MODE_NONE ) then
		ply:Spectate( OBS_MODE_DEATHCAM )
	end	
	ply:OnDeath()
end

function GM:Base_DoPlayerDeath( ply, attacker, dmginfo )
	ply:CallClassFunction( "OnDeath", attacker, dmginfo )
	ply:CreateRagdoll()
	ply:AddDeaths( 1 )
	if ( attacker:IsValid() && attacker:IsPlayer() ) then
		if ( attacker == ply ) then
			if ( GAMEMODE.TakeFragOnSuicide ) then
				attacker:AddFrags( -1 )
				if ( GAMEMODE.TeamBased && GAMEMODE.AddFragsToTeamScore ) then
					team.AddScore( attacker:Team(), -1 )
				end
			end
		else
			attacker:AddFrags( 1 )
			if ( GAMEMODE.TeamBased && GAMEMODE.AddFragsToTeamScore ) then
				team.AddScore( attacker:Team(), 1 )
			end
		end
	end
	if ( GAMEMODE.EnableFreezeCam && IsValid( attacker ) && attacker != ply ) then
		ply:SpectateEntity( attacker )
		ply:Spectate( OBS_MODE_FREEZECAM )
	end
end

function GM:StartSpectating( ply )
	if ( !GAMEMODE:PlayerCanJoinTeam( ply ) ) then return end
	ply:StripWeapons();
	GAMEMODE:PlayerJoinTeam( ply, TEAM_SPECTATOR )
	GAMEMODE:BecomeObserver( ply )
end

function GM:EndSpectating( ply )
	if ( !GAMEMODE:PlayerCanJoinTeam( ply ) ) then return end
	GAMEMODE:PlayerJoinTeam( ply, TEAM_UNASSIGNED )
	ply:KillSilent()
end

function GM:PlayerRequestTeam( ply, teamid )
	-- Silent fail if already on team (hides chat spam)
	if ply:Team() == teamid then return end

	if ( !GAMEMODE.TeamBased && GAMEMODE.AllowSpectating ) then
		if ( teamid == TEAM_SPECTATOR ) then
			GAMEMODE:StartSpectating( ply )
		else
			GAMEMODE:EndSpectating( ply )
		end
		return
	end
	return self.BaseClass:PlayerRequestTeam( ply, teamid ) -- BaseClass is Base
end

function GM:KeyPress(ply, key)
	if ply:GetObserverMode() ~= OBS_MODE_NONE then
		-- Spectator Input Overrides
		if key == IN_JUMP then
			local mode = ply:GetObserverMode()
			if mode == OBS_MODE_CHASE then
				ply:Spectate(OBS_MODE_ROAMING)
			else
				ply:Spectate(OBS_MODE_CHASE)
				-- Auto follow ball
				local ball = nil
				for _, ent in ipairs(ents.FindByClass("prop_ball")) do ball = ent break end
				if IsValid(ball) then ply:SpectateEntity(ball) end
			end
		end
		-- Block all other keys (Attack1/2 usually cycle players)
		-- We ONLY want Spacebar toggle and automatic ball following
		return
	end
	return self.BaseClass:KeyPress(ply, key)
end

local function TimeLeft( ply )
	local tl = GAMEMODE:GetGameTimeLeft()
	if ( tl == -1 ) then return end
	local Time = util.ToMinutesSeconds( tl )
	if ( IsValid( ply ) ) then
		ply:PrintMessage( HUD_PRINTCONSOLE, Time )
	else
		MsgN( Time )
	end
end
concommand.Add( "timeleft", TimeLeft )