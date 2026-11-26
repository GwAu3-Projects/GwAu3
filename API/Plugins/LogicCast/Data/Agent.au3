#include-once
; Fat agent helpers (party / targeting / counting). Thin field getters: Modules\Data\GwAu3_Data_Wrappers.au3 (X/Y/XY).

#Region Agent Controls

; Agent_GetBestTarget lives in Modules/Data/GwAu3_Data_Agent.au3 - do not redefine here.

; Logic GetNearestDistance — nearest living foe via GetNearestAgent (mode 3: dead/spirit/minion dropped).
Func Agent_GetNearestDistance($a_i_Allegiance = 3)
	Local $p = Agent_GetNearestAgent(-2, 0xDB, $a_i_Allegiance)
	If $p <> 0 Then Return Agent_GetDistance($p)
	Return 999999
EndFunc

;~Description: Returns the party member with the lowest HP
; $a_b_ExcludeSelf = True ? "other ally" (target type 4). Same arg order as MostHexed/MostConds.
Func Agent_GetLowestAlly($a_i_Range = 1320, $a_b_ExcludeSelf = False)
	Local $lLowestHP = 1000
	Local $LowestallyPtr = 0
	Local $lMyID = Agent_GetMyID()
	Local $lAgentPtrArray = Agent_GetArray(3, 0xDB, $allegiance_ally, $a_i_Range)

	For $i = 1 To $lAgentPtrArray[0]
		Local $lPtr = $lAgentPtrArray[$i]
		If $a_b_ExcludeSelf And Agent_ConvertID($lPtr) = $lMyID Then ContinueLoop
		Local $lHP = Agent_GetAgentInfo($lPtr, "HP")
		If $lHP < $lLowestHP Then
			$LowestallyPtr = $lPtr
			$lLowestHP = $lHP
		EndIf
	Next
	Return $LowestallyPtr
EndFunc   ;==>Agent_GetLowestAlly

Func Agent_GetHighestAlly($a_i_Range = 1320, $a_b_ExcludeSelf = False)
	Local $lHighestHP = 0
	Local $HighestAllyPtr = 0
	Local $lMyID = Agent_GetMyID()
	Local $lAgentPtrArray = Agent_GetArray(3, 0xDB, $allegiance_ally, $a_i_Range)

	For $i = 1 To $lAgentPtrArray[0]
		Local $lPtr = $lAgentPtrArray[$i]
		If $a_b_ExcludeSelf And Agent_ConvertID($lPtr) = $lMyID Then ContinueLoop
		Local $lHP = Agent_GetAgentInfo($lPtr, "HP")
		If $lHP > $lHighestHP Then
			$HighestAllyPtr = $lPtr
			$lHighestHP = $lHP
		EndIf
	Next
	Return $HighestAllyPtr
EndFunc   ;==>Agent_GetHighestAlly

;~Description: Returns the enemy with the lowest HP
Func Agent_GetLowestEnemy($a_i_Range = 1320)
	Local $lLowest = 0, $lLowestHP = 1
	Local $lAgentPtrArray = Agent_GetAgentArray(0xDB)
	For $i = 1 To $lAgentPtrArray[0]
		If Agent_GetAgentInfo($lAgentPtrArray[$i], "Allegiance") <> 3 Then ContinueLoop
		If Agent_GetDistance($lAgentPtrArray[$i]) > $a_i_Range Then ContinueLoop
		Local $lHP = Agent_GetAgentInfo($lAgentPtrArray[$i], "HP")
		If $lHP < $lLowestHP Then
			$lLowestHP = $lHP
			$lLowest = $lAgentPtrArray[$i]
		EndIf
	Next
	Return $lLowest
EndFunc   ;==>Agent_GetLowestEnemy

;~Description: Most-balled living foe who is not already hexed.
Func Agent_GetNoHexEnemy($a_i_Range = 1320)
	Return Agent_GetBestTargetByRole($a_i_Range, "general", True)
EndFunc   ;==>Agent_GetNoHexEnemy

; Not martial. Most balled. Already-hexed foes are skipped.
Func Agent_GetBestCasterTarget($a_i_Range = 1320)
	Return Agent_GetBestTargetByRole($a_i_Range, "caster", True)
EndFunc   ;==>Agent_GetBestCasterTarget

; Martial weapon. Most balled. Already-hexed foes are skipped.
Func Agent_GetBestMartialTarget($a_i_Range = 1320)
	Return Agent_GetBestTargetByRole($a_i_Range, "martial", True)
EndFunc   ;==>Agent_GetBestMartialTarget

; Monk or Ritualist (primary or secondary) who is not martial.
Func Agent_GetBestHealerTarget($a_i_Range = 1320)
	Return Agent_GetBestTargetByRole($a_i_Range, "healer", True)
EndFunc   ;==>Agent_GetBestHealerTarget

; Hexes only. Signets stay in Agent_GetBestSignetTarget.
; Kind comes from the skill, then AoERange decides most-balled vs closest.
; No matching foe returns 0.
Func Agent_GetBestHexTarget($a_i_SkillID, $a_i_Range = 1320)
	Local $iSkill = Number($a_i_SkillID)
	Local $sKind = Agent_GetHexShutdownType($iSkill)
	Local $bAoe = Number(Skill_GetSkillInfo($iSkill, "AoeRange")) > 0
	Return Agent_GetBestTargetByRole($a_i_Range, $sKind, True, $bAoe)
EndFunc   ;==>Agent_GetBestHexTarget

; healer = Monk/Ritualist support caster (non-martial).
; guilt_mistrust = non-Monk/non-Ritualist, non-martial.
; caster = not martial (spell shutdown).
; martial = melee slow or attack-speed shutdown.
; both = hits casters and martials (no weapon filter).
Func Agent_GetHexShutdownType($a_i_SkillID)
	Switch Number($a_i_SkillID)
		Case $Shame, $Mark_of_Subversion
			Return "healer"
		Case $Guilt, $Mistrust, $Mistrust_PvP
			Return "guilt_mistrust"
		Case $Diversion, $Visions_of_Regret, $Visions_of_Regret_PvP, $Backfire, $Soul_Leech, _
				$Spiteful_Spirit, $Migraine, $Migraine_PvP, $Mind_Freeze, $Mind_Freeze_PvP, _
				$Arcane_Conundrum, $Enchanters_Conundrum, $Enchanters_Conundrum_PvP, $Arcane_Languor
			Return "caster"
		; Next skill of any kind is slowed or disabled, so casters and martials both qualify.
		Case $Sum_of_All_Fears, $Sum_of_All_Fears_Gwen, $Calculated_Risk, $Calculated_Risk_PvP, _
				$Frustration, $Frustration_PvP, $Price_of_Pride
			Return "both"
		; Attack-speed / attack-punish hexes (Effect1 does not flag these).
		; Shared Burden applies Weakness (slower attacks and movement) and its Effect1 is 0.
		Case $Empathy, $Empathy_PvP, $Clumsiness, $Ineptitude, $Wandering_Eye, $Wandering_Eye_PvP, _
				$Insidious_Parasite, $Blurred_Vision, $Faintheartedness, $Spirit_Shackles, _
				$Dulled_Weapon, $Soothing_Images, $Meekness, $Pacifism, _
				$Spirit_of_Failure, $Images_of_Remorse, $Reckless_Haste, _
				$Shared_Burden, $Shared_Burden_PvP, $Shared_Burden_Gwen
			Return "martial"
		; Movement snares. Grasping Earth is also Effect1 bit 64.
		Case $Grasping_Earth, $Earthen_Shackles, $Binding_Chains, $Snaring_Web, $Shadow_Prison, _
				$Dark_Prison, $Ice_Prison, $Icy_Shackles, $Teinais_Prison, $Winters_Embrace, _
				$Crystal_Snare, $Corsairs_Net, $Weaken_Knees, $Stolen_Speed, $Stolen_Speed_PvP, _
				$Kitahs_Burden, $Shadow_of_Fear
			Return "martial"
	EndSwitch

	; $aArray_Of_Skill_Data column Effect1. 64 = slower movement. 2048 = Slowed.
	; Mind Freeze is already returned as caster above; leftover 2048 hexes are snares or attack slows.
	Local $iEffect = Number(Skill_GetSkillInfo($a_i_SkillID, "Effect1"))
	If BitAND($iEffect, 64) Or BitAND($iEffect, 2048) Then Return "martial"
	Return "general"
EndFunc   ;==>Agent_GetHexShutdownType

; Signets. Rage wants an adrenal profession. Clumsiness wants a martial foe who is attacking.
; Anything else is the most-balled living foe. No match returns 0.
Func Agent_GetBestSignetTarget($a_i_SkillID, $a_i_Range = 1320)
	Switch Number($a_i_SkillID)
		Case $Signet_of_Rage
			Return Agent_GetBestTargetByRole($a_i_Range, "adrenal", False)
		Case $Signet_of_Clumsiness, $Signet_of_Clumsiness_PvP
			Return Agent_GetBestTargetByRole($a_i_Range, "attacking", True)
		Case $Unnatural_Signet, $Unnatural_Signet_PvP
			Return Agent_GetBestTargetByRole($a_i_Range, "hexed", False)
		Case Else
			Return Agent_GetBestTargetByRole($a_i_Range, "general", False)
	EndSwitch
EndFunc   ;==>Agent_GetBestSignetTarget

; Shared pull: Agent_GetFilteredAgentArray mode 3 (living foes in range, spirits/minions dropped).
; $a_b_PreferBall: AoE hexes keep the densest ball. Single-target hexes keep the closest valid foe.
Func Agent_GetBestTargetByRole($a_i_Range = 1320, $a_s_Kind = "general", $a_b_NoHex = True, $a_b_PreferBall = True)
	Local $aAgents = Agent_GetFilteredAgentArray(3, 0xDB, 3, $a_i_Range)
	If Not IsArray($aAgents) Or $aAgents[0] = 0 Then Return 0

	Local $lBest = 0, $lBestBall = -1, $lBestDist = 999999
	For $i = 1 To $aAgents[0]
		Local $lPtr = $aAgents[$i]
		If $lPtr = 0 Or Agent_IsWormAgent($lPtr) Then ContinueLoop
		If $a_b_NoHex And Agent_GetAgentInfo($lPtr, "IsHexed") Then ContinueLoop

		Local $bIsMartial = Agent_IsMartial($lPtr) Or Agent_IsMartialPrimary($lPtr)
		Local $iPrimary = Number(Agent_GetAgentInfo($lPtr, "Primary"))

		Switch $a_s_Kind
			Case "healer"
				If $bIsMartial Or Not Agent_IsSupportCasterProfession($lPtr) Then ContinueLoop
			Case "guilt_mistrust"
				If $bIsMartial Or $iPrimary = 0 Or Agent_IsSupportCasterProfession($lPtr) Then ContinueLoop
			Case "caster"
				If $bIsMartial Or $iPrimary = 0 Then ContinueLoop
			Case "martial"
				If Not $bIsMartial Then ContinueLoop
			Case "attacking"
				If Not $bIsMartial Or Not Agent_GetAgentInfo($lPtr, "IsAttacking") Then ContinueLoop
			Case "adrenal"
				If Not Agent_IsAdrenalProfession($lPtr) Then ContinueLoop
			Case "hexed"
				If Not Agent_GetAgentInfo($lPtr, "IsHexed") Then ContinueLoop
			Case "both"
				; Casters and martials both qualify.
		EndSwitch

		Local $iBall = Agent_GetNumberOfEnemiesNearAgent(300, $lPtr)
		Local $fDist = Agent_GetDistance($lPtr)
		Local $bBetter = False
		If $a_b_PreferBall Then
			$bBetter = ($iBall > $lBestBall) Or ($iBall = $lBestBall And $fDist < $lBestDist)
		Else
			$bBetter = ($fDist < $lBestDist)
		EndIf
		If $bBetter Then
			$lBestBall = $iBall
			$lBestDist = $fDist
			$lBest = $lPtr
		EndIf
	Next
	Return $lBest
EndFunc   ;==>Agent_GetBestTargetByRole

; Enchanted foe in range, preferring the most balled. Isolated monks still qualify (ball count 0).
Func Agent_GetBalledEnchantedEnemy($a_i_Range = 1320)
    Local $lBestTargetPtr = 0
    Local $iMaxBalledNumber = -1
    Local $lAgentPtrArray = Agent_GetAgentArray(0xDB) ; living agents only

    For $i = 1 To $lAgentPtrArray[0]
        Local $lPtr = $lAgentPtrArray[$i]

        ; Verify allegiance (3 = enemy) and range
        If Agent_GetAgentInfo($lPtr, "Allegiance") <> 3 Then ContinueLoop
        If Agent_GetAgentInfo($lPtr, "IsDead") Then ContinueLoop
        If Agent_GetDistance($lPtr) > $a_i_Range Then ContinueLoop

        ; Check if enchanted directly via pointer
        If Not Agent_GetAgentInfo($lPtr, "IsEnchanted") Then ContinueLoop

        ; Prefer denser balls; start at -1 so isolated (0 nearby) still wins when alone.
        Local $iBalledNumber = Agent_GetNumberOfEnemiesNearAgent(300, $lPtr)
        If $iBalledNumber > $iMaxBalledNumber Then
            $iMaxBalledNumber = $iBalledNumber
            $lBestTargetPtr = $lPtr
        EndIf
    Next
    If $lBestTargetPtr <> 0 Then Return $lBestTargetPtr
    Return Agent_GetMostEnchantedEnemy($a_i_Range)
EndFunc   ;==>Agent_GetBalledEnchantedEnemy

Func Agent_GetMostBalledCastingEnemy($a_i_Range = 1320)
	Return Agent_GetBestTarget($a_i_Range, True)
EndFunc   ;==>Agent_GetMostBalledCastingEnemy

Func Agent_GetMostBalledHexedEnemy($a_i_Range = 1320)
	Return Agent_GetBestTarget($a_i_Range, False, False, True)
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
Func Agent_GetMostBalledHexedAlly($a_i_Range = 1320, $a_b_ExcludeSelf = False)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $lBestNear = 0, $lBestNearEnemies = -1
	Local $lBestAny = 0
	Local $lMyID = Agent_GetMyID()
	If Not IsArray($aAgents) Or $aAgents[0] = 0 Then Return 0

	For $i = 1 To $aAgents[0]
		Local $lPtr = $aAgents[$i]
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> 1 Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "IsDead") Then ContinueLoop
		If $a_b_ExcludeSelf And Agent_ConvertID($lPtr) = $lMyID Then ContinueLoop
		If Not Agent_GetAgentInfo($lPtr, "IsHexed") Then ContinueLoop
		If Agent_GetDistance($lPtr) > $a_i_Range Then ContinueLoop

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
	Return Agent_GetMostHexedAlly($a_i_Range, $a_b_ExcludeSelf)
EndFunc   ;==>Agent_GetMostBalledHexedAlly

Func Agent_NeedEchoAlly($a_i_SkillID)
	Local $lHeroID
	Local $iSkill = Number($a_i_SkillID)

	Local $iLead = Number(Attribute_GetPartyAttributeInfo($Leadership, 0, "Level"))
	If $iSkill = Number($Heroic_Refrain) And $iLead < 20 Then Return Agent_GetAgentPtr(-2)

	Local $lHeroCount = Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
	For $heronumber = 1 To $lHeroCount
		$lHeroID = GetHeroID($heronumber)
		If $lHeroID = 0 Or Agent_GetAgentInfo($lHeroID, "IsDead") Then ContinueLoop
		If Not Skill_HasEffect($iSkill, $lHeroID) Then Return Agent_GetAgentPtr($lHeroID)
	Next
	Return 0
EndFunc   ;==>Agent_NeedEchoAlly

;~Description: Returns the ally with the most Conditions on them

; Counts effects of a given skill type on an agent.
; NOTE: Effect entry SkillID still needs a raw read (same as GwAu3_Data_Agent internals);
; candidate for Agent_GetEffectSkillID($effectPtr) if promoted to Modules.
Func Agent_GetEffectTypeCount($a_i_EffectType, $a_h_Agent = -2)
    Local $l_p_EffectArray = Agent_GetAgentEffectArrayInfo($a_h_Agent, "EffectArray")
    Local $l_i_EffectCount = Agent_GetAgentEffectArrayInfo($a_h_Agent, "EffectArraySize")

    If $l_p_EffectArray = 0 Or $l_i_EffectCount = 0 Then Return 0

    Local $iCount = 0
    For $j = 0 To $l_i_EffectCount - 1
        Local $iSkillID = Memory_Read($l_p_EffectArray + ($j * 0x18), "long")
        If $iSkillID > 0 And Skill_GetSkillInfo($iSkillID, "SkillType") = $a_i_EffectType Then
            $iCount += 1
        EndIf
    Next
    Return $iCount
EndFunc  ;==>GetAgentEffectCount

; Returns agent ptr with the most effects of a specific type, within $a_i_Range.
; $a_b_ExcludeSelf=True only for skill target type 4 (other ally). Default includes self.
; On equal counts, prefer self so hex/cond remove can land on us.
Func Agent_GetMostEffectAgent($a_i_EffectType, $a_i_Allegiance = 1, $a_i_Range = 1320, $a_b_ExcludeSelf = False)
	Local $iMyID = Agent_GetMyID()
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $lBestPtr = 0, $iMax = -1

	For $i = 1 To $aAgents[0]
		Local $lPtr = $aAgents[$i]
		If $lPtr = 0 Then ContinueLoop
		Local $iAgentID = Agent_GetAgentInfo($lPtr, "ID")
		If $iAgentID = 0 Then ContinueLoop
		If $a_b_ExcludeSelf And $iAgentID = $iMyID Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> $a_i_Allegiance Then ContinueLoop
		If Agent_GetDistance($lPtr) > $a_i_Range Then ContinueLoop

		Local $iCount = Agent_GetEffectTypeCount($a_i_EffectType, $lPtr)
		; Flag fallback when effect-array skill-type count misses live hexes/conds/enchants.
		If $iCount <= 0 Then
			Switch $a_i_EffectType
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

; Default includes self. Pass $a_b_ExcludeSelf=True only for target type 4 (other ally).
Func Agent_GetMostHexedAlly($a_i_Range = 1320, $a_b_ExcludeSelf = False)
	Return Agent_GetMostEffectAgent($Hex, 1, $a_i_Range, $a_b_ExcludeSelf)
EndFunc   ;==>Agent_GetMostHexedAlly

Func Agent_GetMostCondsAlly($a_i_Range = 1320, $a_b_ExcludeSelf = False)
	Return Agent_GetMostEffectAgent($Condition, 1, $a_i_Range, $a_b_ExcludeSelf)
EndFunc   ;==>Agent_GetMostCondsAlly

Func Agent_GetMostEnchantedEnemy($a_i_Range = 1320)
	Return Agent_GetMostEffectAgent($Enchantment, 3, $a_i_Range, False)
EndFunc   ;==>Agent_GetMostEnchantedEnemy

#EndRegion Agent Controls


; Logic IsEnemyNear — living foes only (FilteredAgentArray mode 3 drops dead/spirit/minion).
Func Agent_IsEnemyNear($a_i_Range = 1320)
	Return Agent_GetNumberOfEnemies($a_i_Range) > 0
EndFunc

Func Agent_NoEnemiesAround($a_i_Range = 1320)
	Return Agent_GetNumberOfEnemies($a_i_Range) = 0
EndFunc

; Logic GetNumberOfEnemies — same mode-3 living-enemy array, not a raw AgentArray scan.
Func Agent_GetNumberOfEnemies($a_i_Range = 3000)
	Local $a = Agent_GetFilteredAgentArray(3, 0xDB, 3, $a_i_Range)
	If Not IsArray($a) Then Return 0
	Return $a[0]
EndFunc

Func Agent_GetNumberOfEnemiesNearAgent($a_i_Range = 3000, $a_h_Agent = -2)
	Local $a = Agent_GetFilteredAgentArray(3, 0xDB, 3, $a_i_Range, $a_h_Agent)
	If Not IsArray($a) Then Return 0
	Return $a[0]
EndFunc

; Living enemies within $a_i_Range of a waypoint (Logic GetNumberOfEnemiesNearXY).
Func Agent_GetNumberOfEnemiesNearXY($a_f_X, $a_f_Y, $a_i_Range = 3000)
	Local $a = Agent_GetFilteredAgentArray(3, 0xDB, 3, $a_i_Range, Agent_GetAgentPtr(-2), 0, $a_f_X, $a_f_Y)
	If Not IsArray($a) Then Return 0
	Return $a[0]
EndFunc   ;==>Agent_GetNumberOfEnemiesNearXY

Func Agent_GetNumberOfAllies($a_i_Range = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And Agent_GetDistance($iID) <= $a_i_Range And Not Agent_GetAgentInfo($iID, "IsDead") Then
			$iCount += 1
		EndIf
	Next
	Return $iCount
EndFunc

; Living allegiance-1 allies within range of XY (Logic GetNumberOfAlliesNearXY).
Func Agent_GetNumberOfAlliesNearXY($a_i_Range = 3000, $a_f_X = Default, $a_f_Y = Default)
	If $a_f_X = Default Then $a_f_X = X()
	If $a_f_Y = Default Then $a_f_Y = Y()
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To $aAgents[0]
		Local $p = $aAgents[$i]
		If Agent_GetAgentInfo($p, "Allegiance") <> 1 Then ContinueLoop
		If Agent_GetAgentInfo($p, "IsDead") Then ContinueLoop
		If Agent_GetDistanceToXY($a_f_X, $a_f_Y, $p) > $a_i_Range Then ContinueLoop
		$iCount += 1
	Next
	Return $iCount
EndFunc

; Party members only (player/heroes/hench with party TypeMap), living, within range.
; Prefer this when comparing against Party_GetPartyContextInfo("TotalPartySize").
Func Agent_GetNumberOfPartyInRange($a_i_Range = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To $aAgents[0]
		Local $p = $aAgents[$i]
		If Agent_GetAgentInfo($p, "Allegiance") <> 1 Then ContinueLoop
		If Not Agent_GetAgentInfo($p, "CanBeViewedInPartyWindow") Then ContinueLoop
		If Agent_GetAgentInfo($p, "IsDead") Then ContinueLoop
		If Agent_GetDistance($p) > $a_i_Range Then ContinueLoop
		$iCount += 1
	Next
	Return $iCount
EndFunc

Func Agent_GetNumberOfDeadAllies($a_i_Range = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iCount = 0
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And Agent_GetDistance($iID) <= $a_i_Range And Agent_GetAgentInfo($iID, "Dead") Then
			$iCount += 1
		EndIf
	Next
	Return $iCount
EndFunc

; Nearest living other ally (excludes self). Returns ptr.
; Enemies: use Modules Agent_GetNearestAgent($a_h_Agent, 0xDB, 3) — do not reimplement here.
Func Agent_GetNearestAlly($a_h_Agent = -2)
	Return Agent_GetNearestAgent($a_h_Agent, 0xDB, 1)
EndFunc   ;==>Agent_GetNearestAlly

; Nearest dead ally within $a_i_Range. Returns ptr. Args: ($a_i_Range, $a_h_Agent).
Func Agent_GetNearestDeadAlly($a_i_Range = 5000, $a_h_Agent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $lBestPtr = 0, $iMin = 999999
	Local $iRefID = Agent_GetAgentInfo($a_h_Agent, "ID")
	For $i = 1 To $aAgents[0]
		Local $lPtr = $aAgents[$i]
		If $lPtr = 0 Then ContinueLoop
		Local $iID = Agent_GetAgentInfo($lPtr, "ID")
		If $iID = 0 Or $iID = $iRefID Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> 1 Then ContinueLoop
		If Not Agent_GetAgentInfo($lPtr, "IsDead") And Not Agent_GetAgentInfo($lPtr, "Dead") Then ContinueLoop
		Local $iD = Agent_GetDistance($lPtr, $a_h_Agent)
		If $iD > $a_i_Range Then ContinueLoop
		If $iD < $iMin Then
			$iMin = $iD
			$lBestPtr = $lPtr
		EndIf
	Next
	Return $lBestPtr
EndFunc   ;==>Agent_GetNearestDeadAlly

Func Agent_GetFarthestAlly($a_i_MaxDistance = 5000, $a_h_Agent = -2)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	Local $iBest = 0, $iMax = 0
	Local $iRefID = Agent_GetAgentInfo($a_h_Agent, "ID")
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "Allegiance") = 1 And $iID <> $iRefID And Not Agent_GetAgentInfo($iID, "IsDead") Then
			Local $iD = Agent_GetDistance($iID, $iRefID)
			If $iD > $iMax And $iD <= $a_i_MaxDistance Then
				$iMax = $iD
				$iBest = $iID
			EndIf
		EndIf
	Next
	Return $iBest
EndFunc

; Living boss only — Logic GetBoss matches TypeMap 3072/3073 exactly (dead corpses often keep 0xC00 bits and would softlock Boss / Dungeon Key).
Func Agent_GetBoss($a_i_Range = 5000)
	If Map_GetInstanceInfo("Type") = 0 Then Return 0
	If Agent_GetAgentInfo(-2, "IsDead") Then Return 0
	Local $aAgents = Agent_GetAgentArray(0xDB)
	For $i = 1 To $aAgents[0]
		Local $lAgent = $aAgents[$i]
		If Agent_GetDistance($lAgent) > $a_i_Range Then ContinueLoop
		If Agent_GetAgentInfo($lAgent, "IsDead") Then ContinueLoop
		Local $lTypeMap = Agent_GetAgentInfo($lAgent, "TypeMap")
		; 3072 = boss glow, 3073 = boss + combat stance (Logic exact match — BitAND 0xC00 also hits dead bosses)
		If $lTypeMap = 3072 Or $lTypeMap = 3073 Then Return $lAgent
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

Func GetHeroID($a_i_HeroNumber)
	Return Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID")
EndFunc

Func Agent_GetHero($a_i_HeroNumber)
	Return Agent_GetAgentPtr(GetHeroID($a_i_HeroNumber))
EndFunc

Func Agent_GetHeroProfession($a_i_HeroNumber, $a_b_Secondary = False)
	Local $iID = GetHeroID($a_i_HeroNumber)
	If $a_b_Secondary Then Return Agent_GetAgentInfo($iID, "Secondary")
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

; Logic GetPartyDefeated = party state 0x20 — NOT "party HP == 0" (that false-resigns on a single death).
Func Party_IsDefeated()
	Return Party_GetPartyContextInfo("IsDefeated")
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

Func Agent_GetByPlayerNumber($a_i_PlayerNumber, $a_i_Range = 5000)
	Local $aAgents = Agent_GetAgentArray(0xDB)
	For $i = 1 To $aAgents[0]
		Local $iID = Agent_GetAgentInfo($aAgents[$i], "ID")
		If Agent_GetAgentInfo($iID, "PlayerNumber") = $a_i_PlayerNumber And Agent_GetDistance($iID) <= $a_i_Range Then
			Return $iID
		EndIf
	Next
	Return 0
EndFunc

; Nearest gadget/signpost (Type 0x200) to XY — Logic-main GetNearestSignpostToXY / GetNearestAgentPtr(-2, 0x200, 2, x, y).
; $a_f_MaxDist rejects far gadgets (e.g. Locked Chest across the map when Boss Lock is missing/not yet preferred).
; $a_b_ExcludeChests: skip ExtraTypes mapped in $aChestID (Boss Lock must not grab loot chests).
Func Agent_GetNearestSignpostToXY($a_f_X, $a_f_Y, $a_f_MaxDist = 2500, $a_b_ExcludeChests = False)
	Local $aAgents = Agent_GetAgentArray(0x200)
	Local $iBest = 0, $iMin = 999999999.0
	If Not IsArray($aAgents) Or $aAgents[0] < 1 Then Return 0
	For $i = 1 To $aAgents[0]
		Local $lAgent = $aAgents[$i]
		If $lAgent = 0 Then ContinueLoop
		If Agent_GetAgentInfo($lAgent, "Type") <> 0x200 Then ContinueLoop
		If $a_b_ExcludeChests Then
			Local $lExtra = Agent_GetAgentInfo($lAgent, "ExtraType")
			If IsNumber($lExtra) And $lExtra >= 0 And $lExtra < UBound($aChestID) And $aChestID[$lExtra] <> "" Then ContinueLoop
		EndIf
		Local $iD = Agent_GetDistanceToXY($a_f_X, $a_f_Y, $lAgent)
		If $iD > $a_f_MaxDist Then ContinueLoop
		If $iD < $iMin Then
			$iMin = $iD
			$iBest = $lAgent
		EndIf
	Next
	Return $iBest
EndFunc

; Controlled spirits/minions/pets (Logic GetMinionPtrArray via party Others array).
Func Agent_GetMinionPtrArray($a_i_Allegiance = $allegiance_spirit, $a_i_Range = 5000)
	Local $lOthersPtr = Party_GetMyPartyInfo("ArrayOthersPartyMember")
	Local $lOthersSize = Party_GetMyPartyInfo("ArrayOthersPartyMemberSize")
	Local $lAgentArray[1] = [0]
	If $lOthersPtr = 0 Or $lOthersSize <= 0 Then Return $lAgentArray

	For $i = 0 To $lOthersSize - 1
		Local $lAgentID = Memory_Read($lOthersPtr + ($i * 0x4), "dword")
		Local $lPtr = Agent_GetAgentPtr($lAgentID)
		If $lPtr = 0 Then ContinueLoop
		If Agent_GetAgentInfo($lPtr, "Allegiance") <> $a_i_Allegiance Then ContinueLoop
		If Agent_GetDistance($lPtr) > $a_i_Range Then ContinueLoop
		$lAgentArray[0] += 1
		ReDim $lAgentArray[$lAgentArray[0] + 1]
		$lAgentArray[$lAgentArray[0]] = $lPtr
	Next
	Return $lAgentArray
EndFunc

; NPC model index for spirits/minions — TransmogNpcId bit 0x20000000 overrides PlayerNumber (UAI same).
Func Agent_GetSpiritModelId($a_h_Agent)
	Local $iPN = Number(Agent_GetAgentInfo($a_h_Agent, "PlayerNumber"))
	Local $iTrans = Number(Agent_GetAgentInfo($a_h_Agent, "TransmogNpcId"))
	If BitAND($iTrans, 0x20000000) <> 0 Then Return BitXOR($iTrans, 0x20000000)
	Return $iPN
EndFunc

; True for ritualist spirits (NPC IsSpirit flag and/or known spirit model IDs). Excludes pets.
Func Agent_IsRitualistSpiritAgent($a_h_Agent)
	If $a_h_Agent = 0 Then Return False
	If Number(Agent_GetAgentInfo($a_h_Agent, "Allegiance")) <> $allegiance_spirit Then Return False
	If Number(Agent_GetAgentInfo($a_h_Agent, "LoginNumber")) <> 0 Then Return False
	If Agent_GetAgentInfo($a_h_Agent, "IsDead") Then Return False
	If Agent_IsSpiritAgent($a_h_Agent) Then Return True
	Switch Agent_GetSpiritModelId($a_h_Agent)
		Case $PID_Empowerment, $PID_Rejuvenation, $PID_Displacement, $PID_Life, $PID_Preservation _
				, $PID_Recuperation, $PID_Shelter, $PID_Union, $PID_Restoration _
				, $PID_Agony, $PID_Anger, $PID_Anguish, $PID_Bloodsong, $PID_Destruction _
				, $PID_Earthbind, $PID_Hate, $PID_Pain, $PID_Suffering, $PID_Vampirism _
				, $PID_Dissonance, $PID_Disenchantment, $PID_Shadowsong, $PID_Wanderlust
			Return True
	EndSwitch
	Return False
EndFunc

; True if agent is in *our* party Others list (spirits/minions/pets we own — not other players).
Func Agent_IsMineControlled($a_h_Agent)
	Local $lOthersPtr = Party_GetMyPartyInfo("ArrayOthersPartyMember")
	Local $lOthersSize = Party_GetMyPartyInfo("ArrayOthersPartyMemberSize")
	If $lOthersPtr = 0 Or $lOthersSize <= 0 Then Return False
	Local $lID = Number(Agent_GetAgentInfo($a_h_Agent, "ID"))
	If $lID = 0 Then Return False
	For $i = 0 To $lOthersSize - 1
		If Number(Memory_Read($lOthersPtr + ($i * 0x4), "dword")) = $lID Then Return True
	Next
	Return False
EndFunc

; Living spirits we control in range — agent scan (UAI-style).
Func Agent_GetSpiritPtrArray($a_i_Range = 5000)
	Local $lOut[1] = [0]
	Local $lMax = Agent_GetMaxAgents()
	Local $lHaveOthers = (Party_GetMyPartyInfo("ArrayOthersPartyMemberSize") > 0)
	For $i = 1 To $lMax
		Local $lPtr = Agent_GetAgentPtr($i)
		If $lPtr = 0 Then ContinueLoop
		If Number(Agent_GetAgentInfo($lPtr, "Type")) <> 0xDB Then ContinueLoop
		If Not Agent_IsRitualistSpiritAgent($lPtr) Then ContinueLoop
		If Agent_GetDistance($lPtr) > $a_i_Range Then ContinueLoop
		; Keep only spirits we own; if Others is empty fall back to allegiance-4 spirits in range.
		If $lHaveOthers And Not Agent_IsMineControlled($lPtr) Then ContinueLoop
		$lOut[0] += 1
		ReDim $lOut[$lOut[0] + 1]
		$lOut[$lOut[0]] = $lPtr
	Next
	Return $lOut
EndFunc

Func Agent_GetMySpiritCount($a_i_Range = 5000)
	Local $lArr = Agent_GetSpiritPtrArray($a_i_Range)
	Return $lArr[0]
EndFunc

Func Agent_GetMyMinionCount($a_i_Range = 5000)
	Local $lArr = Agent_GetMinionPtrArray($allegiance_minion, $a_i_Range)
	Return $lArr[0]
EndFunc

; Offensive and/or defensive ritualist spirits I control (Logic GetNumberOfSpirits).
Func Agent_GetNumberOfSpirits($a_i_Range = 5000, $a_b_Offensive = True, $a_b_Defensive = True)
	Local $lCount = 0
	Local $lMinionPtrArray = Agent_GetSpiritPtrArray($a_i_Range)

	For $i = 1 To $lMinionPtrArray[0]
		Switch Agent_GetSpiritModelId($lMinionPtrArray[$i])
			Case $PID_Empowerment, $PID_Rejuvenation, $PID_Displacement, $PID_Life, $PID_Preservation _
					, $PID_Recuperation, $PID_Shelter, $PID_Union, $PID_Restoration
				If $a_b_Defensive Then $lCount += 1
			Case $PID_Agony, $PID_Anger, $PID_Anguish, $PID_Bloodsong, $PID_Destruction _
					, $PID_Earthbind, $PID_Hate, $PID_Pain, $PID_Suffering, $PID_Vampirism
				If $a_b_Offensive Then $lCount += 1
			Case $PID_Dissonance, $PID_Disenchantment, $PID_Shadowsong, $PID_Wanderlust
				$lCount += 1
		EndSwitch
	Next
	Return $lCount
EndFunc

Func Agent_GetNumberOfPressureSpirits($a_i_Range = 5000)
	Return Agent_GetNumberOfSpirits($a_i_Range, True, False)
EndFunc

Func Agent_GetNumberOfSurvivalSpirits($a_i_Range = 5000)
	Return Agent_GetNumberOfSpirits($a_i_Range, False, True)
EndFunc

Func Agent_GetLowestSpirit()
	Local $lHP, $lLowestHP = 1000
	Local $LowestSpiritPtr = 0
	Local $lSpiritPtrArray = Agent_GetSpiritPtrArray()
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

Func Agent_GetNearestSpirit($a_h_Agent = -2)
	Local $lBest = 0, $lBestDist = 999999
	Local $lArr = Agent_GetSpiritPtrArray(5000)
	For $i = 1 To $lArr[0]
		Local $lD = Agent_GetDistance($lArr[$i], $a_h_Agent)
		If $lD < $lBestDist Then
			$lBestDist = $lD
			$lBest = $lArr[$i]
		EndIf
	Next
	Return $lBest
EndFunc

Func Agent_GetNearestMinionAlly($a_h_Agent = -2)
	Return Agent_GetNearestAgent($a_h_Agent, 0xDB, $allegiance_minion)
EndFunc

Func Agent_GetPriorityTarget($a_i_Range = 1320)
	Return Agent_GetNearestAgent(-2, 0xDB, 3)
EndFunc

; Logic GetAgentPtrArray — modes: 0=all, 1=type only, 2=type+allegiance, 3=living in range, 4=effect filter, 5=not allegiance.
; Do NOT use mode 1 with default allegiance; gadgets (0x200) have Allegiance 0, not 3.
Func Agent_GetArray($a_i_Mode = 0, $a_i_Type = 0xDB, $a_i_Allegiance = 3, $a_i_Range = 1320, $a_h_Agent = Default, $a_i_Effect = 0, $a_f_X = Default, $a_f_Y = Default)
	If $a_h_Agent = Default Then $a_h_Agent = Agent_GetAgentPtr(-2)
	If $a_f_X = Default Then $a_f_X = Agent_GetAgentInfo($a_h_Agent, "X")
	If $a_f_Y = Default Then $a_f_Y = Agent_GetAgentInfo($a_h_Agent, "Y")
	Return Agent_GetFilteredAgentArray($a_i_Mode, $a_i_Type, $a_i_Allegiance, $a_i_Range, $a_h_Agent, $a_i_Effect, $a_f_X, $a_f_Y)
EndFunc


; ===== IsMartial wrapper =====
Func Agent_IsMartial($a_h_Agent = -2)
	Local $iWeapon = Agent_GetAgentInfo($a_h_Agent, "WeaponType")
	If $iWeapon >= 1 And $iWeapon <= 7 Then Return True
	Return False
EndFunc

; Warrior / Ranger / Assassin / Paragon / Dervish primary — Guilt/Mistrust wasted (spell-punish hexes).
Func Agent_IsMartialPrimary($a_h_Agent = -2)
	If $a_h_Agent = 0 Then Return False
	Switch Number(Agent_GetAgentInfo($a_h_Agent, "Primary"))
		Case $Warrior, $Ranger, $Assassin, $Paragon, $Dervish
			Return True
	EndSwitch
	Return False
EndFunc   ;==>Agent_IsMartialPrimary

; Monk / Ritualist (primary or secondary) — preferred Shame / Mark of Subversion targets.
Func Agent_IsSupportCasterProfession($a_h_Agent = -2)
	If $a_h_Agent = 0 Then Return False
	Local $iPri = Number(Agent_GetAgentInfo($a_h_Agent, "Primary"))
	Local $iSec = Number(Agent_GetAgentInfo($a_h_Agent, "Secondary"))
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

; Warrior, Ranger, Assassin, Paragon, or Dervish as primary or secondary.
Func Agent_IsAdrenalProfession($a_h_Agent = -2)
	If $a_h_Agent = 0 Then Return False
	Local $iPri = Number(Agent_GetAgentInfo($a_h_Agent, "Primary"))
	Local $iSec = Number(Agent_GetAgentInfo($a_h_Agent, "Secondary"))
	Switch $iPri
		Case $Warrior, $Ranger, $Assassin, $Paragon, $Dervish
			Return True
	EndSwitch
	Switch $iSec
		Case $Warrior, $Ranger, $Assassin, $Paragon, $Dervish
			Return True
	EndSwitch
	Return False
EndFunc   ;==>Agent_IsAdrenalProfession

; Burrowed/unattackable foe: alive flag but no HP (worms etc).
Func Agent_IsWormAgent($a_h_Agent = -2)
	If $a_h_Agent = 0 Then Return True
	If Agent_GetAgentInfo($a_h_Agent, "IsDead") Then Return False
	Return Agent_GetAgentInfo($a_h_Agent, "HP") <= 0
EndFunc

; Spirit/minion via Npc model flags (PlayerNumber / Transmog indexes NpcStruct).
Func Agent_IsSpiritAgent($a_h_Agent = -2)
	Return Agent_GetNpcInfo(Agent_GetSpiritModelId($a_h_Agent), "IsSpirit")
EndFunc



