/// MANIFEST LINKS:
/// Mechanics: M-120 (Knockdown Recovery)
/// Principles: P-020 (Interaction Frequency), C-002 (Short Possession)
STATE.RecoverTime = 2
function STATE:Started(pl, oldstate)
	pl:ResetJumpPower(0)

	if SERVER then
		pl:SetNoDraw(false)
		pl:DrawShadow(true)
	end
	
	if CLIENT then
		pl:SetNoDraw(false)
		pl:DrawShadow(true)
	end
end

function STATE:Ended(pl, newstate)
	if newstate == STATE_MOVEMENT then
		pl:SetNextMoveVelocity(pl:GetVelocity() + pl:GetStateVector())
	end
end

function STATE:Think(pl)
	-- Force visibility (Aggressive Fix)
	if SERVER or CLIENT then
		pl:SetNoDraw(false)
		pl:DrawShadow(true)
	end
end

-- Ensure we don't block drawing
function STATE:PrePlayerDraw(pl)
	-- Return nil/false allows drawing. Return true prevents it.
	return false 
end

function STATE:IsIdle(pl)
	return false
end

function STATE:Move(pl, move)
	move:SetSideSpeed(0)
	move:SetForwardSpeed(0)
	move:SetMaxSpeed(0)
	move:SetMaxClientSpeed(0)

	return MOVE_STOP
end
