#include "../../../_GwAu3.au3"

Global Const $doLoadLoggedChars = True
Opt("GUIOnEventMode", True)
Opt("GUICloseOnESC", False)
Opt("ExpandVarStrings", 1)

#Region Declarations
Global $BotRunning = False
Global $BotPaused = False
Global $g_b_SkillLogUiLive = False
Global $g_i_SkillLogHitsSeen = 0
Global Const $BotTitle = "SkillLog Respond Example"
$g_bAutoStart = False
$g_s_MainCharName = ""
#EndRegion Declaration

For $i = 1 To $CmdLine[0]
	If $CmdLine[$i] = "-character" And $i < $CmdLine[0] Then
		$g_s_MainCharName = $CmdLine[$i + 1]
		$g_bAutoStart = True
		ExitLoop
	EndIf
Next

#Region ### START Koda GUI section ### Form=
$MainGui = GUICreate($BotTitle, 520, 400, 0, 0, -1, $WS_EX_WINDOWEDGE)
GUISetBkColor(0xEAEAEA, $MainGui)
GUICtrlCreateGroup("Select Your Character", 8, 8, 500, 375)
Global $GUINameCombo
If $doLoadLoggedChars Then
	$GUINameCombo = GUICtrlCreateCombo($g_s_MainCharName, 24, 32, 145, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
	Local $sLogged = Scanner_GetLoggedCharNames()
	If $sLogged <> "" Then GUICtrlSetData($GUINameCombo, "|" & $sLogged)
Else
	$GUINameCombo = GUICtrlCreateInput($g_s_MainCharName, 24, 32, 145, 25)
EndIf
$gOnTopCheckbox = GUICtrlCreateCheckbox("On Top", 180, 31, 60, 24)
GUICtrlSetState($gOnTopCheckbox, $GUI_CHECKED)
GUICtrlSetOnEvent($gOnTopCheckbox, "GuiButtonHandler")
WinSetOnTop($MainGui, "", 1)

$GUIStartButton = GUICtrlCreateButton("Start", 24, 72, 70, 25)
GUICtrlSetOnEvent($GUIStartButton, "GuiButtonHandler")
$GUIRefreshButton = GUICtrlCreateButton("Refresh", 100, 72, 70, 25)
GUICtrlSetOnEvent($GUIRefreshButton, "GuiButtonHandler")
$GUIPauseButton = GUICtrlCreateButton("Pause", 176, 72, 70, 25)
GUICtrlSetOnEvent($GUIPauseButton, "GuiButtonHandler")
$GUISkillLogLive = GUICtrlCreateButton("SkillLog: OFF", 252, 72, 110, 25)
GUICtrlSetOnEvent($GUISkillLogLive, "GuiButtonHandler")
GUICtrlSetState($GUISkillLogLive, $GUI_DISABLE)
$GUIDumpButton = GUICtrlCreateButton("Dump", 368, 72, 55, 25)
GUICtrlSetOnEvent($GUIDumpButton, "GuiButtonHandler")
GUICtrlSetState($GUIDumpButton, $GUI_DISABLE)

$g_h_EditText = GUICtrlCreateEdit("", 16, 108, 480, 255, BitOR($ES_AUTOVSCROLL, $ES_MULTILINE, $WS_VSCROLL, $ES_READONLY))
GUICtrlSetBkColor($g_h_EditText, 0xFFFFFF)
GUICtrlCreateGroup("", -99, -99, 1, 1)
GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

Func SkillLogUi_SetLive($a_b_Live)
	$g_b_SkillLogUiLive = ($a_b_Live = True Or $a_b_Live = 1)
	SkillLog_SetLive($g_b_SkillLogUiLive)
	If $g_b_SkillLogUiLive Then
		GUICtrlSetData($GUISkillLogLive, "SkillLog: ON")
		Out("SkillLog live ON → OnSpell / OnMelee (hits=" & $g_i_SkillLogHits & ")")
	Else
		GUICtrlSetData($GUISkillLogLive, "SkillLog: OFF")
		Out("SkillLog live OFF (detours kept, hits=" & $g_i_SkillLogHits & ")")
	EndIf
EndFunc   ;==>SkillLogUi_SetLive

Func StartBot()
	$g_s_MainCharName = StringStripWS(GUICtrlRead($GUINameCombo), 3)
	If $g_s_MainCharName = "" Then
		If Core_Initialize(ProcessExists("gw.exe"), True) = 0 Then
			MsgBox(0, "Error", "Guild Wars is not running.")
			_Exit()
		EndIf
	Else
		If Core_Initialize($g_s_MainCharName, True) = 0 Then
			MsgBox(0, "Error", "Could not find character '" & $g_s_MainCharName & "'")
			_Exit()
		EndIf
	EndIf
	GUICtrlSetState($GUIStartButton, $GUI_DISABLE)
	GUICtrlSetState($GUIRefreshButton, $GUI_DISABLE)
	GUICtrlSetState($GUINameCombo, $GUI_DISABLE)
	GUICtrlSetState($GUISkillLogLive, $GUI_ENABLE)
	GUICtrlSetState($GUIDumpButton, $GUI_ENABLE)
	WinSetTitle($MainGui, "", Player_GetCharName() & " - SkillLog Respond")
	WinSetOnTop($MainGui, "", 1)
	$BotRunning = True
EndFunc   ;==>StartBot

Func GuiButtonHandler()
	Switch @GUI_CtrlId
		Case $GUIStartButton
			StartBot()
		Case $GUIRefreshButton
			Local $sLogged = Scanner_GetLoggedCharNames()
			GUICtrlSetData($GUINameCombo, "")
			If $sLogged <> "" Then GUICtrlSetData($GUINameCombo, "|" & $sLogged)
		Case $GUIPauseButton
			$BotPaused = Not $BotPaused
			If $BotPaused Then
				GUICtrlSetData($GUIPauseButton, "Resume")
				Out("=== PAUSED (loop idle) ===")
			Else
				GUICtrlSetData($GUIPauseButton, "Pause")
				Out("=== RESUMED ===")
			EndIf
		Case $GUISkillLogLive
			SkillLogUi_SetLive(Not $g_b_SkillLogUiLive)
		Case $GUIDumpButton
			SkillLog_DumpScan()
		Case $gOnTopCheckbox
			WinSetOnTop($MainGui, "", BitAND(GUICtrlRead($gOnTopCheckbox), $GUI_CHECKED) ? 1 : 0)
		Case $GUI_EVENT_CLOSE
			_Exit()
	EndSwitch
EndFunc   ;==>GuiButtonHandler

Out("Exemple_SkillLog_Respond — verbose HITs on; expect HIT lines on casts.")
Core_AutoStart()

While Not $BotRunning
	Sleep(100)
WEnd

; Show every SkillLog activate in the edit box (RuptBot leaves this off).
$g_b_SkillLogVerboseHits = True

CacheSkillBar()
Out("ruptSlots=" & $RuptSlots[0] & " RuptEvent=" & ($RuptEventSystem ? "yes" : "no") & " ProtEvent=" & ($ProtEventSystem ? "yes" : "no"))

; CacheSkillBar arms OnSpell/OnMelee then SetLive(False). Force live like Fight.
If $g_s_SkillActivate = "" Then
	Out("CacheSkillBar did not arm SkillLog — forcing Respond(OnSpell,OnMelee)")
	SkillLog_Respond("OnSpell", "OnMelee")
EndIf
SkillLogUi_SetLive(True)
SkillLog_DumpScan()
Out("Cast anything (you or enemy). You should see HIT #… lines. Dump if silent.")

While True
	Sleep(5)
	If $BotPaused Then ContinueLoop
	If $g_i_SkillLogHits <> $g_i_SkillLogHitsSeen Then
		$g_i_SkillLogHitsSeen = $g_i_SkillLogHits
		; HIT Out already printed; this only confirms the counter moved.
	EndIf
WEnd

Func _Exit()
	SkillLog_Respond()
	Exit
EndFunc   ;==>_Exit
