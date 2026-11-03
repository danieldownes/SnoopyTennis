# File-date provenance

`file-dates.csv` records all 54 files in the two supplied archive folders before
they were added to Git. Each row records the relative path, exact byte count,
SHA-256, preserved filesystem modification time in UTC, and the one-file import
commit. `modified_utc` always preserves the original file metadata. `commit_utc`
records the time used for both the Git author date and committer date;
`date_policy` explains how it was chosen.

These commits reconstruct an import from surviving file metadata. They are not
an original Git history, do not recover earlier file versions, and do not imply
that the author wrote bundled third-party drivers. Four Creative support files
carry pre-project timestamps: `Sbsim.com` (1979), `Sbsim.cfg` (1980), `Sbmidi.exe`
(1993) and `CTMIDI.DRV` (1994). Their Git author and committer dates were corrected
to **3 November 2026**, the actual date of this archive import. Their old file
times remain in `modified_utc`, with policy `current_import`. All other archive
commits retain policy `file_mtime`. Later packaging-file metadata can still be
dated 2014; no claim is made that this is when the game itself was written.

`ST_src/MENU.BAS` is dated 2000-01-29T17:41:24+00:00;
`ST_src/STennis.BAS` is dated 2000-06-30T15:51:40+00:00. Several artwork and sound
files are dated 1999. Those are the available dates, rather than an inferred
1999 date assigned to every source file.

Run `python tools/verify_archive.py` from the repository root to check the bytes,
one-file commits and both Git dates. A normal Git checkout gives files fresh
filesystem times; the historical metadata lives in this manifest and the commits.
