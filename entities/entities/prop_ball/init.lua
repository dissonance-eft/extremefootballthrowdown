AddCSLuaFile("cl_init.lua")
/// MANIFEST LINKS:
/// Mechanics: M-140 (Possession Base), M-150 (Fumble Physics)
/// Principles: P-080 (Ball Readability)
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.LastCarrierTeam = 0
ENT.LastOnGround = 0
ENT.LastBallOnGround = 0
ENT.WasOnGround = false

function ENT:Initialize()
	self:SetModel("models/Roller.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMass(25)
		phys:EnableMotion(true)
		phys:EnableDrag(false)
		phys:SetDamping(0.01, 0.25)
		phys:SetMaterial("metal")
		phys:Wake()
	end

	local balltrig = ents.Create("prop_balltrigger")
	if balltrig:IsValid() then
		balltrig:SetPos(self:GetPos())
		balltrig:SetAngles(self:GetAngles())
		balltrig:SetOwner(self)
		balltrig:SetParent(self)
		balltrig:Spawn()
		self.BallTrigger = balltrig
	end

	self.LastCarrierTeam = 0

    self.BallLogic = Ball(self)
	gamemode.Call("SetBall", self)
	gamemode.Call("SetBallHome", self:GetPos())
end

local ShuttingDown = false
hook.Add("ShutDown", "nomore", function()
	ShuttingDown = true
end)
if not game.PreBallCleanUpMap then
	game.PreBallCleanUpMap = game.CleanUpMap
	function game.CleanUpMap()
		ShuttingDown = true
		game.PreBallCleanUpMap()
		ShuttingDown = false
	end
end
function ENT:OnRemove()
	-- Don't recreate during shutdown, cleanup, tiebreaker, warmup, or round transitions
	if ShuttingDown or GAMEMODE.TieBreaker then return end
	if not GAMEMODE:InRound() then return end
	if GAMEMODE:IsWarmUp() then return end

	-- craaaaaazzzyyyyy physics
	local ent = ents.Create(self:GetClass())
	if ent:IsValid() then
		ent:SetPos(GAMEMODE:GetBallHome())
		ent:Spawn()
	end
end

function ENT:ReturnHome()
    if self.BallLogic then self.BallLogic:ReturnHome() end
end
ENT.Reset = ENT.ReturnHome

function ENT:Think()
	self:AlignToCarrier()

	local carrier = self:GetCarrier()
	if not carrier:IsValid() or not carrier:Alive() then
		self:SetCarrier(NULL)
	end

	if self:GetAutoReturn() > 0 then
		if carrier:IsValid() then self:SetAutoReturn(0) end
	elseif not carrier:IsValid() then
		self:SetAutoReturn(CurTime() + self.ResetTime)
	end

	if carrier:IsValid() and carrier:OnGround() then
		self.LastOnGround = CurTime()
	end

	if self:OverTimeScoreBall() and self:GetState() ~= BALL_STATE_SCOREBALL then
		local timeleft = GAMEMODE:GetGameTimeLeft() - 0.11
		if timeleft < 0 then
			timeleft = 0
		end
		self:SetState(BALL_STATE_SCOREBALL, timeleft)
	end

	if self:GetAutoReturn() > 0 and CurTime() >= self:GetAutoReturn()
	or self:WaterLevel() > 0 and not self:GetStateTable().NoWaterReturn
	or carrier:IsValid() and (carrier:WaterLevel() >= 2 and not self:GetStateTable().NoWaterReturn or CurTime() >= self.LastOnGround + 20) then -- If a person is in the air 20 seconds or more then they're probably glitching a trigger_push or something.
		self:ReturnHome()
		return
	end

	self:CallStateFunction("Think")

	if self:GetStateEnd() ~= 0 and CurTime() >= self:GetStateEnd() then
		self:SetState(0)
	end

	self:CheckScoring()
	-- Delegate to BallLogic
	if self.BallLogic then 
	    self.BallLogic:CheckScoring()
	    self.BallLogic:UpdateNearestGoal()
	end
	
	self:NextThink(CurTime())
	return true
end

ENT.NextUpdateNearestGoal = 0
function ENT:UpdateNearestGoal()
    -- Logic moved to BallLogic
end

function ENT:CheckScoring()
	-- Logic moved to BallLogic
end



function ENT:PhysicsUpdate(phys)
	phys:Wake()
	self:CallStateFunction("PhysicsUpdate", phys)

	-- Catch assist: thrown balls gently curve toward the nearest player in their flight path
	-- Works for ANY player (teammate or enemy) — this is a catch assist, not a team advantage
	if self:GetWasThrown() and not self:GetCarrier():IsValid() then
		local vel = phys:GetVelocity()
		local speed = vel:Length()

		-- Only guide fast-moving throws (not slow rolling balls)
		if speed > 400 then
			local bestTarget = nil
			local bestDist = 800 -- Search radius
			local myPos = self:GetPos()
			local dir = vel:GetNormalized()
			local lastCarrier = self:GetLastCarrier()

			for _, ply in ipairs(player.GetAll()) do
				if IsValid(ply) and ply:Alive() and ply ~= lastCarrier and not ply:IsCarrying() then
					local plyPos = ply:GetPos() + Vector(0, 0, 48) -- Target upper chest
					local dist = myPos:Distance(plyPos)
					if dist < bestDist then
						local toPly = (plyPos - myPos):GetNormalized()
						local dot = dir:Dot(toPly)
						-- Must already be arcing near them (dot > 0.85 = ~31 degree cone)
						if dot > 0.85 then 
							bestDist = dist
							bestTarget = ply
						end
					end
				end
			end
			
			if IsValid(bestTarget) then
				local toTarget = (bestTarget:GetPos() + Vector(0, 0, 48) - myPos):GetNormalized()
				-- Gently rotate the velocity vector toward the target — preserves speed, looks like a real curve
				local newDir = LerpVector(3.5 * FrameTime(), dir, toTarget):GetNormalized()
				phys:SetVelocityInstantaneous(newDir * speed)
			end
		end
	end
end

function ENT:Touch(ent)
	if self:CallStateFunction("PreTouch", ent) then return end

	if ent:IsPlayer() and not self:GetCarrier():IsValid() and ent:Alive() and not ent:IsCarrying()
	and ent:CallStateFunction("CanPickup", self) and (self:GetLastCarrier() ~= ent or CurTime() > (self.m_PickupImmunity or 0))
	and (ent:Team() ~= self:GetLastCarrierTeam() or CurTime() > (self.m_TeamPickupImmunity or 0)) then
		if team.HasPlayers(ent:Team() == TEAM_RED and TEAM_BLUE or TEAM_RED) or game.SinglePlayer() or game.MaxPlayers() == 1 then
			if ent:IsValid() and ent:IsPlayer() then
				if RecordMatchEvent then
					RecordMatchEvent("possession_gain", ent, { was_thrown = self:GetWasThrown() })
					if self:GetWasThrown() then
						RecordMatchEvent("throw_received", ent)
					end
				end
				self:SetCarrier(ent)
				ent:AddFrags(1)

				--[[if util.Probability(3) then
					ent:PlayVoiceSet(VOICESET_TAUNT)
				end]]
			end
		else
			net.Start("eft_centermsg")
				net.WriteString("You can't take the ball with no one on the other team!")
			net.Send(ent)
		end
	end

	self:CallStateFunction("Touch", ent)
end

function ENT:StartTouch(ent)
	self:CallStateFunction("StartTouch", ent)
end

function ENT:EndTouch(ent)
	self:CallStateFunction("EndTouch", ent)
end

function ENT:Drop(throwforce, suicide)
	self.m_PickupImmunity = CurTime() + 1

	local carrier = self:GetCarrier()
	if carrier:IsValid() then
		self:SetCarrier(NULL)
		if not throwforce and not suicide then
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:Wake()
				phys:SetVelocityInstantaneous(carrier:GetVelocity() * 1.75 + Vector(0, 0, 128))
			end
		end

		if throwforce then
			-- Notification removed by request
			self.m_TeamPickupImmunity = CurTime() + 0.2
		else
			-- Notification removed by request
			if RecordMatchEvent then
				RecordMatchEvent("possession_loss", carrier, { reason = "fumble" })
			end
		end
	end

	if throwforce then
		GAMEMODE.SuppressTimeLimit = CurTime() + 5

		self:SetWasThrown(true)

		self:Input("onthrown", carrier, carrier)
		--self:SetWasDropped(false)

		if carrier:IsValid() then
			if carrier:Team() == TEAM_RED then
				self:Input("onthrownbyred", carrier, carrier)
			elseif carrier:Team() == TEAM_BLUE then
				self:Input("onthrownbyblue", carrier, carrier)
			end
		end
	else
		self:SetWasThrown(false)

		self:Input("ondropped", carrier, carrier)
		--self:SetWasDropped(true)

		if carrier:IsValid() then
			if carrier:Team() == TEAM_RED then
				self:Input("ondroppedbyred", carrier, carrier)
			elseif carrier:Team() == TEAM_BLUE then
				self:Input("ondroppedbyblue", carrier, carrier)
			end
		end
	end

	self:CallStateFunction("Dropped", throwforce, carrier)
end

util.PrecacheSound("npc/turret_floor/click1.wav")
function ENT:PhysicsCollide(data, phys)
	if data.HitNormal.z <= -0.75 and util.TraceLine({start = data.HitPos - data.HitNormal, endpos = data.HitPos + data.HitNormal, filter = self, mask = MASK_SOLID_BRUSHONLY}).HitSky then
		self:ReturnHome()
	elseif not self:CallStateFunction("PhysicsCollide", data, phys) then
		if 30 < data.Speed and 0.2 < data.DeltaTime then
			self:EmitSound("npc/turret_floor/click1.wav")
		end

		local normal = data.OurOldVelocity:GetNormalized()
		phys:SetVelocityInstantaneous(data.Speed * 0.75 * (2 * data.HitNormal * data.HitNormal:Dot(normal * -1) + normal))
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if string.sub(name, 1, 2) == "on" then
		self:FireOutput(name, activator, caller, args)
	end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if string.sub(key, 1, 2) == "on" then
		self:AddOnOutput(key, value)
	end
end

function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)

	if self:GetState() == BALL_STATE_NONE and dmginfo:IsExplosionDamage() and dmginfo:GetDamage() > 10 then
		self:SetState(BALL_STATE_BLITZBALL, 10)
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

--[[function ENT:SetWasDropped(state)
  self:SetDTBool(0, state)
end]]