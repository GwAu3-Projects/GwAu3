#include-once

;~ Description: Drop a buff with specific skill ID targeting a specific agent
Func Effect_DropBuff($a_i_SkillID, $a_i_TargetID, $a_i_AgentID = -2)
    Local $iBuffID = Agent_GetAgentBuffInfo($a_i_SkillID, $a_i_TargetID, $a_i_AgentID, "BuffID")
    If $iBuffID = 0 Then Return

    Return Core_SendPacket(0x8, $GC_I_HEADER_BUFF_DROP, $iBuffID)
EndFunc ;==>DropBuff
