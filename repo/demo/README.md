# Demo

## Generating test content

```bash
./make-demo-content.sh [target folder]
```

Default target is `~/Movies/qlab-versioning-demo`. Avoid Desktop, Documents and
Downloads — those are protected by macOS privacy controls and QLab will not be
able to list them without an explicit Files & Folders grant.

Produces:

| File | Colour | Purpose |
|---|---|---|
| `fileofvideo_v2608182200.png` | rust | point a Video cue here |
| `fileofvideo_v2608182205.png` | teal | the script should find this |
| `otherfileofvideo_v2608182201.png` | rust | point a Video cue here |
| `otherfileofvideo_v2608182206.png` | teal | the script should find this |
| `fileofvideo_vFINAL.png` | rust | malformed tag, should trigger a warning |

The two `otherfileofvideo` files exist to prove stem matching is exact —
`fileofvideo` is a suffix of `otherfileofvideo`, and the two sets must not
contaminate each other.

## Expected dry run result

```
2 of 2 media cues updated, 1 warning(s)  [DRY RUN]

  2  fileofvideo_v2608182200.png
      was: fileofvideo_v2608182200.png
      now: fileofvideo_v2608182205.png   (18 Aug 2026 22:05)
  3  otherfileofvideo_v2608182201.png
      was: otherfileofvideo_v2608182201.png
      now: otherfileofvideo_v2608182206.png   (18 Aug 2026 22:06)

WARNINGS:
  fileofvideo_vFINAL.png  —  tag is not _vYYMMDDHHmm
```

## Workspace

`Qlab_Versioning_Script_180826.qlab5.partial` is an incomplete upload — a
`.qlab5` is a macOS package, and it was flattened to the settings plist inside
it. It contains cue *templates* but no actual cues, so it will not open as a
working demo.

To replace it, compress the workspace first (right-click → Compress in Finder)
so the package survives transfer, then commit the `.zip`.

Note that a committed workspace carries security-scoped bookmarks to media on
whichever machine saved it. Those will not resolve after cloning, so the
generator script above is the more portable way to reproduce the demo.
