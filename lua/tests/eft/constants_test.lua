-- EFT Constants Test Suite
-- Verifies that runtime constants match MANIFEST.md APPENDIX H values.
-- These are pure-value checks: no entities, no GMod state, always safe to run.

return {
    groupName = "Constants (MANIFEST APPENDIX H)",
    cases = {
        -- ---- Speed constants (sh_globals.lua) ----
        {
            name = "SPEED_CHARGE is 300",
            func = function()
                expect(SPEED_CHARGE).to.equal(300)
            end,
        },
        {
            name = "SPEED_RUN is 150",
            func = function()
                expect(SPEED_RUN).to.equal(150)
            end,
        },
        {
            name = "SPEED_STRAFE is 160",
            func = function()
                expect(SPEED_STRAFE).to.equal(160)
            end,
        },
        {
            name = "SPEED_ATTACK is 100",
            func = function()
                expect(SPEED_ATTACK).to.equal(100)
            end,
        },
        {
            name = "SPEED_THROW equals SPEED_ATTACK",
            func = function()
                expect(SPEED_THROW).to.equal(SPEED_ATTACK)
            end,
        },
        {
            name = "SPEED_CHARGE_SQR is SPEED_CHARGE squared",
            func = function()
                expect(SPEED_CHARGE_SQR).to.equal(SPEED_CHARGE ^ 2)
            end,
        },

        -- ---- Team identifiers (shared.lua) ----
        {
            name = "TEAM_RED is 1",
            func = function()
                expect(TEAM_RED).to.equal(1)
            end,
        },
        {
            name = "TEAM_BLUE is 2",
            func = function()
                expect(TEAM_BLUE).to.equal(2)
            end,
        },
        {
            name = "TEAM_RED and TEAM_BLUE are distinct",
            func = function()
                expect(TEAM_RED).to.NOT.equal(TEAM_BLUE)
            end,
        },

        -- ---- Voiceset constants (sh_voice.lua) ----
        {
            name = "VOICESET_PAIN_LIGHT is 1",
            func = function()
                expect(VOICESET_PAIN_LIGHT).to.equal(1)
            end,
        },
        {
            name = "VOICESET_PAIN_MED is 2",
            func = function()
                expect(VOICESET_PAIN_MED).to.equal(2)
            end,
        },
        {
            name = "VOICESET_PAIN_HEAVY is 3",
            func = function()
                expect(VOICESET_PAIN_HEAVY).to.equal(3)
            end,
        },
        {
            name = "VOICESET_DEATH is 4",
            func = function()
                expect(VOICESET_DEATH).to.equal(4)
            end,
        },
        {
            name = "VOICESET_HAPPY is 5",
            func = function()
                expect(VOICESET_HAPPY).to.equal(5)
            end,
        },
        {
            name = "VOICESET_MAD is 6",
            func = function()
                expect(VOICESET_MAD).to.equal(6)
            end,
        },
        {
            name = "VOICESET_TAUNT is 7",
            func = function()
                expect(VOICESET_TAUNT).to.equal(7)
            end,
        },
        {
            name = "VOICESET_TAKEBALL is 8",
            func = function()
                expect(VOICESET_TAKEBALL).to.equal(8)
            end,
        },
        {
            name = "VOICESET_THROW is 9",
            func = function()
                expect(VOICESET_THROW).to.equal(9)
            end,
        },
        {
            name = "VOICESET_OVERHERE is 10",
            func = function()
                expect(VOICESET_OVERHERE).to.equal(10)
            end,
        },
        {
            name = "All voiceset constants are unique",
            func = function()
                local seen = {}
                local sets = {
                    VOICESET_PAIN_LIGHT, VOICESET_PAIN_MED, VOICESET_PAIN_HEAVY,
                    VOICESET_DEATH, VOICESET_HAPPY, VOICESET_MAD,
                    VOICESET_TAUNT, VOICESET_TAKEBALL, VOICESET_THROW, VOICESET_OVERHERE,
                }
                for _, v in ipairs(sets) do
                    expect(seen[v]).to.NOT.exist()
                    seen[v] = true
                end
            end,
        },

        -- ---- Collision constants (sh_globals.lua) ----
        {
            name = "COLLISION_NORMAL is 0",
            func = function()
                expect(COLLISION_NORMAL).to.equal(0)
            end,
        },
        {
            name = "COLLISION_AVOID is 1",
            func = function()
                expect(COLLISION_AVOID).to.equal(1)
            end,
        },
        {
            name = "COLLISION_PASSTHROUGH is 2",
            func = function()
                expect(COLLISION_PASSTHROUGH).to.equal(2)
            end,
        },
    },
}
