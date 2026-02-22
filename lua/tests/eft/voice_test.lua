-- EFT Voice Dispatch Test Suite
-- Tests that GetVoiceSet() dispatches to the correct character voice set
-- based on model string matching, and that VOICESET_THROW returns a non-empty
-- sound table for every character rather than silently falling through to the
-- global fallback (the original bug: all chars played male01 headsup via VoiceSets[0]).

-- GetVoiceSet is on the player metatable. We call it through a lightweight mock
-- that provides only GetModel() so the dispatch logic runs without a real entity.
local function MockPlayer(modelPath)
    return setmetatable({}, {
        __index = function(_, key)
            if key == "GetModel" then
                return function() return modelPath end
            end
            -- Forward all other calls to the real player meta so GetVoiceSet is found
            local meta = FindMetaTable("Player")
            return meta and meta[key]
        end
    })
end

return {
    groupName = "Voice Dispatch (GetVoiceSet)",
    cases = {
        -- ---- VOICESET_THROW: each character must resolve a non-empty table ----
        -- If any of these return empty {}, the commit that broke it (before 46f6099)
        -- regressed and we'd be hearing silence or the male01 fallback again.

        {
            name = "barney model gets non-empty VOICESET_THROW",
            func = function()
                local p = MockPlayer("models/player/barney.mdl")
                local sounds = p:GetVoiceSet(VOICESET_THROW)
                expect(sounds).to.exist()
                expect(#sounds > 0).to.beTrue()
            end,
        },
        {
            name = "alyx model gets non-empty VOICESET_THROW",
            func = function()
                local p = MockPlayer("models/player/alyx.mdl")
                local sounds = p:GetVoiceSet(VOICESET_THROW)
                expect(sounds).to.exist()
                expect(#sounds > 0).to.beTrue()
            end,
        },
        {
            name = "male01 model gets non-empty VOICESET_THROW",
            func = function()
                local p = MockPlayer("models/player/group01/male_01.mdl")
                local sounds = p:GetVoiceSet(VOICESET_THROW)
                expect(sounds).to.exist()
                expect(#sounds > 0).to.beTrue()
            end,
        },
        {
            name = "female01 model gets non-empty VOICESET_THROW",
            func = function()
                local p = MockPlayer("models/player/group01/female_01.mdl")
                local sounds = p:GetVoiceSet(VOICESET_THROW)
                expect(sounds).to.exist()
                expect(#sounds > 0).to.beTrue()
            end,
        },
        {
            name = "breen model gets non-empty VOICESET_THROW",
            func = function()
                local p = MockPlayer("models/player/breen.mdl")
                local sounds = p:GetVoiceSet(VOICESET_THROW)
                expect(sounds).to.exist()
                expect(#sounds > 0).to.beTrue()
            end,
        },
        {
            name = "mossman model routes to female voice set (VOICESET_THROW non-empty)",
            func = function()
                local p = MockPlayer("models/player/mossman.mdl")
                local sounds = p:GetVoiceSet(VOICESET_THROW)
                expect(sounds).to.exist()
                expect(#sounds > 0).to.beTrue()
            end,
        },
        {
            name = "unknown model falls back to non-empty VOICESET_THROW (male01 default)",
            func = function()
                local p = MockPlayer("models/player/eli.mdl")
                local sounds = p:GetVoiceSet(VOICESET_THROW)
                expect(sounds).to.exist()
                expect(#sounds > 0).to.beTrue()
            end,
        },

        -- ---- Model string routing: correct character identity ----
        {
            name = "barney in model path routes to barney set (not male01)",
            func = function()
                local barney = MockPlayer("models/player/barney.mdl")
                local male   = MockPlayer("models/player/group01/male_01.mdl")
                -- Both get sounds but from different sets; they should NOT be identical tables
                local bSounds = barney:GetVoiceSet(VOICESET_PAIN_LIGHT)
                local mSounds = male:GetVoiceSet(VOICESET_PAIN_LIGHT)
                expect(bSounds).to.exist()
                expect(mSounds).to.exist()
                expect(bSounds).to.NOT.equal(mSounds)
            end,
        },
        {
            name = "female in model path routes to female set (not male01)",
            func = function()
                local female = MockPlayer("models/player/group01/female_02.mdl")
                local male   = MockPlayer("models/player/group01/male_01.mdl")
                local fSounds = female:GetVoiceSet(VOICESET_PAIN_LIGHT)
                local mSounds = male:GetVoiceSet(VOICESET_PAIN_LIGHT)
                expect(fSounds).to.exist()
                expect(mSounds).to.exist()
                expect(fSounds).to.NOT.equal(mSounds)
            end,
        },

        -- ---- Pain sounds: every character must have all three pain levels ----
        {
            name = "all characters have VOICESET_PAIN_LIGHT",
            func = function()
                local models = {
                    "models/player/barney.mdl",
                    "models/player/alyx.mdl",
                    "models/player/group01/male_01.mdl",
                    "models/player/group01/female_01.mdl",
                    "models/player/breen.mdl",
                }
                for _, mdl in ipairs(models) do
                    local sounds = MockPlayer(mdl):GetVoiceSet(VOICESET_PAIN_LIGHT)
                    expect(#sounds > 0).to.beTrue()
                end
            end,
        },
    },
}
