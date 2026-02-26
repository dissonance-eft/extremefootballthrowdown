-- gamemode/obj_bot.lua
/// MANIFEST LINKS:
/// Mechanics: B-000 (Bots), M-110 (Charge logic)
/// Principles: P-060 (Bot Imperfection), C-005 (Predictive Positioning)
/// Scenarios: S-020 (Bot Positioning), A-001 to A-008 (Archetypes)
-- OOP Bot implementation for EFT
-- See lib/SBOX_MAPPING.lua for full porting reference.
--
-- s&box mapping:
--   class Bot               → public sealed class BotController : Component (host-only)
--   cmd:SetForwardMove      → Input.AnalogMove on bot's connection
--   cmd:SetViewAngles       → setting EyeAngles via component
--   util.TraceLine          → Scene.Trace.Ray(start, end).Run()
--   NavMeshAgent            → s&box built-in NavMeshAgent.MoveTo(pos) for pathfinding
--   Bot personality/state   → [Sync(SyncFlags.FromHost)] properties
-- Each bot Player entity gets one Bot instance via sv_bots.lua
-- AI state machine: IDLE → CHASE_BALL / ATTACK / DEFEND / SWARM → CELEBRATE
-- Personality system affects proximity bias: Rusher, Support, Defender, Clearer

---@class Bot : BaseObject
---@field ply Player The underlying bot Player entity
---@field ready boolean True when bot is initialized
---@field nextThink number CurTime() throttle for Think()
---@field state number Current AI state (Bot.STATE_*)
---@field targetYaw number Desired yaw angle for steering
---@field targetPitch number Desired pitch angle (for throws)
---@field Personality string "Rusher"|"Support"|"Defender"|"Clearer"
---@field tackleSkill number Skill modifier (0.95-1.05)
---@field stuckSince number CurTime() when stuck was first detected (0 = not stuck)
---@field stuckPunchAt number CurTime() when the bot should try punching to unstick
---@field throwCooldown number CurTime() before next throw is allowed
---@field throwState? string "winding"|"hailmary"|"goalshot"|"release"|"countdown"|nil
---@field throwStart? number CurTime() when throw wind-up started
---@field throwDuration? number Duration of throw wind-up
---@field throwTarget? Player Target teammate for a throw pass
---@field throwReleaseTime? number CurTime() when countdown expires (set on "release"→"countdown" transition)
---@field wantJump boolean Flag: press jump this tick
---@field wantPunch boolean Flag: press attack this tick
---@field wantReload boolean Flag: press reload (look back) this tick
---@field jukePhase number Per-bot sinusoidal weave phase offset (0 to 2π)
---@field lastJukeLoopTime number CurTime() cooldown to avoid constant juke looping
---@field celebrateStart? number CurTime() when celebration started
---@field didAct? boolean True if celebration act has been performed
Bot = class("Bot")

-- Static configuration
Bot.TURN_RATE_CRUISE = 3.5    ---@type number Degrees per tick: normal turning
Bot.TURN_RATE_FIRM = 6.0      ---@type number Degrees per tick: fast correction
Bot.TURN_RATE_LAST_RESORT = 10.0 ---@type number Degrees per tick: emergency
Bot.WALL_LOOK_DIST = 600      ---@type number Units: forward ray distance for wall detection
Bot.CHARGE_THRESHOLD = 300     ---@type number Units: distance to enter charge behavior
Bot.CARRIER_WEAVE_AMP = 200    ---@type number Units: lateral weave amplitude when carrying ball
Bot.CARRIER_WEAVE_FREQ = 2.0  ---@type number Hz: weave oscillation frequency
Bot.BODYWALL_SPEED = 120      ---@type number Speed threshold: if below this with enemy ahead, punch
Bot.THROW_RANGE_IDEAL = 800   ---@type number Units: ideal distance to stop and throw at goal
Bot.THROW_RANGE_MAX = 1800    ---@type number Units: max believable throw distance
Bot.THROW_GRAVITY = 600       ---@type number EFT sv_gravity (600 HU/s²)

-- AI States
Bot.STATE_IDLE = 0       ---@type number Standing still / no objective
Bot.STATE_CHASE_BALL = 1 ---@type number Chasing a loose ball
Bot.STATE_CARRIER = 2     ---@type number Carrying ball → run to goal
Bot.STATE_SWARM = 3      ---@type number Teammate has ball → escort/block
Bot.STATE_DEFEND = 4     ---@type number Enemy has ball → intercept/tackle
Bot.STATE_KNOCKED = 5    ---@type number Currently knocked down

-- NOTE: class() calls ctor(), NOT initialize(). Bot:ctor() is at line ~295.
-- Bot:initialize() was dead code with wrong personality types and has been removed.

-- ============================================================================
-- HELPER FUNCTIONS (local, ported from sv_bots.lua)
-- ============================================================================

--- Get the bot's horizontal speed.
---@param bot Player The bot player entity
---@return number speed 2D speed in units/second
local function GetBotSpeed(bot)
    return bot:GetVelocity():Length2D()
end

--- Check if a player is in a knocked-down state.
---@param ply Player Player to check
---@return boolean knocked True if knocked down or getting up
local function IsKnockedDown(ply)
    if not IsValid(ply) then return false end
    local state = ply:GetState()
    return state == STATE_KNOCKEDDOWN or state == STATE_KNOCKEDDOWNTOSTAND
end

--- Calculate an intercept point for chasing a moving target.
---@param botPos Vector Bot's position
---@param targetPos Vector Target's current position
---@param targetVel Vector Target's velocity
---@param botSpeed number Bot's current speed
---@return Vector interceptPoint Predicted intercept position
local function GetInterceptPoint(botPos, targetPos, targetVel, botSpeed)
    local toTarget = targetPos - botPos
    local dist = toTarget:Length2D()
    local tSpeed = targetVel:Length2D()
    
    -- S-020 (Bot Positioning): Predict where the target will be, not where it is.
    -- Simple linear prediction: time = distance / relative_speed
    local predictedTime = dist / math.max(botSpeed, 350) 
    
    -- Cap prediction to avoid running to the moon
    predictedTime = math.Clamp(predictedTime, 0.0, 1.5)
    
    return targetPos + targetVel * predictedTime
end

--- Count enemies along a path within a given radius (for path-blocking analysis).
---@param fromPos Vector Start of path
---@param toPos Vector End of path
---@param enemyTeam number Enemy team index
---@param radius number Perpendicular distance threshold
---@return number count Number of blocking enemies
local function CountEnemiesInPath(fromPos, toPos, enemyTeam, radius)
    local dir = (toPos - fromPos):GetNormalized()
    local dist = fromPos:Distance(toPos)
    local count = 0

    for _, ply in ipairs(team.GetPlayers(enemyTeam)) do
        if IsValid(ply) and ply:Alive() and not IsKnockedDown(ply) then
            local toEnemy = ply:GetPos() - fromPos
            local proj = dir:Dot(toEnemy)
            if proj > 0 and proj < dist then
                local perpDist = (toEnemy - dir * proj):Length2D()
                if perpDist < radius then
                    count = count + 1
                end
            end
        end
    end
    return count
end

--- Find the best teammate to throw the ball to (closer to goal, less blocked).
---@param bot Player The bot carrying the ball
---@param goalPos Vector? Target goal position
---@return Player? bestMate Best teammate for a pass, or nil
local function FindThrowTarget(bot, goalPos)
    if not goalPos then return nil end
    local botPos = bot:GetPos()
    local botTeam = bot:Team()
    local enemyTeam = GAMEMODE:GetOppositeTeam(botTeam)
    local bestMate, bestScore = nil, -1

    for _, ply in ipairs(team.GetPlayers(botTeam)) do
        if IsValid(ply) and ply:Alive() and ply ~= bot and not IsKnockedDown(ply) then
            local matePos = ply:GetPos()
            local mateDist = matePos:Distance(goalPos)
            local myDist = botPos:Distance(goalPos)

            if mateDist < myDist * 0.8 then
                local blocked = CountEnemiesInPath(botPos, matePos, enemyTeam, 150)
                local score = (myDist - mateDist) / myDist
                score = score - blocked * 0.3
                if score > bestScore then
                    bestScore = score
                    bestMate = ply
                end
            end
        end
    end
    return bestMate
end

--- Get detailed goal info for a team: position, scoretype, whether throw-only.
--- Scans trigger_goal entities each call (cheap, <16 entities total on any map).
---@param teamid number Team index to get goals for
---@return table[] goals Array of {pos=Vector, scoretype=number, throwOnly=boolean, touchAllowed=boolean, ent=Entity}
local function GetGoalInfo(teamid)
    local results = {}
    for _, ent in pairs(ents.FindByClass("trigger_goal")) do
        if ent:GetTeamID() == teamid then
            local pos = ent:LocalToWorld(ent:OBBCenter())
            local st = ent.m_ScoreType or SCORETYPE_TOUCH
            table.insert(results, {
                pos = pos,
                scoretype = st,
                throwOnly = (bit.band(st, SCORETYPE_THROW) == SCORETYPE_THROW) and (bit.band(st, SCORETYPE_TOUCH) ~= SCORETYPE_TOUCH),
                touchAllowed = bit.band(st, SCORETYPE_TOUCH) == SCORETYPE_TOUCH,
                throwAllowed = bit.band(st, SCORETYPE_THROW) == SCORETYPE_THROW,
                ent = ent
            })
        end
    end
    return results
end

--- Find the best goal to target for the bot (nearest that accepts the given method).
---@param botPos Vector Bot's position
---@param teamid number Enemy team (goals belong to the enemy team for scoring)
---@param preferThrow boolean If true, prefer throw-capable goals; otherwise prefer touchable
---@return table? bestGoal Best goal info table, or nil
local function FindBestGoal(botPos, teamid, preferThrow)
    local goals = GetGoalInfo(teamid)
    local best, bestDist = nil, math.huge
    for _, g in ipairs(goals) do
        -- If we prefer throw, only consider throw-capable goals
        -- If we prefer touch, consider touch-capable goals first
        local acceptable = preferThrow and g.throwAllowed or (not preferThrow and g.touchAllowed)
        if not acceptable then
            -- Fallback: accept any goal
            acceptable = true
        end
        if acceptable then
            local dist = botPos:Distance(g.pos)
            if dist < bestDist then
                bestDist = dist
                best = g
            end
        end
    end
    return best
end

--- Check if ALL goals for a team are throw-only (no touch scoring allowed).
---@param teamid number Team whose goals to check (enemy team for attacking bot)
---@return boolean allThrowOnly True if every goal requires a throw to score
local function AreGoalsThrowOnly(teamid)
    local goals = GetGoalInfo(teamid)
    if #goals == 0 then return false end
    for _, g in ipairs(goals) do
        if g.touchAllowed then return false end
    end
    return true
end

--- Calculate the pitch angle needed for a parabolic throw to hit a target.
--- Uses the same physics model as throw.lua: pos(t) = start + aim*force*t, z -= 300*t²
--- Solves for the pitch that lands the ball at the target position.
---@param fromPos Vector Throw origin (bot's shoot position)
---@param toPos Vector Target position (goal center)
---@param throwForce number Total throw force (default ~1100)
---@param preferHighArc boolean? If true, prefer the high lob arc (theta2)
---@return number? pitch Pitch angle in degrees (negative = up), or nil if impossible
---@return number? flightTime Estimated flight time in seconds
local function CalcThrowPitch(fromPos, toPos, throwForce, preferHighArc)
    local dx = math.sqrt((toPos.x - fromPos.x)^2 + (toPos.y - fromPos.y)^2) -- horizontal distance
    local dz = toPos.z - fromPos.z -- height difference (positive = target above us)
    local g = Bot.THROW_GRAVITY -- 600 HU/s² (EFT sv_gravity)
    local v = throwForce -- total velocity magnitude
    
    if dx < 1 then
        -- Directly below/above: throw straight up
        return dz > 0 and -89 or -45, 0.5
    end
    
    -- Projectile motion:
    -- horizontal: dx = v * cos(theta) * t  →  t = dx / (v * cos(theta))
    -- vertical:   dz = v * sin(theta) * t - g * t²
    -- Substituting t:
    --   dz = dx * tan(theta) - g * dx² / (2 * v² * cos²(theta))
    -- Using identity: 1/cos²(theta) = 1 + tan²(theta), let u = tan(theta):
    --   dz = dx * u - (g * dx²) / (2 * v²) * (1 + u²)
    -- Rearranging into quadratic in u:
    --   (g*dx²/(2v²)) * u² - dx * u + (g*dx²/(2v²) + dz) = 0
    
    local a = (g * dx * dx) / (2 * v * v)
    local b = -dx
    local c = a + dz
    
    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        -- Target is out of range; use max loft
        return -60, nil
    end
    
    local sqrtDisc = math.sqrt(discriminant)
    -- Two solutions: low arc and high arc. We want the LOW arc (more direct, faster arrival)
    local u1 = (-b - sqrtDisc) / (2 * a) -- low arc
    local u2 = (-b + sqrtDisc) / (2 * a) -- high arc
    
    -- Convert tan(theta) back to angle
    local theta1 = math.deg(math.atan(u1)) -- low arc angle
    local theta2 = math.deg(math.atan(u2)) -- high arc angle
    
    -- Pick the better arc: prefer low arc if reasonable, fallback to high arc for elevated targets
    local pitch
    if dz > 100 or preferHighArc then
        -- Target is elevated or we explicitly want a high lob
        pitch = -theta2
    else
        -- Use low arc for speed
        pitch = -theta1
    end
    
    -- Clamp to sane values
    pitch = math.Clamp(pitch, -85, -10)
    
    -- Estimate flight time from the chosen arc
    local cosTheta = math.cos(math.rad(-pitch))
    local flightTime = (cosTheta > 0.01) and (dx / (v * cosTheta)) or 1.0
    
    return pitch, flightTime
end

--- Get this bot's proximity rank to a target (1 = closest on team).
--- Personality modifies effective distance: Rushers get -300, Defenders get +300.
---@param bot Bot|Player The bot (Bot instance uses self.ply in callers)
---@param targetPos Vector Position to rank distance to
---@return number rank 1-based proximity rank (1 = closest)
---@return number total Total players on team
local function GetProximityRank(bot, targetPos)
    local botPos = bot:GetPos()
    local myDist = botPos:Distance(targetPos)

    if bot.Personality == "Rusher" then myDist = myDist - 300
    elseif bot.Personality == "Defender" then myDist = myDist + 300 end

    local rank = 1
    local total = 1

    for _, ply in ipairs(team.GetPlayers(bot:Team())) do
        if IsValid(ply) and ply:Alive() and ply ~= bot then
            total = total + 1
            local theirDist = ply:GetPos():Distance(targetPos)

            if ply.Personality == "Rusher" then theirDist = theirDist - 300
            elseif ply.Personality == "Defender" then theirDist = theirDist + 300 end

            if theirDist < myDist then
                rank = rank + 1
            end
        end
    end

    return rank, total
end

--- Find the nearest enemy player within optional range.
---@param bot Player The bot to search from
---@param maxRange? number Maximum search range in units
---@return Player? nearest Nearest enemy, or nil
---@return number distance Distance to nearest enemy
local function GetNearestEnemy(bot, maxRange)
    local nearest = nil
    local nearestDist = maxRange and (maxRange * maxRange) or math.huge
    local botPos = bot:GetPos()
    local enemyTeam = GAMEMODE:GetOppositeTeam(bot:Team())

    for _, ply in ipairs(team.GetPlayers(enemyTeam)) do
        if IsValid(ply) and ply:Alive() then
            local dist = botPos:DistToSqr(ply:GetPos())
            if dist < nearestDist then
                nearest = ply
                nearestDist = dist
            end
        end
    end
    return nearest, math.sqrt(nearestDist)
end

--- Find the best jump pad (trigger_abspush) that's roughly on the path to a goal.
--- Only returns pads that push players and are between the bot and the goal.
---@param botPos Vector Bot's current position
---@param goalPos Vector Target goal position
---@param maxDetour number Maximum perpendicular detour distance to consider a pad
---@return Vector? padCenter Center of the best jump pad, or nil
local function FindBestJumpPad(botPos, goalPos, maxDetour)
    local toGoal = goalPos - botPos
    local toGoalDir = toGoal:GetNormalized()
    local goalDist = toGoal:Length2D()

    local bestPad = nil
    local bestScore = 0

    local candidates = {}
    table.Add(candidates, ents.FindByClass("trigger_abspush"))
    table.Add(candidates, ents.FindByClass("trigger_jumppad"))

    for _, ent in ipairs(candidates) do
        if IsValid(ent) and ent:GetEnabled() and ent:GetPushPlayers() then
            local padPos = ent:LocalToWorld(ent:OBBCenter())
            local toPad = padPos - botPos
            local proj = toGoalDir:Dot(toPad) -- How far along our path this pad is

            -- Pad must be ahead of us (proj > 0) and not past the goal
            if proj > 100 and proj < goalDist * 0.8 then
                local perpDist = (toPad - toGoalDir * proj):Length2D()
                if perpDist < maxDetour then
                    -- Score: prefer pads that are more on-path (low perp) and reasonably ahead
                    local score = (1 - perpDist / maxDetour) * (proj / goalDist)
                    if score > bestScore then
                        bestScore = score
                        bestPad = padPos
                    end
                end
            end
        end
    end

    return bestPad
end

-- ============================================================================
-- BOT CLASS METHODS
-- ============================================================================

--- Construct a new Bot AI controller for a player entity.
--- Maps to: C# `protected override void OnStart()` on BotController component
---@param ply Player The bot player entity to control
function Bot:ctor(ply)
    self.ply = ply
    self.ready = true
    self.nextThink = CurTime()
    self.state = Bot.STATE_IDLE
    self.targetYaw = ply:EyeAngles().y
    self.Personality = table.Random({"Rusher", "Rusher", "Support", "Support", "Defender", "Clearer"})
    self.tackleSkill = math.Rand(0.95, 1.05)

    -- Sync personality to entity (read by proximity ranking for human players too)
    ply.Personality = self.Personality

    -- Runtime state
    self.stuckSince = 0
    self.stuckPunchAt = 0
    self.throwCooldown = 0
    self.punchReactAt = 0 -- Delayed reaction for body-wall punches

    -- Carrier movement: weave phase offset per bot (unique sinusoidal pattern)
    self.jukePhase = math.random() * math.pi * 2
    -- Juke loop: cooldown to avoid constant looping
    self.lastJukeLoopTime = 0

    print("[Bot] Created " .. ply:Nick() .. " (" .. self.Personality .. ")")
end

---@return boolean valid True if the underlying player entity is still valid
function Bot:IsValid()
    return IsValid(self.ply)
end

---@return number teamId The bot's team index
function Bot:Team()
    return self.ply:Team()
end

---@return string name The bot's display name
function Bot:Name()
    return self.ply:Name()
end
Bot.Nick = Bot.Name

---@return Vector pos The bot's world position
function Bot:GetPos()
    return self.ply:GetPos()
end

--- Main AI think loop (throttled by skill level).
--- Maps to: C# `protected override void OnUpdate()`
function Bot:Think()
    if not self:IsValid() or not self.ply:Alive() then return end

    -- During preround, post-round, or warmup: dance, no AI
    local isIdle = self.ply:GetState() == STATE_PREROUND
                   or (not GAMEMODE:InRound() and not GAMEMODE:IsWarmUp())
                   or GAMEMODE:IsWarmUp()
    if isIdle then
        self.state = Bot.STATE_IDLE
        if not self.nextDanceTime or CurTime() >= self.nextDanceTime then
            -- Force a taunt animation directly (ConCommand 'act' is sandbox-only)
            local seqs = {"taunt_robot", "taunt_dance", "taunt_muscle", "taunt_laugh",
                          "taunt_cheer", "taunt_persistence", "taunt_zombie"}
            local seq = self.ply:LookupSequence(table.Random(seqs))
            if seq and seq > 0 then
                self.ply:SetSequence(seq)
                self.ply:SetPlaybackRate(1)
                self.ply:ResetSequenceInfo()
            end
            self.nextDanceTime = CurTime() + 3 + math.random() * 2
        end
        return
    else
        self.nextDanceTime = nil
    end

    -- Throttle thinking based on skill
    if CurTime() < self.nextThink then return end
    local thinkRate = 0.15 / GetConVar("eft_bots_skill"):GetFloat()
    self.nextThink = CurTime() + thinkRate * (0.7 + math.random() * 0.6)

    self:DecideState()
    self:ExecuteState()
    self:ApplyMovement()
    
    if GetConVar("eft_dev"):GetBool() then
        self:Debug()
    end
end

--- Visual Debugging (server-side overlays, visible when eft_dev 1)
--- Shows: AI state, personality, speed, carrier status, target direction, goal lines
function Bot:Debug()
    local botPos = self.ply:GetPos() + Vector(0,0,72)
    local stateNames = {
        [Bot.STATE_IDLE] = "IDLE",
        [Bot.STATE_CHASE_BALL] = "CHASE",
        [Bot.STATE_CARRIER] = "CARRIER",
        [Bot.STATE_SWARM] = "SWARM",
        [Bot.STATE_DEFEND] = "DEFEND",
        [Bot.STATE_KNOCKED] = "KNOCKED",
    }

    -- State color: green=carrier, red=defend, yellow=chase, blue=swarm, grey=idle
    local stateColors = {
        [Bot.STATE_IDLE] = Color(150, 150, 150),
        [Bot.STATE_CHASE_BALL] = Color(255, 255, 100),
        [Bot.STATE_CARRIER] = Color(100, 255, 100),
        [Bot.STATE_SWARM] = Color(100, 150, 255),
        [Bot.STATE_DEFEND] = Color(255, 100, 100),
        [Bot.STATE_KNOCKED] = Color(150, 80, 80),
    }

    local stateName = stateNames[self.state] or "?"
    local stateCol = stateColors[self.state] or Color(255, 255, 255)
    local speed = math.floor(GetBotSpeed(self.ply))
    local charging = speed >= 300 and self.ply:OnGround()

    -- Line 1: State + personality
    debugoverlay.Text(botPos, stateName .. " [" .. (self.Personality or "?") .. "]", 0.15)

    -- Line 2: Speed + charge indicator
    local speedStr = speed .. " HU/s" .. (charging and " CHARGE" or "")
    debugoverlay.Text(botPos + Vector(0,0,10), speedStr, 0.15)

    -- Line 3: Extra context per state
    if self.throwState then
        debugoverlay.Text(botPos + Vector(0,0,20), "THROW: " .. self.throwState, 0.15)
    end
    if self.stuckSince > 0 then
        local stuckFor = string.format("STUCK %.1fs", CurTime() - self.stuckSince)
        debugoverlay.Text(botPos + Vector(0,0,20), stuckFor, 0.15)
    end

    -- Direction axis (shows where bot wants to face)
    debugoverlay.Axis(self.ply:GetPos(), Angle(0, self.targetYaw, 0), 32, 0.15, true)

    -- State-specific visualizations
    if self.state == Bot.STATE_CARRIER then
        local enemyTeam = GAMEMODE:GetOppositeTeam(self.ply:Team())
        local goalPos = GAMEMODE:GetGoalCenter(enemyTeam)
        if goalPos ~= vector_origin then
            debugoverlay.Cross(goalPos, 32, 0.15, Color(0, 255, 0), true)
            debugoverlay.Line(self.ply:GetPos(), goalPos, 0.15, Color(0, 255, 0), true)
        end
    elseif self.state == Bot.STATE_DEFEND then
        local ball = GAMEMODE:GetBall()
        local carrier = IsValid(ball) and ball:GetCarrier() or nil
        if IsValid(carrier) then
            debugoverlay.Line(self.ply:GetPos(), carrier:GetPos(), 0.15, Color(255, 80, 80), true)
        end
    elseif self.state == Bot.STATE_CHASE_BALL then
        local ball = GAMEMODE:GetBall()
        if IsValid(ball) then
            debugoverlay.Line(self.ply:GetPos(), ball:GetPos(), 0.15, Color(255, 255, 0), true)
        end
    elseif self.state == Bot.STATE_SWARM then
        local ball = GAMEMODE:GetBall()
        local carrier = IsValid(ball) and ball:GetCarrier() or nil
        if IsValid(carrier) then
            debugoverlay.Line(self.ply:GetPos(), carrier:GetPos(), 0.15, Color(80, 120, 255), true)
        end
    end
end

--- Evaluate game state and transition to the appropriate AI state.
function Bot:DecideState()
    local ball = GAMEMODE:GetBall()
    local carrier = IsValid(ball) and ball:GetCarrier() or nil
    local team = self.ply:Team()

    if IsValid(carrier) then
        if carrier == self.ply then
            self.state = Bot.STATE_CARRIER
        elseif carrier:Team() == team then
            self.state = Bot.STATE_SWARM
        else
            self.state = Bot.STATE_DEFEND
        end
    elseif IsValid(ball) then
        self.state = Bot.STATE_CHASE_BALL
    else
        self.state = Bot.STATE_IDLE
    end

    -- Clear throw state if we're no longer the carrier
    if self.state ~= Bot.STATE_CARRIER and self.throwState then
        self.throwState = nil
        self.didThrowSound = nil
    end
end

--- Execute behavior for the current AI state. Sets movement targets and action flags.
function Bot:ExecuteState()
    -- Reset flags (pitch is preserved during throws so the countdown doesn't wipe it)
    self.wantJump = false
    self.wantPunch = false
    self.wantReload = false
    if not self.throwState then
        self.targetPitch = 0
    end

    local bot = self.ply
    local botPos = bot:GetPos()
    local botTeam = bot:Team()
    local enemyTeam = GAMEMODE:GetOppositeTeam(botTeam)
    local botSpeed = GetBotSpeed(bot)
    local curTime = CurTime()

    local attackGoalPos = GAMEMODE:GetGoalCenter(enemyTeam)
    local defenseGoalPos = GAMEMODE:GetGoalCenter(botTeam)
    if attackGoalPos == vector_origin then attackGoalPos = nil end
    if defenseGoalPos == vector_origin then defenseGoalPos = nil end

    -- Stuck check
    self:CheckStuck()

    local ball = GAMEMODE:GetBall()
    local carrier = IsValid(ball) and ball:GetCarrier() or nil

    -- Target position defaults to nil (hold position/use flags only)
    local targetPos = nil

    if self.state == Bot.STATE_CHASE_BALL then
        if IsValid(ball) then
            local myPos = self.ply:GetPos()
            local ballPos = ball:GetPos()
            local ballVel = ball:GetVelocity()

            -- Use intercept prediction when ball is rolling; go straight to it when stationary.
            -- Matches manifest behavior #6 (Angle-cut Intercept) for loose ball.
            if ballVel:Length2D() > 50 then
                targetPos = GetInterceptPoint(myPos, ballPos, ballVel, GetBotSpeed(self.ply))
            else
                targetPos = ballPos
            end

            -- Repulsion fans out approach angles when bots cluster far from the ball,
            -- but fades to zero within 150 HU so nobody overshoots the pickup trigger.
            local distToBall = myPos:Distance(ballPos)
            local repulsionScale = math.Clamp((distToBall - 150) / 400, 0, 1)
            if repulsionScale > 0 then
                local count = 0
                local repulsion = Vector(0, 0, 0)
                for _, teammate in ipairs(team.GetPlayers(self.ply:Team())) do
                    if IsValid(teammate) and teammate ~= self.ply and teammate:Alive() then
                        local distSq = myPos:DistToSqr(teammate:GetPos())
                        if distSq < 22500 then
                            local pushDir = (myPos - teammate:GetPos()):GetNormalized()
                            repulsion = repulsion + pushDir * 120
                            count = count + 1
                        end
                    end
                end
                if count > 0 then targetPos = targetPos + repulsion * repulsionScale end
            end
        end

    elseif self.state == Bot.STATE_CARRIER then
         if attackGoalPos then
            -- === GOAL AWARENESS: Find the actual goal entity and its scoretype ===
            local bestGoal = FindBestGoal(botPos, enemyTeam, false) -- prefer touch first
            local goalIsThrowOnly = bestGoal and bestGoal.throwOnly or false
            local actualGoalPos = bestGoal and bestGoal.pos or attackGoalPos
            local distToGoal = botPos:Distance(actualGoalPos)
            local toGoalDir = (actualGoalPos - botPos):GetNormalized()

            -- If ALL goals are throw-only, switch target to nearest throw-capable goal
            if goalIsThrowOnly or AreGoalsThrowOnly(enemyTeam) then
                local throwGoal = FindBestGoal(botPos, enemyTeam, true)
                if throwGoal then
                    actualGoalPos = throwGoal.pos
                    goalIsThrowOnly = true
                    distToGoal = botPos:Distance(actualGoalPos)
                    toGoalDir = (actualGoalPos - botPos):GetNormalized()
                end
            end

            local blockersInPath = CountEnemiesInPath(botPos, actualGoalPos, enemyTeam, 200)
            local nearestEnemy, nearEnemyDist = GetNearestEnemy(self.ply, 500)

            -- === THROW-ONLY GOAL BEHAVIOR ===
            -- On throw-only maps/goals: run to a firing position, then throw with calculated arc
            if goalIsThrowOnly and self.throwState == nil and curTime > self.throwCooldown then
                local throwRange = Bot.THROW_RANGE_IDEAL
                
                if distToGoal < Bot.THROW_RANGE_MAX then
                    -- Probability-based trigger: chance increases as bot gets closer (P-060)
                    -- At max range (~1800): ~0%. At ideal range (~800): ~42%. At close (~400): ~69%.
                    local throwT = 1 - (distToGoal / Bot.THROW_RANGE_MAX)
                    local throwChance = throwT ^ 1.5

                    if curTime > (self.throwCheckCooldown or 0) then
                        self.throwCheckCooldown = curTime + 0.5 -- re-roll every 0.5s max
                        if math.random() < throwChance then
                            -- Initiate aimed throw at goal
                            local chargeTime = 0.6 + math.random() * 0.4 -- Quick-ish throw
                            local throwPower = math.Clamp(chargeTime, 0, 1.0)
                            local throwForce = 1100 * ((1 + throwPower) / 2)

                            local fromPos = botPos + Vector(0, 0, 64) -- approximate GetShootPos()
                            local calcPitch, flightTime = CalcThrowPitch(fromPos, actualGoalPos, throwForce)

                            if calcPitch then
                                self.throwState = "goalshot"
                                self.throwStart = curTime
                                self.throwDuration = chargeTime
                                self.throwTarget = nil -- Aiming at goal, not a player
                                self.throwCooldown = curTime + 2.0

                                -- Aim at the goal
                                local toGoal2D = (actualGoalPos - botPos)
                                toGoal2D.z = 0
                                self.targetYaw = toGoal2D:Angle().y
                                self.targetPitch = calcPitch

                                -- Add imperfection (P-060)
                                if math.random() < 0.5 then
                                    -- 50% chance for an accurate shot (close to target, minor variance)
                                    self.targetPitch = self.targetPitch + math.Rand(-2.5, 2.5)
                                    self.targetYaw = self.targetYaw + math.Rand(-3.5, 3.5)
                                else
                                    -- 50% chance for a near-miss (off enough to clip edges or sail just past)
                                    self.targetPitch = self.targetPitch + math.Rand(-5, 5)
                                    
                                    local missOffset = math.Rand(5, 12)
                                    if math.random() > 0.5 then
                                        self.targetYaw = self.targetYaw + missOffset
                                    else
                                        self.targetYaw = self.targetYaw - missOffset
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- If we haven't started throwing yet, run to the throw position
                if self.throwState == nil then
                    -- Run toward goal but stop at ideal throw range
                    local stopPos = actualGoalPos - toGoalDir * throwRange
                    stopPos.z = botPos.z -- stay on our ground level
                    targetPos = stopPos
                end
            end

            -- === TOUCH-CAPABLE GOAL: Run it in (original behavior) ===
            if not goalIsThrowOnly and self.throwState == nil then
                -- === CARRIER MOVEMENT: Natural weave instead of strict beeline ===
                if not self.jukePhase then self.jukePhase = math.random() * math.pi * 2 end
                local weaveAmp = Bot.CARRIER_WEAVE_AMP or 80
                local weaveT = curTime * (Bot.CARRIER_WEAVE_FREQ or 1.2) + self.jukePhase
                local lateralOffset = math.sin(weaveT) * weaveAmp
                
                if IsValid(nearestEnemy) and nearEnemyDist < 400 then
                    lateralOffset = lateralOffset * 1.8
                end

                local perpDir = Vector(-toGoalDir.y, toGoalDir.x, 0)
                targetPos = actualGoalPos + perpDir * lateralOffset

                if distToGoal < 300 then
                    -- Run THROUGH the goal, not TO it. Project past center to avoid hesitation.
                    -- trigger_goal is a volume — we need to enter it, not stand at its edge.
                    targetPos = actualGoalPos + toGoalDir * 50
                end
            end

            -- === REACTIVE JUKE: Dodge enemy directly ahead ===
            if IsValid(nearestEnemy) and nearEnemyDist < 250 and not self.throwState then
                local toEnemy = (nearestEnemy:GetPos() - botPos)
                toEnemy.z = 0
                local enemyDot = toGoalDir:Dot(toEnemy:GetNormalized())

                if enemyDot > 0.7 then
                    local dodgeDir = Vector(-toEnemy.y, toEnemy.x, 0):GetNormalized()
                    if bot:EntIndex() % 2 == 0 then dodgeDir = -dodgeDir end
                    targetPos = botPos + toGoalDir * 200 + dodgeDir * 180
                elseif enemyDot < -0.5 then
                    -- Enemy is chasing from behind: look back AND juke hard laterally.
                    -- Alternate direction every ~1.2s, offset by entity index for variety.
                    self.wantReload = true
                    local perpDir = Vector(-toGoalDir.y, toGoalDir.x, 0)
                    local jukeSide = math.floor(curTime * 0.8 + bot:EntIndex() * 0.5) % 2 == 0 and 1 or -1
                    targetPos = botPos + toGoalDir * 300 + perpDir * jukeSide * 320
                else
                     self.wantReload = false
                end
            elseif not self.throwState then
                 self.wantReload = false
            end

            -- === JUMP PAD ROUTING ===
            if not self.throwState and blockersInPath >= 1 and distToGoal > 500 and bot:OnGround() then
                local padPos = FindBestJumpPad(botPos, actualGoalPos, 400)
                if padPos and botPos:Distance(padPos) < 600 then
                    targetPos = padPos
                end
            end

            -- === BODY WALL PUNCH ===
            self.punchReactAt = self.punchReactAt or 0
            if not self.throwState and botSpeed < Bot.BODYWALL_SPEED then
                local wallCount = CountEnemiesInPath(botPos, botPos + toGoalDir * 150, enemyTeam, 80)
                if wallCount >= 1 then
                    if self.punchReactAt == 0 then
                        self.punchReactAt = curTime + 0.25 + math.random() * 0.5
                    elseif curTime >= self.punchReactAt then
                        self.wantPunch = true
                        self.punchReactAt = 0
                    end
                else
                    self.punchReactAt = 0
                end
            end

            -- === HAIL MARY (long-range desperation throw — only on non-throw-only maps) ===
            if not goalIsThrowOnly and distToGoal > 1500 and curTime > self.throwCooldown and self.throwState == nil then
                local nearbyEnemy, nearbyDist = GetNearestEnemy(self.ply, 500)
                if (not IsValid(nearbyEnemy) or nearbyDist > 500) and blockersInPath >= 1 then
                    self.throwState = "hailmary"
                    self.throwStart = curTime
                    self.throwDuration = 1.0
                    self.throwTarget = nil
                    self.throwCooldown = curTime + 4.0

                    self.targetYaw = toGoalDir:Angle().y
                    self.targetPitch = -75
                    targetPos = nil
                end
            end

            -- === THROW PASS (to teammates) ===
            -- Passing should only occur under high pressure, and realistically has a high failure rate (~75% failure)
            -- This models the "1 second vulnerability" of the windup window.
            if not goalIsThrowOnly and not self.wantReload and self.throwState == nil and curTime > self.throwCooldown then
                if blockersInPath >= 2 and distToGoal > 500 then
                    local throwTarget = FindThrowTarget(self.ply, actualGoalPos)
                    if throwTarget then
                        -- 25% chance to actually attempt a pass when the criteria are met
                        if math.random() < 0.25 then
                            self.throwState = "winding"
                            self.throwStart = curTime
                            self.throwDuration = 0.5 + math.random() * 0.7
                            self.throwTarget = throwTarget
                            self.throwCooldown = curTime + 3.0

                            local throwDir = (throwTarget:GetPos() - botPos)
                            throwDir.z = 0
                            if throwDir:LengthSqr() > 1 then
                                self.targetYaw = throwDir:Angle().y
                            end
                        else
                            -- 75% of the time, decide not to pass and put passing on a short cooldown
                            self.throwCooldown = curTime + 1.5
                        end
                    end
                end
            end

            -- === THROW EXECUTION (all throw types) ===
            if self.throwState == "winding" or self.throwState == "hailmary" or self.throwState == "goalshot" then
                -- Stop moving during throw (throw.lua freezes player movement)
                if self.throwState == "hailmary" then
                    targetPos = botPos
                    self.targetPitch = -75
                elseif self.throwState == "goalshot" then
                    targetPos = botPos -- Stand still while aiming at goal
                    -- targetPitch already set by CalcThrowPitch above
                end

                -- Play throw sound
                if not self.didThrowSound then
                    self.didThrowSound = true
                    local throwSounds = self.ply:GetVoiceSet(VOICESET_THROW)
                    if throwSounds and #throwSounds > 0 then
                        self.ply:EmitSound(table.Random(throwSounds))
                    end
                end

                -- Lead-target aiming for directed passes
                if IsValid(self.throwTarget) then
                    local matePos = self.throwTarget:GetPos()
                    local mateVel = self.throwTarget:GetVelocity()
                    local dist = botPos:Distance(matePos)

                    local travelTime = dist / 800
                    local leadPos = matePos + mateVel * travelTime

                    local throwDir = (leadPos - botPos)
                    throwDir.z = 0
                    if throwDir:LengthSqr() > 1 then
                        local windProgress = math.Clamp((curTime - self.throwStart) / self.throwDuration, 0, 1)
                        local finalYaw = throwDir:Angle().y
                        local curveOffset = 25 * (1 - windProgress)
                        if bot:EntIndex() % 2 == 0 then curveOffset = -curveOffset end

                        self.targetYaw = finalYaw + curveOffset

                        -- Use accurate physics arc (High Lob) using exact charge power
                        local throwPower = math.Clamp(self.throwDuration, 0, 1.0)
                        local throwForce = 1100 * ((1 + throwPower) / 2)
                        local calcPitch, _ = CalcThrowPitch(botPos + Vector(0, 0, 64), leadPos, throwForce, true)
                        
                        if calcPitch then
                            self.targetPitch = calcPitch
                        else
                             -- Fallback if out of range
                            self.targetPitch = -45
                        end
                    end
                end

                -- Release check is in BuildCommand (runs every tick) for precise power timing.
            end
        end

    elseif self.state == Bot.STATE_DEFEND then
        if IsValid(carrier) then
            local carrierPos = carrier:GetPos()
            local rank, total = GetProximityRank(self, carrierPos)
            
            -- AGGRESSIVE DEFENSE (S-005, P-060)
            local shouldBlitz = false
            
            -- "Red Zone" Defense Mode: When the carrier is close to the goal, bots "lock in".
            -- All bots blitz fiercely and use much tighter interception logic to mimic humans panic- defending.
            local inRedZone = false
            if defenseGoalPos and carrierPos:Distance(defenseGoalPos) < 1200 then
                inRedZone = true
                shouldBlitz = true -- Everyone blitzes in the Red Zone
            else
                -- Outside Red Zone: use proximity and Personality to decide
                -- Rushers always blitz. Defenders hang back unless they are the absolute closest.
                if self.Personality == "Rusher" then
                    shouldBlitz = true
                elseif self.Personality == "Defender" then
                    shouldBlitz = (rank == 1)
                else
                    shouldBlitz = (rank <= 3) -- Normal bots blitz if they are highly relevant
                end
            end

            if shouldBlitz then
                -- BLITZ: Run straight at them (with intercept) to force a move or tackle
                local carrierVel = carrier:GetVelocity()
                
                if inRedZone then
                    -- Red Zone Intercept: Hyper-accurate. Predict where they are going flawlessly.
                    -- Scale accuracy randomly by tackleSkill (0.95 to 1.05) to still preserve human error
                    local skillMod = self.tackleSkill or 1.0
                    local intercept = GetInterceptPoint(botPos, carrierPos, carrierVel, GetBotSpeed(bot) * skillMod)
                    targetPos = intercept + (intercept - botPos):GetNormalized() * 50
                else
                    -- Standard Intercept: Add a bit of looseness to the chase
                    local intercept = GetInterceptPoint(botPos, carrierPos, carrierVel, GetBotSpeed(bot))
                    targetPos = intercept + (intercept - botPos):GetNormalized() * 50
                end
            else
                -- SUPPORT / CONTAIN: Cut off the path to the goal
                if defenseGoalPos then
                    -- Position ourselves between carrier and goal, but biased towards carrier
                    local toGoal = (defenseGoalPos - carrierPos):GetNormalized()
                    local dist = carrierPos:Distance(defenseGoalPos)
                    
                    -- Drop back distance depends on personality
                    local dropMod = (self.Personality == "Defender") and 0.5 or 0.3
                    local containDist = math.Clamp(dist * dropMod, 150, 400)
                    
                    targetPos = carrierPos + toGoal * containDist
                    
                    -- Spread out slightly so we don't bunch up with other defenders
                    if (bot:EntIndex() + math.floor(CurTime())) % 2 == 0 then
                        targetPos = targetPos + toGoal:Cross(Vector(0,0,1)) * 150
                    else
                        targetPos = targetPos - toGoal:Cross(Vector(0,0,1)) * 150
                    end
                else
                    targetPos = carrierPos -- No goal? Just chase.
                end
            end
            
            -- Jump pad shortcut: if we are far, try to fly in
            if botPos:Distance(targetPos) > 600 and bot:OnGround() and not inRedZone then
                local padPos = FindBestJumpPad(botPos, targetPos, 350)
                if padPos and botPos:Distance(padPos) < 500 then
                    targetPos = padPos
                end
            end

            -- === REACH PUNCH: Immediately punch a nearly-stationary carrier ===
            -- The 0.75s stuck timer never fires against a stationary target (we decelerate
            -- into them without being "stuck"). Short-circuit it: use TargetsContain so
            -- the punch only fires when the hit is physically guaranteed (same trace STATE_PUNCH uses).
            if carrier:GetVelocity():Length2D() < 80 and self.ply:TargetsContain(carrier) then
                self.wantPunch = true
            end
        else
            self.state = Bot.STATE_CHASE_BALL
        end

    elseif self.state == Bot.STATE_SWARM then
         local ball = GAMEMODE:GetBall()
         if IsValid(ball) then
             local carrier = ball:GetCarrier()
             if IsValid(carrier) then
                 local carrierPos = carrier:GetPos()
                 local carrierVel = carrier:GetVelocity()
                 local carrierDir = carrierVel:Length2D() > 50 and carrierVel:GetNormalized() or Vector(1,0,0)

                 -- Intercept Break (The Enforcer)
                 local closestEnemy, closestDist = GetNearestEnemy(carrier, 500)
                 local breaking = false
                 if IsValid(closestEnemy) and closestDist < 300 then
                     targetPos = closestEnemy:GetPos()
                     breaking = true
                 end

                 if not breaking then
                 -- Aggressive Escort: Run AHEAD of the carrier to block/clear path
                 -- Or run to the side if close to goal to offer a pass option
                 
                 local goalDist = carrierPos:Distance(attackGoalPos or vector_origin)
                 
                 if goalDist < 500 then
                     -- Offer pass option near goal (flank)
                     local flankAngle = (bot:EntIndex() % 2 == 0) and 45 or -45
                     local offsetDir = carrierDir:Angle()
                     offsetDir:RotateAroundAxis(Vector(0,0,1), flankAngle)
                     targetPos = carrierPos + offsetDir:Forward() * 300
                 else
                     -- Run Interference: Position 300u ahead of carrier to absorb tackles
                     targetPos = carrierPos + carrierDir * 350
                 end
                 end
              else
                  self.state = Bot.STATE_CHASE_BALL
              end
          end

    elseif self.state == 6 then -- STATE_CELEBRATE
        -- VICTORY LAP + DANCE
        if curTime < (self.celebrateStart or 0) + 1.0 then
            -- Run 1s forward
            targetPos = botPos + bot:GetForward() * 300
        else
            -- Stop and Dance
            targetPos = botPos
            if not self.didAct then
                local acts = {"robot", "dance", "muscle", "laugh", "cheer", "zombie", "bow", "wave"}
                self.ply:ConCommand("act " .. table.Random(acts))
                self.didAct = true
            end
        end
    end

    -- Idle fallback
    if self.state == Bot.STATE_IDLE or not targetPos then
         if IsValid(ball) and ball:GetCarrier() ~= self.ply then
            targetPos = ball:GetPos()
         end
    end

    if targetPos and not self.throwState then
        self:MoveTo(targetPos)
    end
end

--- Detect if the bot is stuck (against walls or players) and set punch/jump flags to escape.
function Bot:CheckStuck()
    local speed = self.ply:GetVelocity():Length2D()
    local onGround = self.ply:OnGround()

    -- Hard stuck: nearly zero speed against geometry
    if speed < 50 and onGround then
        if self.stuckSince == 0 then
            self.stuckSince = CurTime()
        elseif CurTime() > self.stuckSince + 0.75 then
            -- If stuck for > 0.75s, check if it's a player blocking us
            local tr = util.TraceLine({
                start = self.ply:GetPos() + Vector(0,0,40),
                endpos = self.ply:GetPos() + self.ply:GetForward() * 50,
                filter = self.ply
            })
            
            if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
                -- FRIENDLY FIRE CHECK: Only punch if they are NOT on our team
                if tr.Entity:Team() ~= self.ply:Team() then
                    self.wantPunch = true
                end
            end
            
            -- Reset timer to avoid spamming every tick (only punch every 0.75s if still stuck)
            self.stuckSince = 0 
        end
    -- Body wall: moving slowly with enemy blocking ahead (teammates pass through)
    elseif speed < Bot.BODYWALL_SPEED and speed > 10 and onGround then
        local botPos = self.ply:GetPos()
        local botFwd = self.ply:GetForward()
        local enemyTeam = GAMEMODE:GetOppositeTeam(self.ply:Team())

        local blockingCount = 0
        for _, ply in ipairs(team.GetPlayers(enemyTeam)) do
            if IsValid(ply) and ply:Alive() then
                local toEnemy = (ply:GetPos() - botPos)
                local dist = toEnemy:Length2D()
                if dist < 120 then
                    toEnemy:Normalize()
                    if botFwd:Dot(toEnemy) > 0.3 then
                        blockingCount = blockingCount + 1
                    end
                end
            end
        end

        -- Punch to escape body wall (enemy standing in our path, delayed reaction)
        -- Only punch after being blocked for 0.75s to avoid spammy behavior
        if blockingCount >= 1 then
            if self.punchReactAt == 0 then
                self.punchReactAt = CurTime() + 0.75
            elseif CurTime() >= self.punchReactAt then
                self.wantPunch = true
                self.punchReactAt = 0
            end
        else
            self.punchReactAt = 0
        end

        self.stuckSince = 0
    else
        self.stuckSince = 0
    end

end

--- Set targetYaw to face a world position (using NavMesh if available).
---@param targetPos Vector Position to move towards
function Bot:MoveTo(targetPos)
    local waypoint = targetPos
    
    -- Try NavMesh Pathfinding
    if navmesh.IsLoaded() and BotPathfinder then
        local nextPoint = BotPathfinder.GetNextWaypoint(self.ply, targetPos)
        if nextPoint then
            waypoint = nextPoint
            
            -- If NavMesh indicates a jump is needed (vertical link), trigger it
            if self.ply.PathJump then
                self.wantJump = true
            end
        end
    end

    local myPos = self.ply:GetPos()
    local dir = (waypoint - myPos):GetNormalized()
    self.targetYaw = dir:Angle().y
end

--- Detect if there is a low obstacle ahead that we can jump over.
---@param currentYaw number Current facing yaw
---@return boolean canVault True if we should jump
function Bot:DetectJumpableObstacle(currentYaw)
    local botPos = self.ply:GetPos()
    local fwdAng = Angle(0, currentYaw, 0)
    local fwdDir = fwdAng:Forward()
    local checkDist = 70 -- Look slightly ahead

    -- 1. Check waist/chest height (blocked?)
    local trWaist = util.TraceLine({
        start = botPos + Vector(0,0,30),
        endpos = botPos + Vector(0,0,30) + fwdDir * checkDist,
        filter = self.ply,
        mask = MASK_PLAYERSOLID
    })

    local waistBlocked = false
    if trWaist.Hit then
        waistBlocked = true
        local ent = trWaist.Entity
        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ball") then
            waistBlocked = false
        end
    end

    -- 1b. Check Shin/Knee height (blocked?)
    -- Raised to 20 (Step Size is 18). If we hit something below 18, we just walk over it.
    -- If we hit something at 20, it's too tall to walk, so we consider jumping.
    local trShin = util.TraceLine({
        start = botPos + Vector(0,0,20),
        endpos = botPos + Vector(0,0,20) + fwdDir * checkDist,
        filter = self.ply,
        mask = MASK_PLAYERSOLID
    })

    local shinBlocked = false
    if trShin.Hit then
        shinBlocked = true
        local ent = trShin.Entity
        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ball") then
            shinBlocked = false
        end
    end

    if not waistBlocked and not shinBlocked then return false end -- Path is clear

    -- 2. Check head/jump height (clear?)
    -- Check if the space above is clear to jump through
    local trHead = util.TraceLine({
        start = botPos + Vector(0,0,72), -- Lowered slightly to 72 to allow jumping through windows/vents if needed
        endpos = botPos + Vector(0,0,72) + fwdDir * checkDist,
        filter = self.ply,
        mask = MASK_PLAYERSOLID
    })

    if trHead.Hit then return false end -- Obstacle is too tall (e.g. full wall)

    -- 3. Double check the landing spot / World Hit
    -- If the head trace didn't hit anything, but we are about to jump...
    -- make sure we aren't jumping INTO a world brush that was just slightly above the trace
    -- Actually, simpler: if waist/shin was blocked by WORLD, and head is clear, we vault.
    -- BUT if the thing blocking waist/shin is a func_brush or wall that goes up forever, trHead would have hit it.
    -- The issue is likely jumping at high walls where trHead *barely* clears or the bot is too close.
    -- Let's check for world hit explicitly at eye level to be safe.
    local trEye = util.TraceLine({
        start = botPos + Vector(0,0,64),
        endpos = botPos + Vector(0,0,64) + fwdDir * (checkDist + 10),
        filter = self.ply,
        mask = MASK_SOLID_BRUSHONLY
    })
    
    if trEye.HitWorld then return false end

    return true
end

--- Apply wall avoidance and The Curve (P-060) to the current target yaw.
function Bot:ApplyMovement()
    -- During any throw phase, aim must stay locked — wall/pit detection must not redirect it.
    if self.throwState then return end

    -- Punch logic is handled by CheckStuck (0.75s blocked timer).
    -- No proactive punching here — bots only punch when genuinely stuck.
    
    local fwdDir = Angle(0, self.targetYaw, 0):Forward()
    local botPos = self.ply:GetPos()

    -- Gap/Pit Detection (OR NavMesh Jump)
    local shouldJump, avoidPit, gapOffset = self:AnalyzeFloor(self.targetYaw)
    
    if (shouldJump or self.wantJump) and self.ply:OnGround() then
        -- Jump the gap (or NavMesh link)!
        self.wantJump = true
        return -- Skip wall avoidance so we jump straight across
    elseif avoidPit then
        -- Turn away from death pit
        self.targetYaw = self.targetYaw + gapOffset
        return -- Skip wall avoidance to prioritize life
    end

    local wallAhead, wallFraction, wallOffset = self:DetectWalls(self.targetYaw)
    if wallAhead then
        self.targetYaw = self.targetYaw + wallOffset
    else
        -- MANIFEST P-060 (The Curve): If grounded and fast, curve slightly into head-ons
        -- This mimics high-level players turning 1-3 degrees to gain speed (355+)
        if self.ply:OnGround() and GetBotSpeed(self.ply) > 280 then
             -- No wall ahead: apply curve bias
             -- We want to maintain a slight turn (1-2 degrees per tick) to build speed
             -- This bias is randomized per bot (left or right preference)
             if not self.CurveBias then self.CurveBias = (math.random() > 0.5 and 1 or -1) end
             
             -- Only apply if we are generally moving straight (not already turning hard)
             local currentYaw = self.ply:EyeAngles().y
             local diff = math.AngleDifference(self.targetYaw, currentYaw)
             
             if math.abs(diff) < 10 then
                 self.targetYaw = self.targetYaw + self.CurveBias * 5 
             end
        end
    end
end

--- Build the bot's CUserCmd: set view angles, movement, and buttons.
--- Called from StartCommand hook in sv_bots.lua.
---@param cmd CUserCmd The command to populate
function Bot:BuildCommand(cmd)
    if not self:IsValid() or not self.ply:Alive() then return end

    -- During preround: clear all input, don't move or press anything
    if self.ply:GetState() == STATE_PREROUND then
        cmd:ClearMovement()
        cmd:ClearButtons()
        -- Reset stagger time for next round
        self.nextMoveTime = nil
        return
    end

    -- Staggered Start: Random delay to prevent synchronized movement
    if not self.nextMoveTime then
        self.nextMoveTime = CurTime() + math.Rand(0, 2.0)
    end
    
    if CurTime() < self.nextMoveTime then
        cmd:ClearMovement()
        cmd:ClearButtons()
        return
    end

    -- Clear stale input (GMod bot CUserCmds can retain buttons from previous ticks)
    cmd:ClearButtons()
    cmd:ClearMovement()

    -- Sync personality if lost
    if not self.ply.Personality then self.ply.Personality = self.Personality end

    -- 1. TURN
    local currentAng = self.ply:EyeAngles()
    local currentYaw = currentAng.y
    local newPitch = self.targetPitch or 0
    local newYaw

    if self.throwState then
        -- During throw: fast turn toward throw direction (~0.5s to face target)
        newYaw = math.ApproachAngle(currentYaw, self.targetYaw, 12)
    else
        local diff = math.AngleDifference(self.targetYaw, currentYaw)
        local absDiff = math.abs(diff)
        local speed = GetBotSpeed(self.ply)
        
        -- MOMENTUM TURN (P-060 Refined):
        -- If sprinting > 280u/s, cap turn rate to prevent physics braking (GMod friction).
        -- Unless the target is BEHIND us (> 90 deg), then we must brake and turn.
        local turnRate
        
        if speed > 280 and absDiff < 90 then
            -- Wide arc to maintain speed (max ~3 degrees/tick)
            -- This forces the bot to run a curve instead of snapping
            turnRate = 3.0 
        else
            -- Normal turning
            turnRate = Bot.TURN_RATE_CRUISE
            if absDiff > 20 then turnRate = Bot.TURN_RATE_FIRM end
        end
        
        newYaw = math.ApproachAngle(currentYaw, self.targetYaw, turnRate)
    end

    -- Sanitize angles to prevent physics crashes (NaN/Inf)
    if not (newPitch >= -180 and newPitch <= 180) then newPitch = 0 end
    if not (newYaw >= -3600 and newYaw <= 3600) then newYaw = 0 end -- Loose bounds but finite

    local newAng = Angle(newPitch, newYaw, 0)
    
    -- Sanitize to prevent physics crashes
    newAng.p = math.Clamp(newAng.p, -89, 89)
    newAng.y = math.NormalizeAngle(newAng.y)
    newAng.r = 0

    -- NOTE: Removed util.IsValidPhysicsObject() check here.
    -- That function returns false for alive players (they use game movement, not physics objects),
    -- which was silently aborting BuildCommand before any input was applied.

    cmd:SetViewAngles(newAng)
    self.ply:SetEyeAngles(newAng) -- Required for GMod bots

    -- 2. MOVE (Always forward + sprint when not idle, but freeze during throw)
    if self.throwState then
        -- No movement during throw (matches human throw.lua STATE:Move)
    elseif self.state ~= Bot.STATE_IDLE then
         cmd:SetForwardMove(400)
         cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_FORWARD, IN_SPEED))
    end

    -- 3. ACTIONS
    if self.wantJump then 
        cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP)) 
        self.crouchUntil = CurTime() + 0.5
    end
    if (self.crouchUntil or 0) > CurTime() and not self.ply:OnGround() then
        cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_DUCK))
    end
    if self.wantPunch then cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK)) end
    if self.wantReload then cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_RELOAD)) end

    -- 4. THROW INPUT
    -- Lifecycle: "winding"/"hailmary"/"goalshot" → hold IN_ATTACK2 (charges power)
    --            "release"   → release IN_ATTACK2 (throw.lua starts 0.45s countdown)
    --            "countdown" → hold aim for STATE.Time (0.45s) so the ball flies correctly
    if self.throwState == "winding" or self.throwState == "hailmary" or self.throwState == "goalshot" then
        -- Release check runs here every tick (not in ExecuteState's 0.15s throttle) so
        -- chargeTime = throwDuration exactly, matching what was calculated.
        if self.throwStart and CurTime() >= self.throwStart + self.throwDuration then
            self.throwState = "release"
            -- fall through to the "release" branch below on this same tick
        else
            -- Still charging — hold right-click
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK2))
        end
    end
    if self.throwState == "release" then
        -- Release IN_ATTACK2 — throw fires after throw.lua STATE.Time (0.45s) animation.
        -- Transition to "countdown" so ApplyMovement is skipped and targetYaw/targetPitch
        -- are frozen until STATE:Ended actually fires the ball.
        self.throwReleaseTime = CurTime() + 0.5  -- slightly > STATE.Time (0.45s) for safety
        self.throwState = "countdown"
    elseif self.throwState == "countdown" then
        -- Hold aim until the throw animation completes, then resume normal AI
        if CurTime() >= (self.throwReleaseTime or 0) then
            self.throwState = nil
        end
        -- No buttons: IN_ATTACK2 was released on the prior tick
    end
end

-- ============================================================================
-- WALL DETECTION (whisker raycasting)
-- ============================================================================

--- Detect walls ahead using forward + whisker raycasts.
---@param currentYaw number Current facing yaw
---@return boolean wallAhead True if a wall was detected ahead
---@return number fraction Forward trace fraction (1.0 = no wall)
---@return number offsetYaw Suggested yaw offset to avoid the wall
function Bot:DetectWalls(currentYaw)
    local botPos = self.ply:GetPos() + Vector(0, 0, 36) -- Chest height
    local fwdAng = Angle(0, currentYaw, 0)
    local fwdDir = fwdAng:Forward()
    local WALL_LOOK_DIST = Bot.WALL_LOOK_DIST

    local function IsWall(tr)
        if not tr.Hit then return false end
        if tr.HitNormal.z >= 0.7 then return false end -- Walkable slope
        return true
    end

    -- Forward ray
    local trFwd = util.TraceLine({
        start = botPos,
        endpos = botPos + fwdDir * WALL_LOOK_DIST,
        filter = self.ply,
        mask = MASK_SOLID_BRUSHONLY
    })

    if not IsWall(trFwd) then
        return false, 1.0, 0
    end

    -- Wall detected! Cast whisker rays
    local function GetOpenness(tr)
        if not IsWall(tr) then return 1.0 end
        return tr.Fraction
    end

    local WALL_WHISKER_ANGLE = 35
    local leftAng = Angle(0, currentYaw + WALL_WHISKER_ANGLE, 0)
    local rightAng = Angle(0, currentYaw - WALL_WHISKER_ANGLE, 0)

    local trLeft = util.TraceLine({
        start = botPos,
        endpos = botPos + leftAng:Forward() * WALL_LOOK_DIST,
        filter = self.ply,
        mask = MASK_SOLID_BRUSHONLY
    })

    local trRight = util.TraceLine({
        start = botPos,
        endpos = botPos + rightAng:Forward() * WALL_LOOK_DIST,
        filter = self.ply,
        mask = MASK_SOLID_BRUSHONLY
    })

    -- Wide whiskers
    local wideLeftAng = Angle(0, currentYaw + WALL_WHISKER_ANGLE * 2, 0)
    local wideRightAng = Angle(0, currentYaw - WALL_WHISKER_ANGLE * 2, 0)

    local trWideLeft = util.TraceLine({
        start = botPos,
        endpos = botPos + wideLeftAng:Forward() * WALL_LOOK_DIST,
        filter = self.ply,
        mask = MASK_SOLID_BRUSHONLY
    })

    local trWideRight = util.TraceLine({
        start = botPos,
        endpos = botPos + wideRightAng:Forward() * WALL_LOOK_DIST,
        filter = self.ply,
        mask = MASK_SOLID_BRUSHONLY
    })

    local leftScore = GetOpenness(trLeft) + GetOpenness(trWideLeft) * 0.5
    local rightScore = GetOpenness(trRight) + GetOpenness(trWideRight) * 0.5

    local bestOffset
    if leftScore > rightScore then
        bestOffset = WALL_WHISKER_ANGLE * (1.5 - trFwd.Fraction)
    else
        bestOffset = -WALL_WHISKER_ANGLE * (1.5 - trFwd.Fraction)
    end

    if GetOpenness(trLeft) < 0.3 and GetOpenness(trRight) < 0.3 then
        if GetOpenness(trWideLeft) > GetOpenness(trWideRight) then
            bestOffset = WALL_WHISKER_ANGLE * 2.5
        else
            bestOffset = -WALL_WHISKER_ANGLE * 2.5
        end
    end

    return true, trFwd.Fraction, bestOffset
end

-- ============================================================================
-- PIT DETECTION (drop/trigger_hurt avoidance)
-- ============================================================================

--- Detect gaps/pits in the floor ahead and decide if we should jump or turn.
---@param currentYaw number Current facing yaw
---@return boolean shouldJump True if we should jump to clear a gap
---@return boolean avoidPit True if we need to turn to avoid a death pit
---@return number offsetYaw Suggested turn offset
function Bot:AnalyzeFloor(currentYaw)
    local botPos = self.ply:GetPos()

    -- Check if ball is below us (safe to drop)
    local ball = GAMEMODE:GetBall()
    if IsValid(ball) then
        local ballZ = ball:GetPos().z
        if ballZ < botPos.z - 100 then
            return false, false, 0
        end
    end

    local fwdAng = Angle(0, currentYaw, 0)
    local fwdDir = fwdAng:Forward()
    local lookDist = 250 -- Look ahead distance
    local dropLimit = 200 -- Max drop height before considered a "pit"

    local function ScanFloor(dir)
        local scanPos = botPos + dir * lookDist

        -- Trace down to see if there is floor
        local trDown = util.TraceLine({
            start = scanPos + Vector(0,0,10),
            endpos = scanPos - Vector(0,0,dropLimit),
            mask = MASK_SOLID_BRUSHONLY
        })

        -- If we hit nothing, it's a gap/pit
        if not trDown.Hit then 
            -- Now check if there is land FARTHER clearly (jumpable gap)
            local trJumpLand = util.TraceLine({
                start = botPos + dir * (lookDist + 200), -- 450 units total
                endpos = botPos + dir * (lookDist + 200) - Vector(0,0,dropLimit),
                mask = MASK_SOLID_BRUSHONLY
            })
            
            if trJumpLand.Hit then
                -- Gap with landing spot! JUMP!
                return "GAP_JUMPABLE"
            else
                -- Endless void or too far. AVOID.
                return "PIT"
            end
        end

        -- Check for kill triggers
        local trTrigger = util.TraceHull({
            start = scanPos + Vector(0,0,10),
            endpos = scanPos - Vector(0,0,dropLimit),
            mins = Vector(-16,-16,-16),
            maxs = Vector(16,16,16),
            mask = CONTENTS_TRIGGER
        })

        if trTrigger.Hit and IsValid(trTrigger.Entity) then
            local cls = trTrigger.Entity:GetClass()
            if cls == "trigger_hurt" or cls == "trigger_ballreset" or cls == "trigger_kill" then
                return "PIT"
            end
        end

        return "SAFE"
    end

    local status = ScanFloor(fwdDir)
    
    if status == "GAP_JUMPABLE" then
        return true, false, 0 -- JUMP!
    elseif status == "PIT" then
        -- Find safe turn
        local leftAng = Angle(0, currentYaw + 45, 0)
        local rightAng = Angle(0, currentYaw - 45, 0)

        if ScanFloor(leftAng:Forward()) == "SAFE" then return false, true, 45
        elseif ScanFloor(rightAng:Forward()) == "SAFE" then return false, true, -45
        else return false, true, 180 end
    end

    return false, false, 0
end
