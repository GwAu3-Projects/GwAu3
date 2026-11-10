; logicagents.au3
; Agent / party / hero finding and counting functions extracted from original logic.au3
; Prefer GwAu3 primitives (Agent_GetAgentInfo, Agent_GetAgentArray, Agent_GetDistance, etc.)

Func Agent_GetByID($aAgentID = -2)
	Return Agent_GetAgentPtr($aAgentID)
EndFunc

Func Agent_Exists($aAgentID = -2)
	Return Agent_GetAgentPtr($aAgentID) <> 0
EndFunc

; Returns both Skill and Agent IDs
Func Agent_ID($aAgent = -2)
	If IsPtr($aAgent) Then
		; Agent ID is at +0x2C; skill PvPID is at +44.
		; Try agent first; if the value looks like a skill ID, fall through.
		Local $iVal = Memory_Read($aAgent + 0x2C, "long")
		If $iVal > 0 And $iVal < 50000 Then Return $iVal
		; Fallback for skill pointers (PvPID at +44)
		Return Memory_Read($aAgent + 44, "long")
	ElseIf IsDllStruct($aAgent) Then
		Return DllStructGetData($aAgent, "ID")
	Else
		; Numeric ID or agent ID – resolve via GwAu3
		If $aAgent = -2 Or $aAgent = 0 Then Return Agent_GetMyID()
		Return Agent_GetAgentInfo($aAgent, "ID")
	EndIf
EndFunc

Func Agent_X($aAgent = -2)
    Return Agent_GetAgentInfo($aAgent, "X")
EndFunc

Func Agent_Y($aAgent = -2)
    Return Agent_GetAgentInfo($aAgent, "Y")
EndFunc

Func Agent_XY($aAgent = -2)
	Local $a[2] = [Agent_GetAgentInfo($aAgent, "X"), Agent_GetAgentInfo($aAgent, "Y")]
	Return $a
EndFunc

Func Agent_GetHealth($aAgent = -2)
	Return Agent_GetAgentInfo($aAgent, "HP")
EndFunc

Func Agent_GetCurrentTargetID()
	Return Agent_GetCurrentTarget()
EndFunc


#Region Agent Controls

; Finds the most balled target based on a number of critieria
Func Agent_GetBestTargetPtr($aRange = 1320, $CastingOnly = False, $NoHexOnly = False, $HexedOnly = False, $EnchantedOnly = False, $StationaryOnly = False, $PassiveOnly = False, $x = X(), $y = Y(), $MeleeOnly = False, $CasterOnly = False)
	Local $lBestTargetPtr, $lDistance, $lLowestSum = 100000000
	Local $lHP, $lLowestHP = 1
	Local $lAgentPtrArray = Agent_GetAgentArray(0xDB) ; living agents only

	For $i = 1 To $lAgentPtrArray[0]
		Local $lSumDistances = 0
		If IsSpiritAgent($lAgentPtrArray[$i]) Then ContinueLoop
		If $EnchantedOnly And Not Agent_GetAgentInfo($lAgentPtrArray[$i], "IsEnchanted") Then ContinueLoop
		If $NoHexOnly And Agent_GetAgentInfo($lAgentPtrArray[$i], "IsHexed") Then ContinueLoop
		If $HexedOnly And Not Agent_GetAgentInfo($lAgentPtrArray[$i], "IsHexed") Then ContinueLoop
		If $CastingOnly And Not Agent_GetAgentInfo($lAgentPtrArray[$i], "IsCasting") Then ContinueLoop
		If $StationaryOnly And Agent_GetAgentInfo($lAgentPtrArray[$i], "IsMoving") Then ContinueLoop
		If $PassiveOnly And Agent_GetAgentInfo($lAgentPtrArray[$i], "IsAttacking") Then ContinueLoop
		If $MeleeOnly And Not IsMartial($lAgentPtrArray[$i]) Then ContinueLoop
		If $CasterOnly And IsMartial($lAgentPtrArray[$i]) Then ContinueLoop


		$lHP = GetHealth($lAgentPtrArray[$i])
		If $lHP < $lLowestHP Then
			$LowestEnemyPtr = $lAgentPtrArray[$i]
			$LowestHP = $lHP
		EndIf

		For $J = 1 To $lAgentPtrArray[0]
			If $lAgentPtrArray[$J] = $lAgentPtrArray[$i] Then ContinueLoop
			$lDistance = Agent_GetDistanceToCoord($lAgentPtrArray[$i], $lAgentPtrArray[$J])
			$lSumDistances += $lDistance
		Next
		If $lSumDistances < $lLowestSum Then
			$lLowestSum = $lSumDistances
			$lBestTargetPtr = $lAgentPtrArray[$i]
		EndIf
	Next
	Return $lBestTargetPtr
EndFunc   ;==>GetBestTargetPtr

Func Agent_GetNearestDistance($aAllegiance = 3)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iMin = 999999
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = $aAllegiance Then
			Local $iD = Agent_GetDistance($iID)
			If $iD > 0 And $iD < $iMin Then $iMin = $iD
		EndIf
	Next
	Return $iMin
EndFunc

;~Description: Returns the party member with the lowest HP
Func GetLowestAlly($excludeself = False)
	$lLowestHP = 1000
	Local $lHP
	Local $lAgentPtrArray = Agent_GetArray(3, 0xDB, $allegiance_ally)

	For $i = 1 To $lAgentPtrArray[0]
		If $excludeself And $lAgentPtrArray = Agent_GetAgentPtr() Then ContinueLoop
		$lHP = Agent_GetHealth($lAgentPtrArray[$i])
		If $lHP < $lLowestHP Then
			$LowestallyPtr = $lAgentPtrArray[$i]
			$lLowestHP = $lHP
		EndIf
	Next
	Return $LowestallyPtr
EndFunc   ;==>GetLowestAlly

;~Description: Returns the party member with the lowest HP
Func GetHighestAlly($excludeself = False)
	$lHighestHP = 0
	Local $lHP
	Local $lAgentPtrArray = Agent_GetArray(3, 0xDB, $allegiance_ally)

	For $i = 1 To $lAgentPtrArray[0]
		If $excludeself And $lAgentPtrArray = Agent_GetAgentPtr() Then ContinueLoop
		$lHP = Agent_GetHealth($lAgentPtrArray[$i])
		If $lHP > $lHighestHP Then
			$HighestAllyPtr = $lAgentPtrArray[$i]
			$lHighestHP = $lHP
		EndIf
	Next
	Return $HighestAllyPtr
EndFunc   ;==>GetLowestAlly

;~Description: Returns the enemy with the lowest HP
Func GetLowestEnemy($aRange = 1320)
	Agent_GetBestTargetPtr($aRange)
	Return $LowestEnemyPtr
EndFunc   ;==>GetLowestEnemy

;~Description: Returns the first enemy with no Hexes
Func GetNoHexEnemy($aRange = 1320)
	Return Agent_GetBestTargetPtr($aRange, False, True)
EndFunc   ;==>GetNoHexEnemy

Func GetBalledEnchantedEnemy($aRange = 1320)
    Local $lBestTargetPtr = 0
    Local $iMaxBalledNumber = 0
    Local $lAgentPtrArray = Agent_GetAgentArray(0xDB) ; living agents only

    For $i = 1 To $lAgentPtrArray[0]
        Local $lPtr = $lAgentPtrArray[$i]

        ; Verify allegiance (3 = enemy) and range
        If Agent_GetAgentInfo($lPtr, "Allegiance") <> 3 Then ContinueLoop
        If Agent_GetDistance($lPtr) > $aRange Then ContinueLoop

        ; Check if enchanted directly via pointer
        If Not Agent_GetAgentInfo($lPtr, "IsEnchanted") Then ContinueLoop

        ; Count nearby enemies for "balled" grouping
        Local $iBalledNumber = Agent_GetNumberOfEnemiesNearAgent(300, $lPtr)
        If $iBalledNumber > $iMaxBalledNumber Then
            $iMaxBalledNumber = $iBalledNumber
            $lBestTargetPtr = $lPtr
        EndIf
    Next
    Return $lBestTargetPtr
EndFunc   ;==>GetBalledEnchantedEnemy

Func GetMostBalledCastingEnemy($aRange = 1320)
	Return Agent_GetBestTargetPtr($aRange, True)
EndFunc   ;==>GetMostBalledCastingEnemy

Func GetMostBalledHexedEnemy($aRange = 1320)
	Return Agent_GetBestTargetPtr($aRange, False, False, True)
EndFunc   ;==>GetMostBalledHexedEnemy

Func GetBestTargetAlly($DistanceToSelf = 1320, $hexedonly = True, $otherally = False)
	Local $lBestTargetPtr, $lDistance, $lLowestSum = 100000000
	Local $lAgentPtrArray = Agent_GetArray(4, 0xDB, 1)

	For $i = 1 To $lAgentPtrArray[0]
		Local $lSumDistances = 0
		If $hexedonly And Not Agent_GetAgentInfo($lAgentPtrArray[$i], "Dead") Then ContinueLoop
		If $otherally And DllStructGetData($lAgentPtrArray[$i], 'ID') = Agent_GetMyID() Then ContinueLoop

		For $J = 1 To $lAgentPtrArray[0]
			If $lAgentPtrArray[$J] = $lAgentPtrArray[$i] Then ContinueLoop
			$lDistance = Agent_GetDistance($lAgentPtrArray[$i], $lAgentPtrArray[$J])
			$lSumDistances += $lDistance
		Next
		If $lSumDistances < $lLowestSum Then
			$lLowestSum = $lSumDistances
			$lBestTargetPtr = $lAgentPtrArray[$i]
		EndIf
	Next
	Return $lBestTargetPtr
EndFunc   ;==>GetBestTargetAlly

Func GetMostBalledHexedAlly($aRange = 1320)
	Return GetBestTargetAlly($aRange, True)
EndFunc   ;==>GetMostBalledHexedAlly

Func NeedEchoAlly($aSkillID)
	Local $lHeroID

	If GetAttributeByID($Leadership, True) < 20 and $aSkillID == $Heroic_Refrain Then Return Agent_GetAgentPtr(-2)
	For $heronumber = 1 to GetPartySize() - 1
		$lHeroID = GetHeroID($heronumber)
		If Agent_GetAgentInfo($lHeroID, "Dead") Then ContinueLoop                                  ; exclude agents that do not have the effect
		If Not Skill_HasEffect($aSkillID, $heronumber) Then Return Agent_GetAgentPtr($lHeroID)
	Next
EndFunc   ;==>NeedEchoAlly

;~Description: Returns the ally with the most Conditions on them

; Single-pass: returns [AgentID, HexCount, EnchantCount, CondCount] for allies in range
Func GetAgentEffectCount($aEffectType, $aAgent = -2)
    Local $l_p_EffectArray = Agent_GetAgentEffectArrayInfo($aAgent, "EffectArray")
    Local $l_i_EffectCount = Agent_GetAgentEffectArrayInfo($aAgent, "EffectArraySize")

    If $l_p_EffectArray = 0 Or $l_i_EffectCount = 0 Then Return 0

    Local $iCount = 0

    For $j = 0 To $l_i_EffectCount - 1
        Local $l_p_CurrentPtr = $l_p_EffectArray + ($j * 0x18)
        Local $iSkillID = Memory_Read($l_p_CurrentPtr, "long")
        If $iSkillID > 0 Then
            If Skill_GetSkillInfo($iSkillID, "SkillType") = $aEffectType Then
                $iCount += 1
            EndIf
        EndIf
    Next

    Return $iCount
EndFunc  ;==>GetAgentEffectCount

; Determines the agent that has the most effects of a specific type
Func GetMostEffectAgent($aEffectType, $aAllegiance = 1, $aRange = 1320, $excludeself = False)
    Local $iMyID = Agent_GetMyID()
    Local $aAgents = Agent_GetAgentArray(0xDB) ; living agents only
    Local $iBestID = 0, $iMax = 0

    For $i = 1 To $aAgents[0]
        Local $lPtr = $aAgents[$i]
        Local $iAgentID = Agent_GetAgentInfo($lPtr, "ID")

        If $iAgentID = 0 Then ContinueLoop
        If $excludeself And $iAgentID = $iMyID Then ContinueLoop
        If Agent_GetAgentInfo($lPtr, "Allegiance") <> $aAllegiance Then ContinueLoop
        If Agent_GetDistance($lPtr) > $aRange Then ContinueLoop
        Local $iCount = GetAgentEffectCount($aEffectType, $lPtr)
		Out("effect count: " & $iCount)
        If $iCount > $iMax Then
            $iMax = $iCount
            $iBestID = $iAgentID
        EndIf
    Next
    Return $iBestID
EndFunc   ;==>GetMostEffectAgent   ;==>GetMostEffectAgent

;~Description: Returns the Agent ID of the ally with the most Hexes
Func MostHexedAlly($aRange = 1320, $excludeself = False)
    Return GetMostEffectAgent($Hex, 1, $aRange, $excludeself)
EndFunc   ;==>MostHexedAlly

;~Description: Returns the Agent ID of the ally with the most Conditions
Func MostCondsAlly($aRange = 1320, $excludeself = False)
    Return GetMostEffectAgent($Condition, 1, $aRange, $excludeself)
EndFunc   ;==>MostCondsAlly

;~Description: Returns the Agent ID of the enemy with the most Enchantments
Func MostEnchantedEnemy($aRange = 1320)
    Return GetMostEffectAgent($Enchantment, 3, $aRange, False)
EndFunc   ;==>GetMostEnchantedEnemy

#EndRegion Agent Controls


Func Agent_IsEnemyNear($aRange = 1320)
	Return Agent_GetNumberOfEnemies($aRange) > 0
EndFunc

Func Agent_NoEnemiesAround($aRange = 1320)
	Return Agent_GetNumberOfEnemies($aRange) = 0
EndFunc

Func Agent_GetNumberOfEnemies($aRange = 3000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 3 And Agent_GetDistance($iID) <= $aRange And Not Agent_GetAgentInfo($iID, "Dead") Then
			$iCount += 1
		EndIf
	Next
	Return $iCount
EndFunc

Func Agent_GetNumberOfEnemiesNearAgent($aRange = 3000, $aAgent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	Local $iRefID = Agent_GetAgentInfo($aAgent, "ID")
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 3 And Agent_GetDistance($iID, $iRefID) <= $aRange And Not Agent_GetAgentInfo($iID, "Dead") Then
			$iCount += 1
		EndIf
	Next
	Return $iCount
EndFunc

Func Agent_GetNumberOfAllies($aRange = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And Agent_GetDistance($iID) <= $aRange And Not Agent_GetAgentInfo($iID, "Dead") Then
			$iCount += 1
		EndIf
	Next
	Return $iCount
EndFunc

Func Agent_GetNumberOfDeadAllies($aRange = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And Agent_GetDistance($iID) <= $aRange And Agent_GetAgentInfo($iID, "Dead") Then
			$iCount += 1
		EndIf
	Next
	Return $iCount
EndFunc

Func Agent_GetNearestEnemy($aAgent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iBest = 0, $iMin = 999999
	Local $iRefID = Agent_GetAgentInfo($aAgent, "ID")
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 3 And Not Agent_GetAgentInfo($iID, "Dead") Then
			Local $iD = Agent_GetDistance($iID, $iRefID)
			If $iD > 0 And $iD < $iMin Then
				$iMin = $iD
				$iBest = $iID
			EndIf
		EndIf
	Next
	Return $iBest
EndFunc

Func Agent_GetNearestAlly($aAgent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iBest = 0, $iMin = 999999
	Local $iRefID = Agent_GetAgentInfo($aAgent, "ID")
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And $iID <> $iRefID And Not Agent_GetAgentInfo($iID, "Dead") Then
			Local $iD = Agent_GetDistance($iID, $iRefID)
			If $iD > 0 And $iD < $iMin Then
				$iMin = $iD
				$iBest = $iID
			EndIf
		EndIf
	Next
	Return $iBest
EndFunc

Func Agent_GetNearestDeadAlly($aAgent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iBest = 0, $iMin = 999999
	Local $iRefID = Agent_GetAgentInfo($aAgent, "ID")
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And Agent_GetAgentInfo($iID, "Dead") Then
			Local $iD = Agent_GetDistance($iID, $iRefID)
			If $iD > 0 And $iD < $iMin Then
				$iMin = $iD
				$iBest = $iID
			EndIf
		EndIf
	Next
	Return $iBest
EndFunc

Func Agent_GetFarthestAlly($aMaxDistance = 5000, $aAgent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iBest = 0, $iMax = 0
	Local $iRefID = Agent_GetAgentInfo($aAgent, "ID")
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And $iID <> $iRefID And Not Agent_GetAgentInfo($iID, "Dead") Then
			Local $iD = Agent_GetDistance($iID, $iRefID)
			If $iD > $iMax And $iD <= $aMaxDistance Then
				$iMax = $iD
				$iBest = $iID
			EndIf
		EndIf
	Next
	Return $iBest
EndFunc

Func Agent_GetBoss($aRange = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 3 And Agent_GetDistance($iID) <= $aRange Then
			; Simple boss check via type or model; extend as needed
			If BitAND(Agent_GetAgentInfo($iID, "TypeMap"), 0xC00) Then Return $iID
		EndIf
	Next
	Return 0
EndFunc

Func GetPartySize()
	Return Party_GetSize()
EndFunc

Func GetHeroCount()
    Return Party_GetHeroCount()
EndFunc

Func GetHeroID($aHeroNumber)
    Return Party_GetHeroAgentID($aHeroNumber)
EndFunc

Func Agent_GetHero($aHeroNumber)
	Return Agent_GetAgentPtr(GetHeroID($aHeroNumber))
EndFunc

Func Agent_GetHeroProfession($aHeroNumber, $aSecondary = False)
	Local $iID = GetHeroID($aHeroNumber)
	If $aSecondary Then Return Agent_GetAgentInfo($iID, "Secondary")
	Return Agent_GetAgentInfo($iID, "Primary")
EndFunc

Func GetPartyHealth()
	Local $iSize = GetPartySize()
	If $iSize = 0 Then Return 0
	Local $fSum = 0
	For $i = 0 To $iSize - 1
		Local $iID = Party_GetMyPartyPlayerMemberInfo($i, "AgentID")
		$fSum += Agent_GetAgentInfo($iID, "HP")
	Next
	Return $fSum / $iSize
EndFunc

Func GetPartyDefeated()
	Return GetPartyHealth() = 0
EndFunc

Func Agent_GetByPlayerNumber($aPlayerNumber, $aRange = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "PlayerNumber") = $aPlayerNumber And Agent_GetDistance($iID) <= $aRange Then
			Return $iID
		EndIf
	Next
	Return 0
EndFunc

Func Agent_GetNearestNPCToXY($x = 0, $y = 0, $aPlayerNumber = 0)
	; Simplified: nearest non-enemy, non-player agent near XY
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iBest = 0, $iMin = 999999
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		Local $iAlleg = Agent_GetAgentInfo($iID, "Allegiance")
		If $iAlleg <> 3 And $iAlleg <> 1 Then
			Local $iD = Agent_GetDistanceToXY($x, $y, $iID)
			If $iD < $iMin Then
				$iMin = $iD
				$iBest = $iID
			EndIf
		EndIf
	Next
	Return $iBest
EndFunc

Func Agent_GetNearestSignpostToXY($x, $y)
	; Simplified: nearest non-enemy, non-player agent near XY
	Local $aAgents = Agent_GetAgentArray(0x200)
	Local $iBest = 0, $iMin = 999999
	For $i = 1 To UBound($aAgents) - 1
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		Local $iAlleg = Agent_GetAgentInfo($iID, "Allegiance")
		If $iAlleg <> 3 And $iAlleg <> 1 Then
			Local $iD = Agent_GetDistanceToXY($x, $y, $iID)
			If $iD < $iMin Then
				$iMin = $iD
				$iBest = $iID
			EndIf
		EndIf
	Next
	Return $iBest
EndFunc

; Stubs for spirit / pressure counts (extend with spirit type filter)
Func Agent_GetMySpiritCount($aRange = 5000)
	Return 0
EndFunc

Func Agent_GetNumberOfPressureSpirits($aRange = 5000)
	Return 0
EndFunc

Func Agent_GetLowestSpirit()
	Return 0
EndFunc


Func Agent_GetPriorityTarget($aRange = 1320)
	Return Agent_GetNearestEnemy(-2)
EndFunc

Func Agent_GetArray($aMode = 0, $aType = 0xDB, $aAllegiance = 3, $aRange = 1320)
	; Thin wrapper around Agent_GetAgentArray with basic filters
	Local $aAgents = Agent_GetAgentArray($aType)
	Local $aOut[1] = [0]
	For $i = 1 To UBound($aAgents) - 1
		Local $iPtr = $aAgents[$i]
		Local $iID = Agent_GetAgentInfo($iPtr, "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = $aAllegiance And Agent_GetDistance($iID) <= $aRange Then
			$aOut[0] += 1
			ReDim $aOut[$aOut[0] + 1]
			$aOut[$aOut[0]] = $iPtr
		EndIf
	Next
	Return $aOut
EndFunc


; ===== IsMartial wrapper =====
Func Agent_IsMartial($aAgent = -2)
	Local $iWeapon = Agent_GetAgentInfo($aAgent, "WeaponType")
	If $iWeapon >= 1 And $iWeapon <= 7 Then Return True
	Return False
EndFunc


