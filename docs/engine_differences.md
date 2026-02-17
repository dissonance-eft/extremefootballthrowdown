# Engine Differences (Source vs s&box)

This document tracks behavioral divergences between the original GMod engine (Source 1) and the target platform (s&box/Source 2) that affect **MANIFEST** compliance.

## Physics Timestep

*   **Source 1:** 66 tick (default). Physics frames are tied to tickrate.
*   **s&box:** Variable/High tick. Physics is often sub-stepped.
*   **Risk:** `M-130` (Head-On Collision) relies on "instantaneous velocity". Smoothing in s&box might blur the precise frame of impact, causing "mushy" collisions.
*   **Mitigation:** Verify collision velocity explicitly at the moment of impact event, do not rely on `Velocity` property which might be interpolated.

## Movement Model

*   **Source 1:** Quake-based (Air control, friction).
*   **s&box:** custom Character Controller (WalkController).
*   **Risk:** `M-110` (Charge) requires specific acceleration curves. If s&box `Accelerate` is too linear, players will reach max speed too fast or too slow.
*   **Mitigation:** Port the exact friction/acceleration math from `gamemode/obj_player.lua` into the C# `WalkController`.

## Collision Resolution

*   **Source 1:** VPhysics + Hull traces.
*   **s&box:** Jolt/Rubikon Physics.
*   **Risk:** `S-005` (Swarm Interaction). Source handles inter-player collision with specific "rubbing" friction. s&box might be too slippery or too sticky (Velcro effect).
*   **Mitigation:** Tune physics materials on player capsules to match Source `player_clip` friction.

## Input Prediction

*   **Source 1:** Prediction encoded in gamemode logic (Move).
*   **s&box:** Built-in prediction system.
*   **Risk:** `C-009` (Commitment). If prediction rollback is too aggressive, "Last Second Interventions" (`C-004`) might be rolled back, causing "Ghost Goals".
*   **Mitigation:** Authoritative server checks for goal scoring triggers (`M-180`) must override client prediction visual confidence.
