-- gamemode/obj_ball.lua
/// MANIFEST LINKS:
/// Mechanics: M-140 (Possession), M-150 (Fumble), M-170 (Hazards)
/// Events: E-220 (PossessionTransfer), E-230 (BallLoose), E-240 (BallReset)
/// Principles: P-080 (Ball Readability), P-950 (Possession Volatility)
/// Scenarios: S-001 (Goal Line Stand), S-011 (Loose Ball Bounce), S-017 (Mid-Air Catch)
-- OOP Ball implementation for EFT
-- See lib/SBOX_MAPPING.lua for full porting reference.
--
-- s&box mapping:
--   class Ball             → public sealed class BallController : Component
--   self.ent               → GameObject (ball IS the component host)
--   ReturnHome()           → [Rpc.Broadcast] void ReturnHome()
--   net.Start/Send         → [Rpc.Owner] with Rpc.FilterInclude for carrier-specific messages
--   ent:GetPhysicsObject() → Rigidbody component on the same GameObject
--   util.Effect(...)       → Scene.CreateObject() with particle/sound components
-- One Ball instance per ball entity in the scene.

---@class Ball : BaseObject
---@field ent Entity The underlying ball entity (ent_ball)
---@field nextUpdateNearestGoal number RealTime() throttle for nearest goal updates
Ball = class("Ball")

--- Construct a new Ball wrapper around an entity.
---@param ent Entity The ball entity to wrap
function Ball:ctor(ent)
    self.ent = ent
    self.nextUpdateNearestGoal = 0
end

---@return boolean valid True if the underlying entity is still valid
function Ball:IsValid()
    return IsValid(self.ent)
end

---@return Vector pos World position of the ball
function Ball:GetPos()
    return self.ent:GetPos()
end

--- Reset the ball to its home position, clear carrier state, play effects.
--- Maps to: C# `[Broadcast] void ReturnHome()`
function Ball:ReturnHome()
    local ent = self.ent
    GAMEMODE.SuppressTimeLimit = nil

    ent:SetCarrier(NULL)
    ent:SetAutoReturn(0)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocityInstantaneous(Vector(0, 0, 0))
    end

    ent.LastCarrierTeam = 0
    ent:SetLastCarrierTeam(0)
    ent:SetWasThrown(false)
    GAMEMODE:LocalSound("eft/ballreset.ogg")

    local effectdata = EffectData()
    effectdata:SetOrigin(ent:GetPos())
    util.Effect("ballreset", effectdata, true, true)

    GAMEMODE:BroadcastAction("Ball", "reset")
    if GameEvents.ReturnBall then GameEvents.ReturnBall:Invoke() end
    gamemode.Call("ReturnBall") -- Keep for legacy hooks
    ent:Input("onreturnhome")
    ent:CallStateFunction("Returned")
    ent:SetState(0)

    effectdata:SetOrigin(ent:GetPos())
    util.Effect("ballreset", effectdata, true, true)
end

--- Update the nearest goal indicator for the current carrier (throttled).
--- Sends a net message to the carrier with the nearest opposing goal position.
function Ball:UpdateNearestGoal()
    local ent = self.ent
    local carrier = ent:GetCarrier()

    if not IsValid(carrier) or RealTime() < self.nextUpdateNearestGoal then return end
    self.nextUpdateNearestGoal = RealTime() + 0.5

    local carrierpos = carrier:GetPos()
    local teamid = GAMEMODE:GetOppositeTeam(carrier:Team())

    local thenearest
    local thenearestdist = math.huge
    for _, goal in pairs(ents.FindByClass("trigger_goal")) do
        if goal.Enabled and goal.m_TeamID == teamid and goal.m_ScoreType ~= 0 then
            local nearest = goal:NearestPoint(carrierpos)
            local dist = nearest:Distance(carrierpos)
            if dist < thenearestdist then
                thenearestdist = dist
                thenearest = nearest
            end
        end
    end

    if thenearest then
        net.Start("eft_nearestgoal")
            net.WriteVector(thenearest)
        net.Send(carrier)
    end
end

--- Check if the ball (carried or physics) should trigger a score.
function Ball:CheckScoring()
    if not GetGlobalBool("InRound", true) or GAMEMODE:IsWarmUp() then return end

    local ent = self.ent
    local carrier = ent:GetCarrier()

    if IsValid(carrier) then
        self:CheckScoringCarrier(carrier)
    else
        self:CheckScoringPhys()
    end
end

--- Check touch-scoring for a carried ball.
---@param carrier Player The player carrying the ball
function Ball:CheckScoringCarrier(carrier)
    local ent = self.ent
    local teamid = GAMEMODE:GetOppositeTeam(carrier:Team())
    local ballpos = ent:GetPos()
    local ballvel = carrier:GetVelocity()
    local ballpredictedpos = ballpos + ballvel
    local balldir = ballvel:GetNormalized()

    for _, goal in pairs(ents.FindByClass("trigger_goal")) do
        if goal.Enabled and goal.m_TeamID == teamid and bit.band(goal.m_ScoreType, SCORETYPE_TOUCH) ~= 0 then
            local nearest = goal:NearestPoint(ballpredictedpos)
            local dist = nearest:Distance(ballpos)
            if (dist <= 300 and balldir:Dot((nearest - ballpos):GetNormalized()) >= 0.85 or dist <= 128) and util.IsVisible(nearest, ballpos) then
                 -- Score logic handled by trigger_goal Touch
                 -- Structure preserved for future SlowTime / prediction logic
            end
        end
    end
end

--- Check throw-scoring for a physics ball (not carried).
function Ball:CheckScoringPhys()
    local ent = self.ent
    local ballvel = ent:GetVelocity()
    if ballvel:Length() <= 100 then return end

    local ballpos = ent:GetPos()
    local ballpredictedpos = ballpos + ballvel
    local balldir = ballvel:GetNormalized()

    for _, goal in pairs(ents.FindByClass("trigger_goal")) do
        if goal.Enabled and bit.band(goal.m_ScoreType, SCORETYPE_THROW) ~= 0 then
            local nearest = goal:NearestPoint(ballpredictedpos)
            local dist = nearest:Distance(ballpos)
            if (dist <= 200 and balldir:Dot((nearest - ballpos):GetNormalized()) >= 0.85 or dist <= 92) and util.IsVisible(nearest, ballpos) then
                 -- Score logic handled by trigger_goal Touch
                 -- Structure preserved for future SlowTime / prediction logic
            end
        end
    end
end
