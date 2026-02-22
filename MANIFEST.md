# MANIFEST.md: The Constitution of Extreme Football Throwdown

**Extreme Football Throwdown (EFT)** is a continuous collision sport where a swarm of players repeatedly interrupts and reassigns possession of a ball that automatically attaches to whoever physically contacts it after a tackle or throw event. Players do not "choose" possession — possession happens to them.

*   **Distinctiveness:** EFT combines the continuous flow of Hockey/Rocket League with the physical combat of a brawler. There are no stable offensive/defensive phases. Everyone is always charging and trying to tackle someone. If your target has the ball, that's defense. If your target is chasing the ball carrier, that's offense. Same action, different target. Roles are fluid, not fixed.
*   **Core Loop:** Engage → Tackle → Displacement → Auto-possession transfer → Immediate retarget → Repeat. Because carriers are slower than defenders (~263 vs 350 HU/s), offense and defense invert multiple times in a single scramble. Goals occur when the system fails to interrupt a carrier for a brief window — not because a structured play succeeds.
*   **Possession is the spark — and a curse.** The ball is a target marker, not a reward. It glues to you on contact and paints every opponent's crosshair on your back. The game's thrill comes from seizing it, defending it, and ripping it away in rapid succession. There is no "setup" offense, no "safe" carry. Possession is continuously decaying under pressure.
*   **Auto-pickup:** The ball attaches instantly to anyone who touches it. No key, no delay, no confirmation animation. New players are frequently surprised by sudden turnovers caused by running into a loose ball. "Oh shit I have it" moments create instant retargeting and maintain pace. This is intentional — it fuels rapid offense/defense flips and keeps every scramble contested.
*   **Passing is high-risk, high-reward.** A ~1s windup leaves the carrier nearly stationary and exposed. Passes are most effective when chaos gives a second of breathing room; otherwise, running is safer. Bounced or contested catches are the norm, not clean transfers.
*   **Tackles are first-class outcomes.** A tackle that strips the ball from a breakaway carrier is as game-changing as a goal. The scoreboard tracks both. Tackling is not only about taking the ball — it is about disqualifying opponents from the next interaction cycle.
*   **The real resource is upright participation.** The key resource in EFT is not territory or spacing — it is how many upright, charging players are near the next possession change. Knockdowns, swimming, wall hits, and respawns don't deal damage; they remove participation. "Creating space" means reducing the number of upright opponents who can contest the next 1-2 seconds.
*   **The central skill.** A good EFT player is not the one who controls the ball longest. A good EFT player is the one who is correctly positioned at the highest number of state transitions. This explains why head-ons mattered, why scrums mattered, why passing was rare but decisive, and why new players chased the carrier while good players anticipated the collapse.
*   **Inviolable Warning:** **If a change makes the game cleaner but reduces tension, contested interactions, or reversals, the change is WRONG even if technically sound.** Visual polish must never weaken interaction properties. "Cleaner" behavior that reduces possession volatility or interaction density breaks the sport.
*   **Contract:** This document is both the "soul" of the game and the strict implementation contract. Code must serve this manifest. The Lua code is a reference implementation; the manifest is the behavioral specification.

---

## PREAMBLE: WHAT EFT IS NOT (Mandatory Context) <!-- id: PRE-000 -->

> **FOR LLMs/AGENTS:** This section exists because LLMs consistently misinterpret EFT based on the word "football" in the title. You MUST internalize these constraints before writing ANY code, bot logic, or documentation.

### EFT IS NOT American Football

| American Football Concept | EFT Reality | Why It Matters |
|--------------------------|-------------|----------------|
| **Downs / Plays** | DO NOT EXIST | No "1st and 10", no play calls, no huddles |
| **Stoppage after tackle** | DOES NOT HAPPEN | Tackle -> fumble -> ball is loose -> play continues IMMEDIATELY |
| **Offensive/Defensive lines** | NO FORMATIONS | Everyone swarms. No linemen, no blocking schemes |
| **Quarterback** | NO FIXED ROLES | Whoever picks up the ball IS the carrier. Roles are emergent |
| **Playbooks / Routes** | NO SCRIPTED PLAYS | All decisions are real-time, emergent, reactive |
| **Possession after tackle** | BALL BECOMES LOOSE | Tackles cause fumbles, not "downs". Anyone can grab it |
| **Clock stops** | CLOCK NEVER STOPS | Only brief freeze after goals (2s), then immediate resume |
| **Out of bounds** | MAPS ARE ENCLOSED ARENAS | No sidelines. Walled arenas with hazards |
| **Field goals / punts** | DO NOT EXIST | Only scoring method: ball enters goal zone |
| **Turn-based possession** | POSSESSION IS VOLATILE | Changes 5-10 times in seconds during scrums |

### EFT IS NOT These Games Either

| Game | Why NOT |
|------|---------|
| **Basketball** | No shot clock, no possession timer, no out-of-bounds |
| **Soccer** | Forward passing allowed, can tackle without ball |
| **Capture the Flag** | Ball resets to CENTER after score, not team base |
| **Madden/FIFA/NBA2K** | No AI playcalling, no formations, no turn-based possession |
| **Blood Bowl** | Not turn-based. Real-time continuous chaos |

### EFT IS Most Like:

| Game | Similarity | Key Difference |
|------|-----------|----------------|
| **Rocket League** | Continuous play, no stoppages, ball is always live, rotational positioning, boost/speed management | EFT uses player bodies as vehicles, not cars |
| **Rugby (Sevens)** | Continuous flow, tackles cause turnovers, forward passing | EFT is faster, more chaotic, arena-enclosed |
| **Hockey** | Fast pace, constant possession changes, physicality | EFT has no offsides, no icing, simpler rules |
| **Quake/UT (Arena FPS)** | Source engine movement, momentum, spatial control | EFT replaces guns with tackles/throws |

### The Rocket League Mental Model (USE THIS)

LLMs and bot designers should think of EFT as **"Rocket League but you ARE the car"**:

1. **Ball is always live** -- No whistles, no stoppages, no dead ball (except after goals)
2. **Rotation matters** -- Don't ALL chase the ball. Space out. Cover passes. Cut angles
3. **Speed is currency** -- You need >=300 HU/s to tackle (like needing boost in RL)
4. **Possession is fleeting** -- Average carry lasts ~2 seconds before a tackle/fumble
5. **Scrums = kickoffs** -- Both teams converge on ball, chaos ensues, someone breaks out
6. **No assigned positions** -- Everyone reads the field and makes local decisions
7. **Continuous clock** -- Only stops briefly after goals, then immediate ball-at-center restart
8. **The carrier is slow** -- ~263 HU/s vs 350 HU/s empty. They WILL be caught. Must score fast or pass
9. **Tackles are the baseline** -- Like bumps/demos in RL. They happen constantly. Not highlights
10. **Map geometry matters** -- Jump pads, ramps, hazards create routing decisions like boost pads

### Bot AI Anti-Patterns (NEVER DO THESE)

| Anti-Pattern | Why It's Wrong | What To Do Instead |
|-------------|---------------|-------------------|
| **Bots lining up in formation** | No formations exist. This is arena sports | Swarm/rotate like RL bots |
| **Bots stopping after tackles** | Play never stops. Ball is immediately live | Continue chasing loose ball |
| **"Offensive" vs "Defensive" bot types** | Roles are emergent, not assigned | Each bot decides based on proximity/situation |
| **Bots waiting for "their turn"** | No turns. Continuous play | Always be moving, always threatening |
| **Bots running set routes** | No routes exist | Read the field, cut angles, react |
| **Bots ignoring loose ball** | Ball fumbles happen constantly | ALWAYS contest loose balls (scrum behavior) |
| **Bots walking/standing still** | Everyone runs at max speed always | Hold W (IN_FORWARD) at all times unless knocked |
| **Bots pathing along walls** | Walls = death (you stop instantly on contact) | Steer AWAY from walls. Maintain speed |
| **Bots stopping to "aim" throws** | Throwing is rare and risky. Running > throwing | Prioritize carrying to goal over passing |

---

## CORE GAMEPLAY CONCEPTS (The "Why")

### C-001 Continuous Contest <!-- id: C-001 -->
Players are repeatedly drawn into contested interactions around the ball. Possession is the trigger — every carrier is immediately a target, every loose ball is an invitation to swarm. The game loop must never allow a player to feel "safe" or "finished" until the ball resets. Seizing the ball, protecting it, and ripping it away are equally valid and celebrated actions. Scrums are not a failure state — they are the sport. The typical cycle is: scrum → fumble → scramble → breakout attempt → re-collapse → goal or reset.

### C-002 Short Possession <!-- id: C-002 -->
Possession is temporary and unstable. Because carriers are always slower than defenders, a carrier who cannot reach the goal or make a pass within seconds will be caught and stripped. Long-term individual possession is a failure state — not because possession is unimportant, but because the game is designed to make it difficult to hold. All meaningful actions occur under interruption threat. Most decisive windows are under 5 seconds; most are under 1-2 seconds. Three seconds feels like forever because multiple interaction cycles occur during that time.

### C-003 Simultaneous Relevance <!-- id: C-003 -->
Most players can affect events within seconds. The map and movement speeds ensure that even a player far from the ball can rotate to a relevant intercept point quickly.

### C-004 Last-Second Intervention <!-- id: C-004 -->
Scores are preventable until the final moment. Mechanics like the "Goal-Line Stand" (S-001) exist specifically to allow defenders to make hero plays at the buzzer.

### C-005 Predictive Positioning <!-- id: C-005 -->
Players succeed by moving early, not reacting late. The ball's physics and player speeds reward anticipation (cutting off lanes) over reaction (chasing the carrier). Experienced players constantly evaluate one question: "Where will the next possession event occur within the next 1-2 seconds?" They are not tracking the ball itself — they are tracking the next collision that will decide the ball. Good players often move slightly *away* from the current carrier when they predict a tackle is imminent. This is not zoning — it is pre-reaction.

### C-006 Controlled Chaos <!-- id: C-006 -->
Outcomes are uncertain but readable. Fumbles and bounces introduce variance, but that variance must be consistent enough for players to make informed risk assessments.

### C-007 Migrating Conflict Zone <!-- id: C-007 -->
The "important" location of play continuously relocates. A scramble in the corner can instantly become a breakout to the center. Players must constantly re-evaluate where the conflict is moving. EFT is a cascade game: small interactions accumulate until a tipping point occurs (multiple opponents knocked down, a late returner whiffs, a head-on deletes the last upright interrupter). Then pressure fails to reform and the situation resolves suddenly into a run-in goal, a full-power throw, or an immediate counter-collapse. This resolution is not gradual — it is sudden.

### C-008 Downfield Contest Creation <!-- id: C-008 -->
Actions (especially passing) create *new* contests rather than guaranteed possession. A pass is often a "punt" to a more favorable location for a fight, not a clean transfer.

### C-009 Commitment Under Uncertainty <!-- id: C-009 -->
Players must act before full information exists. Committing to a tackle or a jump-catch implies a risk of missing, which the enemy can exploit.

### C-010 Continuous Participation <!-- id: C-010 -->
Respawns and resets return players into the same ongoing play. Elimination is a temporary tactical penalty, not a removal from the match flow.

### C-011 Transition Dominance <!-- id: C-011 -->
The most important events in EFT are transitions, not stable states. Tackle → fumble → instant pickup → immediate new target. Stable carry is not the core — possession change is the core. Impact is often shaping *who receives the ball next*, not being the one who holds it longest. Some players are primarily tacklers/clearers whose value is controlling transitions and disqualifying opponents, not carrying. EFT is skill-expressive but not skill-exclusive: good players influence outcomes more reliably, but low-skill players still matter because simply moving and colliding adds pressure to the swarm.

---

## PART I -- INVARIANTS (Non-Negotiable Rules)

### 1. Sport Identity <!-- id: P-010 -->
EFT is a **continuous-contact team sport** with a ball and goals. Players join to score and to stop scoring. It is not an abstract spatial game; it is a digital sport.

### 2. Interaction Frequency <!-- id: P-020 -->
The game **must generate frequent contested interactions** around the ball. Possession must never be infinitely stable. If possession becomes safe, EFT dies.
*   **Protects Concepts:** C-001, C-002, C-009

### 3. Role Fluidity <!-- id: P-030 -->
**Players do not have fixed roles.** A single player constantly shifts between offense (carrier), defense (tackler), and support (escort) based on what matters next.
> **Constraint:** No code shall enforce "class-based" restrictions that prevent a player from acting on the ball or opponents.
*   **Protects Concepts:** C-003, C-010

### 4. Prediction Dominance <!-- id: P-040 -->
Skill is rewarded for **anticipating future interactions/positions**, not just reacting to the current ball location.
> **Constraint:** Mechanics must favor positioning (e.g., angle cutting) over raw reaction time.
*   **Protects Concepts:** C-005, C-009

### 5. Movement Constraints <!-- id: P-050 -->
*   **Uniform Speed:** All players share the same base movement speed (350 HU/s).
*   **Carrier Liability:** The ball carrier is ALWAYS slower than defenders (~75% speed).
*   **Winning Conditions:** Players win by moving *earlier* (taking better paths/angles), not by having superior movement stats.
*   **Protects Concepts:** C-005, C-003

### 6. Head-On Collisions <!-- id: P-060 -->
Head-on collisions are decided by **instantaneous velocity at impact**. Even tiny speed differences (0.1 HU/s) matter. Head-ons are the primary visible mechanical skill test in EFT.
*   **Momentum Influence:** Player-controlled momentum immediately before impact must influence tackle outcomes in a readable, learnable way. Source movement quirks allow smooth turning to add slight speed above baseline (~350 → ~356-358 HU/s). Winning by 358 vs 357 feels "earned" because the player generated the advantage through movement execution.
*   **Skill Expression:** This preserves the manual skill of "curving" or "strafing" into a hit to maximize velocity. To inexperienced players head-ons can feel random; to experienced players they are highly consistent and historically used as a major skill ranking signal in the community.
*   **Preservation:** Small player-controlled velocity variance must meaningfully affect head-on outcomes. If head-ons become symmetric/normalized, a major skill layer and social hierarchy signal disappears.
*   **Bot Imperfection:** Bots must *not* be perfect at head-ons; they must exhibit human-like variance.
*   **Protects Concepts:** C-006, C-009, C-011

### 7. Passing Purpose <!-- id: P-070 -->
Passing is for **playmaking and survival**, not just "moving the ball". It is high-risk, high-reward.
*   **a) Emergency:** Transfer possession when carrier cannot survive — but the ~1s windup leaves you nearly stationary and exposed, so mistimed emergency passes often fail.
*   **b) Advancement:** Throw ahead into space and chase the landing point — effectively a controlled fumble to a better field position.
*   **c) Playmaking:** Throw to a teammate already moving into a better contest position.
*   **Constraint:** The windup caps movement at ~100 HU/s (SPEED_THROW). A passing carrier is nearly stopped. Passes are most effective when chaos gives a genuine breathing window. Otherwise, running is safer. Bounced/contested catches are the norm; clean catches are the exception.
*   **Protects Concepts:** C-008, C-007, C-001

### 8. Ball Readability <!-- id: P-080 -->
The ball is a **focal point for interaction**, not a chaos generator.
*   Throws should remain consistent (predictable arcs).
*   Fumbles may be slightly dynamic but must remain **readable and contestable**.
*   Uncertainty should come from *players* (inputs/collisions), not random physics noise.
*   **Justification:** The ball must be predictable so player decisions, not object randomness, determine outcomes.
*   **Protects Concepts:** C-006, C-005

### 9. Hazards, Death, and Reset Migration <!-- id: P-090 -->
*   **Hazards are Population Control:** Voids/death zones are not "punishment flavor" — they regulate engagement density by removing participation. Removing even one player for several seconds strongly changes scoring probability because pressure reform depends on nearby upright participants.
*   **Water:** Does not kill. Makes you swim (effectively irrelevant). Prevents meaningful contest until you return to playable area. Triggers ball reset (center).
*   **Voids/Pits/Lava:** Triggers ball reset. Kills and forces respawn potentially far from the ball. Can create 10+ second absence from engagement.
*   **Ball Resets tied to hazards are intentional:** They rapidly re-center the fight at a predictable convergence point. Reset is not downtime — reset is forced re-scrum.
*   **Resets:** Players may *intentionally* reset the ball (e.g., throwing into void) to relocate the contest, especially to avoid conceding near their own goal.
*   **Respawn Participation:** Respawn timing must allow players to re-enter an active play rather than only the next play. The game relies on overlapping participation.
*   **Protects Concepts:** C-010, C-003, C-007

### 10. Reversals and Hype <!-- id: P-100 -->
The system must maximize opportunities for **sudden reversals**: clutch goal saves, swarm escapes, tackle chains, jump-flung catches, predicted interceptions.
> **Constraint:** Scoring must remain meaningful and hype; it is the emotional payoff.
*   **Protects Concepts:** C-004, C-001

> **Continuous Loop Protection:** The game must continuously cycle through these phases during active play. Any change that causes play to remain in a single phase for extended periods (permanent control, permanent stalemate, or uncontested movement) violates the design.

### 11. WHAT BREAKS EFT (Explicit "Do Not Do" List) <!-- id: P-900 -->
*   Making possession safe/stable (e.g., shields, infinite speed)
*   Making throws risk-free or instant, or allowing mobility during throw (removes the "commit" decision)
*   Removing fumbles/resets (removes the scramble)
*   Making the ball highly chaotic/random (removes prediction)
*   Softening knockdowns so consequences vanish (removes threat)
*   Allowing players to meaningfully act while knocked down (removes participation removal)
*   Slowing respawns so players can't rejoin continuous play (breaks flow)
*   Removing head-on momentum influence or making head-ons symmetric/random (removes skill gap)
*   Over-smoothing friction that creates tension windows (removes "The Curve")
*   Making ball resets create downtime instead of immediate convergence
*   Preventing scrums from forming (insufficient density or mechanics changed)
*   Delaying or controlling automatic possession transfer on contact
*   Bots outperforming humans or replacing humans rather than scaffolding population
*   "Sports simulation" expectations replacing chaotic collision sport identity
*   Cleaner or more realistic physics that delete outcome signatures (EFT is arcade-reliable with expressive collision outcomes, not a realism sim)

### 12. Excluded Mechanics <!-- id: P-910 -->

| Mechanic | Reason |
|----------|--------|
| Power Struggles (QTEs) | Button-mashing minigame. UNIVERSALLY HATED |
| Items (tomahawk, nitro, booze) | Unbalanced, deferred to post-launch |
| Throwing guide/pathtracing | "Noob mechanic, lowers skill expression" |
| Aim assist on tackles | Skill expression is the point |
| Formations / assigned roles | Emergent behavior only |
| Play-by-play AI calling | No plays exist. Continuous flow |
| Stoppages after tackles | **NEVER.** Play is ALWAYS continuous |
| Turn-based possession | Possession is volatile by design |
| High Jump (crouch-charge) | Useless feature, removed |
| Alt Dive (self-ragdoll) | Useless, removed |
| Featherball | Unused ball state, removed |
| Overtime scoreball | Disabled -- prefer draw over infinite overtime |

### 13. Behavioral Guarantees (Possession & Collision) <!-- id: P-950 -->

#### Possession Volatility
> **Invariant:** Possession should naturally change hands frequently during active play. The carrier should feel temporarily empowered but inevitably threatened within seconds. If carriers can reliably retain the ball for extended periods, the system is broken.
*   **Protects Concepts:** C-002, C-001

#### Collision Density (Swarm Requirement)
> **Invariant:** Players should regularly be within a few seconds of a meaningful interaction (tackle attempt, interception attempt, or contested ball). Long stretches without threat or contest indicate a broken gameplay state. EFT requires collision density to be EFT. Players remain near the engagement because influence exists near the next possession transfer. There are no persistent roles and no formations — functions last seconds: tackler → carrier → victim → tackler again.
*   **Protects Concepts:** C-003, C-001, C-011

#### Carrier Emotional Tension
> **Invariant:** The carrier must feel dangerous but not safe. A scoring attempt should always feel possible and always feel interruptible. Mechanics must preserve simultaneous empowerment and vulnerability.
*   **Protects Concepts:** C-004, C-009

### 14. Behavioral Guarantees (Commitment & Participation) <!-- id: P-960 -->

#### Core Player Skill Clarification
> **Invariant:** EFT rewards early commitment under uncertainty. Players succeed by acting before full information exists.

Mechanics must reward decisive early action more than late reaction. A player who arrives early and commits should usually outperform a player who reacts perfectly but too late.

*   This includes both:
    *   predicting future interaction locations and moving early
    *   forcefully contesting space in a swarm to influence the outcome

Do not frame the game as purely prediction-based or purely mechanical. The system must support both behaviors.
*   **Protects Concepts:** C-009, C-005

#### Collision Commitment
> **Invariant:** In high-density situations (multiple players contesting a ball or carrier), physical commitment and space-clearing must remain effective strategies. Swarm interactions are a core gameplay state and must not be optimized away.

Large group scrambles around a loose ball or pressured carrier are a desirable gameplay state.
*   **Protects Concepts:** C-001, C-006

---

### 14. Behavioral System Requirements <!-- id: P-970 -->

These are not mechanics and not balance rules. They describe multiplayer behavioral conditions the system must preserve so the gameplay works.

#### Shared Attention Convergence
The game must naturally pull most players toward the same evolving conflict location without coordination. Systems such as carrier vulnerability, loose ball behavior, short respawn, and central resets must combine to cause players to repeatedly converge on a shared play. If players begin spreading out, wandering, or remaining disengaged from the main play, the gameplay system is incorrect even if scoring still functions.

#### Global Readability
Major events (turnovers, breakaways, saves, last-second stops) must be understandable to all players immediately. The ball, its motion, and outcomes must be visually readable so players can anticipate and emotionally react to events across the map. Changes that improve physical realism but reduce player understanding or awareness are incorrect.

#### Universal Influence
Low-skill participation must still meaningfully affect play outcomes. Body presence, pressure, accidental interference, and recovery attempts should influence plays even without precise mechanical execution. The system must not require high mechanical skill for a player to matter within a play.

#### Map Authority
Arena geometry regulates gameplay timing and interaction density. Maps are not scenery — they are gameplay regulators. Geometry changes re-entry timing, collision angles, number of simultaneous participants, hazard removal frequency, throw survival probability, and cascade likelihood. Maps alter the behavior of the swarm, not just aesthetics. Open maps increase interaction frequency and swarm chaos; structured/hazard maps increase prediction, punishment, and participation removal. During engine porting, the engine must be adapted to preserve map behavior rather than altering maps to fit new physics assumptions. A correct EFT implementation treats map design as system tuning, not decoration.

---

## PART II -- SIMULATION MODEL (How the Game Works)

> **Engine Note:** This model relies on standard **Source Engine (Havok) physics**.

### 1. Movement & Charge <!-- id: M-110 -->

| Property | Value | Notes |
|----------|-------|-------|
| Gravity | 600 HU/s^2 | Reduced from Source default of 800 |
| Friction | 6.0 | Engine default (not set by gamemode) |
| Accelerate | 5.0 | Engine default (not set by gamemode) |
| Air accelerate | 10.0 | Engine default (not set by gamemode) |
| Base max speed | 350.0 HU/s | Empty-handed |
| Carrier speed | 262.5 HU/s | 75% of max (350 × 0.75) |
| Pity carrier speed | 315.0 HU/s | 90% of max |
| Strafe-only speed | 160.0 HU/s | When not pressing forward |
| Charge threshold | 300.0 HU/s | Must exceed to tackle |
| Wiggle boost | ~+10 HU/s | Emergent from Source air strafing (not a code constant) |
| Bhop cap | Engine-controlled | Source engine handles via sv_maxvelocity (default 3500) |

*   **Charge State:** Active when grounded and speed > 300 HU/s. The charge animation begins at 280 HU/s so the visual reads as already threatening by the time the tackle fires.
*   **Charge State Economy:** Carriers always operate below charge threshold (~263 HU/s), making them prey. Defenders must build to 300+ to tackle, then manage wall contact and turning penalties to maintain speed. Teammates' core job is to body-block pursuers (legal at any speed) and buy the carrier a route to the goal or a throw window. A carrier's survival depends on tight turns, wall bounces to reset angles, and ramp-boosted exits — not on outrunning defenders.
*   **Acceleration:** ~1.5s to reach max speed from stop; ~1.0s to reach charge threshold.
*   **Wall Punishment:** Hitting any obstacle sets speed to 0. Requires full re-acceleration.

**Forward-Locked Charging ("The Missile" Mechanic):**
- Pressing W (Forward) disables strafing (A/D ignored)
- Steering is via mouse yaw only
- Prevents zig-zag abuse while tackling

**Speed Building Formula (from shared.lua line 439):**
```lua
newspeed = math.max(curspeed + FrameTime() * (15 + 0.5 * (400 - curspeed)) * acceleration, 100)
         * (1 - math.max(0, math.abs(math.AngleDifference(move:GetMoveAngles().yaw, curvel:Angle().yaw)) - 4) / 360)
```

Key properties:
1. Accelerates faster when slower (catches up from 0 quickly)
2. 4-degree grace zone before turning penalty applies
3. Minimum speed always 100 HU/s
4. Strafe-only caps at 120 HU/s
5. Side input zeroed when pressing forward

**Anti-Bunny Hop (Landing Penalty):**
- On landing, if horizontal speed > max * 1.05: reduce by 15%
- Bhops only maintain speed going down ramps/off jump pads (NOT gain speed on flat)

*   **Supports Concepts:** C-005, C-009

### 2. Knockdown & Recovery <!-- id: M-120 -->

| Property | Value |
|----------|-------|
| Knockdown duration | 2.75 seconds |
| Post-hit immunity | 0.45 seconds |
| Anti-stunlock immunity (per-attacker) | 2.0 seconds |
| Total effective removal from play | ~4-5 seconds (knockdown + re-acceleration) |

*   **Recovery:** Player must stand up (anim) and accelerate. Total effective removal from play ~4-5s.
*   **Chain Stunning:** Different attackers bypass each other's per-attacker immunity timers -- 3 players CAN chain-stun a single target. Hitting a downed player resets their knockdown timer.
*   **Supports Concepts:** C-002, C-001

### 3. Tackle Mechanics (The Core Interaction) <!-- id: M-130 -->

| Property | Value |
|----------|-------|
| Charge threshold | 300.0 HU/s |
| Tackle range | BoundingRadius() (dynamic, ~24 HU per player) |
| Knockdown duration | 2.75 seconds |
| Impact force | Target velocity = charger velocity x 1.65 |
| Attacker recoil | Velocity x -0.03 (nearly stops) |
| Charge damage | 5 |
| Punch damage | 25 |

**Charging is GROUND ONLY:**
- Jumping = instantly lose charge state = cannot tackle while airborne
- Air is a VULNERABLE state in EFT (opposite of bhop games)

**Head-on Collision Resolution:**
- Higher speed wins -> lower speed player gets knocked down
- Both on ground + close speed (<24 HU/s difference) = "HEAD ON!" -- mutual knockback (both knocked down but recover faster)
- Ground player always beats air player
- **Carrier CANNOT initiate charge hits** -- must drop ball first or rely on teammates

**Emergent Head-on Technique: "The Curve"**
- Turning slightly INTO an approaching enemy (within the 4-degree grace zone) gains speed without penalty
- This is a single committed curve to one side, NOT a snake/oscillation
- Creates ~355-360 HU/s vs a straight-line player's ~350 HU/s
- Head-ons were won by tiny margins (0.8 HU/s difference could decide the outcome)
- 360 HU/s was the theoretical max -- hitting it consistently was the hallmark of top players

**Cross Counter (Parry):**
- If a charger runs into a player during the last 0.2s of their punch animation, the punch **cross-counters** the charge
- Charger's horizontal velocity is zeroed and they enter spinny knockdown state
- Very tight timing window -- too early or too late means you get tackled as normal

*   **99% of combat is charging/tackling** -- punching is rare (only when cornered)
*   **Supports Concepts:** C-006, C-009

### 4. Combat Matrix (Rock-Paper-Scissors) <!-- id: M-135 -->

| Matchup | Result |
|---------|--------|
| Charge vs Neutral | Charge wins (tackle) |
| Charge vs Charge | Higher speed wins; close = mutual knockback |
| Dive vs Neutral | Dive wins |
| Dive vs Charge | Charge wins |
| Punch vs Charge (cross-counter timing) | **Punch wins** (spinny knockdown!) |
| Punch vs Charge (bad timing) | Charge wins (you get tackled) |
| Dive vs Punch | Punch wins |
| Neutral vs Neutral | Solid stop (both <300: act as walls) |

### 5. Dive Mechanics <!-- id: M-140 -->

| Property | Value |
|----------|-------|
| Trigger | Attack2 while charging (>=300 HU/s, grounded, not carrying ball) |
| Extra speed | +100 HU/s added to current velocity |
| Upward boost | 320 HU/s |
| Duration | Until landing |
| ALWAYS ends in knockdown | Yes (diver becomes vulnerable) |
| Hit reward | -0.5s recovery (faster getup) |
| Miss penalty | +0.5s recovery (slower getup) |
| Turn rate during dive | Rate-limited: 90°/sec (via util.LimitTurning) |
| Crouching during dive | Disabled (IN_DUCK stripped) |
| Can pick up ball | Yes (if touched during dive) |

*   **Supports Concepts:** C-009, C-001

### 6. Punch Mechanics <!-- id: M-145 -->

| Property | Value |
|----------|-------|
| Range | BoundingRadius() (dynamic, same as tackle) |
| State duration | 0.5 seconds (full punch animation lock) |
| Cross-counter window | Last 0.2 seconds of punch state |
| Force | 360 impulse |

### 7. Possession Rules <!-- id: M-150 -->
*   **Pickup:** Touch ball trigger (prop_balltrigger uses Roller_Spikes.mdl physics hull).
*   **Strip:** Tackle causes immediate fumble.
*   **Passing:** Throwing forces possession loss.
*   **Carrier:** Entity holding ball. Speed capped. Cannot initiate tackles (must drop/throw first).
*   **Knocked-down pickup:** NO -- must recover first.
*   **Auto-pickup:** Yes (run through = grab). No pickup key, no pickup delay, no confirmation animation gate. This is intentional and central to the game feel. New players are frequently surprised by sudden turnovers caused by running into a loose ball — this is by design. "Oh shit I have it" moments create instant retargeting and maintain pace. Any added smoothing that makes possession feel controlled reduces EFT's chaos identity. Every loose ball is immediately contested.
*   **Tackles are first-class outcomes.** A tackle that strips a breakaway carrier is as game-changing as a goal. The scoreboard tracks both goals and tackles. Defenders who strip consistently are contributing as much as scorers.
*   **Supports Concepts:** C-002, C-009, C-001

### 8. Fumble / Ball Loose <!-- id: M-160 -->

| Property | Value |
|----------|-------|
| Fumble horizontal velocity | Carrier velocity x 1.75 |
| Fumble vertical pop | 128 HU/s |
| Ball mass | 25 |
| Ball damping | 0.01 linear, 0.25 angular |
| Bounce reduction | 0.75x velocity on bounce |
| General immunity (after drop) | 1.0s (m_PickupImmunity) |
| Team pass immunity | 0.2s after throw (ball); 0.25s (carry items) |

*   **State:** Ball becomes `STATE_FREE`.
*   **Ball behavior:** Static/heavy. Does not roll freely. Bounces on steep ramps.
*   **Supports Concepts:** C-006, C-001, C-007

### 9. Passing & Throw Windup <!-- id: M-170 -->

| Property | Value |
|----------|-------|
| Input | Hold RMB to windup, release to throw |
| Windup time | 1.0 seconds (max power) |
| Movement during windup | 0 HU/s (completely frozen in place) |
| Arc type | Grenade (gravity-affected parabolic) |
| Throw impulse | 1100 along aim vector (single directional force) |
| Speedball windup | 0.5x (faster) |
| Speedball carrier speed | 1.5x (stacks with carrier penalty) |

**Throw Commitment Window (The Longest Voluntary Vulnerability):**
Throwing is the longest voluntary vulnerability state in the game. During throw, movement speed = ~0 (100 HU/s shuffle). A full throw requires surviving >1 second of uninterrupted pressure in a game where 1 second is huge. Throwing is a gamble: full power = high reward, very low survival probability; early release = lower reward, higher probability; cancel = rarer survival choice. Passing skill is primarily prediction of interruption timing, not aim accuracy. Many passes are "get it somewhere" throws, not perfect planned routes.

**Throwing Risk (The 25% Rule):**
- ~25% of pass attempts fail (carrier tackled mid-windup) in simulated play
- In chaotic real servers: failure rate can exceed 75%
- Running into goal is almost always safer than throwing
- On throw-only maps (Slam Dunk): throwing is MANDATORY, making blocking teammates essential

*   **Supports Concepts:** C-008, C-009, C-004

### 10. Jump Mechanics <!-- id: M-175 -->

| Property | Value |
|----------|-------|
| Vertical speed | 200 HU/s |
| Cooldown | 0.3 seconds |
| Breaks charge state | YES -- cannot tackle while airborne |

### 11. Obstacle Collision ("Walls") <!-- id: M-178 -->

> **CRITICAL DEFINITION:** "Wall" in EFT does not mean only vertical walls. It means ANY piece of map geometry that stops your forward progress: walls, platforms, pillars, props, ramps at wrong angles, map edges.

- Running into ANY obstacle: player **stops instantly** (no sliding, no bounce)
- **No wall-running or slide mechanics** -- intentionally simple
- **Stopping = dropping below 300 HU/s = losing charge state = ~4+ seconds of vulnerability**

**Wall Slam (on knocked-down players):**
- When a knocked-down player slides into a wall at speed >=200 HU/s:
  - 0.9 second wall freeze (stuck to wall, can't get up)
  - Visual: wall slam effect + screen shake
  - Only triggers on steep surfaces (wall normal z < 0.65)
  - 10 HP damage (functionally irrelevant -- what matters is TIME LOST)

### 12. Collision Model <!-- id: M-179 -->

| Interaction | Result |
|-------------|--------|
| Opponents | Solid collision. Tackle logic applies |
| Teammates | **Pass-through** (no collision) -- prevents griefing |
| Knocked-down players | Solid to ALL (obstacle) |

### 13. Hazards & Resets <!-- id: M-180 -->

| Hazard | Player Effect | Ball Effect |
|--------|--------------|-------------|
| Lava (Temple Sacrifice) | Death | Instant reset via `trigger_ballreset` |
| Water | Swims (useless) | Instant reset |
| Bottomless Pit | Death | Reset on `trigger_ballreset` brush |
| Roof/Stuck | -- | 20s timer reset |

**Ball Reset Triggers (20 second timer):**
- Untouched for 20 seconds -> resets to midfield
- Enters water -> instant reset
- Carrier in deep water -> instant reset
- Hits skybox -> reset
- Carrier airborne 20+ seconds -> reset (anti-exploit)

*   **Supports Concepts:** C-007, C-010, C-001

### 14. Scoring <!-- id: M-190 -->

| Property | Value |
|----------|-------|
| Goal value | 1 point |
| Run-in (Touchdown) | Carrier enters goal zone (SCORETYPE_TOUCH = 1) |
| Throw-in | Thrown ball enters goal zone (SCORETYPE_THROW = 2) |
| Both | Bitmask 3 = touch + throw |
| Post-goal slow-motion | 2.5s at 0.1x time scale |
| Timer suppress after throw | 5 seconds grace period |

**After score:** Slow-motion celebration -> ball resets to center -> 6s post-round celebration -> 5s pre-round freeze -> play resumes.

*   **Supports Concepts:** C-001, C-004

### 15. Match Structure <!-- id: M-195 -->

| Setting | Value |
|---------|-------|
| Goal cap | 10 (EFT2, up from 7) |
| Match time | 15 minutes (900s) |
| Ball reset timer | 20 seconds untouched |
| Warmup | 30 seconds |
| Respawn delay | 5.0s auto-respawn (MinimumDeathLength) |

**BonusTime (Timer Sync):** After each goal, celebration + pre-round time (~11s) is added back to the game clock. This ensures the round timer only counts live play time.

### 16. Pity Mechanic <!-- id: M-198 -->

- **ConVar:** `eft_pity` (default: **4**)
- **Trigger:** One team trails by 4+ goals
- **Effect:** Losing team's ball carrier speed multiplier changes from 0.75x to 0.9x of max speed
- Result: Pity carrier moves at ~315 HU/s instead of ~263 HU/s
- Still slower than empty-handed chasers (350 HU/s)
- **Not a separate "Rage Mode"** -- just the ball entity's `Move()` function checking `HasPity()`

### 17. Team Sizes <!-- id: M-199 -->

| Setting | Value |
|---------|-------|
| Minimum (bots fill) | 3 per team |
| Max bot fill | 6 per team |
| Competitive (EFL) | 5v5 |
| Public typical | 5v5 to 10v10 |

### Simulation Events (Canonical API)

*   **E-210 TackleResolve(attacker, victim, context)** -- Fires when two players collide at charge speed.
*   **E-220 PossessionTransfer(from, to, reason)** -- Fires on Pickup, Catch, Strip.
*   **E-230 BallLoose(origin, impulse)** -- Fires on Tackle (Strip), Throw release, Reset spawn.
*   **E-240 BallReset(reason)** -- Fires on Hazard touch, Goal scored, Stagnation timer.
*   **E-250 PlayerKnockdown(player, cause)** -- Fires on Tackle outcome, Wall slam.
*   **E-260 PlayerRecovered(player)** -- Fires on Timer expiry. State -> NONE.
*   **E-270 GoalScored(team, method)** -- Fires when ball satisfies goal condition.

---

## PART III -- THE FEEL (What the Mechanics Produce)

> **FOR LLMs/AI AGENTS:** This section explains what the mechanics in Part II *produce* -- the player
> experience they exist to create. If a mechanic seems arbitrary after reading Part II, re-read this
> section. The mechanic likely exists to serve one of these principles.

### The Soul of EFT <!-- id: SOUL -->

Football is the theme. The actual genre is a **spatial prediction and pressure-management game.**

> **Extreme Football Throwdown is a high-frequency role-switching arena game where collision physics
> create localized crises, and players continuously predict, cause, and escape those crises.**

**1. EFT is not about possession -- it is about transitions.**
The game is a rapid cycle of player states: defender, interceptor, carrier, escort, loose-ball scrambler. Players do not pick roles. Physics assigns roles repeatedly. Every tackle or fumble instantly creates a new micro-game. The fun comes from how often your importance changes. Stable carry is not the core — possession change is the core.

**2. The real resource is charge state -- a threat state, not a speed value.**
At 300+ HU/s grounded, you control space. Below charge state, you are prey. Walls, jumps, and sharp turns matter because they force you to lose state and become vulnerable. The question for every code change is not "does this affect speed?" but "does this affect when players feel like predators vs prey?"

**3. The core gameplay loop is collapse and breakout.**
1. Someone stabilizes the ball. 2. Pressure converges. 3. A mistake becomes inevitable. 4. Collision occurs. 5. Ball becomes free. 6. A new player escapes. The goal is the reward. The breakout from chaos is the gameplay.

**4. Both carrying and passing must remain viable -- neither can dominate.**
EFT balances two competing player identities: the hero (juking, escaping the swarm) and the reader (predicting space, throwing ahead of pressure). The mechanics sit in a narrow band where both personalities are viable.

**5. The primary skill is anticipation, not reflex.**
Players are not reacting to events. They are reacting to confirmed predictions. Good defenders don't chase the carrier -- they move to where the carrier will be after the next interaction.

**6. Defense creates action, not stoppage.**
In most sports, defense stops play. In EFT, a tackle is a generator of a new play. The ball pops loose, roles reassign, a new crisis begins.

**7. The rhythm creates flow state.**
Knockdown (2.75s) -> recovery -> re-acceleration (1.5s) -> re-engage creates repeating engagement intervals. Players subconsciously synchronize to these windows. Any change that alters these intervals disrupts the rhythm.

### The Charge State Economy <!-- id: FEEL-CHARGE -->

Charge state (>=300 HU/s + grounded) is the single most important resource in EFT. It is analogous to **energy in an aerial dogfight** -- without it, you are a sitting duck.

**The "Aerial Dogfight on a Flat Plane":**
- **Energy Management:** You trade speed for turn radius.
- **Commitment:** Once you pick a line, you are committed. You can't stop and turn 180 without losing all energy.
- **Boom and Zoom:** You slash through the scrum at high speed, striking and passing through. You don't "stay" in the fight.

| Situation | Charge? | Threat Level |
|-----------|---------|-------------|
| Sprinting at 350, grounded | YES | Maximum -- you tackle anyone you run into |
| Just landed from jump, 280 HU/s | NO | Vulnerable -- anyone can tackle you freely |
| Hit a wall, 0 HU/s | NO | DEAD -- the swarm eats you |
| Sharp turn, dropped to 290 | NO | Exposed -- briefly vulnerable |
| Ball carrier at ~263 | NO (usually) | Target -- everyone is chasing you |
| Pity carrier at 315 | YES | Dangerous -- carrier CAN tackle defenders |

**The "1.5-second eternity":**
Going from 0 to 350 takes ~1.5 seconds. Going from 0 to 300 takes ~1.0 seconds. In a game where everyone else is a 350 HU/s missile, being stationary for 1.5s means you will be hit, stunned, hit again. The danger of walls is NOT the impact -- it is the loss of STATE.

### The Air Vulnerability Paradox <!-- id: FEEL-AIR -->

**Airborne = immune to tackles BUT cannot tackle.** This creates tactical tension:

| State | Can Be Tackled? | Can Tackle? | Strategic Use |
|-------|----------------|-------------|---------------|
| Grounded, charging | Yes (head-on) | Yes | Default combat state |
| Airborne | No | No | Evasion / repositioning |
| Landing | Yes | Depends on speed | Vulnerable transition |

**When jumping is SMART:** Carrier evading a tackle, reaching elevated platforms, throw setup from height, crossing gaps.

**When jumping is STUPID:** While being chased on flat ground (bhop penalty), in a scrum (need charge to contest), when you're the last defender.

### The Cognitive Model (How Humans Actually Perceive EFT) <!-- id: FEEL-COGNITIVE -->

This section exists to prevent future implementations from over-intellectualizing the sport.

Players did NOT think in strategy terms. They did not think: formations, lanes, routes, positions, planned plays. Instead, players operated on immediate prediction. Experienced players constantly evaluated only one question: **"Where will the next possession event occur within the next 1-2 seconds?"**

They were not tracking the ball itself. They were tracking the *next collision that would decide the ball.* The ball is a signal, not the objective. The real objective is being upright and arriving at the next interaction before everyone else.

Because of this, good players often moved slightly away from the current carrier — not toward them — when they predicted a tackle was imminent. This is not zoning or positioning. It is pre-reaction. A player could appear passive for half a second and then instantly become decisive because they moved to the *future* interaction location rather than the present one.

The game was learned procedurally, not instructionally. After only minutes of play, humans formed a subconscious predictive loop: observe → anticipate interruption → reposition → collide → retarget. Skill expression felt intuitive rather than analytical. Players were not executing knowledge — they were executing anticipation.

### Reflex Continuity (The Preservation Goal) <!-- id: FEEL-PRESERVATION -->

EFT strongly imprints because it trains predictive reflexes under social reinforcement: extremely short feedback loops, immediate consequence visibility, public skill signaling (especially head-on wins), high repetition density, rivalry and recognition. Players did not memorize EFT — they internalized it, similarly to a sport or a musical instrument.

**The goal of any port is not visual fidelity. The goal is reflex continuity:** a veteran player should instinctively react correctly within seconds of joining, before consciously analyzing mechanics. If a veteran must relearn interaction timing, the implementation is incorrect even if mechanics appear identical.

Veterans can often predict outcomes before they occur because the system is consistent, not random. This property must be preserved. If a new engine produces the same reflex responses from players, it is EFT. If it produces slower deliberative play, it is not.

### Required Player Perceptions <!-- id: FEEL-PERCEPTIONS -->

A correct implementation should cause players to feel:
*   Pressured while holding the ball
*   Immediately relevant upon spawning
*   Able to predict a breakout before it occurs
*   Responsible when losing a head-on
*   Urgency during throw commitment
*   Chaotic density near the engagement

Players should NOT commonly feel:
*   Safe carrying the ball
*   Methodical play development
*   Formation-based tactics
*   Long uncontested movement
*   Delayed relevance after spawning

**If player perception shifts toward planning instead of reacting, the implementation has diverged.**

### Cross-Domain Validation <!-- id: FEEL-DOMAINS -->

> **PURPOSE:** Eight real-world systems from unrelated domains independently converge on the same behavioral invariants as EFT. Each domain extracts a principle that can be used to validate or diagnose EFT implementations. If a mechanic violates a domain's extracted invariant, it is probably wrong.

**The unified conclusion across all domains:**

> EFT is not a positional sport. EFT is a state transition ecosystem. The ball is not a goal object — it is a moving state generator. Players are not actors — they are reactive agents in a continuously collapsing and reforming interaction field.

---

#### Domain 1 — Rugby Ruck / Broken Play

In rugby, the ball is rarely "owned." It is protected while vulnerable. Players don't guard space — they guard the transfer event. What matters is not scoring. What matters is who is upright near the ball at the moment of transition.

**Extracted invariant:** Possession is determined by proximity + stability at the instant of state change, not planning.

**EFT application:** The important skill is not carrying — it is being upright and facing the right direction when the carrier stops being upright. Bots and players should prioritize proximity to instability, not goal anticipation.

---

#### Domain 2 — Predator Mobbing (Birds Harassing a Hawk)

Observed behavior: agents do not attack simultaneously. They probe. One commits when perceived risk dips. Others fill immediately after disengagement.

**Extracted invariant:** Continuous pressure comes from alternating commitment, not simultaneous commitment. Engagement is staggered.

**EFT application:** This is exactly why scrums don't freeze. Players naturally cycle: approach → feint → tackle → recover → rejoin. Bots that simultaneously commit produce "dogpile syndrome" — everyone arrives at once, knocks each other around, and the carrier escapes untouched. Staggered pressure is the correct model.

---

#### Domain 3 — Traffic Shockwave Flow

In traffic systems: disturbance → compression → release → re-compression. No driver coordinates this. Density causes it.

**Extracted invariant:** Local disruptions propagate outward then re-center on a moving attractor.

**EFT application:** Tackle = disturbance. Fumble = wave collapse. New carrier = new attractor. Players do not "switch targets consciously." They snap. Good human players exhibit instant target migration. Bots must replicate this — immediate reorientation to the new attractor, no lingering pathing toward the previous carrier.

---

#### Domain 4 — Financial Market Microstructure

In high-frequency trading, ownership of an asset changes rapidly in high-interaction zones. The decisive agents are not those predicting long-term value — they are physically positioned (order queue priority) at the instant liquidity appears.

**Extracted invariant:** The advantage belongs to the agent closest to the transfer interface, not the agent with the best long-term plan.

**EFT application:** Ball pickup is a contact interface. Strategic positioning at the scrum edge > running lanes > goal anticipation. A bot positioned on the scrum perimeter when the carrier falls picks up the ball. A bot already running toward the goal does not. This single principle makes bots look human.

---

#### Domain 5 — Multi-Agent Pursuit/Evasion Robotics

Multiple drones intercept a moving target using only local sensing. They do not plan a route to the target's goal. They maintain a shrinking envelope around the target's movement potential.

**Extracted invariant:** Control is achieved by surrounding movement potential, not intercepting final destination.

**EFT application:** Good players don't run to the goal line — they compress the carrier's available movement options. Attacking angles rather than chasing position. A bot that always charges directly at the carrier is trivially juked. A bot that cuts off the carrier's likely exit angle is not.

---

#### Domain 6 — Basketball Pickup (Uncoached, 3v3)

Nobody assigns roles, yet functional spacing appears. Players unconsciously fill gaps, avoid redundancy, and reposition after contact. The shared focal object (ball) anchors spacing without communication.

**Extracted invariant:** Humans maintain functional spacing without communication when a shared focal object exists.

**EFT application:** The ball is the spacing anchor. Bots that cluster directly behind teammates or run parallel chase paths produce redundant coverage. Angular diversity around the carrier — multiple approach vectors — produces emergent coordination that looks coached but isn't.

---

#### Domain 7 — Fighting Game Neutral (Prediction Layer)

In high-level fighting games, winning exchanges are not mechanical. They occur when one player commits to an action space before the other recognizes the commitment window.

**Extracted invariant:** Skill is detecting commitment windows, not reacting to completed actions.

**EFT application:** The throw windup is a commitment window. The correct response is to target throw startup — not wait for ball release. A carrier standing still is already in a commitment window: they are about to throw or they are already absorbing a tackle. Bots should treat stationary carriers as highest-priority threats, not neutral actors.

---

#### Domain 8 — Cellular Automata State Transitions

Each cell has only local rules. Complex global patterns emerge from local transitions, not from any cell knowing the global state.

**Extracted invariant:** Complex emergent behavior does not require complex agents. It requires correct local state transitions.

**EFT application:** This is the most important bot design lesson. Do not give bots strategy trees. Give them correct state reactions.

```
IF near carrier AND carrier unstable → position for pickup
IF carrier just fell               → snap to loose ball (instant)
IF I am knocked down               → recover → return to nearest conflict
IF teammate has ball               → maintain angular diversity, not formation
IF throwing window detected        → commit immediately, not on release
```

The complexity the player perceives ("those bots feel smart") emerges from correct local rules, not from any bot knowing "the plan."

---

#### Synthesized Bot Design Rule

All eight domains reinforce the same priority order for bot decision-making:

1. **Be upright** — participation is the resource
2. **Be near the current transfer interface** — not the previous one, not the predicted goal
3. **Snap to new attractors instantly** — no lingering on old targets
4. **Stagger commitment** — probe, not dogpile
5. **Attack angles, not positions** — compress options, don't chase location
6. **Maintain angular diversity** — never parallel, never clustered
7. **Detect commitment windows** — act on windup, not release
8. **Local rules only** — no strategy trees; correct transitions produce emergent strategy

### Veteran Gameplay Knowledge <!-- id: FEEL-VETERAN -->

**Mindgames Over Mechanics:**
At the highest level, EFT is PRIMARILY about mindgames and prediction, NOT mechanical execution. The mechanics are intentionally simple (hold W, turn, tackle). What separates an EFL veteran from a pub player is reading the opponent's intent 1-2 seconds before they act.

**Speed management is a constant decision:**
- Every yaw adjustment > 4 degrees per frame costs speed
- Good players make micro-corrections (1-3 degrees) to stay in the grace zone
- They read the field geometry far ahead so they never NEED to turn sharply

### The Player Decision Model <!-- id: FEEL-DECISIONS -->

> **PURPOSE:** This section defines how players perceive, decide, and act. Before modifying ANY
> gameplay code: 1. Identify which decisions this model the change touches. 2. Predict whether
> veteran players would make different choices. 3. If yes, the change alters the game -- flag it.
> **The test is not "does the code work?" The test is "would a 1000-hour player still play the same way?"**

#### 18.1 What Information Players React To

| Information Source | What It Tells | Response Time |
|---|---|---|
| Relative position of nearest enemy | "Am I about to be tackled?" | Instant |
| Own speed (proprioceptive) | "Am I in charge state?" | Constant |
| Ball carrier identity | "Is it me, my team, or the enemy?" | <0.5s |
| Distance to goal | "Can I score before I'm caught?" | Read once on pickup |
| Teammate positions | "Is anyone open?" | Peripheral, low priority |
| Map geometry ahead | "Wall? Ramp? Jump pad?" | Constant forward scan |
| Enemy velocity vectors | "Which direction is the tackler coming from?" | 1-2s lookahead |
| Knockdown bodies on ground | "Obstacle or enemy about to stand up?" | Peripheral |
| Score / time remaining | "Play safe or go desperate?" | Checked occasionally |

Players do NOT react to individual mechanics. They react to **spatial pressure** -- the feeling that the space around them is closing.

#### 18.2 Safe vs Threatened

**SAFE:** Moving at 340+ with no enemies in forward cone; teammate has ball; just respawned; on elevated platform; open field to goal.

**THREATENED:** Carrying ball (25% slower); speed below 300; enemy directly ahead; in a corridor; winding up a throw; just landed from a jump; knocked down.

**THE CRITICAL TRANSITION -- "The 1.5-Second Eternity":**
Going from 0 to charge speed takes ~1.5 seconds. Every player knows this. Every player feels the panic when they hit a wall and hear the charge sound of enemies converging. This is the signature anxiety of EFT. Any change that shortens or lengthens this window fundamentally alters the game's emotional rhythm.

#### 18.3 What Causes Scrums

Scrums (4-12 players converging on a ~200 unit radius) are the defining visual of EFT. They are NOT a bug. They are the core experience.

**Formation:** Ball reset to center (symmetric spawns -> simultaneous arrival), fumble in open space, high-bounce throw lands in contested space, carrier tackled near midfield.

**Resolution:** Someone gets a clean pickup during a gap, a tackle creates a brief lane, ball bounces out of the scrum to a perimeter player, random positional advantage.

**Duration:** Typically 2-5 seconds. If longer, ball usually bounces to perimeter. This rewards staying outside the scrum -- a key veteran skill.

**Any change that prevents scrum formation removes the most exciting part of the game.**

#### 18.4 When Players Run vs Throw

```
I HAVE THE BALL. What do I do?

|- Path to goal clear? -> RUN. Always.
|- Close to goal (<~500 units)? -> RUN.
|- 2+ enemies ahead AND teammate closer to goal AND open?
|   -> CONSIDER throwing. 75% of the time, still run.
|- On elevated platform? -> THROW is viable (height advantage).
|- Throw-only map? -> THROW is mandatory. Team must block.
|- DEFAULT -> RUN.
```

**Key insight:** Anything that makes throwing safer shifts the run/throw ratio toward throwing, turning EFT from a running game into a passing game -- a fundamentally different sport.

#### 18.5 Why Positioning > Reaction Time

**Positioning decisions that win games:**
- Rotation after scoring: don't chase center, position at midfield for the breakout
- Cut angles: diagonal intercept 200 units ahead, not direct chase
- Scrum perimeter: stay 150 units outside, wait for the ball to pop out
- Goal-side positioning: always between carrier and your goal
- Ramp awareness: take ramps over jumps to maintain speed

**Reaction time barely matters because:** Forward-facing proximity detection (BoundingRadius), carrier always slower, head-ons decided by speed not clicks, meaningful decisions happen 1-2 seconds before contact.

#### 18.6 The Emotional Arc of a Match

```
0:00-0:30  WARMUP       Relaxed. Players goof off, emote, chat.
0:30-1:00  FIRST SCRUM  Explosive. Everyone sprints to center. Energy spikes.
1:00-5:00  EARLY GAME   Establishing tempo. Score usually 1-2 each.
5:00-10:00 MID GAME     Patterns set. Pity activates if gap hits 4+.
10:00-13:00 LATE GAME   Tension rises. Mistakes feel catastrophic.
13:00-15:00 FINAL PUSH  Maximum intensity. Overtime threat looms.
OVERTIME    SUDDEN DEATH Raw panic. Next goal wins.
```

**Changes that flatten this arc make EFT feel monotonous. The crescendo matters.**

#### 18.7 Evaluation Checklist for Proposed Changes

1. **Speed/vulnerability:** Does this alter how long a player is vulnerable after losing speed?
2. **Carrier risk:** Does this make carrying safer or more dangerous?
3. **Throw viability:** Does this make throwing more or less attractive relative to running?
4. **Scrum formation:** Does this affect how or whether scrums form?
5. **Positioning vs reaction:** Does this reward positioning or reaction time?
6. **Emotional arc:** Does this flatten the tension curve of a match?
7. **Decision preservation:** Would a veteran make the same choice in the same situation?

---

## PART IV -- COMMENTARY / HISTORY / INTENT

*(This section captures context and "why". It does not override Part I.)*

### History
Created by **William "JetBoom" Moodhe** on **NoxiousNet** (October 2012). Built on Fretta13 for Garry's Mod. Steam Workshop: 275,283 subscribers, 10,944 five-star ratings. EFT survived the community's shutdown because of its unique "sport" feel -- it wasn't just a mod, it was a competitive discipline.

### Community Context (Server Culture)
EFT historically functioned as a persistent server "place", not matchmaking. Players joined mid-game, left mid-game, rejoined, memed, trolled, or played seriously. The game did not teach controls well (poor F1/help; context mostly learned by playing). The sport survived because: the core loop is robust to non-optimal play, skill was visible enough to form rivalry and reputation (especially head-ons), and community identity persisted across nights. EFT can be goofy/wacky in tone while still being taken seriously by players. The esport-like seriousness came from rivalry and repetition, not from presentation polish. Do not sterilize identity signals that create culture (e.g., quick feedback, scoreboard readability), but do not design "for trolling" either. The system should survive it naturally.

### Competitive Era: Extreme Football League (EFL)

EFT had a formal 5v5 draft league that ran **8 seasons** across two eras (~2014-2018):
- **EFTFL** (Extreme Football Throwdown Football League): Seasons 1-3
- **EFL** (Extreme Football League): Seasons 1-5

**Championship Winners:**

| Season | Champion | Finals Score |
|--------|----------|--------------|
| EFTFL S1 | Enigmatis | 3-0 |
| EFTFL S2 | Grimace | 3-0 |
| EFTFL S3 | Grimace | 3-0 |
| EFL S1 | lilzzfla1 | 3-0 |
| EFL S2 | cool | 3-0 |
| EFL S3 | lilzzfla1 | 3-0 |
| EFL S4 | Madden | 3-1 |
| EFL S5 | Rin | 3-0 |

**Career Scoring Leaders (estimated cross-season):**

| Player | Est. Career TDs | Notes |
|--------|----------------|-------|
| Madden | 119+ | S4 champion, highest PPG multiple seasons |
| Enigmatis | 112+ | Captain in 4/5 EFL seasons |
| lilzzfla1 | 104+ | 2x EFL champion |
| HeadCrusher | 76+ | Consistent first-round pick |
| Later_Gator | 62+ | S5 scoring leader (1.29 PPG) |
| dissident | 57+ | First overall pick in S3 and S5 |
| cool | 53+ | EFL S2 champion |

### Community Slang
- **"Jetboom'd":** Anything janky or broken
- **"Bodycamping":** Camping near knocked-down players
- **"Bodywalls":** Despised blocking wall tactic
- **"Melondriver":** Reckless high-speed drive-by playstyle

### Player Archetypes (Emergent, Not Assigned)

| Archetype | Tendency | Strength | Weakness |
|-----------|----------|----------|----------|
| **Carrier** | Runs ball in personally | High score output | Slow, predictable |
| **Passer** | Quick passes | Unpredictable, fast | Risky if intercepted |
| **Clearer** | Tackles for teammates | Enables team, disrupts | Low personal score |

Elite teams balance all three. Pure anything gets countered.

### Expert Tactics
- **"The Train":** Team moves as pack, clearing for carrier
- **"Bait and Switch":** Carrier draws defenders, passes to trailing teammate
- **"Punch Trap":** Stand near goal, counter-punch incoming charger (cross-counter timing)
- **"Fumble Camp":** Position near expected fumble spot, grab loose ball
- **"The Screen":** Teammate body-blocks defender, creating lane

### The Chaos Scale (Scale Sensitivity)

EFT functions across multiple population sizes but behavior changes with density. The system must remain playable at low counts and chaotic at high counts without mechanical rule changes.

| Player Count | Chaos Level | Feel |
|-------------|-------------|------|
| 3v3 | Tactical | Higher individual influence, more readable interactions. Every player matters. 1v1 duels |
| 5v5 (EFL) | Competitive sweet spot | Frequent scrums, balanced chaos and prediction. Target baseline |
| 10v10 | Pub standard | Fun chaos. Heavy swarm behavior. Breakaway runs feel heroic |
| 15v15 | Carnage | Rapid cascade resolution. Ball changes hands 5+ times in a single scrum |
| 20v20 | ABSOLUTE BEDLAM | Kill feed is a waterfall of possession changes |

### Flow & Rhythm
The match has a musical rhythm: *Scrum (Crescendo) -> Breakout (Release) -> Chase (Tension) -> Goal (Climax) -> Reset (Silence).* Disrupting this rhythm with too many stoppages or long downtimes kills the "flow state" veterans enter.

### Maps as Behavioral Parameters
Maps are not scenery or movement puzzles — they are **behavioral regulators** that tune the swarm. Geometry changes: re-entry timing, collision angles, number of simultaneous participants, hazard removal frequency, throw survival probability, and cascade likelihood.
*   **Open maps:** Higher scoring, more swarm chaos, more constant collisions. Favor carriers (dodge space).
*   **Structured/hazard maps:** Stronger prediction layer, stronger punishment via participation removal. Favor defenders.
*   **Good Maps:** Create intercept points and force routing decisions. A player who dominates one map may struggle on another.
*   **Bad Maps:** Are just open fields (boring) or overly cluttered (random).
*   Map variety is desirable. EFT maps should differ in playstyle, not just textures.
*   Any map must support the **Continuous Contest**.

### The 2-Second Rule (Statistical Proof)

| Metric | Value |
|--------|-------|
| Turnovers per minute | 3.2 |
| Average possession (Red) | 1.63 seconds |
| Average possession (Blue) | 2.80 seconds |
| Max possession | 20.5 seconds |
| Chaos spikes per match | 22 |

Carrier at ~263 HU/s vs Defenders at 350 HU/s = defenders WILL catch up. Carrier has ~2 seconds of clear running before tackle or pass is forced.

---

## TRACEABILITY GLUE

### Trace Index

| ID | Name | Code Anchor |
| :--- | :--- | :--- |
| **P-050** | Movement/Speed | `gamemode/sh_globals.lua` (`SPEED_CHARGE`, `SPEED_RUN`) |
| **M-110** | Charge Logic | `gamemode/obj_player.lua` (`PlayerController:CanCharge`) |
| **M-130** | Head-On/Tackle | `gamemode/obj_player.lua` (`PlayerController:ChargeHit`) |
| **M-120** | Knockdown | `gamemode/obj_player.lua` (`PlayerController:KnockDown`) |
| **M-150** | Possession | `gamemode/obj_ball.lua` |
| **M-170** | Throw Windup | `gamemode/states/throw.lua` |
| **M-190** | Scoring | `entities/entities/trigger_goal.lua` |
| **E-210** | Tackle Event | `gamemode/obj_player.lua` (Calls `GameEvents.OnPlayerKnockedDownBy`) |
| **B-000** | Bots | `gamemode/obj_bot.lua` (OOP AI), `gamemode/sv_bots.lua` (spawning/hooks) |

### Commenting Standard
```lua
/// Implements M-130 and P-060. See MANIFEST: M-130.
function ResolveTackle(attacker, victim) ...
```

---

## APPENDIX A -- SCENARIO LIBRARY <!-- id: APP-A -->

**S-001 Goal Line Stand**
*   **Setup:** Carrier is <50 HU from goal. Defensive tackler is charging.
*   **Trigger:** Carrier touches goal trigger 0.1s after Tackle occurs.
*   **Expected:** Carrier is launched away. Ball comes loose. No score.
*   **Anti-Outcome:** Carrier scores despite being hit.
*   **Demonstrates Concepts:** C-004, C-001

**S-002 Panic Short Pass**
*   **Setup:** Carrier swarmed by 2 defenders.
*   **Expected:** Ball is released low velocity, bounces nearby.
*   **Anti-Outcome:** Ball stuck to carrier; ball thrown perfectly straight.
*   **Demonstrates Concepts:** C-002, C-006

**S-003 Long Throw Recovery**
*   **Setup:** Carrier throws high arc downfield to empty space.
*   **Expected:** Ball is recoverable. Enables self-passing / "Advancement".
*   **Anti-Outcome:** Ball rolls forever; ball glitches through floor.
*   **Demonstrates Concepts:** C-008, C-007

**S-004 Jump-Flung Fumble**
*   **Setup:** Carrier jumps and is hit mid-air.
*   **Expected:** Carrier flung far. Ball flies in arc. Verticality adds chaos.
*   **Anti-Outcome:** Carrier drops straight down.
*   **Demonstrates Concepts:** C-006, C-009

**S-005 Swarm Collapse**
*   **Setup:** Ball is loose. 4 players converge.
*   **Expected:** Players collide/stun. Ball might pop out again.
*   **Anti-Outcome:** One player slides through ghosting everyone.
*   **Demonstrates Concepts:** C-001, C-003

**S-006 Mid-Field Collection**
*   **Setup:** Ball lobbed across middle. Defender cuts lane.
*   **Expected:** Defender runs through ball path to collect (no catch mechanic).
*   **Note:** "Interception" is difficult; usually involves collecting the bounce/lob.
*   **Demonstrates Concepts:** C-005, C-003

**S-007 Escort Clearing**
*   **Setup:** Carrier following Escort. Defender approaches.
*   **Expected:** Escort tackles Defender. Carrier continues.
*   **Demonstrates Concepts:** C-003, C-001

**S-008 Intentional Hazard Reset**
*   **Setup:** Carrier pinned near own goal attempts a "Safety".
*   **Expected:** Throw ball into void (instant reset) or pit (20s reset).
*   **Result:** Ball resets to CENTER. Creates "NBA Tip-Off" style chaos/tackles.
*   **Demonstrates Concepts:** C-002, C-007

**S-009 Head-On Speed Duel**
*   **Setup:** Player A (357 speed) hits Player B (356 speed).
*   **Expected:** Player B knocked down. Deterministic skill reward despite tiny margin.
*   **Note:** 340 HU/s would be below charge speed and lose to ANY charger.
*   **Anti-Outcome:** Random winner; both fall.
*   **Demonstrates Concepts:** C-006, C-009

**S-010 Last-Second Touchdown Stop**
*   **Setup:** Carrier airborne into goal. Defender hits carrier frame before entry.
*   **Expected:** Denial.
*   **Demonstrates Concepts:** C-004, C-001

**S-011 Loose Ball Bounce**
*   **Expected:** Predictable reflection. Readability.
*   **Anti-Outcome:** Ball stops dead or flies erratically.
*   **Demonstrates Concepts:** C-006, C-005

**S-012 Respawn Rejoin**
*   **Setup:** Player dies. Ball is contested in scrum.
*   **Expected:** Player spawns and reaches scrum before it resolves. Continuous Relevance.
*   **Demonstrates Concepts:** C-010, C-003

**S-013 Choke Corridor Fight**
*   **Setup:** Ball in narrow hallway.
*   **Expected:** Body blocking effective.
*   **Demonstrates Concepts:** C-001, C-002

**S-014 Score Counter-Attack**
*   **Setup:** Team A scores. Ball resets to center immediately.
*   **Expected:** Team B can rush center to attack. Rhythm/Flow.
*   **Demonstrates Concepts:** C-007, C-010

**S-015 Tackle Chain**
*   **Setup:** A tackles B. Ball pops to C. D tackles C. Rapid succession.
*   **Expected:** 2 knockdowns, chaotic ball. Peak excitement moment.
*   **Anti-Outcome:** Global cooldowns prevent D hitting C.
*   **Demonstrates Concepts:** C-002, C-006

**S-016 Goal Line Intercept**
*   **Setup:** Loose ball rolling into goal. Player runs to cut it off.
*   **Expected:** Save. Hero moment.
*   **Note:** Diving is risky as you might fly *over* the ball.
*   **Demonstrates Concepts:** C-004, C-003

**S-017 Mid-Air Catch**
*   **Setup:** Ball thrown high. Player jumps to intercept at apex.
*   **Expected:** Catch and carry momentum. Skill expression.
*   **Demonstrates Concepts:** C-005, C-009



**S-019 Carrier Juke**
*   **Setup:** Defender charges straight. Carrier strafes.
*   **Expected:** Defender flies past. Carrier gains space. Evasion skill.
*   **Demonstrates Concepts:** C-009, C-005

**S-020 Bot Positioning**
*   **Setup:** Ball loose right side.
*   **Expected:** Bot moves to intercept future position. AI competence.
*   **Anti-Outcome:** Bot runs to current ball (behind play).
*   **Demonstrates Concepts:** C-005, C-003

---

## APPENDIX B -- PLAYER ARCHETYPES <!-- id: APP-B -->

**A-001 The Ballhog Runner** -- Never passes. Runs straight for goal. Strong in 1v1 juking, weak against swarms. Bot: `Aggressive`, `Low Pass Frequency`.

**A-002 The Safe Passer** -- Throws immediately upon pressure. Good ball retention, low scoring threat solo. Bot: `Supportive`, `High Pass Frequency`.

**A-003 The Defensive Interceptor** -- Ignores carrier, watches lanes. Turnover generation specialist. Bot: `Defensive`, `Lane Watcher`.

**A-004 The Space Clearer (Escort)** -- Head-hunter. Tackles closest enemy to carrier. Makes holes. Bot: `Aggressive`, `Target Player`.

**A-005 The Reset Strategist** -- Map-aware. Dumps ball to void to reset contest location. Bot: `Tactical`, `Zone Aware`.

**A-006 The Opportunistic Scavenger** -- Hovers near packs. Waits for fumble, then bursts. Scoring off pileups. Bot: `Reactive`, `Burst Speed`.

**A-007 The Predictive Defender** -- Moves to where you *will* be. Ignores jukes, plays the destination. Bot: `High Skill`, `Future Prediction`.

**A-008 The Panic Thrower** -- Low stress tolerance. Mashing throw when touched. Creates chaos. Bot: `Low Skill`, `Panic Threshold`.

---

## APPENDIX C -- MECHANIC PURPOSE BLOCKS <!-- id: APP-C -->

### M-110 Charge/Movement
*   **Purpose:** Movement is skill-based (strafing/curving) rather than stat-based.
*   **Enables:** "The Curve" (turning into hits).
*   **Punishes:** Passive movement, straight lines. **Failure Modes:** If removed, game becomes stat-check.
*   **Related Scenarios:** S-009, S-019. **Related Principles:** P-050, P-060.

### M-120 Knockdown
*   **Purpose:** Consequences for losing a duel. **Enables:** Power plays (4v3 temporarily).
*   **Failure Modes:** Too short = no advantage. Too long = player leaves flow.
*   **Related Scenarios:** S-005, S-007. **Related Principles:** P-020, P-040.

### M-130 Head-On Collision
*   **Purpose:** Dispute resolution mechanism. **Enables:** Physical dominance without RNG.
*   **Failure Modes:** Randomness kills agency.
*   **Related Scenarios:** S-009. **Related Principles:** P-060.

### M-150 Possession
*   **Purpose:** Designate the target. **Enables:** Scoring, "It" status.
*   **Failure Modes:** Infinite possession breaks loop.
*   **Related Scenarios:** S-001. **Related Principles:** P-010, P-950.

### M-170 Passing
*   **Purpose:** Risk/Reward tool for relocation. **Enables:** Escaping pressure, advancing play.
*   **Failure Modes:** Instant passing removes interception threat.
*   **Related Scenarios:** S-002, S-003. **Related Principles:** P-070.

### M-180 Hazards/Resets
*   **Purpose:** Force location changes. **Enables:** Strategic resets, defensive saves.
*   **Failure Modes:** Resets breaking flow (too slow).
*   **Related Scenarios:** S-008. **Related Principles:** P-090.

---

## APPENDIX D -- CONTINUOUS RELEVANCE PRINCIPLE <!-- id: APP-D -->

**The Axiom:** During active play, most players should be within a few seconds of influencing a scoring attempt or its prevention.

**Why:** Short respawn (~5s) ensures return to the same tactical "sentence." Maps maximize convergence. Possession instability keeps the battle moving. No fixed roles means everyone can engage.

**Violation:** If a player spends >10s running to catch up to play, the map or movement speed is broken.

---

## APPENDIX E -- TRACEABILITY STANDARD <!-- id: APP-E -->

**Header Format:**
```lua
/// MANIFEST LINKS:
/// Mechanics: M-### (List implemented mechanics)
/// Events: E-### (List triggered/handled events)
/// Principles: P-### (List upheld principles)
/// Scenarios validated: S-### (List scenarios this code enables)
```

**Primary Code Anchors:**
*   M-110 Charge: `gamemode/obj_player.lua`
*   M-120 Knockdown: `gamemode/obj_player.lua`
*   M-150 Possession: `gamemode/obj_ball.lua`
*   M-170 Passing: `gamemode/states/throw.lua`
*   B-000 Bots: `gamemode/obj_bot.lua` (OOP AI class), `gamemode/sv_bots.lua` (spawn/hooks)

---

## APPENDIX F -- MAPS & ENTITIES <!-- id: APP-F -->

### Map Roster (VMF-Verified)

| Filename | Display Name | Score Types | Push Pads | Powerups | Ball Resets | Notes |
|----------|-------------|-------------|-----------|----------|-------------|-------|
| `eft_slamdunk_v6` | **Slam Dunk** | Throw(x2) + Touch(x2) | 10 | speedball(x2) | 0 | Basketball theme. Separate throw/touch goals. Platforms, ramps |
| `eft_bloodbowl_v5` | **Bloodbowl** | Touch(x2) + Throw(x4) | 0 | none | 4 | Flat NFL stadium. Wide open |
| `eft_baseballdash_v3` | **Baseball Dash** | Throw(x2) | 1 | speedball(x2) | 7 | Baseball diamond. Popular for 20v20. Throw-only |
| `eft_big_metal03r1_d` | Big Metal | default touch | 0 | none | 0 | Industrial. Minimal entities |
| `eft_chamber_v2` | Chamber | Touch(x2) | 0 | speedball(x2) | 1 | Enclosed arena |
| `eft_cosmic_arena_v2` | Cosmic Arena | Touch(x2) + Throw(x2) | 5 | speedball(x10) | 6 | Space theme. Most powerups |
| `eft_legoland_v2` | Legoland | Touch(x2) | 0 | speedball(x2) | 2 | Colorful blocks |
| `eft_miniputt_v1r_d` | Mini Putt | Throw(x2) + Both(x2) | 12 | none | 0 | Golf themed. Most push pads (12). Multiple goal types |
| `eft_sky_metal_v2` | Sky Metal | Throw(x2) | 16 | speedball(x1) | 1 | Elevated platforms. Most push pads (16) |
| `eft_skyline_v3` | Skyline | Touch(x2) | 0 | none | 1 | Rooftop setting |
| `eft_skystep_v4` | **Skystep** | Throw(x2) | 0 | speedball(x2) | 5 | Floating platforms. Tight corridors. Throw-only |
| `eft_soccer_b2` | Soccer | Both(x2) | 0 | none | 0 | Soccer field. Most permissive scoring |
| `eft_spacejump_v6` | **Space Jump** | Throw(x2) | 10 | speedball(x1) | 8 | Low gravity areas. Many push pads |
| `eft_temple_sacrifice_v2` | **Temple Sacrifice** | Throw(x2) | 5 | none | 11 | Aztec theme. Lava. Most ball resets (11) |
| `eft_tunnel_v2` | Tunnel | Touch(x2) | 8 | none | 4 | Underground corridors. Touch-only |

### Map Design Patterns

**Goal type creates map identity:**
- **Touch-only** (Tunnel, Skyline, Chamber, Legoland): Run the ball in. Pure speed/rotation gameplay.
- **Throw-only** (Baseball Dash, Skystep, Space Jump, Temple Sacrifice, Sky Metal): MUST throw. Creates pressure throw dynamic.
- **Hybrid** (Slam Dunk, Bloodbowl, Soccer, Mini Putt, Cosmic Arena): Multiple scoring methods. Most strategic variety.

**Push pad density correlates with verticality:**
Sky Metal (16), Mini Putt (12), Slam Dunk (10), Space Jump (10) = heavy vertical play.

**Ball reset brush count reflects hazard density:**
Temple Sacrifice (11), Space Jump (8), Baseball Dash (7) = many hazard spots.

### Map Geometry as Tactical Space

| Feature | Tactical Purpose | Example |
|---------|-----------------|---------|
| Raised platforms | Alternate run lanes, throw positions | Slam Dunk |
| Ramps | Smooth speed transitions between elevations | Most maps |
| Jump pads | High-speed launches, surprise angles | Slam Dunk, Skystep |
| Narrow corridors | Chokepoints favoring defenders | Tunnel |
| Wide open areas | Favor carriers (dodge space) | Bloodbowl, Soccer |
| Pits/hazards | Zone denial, intentional ball resets | Space Jump |
| Pillars/obstacles | Break line of sight, juke opportunities | Various |

**Each map was designed to feel unique:** A player who dominates Bloodbowl (flat, speed-based) may struggle on Slam Dunk (vertical, prediction-based).

### Mapping Entity Reference (from FGD)

**Core Gameplay Entities:**

| Entity | Type | Purpose |
|--------|------|--------|
| `trigger_goal` | Brush | Goal zone. `scoretype`: 0=none, 1=touch, 2=throw, 3=both. `teamid`: 1=Red, 2=Blue |
| `prop_goal` | Point | Visual goal model |
| `prop_ball` | Point | Ball spawn point. Outputs: `onreturnhome`, `ondropped`, `onthrown`, `onpickedup` |
| `trigger_ballreset` | Brush | Ball reset zone |
| `trigger_jumppad` | Brush | Push zone. `pushvelocity`, `knockdown`. Legacy alias: `trigger_abspush` (identical logic, kept for old maps) |
| `trigger_knockdown` | Brush | Knockdown zone. `knockdowntime` (default 3.0s) |
| `trigger_powerup` | Brush | Powerup zone. Types: `speedball`, `blitzball`, `waterball`, `iceball`, `magnetball`, `scoreball` |

**Spawn Entities:** `info_player_red`, `info_player_blue`, `info_player_spectator`, `logic_norandomweapons`

**Support Entities:** `logic_teamscore` (score event I/O), `env_teamsound` (team-specific sounds)

### Ball Powerups

| Powerup | Effect | Active? |
|---------|--------|--------|
| `speedball` | Speed boost, faster throw windup (0.5x), stronger throw (1.25x) | Active |
| `waterball` | Carrier runs on water surface | Active |
| `iceball` | Near-zero friction: ball slides and rolls freely; low damping, ice physics material | Active |
| `blitzball` | Ball on fire from explosion proximity | Legacy |
| `magnetball` | Ball attracts to nearby players | Disabled |
| `scoreball` | Scoring modifier | Disabled |

---

## APPENDIX G -- BOT AI DESIGN <!-- id: APP-G -->

> **Purpose:** Bots exist to prevent empty-server inertia and maintain engagement density. They are population scaffolding, not dominance agents. They must: keep the server "alive" at low population, preserve swarm identity and contested possession loops, leave as humans join (already implemented), and never dominate humans. Bots should feel like mid-level humans: active, sometimes wrong, sometimes brilliant, often chaotic. They should be tuned by prediction horizon and decision quality, not raw mechanical advantage.
>
> **The Rocket League Bot Philosophy:** Each bot is an independent agent making LOCAL decisions based on spatial awareness. No centralized "play caller." Emergent coordination from individual intelligence. Bots should prioritize being upright near the next interaction, re-entering conflict after displacement, and influencing transitions rather than "running plays." Passing behavior should be modeled as interruption prediction (can I survive the >1s throw window?), not receiver targeting perfection.

### Domain-Validated Design Constraints

Before writing any bot logic, confirm it satisfies the cross-domain invariants from `FEEL-DOMAINS`:

| Domain | Constraint | Anti-pattern it prevents |
|--------|-----------|-------------------------|
| Rugby Ruck | Position for transition, not goal | Bots pre-running to goal line |
| Predator Mobbing | Stagger commitment, don't dogpile | All bots committing simultaneously |
| Traffic Shockwave | Instant target migration on possession change | Bots lingering on old carrier |
| Market Microstructure | Scrum edge > running lanes | Bots "clearing out" from the fight |
| Pursuit/Evasion | Attack angles, not positions | Bots running directly at carrier |
| Basketball Pickup | Angular diversity around ball | Bots forming lines or parallel paths |
| Fighting Game Neutral | Target throw windup, not release | Bots reacting only after ball leaves |
| Cellular Automata | Local state rules only | Bots running strategy trees |

### Core Bot Behaviors (Priority Order)

1. **ALWAYS HOLD FORWARD** -- `IN_FORWARD` at all times. Speed = life.
2. **NEVER run into walls** -- Multi-ray obstacle avoidance is critical.
3. **Use NavMesh Pathfinding** -- If direct path blocked and navmesh exists, use A*.
4. **AVOID PITS** -- Look ahead 350 HU. Detect drops AND hazard triggers.
5. **Steer with yaw, not strafing** -- Match the human control scheme.
6. **Angle-cut Intercept** -- Predict target position (Pos + Vel*Time).
7. **Punch/Jump when stuck** -- If blocked > 0.5s, Jump+Punch to clear.
8. **Run Straight when Clear** -- No idle weaving.
9. **Juke intelligently** -- Only if enemy is DIRECTLY head-on (>0.9 dot).

### State Decision Tree

```
IF knocked down -> keep thinking
IF carrying ball -> run to goal (NavMesh pathing if needed)
  - Clear path? -> RUN STRAIGHT
  - Enemy head-on? -> Side step
  - Stuck against enemy? -> PUNCH
IF ball is loose -> EVERYONE chase (Intercept path)
  - "Run Over" downed enemies if in path (Bully behavior, 30% chance)
IF teammate has ball -> SWARMING ORBIT:
  - Orbit biased by Personality (Support stays close)
IF enemy has ball -> ALL CHASE CARRIER:
  - Rusher: Direct intercept
  - Defender: Hangs back (Sweeper)
```

### Movement Model (Bot Inputs)

**The "Always Hold W" Rule:** `cmd:SetButtons(IN_FORWARD)` is hardcoded. Bots drive like cars: gas always down. Speed controlled by turning radius.

**Steering & The "Grace Zone":**
- If abs(CurrentYaw - DesiredYaw) < 4 degrees: Turn immediately (safe).
- If abs(CurrentYaw - DesiredYaw) > 20 degrees: Drift turn. Wide arc to preserve momentum.

**Wall/Pit Avoidance (Raycast Array):**
- Lookahead: 600 HU (~2s of travel).
- Array: 5 rays (-30, -15, 0, +15, +30 degrees relative to velocity).
- Pit Detection: Secondary cast at floor angle. Avoids `trigger_hurt` and `nodraw`.

### Personality Traits

| Trait | Bias | Effect |
|-------|------|--------|
| **Rusher** | Distance -300 | Aggressively claims attacker role. Chases relentlessly |
| **Support** | Distance +0 | Balanced. Orbits carrier, fills gaps |
| **Defender** | Distance +300 | Falls to sweeper. Stays between goal and ball |

### Advanced Tactics

**Shadow Defense (Last Man Back):**
- When bot is closest to its own goal, switches to shadow defense
- Retreats towards goal matching attacker's speed
- Uses LookBack mechanic (`IN_RELOAD` key) to keep eyes on threat
- Only commits to tackle if attacker enters "Red Zone" (<400 units from goal) or gets too close (<150 units)
- Imperfection: 2% per-tick patience failure chance + positioning jitter

**Lead Blocking (The Enforcer):**
- In escort state, if a defender gets within 300 units of the carrier, bot breaks formation
- Aggressively tackles the defender to clear the lane

**Risky Passing & Hail Marys:**
- Hail Mary: If blocked and far from goal, throw high (-60 deg pitch) toward goal
- Risky Pass: If blocked by 2+ enemies, 15% chance to lead pass to teammate
- All passes use -45 degree pitch to lob over defenders

**Intelligent Pathfinding:**
- Wall avoidance uses TraceHull that ignores players (prevents "Circling" bug)
- NavMesh A* only for complex geometry (walls/corners)

### Rotation Rules
1. **Everyone chases** -- Personalities determine who commits first
2. **Swarming orbit** -- Teammate escort pattern
3. **Bully rule** -- 30% chance to target knocked-down enemy
4. **Sweeper rule** -- Lowest-rank bot acts as goalie/safety

---

## APPENDIX H -- MACHINE-READABLE CONSTANTS <!-- id: APP-H -->

```yaml
meta:
  source: "MANIFEST.md"
  target_platform: "gmod_fretta"
  physics_model: "source1_airaccel"

units:
  hu: "Hammer Units (Source engine spatial unit, ~1 inch)"
  hu_s: "Hammer Units per second (velocity)"
  hu_s2: "Hammer Units per second squared (acceleration)"

physics:
  gravity: 600
  friction: 6.0
  accelerate: 5.0
  airaccelerate: 10.0
  bunnyhop_cap: "engine-controlled (sv_maxvelocity)"

speeds:
  base_max: 350.0
  carrier_normal: 262.5
  carrier_rage: 315.0
  strafe_only: 160.0
  charge_threshold: 300.0
  wiggle_boost: 10.0

tackle:
  threshold_speed: 300.0
  range: "BoundingRadius() (dynamic)"
  knockdown_duration: 2.75
  force_multiplier: 1.65
  attacker_recoil: -0.03
  immunity:
    post_hit: 0.45
    per_attacker: 2.0
  damage:
    charge: 5
    punch: 25

dive:
  trigger: "attack2 while charging (>=300, grounded, no ball)"
  extra_speed: 100
  upward_boost: 320
  always_ends_in_knockdown: true
  recovery_modifier:
    hit_success: -0.5
    miss_whiff: 0.5
  turn_rate: "90 deg/sec (rate-limited via util.LimitTurning)"
  crouching: disabled

punch:
  range: "BoundingRadius() (dynamic, ~24 HU)"
  state_duration: 0.5
  cross_counter_window: 0.2  # last 0.2s of punch animation
  force: 360

jump:
  vertical_speed: 200
  breaks_charge_state: true

throwing:
  base_windup: 1.0
  movement_during: 0  # speed is set to 0 during windup (SPEED_THROW is unused)
  arc_type: "grenade"
  impulse: 1100  # single directional force along aim vector
  speedball_modifiers:
    windup: 0.5
    carrier_speed: 1.5

ball:
  mass: 25
  damping_linear: 0.01
  damping_angular: 0.25
  bounce_reduction: 0.75
  fumble_velocity:
    horizontal: 1.75
    vertical: 128
  pickup:
    trigger: "prop_balltrigger (Roller_Spikes.mdl physics hull)"
    auto_pickup: true
    knocked_down_can_pickup: false
  immunity_timers:
    general: 1.0
    team_pass: 0.2  # ball uses 0.2s; carry items use 0.25s
  reset_triggers:
    - "untouched_20s"
    - "enters_water"
    - "carrier_in_deep_water"
    - "hits_skybox"
    - "carrier_airborne_20s"

wall_slam:
  speed_threshold: 200
  freeze_duration: 0.9
  surface_normal_z_max: 0.65
  damage: 10

combat_outcomes:
  charge_vs_neutral: "charge_wins"
  charge_vs_charge: "higher_speed_wins_or_mutual_knockback"
  dive_vs_neutral: "dive_wins"
  dive_vs_charge: "charge_wins"
  punch_vs_charge_timed: "punch_wins"
  punch_vs_charge_mistimed: "charge_wins"
  dive_vs_punch: "punch_wins"
  neutral_vs_neutral: "solid_stop"

collision:
  opponents: "solid"
  teammates: "pass_through"
  knocked_down: "solid_to_all"

game_rules:
  goal_cap: 10
  match_time: 900
  ball_reset_timer: 20
  warmup: 30
  pity:
    trigger_deficit: 4
    carrier_speed_multiplier: 0.90
  respawn:
    delay: 5.0  # MinimumDeathLength; auto-respawn, no key press needed

team_sizes:
  minimum: 3
  maximum_bots_fill: 6
  competitive: 5

scoring:
  goal_value: 1
  scoretype_touch: 1
  scoretype_throw: 2
  scoretype_both: 3
  post_goal_slowmo:
    duration: 2.5
    time_scale: 0.1
  suppress_timer_after_throw: 5

hazards:
  lava:
    player_effect: "death"
    ball_effect: "instant_reset"
  water:
    player_effect: "swim_useless"
    ball_effect: "instant_reset"
  bottomless_pit:
    player_effect: "death"
    ball_effect: "reset_on_ball_reset_brush"

excluded:
  - name: "power_struggles"
    reason: "QTE button mashing - universally hated"
  - name: "items"
    reason: "Unbalanced, deferred for post-launch"
  - name: "guided_line"
    reason: "Noob mechanic, lowers skill expression"
  - name: "formations"
    reason: "EFT uses emergent swarm behavior, not assigned positions"
  - name: "stoppages"
    reason: "Play NEVER stops except briefly after goals"
  - name: "high_jump"
    reason: "Crouch-charge jump - useless, removed"
  - name: "alt_dive"
    reason: "Self-ragdoll on ALT - useless, removed"
  - name: "featherball"
    reason: "Unused ball state, removed"
  - name: "overtime_scoreball"
    reason: "Disabled - prefer draw over infinite overtime"
```

---

## APPENDIX I -- CONTROLS & CONVARS <!-- id: APP-I -->

### Player Controls

| Input | Neutral | Airborne | Ball Carrier |
|-------|---------|----------|-------------|
| **WASD** | Move (350 HU/s) | Air Strafe | Move (~263 HU/s) |
| **JUMP** | Jump (+200 z) | -- | Jump |
| **CROUCH** | Crouch | Auto Height | Crouch |
| **LMB** | Punch | Punch | Punch (defensive) |
| **RMB** | Dive | Dive | Throw (hold to charge) |
| **R** | Look Behind (180) | Look Behind | Look Behind |

### Spectator Controls

| Input | Description |
|-------|-------------|
| **Spacebar** | Toggle Roaming Cam / Ball Cam (Chase) |
| **Mouse Move** | (Ball Cam) Temporarily orbit for 3s, then auto-revert |
| **Clicks** | Disabled (prevents accidental player cycling) |

### Server ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `eft_gamelength` | `15` | Match duration in minutes (-1 for infinite) |
| `eft_warmuplength` | `30` | Warmup phase duration in seconds |
| `eft_overtime` | `300` | Overtime duration in seconds |
| `eft_competitive` | `0` | Competitive ruleset (0=off, 1=whitelisted items, 2=no items) |
| `eft_scorelimit` | `10` | Points needed to win |
| `eft_pity` | `4` | Goal deficit to trigger pity speed buff |
| `eft_bots_enabled` | `1` | Enable bot players |
| `eft_dev` | `0` | Enable debug overlays for bot AI |
| `eft_bots_skill` | `1.0` | Bot skill multiplier (0.1-2.0) |
| `eft_bots_count` | `10` | Target total players (bots fill empty slots, split per team) |
| `fretta_voting` | `1` | Enable end-of-game voting |
| `fretta_votesneeded` | `0.75` | Fraction of votes needed to win |
| `fretta_votetime` | `20` | Vote duration in seconds |
| `sv_gravity` | `600` | EFT uses reduced gravity (Source default is 800) |

### Client ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `eft_firstperson` | `0` | 1=first-person, 0=third-person (default) |
| `hud_deathnotice_time` | `6` | How long possession notices stay on screen |
| `hud_deathnotice_limit` | `5` | Max simultaneous notices |

### Console Commands

| Command | Access | Description |
|---------|--------|-------------|
| `eft_scan [scope]` | SuperAdmin | Scan Lua for backdoors (gamemode/addons/all) |
| `eft_netstats` | Anyone | Show network bandwidth stats |
| `eft_mapvote` | Admin | Force-start a map vote |
| `eft_mapvote_cancel` | Admin | Cancel active map vote |

### Chat Commands

| Command | Description |
|---------|-------------|
| `!top` | Show top players (if installed) |

---

## REASONING GUIDANCE FOR AI MAINTAINERS <!-- id: AI-GUIDE -->

### Design Philosophy Constraint
EFT rewards **anticipation over planning**. Players succeed by predicting the next interaction, not executing long-term strategies. Any addition that shifts success toward structured planning rather than reactive prediction is misaligned with the sport.

**When modifying or implementing a mechanic:**
1.  **Identify the mechanic's M-ID.**
2.  **Check associated C-IDs (Concepts).**
3.  **Ensure those behaviors still emerge after the change.**
4.  **Consult APPENDIX J (Behavioral Diagnostics)** -- would the change cause any drift conditions?

> **WARNING:** If a change improves clarity or fairness but weakens a linked concept (especially **C-001 Continuous Contest**, **C-002 Short Possession**, **C-003 Simultaneous Relevance**, or **C-011 Transition Dominance**), the change is **INCORRECT**.

**Evaluation Checklist (from 18.7):**
1. Speed/vulnerability -- does this alter vulnerability duration after losing speed?
2. Carrier risk -- safer or more dangerous?
3. Throw viability -- more or less attractive than running?
4. Scrum formation -- affects whether scrums form or resolve?
5. Positioning vs reaction -- which does this reward?
6. Emotional arc -- does this flatten the match tension curve?
7. Decision preservation -- would a veteran still play the same way?
8. Reflex continuity -- would a veteran instinctively react correctly, or need to relearn?

### The Definitive Test
EFT is not defined by its code. EFT is defined by a repeating human experience: **constant pressure, instant retargeting, unstable possession, sudden resolution.** If an implementation recreates those experiences, it is EFT. If it recreates the mechanics but not the experience, it is not EFT.

---

## WIKI GENERATION GUIDANCE <!-- id: WIKI-GUIDE -->

*   **Mechanics Pages:** Each **M-ID** becomes a page describing *how it works*.
*   **Strategy Pages:** Each **C-ID** becomes a page describing *why it matters* and how to play.
*   **Example Plays:** Each **S-ID** becomes a video/gif example.
*   **Map Dossiers:** Map pages audited against **C-007 Migrating Conflict Zone**.
*   **Archetypes:** **A-IDs** become "Playstyle" guides.

**Cross-Linking:**
*   Mechanics MUST link to Concepts they support.

---

## APPENDIX J -- BEHAVIORAL DIAGNOSTICS <!-- id: APP-J-DIAG -->

> This appendix allows a developer, tester, or AI system to determine whether an implementation still behaves as EFT without relying on nostalgia or memory.

### Correct Behavior (Commonly Observed During Normal Play)

*   Possession frequently changes hands within seconds
*   Carriers rarely feel safe for long durations
*   Scrums naturally form around the next expected possession event
*   Most successful goals occur immediately after a brief participation imbalance
*   Players repeatedly switch roles (tackler → carrier → victim → tackler) within short time spans
*   Throw attempts are often interrupted
*   A single removed participant can noticeably affect the next outcome
*   Players instinctively converge on a loose ball without needing incentives
*   Head-on collisions visibly reward smoother approach and timing
*   Players re-enter conflict immediately after recovery

### Drift Conditions (Implementation Is Diverging)

*   Possession chains last a long time
*   Goals result from planned advance rather than sudden break
*   Players spread across the map instead of collapsing toward interaction
*   Carriers feel safe while moving
*   Throws frequently succeed without protection
*   Head-ons feel symmetrical or random
*   Scrums are rare or optional
*   Players hesitate after a turnover instead of instantly retargeting
*   Removing one player has little effect on the next few seconds

If drift conditions appear consistently, the sport is no longer functioning as intended even if mechanics appear identical.

### Acceptable Variance (Across Engine Ports)

The following MAY vary: rendering, animation system, networking architecture, physics solver implementation, code structure.

The following MUST remain functionally equivalent:
*   Automatic possession transfer on contact
*   Throw immobility and survival window
*   Head-on velocity priority resolution
*   Density-driven cascade behavior
*   Immediate retargeting after possession change
*   Participation removal via hazards or knockdown

**Preserve behavioral outcomes, not implementation details.**

### Scale Sensitivity

EFT functions across multiple population sizes but behavior changes with density.

| Population | Characteristics |
|------------|----------------|
| Low (3v3-4v4) | Higher individual influence, more readable interactions |
| Medium (5v5-6v6) | Frequent scrums, balanced chaos and prediction (target baseline) |
| High (10v10+) | Heavy swarm behavior, rapid cascade resolution |

The system must remain playable at low counts and chaotic at high counts without mechanical rule changes.

---

## APPENDIX K -- CODE REFERENCE (REVERSE LOOKUP) <!-- id: APP-K -->

| Mechanic ID | Name | Primary Files |
|---|---|---|
| **M-010** | **Physics Base / Ball Types** | `obj_ball.lua`, `obj_player.lua`, `prop_ball/states/speedball.lua`, `prop_ball/states/iceball.lua`, `prop_ball/states/waterball.lua` |
| **M-030** | **Tactics - Traps** | `trigger_jumppad.lua`, `trigger_mowerblade.lua` |
| **M-050** | **Game Flow** | `logic_teamscore.lua`, `logic_norandomweapons.lua` |
| **M-110** | **Movement & Charge** | `sv_obj_player_extend.lua`, `status__base`, `obj_player_extend.lua` |
| **M-120** | **Knockdown** | `trigger_knockdown.lua`, `status_knockdown.lua` |
| **M-130** | **Collision** | `point_divetackletrigger.lua`, `projectile_arcanewand` |
| **M-140** | **Possession** | `prop_ball`, `prop_carry_base`, `obj_ball.lua` |
| **M-150** | **Fumble** | `prop_ball`, `obj_ball.lua` |
| **M-160** | **Passing** | `obj_player_extend.lua` (Throw), `obj_ball.lua` |
| **M-170** | **Hazards** | `trigger_ballreset.lua`, `trigger_goal.lua`, `env_teamsound.lua` |
| **M-180** | **Scoring** | `trigger_goal.lua`, `round_controller.lua` |
| **P-010** | **Sport Identity** | `cl_init.lua`, `shared.lua`, `cl_hud.lua` |
| **P-040** | **Prediction Dominance** | `info_player_*.lua` |
| **P-050** | **Movement Constraints** | `sv_obj_player_extend.lua` |
| **P-060** | **Audio Cues** | `env_teamsound.lua` |
| **P-080** | **Ball Readability** | `prop_ball`, `prop_carry_*.lua` |
| **P-090** | **Reset Migration** | `trigger_ballreset.lua` |
| **P-100** | **Reversals/Hype** | `trigger_goal.lua`, `round_controller.lua` |
| **C-003** | **Simultaneous Relevance** | `trigger_jumppad.lua` |
| **C-004** | **Last-Second Intervention** | `trigger_goal.lua`, `logic_teamscore.lua` |
| **C-009** | **Status Info** | `cl_hud.lua`, `vgui_hudlayout.lua` |
| **C-010** | **Respawns** | `info_player_red.lua` |
| **B-000** | **Bot AI** | `obj_bot.lua` (OOP class), `sv_bots.lua` (spawning/hooks) |
| **HUD** | **Death Notices** | `cl_deathnotice.lua` (disabled), `vgui_gamenotice.lua` |


---

## APPENDIX L -- FUTURE FEATURES <!-- id: APP-L -->

> **Policy:** Items in this section are desired but not yet started. They are documented here so design decisions in the present don't accidentally foreclose them. Nothing here is a commitment.

---

### L-001 — D3bot Navigation Integration <!-- id: APP-L-001 -->

**Problem:** GMod's native `nav_generate` fails on EFT maps because they use custom spawn entities instead of `info_player_start`. The nav mesh generator seeds from `info_player_start`; with none present, it finds no walkable surface and aborts. On open-air BSP maps (no visleafs to bound walkable space), even `nav_mark_walkable` workarounds are fragile.

**Desired Solution:** Integrate [D3bot](https://github.com/Dadido3/D3bot), which uses a hand-placed node graph instead of the generated nav mesh. This completely sidesteps the nav_generate problem. Nodes are placed in-editor per map; the pathfinder runs on the custom graph, not the BSP nav mesh.

**Scope:**
- Strip ZS-specific bot behavior from D3bot, keep only pathfinding engine
- Replace `sv_bot_pathfinding.lua` A\* calls with D3bot graph lookups
- Build node graphs for each `xft_`/`eft_` map (~30 nodes per map: spawn zones, goal mouths, center circle, flanks)
- Node parameters for jump links where maps have elevation changes

**Status:** Not started. Bot pathfinding currently falls back to direct line-of-sight movement on all maps.

---

### L-002 — Player Stats Persistence <!-- id: APP-L-002 -->

**Problem:** All per-player statistics (goals scored, tackles landed, knockdowns dealt/received, win/loss record) are lost on map change. Match replays are recorded as JSON but are not queryable.

**Desired Solution:** SQLite-backed persistence layer keyed by SteamID64. Stats accumulated across sessions, surfaced on scoreboard and in a leaderboard command.

**Scope:**
- Schema: `players(steamid, name, games, wins, goals, tackles, knockdowns_dealt, knockdowns_received, playtime)`
- Write on: `GM:PlayerDisconnected`, `GameManager:OnRoundEnd`
- Surface via: `!stats [player]` chat command, end-of-match summary panel
- Optional: ELO rating for skill-based team balance (replaces round-robin)

**Status:** Not started. Low priority — EFT is fun without it. Do not add until server population justifies the overhead.

---

### L-003 — Discord Webhook Match Results <!-- id: APP-L-003 -->

**Problem:** Match outcomes are invisible outside the server. No way to share results, hype plays, or announce events to a community channel.

**Desired Solution:** On match end, POST a Discord webhook with: map, final score, goal scorers, MVP (most goals+tackles), match duration. On overtime, post OT start announcement.

**Scope:**
- Pure HTTP, no dependencies — Discord webhooks are a single `HTTP({url=..., method="POST", body=..., headers={...}})` call
- Triggered from `GameManager:OnMatchEnd()`
- Webhook URL stored in a server-side config file (never committed)
- Embed format: team scores, goal scorers as bullet list, map thumbnail if available

**Status:** Not started. Trivial implementation (~50 lines). Requires a Discord server to send to.

---

### L-004 — GLuaTest CI Integration <!-- id: APP-L-004 -->

**Problem:** Zero automated tests exist. Every refactor of `GameManager`, scoring, tiebreaker logic, voiceset dispatch, or knockdown timing is a regression gamble caught only by in-game play.

**Desired Solution:** [GLuaTest](https://github.com/CFC-Servers/GLuaTest) — a GMod unit testing framework with GitHub Actions integration. Spins up a real GMod test server, runs all tests, reports failures in PRs.

**Scope:**
- `lua/tests/gamemanager_test.lua`: `HasReachedRoundLimit()`, `IsOvertime()`, tiebreaker conditions, score accumulation
- `lua/tests/voice_test.lua`: `GetVoiceSet()` dispatch (model string → correct VS_* table)
- `lua/tests/ball_test.lua`: pickup immunity timers, team immunity windows
- CI: `.github/workflows/test.yml` calling the GLuaTest reusable workflow

**Status:** Not started. Framework is low-overhead to adopt. Tests are pure value during the s&box port.

---

### L-005 — Replay Viewer <!-- id: APP-L-005 -->

**Problem:** `sv_match_recorder.lua` writes semantic event JSON to `data/eft_replays/`. The files are unreadable without tooling — no in-game playback, no web viewer, no way to review key moments.

**Desired Solution:** A web-based or in-game replay viewer that reads the JSON and renders a top-down 2D field with player/ball positions over time.

**Scope:**
- Option A (simple): A standalone HTML/JS viewer that reads the JSON file and renders positions on a canvas. No server dependency.
- Option B (in-game): A spectator-mode replay system that reconstructs game state from the event log and animates it.
- Option A is the realistic first step; Option B requires significant infrastructure.

**Status:** Not started. Option A can be implemented independently of the GMod codebase.

---

### L-006 — ELO / Skill-Based Team Balance <!-- id: APP-L-006 -->

**Problem:** Current team balance is round-robin with a "least frags" tiebreaker. A new player placed against a veteran produces lopsided matches regardless of team sizes.

**Desired Solution:** ELO ratings (or Glicko-2 for reliability intervals) stored per-SteamID, used to balance teams by minimizing skill delta rather than just headcount.

**Scope:**
- Requires L-002 (persistence) as prerequisite
- ELO update: `K × (result - expected)` — ~10 lines of Lua
- Balance algorithm: enumerate all team assignments, pick the one minimizing `|sum(elo_red) - sum(elo_blue)|`
- Display: optional `[ELO: 1243]` tag on scoreboard

**Status:** Not started. Requires L-002 first. Do not add until persistent player data exists.

---

### L-007 — Ambient / Reactive Music System <!-- id: APP-L-007 -->

**Problem:** EFT has no background music. Matches are sonically flat between voice callouts and sound effects.

**Desired Solution:** State-reactive music layers: quiet ambient during preround, mid-energy loop during play, intensity swell during overtime. Implemented as GMod sound streams, not full audio middleware.

**Scope:**
- Client-side only (no bandwidth cost)
- Music cues: `MATCH_START`, `ROUND_ACTIVE`, `OVERTIME`, `MATCH_END_WIN`, `MATCH_END_LOSS`
- Volume ducks during voice callouts (already have a hook point in `sh_voice.lua`)
- Custom EFT soundtrack or CC-licensed tracks; no HL2 music (licensing)

**Status:** Not started. Requires sourcing or composing tracks.

---

## CREDITS <!-- id: CREDITS -->

**Original Conception & Code:**
*   **William "JetBoom" Moodhe** (NoxiousNet) -- *The Founder*
*   Original Repo: [Link TBD]

**Modern Resurrection & Maintenance:**
*   **Dissonance** (Review & Refactor) -- *The Steward*
*   New Repo: [Link TBD]

**Community Contributors:**
*   (TBD based on Workshop/Discord contributions)

**Links:**
*   **Server IP:** [Coming Soon]
*   **Steam Workshop:** [Coming Soon]
