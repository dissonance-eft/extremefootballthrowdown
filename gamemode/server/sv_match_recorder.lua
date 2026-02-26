if not SERVER then return end
/// MANIFEST LINKS:
/// Mechanics: M-050 (Game Flow - Recording)
/// Principles: P-080 (Data - Metrics)

-- Match Recorder Module
-- Records semantic gameplay events for post-match analysis.

local RECORDING = {}
RECORDING.MatchData = {}
RECORDING.IsActive = false
RECORDING.StartTime = 0

-- Configuration
local MAX_SPATIAL_DIST = 1400 -- Units to look for relevant players
local REPLAY_DIR = "eft_replays"

if not file.Exists(REPLAY_DIR, "DATA") then
	file.CreateDir(REPLAY_DIR)
end

function RECORDING:StartMatch(mapName)
	self.IsActive = true
	self.StartTime = CurTime()

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
		joined_at = math.Round(CurTime() - self.StartTime, 2)
	})
end

function RECORDING:EndMatch()
	if not self.IsActive then return end
	self.IsActive = false
	self.MatchData.duration = CurTime() - self.StartTime

	table.insert(self.MatchData.events, {
		time = math.Round(self.MatchData.duration, 2),
		type = "match_end",
		pids = {},
		ctx = {},
		data = { duration = math.Round(self.MatchData.duration, 2) }
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
				id = pl:SteamID64() or "BOT",
				pos = {math.Round(pPos.x), math.Round(pPos.y), math.Round(pPos.z)},
				vel = {math.Round(pVel.x), math.Round(pVel.y), math.Round(pVel.z)},
				has_ball = (pl:IsCarrying() and pl:GetCarrying() == ballEnt),
				team = pl:Team()
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

	local ball = GAMEMODE:GetBall()
	local focusPos = IsValid(ball) and ball:GetPos() or vector_origin
	if extraData.pos then focusPos = extraData.pos end

	local eventEntry = {
		time = math.Round(CurTime() - RECORDING.StartTime, 2),
		type = eventType,
		pids = playerIDs,
		ctx = GetSpatialContext(focusPos),
		data = extraData
	}

	table.insert(RECORDING.MatchData.events, eventEntry)
end

hook.Add("Initialize", "InitMatchRecorder", function()
	RECORDING:StartMatch()
end)

hook.Add("PlayerInitialSpawn", "MatchRecorderAddPlayer", function(ply)
	RECORDING:AddPlayer(ply)
end)

-- Match data is only saved when EndMatch() is called explicitly (e.g. round end),
-- not on server shutdown, to avoid incomplete/garbage replays.

_G.RecordMatchEvent = RecordMatchEvent
_G.MatchRecorder = RECORDING
