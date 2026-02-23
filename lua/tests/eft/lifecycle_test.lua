-- EFT GameManager Lifecycle Tests
-- Tests state flag transitions (on the real GAMEMANAGER with restore) and the
-- Think() overtime/endgame decision tree (on isolated mock instances with spies).
--
-- What's NOT tested here: PreRoundStart, RoundStart, RoundEnd — these call into
-- GAMEMODE hooks and Promise.Delay, making them integration territory that
-- requires in-game verification.

-- ============================================================================
-- Helpers
-- ============================================================================

-- Create an isolated GameManager-like instance for Think() testing.
-- Overrides GetTimeLimit, EndOfGame, and SetOvertime with spies so
-- the real game is never affected.
local function testGM(opts)
    opts = opts or {}
    local calls = { endOfGame = false, setOvertime = nil }

    local gm = setmetatable({
        IsEndOfGameFlag = opts.isEndOfGame or false,
        Overtime        = opts.overtime or false,
        OvertimeTime    = opts.overtimeTime ~= nil and opts.overtimeTime or 60,
    }, { __index = GameManager })

    function gm:GetTimeLimit() return opts.timeLimit or math.huge end
    function gm:EndOfGame()    calls.endOfGame = true end
    function gm:SetOvertime(b) calls.setOvertime = b; self.Overtime = b end

    return gm, calls
end

-- Temporarily replace team.GetScore within a callback, then restore.
local function withScores(red, blue, fn)
    local orig = team.GetScore
    team.GetScore = function(t) return t == TEAM_RED and red or blue end
    fn()
    team.GetScore = orig
end

-- ============================================================================
-- Tests
-- ============================================================================

return {
    groupName = "GameManager Lifecycle",
    cases = {

        -- ---- State flag round-trips (real GAMEMANAGER, always restored) ----
        {
            name = "SetInRound(true) -> InRound() is true, GlobalBool InRound is true",
            func = function()
                local orig = GAMEMANAGER.InRoundFlag
                GAMEMANAGER:SetInRound(true)
                expect(GAMEMANAGER:InRound()).to.beTrue()
                expect(GetGlobalBool("InRound", false)).to.beTrue()
                GAMEMANAGER:SetInRound(orig)
            end,
        },
        {
            name = "SetInRound(false) -> InRound() is false, GlobalBool InRound is false",
            func = function()
                local orig = GAMEMANAGER.InRoundFlag
                GAMEMANAGER:SetInRound(false)
                expect(GAMEMANAGER:InRound()).to.beFalse()
                expect(GetGlobalBool("InRound", false)).to.beFalse()
                GAMEMANAGER:SetInRound(orig)
            end,
        },
        {
            name = "SetIsEndOfGame(true) -> flag and GlobalBool IsEndOfGame are true",
            func = function()
                local orig = GAMEMANAGER.IsEndOfGameFlag
                GAMEMANAGER:SetIsEndOfGame(true)
                expect(GAMEMANAGER.IsEndOfGameFlag).to.beTrue()
                expect(GetGlobalBool("IsEndOfGame", false)).to.beTrue()
                GAMEMANAGER:SetIsEndOfGame(orig or false)
            end,
        },
        {
            name = "SetIsEndOfGame(false) -> flag and GlobalBool IsEndOfGame are false",
            func = function()
                local orig = GAMEMANAGER.IsEndOfGameFlag
                GAMEMANAGER:SetIsEndOfGame(false)
                expect(GAMEMANAGER.IsEndOfGameFlag).to.beFalse()
                expect(GetGlobalBool("IsEndOfGame", false)).to.beFalse()
                GAMEMANAGER:SetIsEndOfGame(orig or false)
            end,
        },
        {
            name = "AddBonusTime accumulates correctly",
            func = function()
                local orig = GAMEMANAGER:GetBonusTime()
                GAMEMANAGER:SetBonusTime(10)
                GAMEMANAGER:AddBonusTime(5)
                expect(GAMEMANAGER:GetBonusTime()).to.equal(15)
                GAMEMANAGER:SetBonusTime(orig)
            end,
        },
        {
            name = "ClearRoundResult zeros RoundResult and RRText globals",
            func = function()
                SetGlobalInt("RoundResult", 99)
                SetGlobalString("RRText", "test text")
                GAMEMANAGER:ClearRoundResult()
                expect(GetGlobalInt("RoundResult", 0)).to.equal(0)
                expect(GetGlobalString("RRText", "")).to.equal("")
            end,
        },
        {
            name = "ProcessResultText: nil becomes empty string",
            func = function()
                expect(GAMEMANAGER:ProcessResultText(1, nil)).to.equal("")
            end,
        },
        {
            name = "ProcessResultText: non-nil text passes through unchanged",
            func = function()
                expect(GAMEMANAGER:ProcessResultText(1, "RED scored!")).to.equal("RED scored!")
            end,
        },
        {
            name = "GetRoundLimit returns a positive number",
            func = function()
                local limit = GAMEMANAGER:GetRoundLimit()
                expect(limit).to.beA("number")
                expect(limit > 0).to.beTrue()
            end,
        },

        -- ---- Think(): time-limit branch ----
        {
            name = "Think: time not expired, not overtime -> nothing happens",
            func = function()
                local gm, calls = testGM({ timeLimit = math.huge, overtime = false })
                withScores(3, 3, function() gm:Think() end)
                expect(calls.endOfGame).to.beFalse()
                expect(calls.setOvertime).to.beNil()
            end,
        },
        {
            name = "Think: time expired, tied scores, not overtime -> SetOvertime(true)",
            func = function()
                local gm, calls = testGM({ timeLimit = 0, overtime = false })
                withScores(5, 5, function() gm:Think() end)
                expect(calls.setOvertime).to.equal(true)
                expect(calls.endOfGame).to.beFalse()
            end,
        },
        {
            name = "Think: time expired, scores differ, not overtime -> EndOfGame",
            func = function()
                local gm, calls = testGM({ timeLimit = 0, overtime = false })
                withScores(5, 3, function() gm:Think() end)
                expect(calls.endOfGame).to.beTrue()
                expect(calls.setOvertime).to.beNil()
            end,
        },
        {
            name = "Think: time expired, already in overtime -> EndOfGame",
            func = function()
                local gm, calls = testGM({ timeLimit = 0, overtime = true })
                withScores(5, 5, function() gm:Think() end)
                expect(calls.endOfGame).to.beTrue()
            end,
        },
        {
            name = "Think: time expired, sudden death (OvertimeTime = -1), tied -> EndOfGame (no OT round)",
            func = function()
                local gm, calls = testGM({ timeLimit = 0, overtime = false, overtimeTime = -1 })
                withScores(5, 5, function() gm:Think() end)
                expect(calls.endOfGame).to.beTrue()
                expect(calls.setOvertime).to.beNil()
            end,
        },
        {
            name = "Think: IsEndOfGameFlag = true -> nothing happens even if time expired",
            func = function()
                local gm, calls = testGM({ timeLimit = 0, isEndOfGame = true })
                withScores(10, 10, function() gm:Think() end)
                expect(calls.endOfGame).to.beFalse()
                expect(calls.setOvertime).to.beNil()
            end,
        },
        {
            name = "Think: SuppressTimeLimit active -> time expiry ignored",
            func = function()
                local gm, calls = testGM({ timeLimit = 0 })
                local orig = GAMEMODE.SuppressTimeLimit
                GAMEMODE.SuppressTimeLimit = CurTime() + 999
                withScores(5, 5, function() gm:Think() end)
                GAMEMODE.SuppressTimeLimit = orig
                expect(calls.endOfGame).to.beFalse()
                expect(calls.setOvertime).to.beNil()
            end,
        },

        -- ---- Think(): overtime resolution branch (time not yet expired) ----
        {
            name = "Think: in overtime, scores differ -> EndOfGame (sudden death resolution)",
            func = function()
                local gm, calls = testGM({ timeLimit = math.huge, overtime = true })
                withScores(6, 5, function() gm:Think() end)
                expect(calls.endOfGame).to.beTrue()
            end,
        },
        {
            name = "Think: in overtime, scores still tied -> nothing happens (waiting for goal)",
            func = function()
                local gm, calls = testGM({ timeLimit = math.huge, overtime = true })
                withScores(5, 5, function() gm:Think() end)
                expect(calls.endOfGame).to.beFalse()
                expect(calls.setOvertime).to.beNil()
            end,
        },
        {
            name = "Think: overtime winner can be either team (BLUE wins)",
            func = function()
                local gm, calls = testGM({ timeLimit = math.huge, overtime = true })
                withScores(4, 5, function() gm:Think() end)
                expect(calls.endOfGame).to.beTrue()
            end,
        },
    },
}
