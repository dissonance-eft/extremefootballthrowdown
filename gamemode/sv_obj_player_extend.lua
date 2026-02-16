local meta = FindMetaTable("Player")
if not meta then return end

-- Helper to get controller
local function GetController(ply)
	if not ply.Controller then ply.Controller = PlayerController(ply) end
	return ply.Controller
end

function meta:EndState(nocallended)
	GetController(self):EndState(nocallended)
end

local IN_FORWARD = IN_FORWARD
function meta:CanCharge()
	return GetController(self):CanCharge()
end

function meta:FixModelAngles(velocity)
	GetController(self):FixModelAngles(velocity)
end

function meta:RemoveAllStatus(bSilent, bInstant)
	if bInstant then
		for _, ent in pairs(ents.FindByClass("status_*")) do
			if not ent.NoRemoveOnDeath and ent:GetOwner() == self then
				ent:Remove()
			end
		end
	else
		for _, ent in pairs(ents.FindByClass("status_*")) do
			if not ent.NoRemoveOnDeath and ent:GetOwner() == self then
				ent.SilentRemove = bSilent
				ent:SetDie()
			end
		end
	end
end

function meta:RemoveStatus(sType, bSilent, bInstant)
	return GetController(self):RemoveStatus(sType, bSilent, bInstant)
end

function meta:GetStatus(sType)
	return GetController(self):GetStatus(sType)
end

function meta:GiveStatus(sType, fDie)
	return GetController(self):GiveStatus(sType, fDie)
end

function meta:KnockDown(time, knocker)
	GetController(self):KnockDown(time, knocker)
end

function meta:ResetKnockdownImmunity(pl, time)
	GetController(self):ResetKnockdownImmunity(pl, time)
end

function meta:SetKnockdownImmunity(pl, time)
	GetController(self):SetKnockdownImmunity(pl, time)
end

function meta:GetKnockdownImmunity(pl)
	return GetController(self):GetKnockdownImmunity(pl)
end

function meta:ResetChargeImmunity(pl, time)
	GetController(self):ResetChargeImmunity(pl, time)
end

function meta:SetChargeImmunity(pl, time)
	GetController(self):SetChargeImmunity(pl, time)
end

function meta:GetChargeImmunity(pl)
	return GetController(self):GetChargeImmunity(pl)
end

function meta:SetDiveTackleThrowAwayTime(time)
	self.m_DiveTackleThrowAwayTime = time
end

function meta:GetDiveTackleThrowAwayTime()
	return self.m_DiveTackleThrowAwayTime or 0
end

function meta:ChargeLaunch(hitent, knockdown)
	GetController(self):ChargeLaunch(hitent, knockdown)
end

function meta:ChargeHit(hitent, tr)
	GetController(self):ChargeHit(hitent, tr)
end

function meta:PunchHit(hitent, tr)
	GetController(self):PunchHit(hitent, tr)
end

local oldrag = meta.CreateRagdoll
function meta:CreateRagdoll()
	if not IsValid(self:GetRagdollEntity()) then
		oldrag(self)
	end
end
