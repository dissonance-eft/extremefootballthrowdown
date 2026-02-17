-- MANIFEST CODE SYSTEM (cl_manifest_data.lua)
-- Cross-reference between MANIFEST.md ("the bible") and the Lua implementation.
-- Each code links a design concept to the files that implement it.
-- Viewed in-game via eft_dev 1 (aim at entity to see its manifest links).
--
-- Code prefixes:
--   M-xxx  Mechanics     (Part II: how things work)
--   P-xxx  Principles    (Part I: inviolable design rules)
--   C-xxx  Concepts      (Core Gameplay Concepts: the "why")
--   S-xxx  Scenarios     (Appendix A: testable gameplay moments)
--   A-xxx  Archetypes    (Appendix B: emergent player types)
--   E-xxx  Events        (Simulation Events: canonical API hooks)

ManifestData = {}

-- ==========================================================================
-- DEFINITIONS: What each code means and where it lives in the manifest
-- ==========================================================================
ManifestData.Definitions = {
    -- ======================================================================
    -- MECHANICS (M-xxx) -- Part II: Simulation Model
    -- ======================================================================
    ["M-010"] = "Physics Base",
    --  Ball and player physics foundation. Gravity, friction, collision.
    --  MANIFEST: Part II intro. FILES: obj_ball.lua, obj_player.lua, shared.lua
    --  Constants: gravity=800, friction=6.0, accelerate=5.0, airaccel=10.0

    ["M-030"] = "Tactics - Traps & Pads",
    --  Jump pads, mower traps, powerup triggers. Map-placed tactical elements.
    --  MANIFEST: Appendix F (Mapping Entity Reference).
    --  FILES: trigger_jumppad.lua, trigger_powerup.lua, trigger_mowerblade.lua, prop_mowertrap

    ["M-050"] = "Game Flow Control",
    --  Round lifecycle, tiebreaker, score tracking, random weapon suppression.
    --  MANIFEST: M-195 (Match Structure).
    --  FILES: logic_teamscore.lua, logic_norandomweapons.lua, game_tiebreaker_controller.lua

    ["M-070"] = "Projectile Effects",
    --  Impact effects from thrown/kicked objects (ice ball, arcane wand).
    --  MANIFEST: M-130 (Head-On Collision) for projectile interactions.
    --  FILES: effect_iceballimpact, projectile_arcanewand, explosion_arcanewand

    ["M-110"] = "Movement & Charge",
    --  Speed building, charge threshold (300 HU/s), forward-lock, wall punishment.
    --  "The Missile" mechanic: W disables strafing, mouse-only steering.
    --  MANIFEST: Part II section 1. FILES: shared.lua:434 (DefaultMove), obj_player.lua
    --  Key formula: newspeed = max(curspeed + dt*(15 + 0.5*(400-curspeed))*accel, 100)
    --              * (1 - max(0, abs(yaw_diff) - 4) / 360)
    --  4-degree grace zone before turning penalty. Status effects (boozed, cold) modify.

    ["M-120"] = "Knockdown & Recovery",
    --  2.75s knockdown, immunity timers, chain-stun rules, ragdoll.
    --  Total removal from play: ~4-5s (knockdown + re-acceleration).
    --  MANIFEST: Part II section 2. FILES: obj_player.lua, states/knockeddown.lua
    --  Immunity: 0.45s post-hit, 2.0s per-attacker, 3.75s global anti-stunlock.

    ["M-130"] = "Head-On Collision (Tackle)",
    --  THE core interaction. Higher speed wins. Close speeds = mutual knockback.
    --  Cross-counter: punch during last 0.2s of tackle = parry.
    --  MANIFEST: Part II section 3-4. FILES: obj_player.lua (ChargeHit), point_divetackletrigger.lua
    --  Charge cone: 90 deg, range: 80 HU, force: victim_vel = charger_vel * 1.65

    ["M-135"] = "Combat Matrix (RPS)",
    --  Rock-paper-scissors outcomes: Charge>Neutral, Dive>Neutral, Punch>Charge(timed),
    --  Charge>Dive, Charge>Charge(speed wins), Punch>Dive.
    --  MANIFEST: Part II section 4. FILES: obj_player.lua, states/divetackle.lua, states/punch1.lua

    ["M-140"] = "Dive Mechanics",
    --  Attack2 while charging. +100 HU/s, +320 upward. ALWAYS ends in knockdown.
    --  Hit = -0.5s recovery, miss = +0.5s. Turn rate 25%. Can pick up ball mid-dive.
    --  MANIFEST: Part II section 5. FILES: states/divetackle.lua, point_divetackletrigger.lua

    ["M-145"] = "Punch Mechanics",
    --  Short range (48 HU), 0.25s cooldown, 0.20s lock. Cross-counter window: 0.18s.
    --  Carrier disruption: 0.10s stun + 120 HU/s knockback.
    --  MANIFEST: Part II section 6. FILES: states/punch1.lua, weapon_eft.lua

    ["M-150"] = "Possession Rules",
    --  Pickup (64 HU radius), strip on tackle, passing = loss. Carrier: slower, can't charge.
    --  Auto-pickup on contact. Knocked-down players CANNOT pick up.
    --  MANIFEST: Part II section 7. FILES: obj_ball.lua, prop_ball/, prop_balltrigger

    ["M-160"] = "Fumble / Ball Loose",
    --  Fumble: carrier_vel * 1.75 horizontal, 128 HU/s vertical pop.
    --  Ball mass=25, damping=0.25, bounce=0.75x. STATE_FREE.
    --  General immunity: 1.0s after drop. Team pass immunity: 0.25s.
    --  MANIFEST: Part II section 8. FILES: obj_ball.lua, prop_ball/

    ["M-170"] = "Passing & Throw Windup",
    --  Hold RMB: 1.0s windup. Movement: 100 HU/s (SPEED_THROW). Grenade arc.
    --  Throw impulse: fwd=800, up=150. ~25% of throws fail (carrier tackled mid-windup).
    --  MANIFEST: Part II section 9. FILES: states/throw.lua, obj_ball.lua

    ["M-175"] = "Jump Mechanics",
    --  +200 HU/s vertical, 0.3s cooldown. BREAKS charge state (cannot tackle airborne).
    --  MANIFEST: Part II section 10. FILES: shared.lua (KeyPress IN_WALK)

    ["M-178"] = "Wall Collision",
    --  Running into ANY obstacle = instant stop. No sliding, no bounce.
    --  Stopping = losing charge = ~4s vulnerability. Wall slam on knocked players at 200+ HU/s.
    --  MANIFEST: Part II section 11. FILES: obj_player.lua, states/knockeddown.lua

    ["M-179"] = "Collision Model",
    --  Opponents: solid. Teammates: pass-through. Knocked-down: solid to ALL (obstacle).
    --  MANIFEST: Part II section 12. FILES: shared.lua (ShouldCollide)

    ["M-180"] = "Hazards & Resets",
    --  Lava=death+reset, water=swim+reset, pit=death+reset. 20s untouched timer.
    --  MANIFEST: Part II section 13.
    --  FILES: trigger_ballreset.lua, trigger_goal.lua, env_teamsound.lua, obj_ball.lua

    ["M-190"] = "Scoring",
    --  Goal value: 1 point. Touch (SCORETYPE_TOUCH=1), Throw (SCORETYPE_THROW=2), Both (3).
    --  Post-goal: 2.5s slow-mo at 0.1x. Ball resets to center. 5s timer suppress after throw.
    --  MANIFEST: Part II section 14. FILES: trigger_goal.lua, round_controller.lua, obj_gamemanager.lua

    ["M-195"] = "Match Structure",
    --  Goal cap: 10. Match time: 15min. Warmup: 30s. Respawn: 4.5s + 2.0s freeze + 1.5s ghost.
    --  BonusTime: celebration time added back to game clock.
    --  MANIFEST: Part II section 15. FILES: shared.lua, obj_gamemanager.lua, round_controller.lua

    ["M-198"] = "Pity Mechanic",
    --  Trail by 4+ goals: carrier speed 0.9x instead of 0.75x (315 vs 265 HU/s).
    --  MANIFEST: Part II section 16. FILES: shared.lua (team.HasPity), prop_ball/states/

    ["M-199"] = "Team Sizes",
    --  Min 3/team (bots fill), max 6 bots/team, competitive 5v5.
    --  MANIFEST: Part II section 17. FILES: sv_bots.lua, shared.lua

    -- ======================================================================
    -- PRINCIPLES (P-xxx) -- Part I: Invariants (Non-Negotiable)
    -- ======================================================================
    ["P-010"] = "Sport Identity",
    --  EFT is a continuous-contact team sport with ball and goals.
    --  Players join to score and to stop scoring. Not an abstract spatial game.
    --  MANIFEST: Part I section 1. FILES: shared.lua, cl_hud.lua, status_jersey

    ["P-020"] = "Interaction Frequency",
    --  MUST generate frequent contested interactions. Possession must never be stable.
    --  If possession becomes safe, EFT dies. Protects: C-001, C-002, C-009.
    --  MANIFEST: Part I section 2. FILES: obj_player.lua, trigger_knockdown.lua

    ["P-030"] = "Role Fluidity",
    --  NO fixed roles. Players constantly shift: carrier, tackler, escort.
    --  No code shall enforce class-based restrictions. Protects: C-003, C-010.
    --  MANIFEST: Part I section 3. FILES: class_default.lua, player_extension.lua

    ["P-040"] = "Prediction Dominance",
    --  Skill rewarded for anticipating future positions, not reacting to current.
    --  Mechanics favor positioning over raw reaction time. Protects: C-005, C-009.
    --  MANIFEST: Part I section 4. FILES: info_player_red.lua, info_player_blue.lua

    ["P-050"] = "Movement Constraints",
    --  Uniform base speed (350 HU/s). Carrier always slower (~75% = 265 HU/s).
    --  Win by moving EARLIER (better paths), not having better stats.
    --  MANIFEST: Part I section 5. FILES: sh_globals.lua (SPEED_*), shared.lua (DefaultMove)

    ["P-060"] = "Head-On Collisions",
    --  Decided by instantaneous velocity at impact. Tiny speed differences matter.
    --  "The Curve": turning 1-3 deg into a hit maximizes velocity. Skill expression.
    --  Bots must NOT be perfect -- exhibit human-like variance. Protects: C-006, C-009.
    --  MANIFEST: Part I section 6. FILES: obj_player.lua, obj_bot.lua (CurveBias)

    ["P-070"] = "Passing Purpose",
    --  Passing is for playmaking and survival, not just "moving the ball".
    --  Emergency, advancement, playmaking. Passes are rarely clean catches.
    --  Protects: C-008, C-007, C-001.
    --  MANIFEST: Part I section 7. FILES: states/throw.lua, obj_bot.lua (FindThrowTarget)

    ["P-080"] = "Ball Readability",
    --  Ball is focal point for interaction, not chaos generator.
    --  Throws consistent (predictable arcs). Uncertainty from PLAYERS, not physics noise.
    --  Protects: C-006, C-005.
    --  MANIFEST: Part I section 8. FILES: prop_ball/, prop_carry_*.lua, obj_ball.lua

    ["P-090"] = "Hazards, Death, Reset Migration",
    --  Hazards are strategic tools. Death = ~4s respawn. Intentional ball resets relocate contest.
    --  Respawn timing must allow re-entering active play. Protects: C-010, C-003, C-007.
    --  MANIFEST: Part I section 9. FILES: trigger_ballreset.lua, obj_player.lua (respawn)

    ["P-100"] = "Reversals and Hype",
    --  Maximize sudden reversals: clutch saves, swarm escapes, tackle chains, interceptions.
    --  Scoring must remain meaningful and hype. Protects: C-004, C-001.
    --  MANIFEST: Part I section 10. FILES: trigger_goal.lua, round_controller.lua, cl_hud.lua

    ["P-900"] = "What Breaks EFT",
    --  DO NOT: make possession safe, throws instant, remove fumbles, add randomness,
    --  soften knockdowns, slow respawns, remove momentum influence, smooth friction.
    --  MANIFEST: Part I section 11.

    ["P-910"] = "Excluded Mechanics",
    --  Power struggles (QTE), items, throwing guide, aim assist, formations,
    --  play-by-play AI, stoppages, turn-based possession, high jump, alt dive.
    --  MANIFEST: Part I section 12.

    ["P-950"] = "Behavioral Guarantees (Possession/Collision)",
    --  Possession volatility: carrier threatened within seconds. Collision density: players
    --  within seconds of meaningful interaction. Carrier emotional tension: dangerous but not safe.
    --  MANIFEST: Part I section 13.
    --  FILES: obj_player.lua, obj_ball.lua, states/knockeddown.lua

    ["P-960"] = "Behavioral Guarantees (Commitment/Participation)",
    --  Rewards decisive early action over perfect late reaction. Swarm interactions are
    --  core gameplay, not a bug. Large group scrambles are desirable.
    --  MANIFEST: Part I section 14.

    ["P-970"] = "Behavioral System Requirements",
    --  Shared attention convergence, global readability, universal influence, map authority.
    --  MANIFEST: Part I section 14b.

    -- ======================================================================
    -- CONCEPTS (C-xxx) -- Core Gameplay Concepts: the "Why"
    -- ======================================================================
    ["C-001"] = "Continuous Contest",
    --  Players repeatedly drawn into contested interactions. Never feel "safe" or "finished".
    --  The game loop never allows stability until ball reset.
    --  MANIFEST: Core Gameplay Concepts. RELATED: P-020, P-100.

    ["C-002"] = "Short Possession",
    --  Possession is temporary, unstable. Carrier expects to lose ball within seconds.
    --  Long-term individual possession is a failure state. Average carry: ~2 seconds.
    --  MANIFEST: Core Gameplay Concepts. RELATED: P-020, M-150.

    ["C-003"] = "Simultaneous Relevance",
    --  Most players can affect events within seconds. Map and movement speeds ensure
    --  even distant players can rotate to intercept quickly.
    --  MANIFEST: Core Gameplay Concepts. FILES: trigger_jumppad.lua (enables fast rotation)

    ["C-004"] = "Last-Second Intervention",
    --  Scores are preventable until the final moment. "Goal-Line Stand" (S-001).
    --  MANIFEST: Core Gameplay Concepts. FILES: trigger_goal.lua, logic_teamscore.lua

    ["C-005"] = "Predictive Positioning",
    --  Succeed by moving early, not reacting late. Ball physics and speeds reward anticipation.
    --  Cutting off lanes > chasing the carrier.
    --  MANIFEST: Core Gameplay Concepts. RELATED: P-040.

    ["C-006"] = "Controlled Chaos",
    --  Outcomes uncertain but readable. Fumbles and bounces introduce variance,
    --  but variance must be consistent enough for informed risk assessment.
    --  MANIFEST: Core Gameplay Concepts. RELATED: P-080, M-160.

    ["C-007"] = "Migrating Conflict Zone",
    --  The "important" location continuously relocates. Corner scramble -> center breakout.
    --  Players must constantly re-evaluate where conflict is moving.
    --  MANIFEST: Core Gameplay Concepts. RELATED: P-090, M-180.

    ["C-008"] = "Downfield Contest Creation",
    --  Passing creates NEW contests, not guaranteed possession. A pass is often a "punt"
    --  to a more favorable fight location, not a clean transfer.
    --  MANIFEST: Core Gameplay Concepts. RELATED: P-070, M-170.

    ["C-009"] = "Commitment Under Uncertainty",
    --  Must act before full information exists. Committing to a tackle or jump-catch
    --  implies risk of missing, which the enemy can exploit.
    --  MANIFEST: Core Gameplay Concepts. RELATED: P-060, P-040.

    ["C-010"] = "Continuous Participation",
    --  Respawns return players into the SAME ongoing play. Elimination is a temporary
    --  tactical penalty, not removal from match flow.
    --  MANIFEST: Core Gameplay Concepts. RELATED: P-090, M-195.

    -- ======================================================================
    -- SCENARIOS (S-xxx) -- Appendix A: Testable Gameplay Moments
    -- ======================================================================
    ["S-001"] = "Goal Line Stand",
    --  Carrier <50 HU from goal, tackled 0.1s before entry. Ball comes loose, no score.
    --  Demonstrates: C-004, C-001. FILES: trigger_goal.lua, obj_player.lua

    ["S-002"] = "Panic Short Pass",
    --  Carrier swarmed by 2+, releases ball low velocity, bounces nearby.
    --  Demonstrates: C-002, C-006.

    ["S-003"] = "Long Throw Recovery",
    --  Carrier throws high arc downfield. Ball recoverable (self-passing / advancement).
    --  Demonstrates: C-008, C-007.

    ["S-005"] = "Swarm Collapse",
    --  Ball loose, 4+ players converge. Collisions, stuns, ball might pop again.
    --  Demonstrates: C-001, C-003. FILES: obj_player.lua, obj_bot.lua

    ["S-009"] = "Head-On Speed Duel",
    --  Player A (350) hits Player B (340). B knocked down. Deterministic skill reward.
    --  Demonstrates: C-006, C-009. FILES: obj_player.lua (ChargeHit)

    ["S-010"] = "Last-Second Touchdown Stop",
    --  Carrier airborne into goal. Defender hits frame before entry. Denial.
    --  Demonstrates: C-004, C-001. FILES: trigger_goal.lua

    ["S-011"] = "Loose Ball Bounce",
    --  Predictable reflection. Readability. Ball stops dead or flies erratically = anti-outcome.
    --  Demonstrates: C-006, C-005. FILES: obj_ball.lua

    ["S-017"] = "Mid-Air Catch",
    --  Ball thrown high. Player jumps to intercept at apex. Catch + carry momentum.
    --  Demonstrates: C-005, C-009. FILES: obj_ball.lua, obj_player.lua

    ["S-020"] = "Bot Positioning",
    --  Ball loose right side. Bot moves to intercept FUTURE position, not current.
    --  Demonstrates: C-005, C-003. FILES: obj_bot.lua (GetInterceptPoint)

    -- ======================================================================
    -- ARCHETYPES (A-xxx) -- Appendix B: Emergent Player Types
    -- ======================================================================
    ["A-001"] = "Ballhog Runner",
    --  Never passes, runs straight for goal. Strong 1v1 juking, weak vs swarms.
    --  Bot mapping: Aggressive personality, low PassFreq.

    ["A-002"] = "Safe Passer",
    --  Throws immediately on pressure. Good retention, low solo scoring threat.
    --  Bot mapping: Support personality, high PassFreq.

    ["A-003"] = "Defensive Interceptor",
    --  Ignores carrier, watches lanes. Turnover generation specialist.
    --  Bot mapping: Defensive personality.

    ["A-004"] = "Space Clearer (Escort)",
    --  Head-hunter. Tackles closest enemy to carrier. Makes holes.
    --  Bot mapping: Aggressive + target nearest enemy to carrier.

    ["A-008"] = "Panic Thrower",
    --  Low stress tolerance. Mashing throw when touched. Creates chaos.
    --  Bot mapping: low skill threshold triggers early throw.

    -- ======================================================================
    -- EVENTS (E-xxx) -- Simulation Events: Canonical API
    -- ======================================================================
    ["E-210"] = "TackleResolve",
    --  Fires when two players collide at charge speed.
    --  FILES: obj_player.lua (ChargeHit -> GameEvents.OnPlayerKnockedDownBy)

    ["E-220"] = "PossessionTransfer",
    --  Fires on Pickup, Catch, Strip.
    --  FILES: obj_ball.lua, prop_ball/

    ["E-230"] = "BallLoose",
    --  Fires on tackle (strip), throw release, reset spawn.
    --  FILES: obj_ball.lua

    ["E-240"] = "BallReset",
    --  Fires on hazard touch, goal scored, stagnation timer.
    --  FILES: obj_ball.lua (ReturnHome), trigger_ballreset.lua

    ["E-250"] = "PlayerKnockdown",
    --  Fires on tackle outcome, wall slam.
    --  FILES: obj_player.lua (KnockDown)

    ["E-260"] = "PlayerRecovered",
    --  Fires on knockdown timer expiry. State -> NONE.
    --  FILES: states/knockeddown.lua

    ["E-270"] = "GoalScored",
    --  Fires when ball satisfies goal condition.
    --  FILES: trigger_goal.lua, obj_gamemanager.lua
}

-- ==========================================================================
-- MAPPINGS: Which manifest codes each entity/file implements
-- Maps entity class names to arrays of manifest code IDs.
-- When eft_dev is enabled, aiming at an entity shows these codes.
-- ==========================================================================
ManifestData.Mappings = {
    -- Player entity (combined: collision, movement, knockdown, possession, etc.)
    ["player"] = {
        "M-110",  -- Movement & Charge
        "M-120",  -- Knockdown & Recovery
        "M-130",  -- Head-On Collision
        "M-135",  -- Combat Matrix
        "P-050",  -- Movement Constraints
        "P-060",  -- Head-On Collisions (The Curve)
        "P-030",  -- Role Fluidity
        "P-950",  -- Behavioral Guarantees
        "S-005",  -- Swarm Collapse
        "S-009",  -- Head-On Speed Duel
        "S-017",  -- Mid-Air Catch
    },

    -- Ball entity
    ["prop_ball"] = {
        "M-010",  -- Physics Base
        "M-150",  -- Possession Rules
        "M-160",  -- Fumble / Ball Loose
        "P-080",  -- Ball Readability
        "E-220",  -- PossessionTransfer
        "E-230",  -- BallLoose
        "E-240",  -- BallReset
    },

    -- Ball trigger (pickup zone)
    ["prop_balltrigger"] = {
        "M-010",  -- Physics Base
        "M-150",  -- Possession Rules
    },

    -- Goal trigger
    ["trigger_goal"] = {
        "M-180",  -- Hazards & Resets (goal resets ball)
        "M-190",  -- Scoring
        "P-100",  -- Reversals and Hype
        "C-004",  -- Last-Second Intervention
        "S-001",  -- Goal Line Stand
        "S-010",  -- Last-Second Touchdown Stop
        "E-270",  -- GoalScored
    },

    -- Goal prop (visual)
    ["prop_goal"] = {
        "M-010",  -- Physics Base
        "M-190",  -- Scoring
        "S-001",  -- Goal Line Stand
    },

    -- Ball reset trigger
    ["trigger_ballreset"] = {
        "M-180",  -- Hazards & Resets
        "P-090",  -- Reset Migration
        "C-007",  -- Migrating Conflict Zone
        "E-240",  -- BallReset
    },

    -- Jump pad / push pad
    ["trigger_jumppad"] = {
        "M-030",  -- Tactics - Traps & Pads
        "C-003",  -- Simultaneous Relevance (enables fast rotation)
    },
    ["trigger_abspush"] = {
        "M-030",  -- Tactics - Traps & Pads
        "C-003",  -- Simultaneous Relevance
    },

    -- Knockdown trigger zone
    ["trigger_knockdown"] = {
        "M-120",  -- Knockdown & Recovery
        "P-020",  -- Interaction Frequency
    },

    -- Powerup trigger
    ["trigger_powerup"] = {
        "M-030",  -- Tactics - Traps & Pads
    },

    -- Dive tackle trigger
    ["point_divetackletrigger"] = {
        "M-130",  -- Head-On Collision
        "M-140",  -- Dive Mechanics
    },

    -- Mower hazard
    ["trigger_mowerblade"] = { "M-030" },
    ["prop_mowertrap"] = { "M-030" },

    -- Team sound
    ["env_teamsound"] = {
        "M-180",  -- Hazards (goal sound cues)
        "P-060",  -- Head-On Collisions (audio cues)
    },

    -- Tiebreaker
    ["game_tiebreaker_controller"] = { "M-050" },

    -- Score logic
    ["logic_teamscore"] = {
        "M-050",  -- Game Flow Control
        "C-004",  -- Last-Second Intervention
    },

    -- No random weapons
    ["logic_norandomweapons"] = { "M-050" },

    -- Spawn points
    ["info_player_red"] = { "P-040", "P-010", "C-010" },
    ["info_player_blue"] = { "P-040", "P-010", "C-010" },
    ["info_player_spectator"] = { "P-040" },

    -- Projectile
    ["projectile_arcanewand"] = { "M-130", "M-070" },

    -- Water ball platform
    ["prop_waterballplatform"] = { "M-010" },

    -- Status effects
    ["status_jersey"] = { "P-010" },       -- Sport Identity (visual team ID)
    ["status_boozed"] = { "M-110" },       -- Movement modifier
    ["status_cold"] = { "M-110" },         -- Movement modifier
    ["status_featherballwings"] = { "M-010" },
    ["status__base"] = { "M-110" },        -- Base status: movement modifier

    -- Carry items (all implement possession + readability)
    ["prop_carry_base"] = { "M-150" },
    ["prop_carry_arcanewand"] = { "M-150", "P-080" },
    ["prop_carry_barrel"] = { "M-150", "P-080" },
    ["prop_carry_beatingstick"] = { "M-150", "P-080" },
    ["prop_carry_bigpole"] = { "M-150", "P-080" },
    ["prop_carry_boozebottle"] = { "M-150", "P-080" },
    ["prop_carry_car"] = { "M-150", "P-080" },
    ["prop_carry_melon"] = { "M-150", "P-080" },
    ["prop_carry_melondriver"] = { "M-150", "P-080" },
    ["prop_carry_mowertrap"] = { "M-150", "P-080" },

    -- Effects
    ["effect_iceballimpact"] = { "M-070" },
}

-- ==========================================================================
-- FILE INDEX: Which Lua files are primary anchors for each code
-- Used by the debug overlay and tooling to cross-link code to manifest.
-- ==========================================================================
ManifestData.FileAnchors = {
    -- Mechanics
    ["M-010"] = { "obj_ball.lua", "obj_player.lua" },
    ["M-030"] = { "trigger_jumppad.lua", "trigger_mowerblade.lua", "trigger_powerup.lua" },
    ["M-050"] = { "logic_teamscore.lua", "logic_norandomweapons.lua", "game_tiebreaker_controller.lua" },
    ["M-070"] = { "effect_iceballimpact", "projectile_arcanewand" },
    ["M-110"] = { "shared.lua", "obj_player.lua", "sh_globals.lua" },
    ["M-120"] = { "obj_player.lua", "states/knockeddown.lua", "trigger_knockdown.lua" },
    ["M-130"] = { "obj_player.lua", "point_divetackletrigger.lua", "states/divetackle.lua" },
    ["M-135"] = { "obj_player.lua", "states/divetackle.lua", "states/punch1.lua" },
    ["M-140"] = { "states/divetackle.lua", "point_divetackletrigger.lua" },
    ["M-145"] = { "states/punch1.lua", "weapon_eft.lua" },
    ["M-150"] = { "obj_ball.lua", "prop_ball/", "prop_balltrigger" },
    ["M-160"] = { "obj_ball.lua", "prop_ball/" },
    ["M-170"] = { "states/throw.lua", "obj_ball.lua" },
    ["M-175"] = { "shared.lua" },
    ["M-178"] = { "obj_player.lua", "states/knockeddown.lua" },
    ["M-179"] = { "shared.lua" },
    ["M-180"] = { "trigger_ballreset.lua", "trigger_goal.lua", "env_teamsound.lua" },
    ["M-190"] = { "trigger_goal.lua", "round_controller.lua", "obj_gamemanager.lua" },
    ["M-195"] = { "shared.lua", "obj_gamemanager.lua", "round_controller.lua" },
    ["M-198"] = { "shared.lua", "prop_ball/" },
    ["M-199"] = { "sv_bots.lua", "shared.lua" },

    -- Principles
    ["P-010"] = { "shared.lua", "cl_hud.lua", "status_jersey" },
    ["P-020"] = { "obj_player.lua", "trigger_knockdown.lua" },
    ["P-030"] = { "class_default.lua", "player_extension.lua" },
    ["P-040"] = { "info_player_red.lua", "info_player_blue.lua" },
    ["P-050"] = { "sh_globals.lua", "shared.lua" },
    ["P-060"] = { "obj_player.lua", "obj_bot.lua" },
    ["P-070"] = { "states/throw.lua", "obj_bot.lua" },
    ["P-080"] = { "prop_ball/", "obj_ball.lua" },
    ["P-090"] = { "trigger_ballreset.lua", "obj_player.lua" },
    ["P-100"] = { "trigger_goal.lua", "round_controller.lua", "cl_hud.lua" },
    ["P-950"] = { "obj_player.lua", "obj_ball.lua" },

    -- Concepts
    ["C-001"] = { "obj_player.lua", "obj_ball.lua", "round_controller.lua" },
    ["C-003"] = { "trigger_jumppad.lua" },
    ["C-004"] = { "trigger_goal.lua", "logic_teamscore.lua" },
    ["C-005"] = { "obj_bot.lua" },
    ["C-007"] = { "trigger_ballreset.lua", "obj_ball.lua" },
    ["C-009"] = { "obj_player.lua", "states/divetackle.lua" },
    ["C-010"] = { "obj_player.lua", "round_controller.lua" },

    -- Bot AI
    ["B-000"] = { "sv_bots.lua", "obj_bot.lua", "sv_bot_pathfinding.lua" },
}
