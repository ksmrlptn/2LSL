
-- =========================================================
-- YesCheckSetupScript.scpt
-- Yes Check fresh MacBook setup
-- =========================================================

property appName : "Yes Check"
property appPath : (POSIX path of (path to desktop)) & "Yes Check.app"
property adminPassword : "1234"

on run
	try
		-- 1. Verify application exists
		do shell script "test -d " & quoted form of appPath
		
		-- 2. Launch Yes Check first
		do shell script "open " & quoted form of appPath
		delay 8
		
		-- 3. Configure Full Disk Access
		my configurePermission("Privacy_AllFiles", "Full Disk Access")
		
		-- 4. Configure Accessibility
		my configurePermission("Privacy_Accessibility", "Accessibility")
		
		-- 5. Relaunch Yes Check
		do shell script "open " & quoted form of appPath
		delay 4
		
		display dialog "Yes Check setup sequence finished. Verify both permissions." buttons {"OK"} default button "OK"
		
	on error errorMessage number errorNumber
		display dialog "Setup stopped:" & return & errorMessage & return & "Error: " & errorNumber buttons {"OK"} default button "OK"
	end try
end run


-- =========================================================
-- CONFIGURE PERMISSION
-- =========================================================

on configurePermission(paneID, permissionName)
	
	set paneURL to "x-apple.systempreferences:com.apple.preference.security?" & paneID
	
	do shell script "open " & quoted form of paneURL
	delay 4
	
	set settingsProcessName to my getSettingsProcessName()
	
	tell application "System Events"
		tell process settingsProcessName
			set frontmost to true
		end tell
	end tell
	
	delay 2
	
	-- Search for Yes Check
	if my findYesCheckEntry(settingsProcessName) is false then
		
		-- Add Yes Check if it is missing
		my addYesCheck(permissionName)
		delay 3
		
	end if
	
	-- Find the switch associated with Yes Check
	set targetSwitch to my findYesCheckSwitch(settingsProcessName)
	
	if targetSwitch is missing value then
		error "Could not identify the Yes Check switch in " & permissionName & "."
	end if
	
	-- Read switch state and enable only when OFF
	tell application "System Events"
		try
			set currentState to value of targetSwitch
			
			if currentState is 0 then
				click targetSwitch
			end if
			
		on error errorMessage
			error "Could not read or change the switch in " & permissionName & ": " & errorMessage
		end try
	end tell
	
	delay 2
	
	-- Handle administrator authentication
	my handleAuthentication()
	
	delay 3
	
	-- Handle Yes Check restart prompt
	my handleRestartPrompt()
	
	delay 3
	
end configurePermission


-- =========================================================
-- DETECT SYSTEM SETTINGS
-- =========================================================

on getSettingsProcessName()
	tell application "System Events"
		if exists process "System Settings" then
			return "System Settings"
		else if exists process "System Preferences" then
			return "System Preferences"
		else
			error "System Settings process not found."
		end if
	end tell
end getSettingsProcessName


-- =========================================================
-- FIND YES CHECK ENTRY
-- =========================================================

on findYesCheckEntry(settingsProcessName)
	tell application "System Events"
		tell process settingsProcessName
			
			try
				set allElements to entire contents of window 1
				
				repeat with anElement in allElements
					
					try
						if (name of anElement as text) contains "Yes Check" then
							return true
						end if
					end try
					
					try
						if (description of anElement as text) contains "Yes Check" then
							return true
						end if
					end try
					
				end repeat
			end try
			
		end tell
	end tell
	
	return false
end findYesCheckEntry


-- =========================================================
-- FIND YES CHECK SWITCH
-- =========================================================

on findYesCheckSwitch(settingsProcessName)
	tell application "System Events"
		tell process settingsProcessName
			
			try
				set allElements to entire contents of window 1
				
				repeat with anElement in allElements
					
					set matchesEntry to false
					
					try
						if (name of anElement as text) contains "Yes Check" then
							set matchesEntry to true
						end if
					end try
					
					try
						if (description of anElement as text) contains "Yes Check" then
							set matchesEntry to true
						end if
					end try
					
					if matchesEntry then
						
						try
							if role of anElement is "AXSwitch" then
								return contents of anElement
							end if
						end try
						
						try
							repeat with childElement in entire contents of anElement
								try
									if role of childElement is "AXSwitch" then
										return contents of childElement
									end if
								end try
							end repeat
						end try
						
					end if
					
				end repeat
			end try
			
		end tell
	end tell
	
	return missing value
end findYesCheckSwitch


-- =========================================================
-- ADD YES CHECK THROUGH FILE PICKER
-- =========================================================

on addYesCheck(permissionName)
	tell application "System Events"
		
		set settingsProcessName to my getSettingsProcessName()
		
		tell process settingsProcessName
			set frontmost to true
			delay 2
			
			set addButton to missing value
			
			try
				repeat with aButton in buttons of window 1
					try
						set buttonName to name of aButton as text
						
						if buttonName is "+" then
							set addButton to contents of aButton
							exit repeat
						end if
					end try
					
					try
						set buttonDescription to description of aButton as text
						
						if buttonDescription contains "Add" then
							set addButton to contents of aButton
							exit repeat
						end if
					end try
				end repeat
			end try
			
			if addButton is missing value then
				error "Add (+) button not found in " & permissionName & "."
			end if
			
			click addButton
			delay 2
			
			-- Open Go to Folder
			keystroke "g" using {command down, shift down}
			delay 1
			
			keystroke appPath
			delay 1
			keystroke return
			delay 2
			
			-- Confirm application selection
			keystroke return
		end tell
		
	end tell
	
	delay 3
	
	my handleAuthentication()
	
end addYesCheck


-- =========================================================
-- ADMINISTRATOR AUTHENTICATION
-- =========================================================

on handleAuthentication()
	tell application "System Events"
		
		try
			tell process "SecurityAgent"
				
				if exists window 1 then
					
					repeat with aField in secure text fields of window 1
						try
							click aField
							keystroke adminPassword
							keystroke return
							return
						end try
					end repeat
					
				end if
				
			end tell
		end try
		
	end tell
end handleAuthentication


-- =========================================================
-- HANDLE QUIT AND REOPEN
-- =========================================================

on handleRestartPrompt()
	tell application "System Events"
		
		try
			tell process appName
				
				if exists window 1 then
					
					repeat with aButton in buttons of window 1
						
						try
							set buttonName to name of aButton as text
							
							if buttonName contains "Quit & Reopen" or buttonName contains "Quit and Reopen" or buttonName is "Reopen" then
								click aButton
								return
							end if
							
						end try
						
					end repeat
					
				end if
				
			end tell
		end try
		
	end tell
end handleRestartPrompt
