#include-once
; Thin Cmd wrappers over Modules (Logic-facing names).
; WaitMapLoading($map, $timeout) → Map_WaitMapLoading($map, $instanceType, $timeout).
; Does NOT cache the skill bar — call CacheSkillBar() after load when the bot needs it.

Func WaitMapLoading($a_i_MapID = -1, $a_i_Timeout = 30000, $a_b_WaitAgents = True)
	#forceref $a_b_WaitAgents
	If $a_i_MapID = 0 Then $a_i_MapID = -1
	Return Map_WaitMapLoading($a_i_MapID, -1, $a_i_Timeout)
EndFunc   ;==>WaitMapLoading
