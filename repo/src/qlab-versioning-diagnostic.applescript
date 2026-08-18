-- ============================================================
--  QLab file target diagnostic
--
--  Run this in Script Editor with the workspace open. It walks
--  every cue and reports what, if anything, it can read from the
--  file target property — and what class that value is.
--
--  Result appears in Script Editor's Result pane AND is written to
--  ~/Desktop/QLab cue dump.txt
--
--  QLab 4: change both "com.figure53.QLab.5" strings to ".4"
-- ============================================================

on run
	set out to {}
	
	tell application id "com.figure53.QLab.5"
		if not (exists front workspace) then
			display dialog "No QLab workspace is open." buttons {"OK"} default button 1
			return
		end if
		set rootCues to {}
		try
			set rootCues to every cue list of front workspace
			set end of out to "Entry point: every cue list"
		on error errm
			set end of out to "cue list element FAILED: " & errm
			set rootCues to every cue of front workspace
			set end of out to "Entry point: every cue (fallback)"
		end try
	end tell
	
	set allCues to my flattenCues(rootCues)
	set end of out to "Cues found: " & (count of allCues)
	set end of out to "----------"
	
	tell application id "com.figure53.QLab.5"
		repeat with c in allCues
			set cNum to "?"
			set cName to ""
			set cType to "?"
			try
				set cNum to q number of c
			end try
			try
				set cName to q name of c
			end try
			try
				set cType to q type of c
			on error
				set cType to "q type UNAVAILABLE"
			end try
			
			set entry to cNum & "  [" & cType & "]  " & cName
			
			try
				set ft to file target of c
				set entry to entry & return & "      class: " & ((class of ft) as text)
				try
					set entry to entry & return & "      POSIX path: " & (POSIX path of ft)
				on error e2
					set entry to entry & return & "      POSIX path FAILED: " & e2
					try
						set entry to entry & return & "      as text: " & (ft as text)
					on error e3
						set entry to entry & return & "      as text FAILED: " & e3
					end try
				end try
			on error e1
				set entry to entry & return & "      file target unreadable: " & e1
			end try
			
			set end of out to entry
		end repeat
	end tell
	
	set AppleScript's text item delimiters to return
	set r to out as text
	set AppleScript's text item delimiters to ""
	
	set dumpPath to (POSIX path of (path to desktop folder)) & "QLab cue dump.txt"
	try
		set fRef to open for access (POSIX file dumpPath) with write permission
		set eof fRef to 0
		write r to fRef
		close access fRef
	on error
		try
			close access (POSIX file dumpPath)
		end try
	end try
	
	return r
end run


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
