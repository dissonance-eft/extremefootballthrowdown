-- gamemode/obj_gamemanager.lua
-- OOP Game Manager for EFT
-- Manages Round State, Scoring, and Game Loop
-- See lib/SBOX_MAPPING.lua for full porting reference.
--
-- s&box mapping:
--   class GameManager    → public sealed class GameManager : Component, Component.INetworkListener
--   Singleton pattern    → GameObjectSystem<GameManager> or Scene.GetAllComponents<GameManager>().First()
--   SetGlobalBool/Int    → [Sync(SyncFlags.FromHost)] properties on this component
--   Promise.Delay(n)     → await Task.DelaySeconds(n)
--   timer.Create(...)    → TimeSince/TimeUntil fields + OnFixedUpdate() checks
--   GAMEMODE:EndOfGame   → custom GameManager method with [Rpc.Broadcast]
--   GameEvents.*:Invoke  → ISceneEvent<IGameRoundEvents>.Post(x => x.OnRoundStart(num))
-- Round lifecycle: PreRoundStart → RoundStart → (CheckRoundEnd/RoundTimerEnd) → RoundEnd → next

---@class GameManager : BaseObject
---@field RoundLimit number Maximum number of rounds before EndOfGame
---@field RoundLength number Round duration in seconds (default 900 = 15 min)
---@field RoundPreStartTime number Pre-round freeze time in seconds
---@field RoundPostLength number Post-round delay before next round
---@field VotingDelay number Delay before voting starts
---@field Overtime boolean True if currently in overtime
---@field OvertimeTime number Overtime duration (-1 = sudden death)
---@field RoundNumber number Current round number (1-based)
---@field InRoundFlag boolean True if a round is currently active
---@field IsEndOfGameFlag? boolean Set true when EndOfGame has been called
---@field Instance GameManager Singleton reference
GameManager = class("GameManager")

-- Singleton instance
GameManager.Instance = nil

--- Initialize the GameManager with default configuration.
--- Maps to: C# `protected override void OnStart()`
function GameManager:ctor()
    GameManager.Instance = self

    -- Configuration (Default values, can be overridden by gamemode/convars)
    self.RoundLimit = 10
    self.RoundLength = 60 * 15 -- 15 minutes
    self.RoundPreStartTime = 5
    self.RoundPostLength = 5
    self.VotingDelay = 15

    self.Overtime = false
    self.OvertimeTime = -1

    -- State
    self.RoundNumber = 1
    self.InRoundFlag = false
end

-- ============================================================================
-- CENTRALIZED GLOBAL STATE (Phase 2a)
-- GameManager is the SINGLE AUTHORITY for all round/game state globals.
-- GM:* hooks delegate here — never set globals directly.
-- Maps to: C# [Sync(SyncFlags.FromHost)] properties on GameManager component
-- ============================================================================

--- Sync a round result to clients. Single writer for RoundResult/RRText.
---@param result number Team number (or -1 for draw)
---@param resulttext string Human-readable result text
function GameManager:SetRoundResult(result, resulttext)
    SetGlobalInt("RoundResult", result)
    SetGlobalString("RRText", tostring(resulttext or ""))
end

--- Sync a round winner (player) to clients. Single writer for RoundWinner/RRText.
---@param ply Player Winning player entity
---@param resulttext string Human-readable result text
function GameManager:SetRoundWinner(ply, resulttext)
    SetGlobalEntity("RoundWinner", ply)
    SetGlobalString("RRText", tostring(resulttext or ""))
end

--- Clear round result globals. Single writer.
function GameManager:ClearRoundResult()
    SetGlobalEntity("RoundWinner", NULL)
    SetGlobalInt("RoundResult", 0)
    SetGlobalString("RRText", "")
end

--- Set overtime state and sync to clients. Single writer for "overtime" global.
--- Also starts the overtime round if entering overtime.
---@param b boolean Overtime state
function GameManager:SetOvertime(b)
    self.Overtime = b
    SetGlobalBool("overtime", b)

    if b then
        GAMEMODE:StartRoundBasedGame()
        net.Start("eft_overtime")
        net.Broadcast()
    end
end

--- Set end-of-game flag. Single writer for "IsEndOfGame" global.
---@param b boolean End of game state
function GameManager:SetIsEndOfGame(b)
    self.IsEndOfGameFlag = b
    SetGlobalBool("IsEndOfGame", b)
end

--- Set bonus time (celebration pause). Single writer for "BonusTime" global.
---@param time number Total bonus time accumulated
function GameManager:SetBonusTime(time)
    SetGlobalFloat("BonusTime", time)
end

--- Get current bonus time.
---@return number bonusTime
function GameManager:GetBonusTime()
    return GetGlobalFloat("BonusTime", 0)
end

--- Add bonus time (e.g. after goal celebration).
---@param seconds number Seconds to add
function GameManager:AddBonusTime(seconds)
    self:SetBonusTime(self:GetBonusTime() + seconds)
end

---@return number limit Max rounds (0 = unlimited)
function GameManager:GetRoundLimit()
    return self.RoundLimit
end

--- Get the absolute CurTime() when the game time expires.
--- Delegates to GAMEMODE for ConVar-backed time limit.
---@return number timeLimit Absolute time limit from GAMEMODE
function GameManager:GetTimeLimit()
    return GAMEMODE:GetTimeLimit()
end

---@return boolean inRound True if a round is currently active
function GameManager:InRound()
    return self.InRoundFlag
end

--- Set round-active state and sync to clients via GlobalBool.
---@param b boolean Whether a round is active
function GameManager:SetInRound(b)
    self.InRoundFlag = b
    SetGlobalBool("InRound", b)
end

---@return boolean overtime True if game is in overtime
function GameManager:GetOvertime()
    return self.Overtime
end

-- SetOvertime is defined in the Centralized Global State section above

-- ============================================================================
-- ROUND LOGIC
-- Maps to: C# async Round lifecycle methods
-- PreRoundStart → RoundStart → RoundTimerEnd/CheckRoundEnd → RoundEnd → loop
-- ============================================================================

--- Begin the pre-round phase: check overtime/game-end, then delay into RoundStart.
--- Maps to: C# `async Task PreRoundStart(int roundNum)`
---@param iNum number Round number to start
function GameManager:PreRoundStart(iNum)
    local GM = GAMEMODE -- Bridge to legacy for now

    -- Should the game end? Check for overtime on tied scores first.
    if CurTime() >= GM:GetTimeLimit() or self:HasReachedRoundLimit(iNum) then
        if not self:GetOvertime() and team.GetScore(TEAM_RED) == team.GetScore(TEAM_BLUE) then
            GM:SetOvertime(true)
        else
            self:EndOfGame(true)
            return
        end
    end

    if not GM:CanStartRound(iNum) then
        Promise.Delay(1):then_(function()
            self:PreRoundStart(iNum)
        end)
        return
    end

    -- Pre-round delay using Promise
    Promise.Delay(self.RoundPreStartTime):then_(function()
        self:RoundStart()
    end)

    SetGlobalInt("RoundNumber", iNum)
    self.RoundNumber = iNum
    SetGlobalFloat("RoundStartTime", CurTime() + self.RoundPreStartTime)

    -- Set expected RoundEndTime so clients can display timer during pre-round
    SetGlobalFloat("RoundEndTime", CurTime() + self.RoundPreStartTime + self.RoundLength)

    self:ClearRoundResult()
    if GM.OnPreRoundStart then GM:OnPreRoundStart(iNum) end

    if GameEvents.PreRoundStart then GameEvents.PreRoundStart:Invoke(iNum) end

    self:SetInRound(true)
end

--- Start the active round: unfreeze players, start timer.
--- Maps to: C# `async Task RoundStart()`
function GameManager:RoundStart()
    local roundNum = self.RoundNumber

    if GameEvents.RoundStart then GameEvents.RoundStart:Invoke(roundNum) end

    -- Legacy Hook (Unfreezes players)
    if GAMEMODE.OnRoundStart then GAMEMODE:OnRoundStart(roundNum) end

    self:SetInRound(true)

    -- Determine round duration based on game state
    local remainingTime
    if self:GetOvertime() then
        remainingTime = self.OvertimeTime
    else
        remainingTime = GetGlobalFloat("GameTimeRemaining", 0)
        if remainingTime <= 0 or roundNum == 1 then
            remainingTime = self.RoundLength
        end
    end

    -- Set absolute end time
    SetGlobalFloat("RoundEndsAt", CurTime() + remainingTime)
    SetGlobalFloat("RoundDuration", remainingTime)

    -- Sync Timer Loop
    timer.Create("GameManager_CheckRoundEnd", 0.1, 0, function()
        if self:InRound() and CurTime() >= GetGlobalFloat("RoundEndsAt", 0) then
            timer.Remove("GameManager_CheckRoundEnd")
            self:RoundTimerEnd()
        end
        self:CheckRoundEnd()
    end)
end

--- End the round with a result (team number or player entity).
--- Maps to: C# `void RoundEndWithResult(object result, string text)`
---@param result number|Player Team number or winning player entity
---@param resulttext? string Human-readable result description
function GameManager:RoundEndWithResult(result, resulttext)
    resulttext = self:ProcessResultText(result, resulttext)

    if type(result) == "number" then
        self:SetRoundResult(result, resulttext)
        self:RoundEnd()
        GAMEMODE:OnRoundResult(result, resulttext)
    else
        self:SetRoundWinner(result, resulttext)
        self:RoundEnd()
        GAMEMODE:OnRoundWinner(result, resulttext)
    end
end

--- End the current round: save time, fire events, schedule next round.
--- Maps to: C# `async Task RoundEnd()`
function GameManager:RoundEnd()
    -- Save time remaining
    local roundEndsAt = GetGlobalFloat("RoundEndsAt", 0)
    if roundEndsAt > 0 then
        local remaining = math.max(0, roundEndsAt - CurTime())
        SetGlobalFloat("GameTimeRemaining", remaining)
    end

    GAMEMODE:OnRoundEnd(self.RoundNumber)
    if GameEvents.RoundEnd then GameEvents.RoundEnd:Invoke(self.RoundNumber) end

    self:SetInRound(false)

    timer.Remove("GameManager_CheckRoundEnd")
    SetGlobalFloat("RoundEndTime", -1)

    -- Async post-round delay
    Promise.Delay(self.RoundPostLength):then_(function()
        if self:GetOvertime() then
            self:EndOfGame(true)
        else
            self:PreRoundStart(self.RoundNumber + 1)
        end
    end)
end

--- End the entire game, delegate to GAMEMODE for freeze/voting.
--- Maps to: C# `void EndOfGame(bool startVote)`
---@param bGamemodeVote? boolean Whether to start a gamemode vote
function GameManager:EndOfGame(bGamemodeVote)
    -- Delegate to the GM:EndOfGame which handles freeze, OnEndOfGame, and map voting
    GAMEMODE:EndOfGame(bGamemodeVote)
end

--- Handle round timer expiration: determine winner or draw.
function GameManager:RoundTimerEnd()
    if not self:InRound() then return end

    if not GAMEMODE.TeamBased then
        local ply = GAMEMODE:SelectCurrentlyWinningPlayer()
        if ply then
            self:RoundEndWithResult(ply, "Time Up")
        else
            self:RoundEndWithResult(-1, "Time Up")
        end
    else
        self:RoundEndWithResult(-1, "Time Up")
    end
end

--- Check for win conditions mid-round (e.g. everyone dead).
--- Override this for custom win-condition logic.
function GameManager:CheckRoundEnd()
    -- Delegated to GM or implemented here for custom modes
end

-- ============================================================================
-- SCORING & BALL MANAGEMENT (Phase 2b)
-- GameManager owns scoring logic, tiebreaker setup, and result formatting.
-- GM:* hooks delegate here for backward compat.
-- Maps to: C# GameManager methods with [Rpc.Broadcast] for score events
-- ============================================================================

--- Check if the score limit has been reached by either team.
--- Maps to: C# `bool HasReachedScoreLimit()` property
---@param iNum number Round number (unused, kept for interface compat with round_controller)
---@return boolean reached True if either team has reached the score limit
function GameManager:HasReachedRoundLimit(iNum)
    local scoreLimit = GAMEMODE.ScoreLimit or 10
    return team.GetScore(TEAM_RED) >= scoreLimit or team.GetScore(TEAM_BLUE) >= scoreLimit
end

--- Format result text for display. Override for custom formatting.
--- Maps to: C# `string ProcessResultText(object result, string text)`
---@param result number|Player Team number or winning player
---@param resulttext? string Raw result text
---@return string formatted Formatted result text
function GameManager:ProcessResultText(result, resulttext)
    if resulttext == nil then resulttext = "" end
    return resulttext
end

--- Handle a team scoring a goal. Core scoring logic.
--- Maps to: C# `[Rpc.Broadcast] void OnTeamScored(int teamId, PlayerController hitter, int points, bool isTouch)`
---@param teamid number The team that scored (TEAM_RED or TEAM_BLUE)
---@param hitter? Entity The player/entity that scored
---@param points number Points scored
---@param istouch boolean Whether it was a touch goal
function GameManager:OnTeamScored(teamid, hitter, points, istouch)
    local GM = GAMEMODE
    if not teamid or not self:InRound() or GM:IsWarmUp() then return end

    GM:SlowTime(0.1, 2.5)

    team.AddScore(teamid, points)

    hitter = hitter or NULL

    local hittername
    if hitter and hitter:IsValid() then
        if hitter:IsPlayer() then
            hittername = hitter:Name()
            hitter:AddFrags(math.ceil(math.Clamp(#player.GetAll() / 10, 0.05, 1) * GM.PointsForScoring))
            hitter:SetNWInt("Goals", hitter:GetNWInt("Goals", 0) + 1)
        else
            hittername = hitter:GetClass()
        end
    else
        hittername = "Something"
    end

    self:RoundEndWithResult(teamid, hittername.." from the "..team.GetName(teamid).." scored a goal!")

    -- Add bonus time to compensate for celebration + pre-round delay
    local celebrationTime = (GM.RoundPostLength or 5) + (GM.RoundPreStartTime or 3)
    self:AddBonusTime(celebrationTime)

    local ball = GM:GetBall()

    net.Start("eft_teamscored")
        net.WriteUInt(teamid, 8)
        net.WriteEntity(hitter)
        net.WriteUInt(points, 8)
        if ball:IsValid() and ball.LastBigPoleHit and ball.LastBigPoleHit == hitter and CurTime() < ball.LastBigPoleHitTime + 5 and not istouch then
            net.WriteBit(true)
        else
            net.WriteBit(false)
        end
    net.Broadcast()

    for _, ent in pairs(ents.FindByClass("logic_teamscore")) do
        ent:Input("onscore", hitter, ball)
        if teamid == TEAM_RED then
            ent:Input("onredscore", hitter, ball)
        elseif teamid == TEAM_BLUE then
            ent:Input("onbluescore", hitter, ball)
        end
    end

    -- Legacy hook for gamemode extensions
    gamemode.Call("OnTeamScored", teamid, hitter, points, istouch)
end

--- Set up the tiebreaker minigame between the top players of each team.
--- Maps to: C# `void SetupTieBreaker()`
function GameManager:SetupTieBreaker()
    local GM = GAMEMODE
    if IsValid(GM.TieBreaker) then return end

    for _, ent in pairs(ents.FindByClass("prop_ball")) do ent:Remove() end
    for _, ent in pairs(ents.FindByClass("prop_carry_*")) do ent:Remove() end

    local redpl, bluepl = team.TopPlayer(TEAM_RED), team.TopPlayer(TEAM_BLUE)

    if redpl and bluepl then
        local ballhome = GM:GetBallHome()
        local ent = ents.Create("game_tiebreaker_controller")
        if ent:IsValid() then
            ent:SetPos(ballhome + Vector(0, -256, 0))
            ent:SetRedPlayer(redpl)
            ent:SetBluePlayer(bluepl)
            ent:Spawn()
        end

        redpl:SetPos(ballhome + Vector(-72, -256, 128))
        bluepl:SetPos(ballhome + Vector(72, -256, 128))
        redpl:SetState(STATE_FIGHTER2D)
        bluepl:SetState(STATE_FIGHTER2D)
    end
end

--- End the tiebreaker minigame.
--- Maps to: C# `void EndTieBreaker(int winnerTeamId)`
---@param winnerteamid number The winning team
function GameManager:EndTieBreaker(winnerteamid)
    for _, ent in pairs(ents.FindByClass("game_tiebreaker_controller")) do
        ent:Remove()
    end
end

-- ============================================================================
-- VOTING STATE (Phase 2d)
-- GameManager owns the voting-related globals for single-writer consistency.
-- Maps to: C# [Sync] properties + [Rpc.Broadcast] StartMapVote()
-- ============================================================================

--- Set whether a gamemode vote is currently in progress.
--- Single writer for "InGamemodeVote" global.
---@param b boolean Voting state
function GameManager:SetInGamemodeVote(b)
    SetGlobalBool("InGamemodeVote", b)
end

--- Set the vote end time for client display.
--- Single writer for "VoteEndTime" global.
---@param time number Absolute CurTime() when voting ends
function GameManager:SetVoteEndTime(time)
    SetGlobalFloat("VoteEndTime", time)
end

-- ============================================================================
-- THINK LOOP
-- ============================================================================

--- Main think loop: check time limit, overtime resolution.
--- Called every server tick from GM:Think().
--- Maps to: C# `protected override void OnUpdate()`
function GameManager:Think()
    local GM = GAMEMODE
    if not self.IsEndOfGameFlag then
        if CurTime() >= self:GetTimeLimit() and (not GM.SuppressTimeLimit or CurTime() > GM.SuppressTimeLimit) then
            if self:GetOvertime() or team.GetScore(TEAM_RED) ~= team.GetScore(TEAM_BLUE) or self.OvertimeTime < 0 then
                self:EndOfGame(true)
            else
                self:SetOvertime(true)
            end
        elseif self:GetOvertime() and team.GetScore(TEAM_RED) ~= team.GetScore(TEAM_BLUE) then
            self:EndOfGame(true)
        end
    end
end


-- Static Accessor
if not GAMEMANAGER then GAMEMANAGER = GameManager() end
