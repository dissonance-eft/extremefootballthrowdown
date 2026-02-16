include("shared.lua")

util.PrecacheSound("weapons/physcannon/energy_sing_loop4.wav")

ENT.LerpSpeed = 0

function ENT:Initialize()
	self.PreviousState = self:GetState()

	self.FlySound = CreateSound(self, "weapons/physcannon/energy_sing_loop4.wav")

	gamemode.Call("SetBall", self)
	gamemode.Call("SetBallHome", self:GetPos())
end

function ENT:Think()
	local speed = self:GetVelocity():Length()
	self.LerpSpeed = math.Approach(self.LerpSpeed, speed, FrameTime() * 3500)

	self:AlignToCarrier()
	if self:GetCarrier():IsValid() then
		self.FlySound:Stop()
	else
		self.FlySound:PlayEx(math.Clamp(self.LerpSpeed / 1000, 0.05, 0.9) ^ 0.5, 75 + math.Clamp(self.LerpSpeed / 1500, 0, 1) * 100)
	end

	if self:GetState() ~= self.PreviousState then
		local newstate = self:GetState()
		self:SetState(self.PreviousState)
		self:CallStateFunction("End")
		self:SetState(newstate)
		self:CallStateFunction("Start", false)
		self.PreviousState = newstate
	end

	self:CallStateFunction("Think")

	self:NextThink(CurTime())
	return true
end

function ENT:DrawTranslucent()
	self:AlignToCarrier()

	if not self:CallStateFunction("PreDraw") then
		self:DefaultDraw()
	end

	self:CallStateFunction("PostDraw")
end

ENT.NextEmit = 0
ENT.NextStateEmit = 0
function ENT:CreateSpeedParticles(col)
	-- Only emit when ball is not being carried (in the air/free)
	if self:GetCarrier():IsValid() then return end
	
	-- Emit every frame for smooth trail
	local pos = self:GetPos()
	local vel = self:GetVelocity()

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(24, 32)

	-- Create multiple particles for a denser, smoother trail
	for i = 1, 2 do
		local offset = vel * -0.005 * i
		local particle = emitter:Add("sprites/glow04_noz", pos + offset)
		particle:SetVelocity(Vector(0, 0, 0)) -- Stationary particles form a line
		particle:SetDieTime(0.5)
		particle:SetStartSize(14)
		particle:SetEndSize(2)
		particle:SetStartAlpha(220)
		particle:SetEndAlpha(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetColor(col.r, col.g, col.b)
	end

	emitter:Finish()
end

local matGlow = Material("sprites/light_glow02_add")
local matRing = Material("ball_halo")

function ENT:DefaultDraw()
	local carrier = self:GetCarrier()
	local col = color_white
	
	if IsValid(carrier) then
		-- Ball is being carried: use carrier's team color
		col = team.GetColor(carrier:Team())
	elseif self:GetWasThrown() then
		-- Ball was thrown: retain last carrier's team color
		local lastTeam = self:GetLastCarrierTeam()
		if lastTeam and lastTeam ~= 0 then
			col = team.GetColor(lastTeam)
		end
	end
	-- If dropped (not thrown), col stays white
	
	-- Draw model with team color tint
	render.SetColorModulation(col.r / 255, col.g / 255, col.b / 255)
	self:DrawModel()
	render.SetColorModulation(1, 1, 1)
	
	-- Create particles based on the ball's color
	self:CreateSpeedParticles(col)

    -- Glow effect around the ball
    render.SetMaterial(matGlow)
    local pos = self:GetPos()
    local size = 64 + math.max(0, (math.sin(CurTime() * 8) - 0.25) * 24)
    render.DrawSprite(pos, size, size, col)

    -- Ring effect around the ball
    render.SetMaterial(matRing)
    render.DrawSprite(pos, 33, 33, col)
end
