-- EFT Utility Function Tests
-- Covers pure-logic helpers with no GMod state dependencies.
-- util.ToMinutesSeconds, util.ToMinutesSecondsMilliseconds, GM:GetOppositeTeam

return {
    groupName = "Utility Functions",
    cases = {

        -- ---- util.ToMinutesSeconds ----
        {
            name = "ToMinutesSeconds: 0 -> 00:00",
            func = function()
                expect(util.ToMinutesSeconds(0)).to.equal("00:00")
            end,
        },
        {
            name = "ToMinutesSeconds: 59 -> 00:59",
            func = function()
                expect(util.ToMinutesSeconds(59)).to.equal("00:59")
            end,
        },
        {
            name = "ToMinutesSeconds: 60 -> 01:00",
            func = function()
                expect(util.ToMinutesSeconds(60)).to.equal("01:00")
            end,
        },
        {
            name = "ToMinutesSeconds: 90 -> 01:30",
            func = function()
                expect(util.ToMinutesSeconds(90)).to.equal("01:30")
            end,
        },
        {
            name = "ToMinutesSeconds: 3600 -> 60:00",
            func = function()
                expect(util.ToMinutesSeconds(3600)).to.equal("60:00")
            end,
        },
        {
            name = "ToMinutesSeconds: 3661 -> 61:01",
            func = function()
                expect(util.ToMinutesSeconds(3661)).to.equal("61:01")
            end,
        },

        -- ---- util.ToMinutesSecondsMilliseconds ----
        {
            name = "ToMinutesSecondsMilliseconds: 0 -> 00:00.00",
            func = function()
                expect(util.ToMinutesSecondsMilliseconds(0)).to.equal("00:00.00")
            end,
        },
        {
            name = "ToMinutesSecondsMilliseconds: 0.5 -> 00:00.50",
            func = function()
                expect(util.ToMinutesSecondsMilliseconds(0.5)).to.equal("00:00.50")
            end,
        },
        {
            name = "ToMinutesSecondsMilliseconds: 90.123 -> 01:30.12",
            func = function()
                expect(util.ToMinutesSecondsMilliseconds(90.123)).to.equal("01:30.12")
            end,
        },
        {
            name = "ToMinutesSecondsMilliseconds: 60.99 -> 01:00.99",
            func = function()
                expect(util.ToMinutesSecondsMilliseconds(60.99)).to.equal("01:00.99")
            end,
        },
        {
            name = "ToMinutesSecondsMilliseconds: whole seconds have .00 suffix",
            func = function()
                local result = util.ToMinutesSecondsMilliseconds(45)
                expect(result).to.equal("00:45.00")
            end,
        },

        -- ---- GM:GetOppositeTeam ----
        {
            name = "GetOppositeTeam: RED -> BLUE",
            func = function()
                expect(GAMEMODE:GetOppositeTeam(TEAM_RED)).to.equal(TEAM_BLUE)
            end,
        },
        {
            name = "GetOppositeTeam: BLUE -> RED",
            func = function()
                expect(GAMEMODE:GetOppositeTeam(TEAM_BLUE)).to.equal(TEAM_RED)
            end,
        },
        {
            name = "GetOppositeTeam: unknown id returns itself",
            func = function()
                expect(GAMEMODE:GetOppositeTeam(99)).to.equal(99)
            end,
        },
        {
            name = "GetOppositeTeam: involution (double flip = original)",
            func = function()
                expect(GAMEMODE:GetOppositeTeam(GAMEMODE:GetOppositeTeam(TEAM_RED))).to.equal(TEAM_RED)
                expect(GAMEMODE:GetOppositeTeam(GAMEMODE:GetOppositeTeam(TEAM_BLUE))).to.equal(TEAM_BLUE)
            end,
        },
    },
}
