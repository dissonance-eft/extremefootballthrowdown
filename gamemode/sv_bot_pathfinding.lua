/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity - Bot)
-- ============================================================================
-- BOT PATHFINDING
-- ============================================================================
-- Priority order:
--   1. D3bot custom node graph  (hand-placed nodes per map via in-game editor)
--   2. GMod NavMesh A*          (if nav_generate was successfully run)
--   3. Direct line-of-sight     (always-available fallback)
--
-- EFT maps are open-air BSPs with no info_player_start seeds, so nav_generate
-- fails silently on most maps. D3bot sidesteps this with a custom node graph.
-- Use '!bot editmesh' in chat to open the in-game node editor.
-- Node graphs are saved to: data/d3bot/navmesh/map/<mapname>.txt
-- ============================================================================

BotPathfinder = {}
BotPathfinder.Cache = {}      -- nextWaypoint Vector per bot
BotPathfinder.LastUpdate = {} -- CurTime() of last path calculation per bot

local pathUpdateInterval = 0.5 -- How often to recalculate paths (seconds)

-- ============================================================================
-- D3bot pathfinding (primary — uses hand-placed node graph)
-- ============================================================================

--- Query D3bot's custom node graph for the next waypoint toward targetPos.
--- Returns a Vector or nil if D3bot is unavailable / has no graph for this map.
local function D3botGetNextWaypoint(bot, targetPos)
    if not D3bot or not D3bot.MapNavMesh then return nil end

    local navMesh = D3bot.MapNavMesh
    if not navMesh or not next(navMesh.NodeById) then return nil end -- Empty graph

    local botPos = bot:GetPos()

    local startNode = navMesh:GetNearestNodeOrNil(botPos)
    local endNode   = navMesh:GetNearestNodeOrNil(targetPos)
    if not startNode or not endNode then return nil end
    if startNode == endNode then return nil end -- Same node, direct move

    local path = D3bot.GetBestMeshPathOrNil(startNode, endNode)
    if not path or #path < 2 then return nil end

    -- path[1] = start node (where bot is), path[2] = next node to walk toward
    local nextNode = path[2]
    local waypoint = Vector(nextNode.Pos)

    -- Slight randomization to prevent bot trains on shared paths
    waypoint.x = waypoint.x + math.random(-15, 15)
    waypoint.y = waypoint.y + math.random(-15, 15)

    -- Jump detection: if next node is significantly higher, signal a jump
    bot.PathJump = waypoint.z > botPos.z + 40

    return waypoint
end

-- A* Node structure wrapper not needed, we use CNavArea directly plus a table for costs
-- OpenSet: list of areas to visit
-- CameFrom: map of AreaID -> ParentAreaID (to reconstruct path)
-- GScore: map of AreaID -> Cost from start
-- FScore: map of AreaID -> Estimated total cost

local function ReconstructPath(cameFrom, currentFunc, startArea)
	local path = {}
	local curr = currentFunc
	while curr do
		table.insert(path, 1, curr) -- Prepend
		if curr == startArea then break end
		curr = cameFrom[curr:GetID()]
	end
	return path
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Find the next waypoint toward targetPos.
--- Tries D3bot node graph first, then GMod NavMesh A*, then returns nil (direct LOS).
--- Returns: Vector or nil
function BotPathfinder.GetNextWaypoint(bot, targetPos)
    -- ---- Priority 1: D3bot custom node graph ----
    if BotPathfinder.LastUpdate[bot] == nil or
       CurTime() - (BotPathfinder.LastUpdate[bot] or 0) >= pathUpdateInterval then

        local d3waypoint = D3botGetNextWaypoint(bot, targetPos)
        if d3waypoint then
            BotPathfinder.Cache[bot]      = d3waypoint
            BotPathfinder.LastUpdate[bot] = CurTime()
            return d3waypoint
        end
    elseif BotPathfinder.Cache[bot] and D3bot and D3bot.MapNavMesh and next(D3bot.MapNavMesh.NodeById) then
        return BotPathfinder.Cache[bot] -- Still within throttle window, return cached
    end

    -- ---- Priority 2: GMod NavMesh A* (fallback when no D3bot graph) ----
	if not navmesh.IsLoaded() then return nil end

	local botPos = bot:GetPos()
	
	-- 1. Check if we need pathfinding (Direct LOS check)
	-- Use TraceHull to match player physics (prevent getting stuck on clip brushes/corners)
	local tr = util.TraceHull({
		start = botPos + Vector(0,0,10), -- Slight lift to avoid ground snags
		endpos = targetPos + Vector(0,0,10),
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 72),
		mask = MASK_SOLID, -- Hit everything solid (World + Props + Players initially)
		filter = function(ent) 
            -- Ignore the bot itself AND all other players/bots.
            -- We only want to pathfind around "Map" obstacles (Walls, Props).
            -- Dynamic player obstacles are handled by the combat AI (Switch to melee/Stuck check).
            if ent:IsPlayer() or ent:IsNPC() then return false end
            return true 
        end
	})
	
	if not tr.Hit then return nil end -- Direct path is clear, no A* needed
	
	-- 2. Throttling
	if BotPathfinder.LastUpdate[bot] and CurTime() - BotPathfinder.LastUpdate[bot] < pathUpdateInterval then
		return BotPathfinder.Cache[bot]
	end
	
	-- 3. Run A*
	local startArea = navmesh.GetNavArea(botPos, 200)
	local endArea = navmesh.GetNavArea(targetPos, 200)
	
	if not IsValid(startArea) or not IsValid(endArea) then return nil end
	if startArea == endArea then return nil end -- Same area, direct move
	
	local openSet = {startArea}
	local cameFrom = {}
	local gScore = {[startArea:GetID()] = 0}
	local fScore = {[startArea:GetID()] = startArea:GetCenter():Distance(targetPos)}
	
	local loops = 0
	local maxLoops = 200 -- Safety break
	
	while #openSet > 0 and loops < maxLoops do
		loops = loops + 1
		
		-- Get node with lowest fScore
		local current, currentIndex
		local lowestF = math.huge
		
		for i, area in ipairs(openSet) do
			local f = fScore[area:GetID()] or math.huge
			if f < lowestF then
				lowestF = f
				current = area
				currentIndex = i
			end
		end
		
		if current == endArea then
			-- Reconstruct path
			local path = ReconstructPath(cameFrom, current, startArea)
			-- Return center of the NEXT area (index 2, since 1 is start)
			if path[2] then
				local waypoint = path[2]:GetCenter()
				-- Randomize slightly to avoid bot trains
				waypoint.x = waypoint.x + math.random(-20, 20)
				waypoint.y = waypoint.y + math.random(-20, 20)
				
				BotPathfinder.Cache[bot] = waypoint
				BotPathfinder.LastUpdate[bot] = CurTime()
				
				-- Check for Jumping (if connection is a jump)
				-- NavMesh doesn't easily expose 'jump' links in GMod Lua API without CNavLadder
				-- But we can heuristic: If next area is significantly higher, set WantJump
				if waypoint.z > botPos.z + 40 then
					bot.PathJump = true
				else
					bot.PathJump = false
				end
				
				return waypoint
			end
			return nil
		end
		
		-- Remove current from openSet
		table.remove(openSet, currentIndex)
		
		-- Check neighbors
		for _, neighbor in ipairs(current:GetAdjacentAreas()) do
			local tentativeG = gScore[current:GetID()] + current:GetCenter():Distance(neighbor:GetCenter())
			local nID = neighbor:GetID()
			
			if tentativeG < (gScore[nID] or math.huge) then
				cameFrom[nID] = current
				gScore[nID] = tentativeG
				fScore[nID] = gScore[nID] + neighbor:GetCenter():Distance(targetPos)
				
				-- Add to openSet if not present
				local inOpen = false
				for _, a in ipairs(openSet) do if a == neighbor then inOpen = true break end end
				if not inOpen then
					table.insert(openSet, neighbor)
				end
			end
		end
	end
	
	return nil -- No path found
end
