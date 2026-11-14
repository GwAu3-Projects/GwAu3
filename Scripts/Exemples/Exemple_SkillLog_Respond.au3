#RequireAdmin
; Lean SkillLog test (RuptBot-shaped GUI). Uses LogicCast OnSpell/OnMelee via CacheSkillBar —
; no farm GUI, no external RuptEX. Stock _GwAu3 already pulls SkillLog + LogicCast plugins.
#include "../../API/_GwAu3.au3"

Global Const $doLoadLoggedChars = True
Opt("GUIOnEventMode", True)
Opt("GUICloseOnESC", False)
Opt("ExpandVarStrings", 1)

#Region Declarations
Global $ProcessID = ""
Global $BotRunning = False
Global $Bot_Core_Initialized = False
Global $BotPaused = False
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
$MainGui = GUICreate($BotTitle, 500, 380, 0, 0, -1, $WS_EX_WINDOWEDGE)
GUISetBkColor(0xEAEAEA, $MainGui)
GUICtrlCreateGroup("Select Your Character", 8, 8, 475, 355)
Global $GUINameCombo
If $doLoadLoggedChars Then
	$GUINameCombo = GUICtrlCreateCombo($g_s_MainCharName, 24, 32, 145, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
	Local $sLogged = Scanner_GetLoggedCharNames()
	If $sLogged <> "" Then GUICtrlSetData($GUINameCombo, "|" & $sLogged)
Else
	$GUINameCombo = GUICtrlCreateInput($g_s_MainCharName, 24, 32, 145, 25)
EndIf
$gOnTopCheckbox = GUICtrlCreateCheckbox("On Top", 200, 31, 60, 24)
GUICtrlSetState($gOnTopCheckbox, $GUI_CHECKED)
GUICtrlSetOnEvent($gOnTopCheckbox, "GuiButtonHandler")
WinSetOnTop($MainGui, "", 1)
$GUIStartButton = GUICtrlCreateButton("Start", 24, 72, 75, 25)
GUICtrlSetOnEvent($GUIStartButton, "GuiButtonHandler")
$GUIRefreshButton = GUICtrlCreateButton("Refresh", 110, 72, 75, 25)
GUICtrlSetOnEvent($GUIRefreshButton, "GuiButtonHandler")
$GUIPauseButton = GUICtrlCreateButton("Pause", 200, 72, 75, 25)
GUICtrlSetOnEvent($GUIPauseButton, "GuiButtonHandler")
$g_h_EditText = GUICtrlCreateEdit("", 16, 104, 458, 240, BitOR($ES_AUTOVSCROLL, $ES_MULTILINE, $WS_VSCROLL, $ES_READONLY))
GUICtrlSetBkColor($g_h_EditText, 0xFFFFFF)
GUICtrlCreateGroup("", -99, -99, 1, 1)
GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

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
	WinSetTitle($MainGui, "", Player_GetCharName() & " - SkillLog Respond")
	WinSetOnTop($MainGui, "", 1)
	$BotRunning = True
	$Bot_Core_Initialized = True
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
				SkillLog_SetLive(False)
				Out("=== PAUSED (SkillLog live off) ===")
			Else
				GUICtrlSetData($GUIPauseButton, "Pause")
				SkillLog_SetLive(True)
				Out("=== RESUMED (SkillLog live on) ===")
			EndIf
		Case $gOnTopCheckbox
			WinSetOnTop($MainGui, "", BitAND(GUICtrlRead($gOnTopCheckbox), $GUI_CHECKED) ? 1 : 0)
		Case $GUI_EVENT_CLOSE
			_Exit()
	EndSwitch
EndFunc   ;==>GuiButtonHandler

Out("Exemple_SkillLog_Respond — CacheSkillBar arms OnSpell/OnMelee; loop drains Listen.")
Core_AutoStart()

While Not $BotRunning
	Sleep(100)
WEnd

; CacheSkillBar → SkillLog_Respond("OnSpell","OnMelee") + SetLive(False).
CacheSkillBar()
Out("Skill bar cached")

; Always-on tester (Fight would SetLive True only while fighting).
If $RuptEventSystem Or $ProtEventSystem Then
	SkillLog_SetLive(True)
	Out("SkillLog live on → OnSpell / OnMelee")
	SkillLog_DumpScan()
Else
	Out("No rupt/prot on bar — SkillLog left idle (still armed if CacheSkillBar saw none)")
EndIf

While True
	Sleep(5)
	If $BotPaused Then ContinueLoop
	If Map_GetInstanceInfo("Type") <> $GC_I_MAP_TYPE_EXPLORABLE Then ContinueLoop
	If Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "IsKnocked") Then ContinueLoop

	; OnSpell already Notes + fires landable rupts. Drain late-hit / strip / Shame-Guilt.
	EnemySkillWatch_Poll(1400)
	ListenToSkillsAndCounter(1200)
WEnd

Func _Exit()
	SkillLog_Respond() ; disarm
	Exit
EndFunc   ;==>_Exit
