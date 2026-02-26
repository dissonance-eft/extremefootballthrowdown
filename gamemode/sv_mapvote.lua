-- gamemode/sv_mapvote.lua
/// MANIFEST LINKS:
/// Principles: C-007 (Migrating Conflict Zone - Map Choice)
-- Map Vote System for EFT (server side)
-- Replaces the basic Fretta text-list vote with a modern thumbnail-enabled system.
-- Hooks into the existing EndOfGame → StartGamemodeVote flow.
--
-- s&box mapping:
--   MapVote.Start()      → custom GameManager method with [Rpc.Broadcast]
--   net.Start/Broadcast  → [Rpc.Broadcast] void StartMapVote(string[] maps, float duration)
--   net.Receive vote     → [Rpc.Host] void CastVote(int mapId)
--   RTV system           → chat command handler on Component
--
-- Image support:
--   Place map thumbnails at: materials/mapvote/<mapname>.png
--   (or .jpg → convert to .vtf/.vmt for best results)
--   The client will look for "mapvote/<mapname>" as a Material.
--   If no material exists, a placeholder with the map name is shown.

---@class MapVoteConfig
---@field MapLimit number Maximum maps shown in the vote
---@field TimeLimit number Vote duration in seconds
---@field AllowCurrentMap boolean Include the current map in the vote
---@field EnableCooldown boolean Prevent recently played maps from appearing
---@field MapsBeforeRevote number Maps that must be played before a map can reappear
---@field RTVPlayerCount number Minimum players for RTV to work
---@field RTVWait number Seconds after map start before RTV is allowed
---@field MapPrefixes string[] Map name prefixes to filter for

MapVote = MapVote or {}
MapVote.Config = {
    MapLimit = 24,
    TimeLimit = 15,
    AllowCurrentMap = false,
    EnableCooldown = true,
    MapsBeforeRevote = 3,
    RTVPlayerCount = 3,
    RTVWait = 60,
    MapPrefixes = {"xft_", "eft_"},
}

MapVote.CurrentMaps = {}
MapVote.Votes = {}       -- SteamID -> map index
MapVote.Allow = false

-- Update type constants (shared with client)
MapVote.UPDATE_VOTE = 1
MapVote.UPDATE_WIN  = 3

-- ============================================================================
-- NET STRINGS
-- ============================================================================

util.AddNetworkString("EFT_MapVoteStart")
util.AddNetworkString("EFT_MapVoteUpdate")
util.AddNetworkString("EFT_MapVoteCancel")
util.AddNetworkString("EFT_RTVNotify")

-- ============================================================================
-- COOLDOWN / RECENT MAPS
-- ============================================================================

-- Map cooldown list: in-memory only (resets on server restart, no disk writes)
local recentMaps = {}

local function RecordCurrentMap()
    local cooldownNum = MapVote.Config.MapsBeforeRevote or 3
    local curMap = game.GetMap():lower()

    -- Remove if already in list (prevent duplicates)
    for i = #recentMaps, 1, -1 do
        if recentMaps[i] == curMap then
            table.remove(recentMaps, i)
        end
    end

    -- Insert at front
    table.insert(recentMaps, 1, curMap)

    -- Trim to limit
    while #recentMaps > cooldownNum do
        table.remove(recentMaps)
    end
end

-- ============================================================================
-- VIP / EXTRA VOTE POWER
-- ============================================================================

--- Override this to give certain players extra voting weight (2x).
---@param ply Player
---@return boolean
function MapVote.HasExtraVotePower(ply)
    return ply:IsAdmin()
end

-- ============================================================================
-- VOTE HANDLING (incoming from clients)
-- ============================================================================

net.Receive("EFT_MapVoteUpdate", function(len, ply)
    if not MapVote.Allow then return end
    if not IsValid(ply) then return end

    local updateType = net.ReadUInt(3)

    if updateType == MapVote.UPDATE_VOTE then
        local mapId = net.ReadUInt(32)

        if MapVote.CurrentMaps[mapId] then
            MapVote.Votes[ply:SteamID()] = mapId

            -- Broadcast vote to all clients
            net.Start("EFT_MapVoteUpdate")
                net.WriteUInt(MapVote.UPDATE_VOTE, 3)
                net.WriteEntity(ply)
                net.WriteUInt(mapId, 32)
            net.Broadcast()
        end
    end
end)

-- ============================================================================
-- CORE VOTE LOGIC
-- ============================================================================

--- Start a map vote. Called by the existing GM:StartGamemodeVote flow.
---@param length? number Vote duration in seconds
---@param allowCurrent? boolean Allow current map
---@param limit? number Max maps to show
---@param prefixes? string[] Map prefixes to filter
---@param callback? fun(map: string) Custom callback instead of changelevel
function MapVote.Start(length, allowCurrent, limit, prefixes, callback)
    length = length or MapVote.Config.TimeLimit
    allowCurrent = allowCurrent or MapVote.Config.AllowCurrentMap
    limit = limit or MapVote.Config.MapLimit
    prefixes = prefixes or MapVote.Config.MapPrefixes
    local cooldown = MapVote.Config.EnableCooldown

    -- Find all BSP files
    local allMaps = file.Find("maps/*.bsp", "GAME")
    local voteMaps = {}
    local currentMap = game.GetMap():lower()

    for _, bspFile in RandomPairs(allMaps) do
        local mapName = bspFile:sub(1, -5):lower() -- strip .bsp

        -- Skip current map
        if not allowCurrent and mapName == currentMap then continue end

        -- Skip recently played maps
        if cooldown and table.HasValue(recentMaps, mapName) then continue end

        -- Check prefix match
        local matched = false
        for _, prefix in ipairs(prefixes) do
            if string.sub(mapName, 1, #prefix) == prefix then
                matched = true
                break
            end
        end

        if matched then
            if SERVER then
                voteMaps[#voteMaps + 1] = mapName

                if #voteMaps >= limit then break end
            end
        end
    end

    -- If we found no maps, fall back to allowing current map
    if #voteMaps == 0 and not allowCurrent then
        return MapVote.Start(length, true, limit, prefixes, callback)
    end

    -- If still no maps, abort
    if #voteMaps == 0 then
        ErrorNoHalt("[MapVote] No maps found matching prefixes! Cannot start vote.\n")
        return
    end

    -- Send vote start to all clients
    net.Start("EFT_MapVoteStart")
        net.WriteUInt(#voteMaps, 32)
        for i = 1, #voteMaps do
            net.WriteString(voteMaps[i])
        end
        net.WriteUInt(length, 32)
    net.Broadcast()

    MapVote.Allow = true
    MapVote.CurrentMaps = voteMaps
    MapVote.Votes = {}


    -- Timer to end the vote
    timer.Create("EFT_MapVote", length, 1, function()
        MapVote.Allow = false

        -- Tally votes
        local mapResults = {}
        for steamId, mapIdx in pairs(MapVote.Votes) do
            if not mapResults[mapIdx] then
                mapResults[mapIdx] = 0
            end

            -- Find the player for extra vote power check
            local weight = 1
            for _, ply in ipairs(player.GetAll()) do
                if ply:SteamID() == steamId then
                    if MapVote.HasExtraVotePower(ply) then
                        weight = 2
                    end
                    break
                end
            end

            mapResults[mapIdx] = mapResults[mapIdx] + weight
        end

        -- Record current map to cooldown
        RecordCurrentMap()

        -- Pick winner (or random if no votes)
        local winner = table.GetWinningKey(mapResults) or math.random(1, #voteMaps)

        -- Broadcast winner
        net.Start("EFT_MapVoteUpdate")
            net.WriteUInt(MapVote.UPDATE_WIN, 3)
            net.WriteUInt(winner, 32)
        net.Broadcast()

        local winningMap = MapVote.CurrentMaps[winner]

        -- Change map after a short delay for the flash animation
        timer.Simple(4, function()
            if hook.Run("MapVoteChange", winningMap) == false then return end

            if callback then
                callback(winningMap)
            else
                RunConsoleCommand("changelevel", winningMap)
            end
        end)
    end)
end

--- Cancel an active vote.
function MapVote.Cancel()
    if MapVote.Allow then
        MapVote.Allow = false

        net.Start("EFT_MapVoteCancel")
        net.Broadcast()

        timer.Destroy("EFT_MapVote")
    end
end


-- ============================================================================
-- ROCK THE VOTE
-- ============================================================================

RTV = RTV or {}
RTV.TotalVotes = 0
RTV._startTime = CurTime()

RTV.ChatCommands = {
    "!rtv",
    "/rtv",
    "rtv",
}

---@return boolean canVote
---@return string? errorMsg
function RTV.CanVote(ply)
    if CurTime() - RTV._startTime < (MapVote.Config.RTVWait or 60) then
        return false, "You must wait a bit before voting!"
    end
    if MapVote.Allow then
        return false, "There is already a vote in progress!"
    end
    if GetGlobalBool("IsEndOfGame", false) then
        return false, "The game is already ending!"
    end
    if ply.RTVoted then
        return false, "You have already voted to Rock the Vote!"
    end
    if #player.GetHumans() < (MapVote.Config.RTVPlayerCount or 3) then
        return false, "You need more players before you can rock the vote!"
    end
    return true
end

function RTV.ShouldChange()
    return RTV.TotalVotes >= math.ceil(#player.GetHumans() * 0.66)
end

function RTV.AddVote(ply)
    local can, err = RTV.CanVote(ply)
    if not can then
        ply:PrintMessage(HUD_PRINTTALK, err)
        return
    end

    RTV.TotalVotes = RTV.TotalVotes + 1
    ply.RTVoted = true

    local needed = math.ceil(#player.GetHumans() * 0.66)
    PrintMessage(HUD_PRINTTALK,
        ply:Nick() .. " voted to Rock the Vote. (" .. RTV.TotalVotes .. "/" .. needed .. ")")

    if RTV.ShouldChange() then
        PrintMessage(HUD_PRINTTALK, "Vote has been rocked! Map vote starting...")
        net.Start("EFT_RTVNotify")
        net.Broadcast()

        timer.Simple(3, function()
            MapVote.Start()
        end)
    end
end

hook.Add("PlayerDisconnected", "EFT_RTV_Disconnect", function(ply)
    if ply.RTVoted then
        RTV.TotalVotes = math.max(0, RTV.TotalVotes - 1)
    end

    timer.Simple(0.1, function()
        if RTV.ShouldChange() and not MapVote.Allow and not GetGlobalBool("IsEndOfGame", false) then
            PrintMessage(HUD_PRINTTALK, "Vote has been rocked! Map vote starting...")
            timer.Simple(3, function()
                MapVote.Start()
            end)
        end
    end)
end)

hook.Add("PlayerSay", "EFT_RTV_ChatCommand", function(ply, text)
    if table.HasValue(RTV.ChatCommands, string.lower(text)) then
        RTV.AddVote(ply)
        return ""
    end
end)

