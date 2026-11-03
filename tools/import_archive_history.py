"""Import the two untouched archive folders, one file per dated Git commit.

Both Git dates normally use the recorded filesystem modification time in UTC.
Bundled pre-project Creative support files use the current import time instead;
their original filesystem times remain in the manifest. These are explicitly
reconstructed imports, not a claim that the project used Git then.
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
CURRENT_DATE_IMPORTS = frozenset({
    "SnoopyTennis_v2-1/Sbsim.com",
    "SnoopyTennis_v2-1/Sbsim.cfg",
    "SnoopyTennis_v2-1/Sbmidi.exe",
    "SnoopyTennis_v2-1/CTMIDI.DRV",
})


def date_policy(path, modified_utc, imported_utc):
    current = path in CURRENT_DATE_IMPORTS
    return {"commit_utc": imported_utc if current else modified_utc,
            "date_policy": "current_import" if current else "file_mtime",
            "timestamp_note": "Bundled Creative support file; original timestamp retained as provenance, Git dates use current import time" if current else ""}


def import_message(item):
    if item["date_policy"] == "current_import":
        explanation = ("Reconstructed archive import of a bundled pre-project Creative support file.\n"
                       "Both Git dates use the current import time; the old filesystem timestamp\n"
                       "is retained below as provenance, not as Snoopy Tennis development history.\n\n")
    else:
        explanation = ("Reconstructed archive import. Both Git dates match the preserved\n"
                       "filesystem modification time, not an original Git development event.\n\n")
    return ("Import archived file: " + item["path"] + "\n\n" + explanation +
            "Original modified (UTC): " + item["modified_utc"] + "\n" +
            "SHA-256: " + item["sha256"])


def git(*args, env=None, check=True):
    return subprocess.run(["git", "-C", str(ROOT), *args], env=env, check=check,
                          text=True, capture_output=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute", action="store_true", help="Create the local Git history")
    args = parser.parse_args()
    state_path = ROOT / ".git/archive-import-state.json"
    existing = json.loads(state_path.read_text()) if state_path.exists() else None
    imported_utc = (existing or {}).get("imported_utc") or dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    files = [p for directory in ARCHIVES for p in (ROOT / directory).rglob("*") if p.is_file()]
    plan = []
    for path in sorted(files, key=lambda p: (p.stat().st_mtime_ns, p.relative_to(ROOT).as_posix())):
        stat = path.stat()
        date = dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).isoformat(timespec="seconds")
        relative = path.relative_to(ROOT).as_posix()
        plan.append({"path": relative, "bytes": stat.st_size,
                     "modified_utc": date, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                     **date_policy(relative, date, imported_utc)})
    if not args.execute:
        print(json.dumps({"files": len(plan), "first": plan[0], "last": plan[-1]}, indent=2))
        return
    if not (ROOT / ".git").exists():
        git("init", "--initial-branch=main")
    git("config", "core.autocrlf", "false")
    state = existing or {"plan": plan, "commits": [], "imported_utc": imported_utc}
    if state["plan"] != plan:
        raise RuntimeError("Archive content or dates changed since the import plan was recorded")
    if not state["commits"] and git("rev-parse", "--verify", "HEAD", check=False).returncode == 0:
        raise RuntimeError("Refusing to add reconstructed history after an existing commit")
    if git("diff", "--cached", "--name-only").stdout.strip():
        raise RuntimeError("The Git index must be empty before the archive import")
    state_path.write_text(json.dumps(state, indent=2) + "\n")
    for item in plan[len(state["commits"]):]:
        env = os.environ.copy()
        env["GIT_AUTHOR_DATE"] = item["commit_utc"]
        env["GIT_COMMITTER_DATE"] = item["commit_utc"]
        git("--literal-pathspecs", "add", "--", item["path"])
        message = import_message(item)
        git("-c", "commit.gpgsign=false", "commit", "-m", message, env=env)
        sha = git("rev-parse", "HEAD").stdout.strip()
        state["commits"].append(sha)
        state_path.write_text(json.dumps(state, indent=2) + "\n")
        print(f"{len(state['commits']):02}/{len(plan)} {item['commit_utc'][:10]} {item['path']}", flush=True)
    destination = ROOT / "archive/file-dates.csv"
    destination.parent.mkdir(exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "bytes", "modified_utc", "commit_utc", "date_policy", "sha256", "timestamp_note", "import_commit"])
        writer.writeheader()
        for item, sha in zip(plan, state["commits"]):
            writer.writerow({**item, "import_commit": sha})
    for item in plan:
        if hashlib.sha256((ROOT / item["path"]).read_bytes()).hexdigest() != item["sha256"]:
            raise RuntimeError("Archive bytes changed: " + item["path"])
    print(f"Imported {len(plan)} files; provenance written to {destination}")


if __name__ == "__main__":
    main()
