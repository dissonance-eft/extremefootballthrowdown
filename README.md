# Extreme Football Throwdown

A chaotic tackle-and-score arena sports game for Garry's Mod. Two teams fight over a ball, smash each other at full speed, and try to get it into the other team's goal. No plays, no positions, no stoppages — just nonstop collisions and goals.

**Think Rocket League but you ARE the car.**

## What Is This?

EFT is Kill the Carrier turned into a competitive sport. Everyone sprints at full speed, tackles cause fumbles, and whoever touches the loose ball picks it up automatically — whether they wanted to or not. The carrier is slower than everyone else, so you've got about two seconds before someone flattens you. Score fast, pass, or get hit.

No downs. No whistles. No plays. The ball is always live and the clock never stops.

Originally created by **JetBoom** (William Moodhe) in 2012 on NoxiousNet. 275,000+ Steam Workshop subscribers. This fork preserves the original gameplay while modernizing the codebase and preparing for a future s&box (Source 2) port.

## How It Plays

1. Ball spawns at center. Both teams sprint from their spawns
2. A **scrum** forms — players pile in, tackles fly, the ball bounces between bodies
3. Someone breaks out with it
4. The carrier runs for the goal (75% speed — you WILL be caught) or throws a risky pass
5. **Score** — slow-motion celebration — ball resets to center — go again
6. **Fumble** — ball is loose — anyone can grab it — chaos continues
7. First to 10 goals or highest score when time runs out

## Controls

| Input | What It Does |
|-------|-------------|
| **W/A/S/D** | Move (you steer with the mouse like a car — W is gas) |
| **Mouse** | Aim / steer direction |
| **Left Click** | Punch (short range shove, rarely used) |
| **Right Click** | Dive (lunge attack) / Hold to throw (when carrying ball) |
| **Space** | Jump |
| **R** | Look behind you |

## Core Mechanics

**Speed is everything.** You need 300+ speed to tackle. Hitting a wall drops you to zero. Turning too hard bleeds speed. Jumping kills your charge. Being slow means being a sitting duck for ~4 seconds while you get back up.

- **Tackle** — Sprint into someone at charge speed to knock them down and strip the ball
- **Dive** — Lunge forward for extra reach. High risk: you always fall down afterward, hit or miss
- **Throw** — Hold right click to wind up, release to throw. You're nearly frozen while aiming — throwing is a gamble. Most passes get interrupted
- **Head-On Collisions** — Two chargers hit each other? Higher speed wins. Tiny differences matter. The best players "curve" into hits to gain a few extra units of speed
- **Cross-Counter** — A perfectly timed punch can parry an incoming charge. Extremely tight window

**The carrier is always slower.** 265 speed vs everyone else's 350. You're the target. Teammates help by body-blocking defenders to buy you a lane or a throwing window.

## Teams

- **Red Rhinos** vs **Blue Bulls**
- 3v3 minimum (bots fill empty slots) up to 20v20 in public servers
- The competitive league (EFL) ran 5v5 across 8 seasons (~2014-2018)

## Maps

15 maps, each playing completely differently:

| Map | What Makes It Unique |
|-----|---------------------|
| **Slam Dunk** | Basketball hoops, jump pads, elevated platforms. Vertical chaos |
| **Bloodbowl** | Wide-open NFL stadium. Pure speed and open-field juking |
| **Baseball Dash** | Throw-only goals. You MUST pass — making teammate blocking essential |
| **Temple Sacrifice** | Aztec theme with lava pits. Most hazardous map in the game |
| **Space Jump** | Low gravity zones, floating platforms, 10 jump pads |
| **Skystep** | Tight corridors on floating platforms. Throw-only. One wrong step and you're dead |
| **Tunnel** | Underground corridors and chokepoints. Defenders dominate |
| **Cosmic Arena** | Space theme with 10 speed powerups scattered around |
| And 7 more... | Each with unique layouts, scoring rules, and hazards |

Maps determine whether goals accept **run-ins** (carry the ball in), **throw-ins** (throw it in), or **both** — completely changing how each match plays.

## Installation

1. Subscribe on the [Steam Workshop](https://steamcommunity.com/sharedfile/filedetails/?id=2022813030) — or clone this repo into `garrysmod/gamemodes/`
2. Start a server with gamemode `extremefootballthrowdown`
3. Load any `eft_` map
4. Bots fill empty team slots automatically

## Server Settings

| ConVar | Default | What It Does |
|--------|---------|-------------|
| `eft_gamelength` | 15 | Match length in minutes |
| `eft_scorelimit` | 10 | Goals to win |
| `eft_bots_enabled` | 1 | Fill empty slots with bots |
| `eft_bots_skill` | 1.0 | Bot difficulty (0.1 - 2.0) |
| `eft_bots_count` | 10 | Target total players (bots fill the rest) |
| `eft_competitive` | 0 | Competitive ruleset (0=off, 1=limited items, 2=no items) |
| `eft_overtime` | 300 | Overtime duration in seconds |
| `eft_pity` | 4 | Goal deficit before losing team gets a speed boost |

## Competitive History

EFT had a real competitive scene. The **Extreme Football League (EFL)** ran 8 seasons of drafted 5v5 play from ~2014-2018. Players were scouted, drafted, and competed for championships. Career scoring leaders included Madden (119+ TDs), Enigmatis (112+), and lilzzfla1 (104+). Head-on collision skill was the primary ranking signal — winning by fractions of a unit of speed separated the veterans from everyone else.

## Credits

- **JetBoom** (William Moodhe) — Original creator, NoxiousNet
- **dissonance** (dissident93) — This fork: modernization, bot AI rewrite, s&box port prep
- **NoxiousNet community** — Years of competitive play that defined what EFT is

## License

See [license.txt](license.txt).
