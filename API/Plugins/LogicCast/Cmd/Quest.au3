#include-once
; Quest flow helpers (policy/logging). Module Quest_* / Ui_* for thin Cmd calls.

Func AcceptQuest($a_i_QuestID)
	If Quest_GetQuestInfo($a_i_QuestID, "HasQuest") Then
		Out("AcceptQuest: already in log (LogState=" & Quest_GetQuestInfo($a_i_QuestID, "LogState") & ")")
		Return
	EndIf
	Out("Accepting Quest: " & $a_i_QuestID)
	Local $l_i_Ret = Quest_AcceptQuest($a_i_QuestID)
	Other_PingSleep(100)
	Out("Accepted quest " & $a_i_QuestID & " - Status: " & Quest_GetQuestInfo($a_i_QuestID, "LogState"))
	Return $l_i_Ret
EndFunc

Func CheckQuestStatus($a_i_QuestID)
	Local $l_i_State = Quest_GetQuestInfo($a_i_QuestID, "LogState")
	Return Quest_GetQuestInfo($a_i_QuestID, "IsCompleted") Or $l_i_State = 3 Or $l_i_State = 34 Or $l_i_State = 35 Or $l_i_State = 79
EndFunc

Func CheckForQuest($a_i_Quest, $a_b_AbandonCompleted = False)
	Quest_RequestInfos($a_i_Quest)
	Sleep(200)
	If Not Quest_GetQuestInfo($a_i_Quest, "HasQuest") Then
		Out("Quest is not in our log")
		Return False
	EndIf
	Local $l_i_State = Quest_GetQuestInfo($a_i_Quest, "LogState")
	If Quest_GetQuestInfo($a_i_Quest, "IsCompleted") Or $l_i_State = 3 Or $l_i_State = 34 Or $l_i_State = 35 Or $l_i_State = 79 Then
		Out("Quest already completed, abandoning to secure access to the dungeon")
		Out("LogState = " & $l_i_State)
		If $a_b_AbandonCompleted Then Quest_AbandonQuest($a_i_Quest)
		Return False
	EndIf
	Out("Quest already in our log, activating (LogState=" & $l_i_State & ")")
	Ui_ActiveQuest($a_i_Quest)
	Return True
EndFunc