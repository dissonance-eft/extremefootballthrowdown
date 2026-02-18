"""
EFT Replay Analyzer v2 — Uses actual event types from replay data.
Validates real match data against MANIFEST behavioral guarantees.
"""

import json
import glob
import os
from collections import defaultdict

REPLAY_DIR = r"C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\data\eft_replays"

def analyze_match(filepath):
    with open(filepath, 'r') as f:
        data = json.load(f)
    
    events = data.get("events", [])
    if not events:
        return None
    
    # --- Basic Stats ---
    event_types = defaultdict(int)
    for e in events:
        event_types[e["type"]] += 1
    
    times = [e.get("time", 0) for e in events]
    match_start = min(times)
    match_end = max(times)
    match_duration = match_end - match_start
    
    # Separate event types
    tackles = [e for e in events if e["type"] == "tackle_success"]
    possessions = [e for e in events if e["type"] == "possession_gain"]
    goals = [e for e in events if e["type"] == "goal"]
    respawns = [e for e in events if e["type"] == "respawn"]
    
    # --- Unique players ---
    unique_pids = set()
    for e in events:
        for pid in e.get("pids", []):
            unique_pids.add(str(pid))
    bot_pids = {p for p in unique_pids if p.startswith("9007")}
    human_pids = unique_pids - bot_pids
    
    # --- Active play time (subtract warmup ~30s) ---
    active_time = match_duration - 30
    if active_time <= 0:
        active_time = match_duration
    active_minutes = active_time / 60
    
    # --- Possession Duration Analysis ---
    # possession_gain = someone picked up the ball
    # tackle_success = someone got tackled (carrier loses ball)
    # goal = ball scored
    # Sort all gameplay events by time
    gameplay_events = sorted(
        [e for e in events if e["type"] in ("possession_gain", "tackle_success", "goal")],
        key=lambda x: x.get("time", 0)
    )
    
    possession_durations = []
    last_possession_time = None
    
    for e in gameplay_events:
        t = e.get("time", 0)
        if e["type"] == "possession_gain":
            # If we had a previous pickup, this means the previous carrier lost the ball
            # and someone new picked it up — possession ended
            if last_possession_time is not None:
                dur = t - last_possession_time
                if 0 < dur < 60:
                    possession_durations.append(dur)
            last_possession_time = t
        elif e["type"] in ("tackle_success", "goal"):
            if last_possession_time is not None:
                dur = t - last_possession_time
                if 0 < dur < 60:
                    possession_durations.append(dur)
                last_possession_time = None
    
    # --- Interaction Gaps (time between ANY gameplay event) ---
    all_action = sorted(
        [e for e in events if e["type"] in ("tackle_success", "possession_gain", "goal")],
        key=lambda x: x.get("time", 0)
    )
    
    # Filter to only active play (after warmup)
    warmup_end = match_start + 30
    active_actions = [e for e in all_action if e.get("time", 0) >= warmup_end]
    
    interaction_gaps = []
    for i in range(1, len(active_actions)):
        gap = active_actions[i].get("time", 0) - active_actions[i-1].get("time", 0)
        if gap > 0:
            interaction_gaps.append(gap)
    
    # --- Tackle density analysis ---
    tackle_times = sorted([e.get("time", 0) for e in tackles if e.get("time", 0) >= warmup_end])
    tackle_gaps = []
    for i in range(1, len(tackle_times)):
        g = tackle_times[i] - tackle_times[i-1]
        if g > 0:
            tackle_gaps.append(g)
    
    # --- Goal analysis ---
    goal_times = sorted([e.get("time", 0) for e in goals])
    goal_gaps = []
    for i in range(1, len(goal_times)):
        goal_gaps.append(goal_times[i] - goal_times[i-1])
    
    # --- Possession gain per player ---
    carrier_counts = defaultdict(int)
    for e in possessions:
        for pid in e.get("pids", []):
            carrier_counts[str(pid)] += 1
    
    # --- Tackles per player ---
    tackle_counts = defaultdict(int)
    for e in tackles:
        for pid in e.get("pids", []):
            tackle_counts[str(pid)] += 1
    
    # --- Goal scorers ---
    goal_scorers = defaultdict(int)
    for e in goals:
        for pid in e.get("pids", []):
            goal_scorers[str(pid)] += 1
    
    # --- Compile ---
    avg_pos = sum(possession_durations) / max(len(possession_durations), 1)
    med_pos = sorted(possession_durations)[len(possession_durations)//2] if possession_durations else 0
    
    result = {
        "file": os.path.basename(filepath),
        "match_duration_s": round(match_duration, 1),
        "active_play_s": round(active_time, 1),
        "total_events": len(events),
        "event_counts": dict(event_types),
        "players": {
            "total": len(unique_pids),
            "humans": len(human_pids),
            "bots": len(bot_pids),
        },
        "possession": {
            "gains": len(possessions),
            "avg_duration_s": round(avg_pos, 2),
            "median_duration_s": round(med_pos, 2),
            "max_duration_s": round(max(possession_durations), 2) if possession_durations else 0,
            "min_duration_s": round(min(possession_durations), 2) if possession_durations else 0,
            "count": len(possession_durations),
            "gains_per_min": round(len(possessions) / max(active_minutes, 0.1), 1),
        },
        "tackles": {
            "total": len(tackles),
            "per_minute": round(len(tackles) / max(active_minutes, 0.1), 1),
            "avg_gap_s": round(sum(tackle_gaps) / max(len(tackle_gaps), 1), 2),
        },
        "interactions": {
            "total": len(active_actions),
            "avg_gap_s": round(sum(interaction_gaps) / max(len(interaction_gaps), 1), 2),
            "max_gap_s": round(max(interaction_gaps), 2) if interaction_gaps else 0,
            "per_minute": round(len(active_actions) / max(active_minutes, 0.1), 1),
        },
        "goals": {
            "total": len(goals),
            "avg_gap_s": round(sum(goal_gaps) / max(len(goal_gaps), 1), 1) if goal_gaps else 0,
            "scorers": dict(goal_scorers),
        },
        "carrier_distribution": dict(carrier_counts),
        "tackle_distribution": dict(tackle_counts),
    }
    
    return result

def manifest_check(r):
    """Compare result against MANIFEST behavioral guarantees."""
    checks = []
    active_min = r["active_play_s"] / 60
    
    # ═══════════════════════════════════════════════════
    # C-002: Short Possession (MANIFEST says avg ~2s, max 20s)
    # ═══════════════════════════════════════════════════
    avg_pos = r["possession"]["avg_duration_s"]
    if r["possession"]["count"] == 0:
        checks.append(f"  ⚠️  C-002 Short Possession: No data (possession_gain→tackle pairs not found)")
    elif avg_pos <= 3.0:
        checks.append(f"  ✅ C-002 Short Possession: avg {avg_pos}s (target ≤3s)")
    elif avg_pos <= 5.0:
        checks.append(f"  ⚠️  C-002 Short Possession: avg {avg_pos}s (slightly high, target ~2s)")
    else:
        checks.append(f"  ❌ C-002 Short Possession: avg {avg_pos}s (TOO HIGH, target ~2s)")
    
    max_pos = r["possession"]["max_duration_s"]
    if max_pos > 0 and max_pos <= 20:
        checks.append(f"  ✅ Max possession: {max_pos}s (target ≤20s)")
    elif max_pos > 20:
        checks.append(f"  ⚠️  Max possession: {max_pos}s (exceeds 20s norm)")
    
    # ═══════════════════════════════════════════════════
    # P-020: Interaction Frequency (tackles per minute — proxy for "contested")
    # MANIFEST: turnovers per minute = 3.2
    # ═══════════════════════════════════════════════════
    tpm = r["tackles"]["per_minute"]
    if tpm >= 20:
        checks.append(f"  ✅ P-020 Interaction Freq: {tpm} tackles/min (VERY HIGH — healthy chaos)")
    elif tpm >= 5:
        checks.append(f"  ✅ P-020 Interaction Freq: {tpm} tackles/min (good)")
    elif tpm >= 2:
        checks.append(f"  ⚠️  P-020 Interaction Freq: {tpm} tackles/min (moderate)")
    else:
        checks.append(f"  ❌ P-020 Interaction Freq: {tpm} tackles/min (LOW)")
    
    # ═══════════════════════════════════════════════════
    # C-001: Continuous Contest (gaps between interactions)
    # ═══════════════════════════════════════════════════
    avg_gap = r["interactions"]["avg_gap_s"]
    max_gap = r["interactions"]["max_gap_s"]
    
    if avg_gap <= 3.0:
        checks.append(f"  ✅ C-001 Continuous Contest: avg {avg_gap}s between events (excellent)")
    elif avg_gap <= 6.0:
        checks.append(f"  ✅ C-001 Continuous Contest: avg {avg_gap}s between events (good)")
    elif avg_gap <= 10.0:
        checks.append(f"  ⚠️  C-001 Continuous Contest: avg {avg_gap}s (some dead time)")
    else:
        checks.append(f"  ❌ C-001 Continuous Contest: avg {avg_gap}s (TOO SLOW)")
    
    if max_gap > 15:
        checks.append(f"  ⚠️  Longest gap without action: {max_gap}s")
    
    # ═══════════════════════════════════════════════════
    # C-003: Simultaneous Relevance (carrier distribution)
    # ═══════════════════════════════════════════════════
    if r["carrier_distribution"]:
        carries = list(r["carrier_distribution"].values())
        total_carries = sum(carries)
        max_hog = max(carries)
        hog_pct = max_hog / max(total_carries, 1) * 100
        if hog_pct < 30:
            checks.append(f"  ✅ C-003 Role Fluidity: Top carrier has {hog_pct:.0f}% of pickups (spread is good)")
        elif hog_pct < 50:
            checks.append(f"  ⚠️  C-003 Role Fluidity: Top carrier has {hog_pct:.0f}% of pickups")
        else:
            checks.append(f"  ❌ C-003 Role Fluidity: Top carrier has {hog_pct:.0f}% of pickups (DOMINANT)")
    
    # ═══════════════════════════════════════════════════
    # Scoring rate
    # ═══════════════════════════════════════════════════
    goals_per_min = r["goals"]["total"] / max(active_min, 0.1)
    checks.append(f"  ℹ️  Scoring rate: {goals_per_min:.1f} goals/min ({r['goals']['total']} total in {active_min:.1f} min)")
    
    # Possession gains per minute (proxy for ball changing hands)
    ppm = r["possession"]["gains_per_min"]
    checks.append(f"  ℹ️  Possession changes: {ppm}/min")
    
    return checks

# === MAIN ===
print("=" * 72)
print("  EFT REPLAY ANALYSIS — MANIFEST BEHAVIORAL AUDIT")
print("=" * 72)

files = sorted(glob.glob(os.path.join(REPLAY_DIR, "*.json")))
print(f"\n  Found {len(files)} replay files.\n")

all_results = []
for f in files:
    result = analyze_match(f)
    if result:
        all_results.append(result)

for r in all_results:
    print(f"\n{'─' * 72}")
    print(f"  MATCH: {r['file']}")
    print(f"  Duration: {r['match_duration_s']}s total | {r['active_play_s']}s active")
    print(f"  Players: {r['players']['humans']} human + {r['players']['bots']} bots = {r['players']['total']}")
    print(f"  Total events: {r['total_events']}")
    
    print(f"\n  Event Breakdown:")
    for k, v in sorted(r["event_counts"].items(), key=lambda x: -x[1]):
        bar = "█" * min(v // 2, 40)
        print(f"    {k:20s} {v:5d}  {bar}")
    
    print(f"\n  Possession (C-002 Short Possession):")
    print(f"    Ball pickups: {r['possession']['gains']}")
    if r['possession']['count'] > 0:
        print(f"    Avg hold time: {r['possession']['avg_duration_s']}s (MANIFEST target: ~2s)")
        print(f"    Median:        {r['possession']['median_duration_s']}s")
        print(f"    Range:         {r['possession']['min_duration_s']}s — {r['possession']['max_duration_s']}s")
    else:
        print(f"    (No possession→loss pairs detected — events may not overlap)")
    
    print(f"\n  Tackles (P-020 Interaction Frequency):")
    print(f"    Total: {r['tackles']['total']}")
    print(f"    Rate:  {r['tackles']['per_minute']}/min")
    print(f"    Avg gap between tackles: {r['tackles']['avg_gap_s']}s")
    
    print(f"\n  Interaction Density (C-001 Continuous Contest):")
    print(f"    Events/min: {r['interactions']['per_minute']}")
    print(f"    Avg gap: {r['interactions']['avg_gap_s']}s | Max gap: {r['interactions']['max_gap_s']}s")
    
    print(f"\n  Goals (P-100 Reversals & Hype):")
    print(f"    Total: {r['goals']['total']}")
    if r['goals']['avg_gap_s']:
        print(f"    Avg time between goals: {r['goals']['avg_gap_s']}s")
    if r['goals']['scorers']:
        for pid, count in r['goals']['scorers'].items():
            label = "BOT" if pid.startswith("9007") else "HUMAN"
            print(f"    {label} ({pid[-6:]}): {count} goal(s)")
    
    print(f"\n  MANIFEST COMPLIANCE:")
    for check in manifest_check(r):
        print(check)

# === AGGREGATE ===
if len(all_results) > 1:
    print(f"\n{'═' * 72}")
    print("  AGGREGATE SUMMARY")
    print(f"{'═' * 72}")
    
    total_tackles = sum(r["tackles"]["total"] for r in all_results)
    total_goals = sum(r["goals"]["total"] for r in all_results)
    total_possessions = sum(r["possession"]["gains"] for r in all_results)
    total_time = sum(r["active_play_s"] for r in all_results)
    total_min = total_time / 60
    
    all_pos_durs = []
    for r in all_results:
        if r["possession"]["count"] > 0:
            all_pos_durs.append(r["possession"]["avg_duration_s"])
    
    print(f"\n  Total active play: {total_time:.0f}s ({total_min:.1f} min)")
    print(f"  Total tackles:     {total_tackles} ({total_tackles/max(total_min,0.1):.1f}/min)")
    print(f"  Total possessions: {total_possessions} ({total_possessions/max(total_min,0.1):.1f}/min)")
    print(f"  Total goals:       {total_goals} ({total_goals/max(total_min,0.1):.1f}/min)")
    
    if all_pos_durs:
        print(f"  Avg possession:    {sum(all_pos_durs)/len(all_pos_durs):.2f}s")

    print(f"\n  VERDICT:")
    tpm = total_tackles / max(total_min, 0.1)
    if tpm >= 20:
        print(f"  ✅ High tackle density ({tpm:.0f}/min) — C-001 Continuous Contest HEALTHY")
    elif tpm >= 5:
        print(f"  ✅ Good tackle density ({tpm:.0f}/min)")
    else:
        print(f"  ❌ Low tackle density ({tpm:.0f}/min) — need more contested interactions")
    
    ppm = total_possessions / max(total_min, 0.1)
    if ppm >= 8:
        print(f"  ✅ Ball changes hands frequently ({ppm:.0f}/min) — C-002 Short Possession HEALTHY")
    elif ppm >= 3:
        print(f"  ⚠️  Moderate possession changes ({ppm:.0f}/min)")
    else:
        print(f"  ❌ Ball stays with one player too long ({ppm:.0f}/min)")

print(f"\n{'═' * 72}")
print("  Analysis complete.")
