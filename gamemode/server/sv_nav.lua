if not SERVER then return end
/// MANIFEST LINKS:
/// Mechanics: M-060 (Bot - Navigation)

-- ============================================================================
-- EFT NAV GENERATION
-- ============================================================================
-- On map load, if no .nav exists, snaps floating spawns to ground and
-- runs nav_generate. Source saves the result to maps/<mapname>.nav.
-- The hook does nothing on subsequent loads (navmesh already loaded).
--
-- To generate manually per map, type in console: eft_nav_generate
-- ============================================================================

local NAV_GEN_DELAY   = 3
local SPAWN_SNAP_DIST = 500

local SPAWN_CLASSES = {
	"info_player_teamspawn",
	"info_player_start",
	"info_player_deathmatch",
	"info_player_combine",
	"info_player_rebel",
}

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

local function RunNavGenerate()
	local n = SnapSpawnsToGround()
	if n > 0 then print("[EFT Nav] Snapped " .. n .. " spawn(s) to ground") end
	game.ConsoleCommand("nav_generate\n")
	print("[EFT Nav] nav_generate running for " .. game.GetMap())
end

-- Manual trigger: type eft_nav_generate in console on any loaded map
concommand.Add("eft_nav_generate", function()
	RunNavGenerate()
end)

-- Auto-generate on map load if no .nav exists (server fallback)
hook.Add("InitPostEntity", "EFTAutoNavGenerate", function()
	if navmesh.IsLoaded() then return end
	print("[EFT Nav] No nav mesh for " .. game.GetMap() .. " — generating in " .. NAV_GEN_DELAY .. "s...")
	timer.Simple(NAV_GEN_DELAY, function()
		RunNavGenerate()
	end)
end)
