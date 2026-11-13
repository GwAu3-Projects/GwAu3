#include-once
; Pre-staging UI/NPC interaction helpers (farm orchestration around Modules Ui_/Agent_ Cmd).
;
; Dialog chain design (Logic parity for Froggy → Warmine-style multi-step):
;   TalkToNPC(x, y, dialog1, dialog2=0x81, playerID=0, dialog3=0x84) — up to 3 buttons
;   EnterMission(x, y, dialog1=0x81, dialog2=0x84, playerID=0) — up to 2 buttons
;   TakeQuest(...) — AcceptQuest then optional global $dialog follow-up
; Zero IDs are skipped so scripts can omit a step without sending Dialog(0).

; Thin Logic Dialog / Dialog2 shims → Ui_Dialog (+ optional map wait).
Func Dialog($aDialogID, $NextMapID = 0, $aDeadlock = 1000)
	If $aDialogID = 0 Or $aDialogID = "" Then Return False
	Other_PingSleep(250)
	Ui_Dialog($aDialogID)
	Other_PingSleep(250)
	If $NextMapID <> 0 Then WaitMapLoading($NextMapID, 10000)
	Return True
EndFunc   ;==>Dialog

Func Dialog2($aDialogID, $NextMapID = 0, $aDeadlock = 1000)
	If $aDialogID = 0 Or $aDialogID = "" Then Return False
	Local $lDeadlock = TimerInit()
	Local $lLoad = False
	Other_PingSleep(250)
	Ui_Dialog($aDialogID)
	Other_PingSleep(250)
	Do
		Other_PingSleep(20)
		If Map_GetInstanceInfo("Type") = 2 Then $lLoad = True
	Until TimerDiff($lDeadlock) > $aDeadlock
	If $lLoad Then
		Do
			Other_PingSleep(500)
			Cinematic_ConditionalSkipCinematic()
		Until WaitMapLoading($NextMapID, 10000)
	EndIf
	Return True
EndFunc   ;==>Dialog2

; Send each non-zero dialog ID in order (Logic TalkToNPC / EnterMission body).
Func _Ui_DialogSequence($aDialog1 = 0, $aDialog2 = 0, $aDialog3 = 0)
	If $aDialog1 <> 0 And $aDialog1 <> "" Then Dialog($aDialog1)
	If $aDialog2 <> 0 And $aDialog2 <> "" Then Dialog($aDialog2)
	If $aDialog3 <> 0 And $aDialog3 <> "" Then Dialog($aDialog3)
EndFunc   ;==>_Ui_DialogSequence

; Talk + optional cinematic skip. Prefer Ui_Dialog + Agent_GoToNPCNearXY at call sites.
; Up to 3 dialog IDs — waypoint "Talk To NPC" passes wp[2], $dialog, $questNPC, $dialog3.
Func TalkToNPC($x, $y, $dialog1, $dialog2 = 0x81, $aPlayerID = 0, $dialog3 = 0x84)
	Out("Talk to NPC " & $aPlayerID & " dialogs: " & $dialog1 & ", " & $dialog2 & ", " & $dialog3)
	If Not Agent_GoToNPCNearXY($x, $y, $aPlayerID) Then Return False
	_Ui_DialogSequence($dialog1, $dialog2, $dialog3)
	Local $Timer = TimerInit()
	Do
		Cinematic_SkipCinematic()
		Sleep(200)
	Until Agent_GetAgentInfo(-2, "IsBeingObserved") Or TimerDiff($Timer) > 5000
	Return True
EndFunc   ;==>TalkToNPC

; Enter explorable via NPC dialogs then wait for map load (2-step: wp dialog + global $dialog).
Func EnterMission($x, $y, $dialog1 = 0x81, $dialog2 = 0x84, $aPlayerID = 0, $Loading = True, $MapID = 0)
	Out("EnterMission dialogs: " & $dialog1 & ", " & $dialog2)
	If Not Agent_GoToNPCNearXY($x, $y, $aPlayerID) Then Return False
	_Ui_DialogSequence($dialog1, $dialog2)
	Do
		WaitMapLoading($MapID, 30000)
		Sleep(1000)
	Until Map_GetInstanceInfo("Type") = 1 And Agent_Exists(-2)
	Return True
EndFunc   ;==>EnterMission

; TEMP debug: dump PlayerNumber / Allegiance of current target (manual target Tekk after arrive).
Func Debug_OutCurrentTargetPlayerNumber($aLabel = "CurrentTarget")
	Local $lID = Agent_GetCurrentTarget()
	If $lID = 0 Then
		Out($aLabel & ": no current target")
		Return 0
	EndIf
	Local $lPtr = Agent_GetAgentPtr($lID)
	Local $lPN = Agent_GetAgentInfo($lPtr, "PlayerNumber")
	Local $lAlleg = Agent_GetAgentInfo($lPtr, "Allegiance")
	Local $lType = Agent_GetAgentInfo($lPtr, "Type")
	Local $lName = Agent_GetAgentInfo($lPtr, "Name")
	Out($aLabel & ": ID=" & $lID & " PlayerNumber=" & $lPN & " Allegiance=" & $lAlleg & " Type=0x" & Hex($lType, 3) & " Name=" & $lName)
	Return $lPN
EndFunc   ;==>Debug_OutCurrentTargetPlayerNumber

Func TakeQuest($x, $y, $aQuestID, $aPlayerID = 0)
	; Logic-main TakeQuest: move → interact → reward if ready → AcceptQuest → Dialog($dialog).
	; CheckForQuest is called from the "Take Quest" waypoint switch (not here).
	Out("Taking Quest " & $aQuestID & " (NPC=" & $aPlayerID & ", dialog=" & $dialog & ")")
	AggroMoveToEX($x, $y, 1350)
	; After arrive: target nearest living at XY (any allegiance — Tekk is often ally=1 once quest is active, not NPC=6).
	Local $lNear = Agent_GetNearestAgentToXY($x, $y)
	If $lNear <> 0 Then
		Agent_ChangeTarget($lNear)
		Other_PingSleep(100)
		Debug_OutCurrentTargetPlayerNumber("TakeQuest nearest-at-XY")
		Out("Lookup PlayerNumber " & $aPlayerID & " => ptr=" & Agent_GetAgentByPlayerNumber($aPlayerID))
	Else
		Out("TakeQuest: no living agent near XY " & $x & "," & $y)
		Debug_OutCurrentTargetPlayerNumber("TakeQuest manual-target?")
	EndIf
	; Prefer PlayerNumber; else talk to whatever we just targeted / nearest at XY (any allegiance).
	If Not Agent_GoToNPCNearXY($x, $y, $aPlayerID) Then
		Out("TakeQuest: PlayerNumber miss — interacting with nearest-at-XY / current target")
		Local $lNpc = Agent_GetCurrentTarget()
		If $lNpc = 0 Then $lNpc = $lNear
		If $lNpc <> 0 Then Agent_GoToNPC($lNpc)
	EndIf
	Out("Quest Status: " & Quest_GetQuestInfo($aQuestID, "LogState") & " HasQuest=" & Quest_GetQuestInfo($aQuestID, "HasQuest"))
	If CheckQuestStatus($aQuestID) Then GetReward($x, $y, $aQuestID, $aPlayerID)
	Other_PingSleep(500)
	AcceptQuest($aQuestID)
	Out("Follow-up dialog: " & $dialog)
	If $dialog <> 0 Then
		Local $lNpc2 = Agent_GetAgentByPlayerNumber($aPlayerID)
		If $lNpc2 = 0 Then $lNpc2 = Agent_GetCurrentTarget()
		If $lNpc2 = 0 Then $lNpc2 = Agent_GetNearestAgentToXY($x, $y)
		If $lNpc2 <> 0 Then Agent_GoNPC($lNpc2)
		Other_PingSleep(200)
		Dialog($dialog)
	EndIf
	Out("TakeQuest done. HasQuest=" & Quest_GetQuestInfo($aQuestID, "HasQuest") & " LogState=" & Quest_GetQuestInfo($aQuestID, "LogState"))
	Return True
EndFunc   ;==>TakeQuest

Func UpdateQuest($x, $y, $aQuestID, $aPlayerID = 0)
	AggroMoveToEX($x, $y, 1350)
	Agent_GoToNPCNearXY($x, $y, $aPlayerID)
	Out("Updating quest: " & $aQuestID)
	Ui_UpdateQuest($aQuestID)
	Out("Updated quest status: " & Quest_GetQuestInfo($aQuestID, "LogState"))
	Other_PingSleep(100)
EndFunc   ;==>UpdateQuest
