if not SERVER then return end
/// MANIFEST LINKS:
/// Mechanics: M-060 (Bot - Navigation)

-- ============================================================================
-- EFT AUTO NAV GENERATION
-- ============================================================================
-- On map load, if no .nav file exists for the current map, this module
-- automatically runs nav_generate to build one.
--
-- EFT maps often have spawn points that float slightly above the ground,
-- which causes nav_generate to silently skip them (no walkable seed found).
-- SnapSpawnsToGround() drops all spawn entities onto the floor first so
-- the nav flood-fill seeds correctly on every map.
--
-- The generated .nav is saved to maps/<mapname>.nav automatically by the
-- Source engine after generation completes. Subsequent map loads skip this.
-- ============================================================================

local NAV_GEN_DELAY   = 3    -- Seconds to wait after map load before generating
                              -- (lets all entities settle, physics init, etc.)
local SPAWN_SNAP_DIST = 500  -- Max downward trace distance when snapping spawns

-- Spawn entity classnames used by EFT / Source SDK maps
local SPAWN_CLASSES = {
	"info_player_teamspawn",
	"info_player_start",
	"info_player_deathmatch",
	"info_player_combine",
	"info_player_rebel",
}

-- ============================================================================
-- Spawn snap
-- ============================================================================

--- Trace all spawn entities downward and move them onto the floor.
--- Returns the number of entities that were actually moved.
local function SnapSpawnsToGround()
	local snapped = 0
	for _, cls in ipairs(SPAWN_CLASSES) do
		for _, ent in ipairs(ents.FindByClass(cls)) do
			local pos = ent:GetPos()
			local tr = util.TraceLine({
				start  = pos + Vector(0, 0, 5),
				endpos = pos - Vector(0, 0, SPAWN_SNAP_DIST),
				filter = ent,
				mask   = MASK_PLAYERSOLID_BRUSHONLY,
			})
			-- Only move if the spawn is floating (hit something below it)
			if tr.Hit and tr.HitPos:Distance(pos) > 2 then
				ent:SetPos(tr.HitPos + Vector(0, 0, 1))
				snapped = snapped + 1
			end
		end
	end
	return snapped
end

-- ============================================================================
-- Hook: auto-generate on first load
-- ============================================================================

hook.Add("InitPostEntity", "EFTAutoNavGenerate", function()
	if navmesh.IsLoaded() then
		print("[EFT Nav] NavMesh loaded for " .. game.GetMap())
		return
	end

	print("[EFT Nav] No NavMesh for " .. game.GetMap() ..
	      " — generating in " .. NAV_GEN_DELAY .. "s...")

	timer.Simple(NAV_GEN_DELAY, function()
		local n = SnapSpawnsToGround()
		if n > 0 then
			print("[EFT Nav] Snapped " .. n .. " spawn(s) to ground")
		end

		-- nav_generate runs server-side; Source saves the result to
		-- maps/<mapname>.nav automatically when it finishes.
		game.ConsoleCommand("nav_generate\n")
		print("[EFT Nav] nav_generate started — bots will pathfind after it completes")
	end)
end)
