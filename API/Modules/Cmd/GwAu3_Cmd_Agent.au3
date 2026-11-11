#include-once

Func Agent_ChangeTarget($a_i_AgentID)
	$a_i_AgentID = Agent_ConvertID($a_i_AgentID)

    ; 0 is allowed on purpose: it is how the native clears the selection, and it is
    ; what Agent_ClearTarget sends. Only a negative id is meaningless here.
    If $a_i_AgentID < 0 Then
        Log_Error("Invalid agent ID: " & $a_i_AgentID, "AgentMod", $g_h_EditText)
        Return False
    EndIf

    DllStructSetData($g_d_ChangeTarget, 2, $a_i_AgentID)
    Core_Enqueue($g_p_ChangeTarget, 8)

    ; Record for tracking
    $g_i_LastTargetID = $a_i_AgentID

    Return True
EndFunc

Func Agent_MakeAgentArray($a_i_Type = 0)
    If $a_i_Type < 0 Then
        Log_Error("Invalid agent type: " & $a_i_Type, "AgentMod", $g_h_EditText)
        Return False
    EndIf

    DllStructSetData($g_d_MakeAgentArray, 2, $a_i_Type)
    Core_Enqueue($g_p_MakeAgentArray, 8)

    Log_Debug("Creating agent array snapshot (type filter: " & $a_i_Type & ")", "AgentMod", $g_h_EditText)
    Return True
EndFunc

Func Agent_TargetNearestEnemy($a_f_MaxDistance = 1300)
    Local $l_i_NearestID = 0
    Local $l_f_NearestDistance = $a_f_MaxDistance
    Local $l_i_MyID = Agent_GetMyID()
    Local $l_i_MaxAgents = Agent_GetMaxAgents()

    ; MaxAgents is exclusive: ManagerFindAgent refuses id >= MaxAgents, so reading
    ; that slot could hand Agent_ChangeTarget an id the native kills the client on.
    For $i = 1 To $l_i_MaxAgents - 1
        ; Check if agent exists
        Local $l_p_Pointer = Agent_GetAgentPtr($i)
        If $l_p_Pointer = 0 Then ContinueLoop

        ; Check if agent is alive
        If Agent_GetAgentInfo($l_p_Pointer, "IsDead") Then ContinueLoop

        ; Check if agent is an enemy (simplified check)
        Local $l_i_Allegiance = Agent_GetAgentInfo($i, "Allegiance")
        If $l_i_Allegiance <> $GC_I_ALLEGIANCE_ENEMY Then ContinueLoop

        ; Calculate distance
        Local $l_f_Distance = Agent_GetDistance($i, $l_i_MyID)
        If $l_f_Distance < $l_f_NearestDistance Then
            $l_f_NearestDistance = $l_f_Distance
            $l_i_NearestID = $i
        EndIf
    Next

    If $l_i_NearestID > 0 Then
        Agent_ChangeTarget($l_i_NearestID)
        Log_Debug("Targeted nearest enemy: " & $l_i_NearestID & " at distance: " & $l_f_NearestDistance, "AgentMod", $g_h_EditText)
    Else
        Log_Debug("No enemy found within range: " & $a_f_MaxDistance, "AgentMod", $g_h_EditText)
    EndIf

    Return $l_i_NearestID
EndFunc

Func Agent_TargetNearestAlly($a_f_MaxDistance = 1300, $a_b_ExcludeSelf = True)
    Local $l_i_NearestID = 0
    Local $l_f_NearestDistance = $a_f_MaxDistance
    Local $l_i_MyID = Agent_GetMyID()
    Local $l_i_MaxAgents = Agent_GetMaxAgents()

    ; MaxAgents is exclusive: ManagerFindAgent refuses id >= MaxAgents, so reading
    ; that slot could hand Agent_ChangeTarget an id the native kills the client on.
    For $l_i_Index = 1 To $l_i_MaxAgents - 1
        ; Skip self if requested
        If $a_b_ExcludeSelf And $l_i_Index = $l_i_MyID Then ContinueLoop

        ; Check if agent exists
        Local $l_p_Pointer = Agent_GetAgentPtr($l_i_Index)
        If $l_p_Pointer = 0 Then ContinueLoop

        ; Check if agent is alive
        If Agent_GetAgentInfo($l_p_Pointer, "IsDead") Then ContinueLoop

        ; Check if agent is an ally (simplified check)
        Local $l_i_Allegiance = Agent_GetAgentInfo($l_i_Index, "Allegiance")
        If $l_i_Allegiance <> $GC_I_ALLEGIANCE_ALLY Then ContinueLoop

        ; Calculate distance
        Local $l_f_Distance = Agent_GetDistance($l_i_Index, $l_i_MyID)
        If $l_f_Distance < $l_f_NearestDistance Then
            $l_f_NearestDistance = $l_f_Distance
            $l_i_NearestID = $l_i_Index
        EndIf
    Next

    If $l_i_NearestID > 0 Then
        Agent_ChangeTarget($l_i_NearestID)
        Log_Debug("Targeted nearest ally: " & $l_i_NearestID & " at distance: " & $l_f_NearestDistance, "AgentMod", $g_h_EditText)
    Else
        Log_Debug("No ally found within range: " & $a_f_MaxDistance, "AgentMod", $g_h_EditText)
    EndIf

    Return $l_i_NearestID
EndFunc

Func Agent_TargetNearestAnimal($a_f_MaxDistance = 1300, $a_b_ExcludeSelf = True)
    Local $l_i_NearestID = 0
    Local $l_f_NearestDistance = $a_f_MaxDistance
    Local $l_i_MyID = Agent_GetMyID()
    Local $l_i_MaxAgents = Agent_GetMaxAgents()

    ; MaxAgents is exclusive: ManagerFindAgent refuses id >= MaxAgents, so reading
    ; that slot could hand Agent_ChangeTarget an id the native kills the client on.
    For $l_i_Index = 1 To $l_i_MaxAgents - 1
        ; Skip self if requested
        If $a_b_ExcludeSelf And $l_i_Index = $l_i_MyID Then ContinueLoop

        ; Check if agent exists
        Local $l_p_Pointer = Agent_GetAgentPtr($l_i_Index)
        If $l_p_Pointer = 0 Then ContinueLoop

        ; Check if agent is alive
        If Agent_GetAgentInfo($l_p_Pointer, "IsDead") Then ContinueLoop

        ; Check if agent is an ally (simplified check)
        Local $l_i_Allegiance = Agent_GetAgentInfo($l_i_Index, "Allegiance")
        If $l_i_Allegiance <> $GC_I_ALLEGIANCE_ANIMAL Then ContinueLoop

        ; Calculate distance
        Local $l_f_Distance = Agent_GetDistance($l_i_Index, $l_i_MyID)
        If $l_f_Distance < $l_f_NearestDistance Then
            $l_f_NearestDistance = $l_f_Distance
            $l_i_NearestID = $l_i_Index
        EndIf
    Next

    If $l_i_NearestID > 0 Then
        Agent_ChangeTarget($l_i_NearestID)
        Log_Debug("Targeted nearest animal: " & $l_i_NearestID & " at distance: " & $l_f_NearestDistance, "AgentMod", $g_h_EditText)
    Else
        Log_Debug("No animal found within range: " & $a_f_MaxDistance, "AgentMod", $g_h_EditText)
    EndIf

    Return $l_i_NearestID
EndFunc

Func Agent_ClearTarget()
    Return Agent_ChangeTarget(0)
EndFunc

Func Agent_TargetSelf()
    Local $l_i_MyID = Agent_GetMyID()
    Return Agent_ChangeTarget($l_i_MyID)
EndFunc

;~ Description: Run to or follow a player.
Func Agent_GoPlayer($a_v_Agent)
    Return Core_SendPacket(0x8, $GC_I_HEADER_INTERACT_PLAYER, Agent_ConvertID($a_v_Agent))
EndFunc   ;==>GoPlayer

;~ Description: Talk to an NPC
Func Agent_GoNPC($a_v_Agent)
    Return Core_SendPacket(0xC, $GC_I_HEADER_INTERACT_LIVING, Agent_ConvertID($a_v_Agent))
EndFunc   ;==>GoNPC

;~ Description: Go to NPC until you are within actionable distance and interact with them
Func Agent_GoToNPC($npc = Agent_GetNearestNPC(-2), $Interact = True)
	Local $lBlocked = 0
	Local $lMapLoading = Map_GetInstanceInfo("Type"), $lMapLoadingOld
	Do
		$lMapLoadingOld = $lMapLoading
		$lMapLoading = Map_GetInstanceInfo("Type")
		If $lMapLoading <> $lMapLoadingOld Then ExitLoop
		$npcXY = Agent_XY($npc)
		Cinematic_ConditionalSkipCinematic()
		Sleep(200)
	Until Agent_XY($npc)[0] = $npcXY[0] And Agent_XY($npc)[1] = $npcXY[1] ; wait until the NPC has stopped moving
	Agent_MoveToDistanceAway(70, $npc)
	If $Interact Then Agent_GoNPC($npc)
EndFunc   ;==>GoToNPC

;~ Description: Go to NPC until you are within actionable distance and interact with them
Func Agent_GoToPlayer($Player = GetNearestAgentPtr(-2), $Interact = True)
	Local $lBlocked = 0
	Local $lMapLoading = Map_GetInstanceInfo("Type"), $lMapLoadingOld
	Do
		$PlayerXY = Agent_XY($Player)
		Cinematic_ConditionalSkipCinematic()
		Sleep(200)
	Until Agent_XY($Player)[0] = $PlayerXY[0] And Agent_XY($Player)[1] = $PlayerXY[1] ; wait until the NPC has stopped moving
	Agent_MoveToDistanceAway(70, $Player)
	If $Interact Then GoPlayer($Player)
EndFunc   ;==>GoToNPC

; Finds NPC nearest given coords and PlayerID and talks to him/her
Func Agent_GoToNPCNearXY($a_f_X, $a_f_Y, $a_i_PlayerNumber = 0, $Interact = True) ; $dialog)
	$l_p_npc = Agent_GetNearestNPCtoXY($a_f_X, $a_f_Y, $a_i_PlayerNumber = 0)
	Agent_GoToNPC($l_p_npc, $Interact)
EndFunc   ;==>GoToNPCNearXY

;~ Description: Run to a signpost.
Func Agent_GoSignpost($a_v_Agent)
    Return Core_SendPacket(0xC, $GC_I_HEADER_GADGET_INTERACT, Agent_ConvertID($a_v_Agent), 0)
EndFunc   ;==>GoSignpost

; Move to certain distance away from an agent at a given angle
;~ Description: Moves to a position at a specified distance away from a target agent, logging profession and name directly inline.
Func Agent_MoveToDistanceAway($aDistance, $aAgent, $aRandom = 10)
	If $aAgent = 0 Or Agent_GetAgentInfo(-2, "IsDead") Then Return
	Out("Going to Agent: " & Agent_GetAgentInfo($aAgent, "Profession") & " " & Agent_GetAgentInfo($aAgent, "Name"))
	Local $ClosestXY[2]
	$ClosestXY = Agent_GetClosestXYinRange($aDistance, $aAgent)
	Out("Move to (" & Floor($ClosestXY[0]) & ", " & Floor($ClosestXY[1]) & ")")
	Agent_MoveToXY($ClosestXY[0], $ClosestXY[1], $aRandom)
	Out("New distance to target: " & Floor(Agent_GetDistance($aAgent, -2)))
EndFunc   ;==>Agent_MoveToDistanceAway

;~ Description: Move to signpost until you are within actionable distance and interect with it.
Func Agent_GoToSignpost($aAgent)
	Local $lMe, $lCount
	Local $lBlocked = 0
	Local $lMapLoading = Map_GetInstanceInfo("Type"), $lMapLoadingOld
	Agent_MoveToDistanceAway(60, $aAgent)
	Pingsleep(100)
	GoSignpost($aAgent)
EndFunc   ;==>GoToSignpost

; Finds signpost nearest given coords and PlayerID and talks to him/her
Func Agent_GoToSignpostNearXY($x, $y) ; $dialog
	$signpost = Agent_GetNearestSignpostToXY($x, $y)
	GoToSignpost($signpost)
EndFunc   ;==>GoToSignpostNearXY


;~ Description: Move to a location and wait until you reach it.
Func Agent_MoveToXY($aX, $aY, $aRandom = 50)
	If Map_GetInstanceInfo("IsLoading") Then Return
	Local $lBlocked = 0
	Local $lMapLoading = Map_GetInstanceInfo("Type"), $lMapLoadingOld
	Local $lDestX = $aX + Random(-$aRandom, $aRandom)
	Local $lDestY = $aY + Random(-$aRandom, $aRandom)

	Map_Move($lDestX, $lDestY, 0)
	Do
		If Cinematic_DetectSkipCinematics() Then ExitLoop
		$lMapLoadingOld = $lMapLoading
		$lMapLoading = Map_GetInstanceInfo("Type")
		If $lMapLoading <> $lMapLoadingOld Then ExitLoop
		Cinematic_ConditionalSkipCinematic()
		If Agent_GetAgentInfo(-2, "MoveX") == 0 And Agent_GetAgentInfo(-2, "MoveY") == 0 Then
			$lBlocked += 1
			$lDestX = $aX + Random(-$aRandom, $aRandom)
			$lDestY = $aY + Random(-$aRandom, $aRandom)
			Map_Move($lDestX, $lDestY, 0)
		EndIf
		Sleep(100)
	Until Agent_GetDistanceToXY($lDestX, $lDestY) < 25 Or $lBlocked > 14
EndFunc   ;==>MoveTo

; Move to certain distance away from an agent at a given angle
Func Agent_MoveToClosestXYtoWaypoint($x, $y, $aDistance, $aAgent = GetAgentPtr(-2))
	If $aAgent = 0 Then Return
	Local $ClosestXY = GetClosestXYtoWaypoint($x, $y, $aDistance, $aAgent)
	; Out("Move to (" & Floor($ClosestXY[0]) & ", " & Floor($ClosestXY[1]) & ")")
	MoveTo($ClosestXY[0], $ClosestXY[1], 100)
	Out("New distance to target: " & Floor(GetDistance($aAgent, -2)))

EndFunc   ;==>MoveToClosestXYtoWaypointInRangeOfAgent

;~ Description: Attack an agent.
Func Agent_Attack($a_v_Agent, $a_b_CallTarget = False)
    Return Core_SendPacket(0xC, $GC_I_HEADER_ACTION_ATTACK, Agent_ConvertID($a_v_Agent), $a_b_CallTarget)
EndFunc   ;==>Attack

;~ Description: Call target.
Func Agent_CallTarget($a_v_Target)
    Return Core_SendPacket(0xC, $GC_I_HEADER_CALL_TARGET, 0xA, Agent_ConvertID($a_v_Target))
EndFunc   ;==>CallTarget

;~ Description: Cancel current action.
Func Agent_CancelAction()
    Return Core_SendPacket(0x4, $GC_I_HEADER_ACTION_CANCEL)
EndFunc   ;==>CancelAction