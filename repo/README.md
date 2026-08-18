# qlab-content-versioning

Automatic content versioning for [QLab](https://qlab.app), modelled on disguise
Designer's file-name versioning.

Drop a newer copy of a file into the content folder, fire one Script cue, and
every cue pointing at the old version retargets itself to the new one.

Built for shows where content keeps landing through tech and nobody wants to
re-point forty cues by hand at 11pm.

---

## The naming convention

Version tags are appended to the file name before the extension:

```
_vYYMMDDHHmm          ten digits, no letter suffix
```

| File | Meaning |
|---|---|
| `lowerthird.mov` | base version, no tag |
| `lowerthird_v2608181432.mov` | 18 Aug 2026, 14:32 |
| `lowerthird_v2608182205.mov` | 18 Aug 2026, 22:05 — wins |

Everything before the tag is the **stem**. Files sharing a stem and an extension
form one version set. Stem matching is exact, so `fileofvideo` and
`otherfileofvideo` stay separate sets despite one being a suffix of the other.

Because every tag is the same width, plain alphabetical sort is also
chronological order. There is no `_v2` vs `_v10` ambiguity and nothing to
configure.

### Malformed tags are rejected loudly

Anything that looks like a tag but isn't ten valid digits is **excluded from the
running and reported**, rather than silently winning or silently vanishing:

| File | Outcome |
|---|---|
| `clip_vFINAL.png` | warned — tag is not `_vYYMMDDHHmm` |
| `clip_v26081822.png` | warned — too few digits |
| `clip_v2608322205.png` | warned — day 32 is not a valid date |

This matters more than it sounds. A typo'd stamp and "the content hasn't been
delivered yet" look identical from the cue list. The warning tells them apart.

---

## Install

1. Copy [`src/qlab-content-versioning.applescript`](src/qlab-content-versioning.applescript)
   into a **Script cue**.
2. Create a **Memo cue** and set its cue **number** to `VLOG` (its name gets
   overwritten with the run status, so don't bother naming it).
3. Leave `dryRun` set to `true` and fire the Script cue.
4. Read the Memo cue. When you're happy, set `dryRun` to `false`.

Fire it pre-show, not during playback — retargeting forces QLab to reload the
media.

**QLab 4:** change every `com.figure53.QLab.5` to `com.figure53.QLab.4`.

---

## Settings

All at the top of the script.

| Property | Default | What it does |
|---|---|---|
| `dryRun` | `true` | Report only, change nothing. |
| `contentRoot` | `""` | Restrict to files under this path. `""` = anywhere. |
| `showDialog` | `true` | Blocking summary dialog. Turn off once the Memo cue is in place. |
| `logCueNumber` | `"VLOG"` | Cue number of the Memo cue to log into. `""` = skip. |
| `logFilePath` | `""` | Disk log path. `""` = `~/Desktop/QLab Content Versioning.log`. |
| `stampCueNotes` | `false` | Also write a one-line note into each retargeted cue. Replaces existing notes. |
| `videoExtensions` | movies + stills | Which extensions get versioned. Case-insensitive. |

`videoExtensions` includes image formats because QLab video cues play stills as
well as movies. Trim anything you don't want touched.

---

## Logging

Three outputs, so a result never goes unexplained.

**Memo cue** — one-line status as the cue name, detail in the notes. Visible in
the cue list, travels with the workspace, overwritten each run.

```
2026-08-18 22:04 — 2 of 2 media cues updated, 1 warning
```

**Disk log** — appended, so you keep a history across sessions.

**Dialog** — optional, blocks until dismissed.

The detail block reports how many cues were found, how many had a readable file
target, and which extensions were skipped:

```
6 cues in workspace, 2 with a readable file target
extensions skipped (not in videoExtensions): wav

  2  fileofvideo_v2608182200.png
      was: fileofvideo_v2608182200.png
      now: fileofvideo_v2608182205.png   (18 Aug 2026 22:05)

WARNINGS:
  fileofvideo_vFINAL.png  —  tag is not _vYYMMDDHHmm
```

---

## Trying it

```bash
demo/make-demo-content.sh
```

Writes a set of dummy versioned PNGs to `~/Movies/qlab-versioning-demo`,
including one deliberately malformed file so you can watch the warning fire.
The two versions are different colours, so the retarget is visible on the output
stage and not just in the log.

---

## Troubleshooting

**"0 of 0 media cues updated"** — check the `N with a readable file target`
count in the detail block. If it's zero, `file target` isn't reading. If it's
non-zero, look at the skipped-extensions line: the file type probably isn't in
`videoExtensions`.

**"could not list … — check QLab has Files & Folders access"** — macOS privacy
protection. Picking a file in an open panel grants QLab access to *that file*,
not permission to list the folder it sits in. `do shell script` inherits QLab's
privacy context, so the scan comes back empty even though the cue plays fine.

Fix it in System Settings → Privacy & Security → Files and Folders, or keep
content somewhere unprotected. Desktop, Documents and Downloads are all
protected; `~/Movies` is not.

This permission does not travel with the workspace. Grant it on the show machine
during prep, not on the day.

**Anything else** — run
[`src/qlab-versioning-diagnostic.applescript`](src/qlab-versioning-diagnostic.applescript)
in Script Editor. It dumps every cue with its type, the class returned by
`file target`, and the resolved path or the exact error. Writes to
`~/Desktop/QLab cue dump.txt`.

---

## Differences from disguise

This emulates the behaviour, it isn't a port. Known divergences:

| | disguise Designer | This |
|---|---|---|
| Tag format | `_v` + numerals + optional letter | `_v` + exactly ten digits |
| Date tag | `_vYYYYMMDDHHMM` (four-digit year) | `_vYYMMDDHHmm` (two-digit year) |
| Tag in folder name | Supported — a folder per version date | Not supported, filenames only |
| Rollback | VideoAsset editor, per version | Not implemented |
| Trigger | Automatic on file arrival | Manual, when you fire the cue |

**Do not mix tag widths in one folder.** Sorting is alphabetical, so `2026…`
sorts before `2608…` and a four-digit-year tag would lose to a two-digit one.
Pick one convention for the whole show and tell whoever is exporting.

---

## Licence

MIT — see [LICENSE](LICENSE).
