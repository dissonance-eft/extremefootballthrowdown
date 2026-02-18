import json
import os
import glob
from collections import defaultdict

REPLAY_DIR = r"c:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\data\eft_replays"

def load_replays():
    files = glob.glob(os.path.join(REPLAY_DIR, "*.json"))
    matches = []
    for f in files:
        try:
            with open(f, 'r') as fp:
                matches.append(json.load(fp))
        except Exception as e:
            print(f"Error loading {f}: {e}")
    return matches

def analyze_matches(matches):
    stats = {
        "total_matches": len(matches),
        "total_goals": 0,
        "team_goals": {1: 0, 2: 0}, # 1=Red?, 2=Blue? Need to verify. Usually 1=Red, 2=Blue in Fretta? Or 0/1?
        # In EFT, TEAM_RED=1, TEAM_BLUE=2 usually.
        "top_scorers": defaultdict(int),
        "top_tacklers": defaultdict(int),
        "total_tackles": 0,
        "player_names": {},
        "match_durations": []
    }

    for m in matches:
        duration = m.get("duration", 0)
        stats["match_durations"].append(duration)

        # Map IDs to names
        for p in m.get("players", []):
            if "id" in p and "name" in p:
                stats["player_names"][p["id"]] = p["name"]

        for e in m.get("events", []):
            etype = e.get("type")
            data = e.get("data", {})
            pids = e.get("pids", [])

            if etype == "goal":
                stats["total_goals"] += 1
                team = data.get("team", 0)
                stats["team_goals"][team] = stats["team_goals"].get(team, 0) + 1
                
                # Scorer is usually first pid?
                # RecordMatchEvent("goal", hitter...)
                if pids:
                    scorer_id = pids[0]
                    stats["top_scorers"][scorer_id] += 1
            
            elif etype == "tackle_success":
                stats["total_tackles"] += 1
                # RecordMatchEvent("tackle_success", {knocker, ply})
                # pids[0] = knocker, pids[1] = victim
                if pids:
                    knocker_id = pids[0]
                    stats["top_tacklers"][knocker_id] += 1

    return stats

def generate_report(stats):
    print("# EFT Match Data Analysis")
    print(f"\n**Total Matches Analyzed:** {stats['total_matches']}")
    
    if stats['total_matches'] > 0:
        avg_duration = sum(stats['match_durations']) / stats['total_matches']
        print(f"**Average Match Duration:** {avg_duration/60:.2f} minutes")

    print("\n## Goals")
    print(f"- **Total Goals:** {stats['total_goals']}")
    print(f"- **Red Team (1):** {stats['team_goals'].get(1, 0)}")
    print(f"- **Blue Team (2):** {stats['team_goals'].get(2, 0)}")

    print("\n## Top Scorers")
    sorted_scorers = sorted(stats["top_scorers"].items(), key=lambda x: x[1], reverse=True)
    for pid, count in sorted_scorers[:5]:
        name = stats["player_names"].get(pid, pid)
        print(f"- **{name}:** {count} goals")

    print("\n## Top Tacklers")
    sorted_tacklers = sorted(stats["top_tacklers"].items(), key=lambda x: x[1], reverse=True)
    for pid, count in sorted_tacklers[:5]:
        name = stats["player_names"].get(pid, pid)
        print(f"- **{name}:** {count} tackles")

    print("\n## Gameplay Insights")
    if stats['total_matches'] > 0:
        tpm = stats['total_tackles'] / stats['total_matches']
        gpm = stats['total_goals'] / stats['total_matches']
        print(f"- **Tackles per Match:** {tpm:.1f}")
        print(f"- **Goals per Match:** {gpm:.1f}")

if __name__ == "__main__":
    matches = load_replays()
    stats = analyze_matches(matches)
    generate_report(stats)
