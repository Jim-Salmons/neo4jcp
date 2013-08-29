;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; 
; Neo4j Control Panel
;
; by Jim Salmons, https://github.com/Jim-Salmons
; Project Home: http://jim-salmons.github.io/neo4jcp/
; Feedback/Issues: https://github.com/Jim-Salmons/Neo4jCP/Issues
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

#SingleInstance force

; Supports doing headless commandline interaction with returned output...
; thanks to TODO: url to the forum post where this class came from...
#Include CLI_class.ahk

;;;
;; Read the ini file to set key vars and command line configurations, etc.
;
Neo4jCP_readIni()
Neo4jCP_init()

;; Listen for the Help button coming from the About box.
;
OnMessage(0x53, "WM_HELP")

;;;;;
;; The Control Panel main window...
;;;;;
Gui, wMain:New, , Neo4j Control Panel
Gui, +OwnDialogs +Border
Gui, Add, Text, vServiceName_txt x12 y15 w200 h20 , Neo4j Service: %Neo4j_ServiceName%
Gui, Add, Button, vStartStop_btn gStartStop_action x172 y10 w60 h20 , Stop/Start
Gui, Add, Button, vRestart_btn gRestart_action x242 y10 w60 h20 , Restart
Gui, Add, GroupBox, x2 y40 w300 h80 , Database actions
Gui, Add, Radio, vChangeAction_rb Checked x12 y60 w70 h20 , Change-to
Gui, Add, Radio, vBackupAction_rb x82 y60 w60 h20 , Backup
Gui, Add, Radio, vCloneAction_rb x142 y60 w50 h20 , Clone
Gui, Add, Radio, vDeleteAction_rb x192 y60 w50 h20 , Delete
Gui, Font, underline
Gui, Add, Text, vNew_txt cBlue gCreateNewDB_action x248 y62 w50 h20 , New...
Gui, Font, normal
Gui, Add, DropDownList, vTargetDB_ddl gTargetDB_action Sort x12 y90 w180
Gui, Add, Text, x202 y86 w100 h30 , Select action then DB dropdown.
Gui, Add, StatusBar, , TBD...

; Populate the DDL with current DB names...
currentDatabases := Neo4jCP_databases()
GuiControl, , TargetDB_ddl, %currentDatabases%

;;;
;; Turn the Monitor OFF during development/debugging
;
Neo4jCP_startMonitor()

; Select the currently running database on the list...
GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%

Gui, Show, X%cpX% Y%cpY%

return

;
;; end of autoexec part
;;;
;;;;;;;;;;;;;;;;;;;;;;;

;;;;
;;;
;; Widget handler subroutines (proto-functions)
;

;;;
;; Handle main window and tray menu item open/closed state, etc.
;
Neo4jCP_tray_MenuHandler:
	IfEqual, A_ThisMenuItem, Open Neo4jCP
	{
		IfWinNotExist, %StatusMsg%
		{
			Gui, wMain:Default
			Gui, wMain:Show
			return
		} Else {
			Gui, wMain:Default
			Gui, wMain:Hide
			return
		}
	}
	IfEqual, A_ThisMenuItem, About Neo4jCP
	{
		Gui +OwnDialogs
		msgBox2Move := "About Neo4jCP"
		SetTimer, WinMoveMsgBox, 20
		MsgBox, 16384, %msgBox2Move%, Neo4j Control Panel`nBy: Jim Salmons`nProject Home: http://jim-salmons.github.io/neo4jcp/`nHelp opens browser on Project Issues/Feedback page.
		return
	}
	IfEqual, A_ThisMenuItem, Exit Neo4jCP
			ExitApp
return

;;;
;; Respond to the Start/Stop server button
;
StartStop_action:
	; Do whatever the button's label says to do...
	GuiControlGet, db_action, , StartStop_btn, Text

	IfEqual, db_action, Start
	{
		; Start the server service...
		Neo4jCP_svrService("start")
	} Else {
		; Stop the server service...
		Neo4jCP_svrService("stop")
	}
	IfEqual, Neo4jCP_MonitorState, OFF
	{
		Sleep, Neo4j_ServiceActionDelay
		Neo4jCP_updateStatus()
		Neo4jCP_refreshWin()
	}
return ; End StartStop_action...

;;;
;; Respond to the Restart button
;
Restart_action:

	Neo4jCP_svrService("restart")
	IfEqual, Neo4jCP_MonitorState, OFF
	{
		Sleep, Neo4j_ServiceActionDelay
		Neo4jCP_updateStatus()
		Neo4jCP_refreshWin()
	}	
return

;;;
;; This subroutine responds to the Timer that updates the CP's status UI widgets, etc.
;
Neo4jCP_refreshStatus:
	Neo4jCP_updateStatus()
	Neo4jCP_refreshWin()
return

;;;
;; Utility subroutine to move MsgBoxes relative to the CP position
;
WinMoveMsgBox:
	SetTimer, WinMoveMsgBox, OFF
	ID:=WinExist(msgBox2Move)
	Neo4jCP_dialogPos(dialogX, dialogY)
	WinMove, ahk_id %ID%, , %dialogX%, %dialogY%
Return

;;;
;;  May be used by Timers that want to shorten TrayTip pop-up duration.
;
RemoveTrayTip:
	TrayTip
return

;;;
;; The New Database Action
;
CreateNewDB_action:
	Gui +OwnDialogs
	NewDB_name := ""

	InputBox, NewDB_name, Create Neo4j Database, New Database name: , , 200 , 120 , cpX , cpY
	if ErrorLevel
		; Canceled...
		return
	
	; Check that the new name is unique...
	Success := Neo4jCP_dbname_check(NewDB_name)
	if Success
	{
		; Simply create a folder (check that it has the .db suffix) in the db_dir
		NewName := StrLen(NewDB_name)
		IfEqual , NewName , 0
		{
			msgBox2Move := "Neo4jCP New DB Action"
			SetTimer, WinMoveMsgBox, 20
			MsgBox, 36, %msgBox2Move%, Please provide a new name. Try again...
			return
		} else {
			; Char position is zero-based so offset by one (2 rather than 3 chars in ext)
			TargetNum := NewName - 2
		}
		; Search for the extension suffix at the end of the new name...
		ExtPos := InStr( NewDB_name , .db , false , 0 )
		IfEqual , ExtPos , 0
			NewDB_name := NewDB_name . ".db"
		else
		{
			; Is it at the end?...
			IfNotEqual , ExtPos , %TargetNum%
				NewDB_name := NewDB_name . ".db"
		}
		msgBox2Move := "Neo4jCP New DB Action"
		SetTimer, WinMoveMsgBox, 20
		MsgBox, 36, %msgBox2Move%, Create database named %NewDB_name%?
		IfMsgBox, No
			return
		SetWorkingDir, %db_dir%
		FileCreateDir , %NewDB_name%

		msgBox2Move := "Neo4jCP New DB Action"
		;SetTimer, WinMoveMsgBox, 20
		;MsgBox, 48, %msgBox2Move%, %NewDB_name% created.`nWill be initialized on first access.
		TrayTip, %msgBox2Move%, %NewDB_name% created.`nWill be initialized on first access., %Neo4jCP_TrayTipDelay%, 1

		IfEqual, Neo4jCP_MonitorState, OFF
		{
			; Refresh the TargetDB_ddl...
			GuiControl, , TargetDB_ddl, %NewDB_name%
		}
	} else {
		; This notice delivered by MsgBox rather than TrayTip.
		MsgBox , , Create Neo4j Database, A database named %NewDB_name%`nalready exists. Try another name...
	}
return ; end New Database Action

;;;
;; This responds to DB DropDownList item selection events 
;
TargetDB_action:
	; The DDL and radio buttons determine the action to take...
	Gui +OwnDialogs
	Gui , Submit , NoHide
	; GuiControlGet, TargetDB_ddl ; Retrieve the selected radio button

	;;;;;;;;;;;;
	;;
	;; Handle the response to an action requrest based on the 
	;; DB Task radio button group's context. Basic services are;
	;; change-to, backup, clone, delete and create DB operations
	;; plus convenient UI for start/stop/restart DB service control.
	;;
	;;;;;;;;;;;;

	;;;
	;; Change-to feature BEGIN
	;
	IfEqual , ChangeAction_rb , 1
	{
		; Different than the CurrentDB?
		; If not, do nothing...
		newDb_loc := db_relpath . "/" . TargetDB_ddl
		IfEqual, TargetDB_ddl, %CurrentDB%
			return

		;; Good to go?...
		;
		msgBox2Move := "Neo4jCP Change-to Action"
		SetTimer, WinMoveMsgBox, 20
		MsgBox, 36, %msgBox2Move%, Switch to the %TargetDB_ddl% database?
		IfMsgBox, No
		{
			; restore the CurrentDB selection in the DDL...
			GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%
			return
		}
		;;;;;;;;;
		; Rename the existing server properties file in prep for writing the new one...
		FileMove, %conf_file%, %conf_file%.old  

		; Now, read the old properties file line-by-line and replace the db location 
		; based on the new TargetDB_ddl selection...
		SourceFile = %conf_file%.old
		DestFile = %conf_file%

		IfExist, %DestFile%
			FileDelete, %DestFile%

		Loop, read, %SourceFile%, %DestFile%
		{
			IfInString, A_LoopReadLine, org.neo4j.server.database.location
			{
				; We want the current running db so we can set the GUI's DDL
				FileAppend, org.neo4j.server.database.location=%newDb_loc%`n
			}
			else
			{
				FileAppend, %A_LoopReadLine%`n
			}		
		}

		Menu, tray, Icon, %A_ScriptDir%/Neo4jCP2.ico
		
		;;;
		;; Manually set interim status reporting...
		;
		Neo4jCP_updateStatus( , "RESTARTING" , "Pending")

		Neo4jCP_svrService("restart")

		; Delete the old properties file...
		SetWorkingDir, %conf_dir%
		FileDelete, %SourceFile%

		Menu, tray, Icon, %A_ScriptDir%/Neo4jCP.ico
		; Update the CurrentDB and SrvState values...
		CurrentDB := TargetDB_ddl
		IfEqual, Neo4jCP_MonitorState, OFF
		{
			Neo4jCP_updateStatus()
			Neo4jCP_refreshWin()
		}
		TrayTip, Neo4jCP Change-to Action, Now serving the %CurrentDB% database., %Neo4jCP_TrayTipDelay%, 1
		return
	}
	;
	;; Change-to feature END
	;;;

	;;;
	;; Backup feature BEGIN
	;
	IfEqual , BackupAction_rb , 1
	{
		; Good to go?...
		msgBox2Move := "Neo4jCP Backup Action"
		SetTimer, WinMoveMsgBox, 20
		MsgBox, 36, %msgBox2Move%, Backup the %TargetDB_ddl% database?
		IfMsgBox, No
		{
			; restore the CurrentDB selection in the DDL...
			GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%
			return
		}
		;; Back up the DDL-selected database based on the
		;; backup configuration setting.
		;; Note: Absolute Windows paths use backslash...
		;
		IfExist, %db_backupdir%\%TargetDB_ddl%
			FileRemoveDir, %db_backupdir%\%TargetDB_ddl% , 1
		If ErrorLevel
		{
			msgBox2Move := "Neo4jCP Backup Action"
			SetTimer, WinMoveMsgBox, 20
			MsgBox, 48, %msgBox2Move%, A prior backup exists and could not be deleted...
		}
		FileCopyDir, %db_dir%\%TargetDB_ddl% , %db_backupdir%\%TargetDB_ddl% , 
		If ErrorLevel
		{
			msgBox2Move := "Neo4jCP Backup Action"
			SetTimer, WinMoveMsgBox, 20
			MsgBox, 48, %msgBox2Move%, The backup was not successful. Perhaps access is denied...
		}
		msgBox2Move := "Neo4jCP Backup Action"
		;SetTimer, WinMoveMsgBox, 20
		;MsgBox, 48, %msgBox2Move%, Back-up complete.
		TrayTip, %msgBox2Move%, %TargetDB_ddl% backed up., %Neo4jCP_TrayTipDelay%, 1
		Sleep, 2000

		; restore the CurrentDB selection in the DDL...
		GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%

		return
	}
	;
	;; Backup feature END
	;;;

	;;;
	;; Clone feature BEGIN
	;
	IfEqual , CloneAction_rb , 1
	{
		StringTrimRight, CloneDB_nameRoot, TargetDB_ddl, 3
		CloneDB_name := CloneDB_nameRoot . "_clone.db"
		InputBox, CloneDB_name, Neo4j Clone Action, Cloned database new name:, , 200 , 120 , cpX , cpY , , , %CloneDB_name%
		if ErrorLevel
		{
			; Canceled... so,restore the CurrentDB selection in the DDL...
			GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%
			return
		}
		; Check that the new name is unique...
		Success := Neo4jCP_dbname_check(CloneDB_name)
		if Success
		{
			; Simply create a folder (check that it has the .db suffix) in the db_dir
			NewName := StrLen(CloneDB_name)
			IfEqual , NewName , 0
			{
				msgBox2Move := "Neo4jCP Clone Action"
				SetTimer, WinMoveMsgBox, 20
				MsgBox, 48, %msgBox2Move%, Please provide a name for the cloned database.
				return
			} else {
				; Char position is zero-based so offset by one (2 rather than 3 chars in ext)
				TargetNum := NewName - 2
			}
			; Search for the extension suffix at the end of the new name...
			ExtPos := InStr( CloneDB_name , .db , false , 0 )
			IfEqual , ExtPos , 0
				CloneDB_name := CloneDB_name . ".db"
			else
			{
				; Is it at the end?...
				IfNotEqual , ExtPos , %TargetNum%
					CloneDB_name := CloneDB_name . ".db"
			}
			;msgBox2Move := "Neo4jCP Clone Action"
			;SetTimer, WinMoveMsgBox, 20
			;MsgBox, 36, %msgBox2Move%, Create clone database named %CloneDB_name%?
			;IfMsgBox, No
			;	return
			SetWorkingDir, %db_dir%

			FileCopyDir, %db_dir%\%TargetDB_ddl% , %db_dir%\%CloneDB_name% , 
			If ErrorLevel
			{
				msgBox2Move := "Neo4jCP Clone Action"
				SetTimer, WinMoveMsgBox, 20
				MsgBox, 48, %msgBox2Move%, The cloning was not successful.`nPerhaps access is denied...
			}

			IfEqual, Neo4jCP_MonitorState, OFF
			{
				; Pop the cloned database into the DDL...
				GuiControl, , TargetDB_ddl, %CloneDB_name%
			}

			; restore the CurrentDB selection in the DDL...
			GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%
			
			msgBox2Move := "Neo4jCP Clone Action"
			;SetTimer, WinMoveMsgBox, 20
			;MsgBox, 48, %msgBox2Move%, New CLONED database created.
			TrayTip, %msgBox2Move%, %CloneDB_name% CLONED from %CloneDB_nameRoot%.db., %Neo4jCP_TrayTipDelay%, 1
			Sleep, 2000
		} else {
			msgBox2Move := "Neo4jCP Clone Action"
			SetTimer, WinMoveMsgBox, 20
			MsgBox, 48, %msgBox2Move%, Name not available. Try another...
		}
	return
	}
	;
	;; Clone feature END
	;;;

	;;;
	;; Delete feature BEGIN
	;
	IfEqual , DeleteAction_rb , 1
	{
		; Good to go?...
		msgBox2Move := "Neo4jCP Delete Action"
		SetTimer, WinMoveMsgBox, 20
		MsgBox, 36, %msgBox2Move%, DELETE the %TargetDB_ddl% database?
		IfMsgBox, No
		{
			; restore the CurrentDB selection in the DDL...
			GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%
			return
		}
		;; Note: Absolute Windows paths use backslash...
		;
		IfExist, %db_dir%\%TargetDB_ddl%
			FileRemoveDir, %db_dir%\%TargetDB_ddl% , 1
		If ErrorLevel
		{
			msgBox2Move := "Neo4jCP Delete Action"
			SetTimer, WinMoveMsgBox, 20
			MsgBox, 48, %msgBox2Move%, The database could not be deleted.`nPerhaps it is in use or a file locked.
			return
		}

		; restore the CurrentDB selection in the DDL...
		GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%

		msgBox2Move := "Neo4jCP Delete Action"
		;SetTimer, WinMoveMsgBox, 20
		;MsgBox, 48, %msgBox2Move%, %TargetDB_ddl% deleted.
		TrayTip, %msgBox2Move%, %TargetDB_ddl% deleted., %Neo4jCP_TrayTipDelay% , 1
		Sleep, 2000
		return
	}
	;
	;; Delete feature END
	;;;

return ; End TargetDB_action subroutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Some useful functions...
;;;;;;;;;;;;;;;;;;;;;;;;;;;

Neo4jCP_currentDB()
{
	global
	precheck_DB := CurrentDB

	SetWorkingDir, %conf_dir%
	
	Loop, read, %conf_file%
	{
		IfInString, A_LoopReadLine, org.neo4j.server.database.location
		{
			; We want the current running db so we can set the GUI's DDL
			Success := RegExMatch(A_LoopReadLine, "org\.neo4j\.server\.database\.location=.*/(.*)", Matches)
			IfEqual, Success , 1
			{
				IfNotEqual, precheck_DB, %Matches1%
				{
					CurrentDB = %Matches1%
					;;;
					;; Update the tray icon tooltip and to-be main window
					;
					Neo4jCP_updateStatus()
				}
			}
			break
		}
	}
}

;;;
;; Get the status of the server's service
;
Neo4jCP_svrStatus()
{
	global SvrState, Neo4j_ServiceName

	FileEncoding, CP850
	runner:= new cli("cmd.exe")
	sleep 300
	runner.stdin("sc query " . Neo4j_ServiceName . "`r`n")
	sleep 100
	out:=runner.stdout()
	runner.stdin("exit`r`n")
	runner.close() 

	Result := RegExMatch(out, "STATE.*:....(.*).", Matches)

	IfNotEqual, SvrState, %Matches1%
	{
		;;;
		;;  Update the Svr_State global
		;   TODO: Check that this is beneign...
		SvrState := Matches1
	}
	return Matches1
}

Neo4jCP_startMonitor()
{
	global
	gosub Neo4jCP_refreshStatus
	IfEqual, Neo4jCP_MonitorState, ON
		SetTimer, Neo4jCP_refreshStatus, %Neo4j_ServiceActionDelay%
	return
}

Neo4jCP_updateStatus( pStatusMsg = "" , pSvrState = "", pCurrentDB = "" )
{
	global ; so our existing Status Messages are not overwritten...
	;;
	; Update CurrentDB and SvrState first...
	Neo4jCP_currentDB()
	Neo4jCP_svrStatus()

	if(pStatusMsg <> "")
		StatusMsg := pStatusMsg
	if(pSvrState <> "")
		SvrState := pSvrState
	if(pCurrentDB <> "")
		CurrentDB := pCurrentDB

	;; Update the tray icon tooltip and main window statusbar...
	;
	Menu, Tray, Tip, %StatusMsg%`nSvr State: %SvrState%`nDatabase: %CurrentDB%
	Result := SB_SetText("Svr State: " . SvrState . "`t`tDB: " . CurrentDB)
	IfEqual, Result, 0
	{
		IfWinExist, %StatusMsg%
		{
			Gui, wMain:Default
			Result := SB_SetText("Svr State: " . SvrState . "`t`tDB: " . CurrentDB)

			IfEqual, Result, 0
				Msgbox, Nuts! This should not happen...
		}
	}
}

Neo4jCP_databases(pReturnAs := "pipedStr")
{
	global db_dir
	SetWorkingDir, %db_dir%
	databases := Object()
	databasesStr := ""

	Loop, *, 2
	{
		if A_LoopFileName = log	; Ignore the log folder.
			continue
		; Add the DB folder to the DDL...
		; We need the full paths but show simple folder names...
		databases.Insert(A_LoopFileName)
		databasesStr := databasesStr . "|" . A_LoopFileName
	}

	;;;
	;; Return based on type requested, default pipedStr
	;
	IfEqual, pReturnAs, pipedStr
		return databasesStr
	Else
		return databases
}

Neo4jCP_dbname_check(pNewName)
{
	SetWorkingDir, %db_dir%
	available :=  true
	Loop, *, 2
	{
		IfEqual , A_LoopFileName , log	; Ignore the log folder.
			continue
		IfEqual , A_LoopFileName , %pNewName%
		{
			available := false
			break
		} Else IfEqual, A_LoopFileName, %pNewName%.db
		{
			available := false
			break
		}
	}
	return available
}

Neo4jCP_refreshWin()
{
	global
	Gui , wMain:Default

	;;;
	;; Check and set the Server service buttons...
	;
	curStatus := Neo4jCP_svrStatus()
	IfEqual, curStatus , RUNNING
	{
		GuiControl, , StartStop_btn , Stop
		GuiControl, Enable , Restart_btn
		Menu, tray, Icon, %A_ScriptDir%/Neo4jCP.ico
	}
	Else
	{
		GuiControl, , StartStop_btn , Start
		GuiControl, Disable , Restart_btn
		Menu, tray, Icon, %A_ScriptDir%/Neo4jCP2.ico
	}

	;;;
	;; Any new databases? If so, update the DDList
	;	
	IfEqual, lastCheckDatabases, 
	{
		lastCheckDatabases := Neo4jCP_databases()
	}
	currentDatabases := Neo4jCP_databases()
	IfEqual, currentDatabases, %lastCheckDatabases%
		return

	GuiControl, , TargetDB_ddl, %currentDatabases%
	lastCheckDatabases := currentDatabases
	; Select the currently running database on the list...
	GuiControl, ChooseString, TargetDB_ddl, %CurrentDB%

	return
}

;;;
;; Do start/stop/restart actions on the Neo4j server service.
;
Neo4jCP_svrService( pDoAction , pServerName := "" )
{
	global

	IfEqual, pServerName,
		local svr_name := Neo4j_ServiceName
	Else
		local svr_name := pServerName

	IfInString, Neo4jCP_serverActions , %pDoAction%
	{
		IfEqual , pDoAction , restart
		{
			; do a stop and then start command service operation...
			run_sc_stop := "sc stop " . svr_name
			run_sc_start := "sc start " . svr_name
			IfEqual, AdminUser_pw, 
			{
				msgBox2Move := "Neo4jCP Password Required"
				SetTimer, WinMoveMsgBox, 20
				InputBox, AdminUser_pw, %msgBox2Move%, Admin Password: , HIDE , 200 , 120 , cpX , cpY
				if ErrorLevel {
					; TODO: Not sure if return is proper response here...
					return
				}
			}
			RunAs, Administrator, %AdminUser_pw%
			RunWait, %run_sc_stop%, , Hide
			Sleep , Neo4j_ServiceActionDelay
			RunWait, %run_sc_start%, , Hide
			RunAs
		} else {
			; we're either starting or stopping, a one command service operation...
			run_sc_cmd := "sc " . pDoAction . " " . svr_name
			IfEqual, AdminUser_pw, 
			{
				msgBox2Move := "Neo4jCP Password Required"
				SetTimer, WinMoveMsgBox, 20
				InputBox, AdminUser_pw, %msgBox2Move%, Admin Password: , HIDE , 200 , 120 , cpX , cpY
				if ErrorLevel {
					; TODO: Not sure if return is proper response here...
					return
				}
			}
			RunAs, Administrator, %AdminUser_pw%
			;RunWait, cmd.exe /c %run_cmd_str%, , Hide
			RunWait, %run_sc_cmd%, , Hide
			RunAs
		}
	}
	return
}

;;;
;; Utility function used to position dialogs, etc. relative
;; to the Main CP window (whether current open or hidden).
;
Neo4jCP_dialogPos(ByRef dialogX, ByRef dialogY)
{
	global dialogOffsetX, dialogOffsetY

	;; Check/update the position of the current CP...
	;
	DetectHiddenWindows, On
	WinGetPos, cpX, cpY, cpWidth, cpHeight, Neo4j Control Panel
	dialogX := cpX + dialogOffsetX
	dialogY := cpY + dialogOffsetY
	DetectHiddenWindows, Off
	return
}

;;;
;; Read the ini file to set key global variables and
;; command-line configurations, etc.
;
Neo4jCP_readIni()
{
	global
	; IniRead, , Neo4jCP.ini, Neo4jCP, , %A_Space%
	IniRead, AdminUser_pw, Neo4jCP.ini, Neo4jCP, AdminUser_pw , %A_Space%
	IniRead, conf_dir, Neo4jCP.ini, Neo4jCP, conf_dir, %A_Space%
	IniRead, conf_filename, Neo4jCP.ini, Neo4jCP, conf_filename, %A_Space%
	IniRead, db_dir, Neo4jCP.ini, Neo4jCP, db_dir, %A_Space%
	IniRead, db_relpath, Neo4jCP.ini, Neo4jCP, db_relpath, %A_Space% ; no trailing slash
	IniRead, db_backupdir, Neo4jCP.ini, Neo4jCP, db_backupdir, %A_Space%
	IniRead, Neo4j_ServiceName, Neo4jCP.ini, Neo4jCP, Neo4j_ServiceName, %A_Space%
	IniRead, Neo4j_ServiceActionDelay, Neo4jCP.ini, Neo4jCP, Neo4j_ServiceActionDelay, %A_Space%
	IniRead, Neo4jCP_serverActions, Neo4jCP.ini, Neo4jCP, Neo4jCP_serverActions, %A_Space%
	IniRead, RunServerCmd_stock, Neo4jCP.ini, Neo4jCP, RunServerCmd_stock, %A_Space%]
	IniRead, RunServerParams_stock, Neo4jCP.ini, Neo4jCP, RunServerParams_stock, %A_Space%]
	IniRead, RunServerCmd_hstart, Neo4jCP.ini, Neo4jCP, RunServerCmd_hstart, %A_Space%]
	IniRead, RunServerParams_hstart, Neo4jCP.ini, Neo4jCP, RunServerParams_hstart, %A_Space%]
	IniRead, cpWidth, Neo4jCP.ini, Neo4jCP, cpWidth, %A_Space%
	IniRead, cpInitWinOffsetX, Neo4jCP.ini, Neo4jCP, cpInitWinOffsetX, %A_Space%
	IniRead, cpHeight, Neo4jCP.ini, Neo4jCP, cpHeight, %A_Space%
	IniRead, cpInitWinOffsetY, Neo4jCP.ini, Neo4jCP, cpInitWinOffsetY, %A_Space%
	IniRead, Neo4jCP_MonitorState, Neo4jCP.ini, Neo4jCP, Neo4jCP_MonitorState, %A_Space%
	IniRead, dialogOffsetX, Neo4jCP.ini, Neo4jCP, dialogOffsetX, %A_Space%
	IniRead, dialogOffsetY, Neo4jCP.ini, Neo4jCP, dialogOffsetY, %A_Space%
	IniRead, Neo4j_TrayTipDelay, Neo4jCP.ini, Neo4jCP, Neo4j_TrayTipDelay, %A_Space%
	
	; Together, the above give us the full path and filename...
	conf_file = %conf_dir%\%conf_filename%

	return
}

Neo4jCP_init()
{
	global

	;; Get the screen resolution and remember in dt_ vars
	;
	WinGetPos, dtX, dtY, dtWidth, dtHeight, Program Manager

	;; Set the CP's icon and config the taskbar tray icon menu
	;
	Menu, tray, NoStandard
	Menu, tray, Icon, %A_ScriptDir%/Neo4jCP.ico
	Menu, tray, add, Open Neo4jCP, Neo4jCP_tray_MenuHandler 
	Menu, tray, Default, Open Neo4jCP
	Menu, tray, Click, 1
	Menu, tray, add, About Neo4jCP, Neo4jCP_tray_MenuHandler
	Menu, tray, add  ; Creates a separator line.
	Menu, tray, add, Exit Neo4jCP, Neo4jCP_tray_MenuHandler 

	;; Tray Tip and Main Window Statusbar carry same info...
	;
	StatusMsg := "Neo4j Control Panel"
	SvrState := "TBD"
	CurrentDB := "TDB"

	;; The initial X.Y of the CP when opened first time...
	;
	cpX := dtWidth - cpWidth - cpInitWinOffsetX
	cpY := dtHeight - cpHeight - cpInitWinOffsetY

	;;;
	;; Supported Control Panel server service commands -- the basics
	;
	Neo4jCP_serverActions = start stop restart

	return
}

WM_HELP(wParam, lParam)
{
	RunWait, cmd.exe /c start https://github.com/Jim-Salmons/Neo4jCP/issues, , Hide
	return
}

;;;;;;;;;;;;;;;;;;
;; Over and out...
GuiClose:
GuiEscape:
wMainGuiClose:
wMainGuiEscape:
Gui, Hide
return
ExitApp
