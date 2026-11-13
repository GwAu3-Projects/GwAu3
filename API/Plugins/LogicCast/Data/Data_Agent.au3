; logicagents.au3
; Agent / party / hero finding and counting functions extracted from original logic.au3
; Prefer GwAu3 primitives (Agent_GetAgentInfo, Agent_GetAgentArray, Agent_GetDistance, etc.)

Func Agent_GetByID($aAgentID = -2)
	Return Agent_GetAgentPtr($aAgentID)
EndFunc

Func Agent_Exists($aAgentID = -2)
	Return Agent_GetAgentPtr($aAgentID) <> 0
EndFunc

; Returns agent ID. For skill pointers/structs use Skill_GetSkillInfo(..., "SkillID") instead.
; Legacy Logic ID() used agent+0x2C for agent ptrs and could also be fed skill ptrs — do not mix those.
Func Agent_ID($aAgent = -2)
	If IsDllStruct($aAgent) Then Return DllStructGetData($aAgent, "ID")
	If IsPtr($aAgent) Then Return Agent_GetAgentInfo($aAgent, "ID")
	If $aAgent = -2 Or $aAgent = 0 Then Return Agent_GetMyID()
	Return Agent_GetAgentInfo($aAgent, "ID")
EndFunc

; Legacy Logic alias. Prefer Agent_ID for agents / Skill_GetSkillInfo for skills.
Func ID($aAgent = -2)
	Return Agent_ID($aAgent)
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

; Agent_GetBestTarget lives in Modules/Data/GwAu3_Data_Agent.au3 — do not redefine here.

Func Agent_GetNearestDistance($aAllegiance = 3)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iMin = 999999
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = $aAllegiance Then
			Local $iD = Agent_GetDistance($iID)
			If $iD > 0 And $iD < $iMin Then $iMin = $iD
		EndIf
	Next
	Return $iMin
EndFunc

;~Description: Returns the party member with the lowest HP
; $excludeself = True → "other ally" (target type 4). Same arg order as MostHexed/MostConds.
Func Agent_GetLowestAlly($aRange = 1320, $excludeself = False)
	Local $lLowestHP = 1000
	Local $LowestallyPtr = 0
	Local $lMyID = Agent_GetMyID()
	Local $lAgentPtrArray = Agent_GetArray(3, 0xDB, $allegiance_ally, $aRange)

	For $i = 1 To $lAgentPtrArray[0]
		Local $lPtr = $lAgentPtrArray[$i]
		If $excludeself And Agent_ConvertID($lPtr) = $lMyID Then ContinueLoop
		Local $lHP = Agent_GetHealth($lPtr)
		If $lHP < $lLowestHP Then
			$LowestallyPtr = $lPtr
			$lLowestHP = $lHP
		EndIf
	Next
	Return $LowestallyPtr
EndFunc   ;==>Agent_GetLowestAlly

Func Agent_GetHighestAlly($aRange = 1320, $excludeself = False)
	Local $lHighestHP = 0
	Local $HighestAllyPtr = 0
	Local $lMyID = Agent_GetMyID()
	Local $lAgentPtrArray = Agent_GetArray(3, 0xDB, $allegiance_ally, $aRange)

	For $i = 1 To $lAgentPtrArray[0]
		Local $lPtr = $lAgentPtrArray[$i]
		If $excludeself And Agent_ConvertID($lPtr) = $lMyID Then ContinueLoop
		Local $lHP = Agent_GetHealth($lPtr)
		If $lHP > $lHighestHP Then
			$HighestAllyPtr = $lPtr
			$lHighestHP = $lHP
		EndIf
	Next
	Return $HighestAllyPtr
EndFunc   ;==>Agent_GetHighestAlly

;~Description: Returns the enemy with the lowest HP
Func Agent_GetLowestEnemy($aRange = 1320)
	Local $lLowest = 0, $lLowestHP = 1
	Local $lAgentPtrArray = Agent_GetAgentArray(0xDB)
	For $i = 1 To $lAgentPtrArray[0]
		If Agent_GetAgentInfo($lAgentPtrArray[$i], "Allegiance") <> 3 Then ContinueLoop
		If Agent_GetDistance($lAgentPtrArray[$i]) > $aRange Then ContinueLoop
		Local $lHP = Agent_GetAgentInfo($lAgentPtrArray[$i], "HP")
		If $lHP < $lLowestHP Then
			$lLowestHP = $lHP
			$lLowest = $lAgentPtrArray[$i]
		EndIf
	Next
	Return $lLowest
EndFunc   ;==>Agent_GetLowestEnemy

;~Description: Returns the first enemy with no Hexes
Func Agent_GetNoHexEnemy($aRange = 1320)
	Return Agent_GetBestTarget($aRange, False, True)
EndFunc   ;==>Agent_GetNoHexEnemy

Func Agent_GetBalledEnchantedEnemy($aRange = 1320)
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
EndFunc   ;==>Agent_GetBalledEnchantedEnemy

Func Agent_GetMostBalledCastingEnemy($aRange = 1320)
	Return Agent_GetBestTarget($aRange, True)
EndFunc   ;==>Agent_GetMostBalledCastingEnemy

Func Agent_GetMostBalledHexedEnemy($aRange = 1320)
	Return Agent_GetBestTarget($aRange, False, False, True)
EndFunc   ;==>Agent_GetMostBalledHexedEnemy

Func Agent_GetBestTargetAlly($DistanceToSelf = 1320, $hexedonly = True, $otherally = False)
	Local $lBestTargetPtr = 0, $lDistance, $lLowestSum = 100000000
	Local $lAgentPtrArray = Agent_GetAgentArray(0xDB)
	If Not IsArray($lAgentPtrArray) Or $lAgentPtrArray[0] = 0 Then Return 0

	For $i = 1 To $lAgentPtrArray[0]
		Local $lPtr = $lAgentPtrArray[$i]
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> 1 Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "IsDead") Then ContinueLoop
		If Agent_GetDistance($lPtr) > $DistanceToSelf Then ContinueLoop
		If $hexedonly And Not Agent_GetAgentInfo($lPtr, "IsHexed") Then ContinueLoop
		If $otherally And Agent_ConvertID($lPtr) = Agent_GetMyID() Then ContinueLoop

		; Prefer allies clustered with other allies (legacy "balled" score).
		Local $lSumDistances = 0
		For $J = 1 To $lAgentPtrArray[0]
			If $lAgentPtrArray[$J] = $lPtr Then ContinueLoop
			If Agent_GetAgentInfo($lAgentPtrArray[$J], "Allegiance") <> 1 Then ContinueLoop
			If Agent_GetAgentInfo($lAgentPtrArray[$J], "IsDead") Then ContinueLoop
			$lSumDistances += Agent_GetDistance($lPtr, $lAgentPtrArray[$J])
		Next
		If $lSumDistances < $lLowestSum Then
			$lLowestSum = $lSumDistances
			$lBestTargetPtr = $lPtr
		EndIf
	Next
	Return $lBestTargetPtr
EndFunc   ;==>Agent_GetBestTargetAlly

; Hexed ally with the most nearby enemies (Shatter Hex AoE). Falls back to any hexed ally.
Func Agent_GetMostBalledHexedAlly($aRange = 1320, $excludeself = False)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $lBestNear = 0, $lBestNearEnemies = -1
	Local $lBestAny = 0
	Local $lMyID = Agent_GetMyID()
	If Not IsArray($aAgents) Or $aAgents[0] = 0 Then Return 0

	For $i = 1 To $aAgents[0]
		Local $lPtr = $aAgents[$i]
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> 1 Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "IsDead") Then ContinueLoop
		If $excludeself And Agent_ConvertID($lPtr) = $lMyID Then ContinueLoop
		If Not Agent_GetAgentInfo($lPtr, "IsHexed") Then ContinueLoop
		If Agent_GetDistance($lPtr) > $aRange Then ContinueLoop

		If $lBestAny = 0 Then $lBestAny = $lPtr
		Local $lNear = Agent_GetNumberOfEnemiesNearAgent($area_range, $lPtr)
		If $lNear > $lBestNearEnemies Then
			$lBestNearEnemies = $lNear
			$lBestNear = $lPtr
		EndIf
	Next

	If $lBestNear <> 0 And $lBestNearEnemies > 0 Then Return $lBestNear
	If $lBestNear <> 0 Then Return $lBestNear
	If $lBestAny <> 0 Then Return $lBestAny
	Return Agent_GetMostHexedAlly($aRange, $excludeself)
EndFunc   ;==>Agent_GetMostBalledHexedAlly

Func Agent_NeedEchoAlly($aSkillID)
	Local $lHeroID

	If GetAttributeByID($Leadership, True) < 20 and $aSkillID == $Heroic_Refrain Then Return Agent_GetAgentPtr(-2)
	For $heronumber = 1 to Party_GetPartyContextInfo("TotalPartySize") - 1
		$lHeroID = GetHeroID($heronumber)
		If Agent_GetAgentInfo($lHeroID, "IsDead") Then ContinueLoop
		If Not Skill_HasEffect($aSkillID, $lHeroID) Then Return Agent_GetAgentPtr($lHeroID)
	Next
EndFunc   ;==>NeedEchoAlly

;~Description: Returns the ally with the most Conditions on them

; Counts effects of a given skill type on an agent.
; NOTE: Effect entry SkillID still needs a raw read (same as GwAu3_Data_Agent internals);
; candidate for Agent_GetEffectSkillID($effectPtr) if promoted to Modules.
Func Agent_GetEffectTypeCount($aEffectType, $aAgent = -2)
    Local $l_p_EffectArray = Agent_GetAgentEffectArrayInfo($aAgent, "EffectArray")
    Local $l_i_EffectCount = Agent_GetAgentEffectArrayInfo($aAgent, "EffectArraySize")

    If $l_p_EffectArray = 0 Or $l_i_EffectCount = 0 Then Return 0

    Local $iCount = 0
    For $j = 0 To $l_i_EffectCount - 1
        Local $iSkillID = Memory_Read($l_p_EffectArray + ($j * 0x18), "long")
        If $iSkillID > 0 And Skill_GetSkillInfo($iSkillID, "SkillType") = $aEffectType Then
            $iCount += 1
        EndIf
    Next
    Return $iCount
EndFunc  ;==>GetAgentEffectCount

; Returns agent ptr with the most effects of a specific type, within $aRange.
; $excludeself=True only for skill target type 4 (other ally). Default includes self.
; On equal counts, prefer self so hex/cond remove can land on us.
Func Agent_GetMostEffectAgent($aEffectType, $aAllegiance = 1, $aRange = 1320, $excludeself = False)
	Local $iMyID = Agent_GetMyID()
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $lBestPtr = 0, $iMax = -1

	For $i = 1 To $aAgents[0]
		Local $lPtr = $aAgents[$i]
		If $lPtr = 0 Then ContinueLoop
		Local $iAgentID = Agent_GetAgentInfo($lPtr, "ID")
		If $iAgentID = 0 Then ContinueLoop
		If $excludeself And $iAgentID = $iMyID Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> $aAllegiance Then ContinueLoop
		If Agent_GetDistance($lPtr) > $aRange Then ContinueLoop

		Local $iCount = Agent_GetEffectTypeCount($aEffectType, $lPtr)
		; Flag fallback when effect-array skill-type count misses live hexes/conds/enchants.
		If $iCount <= 0 Then
			Switch $aEffectType
				Case $Hex
					If Agent_GetAgentInfo($lPtr, "IsHexed") Then $iCount = 1
				Case $Condition
					If Agent_GetAgentInfo($lPtr, "IsConditioned") Then $iCount = 1
				Case $Enchantment
					If Agent_GetAgentInfo($lPtr, "Enchanted") Or Agent_GetAgentInfo($lPtr, "IsEnchanted") Then $iCount = 1
			EndSwitch
		EndIf
		If $iCount <= 0 Then ContinueLoop

		If $iCount > $iMax Or ($iCount = $iMax And $iAgentID = $iMyID) Then
			$iMax = $iCount
			$lBestPtr = $lPtr
		EndIf
	Next
	Return $lBestPtr
EndFunc   ;==>Agent_GetMostEffectAgent

; Default includes self. Pass $excludeself=True only for target type 4 (other ally).
Func Agent_GetMostHexedAlly($aRange = 1320, $excludeself = False)
	Return Agent_GetMostEffectAgent($Hex, 1, $aRange, $excludeself)
EndFunc   ;==>Agent_GetMostHexedAlly

Func Agent_GetMostCondsAlly($aRange = 1320, $excludeself = False)
	Return Agent_GetMostEffectAgent($Condition, 1, $aRange, $excludeself)
EndFunc   ;==>Agent_GetMostCondsAlly

Func Agent_GetMostEnchantedEnemy($aRange = 1320)
	Return Agent_GetMostEffectAgent($Enchantment, 3, $aRange, False)
EndFunc   ;==>Agent_GetMostEnchantedEnemy

#EndRegion Agent Controls


; Living foe that should keep Fight/aggro going — excludes spirits, minions, and TypeMap-spawned.
; Matches old Logic GetNumberOfEnemies (skip $typemap_spawned_enemy) + Agent_GetFilteredAgentArray mode 3.
Func Agent_IsCombatEnemy($aAgent)
	If $aAgent = 0 Then Return False
	If Agent_GetAgentInfo($aAgent, "Allegiance") <> 3 Then Return False
	If Agent_GetAgentInfo($aAgent, "IsDead") Then Return False
	If Agent_GetAgentInfo($aAgent, "IsSpirit") Or Agent_GetAgentInfo($aAgent, "IsMinion") Then Return False
	If Agent_IsSpiritAgent($aAgent) Then Return False
	If BitAND(Agent_GetAgentInfo($aAgent, "TypeMap"), $typemap_spawned_enemy) Then Return False
	If Agent_IsWormAgent($aAgent) Then Return False
	Return True
EndFunc   ;==>Agent_IsCombatEnemy

Func Agent_IsEnemyNear($aRange = 1320)
	Return Agent_GetNumberOfEnemies($aRange) > 0
EndFunc

Func Agent_NoEnemiesAround($aRange = 1320)
	Return Agent_GetNumberOfEnemies($aRange) = 0
EndFunc

Func Agent_GetNumberOfEnemies($aRange = 3000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Not Agent_IsCombatEnemy($iID) Then ContinueLoop
		If Agent_GetDistance($iID) <= $aRange Then $iCount += 1
	Next
	Return $iCount
EndFunc

Func Agent_GetNumberOfEnemiesNearAgent($aRange = 3000, $aAgent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	Local $iRefID = Agent_GetAgentInfo($aAgent, "ID")
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Not Agent_IsCombatEnemy($iID) Then ContinueLoop
		If Agent_GetDistance($iID, $iRefID) <= $aRange Then $iCount += 1
	Next
	Return $iCount
EndFunc

Func Agent_GetNumberOfAllies($aRange = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And Agent_GetDistance($iID) <= $aRange And Not Agent_GetAgentInfo($iID, "IsDead") Then
			$iCount += 1
		EndIf
	Next
	Return $iCount
EndFunc

; Party members only (player/heroes/hench with party TypeMap), living, within range.
; Prefer this when comparing against Party_GetPartyContextInfo("TotalPartySize").
Func Agent_GetNumberOfPartyInRange($aRange = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To $aAgents[0]
		Local $p = $aAgents[$i]
		If Agent_GetAgentInfo($p, "Allegiance") <> 1 Then ContinueLoop
		If Not Agent_GetAgentInfo($p, "CanBeViewedInPartyWindow") Then ContinueLoop
		If Agent_GetAgentInfo($p, "IsDead") Then ContinueLoop
		If Agent_GetDistance($p) > $aRange Then ContinueLoop
		$iCount += 1
	Next
	Return $iCount
EndFunc

Func Agent_GetNumberOfDeadAllies($aRange = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And Agent_GetDistance($iID) <= $aRange And Agent_GetAgentInfo($iID, "Dead") Then
			$iCount += 1
		EndIf
	Next
	Return $iCount
EndFunc

; Nearest living other ally (excludes self). Returns ptr.
; Enemies: use Modules Agent_GetNearestAgent($aAgent, 0xDB, 3) — do not reimplement here.
Func Agent_GetNearestAlly($aAgent = -2)
	Return Agent_GetNearestAgent($aAgent, 0xDB, 1)
EndFunc   ;==>Agent_GetNearestAlly

; Nearest dead ally within $aRange. Returns ptr. Args: ($aRange, $aAgent).
Func Agent_GetNearestDeadAlly($aRange = 5000, $aAgent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $lBestPtr = 0, $iMin = 999999
	Local $iRefID = Agent_GetAgentInfo($aAgent, "ID")
	For $i = 1 To $aAgents[0]
		Local $lPtr = $aAgents[$i]
		If $lPtr = 0 Then ContinueLoop
		Local $iID = Agent_GetAgentInfo($lPtr, "ID")
		If $iID = 0 Or $iID = $iRefID Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> 1 Then ContinueLoop
		If Not Agent_GetAgentInfo($lPtr, "IsDead") And Not Agent_GetAgentInfo($lPtr, "Dead") Then ContinueLoop
		Local $iD = Agent_GetDistance($lPtr, $aAgent)
		If $iD > $aRange Then ContinueLoop
		If $iD < $iMin Then
			$iMin = $iD
			$lBestPtr = $lPtr
		EndIf
	Next
	Return $lBestPtr
EndFunc   ;==>Agent_GetNearestDeadAlly

Func Agent_GetFarthestAlly($aMaxDistance = 5000, $aAgent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iBest = 0, $iMax = 0
	Local $iRefID = Agent_GetAgentInfo($aAgent, "ID")
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And $iID <> $iRefID And Not Agent_GetAgentInfo($iID, "IsDead") Then
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
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 3 And Agent_GetDistance($iID) <= $aRange Then
			; Simple boss check via type or model; extend as needed
			If BitAND(Agent_GetAgentInfo($iID, "TypeMap"), 0xC00) Then Return $iID
		EndIf
	Next
	Return 0
EndFunc

; Prefer Party_GetPartyContextInfo / Party_GetMyPartyHeroInfo at call sites.
; Keep Logic names to avoid colliding with UtilityAI Party_GetSize/HeroCount/HeroAgentID.
Func GetPartySize()
	Return Party_GetPartyContextInfo("TotalPartySize")
EndFunc

Func GetHeroCount()
	Return Party_GetPartyContextInfo("HeroCount")
EndFunc

Func GetHeroID($aHeroNumber)
	Return Party_GetMyPartyHeroInfo($aHeroNumber, "AgentID")
EndFunc

Func Agent_GetHero($aHeroNumber)
	Return Agent_GetAgentPtr(GetHeroID($aHeroNumber))
EndFunc

Func Agent_GetHeroProfession($aHeroNumber, $aSecondary = False)
	Local $iID = GetHeroID($aHeroNumber)
	If $aSecondary Then Return Agent_GetAgentInfo($iID, "Secondary")
	Return Agent_GetAgentInfo($iID, "Primary")
EndFunc

; Live party average HP via Agent_GetAgentInfo (does not use UAI agent cache).
; Distinct from UtilityAI Party_GetAverageHealth().
Func Party_GetPartyHealth()
	Local $iSize = Party_GetPartyContextInfo("TotalPartySize")
	If $iSize = 0 Then Return 0
	Local $fSum = 0, $iCounted = 0
	For $i = 1 To $iSize
		Local $iID = Party_GetMemberAgentID($i)
		If $iID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($iID, "IsDead") Then ContinueLoop
		$fSum += Agent_GetAgentInfo($iID, "HP")
		$iCounted += 1
	Next
	If $iCounted = 0 Then Return 0
	Return Round($fSum / $iCounted, 3)
EndFunc

Func Party_IsDefeated()
	Return Party_GetPartyHealth() = 0
EndFunc

; Living party agents (allegiance ally + party TypeMap bit), same idea as old Logic GetParty().
Func Party_GetLivingAgents()
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $aReturn[1] = [0]
	For $i = 1 To $aAgents[0]
		Local $p = $aAgents[$i]
		If Agent_GetAgentInfo($p, "Allegiance") <> 1 Then ContinueLoop
		If Not Agent_GetAgentInfo($p, "CanBeViewedInPartyWindow") Then ContinueLoop
		$aReturn[0] += 1
		ReDim $aReturn[$aReturn[0] + 1]
		$aReturn[$aReturn[0]] = $p
	Next
	Return $aReturn
EndFunc

Func Agent_GetByPlayerNumber($aPlayerNumber, $aRange = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "PlayerNumber") = $aPlayerNumber And Agent_GetDistance($iID) <= $aRange Then
			Return $iID
		EndIf
	Next
	Return 0
EndFunc

Func Agent_GetNearestSignpostToXY($x, $y)
	; Simplified: nearest non-enemy, non-player agent near XY
	Local $aAgents = Agent_GetAgentArray(0x200)
	Local $iBest = 0, $iMin = 999999
	For $i = 1 To $aAgents[0]
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

; Controlled spirits/minions/pets (Logic GetMinionPtrArray via party Others array).
Func Agent_GetMinionPtrArray($aAllegiance = $allegiance_spirit, $aRange = 5000)
	Local $lOthersPtr = Party_GetMyPartyInfo("ArrayOthersPartyMember")
	Local $lOthersSize = Party_GetMyPartyInfo("ArrayOthersPartyMemberSize")
	Local $lAgentArray[1] = [0]
	If $lOthersPtr = 0 Or $lOthersSize <= 0 Then Return $lAgentArray

	For $i = 0 To $lOthersSize - 1
		Local $lAgentID = Memory_Read($lOthersPtr + ($i * 0x4), "dword")
		Local $lPtr = Agent_GetAgentPtr($lAgentID)
		If $lPtr = 0 Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> $aAllegiance Then ContinueLoop
		If Agent_GetDistance($lPtr) > $aRange Then ContinueLoop
		$lAgentArray[0] += 1
		ReDim $lAgentArray[$lAgentArray[0] + 1]
		$lAgentArray[$lAgentArray[0]] = $lPtr
	Next
	Return $lAgentArray
EndFunc

Func Agent_GetMySpiritCount($aRange = 5000)
	Local $lArr = Agent_GetMinionPtrArray($allegiance_spirit, $aRange)
	Return $lArr[0]
EndFunc

Func Agent_GetMyMinionCount($aRange = 5000)
	Local $lArr = Agent_GetMinionPtrArray($allegiance_minion, $aRange)
	Return $lArr[0]
EndFunc

; Offensive and/or defensive ritualist spirits I control (Logic GetNumberOfSpirits).
Func Agent_GetNumberOfSpirits($aRange = 5000, $Offensive = True, $Defensive = True)
	Local $lCount = 0
	Local $lMinionPtrArray = Agent_GetMinionPtrArray($allegiance_spirit, $aRange)

	For $i = 1 To $lMinionPtrArray[0]
		Switch Agent_GetAgentInfo($lMinionPtrArray[$i], "PlayerNumber")
			Case $PID_Empowerment, $PID_Rejuvenation, $PID_Displacement, $PID_Life, $PID_Preservation _
					, $PID_Recuperation, $PID_Shelter, $PID_Union, $PID_Restoration
				If $Defensive Then $lCount += 1
			Case $PID_Agony, $PID_Anger, $PID_Anguish, $PID_Bloodsong, $PID_Destruction _
					, $PID_Earthbind, $PID_Hate, $PID_Pain, $PID_Suffering, $PID_Vampirism
				If $Offensive Then $lCount += 1
			Case $PID_Dissonance, $PID_Disenchantment, $PID_Shadowsong, $PID_Wanderlust
				$lCount += 1
		EndSwitch
	Next
	Return $lCount
EndFunc

Func Agent_GetNumberOfPressureSpirits($aRange = 5000)
	Return Agent_GetNumberOfSpirits($aRange, True, False)
EndFunc

Func Agent_GetNumberOfSurvivalSpirits($aRange = 5000)
	Return Agent_GetNumberOfSpirits($aRange, False, True)
EndFunc

Func Agent_GetLowestSpirit()
	Local $lHP, $lLowestHP = 1000
	Local $LowestSpiritPtr = 0
	Local $lSpiritPtrArray = Agent_GetMinionPtrArray($allegiance_spirit)
	If $lSpiritPtrArray[0] = 0 Then Return 0
	For $i = 1 To $lSpiritPtrArray[0]
		$lHP = Agent_GetAgentInfo($lSpiritPtrArray[$i], "HP")
		If $lHP < $lLowestHP Then
			$LowestSpiritPtr = $lSpiritPtrArray[$i]
			$lLowestHP = $lHP
		EndIf
	Next
	Return $LowestSpiritPtr
EndFunc

Func Agent_GetNearestSpirit($aAgent = -2)
	Return Agent_GetNearestAgent($aAgent, 0xDB, $allegiance_spirit)
EndFunc

Func GetNearestSpirit($aAgent = -2)
	Return Agent_GetNearestSpirit($aAgent)
EndFunc

Func Agent_GetNearestMinionAlly($aAgent = -2)
	Return Agent_GetNearestAgent($aAgent, 0xDB, $allegiance_minion)
EndFunc

Func GetNearestMinionAlly($aAgent = -2)
	Return Agent_GetNearestMinionAlly($aAgent)
EndFunc

Func GetMySpiritCount($aRange = 5000)
	Return Agent_GetMySpiritCount($aRange)
EndFunc

Func GetNumberOfPressureSpirits($aRange = 5000)
	Return Agent_GetNumberOfPressureSpirits($aRange)
EndFunc

Func GetLowestSpirit()
	Return Agent_GetLowestSpirit()
EndFunc


Func Agent_GetPriorityTarget($aRange = 1320)
	Return Agent_GetNearestAgent(-2, 0xDB, 3)
EndFunc

Func Agent_GetArray($aMode = 0, $aType = 0xDB, $aAllegiance = 3, $aRange = 1320)
	; Thin wrapper around Agent_GetAgentArray with basic filters
	Local $aAgents = Agent_GetAgentArray($aType)
	Local $aOut[1] = [0]
	For $i = 1 To $aAgents[0]
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

; Monk / Ritualist (primary or secondary) — preferred Shame / Mark of Subversion targets.
Func Agent_IsSupportCasterProfession($aAgent = -2)
	If $aAgent = 0 Then Return False
	Local $iPri = Number(Agent_GetAgentInfo($aAgent, "Primary"))
	Local $iSec = Number(Agent_GetAgentInfo($aAgent, "Secondary"))
	Switch $iPri
		Case $Monk, $Ritualist
			Return True
	EndSwitch
	Switch $iSec
		Case $Monk, $Ritualist
			Return True
	EndSwitch
	Return False
EndFunc   ;==>Agent_IsSupportCasterProfession

; Burrowed/unattackable foe: alive flag but no HP (worms etc).
Func Agent_IsWormAgent($aAgent = -2)
	If $aAgent = 0 Then Return True
	If Agent_GetAgentInfo($aAgent, "IsDead") Then Return False
	Return Agent_GetAgentInfo($aAgent, "HP") <= 0
EndFunc

Func IsWormAgent($aAgent = -2)
	Return Agent_IsWormAgent($aAgent)
EndFunc

; Spirit/minion via Npc model flags (PlayerNumber indexes NpcStruct).
Func Agent_IsSpiritAgent($aAgent = -2)
	Return Agent_GetNpcInfo(Agent_GetAgentInfo($aAgent, "PlayerNumber"), "IsSpirit")
EndFunc

Func IsSpiritAgent($aAgent = -2)
	Return Agent_IsSpiritAgent($aAgent)
EndFunc



