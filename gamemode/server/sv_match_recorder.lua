if not SERVER then return end
/// MANIFEST LINKS:
/// Mechanics: M-050 (Game Flow - Recording)
/// Principles: P-080 (Data - Metrics)

-- Match Recorder Module
-- Records semantic gameplay events for post-match analysis.
-- Helix-compatible: top-level summary aggregate + per-event derived fields
-- (possession duration, round duration, knockdown events).

local RECORDING = {}
RECORDING.MatchData = {}
RECORDING.IsActive = false
RECORDING.StartTime = 0
RECORDING.PossessionStart = {} -- [playerID] = CurTime() at possession_gain
RECORDING.RoundStart = 0       -- CurTime() at round_start, for round duration

-- Configuration
local MAX_SPATIAL_DIST = 1400 -- Units to look for relevant players
local REPLAY_DIR = "eft_replays"
local MAX_REPLAYS = 50 -- Keep only the most recent N replay files

if not file.Exists(REPLAY_DIR, "DATA") then
	file.CreateDir(REPLAY_DIR)
end

function RECORDING:StartMatch(mapName)
	self.IsActive = true
	self.StartTime = CurTime()
	self.PossessionStart = {}
	self.RoundStart = 0

	self.MatchData = {
		map = mapName or game.GetMap(),
		date = os.date("%Y-%m-%d"),
		time = os.date("%H:%M:%S"),
		timestamp = os.time(),
		players = {},
		events = {}
	}

	-- Don't collect players here: Initialize fires before any player connects.
	-- Players are added lazily via PlayerInitialSpawn.
	table.insert(self.MatchData.events, {
		time = 0,
		type = "match_start",
		pids = {},
		ctx = {},
		data = { map = self.MatchData.map }
	})

	print("[MatchRecorder] Started recording on " .. self.MatchData.map)
end

function RECORDING:AddPlayer(ply)
	if not self.IsActive or not self.MatchData.players then return end
	local id = ply:SteamID64() or "BOT"
	for _, p in ipairs(self.MatchData.players) do
		if p.id == id then return end
	end
	table.insert(self.MatchData.players, {
		id = id,
		name = ply:Nick(),
		team = ply:Team(),
		is_bot = ply:IsBot(),
		joined_at = math.Round(CurTime() - self.StartTime, 2)
	})
end

-- Compute summary aggregate from events for Helix ingestion.
-- Derived values only — never written into the raw event stream.
local function ComputeSummary(events, duration)
	local s = {
		possessions                 = 0,
		tackles                     = 0,
		throws                      = 0,
		throw_received              = 0,
		head_ons                    = 0,
		knockdowns                  = 0,
		goals_red                   = 0,
		goals_blue                  = 0,
		rounds                      = 0,
		ball_resets                 = 0,
		respawns                    = 0,
		possession_duration_total   = 0,
		possession_duration_samples = 0,
	}
	local last_scores = { red = 0, blue = 0 }
	for _, ev in ipairs(events) do
		local t = ev.type
		if     t == "possession_gain"  then s.possessions       = s.possessions + 1
		elseif t == "possession_loss"  then
			if ev.data and ev.data.held_for_seconds then
				s.possession_duration_total   = s.possession_duration_total + ev.data.held_for_seconds
				s.possession_duration_samples = s.possession_duration_samples + 1
			end
		elseif t == "tackle_success"   then s.tackles           = s.tackles + 1
		elseif t == "throw"            then s.throws            = s.throws + 1
		elseif t == "throw_received"   then s.throw_received    = s.throw_received + 1
		elseif t == "head_on"          then s.head_ons          = s.head_ons + 1
		elseif t == "knockdown"        then s.knockdowns        = s.knockdowns + 1
		elseif t == "goal" then
			if ev.data and ev.data.team == 1 then s.goals_red   = s.goals_red + 1
			elseif ev.data and ev.data.team == 2 then s.goals_blue = s.goals_blue + 1
			end
		elseif t == "round_start"      then s.rounds            = s.rounds + 1
		elseif t == "ball_reset"       then s.ball_resets       = s.ball_resets + 1
		elseif t == "respawn"          then s.respawns          = s.respawns + 1
		elseif t == "round_end" then
			if ev.data and ev.data.scores then last_scores = ev.data.scores end
		end
	end

	-- Derived ratios (Helix B1/B3 proxies)
	s.tackle_per_possession   = s.possessions > 0 and math.Round(s.tackles / s.possessions, 3) or 0
	s.coordination_index      = s.possessions > 0 and math.Round(s.throw_received / s.possessions, 3) or 0
	s.avg_possession_duration = s.possession_duration_samples > 0
		and math.Round(s.possession_duration_total / s.possession_duration_samples, 2)
		or nil

	s.final_score      = last_scores
	s.duration_seconds = math.Round(duration, 2)
	return s
end

function RECORDING:EndMatch()
	if not self.IsActive then return end
	self.IsActive = false
	local duration = CurTime() - self.StartTime

	-- Build summary before inserting match_end event
	local summary = ComputeSummary(self.MatchData.events, duration)

	-- Top-level fields for quick Helix ingestion (no event parsing required)
	self.MatchData.duration_seconds = summary.duration_seconds
	self.MatchData.final_score      = summary.final_score
	self.MatchData.summary          = summary

	table.insert(self.MatchData.events, {
		time = summary.duration_seconds,
		type = "match_end",
		pids = {},
		ctx  = {},
		data = {
			duration_seconds = summary.duration_seconds,
			final_score      = summary.final_score
		}
	})

	local json = util.TableToJSON(self.MatchData, true)

	if not file.Exists(REPLAY_DIR, "DATA") then
		file.CreateDir(REPLAY_DIR)
	end

	local timestamp = os.date("%Y%m%d_%H%M%S")
	local filename = string.format("%s/match_%s.json", REPLAY_DIR, timestamp)
	file.Write(filename, json)

	print("[MatchRecorder] Saved replay to data/" .. filename)
	self.MatchData = {}
	self.PossessionStart = {}

	-- Rotate: delete oldest replays if over the cap
	local files = file.Find(REPLAY_DIR .. "/match_*.json", "DATA")
	table.sort(files) -- filenames are timestamped so sort = oldest first
	local overflow = #files - MAX_REPLAYS
	if overflow > 0 then
		for i = 1, overflow do
			file.Delete(REPLAY_DIR .. "/" .. files[i])
		end
		print("[MatchRecorder] Pruned " .. overflow .. " old replay(s), keeping last " .. MAX_REPLAYS)
	end
end

local function GetSpatialContext(focusPos)
	local context = {}

	local ballEnt = GAMEMODE:GetBall()
	local ballPos = IsValid(ballEnt) and ballEnt:GetPos() or (focusPos or vector_origin)
	local ballVel = IsValid(ballEnt) and ballEnt:GetVelocity() or vector_origin

	context.ball = {
		pos = {math.Round(ballPos.x), math.Round(ballPos.y), math.Round(ballPos.z)},
		vel = {math.Round(ballVel.x), math.Round(ballVel.y), math.Round(ballVel.z)}
	}

	context.players = {}
	for _, pl in ipairs(player.GetAll()) do
		if not pl:Alive() or pl:GetObserverMode() ~= OBS_MODE_NONE then continue end

		local pPos = pl:GetPos()
		if pPos:DistToSqr(ballPos) <= (MAX_SPATIAL_DIST * MAX_SPATIAL_DIST) then
			local pVel = pl:GetVelocity()
			table.insert(context.players, {
				id       = pl:SteamID64() or "BOT",
				pos      = {math.Round(pPos.x), math.Round(pPos.y), math.Round(pPos.z)},
				vel      = {math.Round(pVel.x), math.Round(pVel.y), math.Round(pVel.z)},
				has_ball = (pl:IsCarrying() and pl:GetCarrying() == ballEnt),
				team     = pl:Team()
			})
		end
	end

	return context
end

function RecordMatchEvent(eventType, involvedPlayers, extraData)
	if not RECORDING.IsActive then return end

	local playerIDs = {}
	if involvedPlayers then
		if IsValid(involvedPlayers) and involvedPlayers:IsPlayer() then
			table.insert(playerIDs, involvedPlayers:SteamID64() or "BOT")
		elseif type(involvedPlayers) == "table" then
			for _, p in ipairs(involvedPlayers) do
				if IsValid(p) and p:IsPlayer() then
					table.insert(playerIDs, p:SteamID64() or "BOT")
				end
			end
		end
	end

	if extraData == nil then extraData = {} end

	-- Possession duration: record start on gain, compute elapsed on loss
	if eventType == "possession_gain" and playerIDs[1] then
		RECORDING.PossessionStart[playerIDs[1]] = CurTime()
	elseif eventType == "possession_loss" and playerIDs[1] then
		local pid = playerIDs[1]
		local startT = RECORDING.PossessionStart[pid]
		if startT then
			extraData.held_for_seconds = math.Round(CurTime() - startT, 2)
			RECORDING.PossessionStart[pid] = nil
		end
	end

	-- Round duration: record start, compute on end
	if eventType == "round_start" then
		RECORDING.RoundStart = CurTime()
	elseif eventType == "round_end" and RECORDING.RoundStart > 0 then
		extraData.round_duration_seconds = math.Round(CurTime() - RECORDING.RoundStart, 2)
		RECORDING.RoundStart = 0
	end

	local ball = GAMEMODE:GetBall()
	local focusPos = IsValid(ball) and ball:GetPos() or vector_origin
	if extraData.pos then focusPos = extraData.pos end

	local eventEntry = {
		time = math.Round(CurTime() - RECORDING.StartTime, 2),
		type = eventType,
		pids = playerIDs,
		ctx  = GetSpatialContext(focusPos),
		data = extraData
	}

	table.insert(RECORDING.MatchData.events, eventEntry)
end

-- ============================================================================
-- KNOCKDOWN TRACKING
-- Polls at 5Hz to detect STATE_KNOCKEDDOWN entry without per-frame cost.
-- Fires a "knockdown" event once per knockdown instance.
-- ============================================================================
local KnockdownTracked = {}

timer.Create("MatchRecorderKnockdownCheck", 0.2, 0, function()
	if not RECORDING.IsActive then return end
	if not STATE_KNOCKEDDOWN then return end

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:Alive() then
			KnockdownTracked[ply] = nil
			continue
		end

		local isKD = ply.GetState and ply:GetState() == STATE_KNOCKEDDOWN
		if isKD and not KnockdownTracked[ply] then
			KnockdownTracked[ply] = true
			RecordMatchEvent("knockdown", ply, { is_bot = ply:IsBot() })
		elseif not isKD then
			KnockdownTracked[ply] = nil
		end
	end
end)

-- ============================================================================
-- HOOKS
-- ============================================================================

hook.Add("Initialize", "InitMatchRecorder", function()
	RECORDING:StartMatch()
end)

hook.Add("PlayerInitialSpawn", "MatchRecorderAddPlayer", function(ply)
	RECORDING:AddPlayer(ply)
end)

hook.Add("PlayerDisconnected", "MatchRecorderCleanup", function(ply)
	local id = ply:SteamID64() or "BOT"
	RECORDING.PossessionStart[id] = nil
	KnockdownTracked[ply] = nil
end)

-- Match data is only saved when EndMatch() is called explicitly (e.g. round end),
-- not on server shutdown, to avoid incomplete/garbage replays.

_G.RecordMatchEvent = RecordMatchEvent
_G.MatchRecorder = RECORDING
