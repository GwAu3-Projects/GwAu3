#include-once

;~ Description: Drop a buff with specific skill ID targeting a specific agent
Func Effect_DropBond($a_i_SkillID, $a_i_AgentID = -2, $a_i_TargetID = 0)
    Local $l_i_BondID = Agent_GetAgentBondInfo($a_i_AgentID, $a_i_SkillID, $a_i_TargetID, "BondID")
    If $l_i_BondID = 0 Then Return

    Return Core_SendPacket(0x8, $GC_I_HEADER_BOND_DROP, $l_i_BondID)
EndFunc ;==>DropBuff

;~ Description: Modernized routine to acquire Dwarven reputation buffs/blessings with retries and framework effect checks
Func Effect_GetDwarvenBlessing($x, $y)
	Out("Getting Dwarven Blessing")
	Agent_GoToNPCNearXY($x, $y)
	Other_TolSleep(500)

	For $attempt = 1 To 5
		UI_Dialog(0x84)
		Other_TolSleep(500)
		For $i = 0 To UBound($GC_AI_REP_BUFFS_DWARVEN) - 1
			If Agent_GetAgentEffectInfo(-2, $GC_AI_REP_BUFFS_DWARVEN[$i]) Then Return Out("Dwarven Blessing Received")
		Next
	Next
	Return Out("Unable To Get Dwarven Blessing")
EndFunc   ;==>GetDwarvenBlessing

;~ Description: Modernized routine to acquire Asuran reputation buffs/blessings with retries and framework effect checks
Func Effect_GetAsuranBlessing($x, $y)
	Out("Getting Asuran Blessing")
	Agent_GoToNPCNearXY($x, $y)
	Other_TolSleep(500)

	For $attempt = 1 To 5
		UI_Dialog(0x84)
		Other_TolSleep(500)
		For $i = 0 To UBound($GC_AI_REP_BUFFS_ASURA) - 1
			If Agent_GetAgentEffectInfo(-2, $GC_AI_REP_BUFFS_ASURA[$i]) Then Return Out("Asuran Blessing Received")
		Next
	Next
	Return Out("Unable To Get Asuran Blessing")
EndFunc   ;==>GetAsuranBlessing

;~ Description: Modernized routine to acquire Norn reputation buffs/blessings with retries and framework effect checks
Func Effect_GetNornBlessing($x, $y)
	Out("Getting Norn Blessing")
	Agent_GoToNPCNearXY($x, $y)
	Other_TolSleep(500)

	For $attempt = 1 To 5
		UI_Dialog(0x84)
		Other_TolSleep(500)
		For $i = 0 To UBound($GC_AI_REP_BUFFS_NORN) - 1
			If Agent_GetAgentEffectInfo(-2, $GC_AI_REP_BUFFS_NORN[$i]) Then Return Out("Norn Blessing Received")
		Next
	Next
	Return Out("Unable To Get Norn Blessing")
EndFunc   ;==>GetNornBlessing

;~ Description: Modernized routine to acquire Vanguard reputation buffs/blessings with retries and framework effect checks
Func Effect_GetVanguardBlessing($x, $y)
	Out("Getting Vanguard Blessing")
	Agent_GoToNPCNearXY($x, $y)
	Other_TolSleep(500)

	For $attempt = 1 To 5
		UI_Dialog(0x84)
		Other_TolSleep(500)
		For $i = 0 To UBound($GC_AI_REP_BUFFS_VANGUARD) - 1
			If Agent_GetAgentEffectInfo(-2, $GC_AI_REP_BUFFS_VANGUARD[$i]) Then Return Out("Vanguard Blessing Received")
		Next
	Next
	Return Out("Unable To Get Vanguard Blessing")
EndFunc   ;==>GetVanguardBlessing

;~ Description: Modernized routine to acquire Sunspear reputation buffs/blessings with retries and framework effect checks
Func Effect_GetSunspearsBlessing($x, $y)
	Out("Getting Sunspears Blessing")
	Agent_GoToNPCNearXY($x, $y)
	Other_TolSleep(500)

	For $attempt = 1 To 5
		UI_Dialog(0x84)
		Other_TolSleep(500)
		UI_Dialog(0x85)
		Other_TolSleep(500)
		For $i = 0 To UBound($GC_AI_REP_BUFFS_SUNSPEAR) - 1
			If Agent_GetAgentEffectInfo(-2, $GC_AI_REP_BUFFS_SUNSPEAR[$i]) Then Return Out("Sunspears Blessing Received")
		Next
	Next
	Return Out("Unable To Get Sunspears Blessing")
EndFunc   ;==>GetSunspearsBlessing

;~ Description: Modernized routine to acquire Lightbringer reputation buffs/blessings with retries and framework effect checks
Func Effect_GetLightBringerBlessing($x, $y)
	Out("Getting LightBringer Blessing")
	Agent_GoToNPCNearXY($x, $y)
	Other_TolSleep(500)

	For $attempt = 1 To 5
		UI_Dialog(0x85)
		Other_TolSleep(500)
		For $i = 0 To UBound($GC_AI_REP_BUFFS_LIGHTBRINGER) - 1
			If Agent_GetAgentEffectInfo(-2, $GC_AI_REP_BUFFS_LIGHTBRINGER[$i]) Then Return Out("LightBringer Blessing Received")
		Next
	Next
	Return Out("Unable To Get LightBringer Blessing")
EndFunc   ;==>GetLightBringerBlessing

;~ Description: Modernized routine to acquire Luxons Blessing maintaining exact original dialogue sequence
Func GetLuxonsBlessing($x, $y)
	Out("Getting Luxons Blessing")
	Agent_GoToNPCNearXY($x, $y)
	TolSleep(500)

	Local $timeout = 0
	Do
		UI_Dialog(0x85)
		Other_TolSleep(1000)
		UI_Dialog(0x86)
		Other_TolSleep(1000)

		If Agent_GetAgentEffectInfo(-2, $Shadow_Sanctuary_Luxon) Or Agent_GetAgentEffectInfo(-2, $Blessing_of_the_Luxons) Then
			TolSleep(1000)
		Else
			Agent_GoToNPCNearXY($x, $y)
			Other_TolSleep(500)
			UI_Dialog(0x81)
			Other_TolSleep(1000)
			UI_Dialog(0x2)
			Other_TolSleep(1000)
			UI_Dialog(0x84)
			Other_TolSleep(1000)
			UI_Dialog(0x86)
			Other_TolSleep(1000)
		EndIf
		$timeout += 1
	Until Agent_GetAgentEffectInfo(-2, $Shadow_Sanctuary_Luxon) Or Agent_GetAgentEffectInfo(-2, $Blessing_of_the_Luxons) Or $timeout >= 10

	Return Out("Luxons Blessing Acquired")
EndFunc   ;==>GetLuxonsBlessing

;~ Description: Modernized routine to acquire Kurzicks Blessing maintaining exact original dialogue sequence
Func GetKurzicksBlessing($x, $y)
	Out("Getting Kurzicks Blessing")
	Agent_GoToNPCNearXY($x, $y)
	TolSleep(500)

	Local $timeout = 0
	Do
		UI_Dialog(0x85)
		TolSleep(1000)
		UI_Dialog(0x86)
		TolSleep(1000)

		If Agent_GetAgentEffectInfo(-2, $Blessing_of_the_Kurzicks2) Or Agent_GetAgentEffectInfo(-2, $Blessing_of_the_Kurzicks1) Or Agent_GetAgentEffectInfo(-2, $Blessing_of_the_Kurzicks) Or Agent_GetAgentEffectInfo(-2, 1946) Then
			TolSleep(1000)
		Else
			Agent_GoToNPCNearXY($x, $y)
			TolSleep(500)
			UI_Dialog(0x81)
			TolSleep(1000)
			UI_Dialog(0x2)
			TolSleep(1000)
			UI_Dialog(0x84)
			TolSleep(1000)
			UI_Dialog(0x86)
			TolSleep(1000)
		EndIf
		$timeout += 1
	Until Agent_GetAgentEffectInfo(-2, $Blessing_of_the_Kurzicks2) Or Agent_GetAgentEffectInfo(-2, $Blessing_of_the_Kurzicks1) Or Agent_GetAgentEffectInfo(-2, $Blessing_of_the_Kurzicks) Or Agent_GetAgentEffectInfo(-2, 1946) Or $timeout >= 10

	Return Out("Kurzicks Blessing Acquired")
EndFunc   ;==>GetKurzicksBlessing