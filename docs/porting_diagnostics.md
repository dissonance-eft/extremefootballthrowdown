# Porting Diagnostics (Behavioral Translation)

This document translates vague "feeling" feedback into specific **MANIFEST** violations. Use this to diagnose what is broken when players complain.

| Symptom / Complaint | Probable Root Cause | Broken Property | Check ID |
| :--- | :--- | :--- | :--- |
| "I feel safe running the ball." | Carriers are moving too fast or defenders lack intercept tools. | **Possession Volatility** | `C-002` |
| "Tackles feel random." | Head-on resolution isn't respecting velocity delta. | **Determinism** | `M-130` |
| "Matches feel empty/walking simulator." | Respawn times are too long or map is too big. | **Continuous Relevance** | `C-003` |
| "Passing is useless; I just get tackled." | Windup is too long OR receivers aren't getting open. | **Commitment/Reward** | `M-160` |
| "I can't stop a goal at the last second." | Hitboxes are too small or latency compensation is missing. | **Last-Second Intervention** | `C-004` |
| "The ball just teleports instantly." | Trace resolution is skipping physics simulation. | **Readability** | `P-080` |
| "Defending is impossible against spammers." | No "lock" or "punishment" for missing a tackle. | **Commitment** | `C-009` |
| "Winning feels like luck." | Head-on collisions not rewarding momentum. | **Skill Expression** | `P-060` |

## Diagnostic Procedure

1.  Identify the feeling.
2.  Find the **Broken Property**.
3.  Look up the **Check ID** in `MANIFEST.md`.
4.  Verify the code associated with that ID (use `manifest_lookup.py`).
5.  **FIX:** Restore the constraints defined in the MANIFEST.
