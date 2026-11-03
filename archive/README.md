# File-date provenance

`file-dates.csv` records all 54 files in the two supplied archive folders before
they were added to Git. Each row records the relative path, exact byte count,
SHA-256, preserved filesystem modification time in UTC, and the one-file import
commit. Both the Git author date and committer date use that time.

These commits reconstruct an import from surviving file metadata. They are not
an original Git history, do not recover earlier file versions, and do not imply
that the author wrote bundled third-party drivers. Some support files have
1979/1980 timestamps; later packaging files have 2014 timestamps. Such dates are
retained without treating them as dates when the game was developed.

`ST_src/MENU.BAS` is dated 2000-01-29T17:41:24+00:00;
`ST_src/STennis.BAS` is dated 2000-06-30T15:51:40+00:00. Several artwork and sound
files are dated 1999. Those are the available dates, rather than an inferred
1999 date assigned to every source file.

Run `python tools/verify_archive.py` from the repository root to check the bytes,
one-file commits and both Git dates. A normal Git checkout gives files fresh
filesystem times; the historical metadata lives in this manifest and the commits.
