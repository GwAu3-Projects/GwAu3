#include-once
; Pre-staging Map Cmd shims (Logic arg order → Modules).

Func WaitMapLoading($aMapID = -1, $aTimeout = 30000, $aWaitAgents = True)
	If $aMapID = 0 Then $aMapID = -1
	Local $bOk = Map_WaitMapLoading($aMapID, -1, $aTimeout)
	If $bOk Then EnsureSkillBarCache()
	Return $bOk
EndFunc   ;==>WaitMapLoading

Func GetInstanceUpTime()
	Return Map_GetInstanceUpTime()
EndFunc   ;==>GetInstanceUpTime
