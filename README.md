# Extreme Football Throwdown

A continuous-play physics-based arena sport gamemode for Garry's Mod.

**Think "Rocket League but you ARE the car."** Everyone chases whoever has the ball, tackles cause fumbles, possession is volatile, and the clock never stops.

## What Is This?

EFT is digital Kill the Carrier. Two teams of players sprint across enclosed arenas, tackling each other at full speed to cause fumbles, then racing to carry or throw the ball into the opposing team's goal. There are no downs, no stoppages, no assigned positions. The ball is always live. Average possession lasts about two seconds before someone gets flattened.

Originally created by **JetBoom** (William Moodhe) in 2012 on NoxiousNet. This fork preserves the original gameplay while adding smarter bot AI and preparing the codebase for a future s&box (Source 2) port.

## Teams

- **Red Rhinos** vs **Blue Bulls**
- 3v3 minimum (bots fill empty slots) up to 20v20 in public servers
- Competitive league (EFL) ran 5v5 across 8 seasons

## How It Plays

1. Ball spawns at center
2. Both teams sprint from symmetric spawns — a **scrum** forms as players converge
3. Tackles cause fumbles. Possession changes constantly
4. Someone breaks out with the ball
5. Carrier runs toward the goal (slower than everyone else) or throws a high-arc pass
6. **Score** → brief slow-motion celebration → ball resets to center
7. **Fumble** → ball is loose → anyone grabs it → chaos continues
8. First to 10 goals or highest score when time runs out wins

## Core Mechanics

**Speed is everything.** Players must maintain 300+ units/second to tackle. Hitting a wall, turning too sharply, or jumping all cost speed — and being slow means being a sitting duck.

- **Tackle**: Sprint into an opponent at charge speed (300+ HU/s) to knock them down and cause a fumble
- **Dive**: Lunge forward for extra reach — always ends in a knockdown for the diver, hit or miss
- **Punch**: Short-range shove. Rarely used, but a perfectly timed punch can counter-parry an incoming charge
- **Throw**: Hold to charge power, release to lob a grenade-arc pass. The carrier is nearly frozen while winding up — throwing is a commitment
- **Ball Carrier**: Moves at 75% speed. You WILL be caught. Score fast or pass

## Maps

EFT ships with 15 maps, each with distinct geometry that creates different tactical situations:

| Map | Style |
|-----|-------|
| **Slam Dunk** | Basketball hoops, jump pads, elevated platforms |
| **Bloodbowl** | Wide-open NFL stadium, pure speed |
| **Baseball Dash** | Throw-only scoring, baseball diamond |
| **Temple Sacrifice** | Lava gaps, most hazardous map |
| **Tunnel** | Underground corridors, chokepoints |
| **Space Jump** | Low gravity zones, floating platforms |
| **Cosmic Arena** | Space theme, most powerups |
| And 8 more... | Each with unique layout and scoring rules |

Maps define whether goals accept run-ins, throw-ins, or both — creating fundamentally different match dynamics on every map.

## Installation

1. Subscribe on the [Steam Workshop](https://steamcommunity.com/sharedfile/filedetails/?id=2022813030) or clone this repo into your `garrysmod/gamemodes/` directory
2. Start a server with the gamemode set to `extremefootballthrowdown`
3. Load any map with the `eft_` or `xft_` prefix
4. Bots will fill empty team slots automatically

## Server Configuration

| ConVar | Default | Description |
|--------|---------|-------------|
| `eft_gamelength` | 15 | Match duration in minutes (-1 for infinite) |
| `eft_scorelimit` | 10 | Goals to win |
| `eft_bots_enabled` | 1 | Enable bot players |
| `eft_bots_skill` | 1.0 | Bot difficulty multiplier |
| `eft_competitive` | 0 | Competitive ruleset (0=off, 1=whitelisted items, 2=no items) |
| `eft_overtime` | 300 | Overtime duration in seconds |
| `eft_warmup` | 30 | Warmup period in seconds |

## Competitive History

EFT had a formal draft league — the **Extreme Football League (EFL)** — running 8 seasons of 5v5 competitive play from approximately 2014-2018. Career scoring leaders included Madden (119+ TDs), Enigmatis (112+), and lilzzfla1 (104+). The game accumulated 275,000+ Steam Workshop subscribers.

## Credits

- **JetBoom** (William Moodhe) — Original creator
- **dissonance** (dissident93) — This fork: OOP refactor, bot AI rewrite, s&box port preparation
- **NoxiousNet community** — Years of competitive play that defined what EFT is

## License

See [license.txt](license.txt) for details.
