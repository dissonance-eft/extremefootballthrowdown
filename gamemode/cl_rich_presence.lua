if not CLIENT then return end
/// MANIFEST LINKS:
/// Features: APP-L (L-003 Rich Presence)

-- ============================================================================
-- RICH PRESENCE
-- Updates Steam Rich Presence and optionally Discord Rich Presence.
--
-- Steam RP: built-in via steamworks.SetRichPresence(). Shows in Steam friends
--   list, overlay, and join buttons. No Workshop dependency.
--
-- Discord RP: GMod natively shows gamemode + map in Discord automatically.
--   For live score in Discord detail/state fields, the Workshop addon
--   "Discord Rich Presence" (gm_discord_rpc) is required on each client.
--   This module is compatible with it when present; gracefully no-ops without.
-- ============================================================================

local THROTTLE = 5     -- Min seconds between RP updates (avoid spam)
local lastUpdate = 0

local function GetScoreString()
    local r = team.GetScore(TEAM_RED) or 0
    local b = team.GetScore(TEAM_BLUE) or 0
    return "RED " .. r .. " — BLUE " .. b
end

local function GetStateString()
    if GetGlobalBool("IsEndOfGame", false) then
        return "Post-Match"
    elseif GetGlobalBool("overtime", false) then
        return "OVERTIME"
    elseif GetGlobalBool("InRound", false) then
        return "In Match"
    else
        return "Warmup"
    end
end

local function UpdatePresence(force)
    if not force and CurTime() - lastUpdate < THROTTLE then return end
    lastUpdate = CurTime()

    local map   = game.GetMap()
    local score = GetScoreString()
    local state = GetStateString()

    -- Steam Rich Presence
    -- Shows in friends list as: "In a Game: <status>"
    if steamworks and steamworks.SetRichPresence then
        steamworks.SetRichPresence("status", state .. " · " .. score)
        steamworks.SetRichPresence("connect", "+connect " .. game.GetIPAddress())
    end

    -- Discord Rich Presence (requires gm_discord_rpc Workshop addon to be installed)
    -- Without it this block is silently skipped; GMod still shows gamemode+map natively.
    if discord and discord.SetPresence then
        discord.SetPresence({
            details       = map,
            state         = score,
            large_image   = "eft_logo",
            large_text    = "Extreme Football Throwdown",
            small_image   = state == "OVERTIME" and "overtime" or "ingame",
            small_text    = state,
            start_time    = GAMEMODE.MatchStartTime or os.time(),
        })
    end
end

-- ============================================================================
-- Update triggers
-- ============================================================================

-- Score change → update immediately (bypass throttle)
hook.Add("TeamScored", "EFT_RP_Score", function()
    lastUpdate = 0
    UpdatePresence()
end)

-- Match end
net.Receive("eft_endofgame", function()
    lastUpdate = 0
    timer.Simple(0.5, function() UpdatePresence(true) end)
end)

-- Overtime start
net.Receive("eft_overtime", function()
    lastUpdate = 0
    UpdatePresence(true)
end)

-- Initial join (allow a few seconds for globals to sync from server)
hook.Add("InitPostEntity", "EFT_RP_Init", function()
    timer.Simple(3, function() UpdatePresence(true) end)
end)

-- Periodic refresh every 60s to catch any missed state transitions
timer.Create("EFT_RP_Periodic", 60, 0, UpdatePresence)
