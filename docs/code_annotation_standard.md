# Code Annotation Standard

To ensure **Extreme Football Throwdown** remains true to its design constitution (`MANIFEST.md`), all gameplay code must be explicitly linked to the concepts it implements.

## The Header

Every file in `gamemode/`, `entities/`, or `states/` that implements logic related to a `MANIFEST` ID must include this header:

```lua
/// MANIFEST LINKS:
/// Mechanics: M-### (e.g. M-130)
/// Concepts: C-### (e.g. C-009)
/// Principles: P-### (e.g. P-060)
/// Scenarios: S-### (e.g. S-009)
```

### Rules

1.  **Do not guess.** If code implements "Movement", check `M-110` in `MANIFEST.md`.
2.  **Verify Constraints.** If you link `P-040` (Prediction Dominance), verify your code does *not* rely purely on reaction time.
3.  **Update on Change.** If you change the behavior, check if you broke the linked Concept.

## Common IDs

*   **M-110**: Movement & Charge
*   **M-130**: Head-On Collision
*   **M-140**: Possession
*   **M-160**: Passing
*   **M-180**: Scoring
*   **C-001**: Continuous Contest (The "Why")
*   **C-009**: Commitment Under Uncertainty (The "Skill")

## Example

```lua
-- gamemode/obj_player.lua
/// MANIFEST LINKS:
/// Mechanics: M-130 (Head-On Collision)
/// Principles: P-060 (Momentum Influence)
/// Concepts: C-006 (Human Variance)
function Player:ResolveTackle(target)
    -- ...
end
```
