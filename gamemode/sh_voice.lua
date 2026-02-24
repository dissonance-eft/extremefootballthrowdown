VOICESET_PAIN_LIGHT = 1
/// MANIFEST LINKS:
/// Principles: P-060 (Audio Cues), P-100 (Reversals/Hype), P-080 (Readability)
VOICESET_PAIN_MED = 2
VOICESET_PAIN_HEAVY = 3
VOICESET_DEATH = 4
VOICESET_HAPPY = 5
VOICESET_MAD = 6
VOICESET_TAUNT = 7
VOICESET_TAKEBALL = 8
VOICESET_THROW = 9
VOICESET_OVERHERE = 10

local VoiceSets = {}

VoiceSets[0] = {
	[VOICESET_THROW] = {
		Sound("vo/npc/male01/headsup01.wav"),
		Sound("vo/npc/male01/headsup02.wav")
	}
}

-- ============================================================================
-- VOICE SET DEFINITIONS
-- ============================================================================

-- BARNEY (MALE)
local VS_BARNEY = {
	[VOICESET_PAIN_LIGHT] = { Sound("vo/npc/Barney/ba_pain02.wav"), Sound("vo/npc/Barney/ba_pain07.wav"), Sound("vo/npc/Barney/ba_pain04.wav") },
	[VOICESET_PAIN_MED]   = { Sound("vo/npc/Barney/ba_pain01.wav"), Sound("vo/npc/Barney/ba_pain08.wav"), Sound("vo/npc/Barney/ba_pain10.wav") },
	[VOICESET_PAIN_HEAVY] = { Sound("vo/npc/Barney/ba_pain05.wav"), Sound("vo/npc/Barney/ba_pain06.wav"), Sound("vo/npc/Barney/ba_pain09.wav") },
	[VOICESET_DEATH]      = { Sound("vo/npc/Barney/ba_ohshit03.wav"), Sound("vo/npc/Barney/ba_no01.wav"), Sound("vo/npc/Barney/ba_no02.wav"), Sound("vo/npc/Barney/ba_pain03.wav") },
	[VOICESET_HAPPY]      = { Sound("vo/npc/Barney/ba_gotone.wav"), Sound("vo/npc/Barney/ba_yell.wav"), Sound("vo/npc/Barney/ba_bringiton.wav"), Sound("vo/npc/Barney/ba_laugh01.wav") },
	[VOICESET_MAD]        = { Sound("vo/npc/Barney/ba_damnit.wav"), Sound("vo/npc/Barney/ba_no02.wav"), Sound("vo/npc/Barney/ba_no01.wav"), Sound("vo/Streetwar/rubble/ba_damnitall.wav") },
	[VOICESET_TAUNT]      = { Sound("vo/npc/Barney/ba_yell.wav"), Sound("vo/npc/Barney/ba_downyougo.wav"), Sound("vo/npc/Barney/ba_laugh02.wav"), Sound("vo/npc/Barney/ba_ohyeah.wav") },
	[VOICESET_TAKEBALL]   = { Sound("vo/npc/Barney/ba_letsdoit.wav"), Sound("vo/npc/Barney/ba_letsgo.wav"), Sound("vo/npc/Barney/ba_bringiton.wav") },
	[VOICESET_THROW]      = { Sound("vo/npc/male01/headsup01.wav"), Sound("vo/npc/male01/headsup02.wav") },
	[VOICESET_OVERHERE]   = { Sound("vo/Streetwar/sniper/ba_overhere.wav") }
}

-- ALYX (FEMALE)
local VS_ALYX = {
    [VOICESET_PAIN_LIGHT] = { Sound("vo/npc/Alyx/hurt04.wav"), Sound("vo/npc/Alyx/hurt05.wav"), Sound("vo/npc/Alyx/hurt06.wav") },
    [VOICESET_PAIN_MED]   = { Sound("vo/npc/Alyx/hurt01.wav"), Sound("vo/npc/Alyx/hurt02.wav"), Sound("vo/npc/Alyx/hurt03.wav") },
    [VOICESET_PAIN_HEAVY] = { Sound("vo/npc/Alyx/hurt08.wav"), Sound("vo/npc/Alyx/uggh01.wav"), Sound("vo/npc/Alyx/uggh02.wav") },
    [VOICESET_DEATH]      = { Sound("vo/npc/Alyx/no01.wav"), Sound("vo/npc/Alyx/no02.wav"), Sound("vo/npc/Alyx/no03.wav") },
    [VOICESET_HAPPY]      = { Sound("vo/npc/Alyx/laugh01.wav"), Sound("vo/npc/Alyx/nice.wav"), Sound("vo/npc/Alyx/al_yes.wav") },
    [VOICESET_MAD]        = { Sound("vo/npc/Alyx/dammit01.wav"), Sound("vo/npc/Alyx/dammit02.wav"), Sound("vo/npc/Alyx/what_is_that.wav") },
    [VOICESET_TAUNT]      = { Sound("vo/npc/Alyx/watchout01.wav"), Sound("vo/npc/Alyx/watchout02.wav"), Sound("vo/npc/Alyx/al_excuseme.wav") },
    [VOICESET_TAKEBALL]   = { Sound("vo/npc/Alyx/lets_go_this_way.wav"), Sound("vo/npc/Alyx/ok01.wav") },
    [VOICESET_THROW]      = { Sound("vo/npc/Alyx/headsup01.wav"), Sound("vo/npc/Alyx/headsup02.wav") },
    [VOICESET_OVERHERE]   = { Sound("vo/npc/Alyx/overhere01.wav") }
}

-- MALE01 (STANDARD CITIZEN)
local VS_MALE01 = {
	[VOICESET_PAIN_LIGHT] = { Sound("vo/npc/male01/ow01.wav"), Sound("vo/npc/male01/ow02.wav"), Sound("vo/npc/male01/pain01.wav") },
	[VOICESET_PAIN_MED]   = { Sound("vo/npc/male01/pain04.wav"), Sound("vo/npc/male01/pain05.wav"), Sound("vo/npc/male01/pain06.wav") },
	[VOICESET_PAIN_HEAVY] = { Sound("vo/npc/male01/pain07.wav"), Sound("vo/npc/male01/pain08.wav"), Sound("vo/npc/male01/help01.wav") },
	[VOICESET_DEATH]      = { Sound("vo/npc/male01/no02.wav"), Sound("vo/npc/male01/pain07.wav"), Sound("vo/npc/male01/pain08.wav"), Sound("ambient/voices/citizen_beaten3.wav") },
	[VOICESET_HAPPY]      = { Sound("vo/npc/male01/nice.wav"), Sound("vo/npc/male01/yeah02.wav"), Sound("vo/npc/male01/gotone01.wav") },
	[VOICESET_MAD]        = { Sound("vo/npc/male01/gethellout.wav"), Sound("vo/npc/male01/ohno.wav"), Sound("vo/npc/male01/run01.wav") },
	[VOICESET_TAUNT]      = { Sound("vo/npc/male01/excuseme02.wav"), Sound("vo/npc/male01/overhere01.wav"), Sound("vo/npc/male01/watchout.wav") },
	[VOICESET_TAKEBALL]   = { Sound("vo/npc/male01/ok01.wav"), Sound("vo/npc/male01/ok02.wav"), Sound("vo/npc/male01/letsgo01.wav") },
	[VOICESET_THROW]      = { Sound("vo/npc/male01/headsup01.wav"), Sound("vo/npc/male01/headsup02.wav"), Sound("vo/npc/male01/pain07.wav") },
	[VOICESET_OVERHERE]   = { Sound("vo/npc/male01/overhere01.wav") }
}

-- FEMALE01 (STANDARD CITIZEN)
local VS_FEMALE01 = {
    [VOICESET_PAIN_LIGHT] = { Sound("vo/npc/female01/pain01.wav"), Sound("vo/npc/female01/pain02.wav"), Sound("vo/npc/female01/pain03.wav") },
    [VOICESET_PAIN_MED]   = { Sound("vo/npc/female01/pain04.wav"), Sound("vo/npc/female01/pain05.wav"), Sound("vo/npc/female01/pain06.wav") },
    [VOICESET_PAIN_HEAVY] = { Sound("vo/npc/female01/pain07.wav"), Sound("vo/npc/female01/pain08.wav"), Sound("vo/npc/female01/pain09.wav") },
    [VOICESET_DEATH]      = { Sound("vo/npc/female01/no01.wav"), Sound("vo/npc/female01/no02.wav"), Sound("vo/npc/female01/pain09.wav") },
    [VOICESET_HAPPY]      = { Sound("vo/npc/female01/nice01.wav"), Sound("vo/npc/female01/nice02.wav"), Sound("vo/npc/female01/yeah02.wav") },
    [VOICESET_MAD]        = { Sound("vo/npc/female01/gethellout.wav"), Sound("vo/npc/female01/ohno.wav"), Sound("vo/npc/female01/run01.wav") },
    [VOICESET_TAUNT]      = { Sound("vo/npc/female01/excuseme01.wav"), Sound("vo/npc/female01/excuseme02.wav"), Sound("vo/npc/female01/gethellout.wav") },
    [VOICESET_TAKEBALL]   = { Sound("vo/npc/female01/ok01.wav"), Sound("vo/npc/female01/ok02.wav"), Sound("vo/npc/female01/letsgo01.wav") },
    [VOICESET_THROW]      = { Sound("vo/npc/female01/headsup01.wav"), Sound("vo/npc/female01/headsup02.wav") },
    [VOICESET_OVERHERE]   = { Sound("vo/npc/female01/overhere01.wav") }
}

-- BREEN (MALE)
local VS_BREEN = {
	[VOICESET_PAIN_LIGHT] = { Sound("vo/Citadel/br_no.wav"), Sound("vo/Citadel/br_no.wav") },
	[VOICESET_PAIN_MED]   = { Sound("vo/Citadel/br_no.wav"), Sound("vo/Citadel/br_youfool.wav") },
	[VOICESET_PAIN_HEAVY] = { Sound("vo/Citadel/br_ohshit.wav"), Sound("vo/Citadel/br_failing11.wav") },
	[VOICESET_DEATH]      = { Sound("vo/Citadel/br_failing11.wav"), Sound("vo/Citadel/br_ohshit.wav"), Sound("vo/Citadel/br_youfool.wav") },
	[VOICESET_HAPPY]      = { Sound("vo/Citadel/br_laugh01.wav"), Sound("vo/Citadel/br_gravgun.wav"), Sound("vo/Citadel/br_mock06.wav"), Sound("vo/Citadel/br_mock09.wav"), Sound("vo/Citadel/br_mock13.wav") },
	[VOICESET_MAD]        = { Sound("vo/Citadel/br_no.wav"), Sound("vo/Citadel/br_youfool.wav"), Sound("vo/Citadel/br_mock05.wav") },
	[VOICESET_TAUNT]      = { Sound("vo/Citadel/br_youfool.wav"), Sound("vo/Citadel/br_laugh01.wav"), Sound("vo/Citadel/br_mock09.wav") },
	[VOICESET_TAKEBALL]   = { Sound("vo/Citadel/br_mock06.wav") },
	[VOICESET_THROW]      = { Sound("vo/npc/male01/headsup01.wav"), Sound("vo/npc/male01/headsup02.wav") },
	[VOICESET_OVERHERE]   = { Sound("vo/Citadel/br_mock13.wav") }
}

local meta = FindMetaTable("Player")
if not meta then return end

local empty = {}
function meta:GetVoiceSet(set)
    local model = self:GetModel():lower()
    
    local voiceSet = VS_MALE01 -- Default
    
    if string.find(model, "barney") then
        voiceSet = VS_BARNEY
    elseif string.find(model, "alyx") then
        voiceSet = VS_ALYX
    elseif string.find(model, "breen") then
        voiceSet = VS_BREEN
    elseif string.find(model, "female") or string.find(model, "mossman")
        or string.find(model, "chell") or string.find(model, "_fem") then
        voiceSet = VS_FEMALE01
    end
    
    if voiceSet and voiceSet[set] then return voiceSet[set] end
    if VoiceSets[0][set] then return VoiceSets[0][set] end

	return empty
end

function meta:PlayVoiceSet(set, level, pitch, volume)
	local snd = table.Random(self:GetVoiceSet(set))
	level = level or 80
	pitch = pitch or math.Rand(95, 105)
	volume = volume or 0.8

	if snd then
		self:EmitSound(snd, level, pitch, volume)
	end

	return snd
end

function meta:PlayPainSound()
	if CurTime() < self.NextPainSound then return end

	local snds
	local health = self:Health()
	if 70 <= health then
		snds = VOICESET_PAIN_LIGHT
	elseif 35 <= health then
		snds = VOICESET_PAIN_MED
	else
		snds = VOICESET_PAIN_HEAVY
	end

	snd = self:PlayVoiceSet(snds)

	if snd then
		self.NextPainSound = CurTime() + SoundDuration(snd) - 0.1
	end
end