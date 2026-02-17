-- gamemode/obj_player.lua
/// MANIFEST LINKS:
/// Mechanics: M-110 (Charge), M-120 (Knockdown), M-130 (Head-On Collision)
/// Events: E-210 (TackleResolve), E-250 (PlayerKnockdown)
/// Principles: P-050 (Movement), P-060 (Head-On), P-950 (Collision Density)
/// Scenarios: S-005 (Swarm), S-009 (Speed Duel), S-017 (Mid-Air Catch)
-- OOP Player Controller for EFT
-- Bridges GMod Player meta-table to a class-based system for s&box parity
-- See lib/SBOX_MAPPING.lua for full porting reference.
--
-- s&box mapping:
--   class PlayerController → public sealed partial class EFTPlayerController : Component
--   self.ply               → GameObject (the entity IS the component host)
--   CanCharge()            → bool property with [Sync] for prediction
--   KnockDown/ChargeHit   → [Rpc.Broadcast] methods
--   Immunity tables        → [Sync(SyncFlags.FromHost)] Dictionary or TimeSince per-attacker
--   GetStatus/GiveStatus   → Component queries: GameObject.Components.Get<StatusComponent>()
-- Each GMod Player entity gets one PlayerController instance via sv/cl_obj_player_extend.lua
-- Immunity tables live on the Player entity (reset in PlayerSpawn) — single source of truth.

---@class PlayerController : BaseObject
---@field ply Player The underlying GMod Player entity
PlayerController = class("PlayerController")

--- Construct a new PlayerController wrapping a GMod Player entity.
--- Maps to: C# `protected override void OnStart()` (component init)
---@param ply Player The player entity to wrap
function PlayerController:ctor(ply)
    self.ply = ply
    -- Immunity tables live on the Player entity (reset in PlayerSpawn).
    -- We read/write ply.m_KnockdownImmunity and ply.m_ChargeImmunity directly
    -- so there is only ONE source of truth.
end

--- Check if the underlying player entity is still valid.
--- Maps to: C# `Component.IsValid` / null-check
---@return boolean
function PlayerController:IsValid()
    return IsValid(self.ply)
end

-- ============================================================================
-- SHARED LOGIC
-- ============================================================================

local IN_FORWARD = IN_FORWARD

--- Can this player enter charging state?
--- Shared prediction: CLIENT skips IN_FORWARD check for non-local players (bots don't replicate buttons).
--- Maps to: C# `bool CanCharge` property on PlayerController component
---@return boolean
function PlayerController:CanCharge()
    local ply = self.ply
    return ply:GetState() == STATE_NONE and ply:GetStateInteger() == 0
    and ply:OnGround() and not ply:Crouching() and not ply:IsCarrying() and ply:WaterLevel() <= 1
    and (CLIENT and LocalPlayer() ~= ply or ply:KeyDown(IN_FORWARD))
    and ply:GetVelocity():LengthSqr() >= SPEED_CHARGE_SQR
end

--- Orient the player model to match eye angles and set movement pose parameter.
--- Both SetLocalAngles (animation resolver) and SetRenderAngles (visual) needed on CLIENT.
--- Maps to: C# `Transform.Rotation` + `AnimationHelper.MoveYaw`
---@param velocity Vector The player's current velocity
function PlayerController:FixModelAngles(velocity)
    local ply = self.ply
    local eye = ply:EyeAngles()
    ply:SetLocalAngles(eye)
    if CLIENT then
        ply:SetRenderAngles(eye)
    end
    ply:SetPoseParameter("move_yaw", math.NormalizeAngle(velocity:Angle().yaw - eye.y))
end

--- End the current state (return to STATE_NONE). Client-side only runs for LocalPlayer.
--- Maps to: C# state machine transition → `SetState(State.None)`
---@param nocallended? boolean If true, skip calling the state's OnEnded callback
function PlayerController:EndState(nocallended)
    local ply = self.ply
    -- Client side check for MySelf parity
    if CLIENT and ply ~= LocalPlayer() then return end
    ply:SetState(STATE_NONE, nil, nil, nocallended)
end

-- ============================================================================
-- SERVER LOGIC
-- ============================================================================
if SERVER then

    --- Initialize player fields on first spawn (called from GM:PlayerInitialSpawn).
    --- Maps to: C# `protected override void OnStart()` setup
    ---@param ply Player
    function PlayerController:OnInitialSpawn()
        local ply = self.ply
        ply:SetCanWalk(false)
        ply:SprintDisable()
        ply:SetCustomCollisionCheck(true)
        ply:SetNoCollideWithTeammates(false)
        ply:SetAvoidPlayers(false)
        ply:CollisionRulesChanged()

        ply.NextHealthRegen = 0
        ply.LastDamaged = 0
        ply.m_KnockdownImmunityGlobal = 0
        ply.m_KnockdownImmunityChain = 0
    end

    --- Per-spawn setup: reset state, give weapon, set model/color.
    --- Called from GM:PlayerSpawn after Base_PlayerSpawn.
    --- Maps to: C# `void OnSpawn()` or `protected override void OnEnabled()`
    function PlayerController:OnSpawn()
        local ply = self.ply
        local GM = GAMEMODE

        ply:Extinguish()

        ply.m_KnockdownImmunity = {}
        ply.m_ChargeImmunity = {}
        ply.PointsCarry = 0
        ply.NextPainSound = 0
        ply:SetLastAttacker(nil)

        local teamid = ply:Team()

        local modelname = player_manager.TranslatePlayerModel(ply:GetInfo("cl_playermodel"))
        if not GM.AllowedPlayerModels[modelname:lower()] then
            modelname = teamid == TEAM_RED and "models/player/barney.mdl" or "models/player/breen.mdl"
        end
        ply:SetModel(modelname)

        if teamid == TEAM_RED then
            ply:SetPlayerColor(Vector(200 / 255, 0 / 255, 0 / 255))
        else
            ply:SetPlayerColor(Vector(30 / 255, 120 / 255, 255 / 255))
        end

        if not team.Joinable(teamid) then return end

        if teamid == TEAM_RED or teamid == TEAM_BLUE then
            ply:ShouldDropWeapon(false)
            ply:Give("weapon_eft")
        else
            ply:StripWeapons()
        end

        if CurTime() < GetGlobalFloat("RoundStartTime") and teamid ~= TEAM_SPECTATOR and teamid ~= TEAM_CONNECTING then
            ply:SetState(STATE_PREROUND)
        else
            ply:EndState()
            if ply:ShouldBeFrozen() then
                ply:Freeze(true)
            end
        end

        ply:SetGravity(1)

        if RecordMatchEvent and teamid ~= TEAM_SPECTATOR and teamid ~= TEAM_CONNECTING then
            RecordMatchEvent("respawn", ply)
        end
    end

    --- Handle player taking damage: track attacker, award points, play pain sound.
    --- Called from GM:PlayerHurt.
    --- Maps to: C# `void OnHurt(PlayerController attacker, float damage)`
    ---@param attacker Entity The entity that caused the damage
    ---@param healthremaining number Health after damage
    ---@param damage number Damage amount
    function PlayerController:OnHurt(attacker, healthremaining, damage)
        local ply = self.ply
        ply.LastDamaged = CurTime()

        if attacker ~= ply and attacker:IsValid() and attacker:IsPlayer() then
            ply:SetLastAttacker(attacker)

            attacker.PointsCarry = attacker.PointsCarry + damage * GAMEMODE.PointsForDamage
            if attacker.PointsCarry >= 1 then
                local toadd = math.floor(attacker.PointsCarry)
                attacker:AddFrags(toadd)
                attacker.PointsCarry = attacker.PointsCarry - toadd
            end
        end

        ply:PlayPainSound()
    end

    --- Handle player death: set respawn, drop carry, create ragdoll.
    --- Called from GM:DoPlayerDeath.
    --- Maps to: C# `void OnKilled(DamageInfo info)`
    ---@param attacker Entity The killer
    ---@param dmginfo CTakeDamageInfo Damage info
    function PlayerController:OnKilled(attacker, dmginfo)
        local ply = self.ply
        ply:SetRespawnTime(4)
        ply:Extinguish()
        ply:Freeze(false)

        if attacker == ply or not attacker:IsValid() or not attacker:IsPlayer() then
            local lastattacker = ply:GetLastAttacker()
            if lastattacker and lastattacker:IsValid() and lastattacker:IsPlayer() and lastattacker:Team() ~= ply:Team() then
                attacker = lastattacker
            end
        end

        ply:PlayVoiceSet(VOICESET_DEATH)

        local carrying = ply:GetCarrying()
        if carrying:IsValid() and carrying.Drop then carrying:Drop(nil, attacker == ply) end

        if not ply:CallStateFunction("DontCreateRagdoll", dmginfo) then
            ply:CreateRagdoll()
        end

        ply:AddDeaths(1)

        gamemode.Call("OnDoPlayerDeath", ply, attacker, dmginfo)
    end

    --- Health regeneration tick (called from GM:Think per-player).
    --- Maps to: C# `OnFixedUpdate()` health regen check
    function PlayerController:ThinkHealthRegen()
        local ply = self.ply
        if ply.NextHealthRegen and CurTime() >= ply.NextHealthRegen
            and ply.LastDamaged and CurTime() >= ply.LastDamaged + 1
            and ply:Health() < ply:GetMaxHealth() then
            ply.NextHealthRegen = CurTime() + 0.25
            ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + 2))
        end
    end

    --- Knock this player down for a duration, optionally crediting a knocker.
    --- Maps to: C# `[Broadcast] void KnockDown(float time, PlayerController knocker)`
    ---@param time? number Duration in seconds (default 2.75)
    ---@param knocker? Player The player who caused the knockdown
    function PlayerController:KnockDown(time, knocker)
        local ply = self.ply
        if not ply:Alive() or ply:InVehicle() or ply:GetState() == STATE_PREROUND then return end

        time = time or 2.75
        ply:SetState(STATE_KNOCKEDDOWN, time)

        if knocker and knocker:IsValid() and knocker:IsPlayer() then
            -- Track tackles
            if knocker:Team() ~= ply:Team() then
                knocker:SetNWInt("Tackles", knocker:GetNWInt("Tackles", 0) + 1)
            end
            if GameEvents.OnPlayerKnockedDownBy then GameEvents.OnPlayerKnockedDownBy:Invoke(ply, knocker) end
            gamemode.Call("OnPlayerKnockedDownBy", ply, knocker)

            if RecordMatchEvent then
                RecordMatchEvent("tackle_success", {knocker, ply})
            end
        end

        local carry = ply:GetCarrying()
        if carry:IsValid() and carry.Drop then
            carry:Drop()
        end
    end

    ---@param otherInfo Player|Entity Key for the immunity lookup (typically the other player)
    ---@param time number Absolute CurTime() when immunity expires
    function PlayerController:SetKnockdownImmunity(otherInfo, time)
        self.ply.m_KnockdownImmunity[otherInfo] = time
    end

    ---@param otherInfo Player|Entity Key for the immunity lookup
    ---@return number expiry CurTime() when immunity expires (0 = no immunity)
    function PlayerController:GetKnockdownImmunity(otherInfo)
        return self.ply.m_KnockdownImmunity[otherInfo] or 0
    end

    --- Grant 2-second knockdown immunity against a specific entity.
    ---@param otherInfo Player|Entity The entity to be immune against
    function PlayerController:ResetKnockdownImmunity(otherInfo)
        self:SetKnockdownImmunity(otherInfo, CurTime() + 2)
    end

    ---@param otherInfo Player|Entity Key for the immunity lookup
    ---@param time number Absolute CurTime() when immunity expires
    function PlayerController:SetChargeImmunity(otherInfo, time)
        self.ply.m_ChargeImmunity[otherInfo] = time
    end

    ---@param otherInfo Player|Entity Key for the immunity lookup
    ---@return number expiry CurTime() when immunity expires (0 = no immunity)
    function PlayerController:GetChargeImmunity(otherInfo)
        return self.ply.m_ChargeImmunity[otherInfo] or 0
    end

    --- Grant 0.45-second charge immunity against a specific entity.
    ---@param otherInfo Player|Entity The entity to be immune against
    function PlayerController:ResetChargeImmunity(otherInfo)
        self:SetChargeImmunity(otherInfo, CurTime() + 0.45)
    end

    --- Launch a hit entity away from the charger's position.
    ---@param hitent Player The player being launched
    ---@param knockdown boolean Whether to also knock the target down
    function PlayerController:ChargeLaunch(hitent, knockdown)
        local ply = self.ply
        hitent:ThrowFromPosition(ply:GetLaunchPos(), ply:GetVelocity():Length() * 1.65, knockdown, ply)
    end

    --- Handle charge collision with another player: damage, knockdown, effects.
    ---@param hitent Player The player that was hit
    ---@param tr? TraceResult Optional trace result for effect positioning
    function PlayerController:ChargeHit(hitent, tr)
        local ply = self.ply
        if hitent:ImmuneToAll() then return end

        ply:SetLastChargeHit(CurTime())

        local knockdown = CurTime() >= hitent:GetKnockdownImmunity(ply)
        self:ChargeLaunch(hitent, false)
        hitent:ResetChargeImmunity(ply)
        if knockdown then
            hitent:ResetKnockdownImmunity(ply)
            hitent:KnockDown(nil, ply)
        end
        hitent:TakeDamage(5, ply)

        ply:SetVelocity(ply:GetVelocity() * -0.03)
        ply:ViewPunch(VectorRand():Angle() * (math.random(0, 1) == 0 and -1 or 1) * 0.15)

        local effectdata = EffectData()
        if tr then
            effectdata:SetOrigin(tr.HitPos)
        else
            effectdata:SetOrigin(hitent:NearestPoint(ply:EyePos()))
        end
        effectdata:SetNormal(ply:GetVelocity():GetNormalized())
        effectdata:SetEntity(hitent)
        util.Effect("chargehit", effectdata, true, true)
    end

    --- Handle punch collision with another player: damage, knockdown, effects.
    ---@param hitent Player The player that was hit
    ---@param tr? TraceResult Optional trace result for effect positioning
    function PlayerController:PunchHit(hitent, tr)
        local ply = self.ply
        if hitent:ImmuneToAll() then return end

        local knockdown = CurTime() >= hitent:GetKnockdownImmunity(ply)
        hitent:ThrowFromPosition(ply:GetLaunchPos(), 360, knockdown, ply)
        if knockdown then
            hitent:ResetKnockdownImmunity(ply)
        end
        hitent:TakeDamage(25, ply)

        ply:ViewPunch(VectorRand():Angle() * (math.random(2) == 1 and -1 or 1) * 0.1)

        local effectdata = EffectData()
        if tr then
            effectdata:SetOrigin(tr.HitPos)
            effectdata:SetNormal(tr.HitNormal)
        else
            effectdata:SetOrigin(hitent:NearestPoint(ply:EyePos()))
            effectdata:SetNormal(ply:GetForward() * -1)
        end
        effectdata:SetEntity(hitent)
        util.Effect("punchhit", effectdata, true, true)
    end

    --- Find an active status entity of the given type owned by this player.
    ---@param sType string Status type name (e.g. "speed", "shield")
    ---@return Entity? status The status entity, or nil
    function PlayerController:GetStatus(sType)
        local ent = self.ply["status_"..sType]
        if ent and ent:IsValid() and ent.Owner == self.ply then return ent end
    end

    --- Remove a status entity from this player.
    ---@param sType string Status type name
    ---@param bSilent? boolean If true, suppress removal effects
    ---@param bInstant? boolean If true, remove immediately instead of fading
    ---@return boolean? removed True if a status was found and removed
    function PlayerController:RemoveStatus(sType, bSilent, bInstant)
        local removed
        for _, ent in pairs(ents.FindByClass("status_"..sType)) do
            if ent:GetOwner() == self.ply then
                if bInstant then
                    ent:Remove()
                else
                    ent.SilentRemove = bSilent
                    ent:SetDie()
                end
                removed = true
            end
        end
        return removed
    end

    --- Give a status effect to this player (create or refresh).
    ---@param sType string Status type name (maps to entity class "status_{sType}")
    ---@param fDie? number Absolute CurTime() when the status should expire
    ---@return Entity? status The created or refreshed status entity
    function PlayerController:GiveStatus(sType, fDie)
        local cur = self:GetStatus(sType)
        if cur then
            if fDie then cur:SetDie(fDie) end
            cur:SetPlayer(self.ply, true)
            return cur
        else
            local ent = ents.Create("status_"..sType)
            if ent:IsValid() then
                ent:Spawn()
                if fDie then ent:SetDie(fDie) end
                ent:SetPlayer(self.ply)
                return ent
            end
        end
    end

end

-- ============================================================================
-- CLIENT LOGIC
-- ============================================================================
if CLIENT then

    --- Compute third-person camera position (lerped, offset right and back).
    --- Maps to: C# `CameraComponent` / `CameraMode.ThirdPerson`
    ---@param camerapos Vector In/out: current camera position (modified in-place via Set)
    ---@param origin Vector Player eye origin
    ---@param angles Angle Camera angles
    ---@param fov number Field of view (unused, reserved for s&box parity)
    ---@param znear number Near clip plane (unused, reserved for s&box parity)
    ---@param zfar number Far clip plane (unused, reserved for s&box parity)
    ---@param lerp? number Interpolation factor 0..1 (default 1 = instant)
    ---@param right? number Right offset in units (default 16)
    function PlayerController:ThirdPersonCamera(camerapos, origin, angles, fov, znear, zfar, lerp, right)
        lerp = lerp or 1
        right = right or 16

        local newcamerapos = origin + angles:Right() * right + angles:Forward() * -16

        camerapos:Set(camerapos * (1 - lerp) + newcamerapos * lerp)
    end

    --- CLIENT: Find an active status entity of the given type owned by this player.
    ---@param sType string Status type name
    ---@return Entity? status The status entity, or nil
    function PlayerController:GetStatus(sType)
         for _, ent in pairs(ents.FindByClass("status_"..sType)) do
            if ent:GetOwner() == self.ply then return ent end
        end
    end

    function PlayerController:GiveStatus(sType, fDie) end -- Server only
    function PlayerController:RemoveStatus(sType) end -- Server only

end
