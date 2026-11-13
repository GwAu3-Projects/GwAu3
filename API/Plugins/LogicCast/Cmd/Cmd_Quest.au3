#include-once
; Pre-staging Quest Cmd helpers → Modules Quest_* / Ui_*.

Func AcceptQuest($aQuestID)
	; Logic: skip accept packet if quest is already in the log (TakeQuest still fires $dialog).
	If Quest_GetQuestInfo($aQuestID, "HasQuest") Then
		Out("AcceptQuest: already in log (LogState=" & Quest_GetQuestInfo($aQuestID, "LogState") & ")")
		Return
	EndIf
	Out("Accepting Quest: " & $aQuestID)
	Local $lRet = Quest_AcceptQuest($aQuestID)
	Other_PingSleep(100)
	Out("Accepted quest " & $aQuestID & " - Status: " & Quest_GetQuestInfo($aQuestID, "LogState"))
	Return $lRet
EndFunc

Func QuestReward($aQuestID)
	Return Quest_QuestReward($aQuestID)
EndFunc

Func AbandonQuest($aQuestID)
	Out("Abandoning quest: " & $aQuestID)
	Return Quest_AbandonQuest($aQuestID)
EndFunc

Func RequestQuestInformation($aQuestID)
	Return Quest_RequestInfos($aQuestID)
EndFunc

Func SetActiveQuest($aQuestID)
	Return Ui_ActiveQuest($aQuestID)
EndFunc

Func CheckQuestStatus($aQuestID)
	; True when quest is ready for reward / completed in log.
	Local $lState = Quest_GetQuestInfo($aQuestID, "LogState")
	Return Quest_GetQuestInfo($aQuestID, "IsCompleted") Or $lState = 3 Or $lState = 34 Or $lState = 35 Or $lState = 79
EndFunc

; Logic CheckForQuest: refresh log, activate mid-quest, optionally abandon completed.
; LogState 0 = absent, 1 = active/in progress, else completed-ish.
Func CheckForQuest($quest, $abandoncompleted = False)
	RequestQuestInformation($quest)
	Sleep(200)
	If Not Quest_GetQuestInfo($quest, "HasQuest") Then
		Out("Quest is not in our log")
		Return False
	EndIf
	Local $lState = Quest_GetQuestInfo($quest, "LogState")
	If Quest_GetQuestInfo($quest, "IsCompleted") Or $lState = 3 Or $lState = 34 Or $lState = 35 Or $lState = 79 Then
		Out("Quest already completed, abandoning to secure access to the dungeon")
		Out("LogState = " & $lState)
		If $abandoncompleted Then AbandonQuest($quest)
		Return False
	EndIf
	Out("Quest already in our log, activating (LogState=" & $lState & ")")
	SetActiveQuest($quest)
	Return True
EndFunc
