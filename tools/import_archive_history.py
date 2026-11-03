"""Import the two untouched archive folders, one file per dated Git commit.

Both Git dates use the recorded filesystem modification time in UTC. These are
explicitly reconstructed imports, not a claim that the project used Git then.
The import plan and progress live in .git so an interrupted import can resume.
"""
from pathlib import Path
import argparse
import csv
import datetime as dt
import hashlib
import json
import os
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ARCHIVES = ("ST_src", "SnoopyTennis_v2-1")


def git(*args, env=None, check=True):
    return subprocess.run(["git", "-C", str(ROOT), *args], env=env, check=check,
                          text=True, capture_output=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true", help="Create the local Git history")
    args = parser.parse_args()
    files = [p for directory in ARCHIVES for p in (ROOT / directory).rglob("*") if p.is_file()]
    plan = []
    for path in sorted(files, key=lambda p: (p.stat().st_mtime_ns, p.relative_to(ROOT).as_posix())):
        stat = path.stat()
        date = dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).isoformat(timespec="seconds")
        plan.append({"path": path.relative_to(ROOT).as_posix(), "bytes": stat.st_size,
                     "modified_utc": date, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                     "timestamp_note": "Pre-1980 bundled-file timestamp; not a project creation date" if date < "1980" else ""})
    if not args.execute:
        print(json.dumps({"files": len(plan), "first": plan[0], "last": plan[-1]}, indent=2))
        return
    if not (ROOT / ".git").exists():
        git("init", "--initial-branch=main")
    git("config", "core.autocrlf", "false")
    state_path = ROOT / ".git/archive-import-state.json"
    state = json.loads(state_path.read_text()) if state_path.exists() else {"plan": plan, "commits": []}
    if state["plan"] != plan:
        raise RuntimeError("Archive content or dates changed since the import plan was recorded")
    if not state["commits"] and git("rev-parse", "--verify", "HEAD", check=False).returncode == 0:
        raise RuntimeError("Refusing to add reconstructed history after an existing commit")
    if git("diff", "--cached", "--name-only").stdout.strip():
        raise RuntimeError("The Git index must be empty before the archive import")
    state_path.write_text(json.dumps(state, indent=2) + "\n")
    for item in plan[len(state["commits"]):]:
        env = os.environ.copy()
        env["GIT_AUTHOR_DATE"] = item["modified_utc"]
        env["GIT_COMMITTER_DATE"] = item["modified_utc"]
        git("--literal-pathspecs", "add", "--", item["path"])
        message = ("Import archived file: " + item["path"] + "\n\n"
                   "Reconstructed archive import. Both Git dates match the preserved\n"
                   "filesystem modification time, not an original Git development event.\n\n"
                   "Original modified (UTC): " + item["modified_utc"] + "\n"
                   "SHA-256: " + item["sha256"])
        git("-c", "commit.gpgsign=false", "commit", "-m", message, env=env)
        sha = git("rev-parse", "HEAD").stdout.strip()
        state["commits"].append(sha)
        state_path.write_text(json.dumps(state, indent=2) + "\n")
        print(f"{len(state['commits']):02}/{len(plan)} {item['modified_utc'][:10]} {item['path']}", flush=True)
    destination = ROOT / "archive/file-dates.csv"
    destination.parent.mkdir(exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "bytes", "modified_utc", "sha256", "timestamp_note", "import_commit"])
        writer.writeheader()
        for item, sha in zip(plan, state["commits"]):
            writer.writerow({**item, "import_commit": sha})
    for item in plan:
        if hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest() != item["sha256"]:
            raise RuntimeError("Archive bytes changed: " + item["path"])
    print(f"Imported {len(plan)} files; provenance written to {destination}")


if __name__ == "__main__":
    main()
