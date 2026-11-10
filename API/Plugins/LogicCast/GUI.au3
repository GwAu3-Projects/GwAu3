;~ AutoItSetOption("GUIOnEventMode", 1)	; Opt("GUIOnEventMode", True)

Global Const $INI_PATH 		= @ScriptDir & "\Settings.ini"

#Region Settings



;Fix const u cannot change
Global Const $AUTOIT_GUI_HEADER_SIZE 	= 26	;The thing where title is and minimize button etc. You can change it with tricks etc but not worth caring about it.
Global Const $AUTOIT_GUI_MENUBAR_SIZE 	= 20	;the thing just beneath the header. You can also change it with tricks but its really not worth caring about it.
Global Const $AUTOIT_GUI_EDITBOX_Y_FIX 	= 1		;You need to add +1 on Y-Pos to make it even with other controls...

;Main
Global Const $GUI_WIDTH				= 390
Global Const $GUI_HEIGHT			= 312
Global Const $GUI_FONTSIZE 			= 9			;standard fontsize
Global Const $GUI_BORDERSIZE 		= 8			;just the space needed to be on the left, right, top, bottom GUI
Global Const $GUI_CONTROL_SPACE 	= 4			;just the space needed to be on the left, right, top, bottom GUI
Global Const $GUI_STATUSBAR_WIDTH	= [135, 265, -1]	;110 Width for the 'Run Time: 00:00:00' and -1 to determine the second party has infinite space (end of GUI width)

;Buttons
Global Const $GUI_BUTTON_WIDTH 		= 140		;Make every button the same size (use multiplier for bigger/smaller buttons, so resizing will be easy
Global Const $GUI_BUTTON_HEIGHT 	= 25

;Labels
Global Const $GUI_LABEL_WIDTH 		= 120		;Make every button the same size (use multiplier for bigger/smaller buttons, so resizing will be easy
Global Const $GUI_LABEL_HEIGHT 		= 20

Global Const $GUI_CHECKBOX_WIDTH 	= 110
Global Const $GUI_CHECKBOX_HEIGHT 	= 16

Global $GoodName = ""
#EndRegion

#Region GUI Vars
;Main
Global $GUI = 0									;handle to the main window

;Statusbar
Global $GUI_hStatusBar 							= 0						;Buttom Statusbar for the time preview
Global $GUI_RunCounter 							= 0						;Run counter
Global $GUI_FailCounter 						= 0						;Fail counter

;Menu
Global $GUI_idMenuFile							= 0			;The Main Menu, this cannot handle any events, so we re creating sub menus below
Global $GUI_idMenuFile_idSettings 				= 0			;Settings
Global $GUI_idMenuFile_idModSettings			= 0			;Mod Settings
Global $GUI_idMenuFile_idOpenDir				= 0			;Open Dir
Global $GUI_idMenuFile_idExit					= 0			;Exit

;Buttons
Global $GUI_idButtonStart						= 0
Global $GUI_idButtonStop						= 0
Global $GUI_idButtonResume						= 0
Global $GUI_idButtonStart_Function				= ""	;Sub Function to call onStartPressed
Global $GUI_idButtonStop_Function				= ""	;Sub Function to call onStopPressed
Global $GUI_idButtonResume_Function				= ""	;Sub Function to call onResumePressed

;Group 1: Settings
Global $GUI_idConsole 							= 0
Global $GUI_GroupSettings 						= 0
Global $GUI_GroupSettings_CheckRender			= 0
Global $Rendering								= 1
Global $GUI_GroupSettings_CheckSkills			= 0
Global $GUI_GroupSettings_CheckHM				= 0
Global $GUI_GroupSettings_CheckConsets			= 0
Global $GUI_GroupSettings_CheckScrolls			= 0
Global $GUI_GroupSettings_CheckStones			= 0
Global $GUI_GroupSettings_CheckChests			= 0
Global $GUI_GroupSettings_CheckRareSkins		= 0
Global $GUI_GroupSettings_CheckSell				= 0

;Group 2: General Statistics
Global $GUI_GroupGeneralStats = 0
Global $GUI_GroupGeneralStats_lblDeldrimor 		= 0
Global $GUI_GroupGeneralStats_lblAsura			= 0
Global $GUI_GroupGeneralStats_lblLockpicks 		= 0
Global $GUI_GroupGeneralStats_lblWipes 			= 0
Global $GUI_GroupGeneralStats_lblDeldrimorVal 	= 0
Global $GUI_GroupGeneralStats_lblAsuraVal 		= 0
Global $GUI_GroupGeneralStats_lblLockpicksVal 	= 0
Global $GUI_GroupGeneralStats_lblWipesVal		= 0
Global $GUI_GroupGeneralStats_lblBestRunTimeVal	= 0
Global $GUI_GroupGeneralStats_lblAvgRunTimeVal	= 0


Global $GUI_GroupDropStatistics = 0
Global $GUI_GroupDropStatistics_lblRareSkins 	= 0
Global $GUI_GroupDropStatistics_lblGolds 		= 0
Global $GUI_GroupDropStatistics_lblLockpicks 	= 0
Global $GUI_GroupDropStatistics_lblChests 		= 0
Global $GUI_GroupDropStatistics_lblDyes 		= 0
Global $GUI_GroupDropStatistics_lblTomes 		= 0
Global $GUI_GroupDropStatistics_lblRareSkinsVal	= 0
Global $GUI_GroupDropStatistics_lblGoldsVal 	= 0
Global $GUI_GroupDropStatistics_lblLockpicksVal	= 0
Global $GUI_GroupDropStatistics_lblChestsVal 	= 0
Global $GUI_GroupDropStatistics_lblDyesVal 		= 0
Global $GUI_GroupDropStatistics_lblTomesVal	= 0
#EndRegion GUI Vars

#Region String Extensions
Func String_GetTimeStamp($ShowSeconds)
	Local $TimeStamp = "[" & @HOUR & ":" & @MIN
	If $ShowSeconds Then $TimeStamp &= ":" & @SEC
	$TimeStamp &= "]"
	Return $TimeStamp
EndFunc
#EndRegion

#Region GUI Helpfunctions
;Gets the information of a control related to the main GUI
;$SizeBuffer[0] = X Position
;$SizeBuffer[1] = Y Position
;$SizeBuffer[2] = Width
;$SizeBuffer[3] = Height
Func GUI_GetCtrlInfo($ControlID, $GuiHasMenu = ($GUI_idMenuFile <> 0), $GUI = $GUI)
	If $GUI = 0 Then Return SetError(1, 0)

	Local $SizeBuffer 	= WinGetPos(GUICtrlGetHandle($ControlID))
	Local $SizeGUI 		= WinGetPos($GUI)

	;I have to subract the GUI X Coords else it would get the total coords of the entire screen
	$SizeBuffer[0] -= $SizeGUI[0]
	$SizeBuffer[1] -= $SizeGUI[1]

	If GUI_HasStyle($WS_CAPTION) Then $SizeBuffer[1] -= $AUTOIT_GUI_HEADER_SIZE
	If $GuiHasMenu Then	$SizeBuffer[1] -= $AUTOIT_GUI_MENUBAR_SIZE

	Return $SizeBuffer
EndFunc

Func GUI_HasStyle($Style, $GUI = $GUI)
	Return BitAND(GUIGetStyle($GUI)[0], $Style) = $Style
EndFunc

Func GUI_IsChecked($ControlID)
	Return BitAND(GUICtrlRead($ControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc
#EndRegion GUI Helpfunctions

#Region Creation
#cs
#Region Set Uskin
_Uskin_LoadDLL()
_USkin_Init(@ScriptDir & "\Skins\Royale.msstyles") ; <-- Put here your skin...
OnAutoItExitRegister(_USkin_Exit)
#EndRegion Set Uskin
#ce

Func GUI_Create()
	;Locals
	Local $temp1[4]
	Local $temp2[4]

	local $tempCtrlTop = 0
	Global $Title = $BOTNAME & " - v" & $VERSION & " - By " & $AUTHORS[0]

	;Main
	$GUI = GUICreate($Title, $GUI_WIDTH, $GUI_HEIGHT)
	GUISetOnEvent($GUI_EVENT_CLOSE, "GUI_onExit")
	GUISetFont($GUI_FONTSIZE)
	GUISetBkColor(0xAAAAAA)

	;Menu
	$GUI_idMenuFile = GUICtrlCreateMenu("File")
	$GUI_idMenuFile_idSettings 	= GUICtrlCreateMenuItem("Settings", $GUI_idMenuFile)
	$GUI_idMenuFile_idModSettings 	= GUICtrlCreateMenuItem("Mod Settings", $GUI_idMenuFile)
	$GUI_idMenuFile_idOpenDir 	= GUICtrlCreateMenuItem("Open Dir", $GUI_idMenuFile)
	$GUI_idMenuFile_idExit 		= GUICtrlCreateMenuItem("Exit"    , $GUI_idMenuFile)
	GUICtrlSetOnEvent($GUI_idMenuFile_idSettings, "GUI_MenuCallback")
	GUICtrlSetOnEvent($GUI_idMenuFile_idModSettings, "GUI_MenuCallback")
	GUICtrlSetOnEvent($GUI_idMenuFile_idOpenDir, "GUI_MenuCallback")
	GUICtrlSetOnEvent($GUI_idMenuFile_idExit, "GUI_MenuCallback")

	#Region Gui Grid Row 1

	;Buttons
	$GUI_idButtonStart 	= GUICtrlCreateButton("Start" , $GUI_BORDERSIZE, $GUI_BORDERSIZE, $GUI_BUTTON_WIDTH, $GUI_BUTTON_HEIGHT, -1, $WS_EX_LAYOUTRTL)
	$GUI_idButtonStop 	= GUICtrlCreateButton("Stop"  , $GUI_BORDERSIZE, $GUI_BORDERSIZE, $GUI_BUTTON_WIDTH, $GUI_BUTTON_HEIGHT, -1, $WS_EX_LAYOUTRTL)
	$GUI_idButtonResume 	= GUICtrlCreateButton("Resume", $GUI_BORDERSIZE, $GUI_BORDERSIZE, $GUI_BUTTON_WIDTH, $GUI_BUTTON_HEIGHT, -1, $WS_EX_LAYOUTRTL)
	GUICtrlSetOnEvent($GUI_idButtonStart, "GUI_ButtonCallback")
	GUICtrlSetOnEvent($GUI_idButtonStop, "GUI_ButtonCallback")
	GUICtrlSetOnEvent($GUI_idButtonResume, "GUI_ButtonCallback")
	GUI_HideButton($GUI_idButtonStop  , True)
	GUI_HideButton($GUI_idButtonResume, True)


	#EndRegion Gui Grid Row 1

	#Region Gui Grid Row 2
	;Group 1: Fast Settings
	$tempCtrlTop = $GUI_CHECKBOX_HEIGHT + $GUI_CONTROL_SPACE

	$temp1 = GUI_GetCtrlInfo($GUI_idButtonStart)
	$GUI_GroupSettings = GUICtrlCreateGroup("Settings", $GUI_BORDERSIZE		, $temp1[1] + $temp1[3] + $GUI_CONTROL_SPACE, $GUI_LABEL_WIDTH + $GUI_BORDERSIZE * 2,  20 + $tempCtrlTop * 9, -1, $WS_EX_TRANSPARENT)
	$GUI_GroupSettings_CheckRender  	= GUICtrlCreateCheckbox("Stop Rendering"	, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 0, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	$GUI_GroupSettings_CheckSkills   	= GUICtrlCreateCheckbox("Load Skills"		, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 1, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	$GUI_GroupSettings_CheckHM			= GUICtrlCreateCheckbox("Hard Mode"			, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 2, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	$GUI_GroupSettings_CheckConsets		= GUICtrlCreateCheckbox("Consets"			, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 3, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	$GUI_GroupSettings_CheckScrolls 	= GUICtrlCreateCheckbox("Scrolls"			, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 4, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	$GUI_GroupSettings_CheckStones  	= GUICtrlCreateCheckbox("Stones"		 	, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 5, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	$GUI_GroupSettings_CheckChests  	= GUICtrlCreateCheckbox("Open Chests"		, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 6, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	$GUI_GroupSettings_CheckRareSkins	= GUICtrlCreateCheckbox("Store Rare Skins"	, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 7, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	$GUI_GroupSettings_CheckSell    	= GUICtrlCreateCheckbox("Auto-Sell"	  		, $GUI_BORDERSIZE * 2, $temp1[1] + $temp1[3] + 20 + $tempCtrlTop * 8, $GUI_CHECKBOX_WIDTH, $GUI_CHECKBOX_HEIGHT)
	GUICtrlCreateGroup("", -99, -99, 1, 1)	;Closes a Group

	GUICtrlSetOnEvent($GUI_GroupSettings_CheckRender, "ToggleRendering")
	GUICtrlSetOnEvent($GUI_GroupSettings_CheckSkills, "LoadBestSkillTemplate")
	GUICtrlSetOnEvent($GUI_GroupSettings_CheckSell, "IdentifyBags")


	$temp2 = GUI_GetCtrlInfo($GUI_GroupSettings)

	$GUI_idConsole = GUICtrlCreateEdit("", _
		$GUI_BORDERSIZE + $GUI_CONTROL_SPACE + ($temp1[2] > $temp2[2] ? $temp1[2] : $temp2[2]), _
		$temp1[1] + $AUTOIT_GUI_EDITBOX_Y_FIX, _
		$GUI_WIDTH - $GUI_BORDERSIZE * 2 - $GUI_CONTROL_SPACE - ($temp1[2] > $temp2[2] ? $temp1[2] : $temp2[2]), _
		$temp1[3] + $temp2[3] + $AUTOIT_GUI_EDITBOX_Y_FIX, BitOR($ES_MULTILINE, $ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
	GUICtrlSetBkColor($GUI_idConsole, 0x000000)
	GUICtrlSetColor($GUI_idConsole, 0xFFFFFF)
	#EndRegion Gui GridRow 2

	#Region Gui Grid Row 3
	$tempCtrlTop = $GUI_LABEL_HEIGHT

	;Group 2: General Statistics
	$GUI_GroupGeneralStats = GUICtrlCreateGroup("General Statistics", $GUI_BORDERSIZE, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE, $GUI_LABEL_WIDTH * 1.45 + $GUI_BORDERSIZE * 2, 20 + $tempCtrlTop * 6 + $GUI_CONTROL_SPACE)
    GUICtrlSetFont($GUI_GroupGeneralStats, 9, 800, 0, "Arial")

	$GUI_GroupGeneralStats_lblDeldrimor 	= GUICtrlCreateLabel("Deldrimor:"		, $GUI_BORDERSIZE * 2, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 0, $GUI_LABEL_WIDTH, $GUI_LABEL_HEIGHT)
	$GUI_GroupGeneralStats_lblAsura			= GUICtrlCreateLabel("Asura Points:"	, $GUI_BORDERSIZE * 2, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 1, $GUI_LABEL_WIDTH * 0.75, $GUI_LABEL_HEIGHT)
	$GUI_GroupGeneralStats_lblLockpicks		= GUICtrlCreateLabel("Lockpicks:"		, $GUI_BORDERSIZE * 2, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 2, $GUI_LABEL_WIDTH * 0.75, $GUI_LABEL_HEIGHT)
	$GUI_GroupGeneralStats_lblWipes	 		= GUICtrlCreateLabel("Wipes:"			, $GUI_BORDERSIZE * 2, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 3, $GUI_LABEL_WIDTH * 0.75, $GUI_LABEL_HEIGHT)
	$GUI_GroupGeneralStats_lblBestRunTime	= GUICtrlCreateLabel("Best Run Time:"	, $GUI_BORDERSIZE * 2, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 4, $GUI_LABEL_WIDTH * 0.75, $GUI_LABEL_HEIGHT)
	$GUI_GroupGeneralStats_lblAvgRunTime	= GUICtrlCreateLabel("Avg Run Time:"	, $GUI_BORDERSIZE * 2, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 5, $GUI_LABEL_WIDTH * 0.75, $GUI_LABEL_HEIGHT)

	$GUI_GroupGeneralStats_lblDeldrimorVal 	= GUICtrlCreateLabel("0", 			$GUI_BORDERSIZE * 2 + $GUI_LABEL_WIDTH * 0.75, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 0, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupGeneralStats_lblAsuraVal 		= GUICtrlCreateLabel("0", 			$GUI_BORDERSIZE * 2 + $GUI_LABEL_WIDTH * 0.75, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 1, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupGeneralStats_lblLockpicksVal 	= GUICtrlCreateLabel("0", 			$GUI_BORDERSIZE * 2 + $GUI_LABEL_WIDTH * 0.75, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 2, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupGeneralStats_lblWipesVal 		= GUICtrlCreateLabel("0", 			$GUI_BORDERSIZE * 2 + $GUI_LABEL_WIDTH * 0.75, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 3, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupGeneralStats_lblBestRunTimeVal= GUICtrlCreateLabel("00:00:00", 	$GUI_BORDERSIZE * 2 + $GUI_LABEL_WIDTH * 0.75, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 4, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupGeneralStats_lblAvgRunTimeVal = GUICtrlCreateLabel("00:00:00", 	$GUI_BORDERSIZE * 2 + $GUI_LABEL_WIDTH * 0.75, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE + 20 + $tempCtrlTop * 5, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	;Group 3: Drop Statistics
	$temp1 = GUI_GetCtrlInfo($GUI_GroupGeneralStats)
	$GUI_GroupDropStatistics = GUICtrlCreateGroup("Drop Statistics", $temp1[0] + $temp1[2] + $GUI_CONTROL_SPACE, $temp2[1] + $temp2[3] + $GUI_CONTROL_SPACE, $GUI_LABEL_WIDTH * 1.45 + $GUI_BORDERSIZE * 2, 20 + $tempCtrlTop * 6 + $GUI_CONTROL_SPACE)
	GUICtrlSetFont($GUI_GroupDropStatistics, 9, 800, 0, "Arial")
	$temp1 = GUI_GetCtrlInfo($GUI_GroupDropStatistics)
	$GUI_GroupDropStatistics_lblRareSkins 		= GUICtrlCreateLabel("Rare Skins:"		, $temp1[0] + $GUI_CONTROL_SPACE, $temp1[1] + 20 + $tempCtrlTop * 0, $GUI_LABEL_WIDTH , $GUI_LABEL_HEIGHT)
	$GUI_GroupDropStatistics_lblGolds 			= GUICtrlCreateLabel("Gold Items:"		, $temp1[0] + $GUI_CONTROL_SPACE, $temp1[1] + 20 + $tempCtrlTop * 1, $GUI_LABEL_WIDTH , $GUI_LABEL_HEIGHT)
	$GUI_GroupDropStatistics_lblLockpicks 		= GUICtrlCreateLabel("Lockpicks:"		, $temp1[0] + $GUI_CONTROL_SPACE, $temp1[1] + 20 + $tempCtrlTop * 2, $GUI_LABEL_WIDTH , $GUI_LABEL_HEIGHT)
	$GUI_GroupDropStatistics_lblChests 			= GUICtrlCreateLabel("Chests Opened:"	, $temp1[0] + $GUI_CONTROL_SPACE, $temp1[1] + 20 + $tempCtrlTop * 3, $GUI_LABEL_WIDTH , $GUI_LABEL_HEIGHT)
	$GUI_GroupDropStatistics_lblDyes 			= GUICtrlCreateLabel("Black Dye:"		, $temp1[0] + $GUI_CONTROL_SPACE, $temp1[1] + 20 + $tempCtrlTop * 4, $GUI_LABEL_WIDTH , $GUI_LABEL_HEIGHT)
	$GUI_GroupDropStatistics_lblTomes 			= GUICtrlCreateLabel("Tomes:"			, $temp1[0] + $GUI_CONTROL_SPACE, $temp1[1] + 20 + $tempCtrlTop * 5, $GUI_LABEL_WIDTH , $GUI_LABEL_HEIGHT)
	$GUI_GroupDropStatistics_lblRareSkinsVal 	= GUICtrlCreateLabel("0", $temp1[0] + $GUI_CONTROL_SPACE + $GUI_LABEL_WIDTH * 0.75, $temp1[1] + 20 + $tempCtrlTop * 0, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupDropStatistics_lblGoldsVal 		= GUICtrlCreateLabel("0", $temp1[0] + $GUI_CONTROL_SPACE + $GUI_LABEL_WIDTH * 0.75, $temp1[1] + 20 + $tempCtrlTop * 1, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupDropStatistics_lblLockpicksVal	= GUICtrlCreateLabel("0", $temp1[0] + $GUI_CONTROL_SPACE + $GUI_LABEL_WIDTH * 0.75, $temp1[1] + 20 + $tempCtrlTop * 2, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupDropStatistics_lblChestsVal 		= GUICtrlCreateLabel("0", $temp1[0] + $GUI_CONTROL_SPACE + $GUI_LABEL_WIDTH * 0.75, $temp1[1] + 20 + $tempCtrlTop * 3, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupDropStatistics_lblDyesVal 		= GUICtrlCreateLabel("0", $temp1[0] + $GUI_CONTROL_SPACE + $GUI_LABEL_WIDTH * 0.75, $temp1[1] + 20 + $tempCtrlTop * 4, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	$GUI_GroupDropStatistics_lblTomesVal		= GUICtrlCreateLabel("0", $temp1[0] + $GUI_CONTROL_SPACE + $GUI_LABEL_WIDTH * 0.75, $temp1[1] + 20 + $tempCtrlTop * 5, $GUI_LABEL_WIDTH * 0.5, $GUI_LABEL_HEIGHT, $SS_RIGHT)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	#EndRegion Gui GridRow 2

	$temp1 = GUI_GetCtrlInfo($GUI_GroupDropStatistics, False)
	$temp2 = WinGetPos($GUI)
	WinMove($GUI, "", $temp2[0], $temp2[1], $temp2[2], $temp1[1] + $temp1[3] + $GUI_BORDERSIZE + $AUTOIT_GUI_HEADER_SIZE + 25)

    ;StatusBar
    $GUI_hStatusBar = _GUICtrlStatusBar_Create($GUI)
    _GUICtrlStatusBar_SetParts($GUI_hStatusBar, $GUI_STATUSBAR_WIDTH)
    _GUICtrlStatusBar_SetText($GUI_hStatusBar, "Runs: 0 (0% failed)", 0)
    _GUICtrlStatusBar_SetText($GUI_hStatusBar, "Run Time: 00:00:00", 1)
    _GUICtrlStatusBar_SetText($GUI_hStatusBar, "Total Time: 00:00:00", 2)


	#Region INI
	GUI_IniCreate()
	If Not GUI_IniIsComplete() Then
		FileDelete($INI_PATH)
		Out("INI file incompleted. Recreating it.")
		GUI_IniCreate()
	EndIf

	GUICtrlSetState($GUI_GroupSettings_CheckHM, (IniRead($INI_PATH, "Settings", "Hard Mode", True)) ? $GUI_CHECKED : 0)
	GUICtrlSetState($GUI_GroupSettings_CheckConsets, (IniRead($INI_PATH, "Settings", "Consets", True)) ? $GUI_UNCHECKED : 0)
	GUICtrlSetState($GUI_GroupSettings_CheckScrolls, (IniRead($INI_PATH, "Settings", "Scrolls", True)) ? $GUI_CHECKED : 0)
	GUICtrlSetState($GUI_GroupSettings_CheckStones, (IniRead($INI_PATH, "Settings", "Stones", True)) ? $GUI_CHECKED : 0)
	GUICtrlSetState($GUI_GroupSettings_CheckChests, (IniRead($INI_PATH, "Settings", "OpenChests", True)) ? $GUI_UNCHECKED : 0)
	GUICtrlSetState($GUI_GroupSettings_CheckRareSkins, (IniRead($INI_PATH, "Settings", "StoreRareSkins", True)) ? $GUI_CHECKED : 0)
	GUICtrlSetState($GUI_GroupSettings_CheckSell, (IniRead($INI_PATH, "Settings", "AutoSell", True)) ? $GUI_CHECKED : 0)
	#EndRegion INI

	GUISetState(@SW_SHOW)
EndFunc
#EndRegion Creation

#Region Events
Func GUI_onExit()
	Local $AgentName = MemoryRead($mCharname, 'wchar[30]')
	WinSetTitle($mGWWindowHandle, '', 'Guild Wars')
	WinSetState(GetWindowHandle(), "", @SW_SHOW)
	Exit
EndFunc

Func GUI_ButtonCallback()
	If Not @GUI_CtrlHandle = $GUI Then Return ;If u run multiple GUIs, sort out the GUI u dont need, to reduce unnecessary cpu usage.
	Local $idButton = @GUI_CtrlId
	Switch($idButton)
		Case $GUI_idButtonStart
			GUI_HideButton($GUI_idButtonStart, True)
			GUI_HideButton($GUI_idButtonStop, False)
			GUI_HideButton($GUI_idButtonResume, True)
			Call($GUI_idButtonStart_Function)
		Case $GUI_idButtonStop
			GUI_HideButton($GUI_idButtonStop, True)
			GUI_HideButton($GUI_idButtonResume, False)
			Call($GUI_idButtonStop_Function)
		Case $GUI_idButtonResume
			GUI_HideButton($GUI_idButtonStop, False)
			GUI_HideButton($GUI_idButtonResume, True)
			Call($GUI_idButtonResume_Function)
	EndSwitch
EndFunc

Func GUI_MenuCallback() ;Checking here for the GUI does not work. Since every GUI can only have one Menu.
	Local $idMenuItem = @GUI_CtrlId
	Switch($idMenuItem)
		Case $GUI_idMenuFile_idSettings
			Run("notepad.exe " & $INI_PATH)
		Case $GUI_idMenuFile_idModSettings
			ModSelection()
	    Case $GUI_idMenuFile_idOpenDir
			Run("Explorer.exe " & @ScriptDir)
		Case $GUI_idMenuFile_idExit
			Exit
	EndSwitch
EndFunc
#EndRegion

#Region Getters
;Group 1: Checkbox
Func GUI_IsRenderChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckRender)
EndFunc

Func GUI_IsLoadSkillsChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckSkills)
EndFunc

Func GUI_IsHMChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckHM)
EndFunc

Func GUI_IsConsetsChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckConsets)
EndFunc

Func GUI_IsScrollsChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckScrolls)
EndFunc

Func GUI_IsStonesChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckStones)
EndFunc

Func GUI_IsChestChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckChests)
EndFunc

Func GUI_IsRareSkinsChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckRareSkins)
EndFunc

Func GUI_IsSellChecked()
	Return GUI_IsChecked($GUI_GroupSettings_CheckSell)
EndFunc

;Group 2: General
Func GUI_GetDeldrimor()
	Return GUICtrlRead($GUI_GroupGeneralStats_lblDeldrimorVal)
EndFunc

Func GUI_GetAsura()
	Return GUICtrlRead($GUI_GroupGeneralStats_lblAsuraVal)
EndFunc

Func GUI_GetLockpicks()
	Return GUICtrlRead($GUI_GroupGeneralStats_lblLockpicksVal)
EndFunc

Func GUI_GetWipes()
	Return GUICtrlRead($GUI_GroupGeneralStats_lblWipesVal)
EndFunc

Func GUI_GetBestRunTime()
	Return GUICtrlRead($GUI_GroupGeneralStats_lblBestRunTimeVal)
EndFunc

;Group 3: Drops
Func GUI_GetRareSkins()
	Return GUICtrlRead($GUI_GroupDropStatistics_lblRareSkinsVal)
EndFunc

Func GUI_GetGolds()
	Return GUICtrlRead($GUI_GroupDropStatistics_lblGoldsVal)
EndFunc

Func GUI_GetDroppedLockpicks()
	Return GUICtrlRead($GUI_GroupDropStatistics_lblLockpicksVal)
EndFunc

Func GUI_GetChestsOpened()
	Return GUICtrlRead($GUI_GroupDropStatistics_lblChestsVal)
EndFunc

Func GUI_GetBlackDyes()
	Return GUICtrlRead($GUI_GroupDropStatistics_lblDyesVal)
EndFunc

Func GUI_GetTomes()
	Return GUICtrlRead($GUI_GroupDropStatistics_lblTomesVal)
EndFunc

Func GUI_GetConsoleText()
	Global $GUI_idConsole
	Return GUICtrlRead($GUI_idConsole)
EndFunc

#EndRegion Getters

#Region Commands
Func GUI_SetOnStartFunc($NewFunc = "")
	$GUI_idButtonStart_Function = $NewFunc
EndFunc

Func GUI_SetOnStopFunc($NewFunc = "")
	$GUI_idButtonStop_Function = $NewFunc
EndFunc

Func GUI_SetOnResumeFunc($NewFunc = "")
	$GUI_idButtonResume_Function = $NewFunc
EndFunc

Func GUI_HideButton($ButtonID, $Hide)
	GUICtrlSetState($ButtonID, $Hide ? $GUI_HIDE : $GUI_SHOW)		;Hiding
	GUICtrlSetState($ButtonID, $Hide ? $GUI_DISABLE : $GUI_ENABLE)	;Makes it unable to press it, or let it be pressed
EndFunc

;Group 2: General
Func GUI_SetDeldrimor($Value)
	Return GUICtrlSetData($GUI_GroupGeneralStats_lblDeldrimorVal, $Value)
EndFunc

Func GUI_SetAsura($Value)
	Return GUICtrlSetData($GUI_GroupGeneralStats_lblAsuraVal, $Value)
EndFunc

Func GUI_SetLockpicks($Value)
  	Return GUICtrlSetData($GUI_GroupGeneralStats_lblLockpicksVal, $Value)
EndFunc

Func GUI_SetWipes($Value)
	Return GUICtrlSetData($GUI_GroupGeneralStats_lblWipesVal, $Value)
 EndFunc

;Group 3: Drops
Func GUI_SetRareSkins($Value)
	Return GUICtrlSetData($GUI_GroupDropStatistics_lblRareSkinsVal, $Value)
 EndFunc

Func GUI_SetGolds($Value)
	Return GUICtrlSetData($GUI_GroupDropStatistics_lblGoldsVal, $Value)
EndFunc

Func GUI_SetDroppedLockpicks($Value)
	Return GUICtrlSetData($GUI_GroupDropStatistics_lblLockpicksVal, $Value)
EndFunc

Func GUI_SetChestsOpened($Value)
	Return GUICtrlSetData($GUI_GroupDropStatistics_lblChestsVal, $Value)
EndFunc

Func GUI_SetBlackDyes($Value)
	Return GUICtrlSetData($GUI_GroupDropStatistics_lblDyesVal, $Value)
EndFunc

Func GUI_SetTomes($Value)
	Return GUICtrlSetData($GUI_GroupDropStatistics_lblTomesVal, $Value)
EndFunc


;Console
Func GUI_SetRunCounter($Value = -1)
    If $Value = -1 Then
	Out("Run Count: " & $GUI_RunCounter & "Instance time: " & GetInstanceUpTime())
        If $GUI_RunCounter >= 0 And GetInstanceUpTime() < 15000 Then $GUI_RunCounter += 1
    Else
        $GUI_RunCounter = $Value
    EndIf
    _GUICtrlStatusBar_SetText($GUI_hStatusBar, "Runs: " & $GUI_RunCounter & " (" & Round($GUI_FailCounter/$GUI_RunCounter * 100 ,2) & "% failed)", 0)
EndFunc

Func GUI_SetFailCounter($Value = -1)
    If $Value = -1 Then
        $GUI_FailCounter += 1
    Else
        $GUI_FailCounter += 1 = $Value
    EndIf
    _GUICtrlStatusBar_SetText($GUI_hStatusBar, "Runs: " & $GUI_RunCounter & " (" & Round($GUI_FailCounter/$GUI_RunCounter * 100 ,2) & "% failed)", 0)
EndFunc

Func GUI_Print($Text, $TimeStamp = True, $ShowSeconds = False)
	If $TimeStamp Then $Text = String_GetTimeStamp($ShowSeconds) & " " & $Text
	GUICtrlSetData($GUI_idConsole, GUI_GetConsoleText() & $Text)
	_GUICtrlEdit_Scroll($GUI_idConsole, $SB_SCROLLCARET)
EndFunc

Func Out($Text, $TimeStamp = True, $ShowSeconds = False)
	Local $Out = ""
	If GUI_GetConsoleText() <> "" Then $Out = @CRLF
	If $TimeStamp Then $Out &= String_GetTimeStamp($ShowSeconds) & " "
	GUICtrlSetData($GUI_idConsole, GUI_GetConsoleText() & $Out & $Text & "")
	_GUICtrlEdit_Scroll($GUI_idConsole, $SB_SCROLLCARET)
EndFunc

Func GUI_SetRunTime($iTicks)
	Local $iHours, $iMins, $iSecs
	Local $TimeStamp = ""
	_TicksToTime($iTicks, $iHours, $iMins, $iSecs)
	If $iHours < 10 Then $TimeStamp = "0"
	$TimeStamp &= $iHours & ":"
	If $iMins < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iMins & ":"
	If $iSecs < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iSecs
	_GUICtrlStatusBar_SetText($GUI_hStatusBar, "Run Time: " & $TimeStamp, 1)
EndFunc

Func GUI_SetBestRunTime($iTicks)
	Local $iHours, $iMins, $iSecs
	Local $TimeStamp = ""
	_TicksToTime($iTicks, $iHours, $iMins, $iSecs)
	If $iHours < 10 Then $TimeStamp = "0"
	$TimeStamp &= $iHours & ":"
	If $iMins < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iMins & ":"
	If $iSecs < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iSecs
	GUICtrlSetData($GUI_GroupGeneralStats_lblBestRunTimeVal, $TimeStamp)
EndFunc

Func GUI_SetTotalTime($iTicks)
	Local $iHours, $iMins, $iSecs
	Local $TimeStamp = ""
	_TicksToTime($iTicks, $iHours, $iMins, $iSecs)
	If $iHours < 10 Then $TimeStamp = "0"
	$TimeStamp &= $iHours & ":"
	If $iMins < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iMins & ":"
	If $iSecs < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iSecs
	_GUICtrlStatusBar_SetText($GUI_hStatusBar, "Total Time: " & $TimeStamp, 2)
 EndFunc

Func GUI_SetAvgRunTime($TimeStamp)
 	GUICtrlSetData($GUI_GroupGeneralStats_lblAvgRunTimeVal, $TimeStamp)
 EndFunc

#EndRegion Commands

#Region Ini
Global Const $ValuesToBeSaved = [ _
		[7, ""], _ ;Amount of elements in the array
		["HardMode", True], _
		["Consets", True], _
		["Scrolls", True], _
		["Stones", True], _
		["OpenChests", True], _
		["StoreRareSkins", True], _
		["AutoSell", True] _
]

Func GUI_IniCreate()
	If FileExists($INI_PATH) Then Return False
	Out("Creating INI File.")
	Return IniWriteSection($INI_PATH, "Settings", $ValuesToBeSaved)
EndFunc

Func GUI_IniHasKey($Sections, $Key)
	Local $IniResult = IniReadSection($INI_PATH, "Settings")

	For $i = 1 To $ValuesToBeSaved[0][0]
		If $IniResult[$i][0] = $Key Then Return True
	Next

	Return False
EndFunc

;This func will loop through all the keys in Settings and checks if every value is in the same row
;and has the same value. If one is missing or out of order
Func GUI_IniIsComplete()
	If Not FileExists($INI_PATH) Then Return False

	Local $IniResult = IniReadSection($INI_PATH, "Settings")

	If $IniResult[0][0] <> $ValuesToBeSaved[0][0] Then Return False

	For $key = 1 To $ValuesToBeSaved[0][0]
		If Not GUI_IniHasKey("Settings", $ValuesToBeSaved[$key][0]) Then Return False
	Next

	Return True
EndFunc

#EndRegion Ini File

Func SELECTCHARNAME($acharname)
    Local $array = SCANGW()
    For $j = 0x1 To 10
        For $i = 0x1 To $array[0x0]
            If $acharname == $array[$i] Then Return True
        Next
        Sleep(100)
    Next
    Return False
EndFunc   ;==>SELECTCHARNAME

Func AutoConnecte()
	Local $files, $guinicknamesetting

	$files = IniRead(@ScriptDir & "\_Extra\Autoconnect.ini", "Number of Accounts", "Number", " ")
	For $i = 0 To $files
		$guinicknamesetting = IniRead(@ScriptDir & "\_Extra\Autoconnect.ini", "Worker #" & $i, "Account Char Name", " ")
		If SELECTCHARNAME($guinicknamesetting) = False Then ContinueLoop
		If WinExists("Guild Wars - " & $guinicknamesetting) Then ContinueLoop
		$GoodName = $guinicknamesetting
	Next
	If $GoodName <> "" Then
		Out("Auto Connecte")
		Initialize($GoodName, True, True, True)
		Return True
	Else
		Out("Fail Auto Connecte")
		Return False
	EndIf
EndFunc