; Archived: SetEvent-free agent poll cast watch (pre-SkillLog / fallback).
; Not included by default. Re-#include and restore $aLastCast globals if needed.
; Replaced by SkillLog_Respond → OnSpell / OnMelee.
;
; Original role: poll living agents for cast pose + Skill ID, dedupe via $aLastCast,
; then OnSpell / OnMelee.

#include-once

Global $aLastCast[0][4] ; [AgentID, SkillID, Timestamp, TargetID]
Global $iLastCastCount = 0

Func UpdateAndDispatchCasts($aRange = 1500)
	If Map_GetInstanceInfo("Type") <> $GC_I_MAP_TYPE_EXPLORABLE Then Return

	Local $iMyID = Agent_GetMyID()
	If $iMyID <> 0 And ESW_IsCastPose($iMyID) Then
		Local $iMySkill = Number(Agent_GetAgentInfo($iMyID, "Skill"))
		If $iMySkill > 0 Then _UpdateAndDispatch_NoteCast($iMyID, $iMySkill, 0)
	EndIf

	Local $aPtr = Agent_GetFilteredAgentArray(4, $GC_I_AGENT_TYPE_LIVING, $GC_I_ALLEGIANCE_ENEMY, $aRange, Agent_GetAgentPtr(-2), 0)
	Local $n, $iAgent, $iSkill
	For $n = 1 To $aPtr[0]
		$iAgent = Number(Agent_GetAgentInfo($aPtr[$n], "ID"))
		If $iAgent = 0 Then ContinueLoop
		If Not ESW_IsCastPose($iAgent) Then ContinueLoop
		$iSkill = Number(Agent_GetAgentInfo($iAgent, "Skill"))
		If $iSkill = 0 Then ContinueLoop
		_UpdateAndDispatch_NoteCast($iAgent, $iSkill, 0)
	Next
EndFunc   ;==>UpdateAndDispatchCasts

Func _UpdateAndDispatch_NoteCast($aCasterID, $aSkillID, $aTargetID = 0)
	Local $j
	For $j = 0 To $iLastCastCount - 1
		If $aLastCast[$j][0] = $aCasterID And $aLastCast[$j][1] = $aSkillID Then
			If TimerDiff($aLastCast[$j][2]) < 3000 Then Return
		EndIf
	Next

	If $iLastCastCount >= 100 Then
		Local $k, $m
		For $k = 0 To 98
			For $m = 0 To 3
				$aLastCast[$k][$m] = $aLastCast[$k + 1][$m]
			Next
		Next
		$iLastCastCount = 99
	EndIf

	ReDim $aLastCast[$iLastCastCount + 1][4]
	$aLastCast[$iLastCastCount][0] = $aCasterID
	$aLastCast[$iLastCastCount][1] = $aSkillID
	$aLastCast[$iLastCastCount][2] = TimerInit()
	$aLastCast[$iLastCastCount][3] = $aTargetID
	$iLastCastCount += 1

	Local $fAct = Skill_GetSkillInfo($aSkillID, "Activation")
	Local $iType = Skill_GetSkillInfo($aSkillID, "SkillType")
	If $iType = $Attack Then
		OnMelee($aCasterID, $aTargetID, $aSkillID, $fAct)
	Else
		OnSpell($aCasterID, $aTargetID, $aSkillID, $fAct)
	EndIf
EndFunc   ;==>_UpdateAndDispatch_NoteCast
