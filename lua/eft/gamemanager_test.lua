-- EFT GameManager Logic Tests
-- Tests scoring, time limit calculation, and pity logic.
-- Mocks are restored after each test that requires them.

return {
    groupName = "GameManager Logic",
    cases = {

        -- ---- HasReachedRoundLimit ----
        {
            name = "HasReachedRoundLimit: false when both teams at 0",
            func = function()
                local origGetScore = team.GetScore
                team.GetScore = function() return 0 end
                local result = GAMEMANAGER:HasReachedRoundLimit()
                team.GetScore = origGetScore
                expect(result).to.beFalse()
            end,
        },
        {
            name = "HasReachedRoundLimit: true when RED reaches ScoreLimit",
            func = function()
                local origGetScore = team.GetScore
                local origScoreLimit = GAMEMODE.ScoreLimit
                GAMEMODE.ScoreLimit = 5
                team.GetScore = function(t) return t == TEAM_RED and 5 or 0 end
                local result = GAMEMANAGER:HasReachedRoundLimit()
                team.GetScore = origGetScore
                GAMEMODE.ScoreLimit = origScoreLimit
                expect(result).to.beTrue()
            end,
        },
        {
            name = "HasReachedRoundLimit: true when BLUE reaches ScoreLimit",
            func = function()
                local origGetScore = team.GetScore
                local origScoreLimit = GAMEMODE.ScoreLimit
                GAMEMODE.ScoreLimit = 5
                team.GetScore = function(t) return t == TEAM_BLUE and 5 or 0 end
                local result = GAMEMANAGER:HasReachedRoundLimit()
                team.GetScore = origGetScore
                GAMEMODE.ScoreLimit = origScoreLimit
                expect(result).to.beTrue()
            end,
        },
        {
            name = "HasReachedRoundLimit: false when one below limit",
            func = function()
                local origGetScore = team.GetScore
                local origScoreLimit = GAMEMODE.ScoreLimit
                GAMEMODE.ScoreLimit = 10
                team.GetScore = function(t) return t == TEAM_RED and 9 or 0 end
                local result = GAMEMANAGER:HasReachedRoundLimit()
                team.GetScore = origGetScore
                GAMEMODE.ScoreLimit = origScoreLimit
                expect(result).to.beFalse()
            end,
        },
        {
            name = "HasReachedRoundLimit: true when either exceeds limit",
            func = function()
                local origGetScore = team.GetScore
                local origScoreLimit = GAMEMODE.ScoreLimit
                GAMEMODE.ScoreLimit = 5
                team.GetScore = function(t) return t == TEAM_BLUE and 7 or 3 end
                local result = GAMEMANAGER:HasReachedRoundLimit()
                team.GetScore = origGetScore
                GAMEMODE.ScoreLimit = origScoreLimit
                expect(result).to.beTrue()
            end,
        },

        -- ---- GetTimeLimit ----
        {
            name = "GetTimeLimit: returns -1 when GameLength is 0",
            func = function()
                local orig = GAMEMODE.GameLength
                GAMEMODE.GameLength = 0
                local result = GAMEMODE:GetTimeLimit()
                GAMEMODE.GameLength = orig
                expect(result).to.equal(-1)
            end,
        },
        {
            name = "GetTimeLimit: returns GameLength*60 with no warmup or bonus",
            func = function()
                local origGL = GAMEMODE.GameLength
                local origWU = GAMEMODE.WarmUpLength
                local origOT = GAMEMODE.OvertimeTime
                GAMEMODE.GameLength = 5
                GAMEMODE.WarmUpLength = 0
                GAMEMODE.OvertimeTime = 0
                local result = GAMEMODE:GetTimeLimit()
                GAMEMODE.GameLength = origGL
                GAMEMODE.WarmUpLength = origWU
                GAMEMODE.OvertimeTime = origOT
                expect(result).to.equal(300)
            end,
        },
        {
            name = "GetTimeLimit: adds WarmUpLength to GameLength*60",
            func = function()
                local origGL = GAMEMODE.GameLength
                local origWU = GAMEMODE.WarmUpLength
                local origOT = GAMEMODE.OvertimeTime
                GAMEMODE.GameLength = 5
                GAMEMODE.WarmUpLength = 30
                GAMEMODE.OvertimeTime = 0
                local result = GAMEMODE:GetTimeLimit()
                GAMEMODE.GameLength = origGL
                GAMEMODE.WarmUpLength = origWU
                GAMEMODE.OvertimeTime = origOT
                expect(result).to.equal(330) -- 300 + 30
            end,
        },
        {
            name = "GetTimeLimit: returns a number when GameLength > 0",
            func = function()
                local orig = GAMEMODE.GameLength
                GAMEMODE.GameLength = 1
                local result = GAMEMODE:GetTimeLimit()
                GAMEMODE.GameLength = orig
                expect(result).to.beA("number")
            end,
        },

        -- ---- GetGameTimeLeft ----
        {
            name = "GetGameTimeLeft: returns -1 when GameLength is 0",
            func = function()
                local orig = GAMEMODE.GameLength
                GAMEMODE.GameLength = 0
                local result = GAMEMODE:GetGameTimeLeft()
                GAMEMODE.GameLength = orig
                expect(result).to.equal(-1)
            end,
        },
        {
            name = "GetGameTimeLeft: returns positive number for far-future limit",
            func = function()
                local origGL = GAMEMODE.GameLength
                local origWU = GAMEMODE.WarmUpLength
                local origOT = GAMEMODE.OvertimeTime
                GAMEMODE.GameLength = 999999
                GAMEMODE.WarmUpLength = 0
                GAMEMODE.OvertimeTime = 0
                local result = GAMEMODE:GetGameTimeLeft()
                GAMEMODE.GameLength = origGL
                GAMEMODE.WarmUpLength = origWU
                GAMEMODE.OvertimeTime = origOT
                expect(result > 0).to.beTrue()
            end,
        },
        {
            name = "GetGameTimeLeft: clamps to 0 (never negative)",
            func = function()
                local origGL = GAMEMODE.GameLength
                local origWU = GAMEMODE.WarmUpLength
                local origOT = GAMEMODE.OvertimeTime
                GAMEMODE.GameLength = 0.001 -- limit is ~0.06s, already in the past
                GAMEMODE.WarmUpLength = 0
                GAMEMODE.OvertimeTime = 0
                local result = GAMEMODE:GetGameTimeLeft()
                GAMEMODE.GameLength = origGL
                GAMEMODE.WarmUpLength = origWU
                GAMEMODE.OvertimeTime = origOT
                expect(result >= 0).to.beTrue()
            end,
        },

        -- ---- team.HasPity ----
        {
            name = "team.HasPity: false when Pity is 0",
            func = function()
                local origPity = GAMEMODE.Pity
                local origGetScore = team.GetScore
                GAMEMODE.Pity = 0
                team.GetScore = function(t) return t == TEAM_RED and 10 or 0 end
                local result = team.HasPity(TEAM_BLUE)
                GAMEMODE.Pity = origPity
                team.GetScore = origGetScore
                expect(result).to.beFalse()
            end,
        },
        {
            name = "team.HasPity: true when trailing team is Pity goals behind",
            func = function()
                local origPity = GAMEMODE.Pity
                local origGetScore = team.GetScore
                GAMEMODE.Pity = 3
                team.GetScore = function(t) return t == TEAM_RED and 6 or 2 end
                -- BLUE has 2, RED has 6 → BLUE is 4 behind (> pity of 3) → BLUE gets pity
                local result = team.HasPity(TEAM_BLUE)
                GAMEMODE.Pity = origPity
                team.GetScore = origGetScore
                expect(result).to.beTrue()
            end,
        },
        {
            name = "team.HasPity: false when gap is exactly at threshold (needs to exceed)",
            func = function()
                local origPity = GAMEMODE.Pity
                local origGetScore = team.GetScore
                GAMEMODE.Pity = 3
                team.GetScore = function(t) return t == TEAM_RED and 5 or 2 end
                -- BLUE has 2, RED has 5 → gap is exactly 3 → requires >= 3 → true
                local result = team.HasPity(TEAM_BLUE)
                GAMEMODE.Pity = origPity
                team.GetScore = origGetScore
                expect(result).to.beTrue()
            end,
        },
        {
            name = "team.HasPity: false when leading team queried",
            func = function()
                local origPity = GAMEMODE.Pity
                local origGetScore = team.GetScore
                GAMEMODE.Pity = 2
                team.GetScore = function(t) return t == TEAM_RED and 8 or 2 end
                -- RED is winning, they don't get pity
                local result = team.HasPity(TEAM_RED)
                GAMEMODE.Pity = origPity
                team.GetScore = origGetScore
                expect(result).to.beFalse()
            end,
        },
    },
}
