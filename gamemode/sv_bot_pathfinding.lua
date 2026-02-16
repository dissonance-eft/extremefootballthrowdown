-- ============================================================================
-- BOT PATHFINDING (A* using GMod NavMesh)
-- ============================================================================
-- Provides advanced navigation for bots on complex maps (Tunnel, Temple, etc)
-- If no NavMesh is present, bots fall back to direct line-of-sight movement.
-- ============================================================================

BotPathfinder = {}
BotPathfinder.Cache = {} -- Simple cache to avoid re-pathing every frame
BotPathfinder.LastUpdate = {}

local pathUpdateInterval = 0.5 -- How often to recalculate paths (seconds)

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

-- Find a path from startPos to endPos using NavMesh
-- Returns: nextWaypoint (Vector) or nil if no path/direct
function BotPathfinder.GetNextWaypoint(bot, targetPos)
	if not navmesh.IsLoaded() then return nil end
	
	local botPos = bot:GetPos()
	
	-- 1. Check if we need pathfinding (Direct LOS check)
	-- Use TraceHull to match player physics (prevent getting stuck on clip brushes/corners)
	local tr = util.TraceHull({
		start = botPos + Vector(0,0,10), -- Slight lift to avoid ground snags
		endpos = targetPos + Vector(0,0,10),
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 72),
		mask = MASK_PLAYERSOLID, -- Include World + Props + Clips
		filter = bot
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
