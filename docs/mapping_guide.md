# EFT Mapping Guide

**Target Platform:** Garry's Mod (Source Engine)
**FGD:** `extremefootballthrowdown.fgd`

## Core Philosophy (The "Flow" of EFT)
EFT is about **Continuous Contest** (C-001). Maps should not encourage stalemates or safe zones.

### 1. The Arena Shape
*   **Concept:** C-007 (Migrating Conflict Zone)
*   **Guidance:** Do not build flat, open boxes. Build "lanes" and "choke points" that force players to converge.
*   **Verticality:** Use verticality to break sightlines, but ensure `trigger_jumppad` entities allow flow back up.

### 2. Entity Placement

#### `prop_ball` (M-140)
*   **Placement:** Exact center of the map.
*   **Why:** Ensures fair access at round start.
*   **Note:** Only ONE per map.

#### `info_player_red` / `info_player_blue` (C-010)
*   **Placement:** Behind the goals, facing the field.
*   **Count:** At least 6-8 per team to avoid spawn blocking.
*   **Protection:** Protected from direct line-of-sight to the goal if possible, to prevent instant spawn-camping.

#### `trigger_goal` (M-180, S-001)
*   **Placement:** At opposite ends of the arena.
*   **Size:** Large enough to dive into (approx 128x128x128 minimum).
*   **Team ID:** Ensure `Team Red` (1) and `Team Blue` (2) are set correctly.

#### `trigger_ballreset` (P-090)
*   **Placement:** Covering ANY bottomless pit, hazard, or area where the ball could get stuck.
*   **Function:** Resets the ball to the center spawner.
*   **Crucial:** Without this, the game breaks if the ball falls off the map.

#### `trigger_jumppad` (C-003)
*   **Placement:** Routes that allow rapid vertical traversal.
*   **Tuning:** Adjust push velocity to allow smooth arcs.

### 3. Hazard Design (P-090)
*   **Skybox:** Ensure the skybox is high enough for throws.
*   **Kill Triggers:** Use `trigger_hurt` for lava/death pits.
*   **Reset:** ALWAYS pair a kill trigger with a `trigger_ballreset` so the ball resets if the carrier dies in the void.

## Lighting and Visibility (P-080)
*   The ball must be visible. Avoid overly dark corners where the white ball might be lost.
*   Use contrast to highlight goal areas.
