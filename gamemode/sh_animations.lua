

local ACT_HL2MP_IDLE = ACT_HL2MP_IDLE
local ACT_HL2MP_IDLE_MELEE = ACT_HL2MP_IDLE_MELEE
local ACT_HL2MP_SWIM = ACT_HL2MP_SWIM
local ACT_HL2MP_SWIM_IDLE = ACT_HL2MP_SWIM_IDLE
local ACT_HL2MP_WALK_SUITCASE = ACT_HL2MP_WALK_SUITCASE
local ACT_MP_WALK = ACT_MP_WALK
local ACT_MP_RUN = ACT_MP_RUN
local ACT_HL2MP_RUN_FAST = ACT_HL2MP_RUN_FAST
local ACT_HL2MP_IDLE_MELEE2 = ACT_HL2MP_IDLE_MELEE2
local SPEED_CHARGE_SQR = SPEED_CHARGE_SQR
local SPEED_RUN_SQR = SPEED_RUN_SQR
-- Charge ANIMATION triggers 20 HU/s early (280 vs 300) so the "fast run"
-- look is already fully blended in by the time the actual charge fires at 300.
local SPEED_CHARGE_ANIM_SQR = 280 * 280 -- 78400

function GM:HandlePlayerSwimming(pl, velocity)
	if not pl:IsSwimming() then return false end
/// MANIFEST LINKS:
/// Principles: P-010 (Sport Identity - Foundation)

	if velocity:LengthSqr() > 100 then
		pl.CalcIdeal = ACT_HL2MP_SWIM
	else
		pl.CalcIdeal = ACT_HL2MP_SWIM_IDLE
	end

	return true
end

function GM:CalcMainActivity(pl, velocity)
	pl.CalcIdeal = ACT_HL2MP_IDLE
	pl.CalcSeqOverride = -1

	self:HandlePlayerLanding( pl, velocity, pl.m_bWasOnGround )

	if not ( self:HandlePlayerJumping( pl, velocity ) or self:HandlePlayerDucking( pl, velocity ) or self:HandlePlayerSwimming( pl, velocity ) ) then
		local len2d = velocity:LengthSqr()
		if len2d >= SPEED_CHARGE_ANIM_SQR then
			pl.CalcIdeal = ACT_HL2MP_RUN_FAST
		elseif len2d >= SPEED_RUN_SQR then
			pl.CalcIdeal = pl:IsCarrying() and ACT_HL2MP_RUN_SLAM or ACT_MP_RUN
		elseif len2d >= 1 then
			pl.CalcIdeal = pl:IsCarrying() and ACT_HL2MP_WALK_SLAM or ACT_MP_WALK
		else
			pl.CalcIdeal = pl:IsCarrying() and ACT_HL2MP_IDLE_SLAM or ACT_HL2MP_IDLE
		end
	end

	pl.m_bWasOnGround = pl:IsOnGround()

	if not pl:CallStateFunction("CalcMainActivity", velocity) then
		pl:CallCarryFunction("CalcMainActivity", velocity)
	end

	if not pl:CallStateFunction("TranslateActivity") then
		pl:CallCarryFunction("TranslateActivity")
	end

	return pl.CalcIdeal, pl.CalcSeqOverride
end

function GM:DoAnimationEvent(pl, event, data)
	return pl:CallCarryFunction("DoAnimationEvent", event, data) or pl:CallStateFunction("DoAnimationEvent", event, data) or self.BaseClass.DoAnimationEvent(self, pl, event, data)
end

function GM:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	return pl:CallStateFunction("UpdateAnimation", velocity, maxseqgroundspeed) or pl:CallCarryFunction("UpdateAnimation", velocity, maxseqgroundspeed) or self.BaseClass.UpdateAnimation(self, pl, velocity, maxseqgroundspeed)
end
