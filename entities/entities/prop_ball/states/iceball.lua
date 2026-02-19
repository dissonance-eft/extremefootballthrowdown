/// MANIFEST LINKS:
/// Mechanics: M-010 (Possession - Ball Types)
STATE.Name = "Ice Ball"

if SERVER then
	function STATE:Start(ball, samestate)
		ball:EmitSound("vehicles/Airboat/pontoon_splash2.wav", 100, 110)

		-- Low-friction physics: reduce damping so the ball slides and rolls freely.
		local phys = ball:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetDamping(0.02, 0.02)       -- nearly no linear/angular damping (default ~0.1 / 0.1)
			phys:SetMaterial("ice")            -- zero-friction surface material
		end
	end

	function STATE:End(ball)
		-- Restore default ball physics on state exit.
		local phys = ball:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetDamping(0.1, 0.1)
			phys:SetMaterial("gmod_silent")   -- restore to whatever the prop_ball uses normally
		end
	end

	-- Low-friction bounce: preserve nearly all horizontal momentum,
	-- give a gentle vertical reflect so it doesn't die on impact.
	function STATE:PhysicsCollide(ball, hitdata, phys)
		local vel = hitdata.OurOldVelocity
		local n   = hitdata.HitNormal

		-- Project velocity onto the surface plane (remove component along normal)
		local normalComponent = n * vel:Dot(n)
		local tangential = vel - normalComponent

		-- Reflect the normal component with a small coefficient of restitution,
		-- keep ~97% of tangential speed so it rolls rather than stopping.
		local reflected = tangential * 0.97 + normalComponent * (-0.25)

		phys:SetVelocityInstantaneous(reflected)
		return true
	end
end

local colBall = Color(0, 255, 255)
function STATE:GetBallColor(ball, carrier)
	return colBall
end

if not CLIENT then return end

-- Shiny pass: draw the model a second time at low blend with bright cyan modulation.
-- models/shiny is a valid VertexLitGeneric model material (ships with GMod, not a sprite).
-- Used as an OVERLAY (not a full override) so the base rollermine texture shows through.
local matShiny     = Material("models/shiny")
local matFrostHalo = Material("sprites/light_glow02_add")
local colFrost     = Color(180, 240, 255)  -- cold blue-white halo

local vecGrav = Vector(0, 0, -400)
function STATE:PostDraw(ball)
	-- Second draw at 40% blend with matShiny → adds specular sheen without hiding the base mesh.
	-- Bright cyan modulation makes the sheen read as ice rather than generic chrome.
	render.SetColorModulation(0.5, 1, 1)
	render.SetBlend(0.25)
	render.ModelMaterialOverride(matShiny)
	ball:DrawModel()
	render.ModelMaterialOverride()
	render.SetBlend(1)
	render.SetColorModulation(1, 1, 1)

	-- Frost halo: slightly larger and colder than the default glow in DefaultDraw.
	local pos  = ball:GetPos()
	local size = 80 + math.sin(CurTime() * 3) * 8  -- gentle pulse
	render.SetMaterial(matFrostHalo)
	render.DrawSprite(pos, size, size, colFrost)

	if CurTime() < ball.NextStateEmit then return end
	ball.NextStateEmit = CurTime() + 0.01

	local carrier = ball:GetCarrier()
	local vel = carrier:IsValid() and carrier:GetVelocity() or ball:GetVelocity()
	local pos = ball:GetPos()

	local emitter = ParticleEmitter(pos)
	emitter:SetNearClip(16, 24)

	local particle = emitter:Add("particle/snow", ball:GetPos())
	particle:SetDieTime(math.Rand(1.7, 2.5))
	particle:SetStartSize(3)
	particle:SetEndSize(0)
	particle:SetStartAlpha(255)
	particle:SetEndAlpha(255)
	particle:SetVelocity(VectorRand():GetNormalized() * math.Rand(100, 228) + vel * 0.8)
	particle:SetAirResistance(100)
	particle:SetGravity(vecGrav)
	particle:SetCollide(true)
	particle:SetBounce(0.1)
	particle:SetRoll(math.Rand(0, 360))
	particle:SetRollDelta(math.Rand(-15, 15))

	emitter:Finish()
end
