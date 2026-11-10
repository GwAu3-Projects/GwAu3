#include-once
Global $mMove = DllStructCreate('ptr;float;float;float')
Global $mMovePtr = DllStructGetPtr($mMove)

;~ Description: Moves the player to specific world coordinates (X, Y).
Func Player_Move($a_x, $a_y, $aRandom = 50)
    If Agent_GetAgentPtr(-2) = 0 Then Return False

    Local $l_x = $a_x
    Local $l_y = $a_y

    If $aRandom > 0 Then
        $l_x += Random(-$aRandom, $aRandom)
        $l_y += Random(-$aRandom, $aRandom)
    EndIf

    DllStructSetData($mMove, 2, $l_x)
    DllStructSetData($mMove, 3, $l_y)
    Core_Enqueue($mMovePtr, 16)

    Return True
EndFunc   ;==>Player_Move


;~ Description: Agents Movevement on the X axis
Func Player_MoveX($aAgent = GetAgentPtr(-2))
	Return Memory_Read(GetAgentPtr($aAgent) + 160, 'float')
EndFunc   ;==>MoveX


;~ Description: Agents Movevement on the Y axis
Func Player_MoveY($aAgent = GetAgentPtr(-2))
	Return Memory_Read(GetAgentPtr($aAgent) + 164, 'float')
EndFunc   ;==>MoveY