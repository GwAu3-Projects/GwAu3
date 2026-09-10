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

;~ Description: Run to a signpost.
Func Agent_GoSignpost($a_v_Agent)
    Return Core_SendPacket(0xC, $GC_I_HEADER_GADGET_INTERACT, Agent_ConvertID($a_v_Agent), 0)
EndFunc   ;==>GoSignpost

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