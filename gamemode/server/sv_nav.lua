if not SERVER then return end
/// MANIFEST LINKS:
/// Mechanics: M-060 (Bot - Navigation)

-- ============================================================================
-- EFT NAV GENERATION
-- ============================================================================
-- NORMAL MODE (default):
--   On map load, if no .nav exists, snaps floating spawns to ground and
--   runs nav_generate. Source saves the result to maps/<mapname>.nav.
--   The hook does nothing on subsequent loads (navmesh already loaded).
--
-- BATCH MODE (local use only — generates all maps in one session):
--   Launch GMod with: +eft_nav_batch 1 +map eft_slamdunk_v6
--   Cycles every EFT map automatically, generates nav, then quits.
--   Collect the .nav files from garrysmod/maps/ and commit to git.
-- ============================================================================

-- Register convar so +eft_nav_batch 1 launch arg is readable via GetConVar()
CreateConVar("eft_nav_batch", "0", FCVAR_NONE, "Set to 1 to auto-cycle all EFT maps and generate nav meshes, then quit.")

local NAV_GEN_DELAY   = 3    -- Seconds after map load before generating
local SPAWN_SNAP_DIST = 500  -- Max downward trace for spawn snapping
local POLL_INTERVAL   = 5    -- Seconds between "is nav done?" checks (batch)
local BATCH_TIMEOUT   = 600  -- Max seconds to wait per map before advancing (10 min)

-- All EFT maps — batch mode cycles these in order
local BATCH_MAPS = {
	"eft_baseballdash_v3",
	"eft_big_metal03r1",
	"eft_bloodbowl_v5",
	"eft_castle_warfare",
	"eft_chamber_v3",
	"eft_cosmic_arena_v2",
	"eft_countdown_v4",
	"eft_handegg_r2",
	"eft_lake_parima_v2",
	"eft_legoland_v2",
	"eft_minecraft_v4",
	"eft_miniputt_v1r",
	"eft_oasis_v4",
	"eft_sky_metal_v2",
	"eft_skyline_v2",
	"eft_skystep_v4",
	"eft_slamdunk_v6",
	"eft_soccer_b4",
	"eft_spacejump_v6",
	"eft_temple_sacrifice_v3",
	"eft_tunnel_v2",
	"eft_turbines_v2",
}

-- Spawn entity classnames used across EFT / Source SDK maps
local SPAWN_CLASSES = {
	"info_player_teamspawn",
	"info_player_start",
	"info_player_deathmatch",
	"info_player_combine",
	"info_player_rebel",
}

-- ============================================================================
-- Helpers
-- ============================================================================

--- Trace all spawn entities downward and land them on the floor.
--- Fixes the silent nav_generate failure caused by floating spawn points.
local function SnapSpawnsToGround()
	local snapped = 0
	for _, cls in ipairs(SPAWN_CLASSES) do
		for _, ent in ipairs(ents.FindByClass(cls)) do
			local pos = ent:GetPos()
			local tr  = util.TraceLine({
				start  = pos + Vector(0, 0, 5),
				endpos = pos - Vector(0, 0, SPAWN_SNAP_DIST),
				filter = ent,
				mask   = MASK_PLAYERSOLID_BRUSHONLY,
			})
			if tr.Hit and tr.HitPos:Distance(pos) > 2 then
				ent:SetPos(tr.HitPos + Vector(0, 0, 1))
				snapped = snapped + 1
			end
		end
	end
	return snapped
end

--- Run nav_generate: snap spawns, fire the command, return immediately.
local function RunNavGenerate()
	local n = SnapSpawnsToGround()
	if n > 0 then
		print("[EFT Nav] Snapped " .. n .. " spawn(s) to ground")
	end
	game.ConsoleCommand("nav_generate\n")
	print("[EFT Nav] nav_generate started")
end

-- ============================================================================
-- Batch mode helpers
-- ============================================================================

--- Find the next map after currentMap in the batch list. Returns nil if done.
local function NextBatchMap(currentMap)
	for i, m in ipairs(BATCH_MAPS) do
		if m == currentMap then
			return BATCH_MAPS[i + 1] -- nil if last
		end
	end
	return BATCH_MAPS[1] -- current map not in list; start from top
end

--- After nav_generate is running, poll until the mesh loads then advance.
local function WaitThenAdvance(currentMap, nextMap)
	local started   = CurTime()
	local timerName = "EFTNavBatchWait"

	timer.Create(timerName, POLL_INTERVAL, 0, function()
		local elapsed = CurTime() - started
		local done    = navmesh.IsLoaded() and navmesh.GetNavAreaCount() > 0
		local timeout = elapsed >= BATCH_TIMEOUT

		if done then
			print(string.format("[EFT Nav] ✓ %s — %d areas (%.0fs)",
			      currentMap, navmesh.GetNavAreaCount(), elapsed))
		elseif timeout then
			print(string.format("[EFT Nav] ✗ %s — timed out after %.0fs, skipping",
			      currentMap, elapsed))
		end

		if done or timeout then
			timer.Remove(timerName)
			if nextMap then
				print("[EFT Nav] → Loading " .. nextMap)
				game.ConsoleCommand("changelevel " .. nextMap .. "\n")
			else
				print("[EFT Nav] ══ ALL MAPS DONE ══")
				print("[EFT Nav] Nav files are in: garrysmod/maps/")
				print("[EFT Nav] Commit them to git, then include in workshop GMA.")
				game.ConsoleCommand("quit\n")
			end
		end
	end)
end

-- ============================================================================
-- Main hook
-- ============================================================================

-- ============================================================================
-- Console command: trigger batch mode from inside a running local game
-- Usage: start any EFT map locally, open console, type: eft_nav_batch_start
-- ============================================================================
concommand.Add("eft_nav_batch_start", function()
	RunConsoleCommand("eft_nav_batch", "1")
	print("[EFT Nav] Batch mode enabled — cycling to first map...")
	timer.Simple(0.5, function()
		game.ConsoleCommand("changelevel " .. BATCH_MAPS[1] .. "\n")
	end)
end)

hook.Add("InitPostEntity", "EFTAutoNavGenerate", function()
	local isBatch   = GetConVarNumber("eft_nav_batch") > 0
	local mapName   = game.GetMap()
	local navLoaded = navmesh.IsLoaded()

	-- ── Batch mode ──────────────────────────────────────────────────────────
	if isBatch then
		local nextMap = NextBatchMap(mapName)

		if navLoaded then
			-- Nav already exists for this map — skip it
			print(string.format("[EFT Nav] %s already has a nav mesh, skipping", mapName))
			if nextMap then
				timer.Simple(1, function()
					game.ConsoleCommand("changelevel " .. nextMap .. "\n")
				end)
			else
				print("[EFT Nav] ══ ALL MAPS DONE (all were pre-existing) ══")
				game.ConsoleCommand("quit\n")
			end
		else
			-- Generate, then advance
			print(string.format("[EFT Nav] [%d/%d] Generating: %s",
			      table.KeyFromValue(BATCH_MAPS, mapName) or 0,
			      #BATCH_MAPS, mapName))
			timer.Simple(NAV_GEN_DELAY, function()
				RunNavGenerate()
				WaitThenAdvance(mapName, nextMap)
			end)
		end
		return
	end

	-- ── Normal mode (server auto-gen fallback) ───────────────────────────────
	if navLoaded then
		print("[EFT Nav] NavMesh loaded for " .. mapName)
		return
	end

	print("[EFT Nav] No NavMesh for " .. mapName ..
	      " — generating in " .. NAV_GEN_DELAY .. "s...")

	timer.Simple(NAV_GEN_DELAY, function()
		RunNavGenerate()
		print("[EFT Nav] nav_generate running — bots will pathfind after it completes")
	end)
end)
