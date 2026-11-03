"""Verify preserved bytes and the two dates of each reconstructed import."""
from pathlib import Path
import csv
import datetime as dt
import hashlib
import subprocess

ROOT = Path(__file__).resolve().parents[1]
rows = list(csv.DictReader((ROOT / "archive/file-dates.csv").open(encoding="utf-8")))
for row in rows:
    path = ROOT / row["path"]
    assert path.stat().st_size == int(row["bytes"]), row["path"]
    assert hashlib.sha256(path.read_bytes()).hexdigest() == row["sha256"], row["path"]
    result = subprocess.run(["git", "-C", str(ROOT), "show", "-s", "--format=%aI%n%cI", row["import_commit"]],
                            check=True, capture_output=True, text=True)
    expected = dt.datetime.fromisoformat(row["modified_utc"])
    assert [dt.datetime.fromisoformat(value.replace("Z", "+00:00")) for value in result.stdout.splitlines()] == [expected, expected], row["path"]
    changes = subprocess.run(["git", "-C", str(ROOT), "diff-tree", "--root", "--no-commit-id", "--name-only", "-r", row["import_commit"]],
                             check=True, capture_output=True, text=True)
    assert changes.stdout.splitlines() == [row["path"]], row["path"]
print(f"Verified {len(rows)} archive hashes, one-file commits, author dates and committer dates")
