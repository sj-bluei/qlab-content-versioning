-- ============================================================
--  QLab Content Versioning
--  disguise-style automatic retargeting for media cues.
--
--  Scans the folder each cue's file target lives in, finds the
--  newest sibling sharing the same stem name and extension, and
--  retargets the cue to it.
--
--  TAG FORMAT — this build expects exactly:
--
--      _vYYMMDDHHmm        ten digits, no letter suffix
--
--      lowerthird.mov                base version, no tag
--      lowerthird_v2608181432.mov    18 Aug 2026, 14:32
--
--  Because every tag is the same width, a plain alphabetical sort
--  is also chronological order, so there is no _v2 / _v10 problem
--  and no sort mode to choose.
--
--  Anything that looks like a tag but isn't ten digits — a typo,
--  a truncated stamp, an impossible date — is EXCLUDED from the
--  running and reported as a warning rather than silently winning.
--
--  Note for disguise interchange: Designer's documented date tag
--  is _vYYYYMMDDHHMM with a four-digit year. A two-digit year
--  still parses and still sorts correctly on its own, but never
--  mix the two widths in one folder — "2026…" sorts before
--  "2608…", so a four-digit tag would lose to a two-digit one.
--
--  LOGGING
--    1. Memo cue  — create a Memo cue anywhere in the workspace
--       and set its cue NUMBER to match logCueNumber below. Its
--       name becomes a one-line status, its notes hold the detail.
--    2. Disk log  — appended to logFilePath, one block per run.
--
--    The log reports how many cues had a READABLE file target,
--    which extensions were skipped, and whether any folder could
--    not be listed — so a zero result always says why.
--
--  USE: paste into a Script Cue at the top of the workspace and
--  fire it pre-show. Run with dryRun set to true FIRST.
-- ============================================================

-- ---------- settings ----------
property dryRun : true -- true = report only, change nothing
property contentRoot : "" -- e.g. "/Users/show/Movies/SHOW_CONTENT" ; "" = anywhere
property showDialog : true -- summary dialog; turn off once the Memo cue is in place

property logCueNumber : "VLOG" -- cue number of the Memo cue to write into; "" = skip
property logFilePath : "" -- absolute POSIX path; "" = Desktop/QLab Content Versioning.log
property stampCueNotes : false -- also write a one-line note into each retargeted cue

-- Only these extensions are touched. Anything else is left alone.
-- Comparison is case-insensitive. QLab video cues play stills as
-- well as movies, so image formats belong here too — trim any you
-- don't want versioned.
property videoExtensions : {¬
	"mov", "mp4", "m4v", "mxf", "avi", "mkv", "mpg", "mpeg", "webm", "wmv", ¬
	"png", "jpg", "jpeg", "tif", "tiff", "gif", "bmp", "heic"}

-- QLab 4 users: change every "com.figure53.QLab.5" below to "com.figure53.QLab.4"
-- ------------------------------


on run
	set runStamp to my timestamp()
	
	tell application id "com.figure53.QLab.5"
		if not (exists front workspace) then
			display dialog "No QLab workspace is open." buttons {"OK"} default button 1
			return
		end if
		set rootCues to {}
		try
			set rootCues to every cue list of front workspace
		on error
			set rootCues to every cue of front workspace
		end try
	end tell
	
	set allCues to my flattenCues(rootCues)
	
	set nWithTarget to 0
	set nChecked to 0
	set nChanged to 0
	set report to {}
	set warnings to {}
	set skippedExts to {}
	
	repeat with c in allCues
		set currentPath to my targetPathOf(c)
		
		if currentPath is not "" then
			set nWithTarget to nWithTarget + 1
			set thisExt to my extensionOf(currentPath)
			
			if videoExtensions does not contain thisExt then
				if thisExt is "" then set thisExt to "(no extension)"
				if skippedExts does not contain thisExt then set end of skippedExts to thisExt
			else
				set inScope to true
				if contentRoot is not "" then
					if currentPath does not start with contentRoot then set inScope to false
				end if
				
				if inScope then
					set nChecked to nChecked + 1
					set scanResult to my scanFolder(currentPath)
					set newPath to item 1 of scanResult
					
					-- collect warnings, skipping ones already logged
					repeat with w in (item 2 of scanResult)
						set wTxt to contents of w
						if warnings does not contain wTxt then set end of warnings to wTxt
					end repeat
					
					if newPath is not currentPath then
						set nChanged to nChanged + 1
						set oldName to my lastPathComponent(currentPath)
						set newName to my lastPathComponent(newPath)
						set whenTxt to my prettyTag(newName)
						if whenTxt is not "" then set whenTxt to "   (" & whenTxt & ")"
						
						set cueNum to ""
						set cueName to ""
						tell application id "com.figure53.QLab.5"
							try
								set cueNum to q number of c
							end try
							-- q display name falls back to the filename when the
							-- cue has no user-set name, which is the usual case
							try
								set cueName to q display name of c
							on error
								try
									set cueName to q name of c
								end try
							end try
							if not dryRun then
								set file target of c to ((POSIX file newPath) as alias)
								if stampCueNotes then
									try
										set notes of c to "Auto-versioned " & runStamp & " -> " & newName
									end try
								end if
							end if
						end tell
						
						set end of report to "  " & cueNum & "  " & cueName & return & ¬
							"      was: " & oldName & return & ¬
							"      now: " & newName & whenTxt
					end if
				end if
			end if
		end if
	end repeat
	
	-- ---------- assemble the log ----------
	set AppleScript's text item delimiters to return
	set body to report as text
	set warnBody to warnings as text
	set AppleScript's text item delimiters to ", "
	set skipBody to skippedExts as text
	set AppleScript's text item delimiters to ""
	
	set statusLine to runStamp & " — " & (nChanged as text) & " of " & ¬
		(nChecked as text) & " media cues updated"
	if (count of warnings) > 0 then
		set statusLine to statusLine & ", " & ((count of warnings) as text) & " warning(s)"
	end if
	if dryRun then set statusLine to statusLine & "  [DRY RUN]"
	
	set detail to statusLine & return & ¬
		((count of allCues) as text) & " cues in workspace, " & ¬
		(nWithTarget as text) & " with a readable file target"
	if (count of skippedExts) > 0 then
		set detail to detail & return & ¬
			"extensions skipped (not in videoExtensions): " & skipBody
	end if
	if contentRoot is not "" then set detail to detail & return & "root: " & contentRoot
	
	if nChanged is 0 then
		set detail to detail & return & return & "  No newer versions found."
	else
		set detail to detail & return & return & body
	end if
	if (count of warnings) > 0 then
		set detail to detail & return & return & "WARNINGS:" & return & warnBody
	end if
	
	-- ---------- write to the Memo cue ----------
	set memoResult to ""
	if logCueNumber is not "" then
		set logCue to my findCueByNumber(allCues, logCueNumber)
		if logCue is missing value then
			set memoResult to "Memo cue \"" & logCueNumber & "\" not found — skipped."
		else
			tell application id "com.figure53.QLab.5"
				try
					set q name of logCue to statusLine
					set notes of logCue to detail
					set memoResult to "Logged to Memo cue " & logCueNumber & "."
				on error errMsg
					set memoResult to "Could not write Memo cue: " & errMsg
				end try
			end tell
		end if
	end if
	
	-- ---------- write to disk ----------
	set thePath to logFilePath
	if thePath is "" then
		set thePath to (POSIX path of (path to desktop folder)) & "QLab Content Versioning.log"
	end if
	set fileResult to my appendToFile(detail & return & "----------" & return, thePath)
	
	set summary to detail & return & return & memoResult & return & fileResult
	log summary
	if showDialog then display dialog summary buttons {"OK"} default button 1
	return summary
end run


-- Read a cue's file target, coping with either an alias/file
-- specifier or a plain text path. Returns "" if there isn't one.
on targetPathOf(c)
	set p to ""
	tell application id "com.figure53.QLab.5"
		try
			set ft to file target of c
			if ft is missing value then
				set p to ""
			else if (class of ft) is text then
				set p to ft
			else
				set p to POSIX path of ft
			end if
		on error
			set p to ""
		end try
	end tell
	-- if it came back as an HFS path, convert it
	if p is not "" and p does not start with "/" and p contains ":" then
		try
			set p to POSIX path of (p as alias)
		end try
	end if
	return p
end targetPathOf


-- Lowercasing isn't needed: AppleScript list comparison is
-- case-insensitive by default, so .MOV and .mov both match.
on extensionOf(p)
	if p does not contain "." then return ""
	set AppleScript's text item delimiters to "."
	set ext to last text item of p
	set AppleScript's text item delimiters to ""
	return ext
end extensionOf


-- Walk cue lists and groups recursively
on flattenCues(cueRefs)
	set out to {}
	tell application id "com.figure53.QLab.5"
		repeat with c in cueRefs
			set thisCue to contents of c
			set end of out to thisCue
			set kids to {}
			try
				set kids to every cue of thisCue
			end try
			if (count of kids) > 0 then set out to out & my flattenCues(kids)
		end repeat
	end tell
	return out
end flattenCues


on findCueByNumber(cueList, theNumber)
	tell application id "com.figure53.QLab.5"
		repeat with c in cueList
			try
				if (q number of c) is theNumber then return contents of c
			end try
		end repeat
	end tell
	return missing value
end findCueByNumber


-- Returns {winningPath, {warning, warning, ...}}
--
-- A sibling qualifies if it has the same extension and, after
-- stripping a strict _vYYMMDDHHmm tag, the same stem. Files whose
-- tag is malformed or whose date fields are out of range are
-- excluded and reported.
--
-- The cue's own file must always turn up as a candidate. If it
-- doesn't, the folder could not be listed — almost always a macOS
-- Files & Folders permission problem — and that is reported too.
on scanFolder(thePath)
	set sh to "t=" & quoted form of thePath & "; " & ¬
		"d=$(dirname \"$t\"); b=$(basename \"$t\"); " & ¬
		"e=$(printf '%s' \"${b##*.}\" | tr 'A-Z' 'a-z'); s=${b%.*}; " & ¬
		"r=$(printf '%s' \"$s\" | sed -E 's/_[vV][0-9]{10}$//'); " & ¬
		"out=$( for f in \"$d\"/*; do " & ¬
		"  [ -f \"$f\" ] || continue; " & ¬
		"  fb=$(basename \"$f\"); " & ¬
		"  fe=$(printf '%s' \"${fb##*.}\" | tr 'A-Z' 'a-z'); " & ¬
		"  [ \"$fe\" = \"$e\" ] || continue; " & ¬
		"  fs=${fb%.*}; " & ¬
		"  if [ \"$fs\" = \"$r\" ]; then printf 'CAND\\t\\t%s\\n' \"$f\"; continue; fi; " & ¬
		"  tag=$(printf '%s' \"$fs\" | sed -nE 's/^.*_[vV]([0-9]{10})$/\\1/p'); " & ¬
		"  froot=$(printf '%s' \"$fs\" | sed -E 's/_[vV][0-9]{10}$//'); " & ¬
		"  if [ -n \"$tag\" ] && [ \"$froot\" = \"$r\" ]; then " & ¬
		"    MO=$(printf '%s' \"$tag\" | cut -c3-4 | sed 's/^0//'); " & ¬
		"    DA=$(printf '%s' \"$tag\" | cut -c5-6 | sed 's/^0//'); " & ¬
		"    HO=$(printf '%s' \"$tag\" | cut -c7-8 | sed 's/^0//'); " & ¬
		"    MI=$(printf '%s' \"$tag\" | cut -c9-10 | sed 's/^0//'); " & ¬
		"    [ -n \"$MO\" ] || MO=0; [ -n \"$DA\" ] || DA=0; " & ¬
		"    [ -n \"$HO\" ] || HO=0; [ -n \"$MI\" ] || MI=0; " & ¬
		"    ok=1; " & ¬
		"    { [ \"$MO\" -ge 1 ] && [ \"$MO\" -le 12 ]; } || ok=0; " & ¬
		"    { [ \"$DA\" -ge 1 ] && [ \"$DA\" -le 31 ]; } || ok=0; " & ¬
		"    [ \"$HO\" -le 23 ] || ok=0; " & ¬
		"    [ \"$MI\" -le 59 ] || ok=0; " & ¬
		"    if [ \"$ok\" = 1 ]; then printf 'CAND\\t%s\\t%s\\n' \"$tag\" \"$f\"; " & ¬
		"    else printf 'WARN\\t  %s  —  not a valid date/time\\n' \"$fb\"; fi; " & ¬
		"    continue; " & ¬
		"  fi; " & ¬
		"  loose=$(printf '%s' \"$fs\" | sed -E 's/_[vV][0-9A-Za-z]*$//'); " & ¬
		"  if [ \"$loose\" = \"$r\" ] && [ \"$loose\" != \"$fs\" ]; then " & ¬
		"    printf 'WARN\\t  %s  —  tag is not _vYYMMDDHHmm\\n' \"$fb\"; " & ¬
		"  fi; " & ¬
		"done ); " & ¬
		"best=$(printf '%s\\n' \"$out\" | grep '^CAND' | cut -f2- | LC_ALL=C sort | tail -n 1 | cut -f2-); " & ¬
		"[ -n \"$best\" ] || best=\"$t\"; " & ¬
		"printf 'BEST\\t%s\\n' \"$best\"; " & ¬
		"printf '%s\\n' \"$out\" | grep '^WARN'; " & ¬
		"if ! printf '%s\\n' \"$out\" | grep -q '^CAND'; then " & ¬
		"  printf 'WARN\\t  could not list %s  —  check QLab has Files & Folders access\\n' \"$d\"; " & ¬
		"fi; true"
	
	set winner to thePath
	set warnList to {}
	try
		set res to do shell script sh
		set AppleScript's text item delimiters to tab
		repeat with ln in paragraphs of res
			set parts to text items of (contents of ln)
			if (count of parts) ≥ 2 then
				if item 1 of parts is "BEST" then
					set winner to item 2 of parts
				else if item 1 of parts is "WARN" then
					set end of warnList to item 2 of parts
				end if
			end if
		end repeat
		set AppleScript's text item delimiters to ""
	on error
		set AppleScript's text item delimiters to ""
	end try
	return {winner, warnList}
end scanFolder


-- "lowerthird_v2608181432.mov" -> "18 Aug 2026 14:32"
on prettyTag(fname)
	try
		set stem to fname
		if stem contains "." then
			set AppleScript's text item delimiters to "."
			set stem to (text items 1 thru -2 of stem) as text
			set AppleScript's text item delimiters to ""
		end if
		if (count of stem) < 12 then return ""
		set tail12 to text -12 thru -1 of stem
		if (text 1 thru 2 of tail12) is not "_v" then return ""
		set d to text 3 thru 12 of tail12
		repeat with ch in characters of d
			if "0123456789" does not contain (contents of ch) then return ""
		end repeat
		set monthNames to {"Jan", "Feb", "Mar", "Apr", "May", "Jun", ¬
			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
		set moNum to (text 3 thru 4 of d) as integer
		if moNum < 1 or moNum > 12 then return ""
		return (text 5 thru 6 of d) & " " & (item moNum of monthNames) & ¬
			" 20" & (text 1 thru 2 of d) & " " & ¬
			(text 7 thru 8 of d) & ":" & (text 9 thru 10 of d)
	on error
		return ""
	end try
end prettyTag


on appendToFile(txt, posixPath)
	try
		set fRef to open for access (POSIX file posixPath) with write permission
		write txt to fRef starting at eof
		close access fRef
		return "Appended to " & posixPath
	on error errMsg
		try
			close access (POSIX file posixPath)
		end try
		return "Could not write log file: " & errMsg
	end try
end appendToFile


on timestamp()
	try
		return do shell script "date '+%Y-%m-%d %H:%M'"
	on error
		return (current date) as text
	end try
end timestamp


on lastPathComponent(p)
	set AppleScript's text item delimiters to "/"
	set n to last text item of p
	set AppleScript's text item delimiters to ""
	return n
end lastPathComponent
