STATE.ExtraSpeed = 100
/// MANIFEST LINKS:
/// Mechanics: M-120 (Dive Tackle), M-110 (Movement Lock)
/// Principles: P-100 (High Risk/Reward), C-004 (Last-Second Intervention)
STATE.UpwardBoost = 320

function STATE:IsIdle(pl)
	return false
end

function STATE:Started(pl, oldstate)
	--pl:Freeze(true)
	pl:SetStateEntity(NULL)
	pl.DiveGuideAngles = nil

	local ang = pl:EyeAngles()
	ang[1] = 0
	ang[3] = 0

	pl:SetGroundEntity(NULL)
	pl:SetLocalVelocity((pl:GetVelocity():Length() + self.ExtraSpeed) * ang:Forward() + Vector(0, 0, self.UpwardBoost))

	if SERVER then
		local ent = ents.Create("point_divetackletrigger")
		if ent:IsValid() then
			ent:SetOwner(pl)
			ent:SetParent(pl)
			ent:SetPos(pl:GetPos() + pl:GetForward() * 24)
			ent:Spawn()
		end
	end
end

function STATE:Ended(pl, newstate)
	pl:Freeze(false)
	pl.DiveGuideAngles = nil
	pl.LastDiveYaw = nil
	pl.DiveTwist = nil

	-- Clear bone manipulation on CLIENT
	if CLIENT then
		local boneId = pl:LookupBone("ValveBiped.Bip01_Spine2") or pl:LookupBone("ValveBiped.Bip01_Spine1")
		if boneId then
			pl:ManipulateBoneAngles(boneId, Angle(0, 0, 0))
		end
	end

	if SERVER then
		for _, ent in pairs(ents.FindByClass("point_divetackletrigger")) do
			if ent:GetOwner() == pl then
				ent:Remove()
			end
		end
	end

	pl:SetStateEntity(NULL)
end

function STATE:CanPickup(pl, ent)
	return ent == GAMEMODE.Ball and pl:GetStateEntity() == NULL
end

if SERVER then
function STATE:Think(pl)
	if pl:OnGround() or pl:IsSwimming() then
		if pl:IsCarryingBall() then
			pl:EndState()
			pl:SetLocalVelocity(pl:GetVelocity() * 0.5)
		else
			for _, ent in pairs(ents.FindByClass("point_divetackletrigger")) do
				if ent:GetOwner() == pl then
					ent:ProcessTackles()
					return
				end
			end
		--[[else
			local heading = pl:GetVelocity()
			local speed = heading:Length()
			if 200 <= speed then
				heading:Normalize()
				local startpos = pl:GetPos()
				local tr = util.TraceHull({start = startpos, endpos = startpos + speed * FrameTime() * 2 * heading, mask = MASK_PLAYERSOLID, filter = pl:GetTraceFilter(), mins = pl:OBBMins(), maxs = pl:OBBMaxs()})
				if tr.Hit and tr.HitNormal.z < 0.65 and 0 < tr.HitNormal:Length() and not (tr.Entity:IsValid() and tr.Entity:IsPlayer()) then
					pl:KnockDown(3)
				end
			end]]
		end
	end
end
end

function STATE:CalcMainActivity(pl, velocity)
	pl.CalcSeqOverride = pl:LookupSequence("zombie_leap_mid")

	return true
end

function STATE:UpdateAnimation(pl)
	pl:SetPlaybackRate(0)
	pl:SetCycle( (CurTime() - pl:GetStateStart()) * 1.5 % 1 )

	if CLIENT then
		-- Track yaw delta for twist calculation (runs every animation frame)
		local currentYaw = pl:GetAngles().y
		pl.LastDiveYaw = pl.LastDiveYaw or currentYaw
		local yawDelta = math.AngleDifference(currentYaw, pl.LastDiveYaw)
		pl.LastDiveYaw = currentYaw
		
		-- Calculate turn rate → bank angle
		local turnRate = yawDelta / math.max(FrameTime(), 0.001)
		local targetTwist = math.Clamp(turnRate * -0.5, -60, 60)
		
		pl.DiveTwist = Lerp(FrameTime() * 8, pl.DiveTwist or 0, targetTwist)
	end

	return true
end

-- Use bone manipulation to twist only the upper body during the dive.
-- This affects the spine bone so the torso leans while legs stay in the dive pose.
function STATE:BuildBonePositions(pl)
	if not pl.DiveTwist or math.abs(pl.DiveTwist) < 0.5 then return end
	
	local boneId = pl:LookupBone("ValveBiped.Bip01_Spine2")
	if not boneId then
		-- Fallback: try spine1
		boneId = pl:LookupBone("ValveBiped.Bip01_Spine1")
	end
	if not boneId then return end
	
	pl:ManipulateBoneAngles(boneId, Angle(0, 0, pl.DiveTwist))
end

function STATE:PrePlayerDraw(pl)
	-- Nothing needed — bone manipulation handles the twist
end

function STATE:PostPlayerDraw(pl)
	-- Clear bone manipulation so it doesn't persist after draw
	if pl.DiveTwist and math.abs(pl.DiveTwist) >= 0.5 then
		local boneId = pl:LookupBone("ValveBiped.Bip01_Spine2") or pl:LookupBone("ValveBiped.Bip01_Spine1")
		if boneId then
			pl:ManipulateBoneAngles(boneId, Angle(0, 0, 0))
		end
	end
end

-- Limit turn rate to 25% during dive (some control, but no 360 spins)
-- Also disable crouching
function STATE:CreateMove(pl, cmd)
	-- Strip crouch
	local buttons = cmd:GetButtons()
	if bit.band(buttons, IN_DUCK) ~= 0 then
		cmd:SetButtons(bit.band(buttons, bit.bnot(IN_DUCK)))
	end
	
	-- Apply turn rate limiting (Tomahawk logic)
	-- This provides consistent resistance and prevents instant 180 spins
	local currentAng = pl.DiveGuideAngles or cmd:GetViewAngles()
	local desiredAng = cmd:GetViewAngles()
	
	-- Limit turn rate to 90 degrees/second
	local newAng = util.LimitTurning(currentAng, desiredAng, 90, FrameTime())
	
	pl.DiveGuideAngles = newAng
	cmd:SetViewAngles(newAng)

	return true
end
