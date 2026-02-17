# Known Bad States (Regression Gallery)

These are recognizable broken gameplay states that have appeared in the past. If you see these, **STOP**. The build is broken.

## 1. The "Walking Simulator"
*   **Symptoms:** Players spend >50% of the match running toward a ball they never reach.
*   **Cause:** Map too large OR Respawn time too long (>6s) OR Movement speed too low.
*   **Violates:** `C-003` (Continuous Relevance).

## 2. The "Velcro Carrier"
*   **Symptoms:** Carrier gets tackled but the ball "sticks" to them or instantly repopulates in their hands.
*   **Cause:** `PossessionTransfer` event firing after `Knockdown` event inappropriately, or pick-up radius too large.
*   **Violates:** `C-002` (Short Possession).

## 3. The "Ghost Tackle"
*   **Symptoms:** You hear the tackle sound, you see the hit, but the carrier keeps running.
*   **Cause:** Client predicted the hit, Server authoritative check failed (likely due to lag compensation mismatch).
*   **Violates:** `C-009` (Commitment).

## 4. The "Infinite Dribble"
*   **Symptoms:** Players can kick/nudge the ball forward faster than they can run, allowing them to traverse the map without carrying (avoiding speed penalty).
*   **Cause:** Physics collision impulse on the ball is too high relative to player speed.
*   **Violates:** `M-140` (Carrier Liability).

## 5. The "Statue Defense"
*   **Symptoms:** Defenders stop moving to block a path, and it works perfectly 100% of the time.
*   **Cause:** Collision boxes are too wide (creating a wall) or friction is infinite (no way to push past).
*   **Violates:** `C-001` (Continuous Contest). Staic defense should fail against momentum.
