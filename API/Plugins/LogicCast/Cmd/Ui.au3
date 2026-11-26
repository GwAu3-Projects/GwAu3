#include-once
; UI/NPC interaction helpers (farm orchestration around Modules Ui_/Agent_ Cmd).

; Match Logic Dialog: HEADER_DIALOG_SEND via Game_Dialog (SendPacket), not Ui_Dialog (CtoS enqueue).
; Accept/Reward already use Quest_* → same SendPacket header; follow-up $dialog=1 must match.
Func Dialog($a_i_DialogID, $a_i_NextMapID = 0, $a_i_Deadlock = 1000)
	If $a_i_DialogID = 0 Or $a_i_DialogID = "" Then Return False
	Other_PingSleep(250)
	Game_Dialog($a_i_DialogID)
	Other_PingSleep(250)
	If $a_i_NextMapID <> 0 Then WaitMapLoading($a_i_NextMapID, 10000)
	Return True
EndFunc   ;==>Dialog

Func Dialog2($a_i_DialogID, $a_i_NextMapID = 0, $a_i_Deadlock = 1000)
	If $a_i_DialogID = 0 Or $a_i_DialogID = "" Then Return False
	Local $l_h_Deadlock = TimerInit()
	Local $l_b_Load = False
	Other_PingSleep(250)
	Game_Dialog($a_i_DialogID)
	Other_PingSleep(250)
	Do
		Other_PingSleep(20)
		If Map_GetInstanceInfo("Type") = 2 Then $l_b_Load = True
	Until TimerDiff($l_h_Deadlock) > $a_i_Deadlock
	If $l_b_Load Then
		Do
			Other_PingSleep(500)
			Cinematic_ConditionalSkipCinematic()
		Until WaitMapLoading($a_i_NextMapID, 10000)
	EndIf
	Return True
EndFunc   ;==>Dialog2

Func _Ui_DialogSequence($a_i_Dialog1 = 0, $a_i_Dialog2 = 0, $a_i_Dialog3 = 0)
	If $a_i_Dialog1 <> 0 And $a_i_Dialog1 <> "" Then Dialog($a_i_Dialog1)
	If $a_i_Dialog2 <> 0 And $a_i_Dialog2 <> "" Then Dialog($a_i_Dialog2)
	If $a_i_Dialog3 <> 0 And $a_i_Dialog3 <> "" Then Dialog($a_i_Dialog3)
EndFunc   ;==>_Ui_DialogSequence

Func TalkToNPC($a_f_X, $a_f_Y, $a_i_Dialog1, $a_i_Dialog2 = 0x81, $a_i_PlayerID = 0, $a_i_Dialog3 = 0x84)
	Out("Talk to NPC " & $a_i_PlayerID & " dialogs: " & $a_i_Dialog1 & ", " & $a_i_Dialog2 & ", " & $a_i_Dialog3)
	If Not Agent_GoToNPCNearXY($a_f_X, $a_f_Y, $a_i_PlayerID) Then Return False
	_Ui_DialogSequence($a_i_Dialog1, $a_i_Dialog2, $a_i_Dialog3)
	Local $l_h_Timer = TimerInit()
	Do
		Cinematic_SkipCinematic()
		Sleep(200)
	Until Agent_GetAgentInfo(-2, "IsBeingObserved") Or TimerDiff($l_h_Timer) > 5000
	Return True
EndFunc   ;==>TalkToNPC

Func EnterMission($a_f_X, $a_f_Y, $a_i_Dialog1 = 0x81, $a_i_Dialog2 = 0x84, $a_i_PlayerID = 0, $a_b_Loading = True, $a_i_MapID = 0)
	Out("EnterMission dialogs: " & $a_i_Dialog1 & ", " & $a_i_Dialog2)
	If Not Agent_GoToNPCNearXY($a_f_X, $a_f_Y, $a_i_PlayerID) Then Return False
	_Ui_DialogSequence($a_i_Dialog1, $a_i_Dialog2)
	Do
		WaitMapLoading($a_i_MapID, 30000)
		Sleep(1000)
	Until Map_GetInstanceInfo("Type") = 1 And Agent_Exists(-2)
	Return True
EndFunc   ;==>EnterMission

Func Debug_OutCurrentTargetPlayerNumber($a_s_Label = "CurrentTarget")
	Local $l_i_ID = Agent_GetCurrentTarget()
	If $l_i_ID = 0 Then
		Out($a_s_Label & ": no current target")
		Return 0
	EndIf
	Local $l_h_Ptr = Agent_GetAgentPtr($l_i_ID)
	Local $l_i_PlayerNumber = Agent_GetAgentInfo($l_h_Ptr, "PlayerNumber")
	Local $l_i_Allegiance = Agent_GetAgentInfo($l_h_Ptr, "Allegiance")
	Local $l_i_Type = Agent_GetAgentInfo($l_h_Ptr, "Type")
	Local $l_s_Name = Agent_GetAgentInfo($l_h_Ptr, "Name")
	Out($a_s_Label & ": ID=" & $l_i_ID & " PlayerNumber=" & $l_i_PlayerNumber & " Allegiance=" & $l_i_Allegiance & " Type=0x" & Hex($l_i_Type, 3) & " Name=" & $l_s_Name)
	Return $l_i_PlayerNumber
EndFunc   ;==>Debug_OutCurrentTargetPlayerNumber

; Shared dungeon/NPC quest take for all farms (BDS, Froggy, Dryad, Frostmaw, Sorrow's, …).
; Logic shape: move → exact PlayerNumber NPC → GetReward if completed → AcceptQuest → Dialog($dialog).
; Dialog() = Game_Dialog (HEADER_DIALOG_SEND). Do not call Ui_Dialog / AcceptQuest ad-hoc from bots.
Func TakeQuest($a_f_X, $a_f_Y, $a_i_QuestID, $a_i_PlayerID = 0)
	Out("Taking Quest " & $a_i_QuestID & " (NPC=" & $a_i_PlayerID & ", dialog=" & $dialog & ") map=" & Map_GetMapID())
	AggroMoveToEX($a_f_X, $a_f_Y, 1350)
	; Exact PlayerNumber only — nearest-NPC fallback once accepted on the wrong agent.
	Local $l_h_Npc = 0, $lWait = TimerInit()
	If $a_i_PlayerID <> 0 Then
		Do
			$l_h_Npc = Agent_GetAgentByPlayerNumber($a_i_PlayerID)
			If $l_h_Npc <> 0 Then ExitLoop
			Sleep(250)
		Until TimerDiff($lWait) > 15000
	EndIf
	If $l_h_Npc = 0 Then
		Out("TakeQuest: PlayerNumber " & $a_i_PlayerID & " not found after wait — abort")
		Return False
	EndIf
	Out("TakeQuest: using NPC ptr=" & $l_h_Npc & " PN=" & Agent_GetAgentInfo($l_h_Npc, "PlayerNumber") & " Name=" & Agent_GetAgentInfo($l_h_Npc, "Name"))
	Agent_ChangeTarget($l_h_Npc)
	Other_PingSleep(100)
	Agent_GoToNPC($l_h_Npc)
	Out("Quest Status: " & Quest_GetQuestInfo($a_i_QuestID, "LogState") & " HasQuest=" & Quest_GetQuestInfo($a_i_QuestID, "HasQuest"))
	If CheckQuestStatus($a_i_QuestID) Then GetReward($a_f_X, $a_f_Y, $a_i_QuestID, $a_i_PlayerID)
	Other_PingSleep(500)
	AcceptQuest($a_i_QuestID)
	Out("Follow-up dialog: " & $dialog)
	If $dialog <> 0 Then
		$l_h_Npc = Agent_GetAgentByPlayerNumber($a_i_PlayerID)
		If $l_h_Npc <> 0 Then Agent_GoNPC($l_h_Npc)
		Other_PingSleep(200)
		Dialog($dialog)
	EndIf
	Quest_RequestInfos($a_i_QuestID)
	Other_PingSleep(300)
	Out("TakeQuest done. HasQuest=" & Quest_GetQuestInfo($a_i_QuestID, "HasQuest") & " LogState=" & Quest_GetQuestInfo($a_i_QuestID, "LogState"))
	Return Quest_GetQuestInfo($a_i_QuestID, "HasQuest")
EndFunc   ;==>TakeQuest

Func UpdateQuest($a_f_X, $a_f_Y, $a_i_QuestID, $a_i_PlayerID = 0)
	AggroMoveToEX($a_f_X, $a_f_Y, 1350)
	Agent_GoToNPCNearXY($a_f_X, $a_f_Y, $a_i_PlayerID)
	Out("Updating quest: " & $a_i_QuestID)
	Ui_UpdateQuest($a_i_QuestID)
	Out("Updated quest status: " & Quest_GetQuestInfo($a_i_QuestID, "LogState"))
	Other_PingSleep(100)
EndFunc   ;==>UpdateQuest