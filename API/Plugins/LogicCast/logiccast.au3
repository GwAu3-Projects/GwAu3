#Region Cast Functions
Global Enum $all = 0, $ptr, $energyreq, $adrereq, $type, $activation, $aftercast, $target, $hexes, $pressure, $bind, $speedBoost, $survive, $attackskill, $heal, $prot, $bond, $condremove, $hexremove, $enchantremove, $rupt, $hardrupt, $precast, $echochantshout, $junundu, $rezz
Global $SkillBarCache[9][26]
Global $Skillbar[8] = [1, 2, 3, 4, 5, 6, 7, 8]
Global $RuptSlots[9]
Global $ProtSlots[9]
Global $HeroPrecast[100][3]
Global $BiP[3] = [0, 0, 0]
Global $SkillbarSlot[3500]	; used to store the skillslot of skill ID's present in the skill bar
Global $aSkillRange
Global $Summon_Spirits
Global $PressureSpiritSkills = 0
Global $MySkillID = 0
Global $MyTargetID = 0
Global $MyActivation = 0
Global $MyAftercast = 0
Global $AftercastTimer = 501
Global $MysticHealingArray[1][3]
Global $HeroHeals[0][3]
Global $HeroHexRemoval[0][3]
Global $HeroConditionRemoval[0][3]
Global $MysticHealingGroupOne[1][3]
Global $MysticHealingGroupTwo[1][3]
Global $MysticTimerOne
Global $MysticTimerTwo
Global $MysticTimer = TimerInit()
Global $MysticSwitch = 1
Global $HealCount = 0
Global $RuptEventSystem = 0
Global $ProtEventSystem = 0
Global $aLastCast[0][4]   		;for UpdateAndDispatchCasts() [AgentID, SkillID, Timestamp, TargetID]
Global $iLastCastCount = 0 		; UpdateAndDispatchCasts()

Func CacheSkillBar()

; REVIEW: GwAu3 equivalent is Cache_SkillBar() in UtilityAI_Cache.au3. Keeps $SkillBarCache / $RuptSlots for Logic interrupt path.
	Out("Mapping your skill bar")
	$SkillBarCache = 0			; resets the array if we cache a different skill bar
	Global $SkillBarCache[9][26]
	$SkillbarSlot = 0			; resets the array if we cache a different skill bar
	Global $SkillbarSlot[3500]
	$PressureSpiritSkills = 0 	; resets the array if we cache a different skill bar
	$RuptSlots = 0
	Global $RuptSlots[9]		; resets the array if we cache a different skill bar
	$ProtSlots = 0
	Global $ProtSlots[9]		; resets the array if we cache a different skill bar
	Sleep(200)
	For $i = 1 To 8
		$aSkillID = GetSkillbarInfo($i, "SkillID")
		$SkillbarSlot[$aSkillID] = $i
		$SkillBarCache[$i][$all] = $aSkillID ; we store the skillslots of each skill in the first column
		$SkillBarCache[$i][$ptr] = Skill_GetSkillPtr($SkillBarCache[$i][$all])
		$SkillBarCache[$i][$energyreq] = Skill_GetSkillInfo($SkillBarCache[$i][$all], "EnergyCost")
		$SkillBarCache[$i][$adrereq]   = Skill_GetSkillInfo($SkillBarCache[$i][$all], "Adrenaline")
		$SkillBarCache[$i][$type]      = Skill_GetSkillInfo($SkillBarCache[$i][$all], "SkillType")
		$SkillBarCache[$i][$target]    = Skill_GetSkillInfo($SkillBarCache[$i][$all], "Target")

		;Activation time reduced for fast casting
		Switch $SkillBarCache[$i][$type]
			Case $Signet
				$SkillBarCache[$i][$activation] =  Memory_Read($SkillBarCache[$i][$ptr] + 60, 'float') * 1000 * (1 - 0.03 * GetAttributeByID($Fast_Casting, True))
			Case $Spell, $Hex
				$SkillBarCache[$i][$activation] =  Memory_Read($SkillBarCache[$i][$ptr] + 60, 'float') * 1000 * (1 - 0.955^GetAttributeByID($Fast_Casting, True))
			Case Else
				$SkillBarCache[$i][$activation] = Memory_Read($SkillBarCache[$i][$ptr] + 60, 'float') * 1000
		EndSwitch

		$SkillBarCache[$i][$aftercast] = Memory_Read($SkillBarCache[$i][$ptr] + 64, "float") * 750 	; Aftercast


		; recoding of target = 1 into the appropriate target categories
		If $SkillBarCache[$i][$target] = 1 Then
			Switch $SkillBarCache[$i][$all]
				Case $Summon_Spirits_Kurzick, $Summon_Spirits_Luxon, $Air_of_Superiority, $Summon_Mursaat, $Summon_Ruby_Djinn, $Summon_Ice_Imp, $Summon_Naga_Shaman
					$SkillBarCache[$i][$target] = 0 ; self
				Case $Gust, $Double_Dragon, $Stone_Sheath
					$SkillBarCache[$i][$target] = 3 ;ally
				Case $Heart_of_Shadow, $Vipers_Defense, $Ride_the_Lightning, $Mirror_of_Ice, $Charm_Animal, $Wandering_Eye, $Clumsiness, $Ineptitude, $Signet_of_Clumsiness, _
					$Signet_of_Clumsiness_PvP, $Empathy, $Insidious_Parasite, $Accumulated_Pain, $Arcane_Conundrum, $Panic, $Panic_PvP, $Overload, $Mistrust, $Mistrust_PvP
					$SkillBarCache[$i][$target] = 5 ; Enemy
				Case $Gaze_of_Fury, $Rupture_Soul, $Spirit_to_Flesh, $Spirit_Walk, $Draw_Spirit, $Swap, $Signet_of_Binding, $Putrid_Flesh, $Feast_for_the_Dead
					$SkillBarCache[$i][$target] = 14 ; minion
				Case $Strike_as_One
					$SkillBarCache[$i][$target] = 6 ; dead ally
				Case $Meteor_Shower, $Meteor
					$SkillBarCache[$i][$target] = 16 ; ground
				Case Else	; $Putrid_Explosion
					$SkillBarCache[$i][$target] = 0

			EndSwitch
		EndIf

		If IsResSkill($aSkillID) Then $SkillBarCache[$i][$rezz] = $aSkillID
		If IsHexSpell($aSkillID) Then $SkillBarCache[$i][$hexes] = $aSkillID
		If IsPressureSkill($aSkillID) Then $SkillBarCache[$i][$pressure] = $aSkillID
		If IsBindingSkill($aSkillID) Then $SkillBarCache[$i][$bind] = $aSkillID
		If IsSpeedBoost($aSkillID) Then $SkillBarCache[$i][$speedBoost] = $aSkillID
		If IsSurvivalSkill($aSkillID) Then $SkillBarCache[$i][$survive] = $aSkillID
		If IsAttackSkill($aSkillID) Then $SkillBarCache[$i][$attackskill] = $aSkillID
		If IsHealSkill($aSkillID) Then $SkillBarCache[$i][$heal] = $aSkillID
		If IsBondSkill($aSkillID) Then $SkillBarCache[$i][$bond] = $aSkillID
		If IsCondRemoveSkill($aSkillID) Then $SkillBarCache[$i][$condremove] = $aSkillID
		If IsHexRemoveSkill($aSkillID) Then $SkillBarCache[$i][$hexremove] = $aSkillID
		If IsEnchantRemoveSkill($aSkillID) Then $SkillBarCache[$i][$enchantremove] = $aSkillID
		If IsRuptSkill($aSkillID) Then
			$RuptSlots[0] += 1
			$RuptSlots[$RuptSlots[0]] = $i
			$SkillBarCache[$i][$rupt] = $aSkillID
		EndIf
		If $i = 8 Then
			ReDim $RuptSlots[$RuptSlots[0]+1]
			If $RuptSlots[0] > 0 Then
				Out("Rupts detected, activating Event System")
				$RuptEventSystem = True
			EndIf
		EndIf
		If IsRuptSkill($aSkillID, True) Then $SkillBarCache[$i][$hardrupt] = $aSkillID
		If IsPrecastSkill($aSkillID) Then $SkillBarCache[$i][$precast] = $aSkillID
		If IsChantSkill($aSkillID) or IsShoutSkill($aSkillID) Or IsEchoRefrainskill($aSkillID) Then $SkillBarCache[$i][$echochantshout] = $aSkillID
		If IsJununduSkill($aSkillID) Then $SkillBarCache[$i][$junundu] = $aSkillID
		If IsPressureSpiritSkill($aSkillID) Then $PressureSpiritSkills += 1
		If IsProtectiveSkill($aSkillID) Then
			$ProtSlots[0] += 1
			$ProtSlots[$ProtSlots[0]] = $i
			$SkillBarCache[$i][$prot] = $aSkillID
		EndIf
		If $i = 8 Then
			ReDim $ProtSlots[$ProtSlots[0]+1]
			If $ProtSlots[0] > 0 Then
				Out("Prot detected, activating Event System")
				$ProtEventSystem = True
			EndIf
		EndIf
	Next
	If $SkillbarSlot[$Signet_Of_Spirits] > 0 Then $PressureSpiritSkills += 2    ; add 2 spirits for Signet of Spirits
	Out($PressureSpiritSkills & " pressure sprits on your skillbar")
	$Summon_Spirits = $SkillbarSlot[$Summon_Spirits_Luxon] + $SkillbarSlot[$Summon_Spirits_Kurzick]
	Out("Mapping your skill bar - completed")
	; _ArrayDisplay($SkillBarCache)
	; _ArrayDisplay($RuptSlots)

	Return True
EndFunc   ;==>CacheSkillBar

; Creates a dynamic log of agents and skills they use from which to trigger rupts or other skills
Func UpdateAndDispatchCasts()
    Local $aAgents = Agent_GetAgentArray()

    For $i = 1 To UBound($aAgents) - 1
        Local $iPtr = $aAgents[$i]
        If Not IsPtr($iPtr) Then ContinueLoop

        Local $iID = Agent_GetAgentInfo($iPtr, "ID")
        If $iID = 0 Then ContinueLoop
        If Agent_GetAgentInfo($iID, "Allegiance") <> 3 Then ContinueLoop
        If Agent_GetDistance($iID) > 1500 Then ContinueLoop

        Local $bCasting = Agent_GetAgentInfo($iID, "IsCasting")
        Local $iSkill   = Agent_GetAgentInfo($iID, "Skill")

        If Not $bCasting Or $iSkill = 0 Then ContinueLoop

        ; Skip if we already processed this exact cast recently (< 3 s)
        Local $bAlreadySeen = False
        For $j = 0 To $iLastCastCount - 1
            If $aLastCast[$j][0] = $iID And $aLastCast[$j][1] = $iSkill Then
                If TimerDiff($aLastCast[$j][2]) < 3000 Then
                    $bAlreadySeen = True
                    ExitLoop
                EndIf
            EndIf
        Next
        If $bAlreadySeen Then ContinueLoop

        ; Keep at most the last 100 casts
        If $iLastCastCount >= 100 Then
            For $k = 0 To 98
                For $m = 0 To 3
                    $aLastCast[$k][$m] = $aLastCast[$k + 1][$m]
                Next
            Next
            $iLastCastCount = 99
        EndIf

        ReDim $aLastCast[$iLastCastCount + 1][4]
        $aLastCast[$iLastCastCount][0] = $iID
        $aLastCast[$iLastCastCount][1] = $iSkill
        $aLastCast[$iLastCastCount][2] = TimerInit()
        $aLastCast[$iLastCastCount][3] = Agent_GetAgentInfo($iID, "Target")
        $iLastCastCount += 1


		Local $iType = Skill_GetSkillInfo($iSkill, "SkillType")
		If $iType = $Attack Then
			AttackActivation($iID, Agent_GetAgentInfo($iID, "Target"), $iSkill, Skill_GetSkillInfo($iSkill, "Activation"))
		Else
			SpellActivation($iID, Agent_GetAgentInfo($iID, "Target"), $iSkill, Skill_GetSkillInfo($iSkill, "Activation"))
			; RuptEX($iID, Agent_GetAgentInfo($iID, "Target"), $iSkill, Skill_GetSkillInfo($iSkill, "Activation"))
		EndIf
    Next

    ; Debug: dump the cast log after each pass
    ; Out("--- Cast log (" & $iLastCastCount & ") ---")
    ; For $j = 0 To $iLastCastCount - 1
    ;     Out("  [" & $j & "] ID:" & $aLastCast[$j][0] & " Skill:" & $aLastCast[$j][1] & "Target:" & $aLastCast[$j][3] & " Age:" & Round(TimerDiff($aLastCast[$j][2])) & "ms")
    ; Next
EndFunc

Func SpellActivation($aCasterID, $aTargetID, $aSkillID, $aActivation)
	$RuptTimer = TimerInit()
	Local $Blocked = 0
	Local $lCasterPtr = Agent_GetAgentPtr($aCasterID), $lTargetPtr = Agent_GetAgentPtr($aTargetID), $lSkillPtr = Skill_GetSkillPtr($aSkillID)
	If Map_GetInstanceInfo("Type") <> $Map_Explorable Or Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "Knocked") Or Agent_GetAgentInfo(-2, "IsCasting") Then Return

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		Rupt and Cancel Skill to avoid Rupt		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	;~ For cancel casting
	If $aCasterID == Agent_GetMyID() Then
		;Out("I am casting " & $aSkill_Name[$aSkillID])
		$MyActivation = Memory_Read($lSkillPtr + 60, 'float') * 1000	; storing my activation time into a global variable for the next skill parsing
		$MyAftercast = Memory_Read($lSkillPtr + 64, 'float') * 750
		$MySkillID = $aSkillID
		$MyTargetID = $aTargetID
		$AftercastTimer = TimerInit()
		;Return ;<<< Are you sure about it ?
	EndIf

	;~ Cancel casting to avoid rupt
	If IsHardRuptSkill($aSkillID) And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " is interrupting my " & $aSkill_Name[$MySkillID])
		If TimerDiff($AftercastTimer) > $MyActivation * 1000 Then Return
		If $MyActivation > 250 Then CancelAction()
		$AftercastTimer = TimerInit()
		Return
	EndIf

	;~ 	Rupt Skills
	Out($RuptSlots[0] & "interrupts on our bar")
	If $RuptSlots[0] > 0 Then
		If TimerDiff($AftercastTimer) < $MyActivation Then Return

		If Agent_GetAgentInfo($aCasterID, "Allegiance") <> 3 Or Agent_GetDistance($aCasterID) > 1200 Then Return
		Out("Testing Rupt Splot for skillID " & $aSkillID & ", CasterID " & $aCasterID & ", TargetID " & $aTargetID)

		$lRuptSlot = GetRuptSlot($aSkillID, $aCasterID)
		Out("Ruptslot: " & $lRuptSlot)
		If $lRuptSlot > 0 Then
			Skill_TryUseSkill($lRuptSlot, $aCasterID)
			If Agent_GetAgentInfo($lCasterPtr, "IsCasting") = 0 Then Out("Interrupted " & $aSkill_Name[$aSkillID] & "!!!")
			Out("Rupt(): " & TimerDiff($RuptTimer))
			Return
		EndIf
	EndIf

	;~ 	Prot skills
	If $ProtSlots[0] > 0 Then
		If Agent_GetAgentInfo($aCasterID, "Allegiance") <> 3 Or Agent_GetDistance($aTargetID) > 1250 Then Return
		$ProtSlots  = GetProtSlot($aSkillID, $aCasterID, $aTargetID)
		If $ProtSlots > 0 Then
			Skill_TryUseSkill($ProtSlots, $aTargetID)
			Return
		EndIf
	EndIf

	;~ 	Enchant removal (on enemies) - pending targetID reads (broken), we don't remove the enchantment on the target of the spell, instead we
	For $i = 1 To 8
		If $SkillBarCache[$i][$enchantremove] <> "" Then
			If Not Skill_GetSkillbarInfo($i, "IsRecharged") Then ContinueLoop
			If $SkillBarCache[$i][$energyreq] > Agent_GetAgentInfo(-2, "CurrentEnergy") Then ContinueLoop
			Local $iTarget = GetBalledEnchantedEnemy(1320)
			Out("Enchanted ennemy ID: " & GetBalledEnchantedEnemy(1320))
			If $iTarget <> 0 Then
				Out("C")
				Skill_TryUseSkill($i, $iTarget)
				Return
			EndIf
		EndIf
	Next

	;~ 	Hex removal (on allies)
	For $i = 1 To 8
		If $SkillBarCache[$i][$hexremove] <> "" Then
			If Not Skill_GetSkillbarInfo($i, "IsRecharged") Then ContinueLoop
			If $SkillBarCache[$i][$energyreq] > Agent_GetAgentInfo(-2, "CurrentEnergy") Then ContinueLoop
			Out("Most hexed Ally ID: " & MostHexedAlly())
			Local $iTarget = MostHexedAlly()
			If $iTarget <> 0 Then
				Skill_TryUseSkill($i, $iTarget)
				Return
			EndIf
		EndIf
	Next

;~ ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		Move to Avoid AoE	<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	;~ 	Area Range
	If IsAoESkill($aSkillID) = 1 Then
		If $aTargetID <> Agent_GetMyID() Then
			$AOEDangerXYLocation = Agent_XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 362 Then ;312 + 50
				Out("Ally: " & $aTargetID & " is the area AoE Target of " & $aCasterID & ", move !")
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 362)
			EndIf
			Return
		EndIf
	EndIf

	;~ 	Area Nearby
	If IsAoESkill($aSkillID) = 2 Then
		If $aTargetID <> Agent_GetMyID() Then
			$AOEDangerXYLocation = Agent_XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 290 Then ;240 + 50
				Out("Ally: " & $aTargetID & " is the nearby AoE Target of " & $aCasterID & ", move !")
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 290)
			EndIf
			Return
		EndIf
	EndIf

	;~ 	Area Adjacent
	If IsAoESkill($aSkillID) = 3 Then
		If $aTargetID <> Agent_GetMyID() Then
			$AOEDangerXYLocation = Agent_XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 256 Then ;156 + 50
				Out("Ally: " & $aTargetID & " is the nearby AoE Target of " & $aCasterID & ", move !")
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 256)
			EndIf
			Return
		EndIf
	EndIf

	;~ 	Static Area
	If IsAoESkill($aSkillID) = 4 Then
		If $aTargetID = Agent_GetMyID() Then
			$AOEDangerXYLocation = Agent_XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 290 Then ;240 + 50
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 290)
			EndIf
		Else
			$AOEDangerXYLocation = Agent_XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 290 Then ;240 + 50
				Out("Ally: " & $aTargetID & " is the Static AoE Target of " & $aCasterID & ", move !")
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 290)
			EndIf
		EndIf
		Return
	EndIf

;~ ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		Cancel, switch defensive set, stop moving		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	;~ 	Cancel casting to avoid damage
	If IsAnnoyingSkill($aSkillID) = 1 And $aTargetID = Agent_GetMyID() Or IsAnnoyingSkill($aSkillID) = 2 And $aTargetID = Agent_GetMyID() Then ;Maybe separate 1 and 2
		Out($aCasterID & " Hurt me " & $aSkill_Name[$MySkillID])
		If TimerDiff($AftercastTimer) > $MyActivation * 1000 Then Return
		If $MyActivation > 250 Then DoubleCancel()
		$AftercastTimer = TimerInit()
		Return
	EndIf

	;~ 	Cancel Skill to avoid Melee rupt
	If IsAnnoyingSkill($aSkillID) = 9 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " Hurt me " & $aSkill_Name[$MySkillID])
		If TimerDiff($AftercastTimer) > $MyActivation * 1000 Then Return
		If $MyActivation > 250 Then DoubleCancel()
		$AftercastTimer = TimerInit()
		Return
	EndIf

	;~ 	Cancel Cast If Dazed or use block skill
	If IsAnnoyingSkill($aSkillID) = 7 And $aTargetID = Agent_GetMyID() Then
		If Skill_HasEffect($Dazed) Then
			If UseBlock() Then
				Out("Use Block Skill to avoid Melee and Daze")
			Else
				Out("Can't use block, cancel action")
				If TimerDiff($AftercastTimer) > $MyActivation * 1000 Then Return
				If $MyActivation > 250 Then DoubleCancel()
			EndIf
		EndIf
		Return
	EndIf

	;~ Cancel Attack to avoid damage
	If IsAnnoyingSkill($aSkillID) = 3 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " counter attack me " & $aSkill_Name[$MySkillID])
		If Agent_GetAgentInfo(-2, "Attacking") Then DoubleCancel()
		Out("Stop Attacking to avoid Damage")
		Return
	EndIf

	;~ 	Cancel Moving cause melee try to KD me
	If IsAnnoyingSkill($aSkillID) = 4 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " KD me " & $aSkill_Name[$MySkillID])
		If Agent_GetAgentInfo(-2, "Moving") Then DoubleCancel()
		Out("Stop Moving to avoid KD")
		Return
	EndIf

	;~ 	Cancel Action to use Block and Balance skill and defensif set
	If IsAnnoyingSkill($aSkillID) = 5 And $aTargetID = Agent_GetMyID() Then
		If UseBalanced() Then
			Out("Use Balanced Skill to avoid KD")
		ElseIf UseBlock() Then
			Out("Use Block Skill to avoid KD")
		ElseIf Not Agent_IsMartial(-2) Then
			Out("Switch Defensif set, We will be KB")
			DoubleCancel()
			Sleep(50)
			ChangeWeaponSet(1)
			Sleep(500)
		EndIf
		Return
	EndIf

	;~ 	Cancel Action to use Balance skill and defensif set
	If IsAnnoyingSkill($aSkillID) = 6 And $aTargetID = Agent_GetMyID() Then
		If UseBalanced() Then
			Out("Use Balanced Skill to avoid KD")
		Else
			Out("Switch Defensif set, We will be KB")
			DoubleCancel()
			Sleep(50)
			ChangeWeaponSet(1)
			Sleep(500)
		EndIf
		Return
	EndIf

	;~ 	UseBlock or Defsenive set if melee pressure is on me
	If IsAnnoyingSkill($aSkillID) = 8 And $aTargetID = Agent_GetMyID() Then
		If UseBlock() Then
			Out("Use Block Skill, melee pressure on me")
		ElseIf Not Agent_IsMartial(-2) Then
			Out("Switch Defensif set, Melee pressure on me")
			DoubleCancel()
			Sleep(50)
			ChangeWeaponSet(1)
			Sleep(500)
		EndIf
		Return
	EndIf

	;~ 	Cancel Action
	If IsAnnoyingSkill($aSkillID) = 10 And $aTargetID = Agent_GetMyID() Then
		If Agent_GetAgentInfo(-2, "Attacking") Then DoubleCancel()
		Return
	EndIf

EndFunc   ;==>Rupt

Func AttackActivation($aCasterID, $aTargetID, $aSkillID, $lActivation)
	$RuptTimer = TimerInit()
	Local $Blocked = 0
	Local $lCasterPtr = Agent_GetAgentPtr($aCasterID), $lTargetPtr = Agent_GetAgentPtr($aTargetID), $lSkillPtr = Skill_GetSkillPtr($aSkillID)
	If Map_GetInstanceInfo("Type") <> $Map_Explorable Or Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "Knocked") Or Agent_GetAgentInfo(-2, "IsCasting") Then Return

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		Rupt and Cancel Skill to avoid Rupt		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	;~ For cancel casting
	If $aCasterID == Agent_GetMyID() Then
		;Out("I am casting " & $aSkill_Name[$aSkillID])
		$MyActivation = Memory_Read($lSkillPtr + 60, 'float') * 1000	; storing my activation time into a global variable for the next skill parsing
		$MyAftercast = Memory_Read($lSkillPtr + 64, 'float') * 750
		$MySkillID = $aSkillID
		$MyTargetID = $aTargetID
		$AftercastTimer = TimerInit()
		;Return ;<<< Are you sure about it ?
	EndIf

	;~ Cancel casting to avoid rupt
	If IsHardRuptSkill($aSkillID) And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " is interrupting my " & $aSkill_Name[$MySkillID])
		If TimerDiff($AftercastTimer) > $MyActivation * 1000 Then Return
		If $MyActivation > 250 Then DoubleCancel()
		$AftercastTimer = TimerInit()
		Return
	EndIf

	;~ 	Rupt Skills
	If RuptSlots[0] > 0 Then
		If TimerDiff($AftercastTimer) < $MyAftercast Then Return
		If Agent_GetAgentInfo($aCasterID, "Allegiance") <> 3 Or Agent_GetDistance($aCasterID) > 1200 Then Return
		$lRuptSlot = GetRuptSlot($aSkillID, $aCasterID)
		If $lRuptSlot > 0 Then
			Skill_TryUseSkill($lRuptSlot, $aCasterID)
			If Agent_GetAgentInfo($lCasterPtr, "IsCasting") = 0 Then Out("Interrupted " & $aSkill_Name[$aSkillID] & "!!!")
			Out("Rupt(): " & TimerDiff($RuptTimer))
			Return
		EndIf
	EndIf

	;~ 	Prot skills

	If $ProtSlots[0] > 0 Then
		If Agent_GetAgentInfo($aCasterID, "Allegiance") <> 3 Or Agent_GetDistance($aTargetID) > 1250 Then Return
		$ProtSlots  = GetProtSlot($aSkillID, $aCasterID, $aTargetID)
		If $ProtSlots > 0 Then
			Skill_TryUseSkill($ProtSlots, $aTargetID)
			Return
		EndIf
	EndIf

;~ ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		Cancel, switch defensive set, stop moving		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	;~ 	Cancel casting to avoid damage
	If IsAnnoyingSkill($aSkillID) = 1 And $aTargetID = Agent_GetMyID() Or IsAnnoyingSkill($aSkillID) = 2 And $aTargetID = Agent_GetMyID() Then ;Maybe separate 1 and 2
		Out($aCasterID & " Hurt me " & $aSkill_Name[$MySkillID])
		If TimerDiff($AftercastTimer) > $MyActivation * 1000 Then Return
		If $MyActivation > 250 Then DoubleCancel()
		$AftercastTimer = TimerInit()
		Return
	EndIf

	;~ 	Cancel Skill to avoid Melee rupt
	If IsAnnoyingSkill($aSkillID) = 9 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " Hurt me " & $aSkill_Name[$MySkillID])
		If TimerDiff($AftercastTimer) > $MyActivation * 1000 Then Return
		If $MyActivation > 250 Then DoubleCancel()
		$AftercastTimer = TimerInit()
		Return
	EndIf

	;~ 	Cancel Cast If Dazed or use block skill
	If IsAnnoyingSkill($aSkillID) = 7 And $aTargetID = Agent_GetMyID() Then
		If Skill_HasEffect($Dazed) Then
			If UseBlock() Then
				Out("Use Block Skill to avoid Melee and Daze")
			Else
				Out("Can't use block, cancel action")
				If TimerDiff($AftercastTimer) > $MyActivation * 1000 Then Return
				If $MyActivation > 250 Then DoubleCancel()
			EndIf
		EndIf
		Return
	EndIf

	;~ Cancel Attack to avoid damage
	If IsAnnoyingSkill($aSkillID) = 3 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " counter attack me " & $aSkill_Name[$MySkillID])
		If Agent_GetAgentInfo(-2, "Attacking") Then DoubleCancel()
		Out("Stop Attacking to avoid Damage")
		Return
	EndIf

	;~ 	Cancel Moving cause melee try to KD me
	If IsAnnoyingSkill($aSkillID) = 4 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " KD me " & $aSkill_Name[$MySkillID])
		If Agent_GetAgentInfo(-2, "Moving") Then DoubleCancel()
		Out("Stop Moving to avoid KD")
		Return
	EndIf

	;~ 	Cancel Action to use Block and Balance skill and defensif set
	If IsAnnoyingSkill($aSkillID) = 5 And $aTargetID = Agent_GetMyID() Then
		If UseBalanced() Then
			Out("Use Balanced Skill to avoid KD")
		ElseIf UseBlock() Then
			Out("Use Block Skill to avoid KD")
		ElseIf Not Agent_IsMartial(-2) Then
			Out("Switch Defensif set, We will be KB")
			DoubleCancel()
			Sleep(50)
			ChangeWeaponSet(1)
			Sleep(500)
		EndIf
		Return
	EndIf

	;~ 	Cancel Action to use Balance skill and defensif set
	If IsAnnoyingSkill($aSkillID) = 6 And $aTargetID = Agent_GetMyID() Then
		If UseBalanced() Then
			Out("Use Balanced Skill to avoid KD")
		Else
			Out("Switch Defensif set, We will be KB")
			DoubleCancel()
			Sleep(50)
			ChangeWeaponSet(1)
			Sleep(500)
		EndIf
		Return
	EndIf

	;~ 	UseBlock or Defsenive set if melee pressure is on me
	If IsAnnoyingSkill($aSkillID) = 8 And $aTargetID = Agent_GetMyID() Then
		If UseBlock() Then
			Out("Use Block Skill, melee pressure on me")
		ElseIf Not Agent_IsMartial(-2) Then
			Out("Switch Defensif set, Melee pressure on me")
			DoubleCancel()
			Sleep(50)
			ChangeWeaponSet(1)
			Sleep(500)
		EndIf
		Return
	EndIf

	;~ 	Cancel Action
	If IsAnnoyingSkill($aSkillID) = 10 And $aTargetID = Agent_GetMyID() Then
		If Agent_GetAgentInfo(-2, "Attacking") Then DoubleCancel()
		Return
	EndIf

EndFunc   ;==>Rupt

Func GetRuptSlot($aSkillID, $aCasterID)
    Out("GetRuptSlot | Enemy skill:" & $aSkillID & " | RuptSlots count:" & $RuptSlots[0])

    Local $iDist = Agent_GetDistance($aCasterID)
    If $iDist > 1500 Or $iDist = 0 Then
        Out("  → caster out of range, aborting")
        Return 0
    EndIf

    Local $bNeedsHardRupt = RequiresHardRupt($aSkillID)
    Out("  → needs hard rupt: " & $bNeedsHardRupt)

    For $i = 1 To $RuptSlots[0]
        Local $aSkillSlot = $RuptSlots[$i]
        Out("  checking slot " & $aSkillSlot & " (skill " & $SkillBarCache[$aSkillSlot][$all] & ")")

        If Not Skill_GetSkillbarInfo($aSkillSlot, "IsRecharged") Then ContinueLoop
        If $SkillBarCache[$aSkillSlot][$energyreq] > Agent_GetAgentInfo(-2, "CurrentEnergy") Then ContinueLoop
        If $bNeedsHardRupt And $SkillBarCache[$aSkillSlot][$hardrupt] = "" Then ContinueLoop
        Return $aSkillSlot
    Next
    Return 0
EndFunc   ;==>GetRuptSlot

;~ Description: Returns the skill ID of an equipped skill.
;~ Uses Logic-style offset math; pointer comes from GwAu3
Func GetSkillbarInfo($aSkillSlot, $aHeroNumber = 0)
    Local $pSkillbar = _GetSkillbarPtr($aHeroNumber)
    If Not IsPtr($pSkillbar) Then Return 0
    $aSkillSlot -= 1
    Return Memory_Read($pSkillbar + 16 + $aSkillSlot * 20, "dword")
EndFunc

; Internal helper – caches the pointer for the local player
Func _GetSkillbarPtr($aHeroNumber = 0)
    Static $pCached = 0
    Static $iCachedHero = -1

    If $aHeroNumber = $iCachedHero And IsPtr($pCached) Then
        Return $pCached
    EndIf

    Local $l_p_Ptr = World_GetWorldInfo("SkillbarArray")
    Local $l_i_Size = World_GetWorldInfo("SkillbarArraySize")
    Local $l_i_HeroID
    If $aHeroNumber = 0 Then
        $l_i_HeroID = Agent_GetMyID()
    Else
        $l_i_HeroID = Party_GetMyPartyHeroInfo($aHeroNumber, "AgentID")
    EndIf

    For $i = 0 To $l_i_Size - 1
        Local $p = $l_p_Ptr + (0xBC * $i)
        If Memory_Read($p, "long") = $l_i_HeroID Then
            $pCached = $p
            $iCachedHero = $aHeroNumber
            Return $p
        EndIf
    Next
    Return 0
EndFunc


Func Fight($x, $y, $aAggroRange = 1320, $careful = False, $aMaxDistanceToXY = 5000, $aAgent = 0) ; Fighting mechanics
; REVIEW: GwAu3 equivalent is UAI_Fight(). Call this one when you want the Logic interrupt path.
	Out("Fighting enemies")
	Local $TimerToGetOut = TimerInit()
	; SetEvent("SpellActivation", "AttackActivation", "", "", "", "") ; only active during fight to avoid crashes

	Do
		If CanAttack($aAggroRange) Then
			CallTarget($BestTargetPtr)
			Attack($BestTargetPtr, False) ; CanAttack() sets $besttarget global variable to best target, turned to False to avoid crashes
		EndIf
		Precast($aAggroRange, $careful)
		If $careful Then
			CancelAll()
			Move(Agent_X($BestTargetPtr), Agent_Y($BestTargetPtr))
			RndSleep(300)
		EndIf
		UseSkills($x, $y, $aAggroRange, $all, $aMaxDistanceToXY, $aAgent)
	Until Agent_NoEnemiesAround($aAggroRange) Or TimerDiff($TimerToGetOut) > 240000 ;UseSkills($x, $y, $aAggroRange, $all, $aMaxDistanceToXY, $aAgent) = False Or TimerDiff($TimerToGetOut) > 240000
	; SetEvent("", "", "", "", "", "")
EndFunc   ;==>Fight

;~ Use this function to cast all of your skills  or skills of a certain type.
;~ $skilltype: $all = 0, $type, $target, $hexes, $pressure, $bind, $speedBoost, $survive, $attackskill, $heal, $prot, $bond, $condremove, $hexremove, $rupt, $HardRupt, $precast
Func UseSkills($x, $y, $aAggroRange = 1320, $skilltype = $all, $aMaxDistanceToXY = 5000, $aAgent = 0)
; REVIEW: GwAu3 equivalent is UAI_UseSkills() / UAI_TryUseSkill(). This version walks $SkillBarCache.
	For $aSkillSlot In $Skillbar
		If Agent_GetAgentInfo(-2, "IsDead") Or Map_GetInstanceInfo("Type") == 2 Then Return False
		If Agent_GetAgentInfo($BestTargetPtr, "Allegiance") = 3 And Agent_GetAgentInfo($BestTargetPtr, "IsDead") Then Return False
		UpdateAndDispatchCasts()
		If Agent_NoEnemiesAround($aAggroRange) Then Return False
		If $SkillBarCache[$aSkillSlot][$skilltype] = "" Then ContinueLoop
		If CanUse($aSkillSlot, $aAggroRange) Then Skill_UseSkill($aSkillSlot, $BestTargetPtr)

		If $aSkillSlot = 8 Then
			If $aAgent <> 0 Then
				If Agent_GetDistance($aAgent) > $aMaxDistanceToXY Then Return False
			ElseIf $aMaxDistancetoXY <> 5000 Then
				If Agent_GetDistanceToXY($x, $y) > $aMaxDistanceToXY Then Return False	; exit fight if we deviate for waypoints by more than allowed distance
			EndIf
			$aSkillSlot = 1
		EndIf
	Next
	Return True
EndFunc   ;==>UseSkills

Func Skill_TryUseSkill($aSkillSlot, $aTarget = -2, $aCallTarget = False)
	If Not CanCast($aSkillSlot) Then Return
    Skill_UseSkill($aSkillSlot, $aTarget)
EndFunc

Func UnFight($x, $y, $aAggroRange = 1320, $aMaxDistanceToXY = 5000, $aAgent = 0)
	UseUnfightSkills($x, $y, $aAggroRange, $all, $aMaxDistanceToXY, $aAgent)
EndFunc   ;==>Fight

; For skills (pointer, struct, or ID) → skill ID
Func GetSkillID($aSkill)
    If IsPtr($aSkill) Then
        Return Memory_Read($aSkill, "long")          ; skill ID is at offset 0
    ElseIf IsDllStruct($aSkill) Then
        Return DllStructGetData($aSkill, "ID")
    Else
        Return $aSkill                               ; already a skill ID
    EndIf
EndFunc

Func UseUnfightSkills($x, $y, $aAggroRange = 1320, $skilltype = $all, $aMaxDistanceToXY = 5000, $aAgent = 0)
	For $aSkillSlot In $Skillbar
		If Agent_GetAgentInfo(-2, "IsDead") Or Map_GetInstanceInfo("Type") == 2 Then Return False
		If Memory_Read($BestTargetPtr + 433, "byte") = 3 And Agent_GetAgentInfo($BestTargetPtr, "IsDead") Then Return False
		If $SkillBarCache[$aSkillSlot][$skilltype] = "" Then ContinueLoop
		If CanUse($aSkillSlot, $aAggroRange) Then
			Skill_UseSkill($aSkillSlot, $BestTargetPtr)
		EndIf

		If $aSkillSlot = 8 Then
			If $aAgent <> 0 Then
				If Agent_GetDistance($aAgent) > $aMaxDistanceToXY Then Return False
			ElseIf $aMaxDistancetoXY <> 5000 Then
				If Agent_GetDistanceToXY($x, $y) > $aMaxDistanceToXY Then Return False	; exit fight if we deviate for waypoints by more than allowed distance
			EndIf
			$aSkillSlot = 1
		EndIf
	Next
	Return True
EndFunc   ;==>UseSkills

Func SkillCancel($aCasterID, $aTargetID, $aSkillID)
	Local $lCasterPtr = Agent_GetAgentPtr($aCasterID), $lTargetPtr = Agent_GetAgentPtr($aTargetID), $lSkillPtr = Skill_GetSkillPtr($aSkillID)
	If Map_GetInstanceInfo("Type") <> $Map_Explorable Or Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "Knocked") Then Return

	Switch $aSkillID
		Case 30, 51
			If $aTargetID = Agent_GetMyID() Then
				Out("SkillCancel")
				Out("Need to cancel")
				DoubleCancel()
			EndIf
	EndSwitch
EndFunc

Func SkillComplete($aCasterID, $aTargetID, $aSkillID)
	Local $lCasterPtr = Agent_GetAgentPtr($aCasterID), $lTargetPtr = Agent_GetAgentPtr($aTargetID), $lSkillPtr = Skill_GetSkillPtr($aSkillID)
	If Map_GetInstanceInfo("Type") <> $Map_Explorable Or Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "Knocked") Then Return

	Switch $aSkillID
		Case 30, 51
			If $aTargetID = Agent_GetMyID() Then
				Out("SkillComplete")
				Out("Need to cancel")
				DoubleCancel()
			EndIf
	EndSwitch
;~ 	Switch DllStructGetData($ASKILL, "ID")
;~ 		Case 28, 30, 51
;~ 			If $VEILENABLED And DllStructGetData($ACASTER, "Allegiance") == 3 And GETDISTANCE($ATARGET) <= 1247 And DllStructGetData($ATARGET, "Primary") == 3 And DllStructGetData(GETEFFECT(30), "SkillID") == 0 And DllStructGetData(GETEFFECT(51), "SkillID") == 0 And DllStructGetData($ATARGET, "ID") <> Agent_GetMyID() Then
;~ 				USEVEIL($ATARGET)
;~ 				Do
;~ 					Sleep(100)
;~ 				Until Not GETISCASTING(-2)
;~ 				$MONKIDX = DllStructGetData($ATARGET, "PlayerNumber")
;~ 				DROPBUFFXX(309, $MONKIDX)
;~ 			EndIf
;~ 		Case 235, 227
;~ 			If $BGENABLED And DllStructGetData($ACASTER, "Allegiance") == 3 And GETDISTANCE($ATARGET) <= 1247 And DllStructGetData($ATARGET, "Primary") == 1 Or DllStructGetData($ATARGET, "Primary") == 2 Or DllStructGetData($ATARGET, "Primary") == 10 Or DllStructGetData($ATARGET, "Primary") == 2 And DllStructGetData(GETEFFECT(30), "SkillID") == 0 And DllStructGetData(GETEFFECT(51), "SkillID") == 0 And DllStructGetData($ATARGET, "ID") <> Agent_GetMyID() Then
;~ 				USEVEIL($ATARGET)
;~ 				Do
;~ 					Sleep(100)
;~ 				Until Not GETISCASTING(-2)
;~ 				$MONKIDX = DllStructGetData($ATARGET, "PlayerNumber")
;~ 				DROPBUFFXX(309, $MONKIDX)
;~ 			EndIf
;~ 	EndSwitch
EndFunc

Func UseBlock()
	Local $lEffects = GetEffect()
	If IsArray($lEffects) Then
		For $i = 1 To $lEffects[0]
			If IsBlock(DllStructGetData($lEffects[$i], 'SkillID')) Then Return 1
			If IsBalanced(DllStructGetData($lEffects[$i], 'SkillID')) Then Return 1
		Next
	EndIf
	Local $lSkillbar = GetSkillbar()
	For $i = 1 To 8
		If IsBlock(DllStructGetData($lSkillbar, 'ID' & $i)) And DllStructGetData($lSkillbar, 'Recharge' & $i) == 0 Then
			If DllStructGetData(GetSkillByID(DllStructGetData($lSkillbar,'ID'&$i)), 'Adrenaline') <= DllStructGetData($lSkillbar, 'AdrenalineA' & $i) Then
				Skill_Use($i, -2)
				Return 1
			EndIf
		EndIf
	Next
	Return 0
EndFunc

Func UseBalanced()
	Local $lEffects = GetEffect()
	If IsArray($lEffects) Then
		For $i = 1 To $lEffects[0]
			If IsBlock(DllStructGetData($lEffects[$i], 'SkillID')) Then Return 1
			If IsBalanced(DllStructGetData($lEffects[$i], 'SkillID')) Then Return 1
		Next
	EndIf
	Local $lSkillbar = GetSkillbar()
	For $i = 1 To 8
		If IsBalanced(DllStructGetData($lSkillbar, 'ID' & $i)) And DllStructGetData($lSkillbar, 'Recharge' & $i) == 0 Then
			If DllStructGetData(GetSkillByID(DllStructGetData($lSkillbar,'ID'&$i)), 'Adrenaline') <= DllStructGetData($lSkillbar, 'AdrenalineA' & $i) Then
				Skill_Use($i, -2)
				Return 1
			EndIf
		EndIf
	Next
	Return 0
EndFunc

;~ Description: Calculates a safe spot and moves to it.
Func MoveToSafeSpot($aX, $aY, $radius = 100, $aMe = Agent_GetAgentPtr(-2))
   Local $d2r = 3.141592653589 / 180
   Local $coords[2], $TestDistance
   Local $theta = 0, $TempX, $TempY, $SafeDistance = 10000000
   Local $SafeX, $SafeY
   Local $MyLocation = Agent_XY($aMe)

   For $i = 0 To 99
	  $theta += 3.6
	  $TempX = ($radius * Cos($theta * $d2r)) + $aX
	  $TempY = ($radius * Sin($theta * $d2r)) + $aY

	  $TestDistance = ComputeDistance($TempX, $TempY, $MyLocation[0], $MyLocation[1])
	  If $TestDistance < $SafeDistance Then
		 $SafeDistance = $TestDistance
		 $SafeX = $TempX
		 $SafeY = $TempY
	  EndIf
   Next
   Move_ToCoord($SafeX, $SafeY)
EndFunc   ;==>MoveToSafeSpot

Func GetProtSlot($aSkillID, $lCasterPtr, $aTargetPtr)
	For $aSkillSlot In $ProtSlots	; cached skillslots with an interrupt skill
		If $SkillBarCache[$aSkillSlot][$energyreq] >  Agent_GetAgentInfo(-2, "CurrentEnergy") Then ContinueLoop
;~ 		If Skill_GetSkillbarInfo($SkillbarSlot[$Power_Drain]) Then Return $SkillbarSlot[$Power_Drain]
;~ 		If Skill_GetSkillbarInfo($SkillbarSlot[$Leech_Signet], "IsRecharged") Then Return $SkillbarSlot[$Leech_Signet]
;~ 		If Skill_GetSkillbarInfo($SkillbarSlot[$Power_Leech], "IsRecharged") Then Return $SkillbarSlot[$Power_Leech]

		Switch $SkillBarCache[$aSkillSlot][$Prot]
			Case ""
				ContinueLoop
			Case $Guardian, $Weapon_of_Warding, $Weapon_of_Warding_PvP, $Weapon_of_Shadow, $Aura_of_Stability, $Aegis, $Aegis_PvP
				If Not IsAttackSkill($aSkillID) Then ContinueLoop
			Case $Spirit_Bond, $Spirit_Bond_PvP, $Protective_Spirit, $Shield_of_Absorption, $Reversal_of_Fortune, $Weapon_of_Shadow
				If Not IsSpellskill($aSkillID) Then ContinueLoop
				If IsSpellskill($aSkillID) And IsHexSpell($aSkillID) Then ContinueLoop
				If IsSpellskill($aSkillID) And IsConditionSpell($aSkillID) Then ContinueLoop
			Case $Xinraes_Weapon, $Reversal_of_Damage, $Vengeful_Weapon
				If Not IsAttackSkill($aSkillID) Or Not IsSpellskill($aSkillID) Then ContinueLoop
			Case $Weapon_of_Remedy, $Life_Sheath, $Resilient_Weapon
				If Not IsConditionSpell($aSkillID) Or Not IsAttackSkill($aSkillID) Then ContinueLoop
			EndSwitch

		If Skill_GetSkillbarInfo($aSkillSlot, "IsRecharged") Then
			Return $aSkillSlot
		EndIf
	Next
	Return 0
EndFunc   ;==>GetRuptSlot

Func CanAttack($aRange = 1320)
	If Map_GetInstanceInfo("Type") == 2 Then Connection_CheckAndReconnect()
	If Map_GetInstanceInfo("Type") == 0 Then Return
	$BestTargetPtr = 0
 	If $BestTargetPtr = 0 Then Global $BestTargetPtr = Agent_GetBestTarget($aRange)

	Out(Agent_GetAgentInfo(-2, "ID") & " - My ID: " & ID(-2))
	If $BestTargetPtr = 0 Or IsWormAgent($BestTargetPtr) Then Return False	; prevents crash from attacking enemies that burry into the ground
	If CanCast() Then Return True
	Return False
EndFunc   ;==>CanAttack

;~ Description: Determines whether we should cast based the type of skill being used and shut-down effects on us. Also prevents stances when the effect already exists.
Func CanCast($aSkillSlot = 0)
; REVIEW: GwAu3 equivalent is UAI_CanUse() + per-skill CanUse_* handlers. This one uses $SkillBarCache.
	Local $pEffects = World_GetWorldInfo("AgentEffectsArray")
	Local $iSize = World_GetWorldInfo("AgentEffectsArraySize")
	Out("Effects array: " & $pEffects & " size: " & $iSize)
	Local $lAgentID = Memory_Read($pEffects, "long")
	Local $lEffectPtr = Memory_Read($pEffects + 0x14, "ptr")
	Local $lEffectCount = Memory_Read($pEffects + 0x1C, "long")
	Out("Array agent: " & $lAgentID & " my ID: " & Agent_GetMyID())
	Out("Effect ptr: " & $lEffectPtr & " count: " & $lEffectCount)
	If $lEffectCount > 0 And $lEffectPtr <> 0 Then
    For $j = 0 To $lEffectCount - 1
        Local $lSkillID = Memory_Read($lEffectPtr + $j * 0x18, "long")
        Out("  Effect " & $j & ": " & $lSkillID)
    Next
	EndIf

	UAI_CachePlayerEffectsAndBonds()
	; In CanCast, after UAI_CachePlayerEffectsAndBonds():
	Out("Effects count: " & $g_i_PlayerEffectsCount)
	For $i = 0 To $g_i_PlayerEffectsCount - 1
		Out("  Effect " & $i & ": " & $g_amx3_PlayerEffects[0][$i][$GC_UAI_EFFECT_SkillID])
	Next

	Local $Requi
	If Map_GetInstanceInfo("Type") == 2 Then Connection_CheckAndReconnect()
	If Map_GetInstanceInfo("Type") == 0 Then Return
	If Agent_GetAgentInfo(-2, "Knocked") Or Agent_GetAgentInfo(-2, "IsDead") Or Wipe = 1 Then Return False

	If $aSkillSlot <> 0 Then
		If Not Skill_GetSkillbarInfo($aSkillSlot, "IsRecharged") Then Return False
		If Agent_GetAgentInfo(-2, "CurrentEnergy") < $SkillBarCache[$aSkillSlot][$energyreq] Then Return False;* (1 + Skill_HasEffect($Quickening_Zephyr) * 30 / 100) Then Return False
		If Skill_HasEffect($Quickening_Zephyr) Then
			$Requi = $SkillBarCache[$aSkillSlot][$energyreq] * 30 / 100
			If Agent_GetAgentInfo(-2, "CurrentEnergy") < $Requi Then Return False
		EndIf
		If $SkillBarCache[$aSkillSlot][$adrereq] <> 0 And GetSkillbarSkillAdrenaline($aSkillslot) < $SkillBarCache[$aSkillSlot][$adrereq]  Then Return False
	EndIf

	If $aSkillSlot = 0 Then $aType = $attack
	Out("CanCast slot " & $aSkillSlot & " | Backfire:" & Skill_HasEffect($Backfire) & " | Diversion:" & Skill_HasEffect($Diversion))
	Switch $SkillBarCache[$aSkillSlot][$type]
		Case $Hex, $Spell, $Enchantment, $Well, $Ward, $ItemSpell, $WeaponSpell
			Switch True
				Case Skill_HasEffect($Diversion), Skill_HasEffect($Visions_of_Regret), _
					 Skill_HasEffect($Visions_of_Regret_PvP), Skill_HasEffect($Backfire), _
					 Skill_HasEffect($Soul_Leech), Skill_HasEffect($Mistrust), _
					 Skill_HasEffect($Mistrust_PvP), Skill_HasEffect($Mark_of_Subversion), _
					 Skill_HasEffect($Spiteful_Spirit)
					Out("Can't cast - blocked by effect")
					Return False
			EndSwitch
		Case $Stance
			If Skill_HasEffect($SkillBarCache[$aSkillSlot][$all]) Then Return False
		Case $Attack
			Switch True
				Case Skill_HasEffect($Ineptitude), Skill_HasEffect($Clumsiness), _
					 Skill_HasEffect($Spiteful_Spirit), Skill_HasEffect($Wandering_Eye), _
					 Skill_HasEffect($Wandering_Eye_PvP)
					Out("Can't Attack")
					Return False
			EndSwitch
		Case $Ritual, $Signet, $Glyph, $Shout, $Preparation, $Trap, $Chant, $EchoRefrain, $Disguise
			Switch True
				Case Skill_HasEffect($Diversion), Skill_HasEffect($Visions_of_Regret), _
					 Skill_HasEffect($Visions_of_Regret_PvP), Skill_HasEffect($Spiteful_Spirit)
					Return False
			EndSwitch
		Case $Shout, $Chant
			Switch True
				Case Skill_HasEffect($Cacophony), Skill_HasEffect($Ulcerous_Lungs), _
					 Skill_HasEffect($Vocal_Minority), Skill_HasEffect($Well_of_Silence)
					Return False
			EndSwitch
		Case $Signet
			Switch True
				Case Skill_HasEffect($Ignorance), Skill_HasEffect($Rust)
					Return False
			EndSwitch
	EndSwitch
	Return True

EndFunc   ;==>CanCast

;~ Tests if a skill can be used based on them belonging to one or more skill types;
;~ Tests if we have a valid target for the skillslot being tested
;~ Can also be used to cast other skills before the actual skill
Func CanUse($aSkillSlot, $aAggroRange = 1320)
; REVIEW: GwAu3 equivalent is UAI_CanUse(). Keep this while using Logic cache.
	;If Not CanCast($aSkillSlot) Then Return False
	If $aSkillSlot = "" Then Return
	If GetBestTargetBySkillSlot($aSkillSlot, $aAggroRange) = 0 Then Return False        ; This sets §besttarget global variable to the best target for the skillslot if valid
	If Skill_HasEffect($Glyph_Of_Sacrifice) And $aSkillSlot <> $SkillbarSlot[$Meteor_Shower] Then Return False

;~ BINDING RITUALS
	If $SkillBarCache[$aSkillSlot][$bind] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$bind]     ; binding ritual skills
			Case $Summon_Spirits_Kurzick, $Summon_Spirits_Luxon
				If Agent_GetNumberOfPressureSpirits(5000) > 0 And Agent_GetNumberOfPressureSpirits(1250) = 0 Then Return True
				If Agent_GetAgentInfo(Agent_GetLowestSpirit(), "HP") > 0.85 Then Return False
			Case $Spirit_Siphon
				Out("Spirit Energy" & Agent_GetAgentInfo(GetNearestSpirit(), "CurrentEnergy"))
				If Agent_GetAgentInfo(-2, "CurrentEnergy") > 30 Or Agent_GetAgentInfo(GetNearestSpirit(), "CurrentEnergy") < 19 Then Return False
			Case $Agony, $Agony_PvP, $Anguish, $Anguish_PvP, $Bloodsong, $Bloodsong_PvP, $Destruction, $Destruction_PvP, _
					$Disenchantment, $Disenchantment_PvP, $Dissonance, $Dissonance_PvP, $Gaze_of_Fury, $Gaze_of_Fury_PvP, _
					$Pain, $Pain_PvP, $Wanderlust, $Wanderlust_PvP, $Earthbind, $Earthbind_PvP, $Shadowsong, $Shadowsong_PvP, _
					$Signet_Of_Spirits, $Signet_of_Spirits_PvP, $Vampirism
					; Out("MySpirits: " & GetMySpiritCount() & " , My SpiritSkills: " & $PressureSpiritSkills)
				If Agent_GetMySpiritCount() >= $PressureSpiritSkills Then Return False
			Case $Signet_of_Ghostly_Might, $Signet_of_Ghostly_Might_PvP
				If Agent_GetMySpiritCount() < $PressureSpiritSkills Then Return False
			Case $Shelter, $Union, $Displacement, $Winter, $Edge_of_Extinction, $Soul_Twisting
				If Skill_HasEffect($SkillBarCache[$aSkillSlot][$bind]) Then Return False
				If Skill_GetSkillbarInfo($SkillbarSlot[$Soul_Twisting], "IsRecharged") And Not Skill_HasEffect($Soul_Twisting) Then Skill_UseSkill($SkillbarSlot[$Soul_Twisting], -2)
		EndSwitch
	EndIf

;~ SURVIVAL SKILLS
	If $SkillBarCache[$aSkillSlot][$survive] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$survive]
			Case $I_Am_Unstoppable
				If GetEffectTimeRemaining($Shadow_Form) > 5000 And Not Agent_GetAgentInfo(-2, "Knocked") Then Return False
			Case $Glyph_of_Swiftness
				If GetEffectTimeRemaining($Shadow_Form) > 5000 Then Return False
				If GetSkillbarSkillRecharge($SkillbarSlot[$Shadow_Form]) > 5000 Then Return False
			Case $Shadow_Form
				If GetEffectTimeRemaining($Shadow_Form) > 5000 Then Return False
				If GetEffectTimeRemaining($Glyph_of_Swiftness) = 0 Then Return False
			Case $Shroud_Of_Distress
				If Agent_GetAgentInfo(-2, "HP") > 0.9 Then Return False
				If GetEffectTimeRemaining($Shroud_Of_Distress) > 5000 Then Return False
			Case $Shadow_Sanctuary_Luxon, $Shadow_Sanctuary_Kurzick, $Shadow_Refuge
				If Agent_GetAgentInfo(-2, "HP") > 0.7 Then Return False
			Case $Heart_of_Shadow
				If Agent_GetAgentInfo(-2, "HP") > 0.5 Then Return False
			Case $Zealots_Fire
				If GetEffectTimeRemaining($Zealots_Fire) > 5000 Then Return False
				If GetEffectTimeRemaining($Protective_Spirit) < 5000 Then Return False
				If GetEffectTimeRemaining($Shield_of_Absorption) < 4000 And GetEffectTimeRemaining($Shielding_Hands) < 4000 Then Return False
			Case $Protective_Spirit
 				;If Not Skill_GetSkillbarInfo($SkillbarSlot[$Shield_of_Absorption]) Then Return False
				If GetEffectTimeRemaining($Protective_Spirit) > 6000 Then Return False
				; If GetEffectTimeRemaining($Shielding_Hands) > 4000 And GetEffectTimeRemaining($Protective_Spirit) > 4000 Then Return False
				;If GetEffectTimeRemaining($Shield_of_Absorption) <> 0 Then Return False
;~ 				If GetEffectTimeRemaining($Spirit_Bond) <> 0 And GetEffectTimeRemaining($Protective_Spirit) > 4000 Then Return False
			Case $Shield_of_Absorption
				;If GetEffectTimeRemaining($Protective_Spirit) < 12000 Then Return False
				If GetEffectTimeRemaining($Shielding_Hands) > 3500 Then Return False
			Case $Shielding_Hands
				If GetEffectTimeRemaining($Shield_of_Absorption) > 5000 Then Return False
			Case $Spirit_Bond
				If Skill_GetSkillbarInfo($SkillbarSlot[$Shielding_Hands]) And GetEffectTimeRemaining($Spirit_Bond) <> 0 Then Return False
				If GetEffectTimeRemaining($Spirit_Bond) > 3500 Or GetEffectTimeRemaining($Shielding_Hands) > 3500 Then Return False
			Case $Mystic_Regeneration
				If GetEffectTimeRemaining($Mystic_Regeneration) < 4000 Then Return True
			Case $Shield_of_Judgment
				; Out("SHPtr: " & GetSkillEffectPtr($Shielding_Hands))
				; Out("SH: " & Floor(GetEffectTimeRemaining($Shielding_Hands)) & ", " & "SoA:" & Floor(GetEffectTimeRemaining($Shield_of_Absorption)))
				If GetEffectTimeRemaining($Shielding_Hands) < 4500 And GetEffectTimeRemaining($Shield_of_Absorption) < 4500 Then Return False
		EndSwitch
	EndIf

;~ PRESSURE SKILLS
	If $SkillBarCache[$aSkillSlot][$pressure] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$pressure]
			Case $Finish_Him
				If DllStructGetData(Agent_GetCurrentTarget(), 'HP') > 0.45 Then Return False
			Case $Dark_Pact
				If DllStructGetData(Agent_GetByID(-2), 'HP') < 0.15 Then Return False
			Case $Scourge_Healing
				If Agent_GetAgentInfo(Agent_GetCurrentTarget(), "Hexed") Then Return False
			Case $Spear_of_Fury_Luxon, $Spear_of_Fury_Kurzick
				If Not Agent_GetAgentInfo(Agent_GetCurrentTarget(), "Condition") Then Return False
		EndSwitch
	EndIf

;~ SPEEDBOOST SKILLS
	If $SkillBarCache[$aSkillSlot][$speedBoost] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$speedBoost]
			Case $Dwarven_Stability
				If GetEffectTimeRemaining(GetEffect($Dwarven_Stability)) > 3000 Then Return False
			Case $Dark_Escape
				If GetEffectTimeRemaining(GetEffect($Dwarven_Stability)) = 0 Then Return False
			Case $Dash
				If GetEffectTimeRemaining(GetEffect($Dwarven_Stability)) = 0 Then Return False
		EndSwitch
	EndIf

;~ PRECAST SKILLS
	If $SkillBarCache[$aSkillSlot][$precast] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$precast]
			Case $Balthazars_Spirit
				If GetEffectTimeRemaining(GetEffect($Balthazars_Spirit)) <> 0 Then Return False
			Case $Blessed_Aura
				If GetEffectTimeRemaining(GetEffect($Blessed_Aura)) <> 0 Then Return False
			Case $Agony, $Agony_PvP, $Anguish, $Anguish_PvP, $Bloodsong, $Bloodsong_PvP, $Destruction, $Destruction_PvP, _
					$Disenchantment, $Disenchantment_PvP, $Dissonance, $Dissonance_PvP, $Gaze_of_Fury, $Gaze_of_Fury_PvP, _
					$Pain, $Pain_PvP, $Wanderlust, $Wanderlust_PvP, $Earthbind, $Earthbind_PvP, $Shadowsong, $Shadowsong_PvP, _
					$Signet_Of_Spirits, $Signet_of_Spirits_PvP, $Vampirism
				If Agent_GetNumberOfPressureSpirits() >= $PressureSpiritSkills Then Return False
			Case $Summon_Spirits_Kurzick, $Summon_Spirits_Luxon
				If Agent_GetNumberOfPressureSpirits() = 0 Or Agent_GetAgentInfo(Agent_GetLowestSpirit(), "HP") > 0.85 Then Return False
		EndSwitch
	EndIf

;~ HEAL SKILLS
	If $SkillBarCache[$aSkillSlot][$heal] <> "" Then
		$lowestally = GetLowestAlly()
		Switch $SkillBarCache[$aSkillSlot][$heal]
			Case $Word_of_Healing
				If Agent_GetAgentInfo($lowestally, "HP") > 0.5 Then Return False
			Case $Healing_Spring
				If Agent_GetAgentInfo(-2, "HP") > 0.95 Then Return False
			Case $Mend_Body_and_Soul
				If Agent_GetAgentInfo($lowestally, "HP") > 0.5 And Not Agent_GetAgentInfo($lowestally, "IsDead") Then Return False
			Case $Divine_Healing, $Heal_Party, $Heavens_Delight, $Protective_Was_Kaolai, $Protective_Was_Kaolai_PvP, $Heal_Party, $Mystic_Healing, $Mystic_Healing_PvP, $Courageous_Was_Saidra
				If GetPartyHealth() > 0.90 Or Agent_GetAgentInfo($lowestally, "HP") > 0.75 Then Return False
			Case Else
				If IsHealSkill($SkillBarCache[$aSkillSlot][$heal]) And Agent_GetAgentInfo($lowestally, "HP") > 0.8 Then Return False
				If IsSelfHealSkill($SkillBarCache[$aSkillSlot][$heal]) And Agent_GetAgentInfo(-2, "HP") > 0.8 Then Return False
		EndSwitch
	EndIf

;~ CONDITION REMOVE SKILLS
	If $SkillBarCache[$aSkillSlot][$condremove] <> "" Then
		If RequiresCondition($SkillBarCache[$aSkillSlot][$condremove]) And Not Agent_GetAgentInfo($MostConditionedAllyPtr, "IsDead") Then Return False
		$lowestally = GetLowestAlly()
		Switch $SkillBarCache[$aSkillSlot][$heal]
			Case $Martyr, $Pure_Was_Li_Ming
				If GetNumberOfConditionedAllies() = 0 Then Return False
			Case $Extinguish, $Breath_of_the_Great_Dwarf
				If GetNumberOfBurningAllies() = 0 Then Return False
			Case $Resilient_Was_Xiko
				If Not Agent_GetAgentInfo($MostConditionedAllyPtr, "IsDead") Then Return False
		EndSwitch
	EndIf

;~ HEX REMOVE SKILLS
	If $SkillBarCache[$aSkillSlot][$hexremove] <> "" Then
		$MostHexedAllyPtr = MostHexedAlly()

		If RequiresHex($SkillBarCache[$aSkillSlot][$hexremove]) And Not Agent_GetAgentInfo($BestTargetPtr, "IsDead") Then Return False

		Switch $SkillBarCache[$aSkillSlot][$hexremove]
			Case $Divert_Hexes, $Cure_Hex                                                         ;Heal and remove hex (me and ally)
				If Agent_GetAgentInfo($MostHexedAllyPtr, "HP") > 0.8 Then Return False
			Case $Blessed_Light                                                                 ;Heal remove hex or condition (me and ally)
				If Agent_GetAgentInfo($MostHexedAllyPtr, "HP") > 0.8 Then Return False
			Case $Contemplation_of_Purity                                                         ;If I have hex or condition (me only)
				If Agent_GetAgentInfo(-2, "HP") > 0.95 Then Return False
			Case $Withdraw_Hexes                                                                 ;affect ally adjacent (me and ally)
				If GetNumberOfAlliesNearAgent(300, $MostHexedAllyPtr) = 0 Then Return False
			Case $Holy_Veil                                                                     ;bond, remove hex (me and ally)
				;After use it DropBuff($holy_veil, $MostHexedAlly)
			Case $Pious_Restoration                                                             ;Remove Hex if I have Dervish enchantment (me only)
				If Not Agent_GetAgentInfo(-2, "Enchanted") Then Return False ;Maybe use IsDervishEnchantment ?
			Case $Purge_Signet                                                                     ;Removes all hex and all condition. (me and ally)
				If Not Agent_GetAgentInfo($MostHexedAllyPtr, "IsDead") Then Return False 					;Can remove if only want Remove Hex
			Case $Signet_of_Removal ;															Removes one hex and one condition. If target is enchanted. (me and ally)
				If Not Agent_GetAgentInfo($MostHexedAllyPtr, "Enchanted") Then Return False
			Case Else ;$Reverse_Hex, $Remove_Hex, $Expel_Hexes, $Inspired_Hex, $Revealed_Hex, $Spotless_Mind, $Convert_Hexes, $Deny_Hexes, _ ; remove hex (me and ally)
				Return True
		EndSwitch
	EndIf

;~  ECHOES, CHANTS AND SHOUTS
	If $SkillBarCache[$aSkillSlot][$echochantshout] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$echochantshout]
			Case $To_the_Limit
				If Agent_GetNumberOfEnemies($Earshot_Range) = 0 Then Return False
			Case $Save_Yourselves_Kurzick, $Save_Yourselves_Luxon, $Theres_Nothing_to_Fear
				If Skill_HasEffect($Cacophony) Or Skill_HasEffect($Vocal_Minority) Then UseHeroHexRemoval()
				; If GetNumberOfEnemies(1400) = 0 Then Return False We don't need this because when are not using those skills when enemies are not around
				If GetLowestAlly() > 0.90 Then Return False ;GetPartyHealth() > 0.9
			Case $Heroic_Refrain, $Mending_Refrain, $Bladeturn_Refrain, $Burning_Refrain
				If Agent_GetAgentInfo(-2, "CurrentEnergy") < 20 And Not Skill_HasEffect($Blood_is_Power) And Agent_GetAgentInfo(Agent_GetHero($BiP[0], "HP")) > 0.4 Then Skill_UseHero($BiP[0], $BiP[1], -2)
				If Agent_GetAgentInfo(-2, "IsDead") Then Return False
			Case $Go_for_the_Eyes, $Go_for_the_Eyes_PvP, $Burning_Refrain
				Return True
			Case Else
				If Skill_HasEffect($SkillBarCache[$aSkillSlot][$echochantshout]) Or Skill_HasEffect($Vocal_Minority) Then Return False
		EndSwitch
	EndIf

;~ INTERRUPTS
	If $SkillBarCache[$aSkillSlot][$rupt] <> "" Then Return False ; managed through event system

;~ 	Switch $SkillBarCache[$aSkillSlot][$all]
;~ 		Case $Ether_Signet
;~ 			If Agent_GetAgentInfo(-2, "CurrentEnergy") > 4 Then Return False
;~ 		Case $To_the_Limit
;~ 	EndSwitch

;~ JUNUNDU
	If $SkillBarCache[$aSkillSlot][$rupt] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$junundu]
			Case $Junundu_Strike	; only affects adjacent range but will run to enemy
				If Agent_GetNearestDistance() > $Earshot_Range Then Return False
				MoveTo(Agent_X($BestTargetPtr), Agent_Y($BestTargetPtr))
			Case $Burning_Breath, $Junundu_Siege1	; skill fails if target is closer than nearbyrange, check if we should move out of range before using
				If Agent_GetDistance($BestTargetPtr) < $Nearby_Range Then Return False
			Case $Blinding_Breath, $Choking_Breath, $Junundu_Smash ; untargeted skill, only affects adjacent foes
				If CanCast($SkillbarSlot[$Burning_Breath]) Or CanCast($SkillbarSlot[$Junundu_Siege1]) Then Return False
				MoveTo(Agent_X($BestTargetPtr), Agent_Y($BestTargetPtr))
			Case $Junundu_Bite	; does not heal if target is not knocked down and easily reachable
				If Not Agent_GetAgentInfo($BestTargetPtr, "Knocked") And Agent_GetDistance($BestTargetPtr) < $Nearby_Range Then Return False
			Case $Junundu_Feast
				If GetNumberOfCorpses($Adjacent_Range) = 0 Then Return False
			Case $Junundu_Tunnel	; stance is used on recharge as per CanCast() conditions
				For $aHero = 1 To GetPartySize() -1	; make heroes run with us, they won't use on their own
					For $aSkillSlot = 1 To 8
						$aSkillID = GetSkillbarInfo($i, "SkillID")($aSkillSlot, $aHero)
						If $aSkillID = $Junundu_Tunnel Then UseHeroSkill($aHero, $aSkillSlot)
					Next
				Next
			Case $Junundu_Wail	; touch skill, will run to enemy
				If Agent_GetNumberOfDeadAllies($Earshot_Range) = 0 And (Agent_GetAgentInfo(-2, "HP") > 0.8 Or Agent_GetNumberOfAllies($Earshot_Range) < 3 Or Agent_GetNumberOfEnemies($Earshot_Range) > 0) Then Return False
			Case $Leave_Junundu, $Unknown_Junundu_Ability
				Return False
		EndSwitch
	EndIf

;~  REZZ
	If $SkillBarCache[$aSkillSlot][$rezz] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$rezz]
			Case $Unyielding_Aura ; targeted spells will already fail if no valid target, but non targeted won't
				If Skill_HasEffect($Unyielding_Aura) And Agent_GetNearestDeadAlly($Earshot_Range) <> 0 Then DropBuff($Unyielding_Aura)
			Case $Eternal_Aura, $Restoration
				If Skill_HasEffect($SkillBarCache[$aSkillSlot][$rezz]) Then Return False
			Case $Junundu_Wail
				If Agent_GetNumberOfDeadAllies($Earshot_Range) = 0 And (Agent_GetAgentInfo(-2, "HP") > 0.8 Or Agent_GetNumberOfAllies($Earshot_Range) < 3 Or Agent_GetNumberOfEnemies($Earshot_Range) > 0) Then Return False
			Case Else
				If Agent_GetNumberOfDeadAllies($Earshot_Range) = 0 Then Return False
		EndSwitch
	EndIf

;~ HEX
	If $SkillBarCache[$aSkillSlot][$hexes] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$hexes]
			Case $Panic, $Panic_PvP, $Overload, $Mistrust, $Mistrust_PvP ; targeted spells will already fail if no valid target, but non targeted won't
				If Agent_GetAgentInfo($BestTargetPtr, "Knocked") Then Return False
		EndSwitch
	EndIf

;~  OTHER
    If $SkillBarCache[$aSkillSlot][$all] <> "" Then
        Switch $SkillBarCache[$aSkillSlot][$all]
            Case $Ineptitude, $Wandering_Eye, $Clumsiness, $Signet_of_Clumsiness, $Signet_of_Clumsiness_PvP
				If Agent_GetAgentInfo($BestTargetPtr, "Knocked") Then Return False
			Case $Accumulated_Pain
				If Not Agent_GetAgentInfo($BestTargetPtr, "IsDead") Then Return False
			Case $Vow_of_Piety
				If Skill_HasEffect($Vow_of_Piety) Then Return False
			Case $Glyph_Of_Sacrifice
				If Agent_GetAgentInfo(-2, "CurrentEnergy") < 30 Then Return False
				If Not CanCast($SkillbarSlot[$Meteor_Shower]) Then Return False
			Case $Meteor_Shower
				If Not Skill_HasEffect($Glyph_Of_Sacrifice) Then Return False
        EndSwitch
    EndIf

	Return True
EndFunc   ;==>CanUse

;~ Description: Finds the best target for a skillslot based on target requirements and the type of skill, and returns 0 if no good skill ca be used
Func GetBestTargetBySkillSlot($aSkillSlot, $aAggroRange = 1320)
	If Map_GetInstanceInfo("Type") == 2 Then Connection_CheckAndReconnect()
	If Map_GetInstanceInfo("Type") == 0 Then Return
	$MyPtr = Agent_GetAgentPtr(-2)
	Switch $SkillBarCache[$aSkillSlot][$hexes]
		Case $Panic, $Panic_PvP, $Wastrels_Worry, $Wastrels_Demise, $Wastrels_Demise_PvP, $Overload, $Mistrust, $Mistrust_PvP ; targeted spells will already fail if no valid target, but non targeted won't
			$BestTargetPtr = Agent_GetBestTarget($aAggroRange)
			Return $BestTargetPtr
		EndSwitch

	Switch $SkillBarCache[$aSkillSlot][$all]
		Case $Meteor_Shower, $Meteor
			$BestTargetPtr = Agent_GetBestTarget($aAggroRange)
			Return $BestTargetPtr
	EndSwitch

	Switch $SkillBarCache[$aSkillSlot][$target]
		Case 0	; self
			Switch $SkillBarCache[$aSkillSlot][$type]
				Case $Ward, $Ritual, $Signet
					If Agent_GetDistance(Agent_GetNearestEnemy()) > $aAggroRange Then Return False
				Case Else
					If $SkillBarCache[$aSkillslot][$precast] == 0 And Agent_GetDistance(Agent_GetNearestEnemy(-2)) > $aAggroRange Then Return False
					$BestTargetPtr = $MyPtr
			EndSwitch

		Case 3	; ally
			If $SkillBarCache[$aSkillSlot][$condremove] <> "" Then
				$BestTargetPtr = MostCondsAlly()
			ElseIf $SkillBarCache[$aSkillSlot][$hexremove] <> "" Then
				Switch $SkillBarCache[$aSkillSlot][$hexremove]
					Case $Hex_Eater_Signet, $Hex_Eater_Vortex, $Shatter_Hex, $Smite_Hex
						$BestTargetPtr = GetMostBalledHexedAlly()
					Case Else
						$BestTargetPtr = MostHexedAlly()
				EndSwitch
			ElseIf $SkillBarCache[$aSkillSlot][$precast] <> "" Then
				$BestTargetPtr = $MyPtr
			ElseIf $SkillBarCache[$aSkillSlot][$survive] <> "" Then
				$BestTargetPtr = $MyPtr
			ElseIf $SkillBarCache[$aSkillSlot][$type] = $EchoRefrain Then
				$BestTargetPtr = NeedEchoAlly($SkillBarCache[$aSkillSlot][$echochantshout])
			Else
				$BestTargetPtr = GetLowestAlly()
			EndIf
		Case 4	; other ally
			If $SkillBarCache[$aSkillSlot][$condremove] <> "" Then
				$BestTargetPtr = MostCondsAlly(True)
			ElseIf $SkillBarCache[$aSkillSlot][$hexremove] <> "" Then
				$BestTargetPtr = MostHexedAlly(True)
			ElseIf $SkillBarCache[$aSkillSlot][$heal] <> "" Then
				$BestTargetPtr = GetLowestAlly(True)
			ElseIf $SkillBarCache[$aSkillSlot][$precast] <> "" Then
				$BestTargetPtr = $MyPtr
			ElseIf $SkillBarCache[$aSkillSlot][$survive] <> "" Then
				$BestTargetPtr = $MyPtr
			ElseIf $SkillBarCache[$aSkillSlot][$type] = $EchoRefrain Then
				$BestTargetPtr = NeedEchoAlly($SkillBarCache[$aSkillSlot][$echochantshout])
			Else
				$BestTargetPtr = GetLowestAlly(True)
			EndIf

		Case 5	; enemy,
			If $SkillBarCache[$aSkillSlot][$hexes] <> "" Then
				$BestTargetPtr = GetNoHexEnemy($aAggroRange) = 0
				If $BestTargetPtr = 0 Then $BestTargetPtr = Agent_GetBestTarget($aAggroRange)
			ElseIf $SkillBarCache[$aSkillSlot][$enchantremove] <> "" Then
				$BestTargetPtr = GetBalledEnchantedEnemy($aAggroRange)
			ElseIf $SkillBarCache[$aSkillSlot][$attackskill] <> "" Then
				$BestTargetPtr = GetBestMeleeTarget($SkillBarCache[$aSkillSlot][$attackskill])
			ElseIf $SkillBarCache[$aSkillSlot][$rupt] <> "" Then
				$BestTargetPtr = GetMostBalledCastingEnemy($aAggroRange)    ; finds only enemies that are casting a spell
			Else
				Switch $SkillBarCache[$aSkillSlot][$all]
					Case $Unnatural_Signet
						$BestTargetPtr = Agent_GetBestTarget(1320, False, True)
						If $BestTargetPtr = 0 then $BestTargetPtr = Agent_GetBestTarget($aAggroRange)
					Case Else
						$BestTargetPtr = Agent_GetBestTarget($aAggroRange)
					EndSwitch
			EndIf
		Case 6	; dead ally
			$BestTargetPtr = Agent_GetNearestDeadAlly()
		Case 14	; spirit, minion
			$BestTargetPtr = GetNearestMinionAlly()
	EndSwitch


	If $BestTargetPtr <> 0 Then Return $BestTargetPtr
	Return 0

EndFunc   ;==>GetBestTargetBySkillSlot

Func Survive($aAggroRange = 1500)
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	If CanUse($SkillbarSlot[$I_Am_Unstoppable], $aAggroRange) Then Skill_UseSkill($SkillbarSlot[$I_Am_Unstoppable])
	If CanUse($SkillbarSlot[$Glyph_of_Swiftness], $aAggroRange) Then Skill_UseSkill($SkillbarSlot[$Glyph_of_Swiftness])
	If CanUse($SkillbarSlot[$Shadow_Form], $aAggroRange) Then Skill_UseSkill($SkillbarSlot[$Shadow_Form])

	If CanUse($SkillbarSlot[$Protective_Spirit], $aAggroRange) Then Skill_UseSkill($SkillbarSlot[$Protective_Spirit])
	If CanUse($SkillbarSlot[$Shielding_Hands], $aAggroRange) Then Skill_UseSkill($SkillbarSlot[$Shielding_Hands])
;~ 	If CanUse($SkillbarSlot[$Spirit_Bond]) Then Skill_UseSkill($SkillbarSlot[$Spirit_Bond])

	For $aSkillSlot In $Skillbar
		If Agent_GetAgentInfo(-2, "IsDead") Then ExitLoop
		If Agent_GetAgentInfo(-2, "HP") < 0.9 And TimerDiff($MysticTimer) > 500 And UBound($HeroHeals) <> 0 Then
			Skill_UseHero($HeroHeals[$HealCount][1], $HeroHeals[$HealCount][2], 0)
			$MysticTimer = TimerInit()
			$HealCount += 1
			If $HealCount > UBound($HeroHeals) - 1 Then $HealCount = 0
		EndIf

		If $SkillBarCache[$aSkillSlot][$survive] = "" Then ContinueLoop
		If CanUse($aSkillSlot, $aAggroRange) Then Skill_UseSkill($aSkillSlot, $BestTargetPtr)
	Next
EndFunc   ;==>Survive

Func Precast($aAggroRange = $compass_range, $precastspirits = True)
	If $precastspirits Then PrecastWardsAndSpirits()
	If CanUse($SkillbarSlot[$Ebon_Battle_Standard_Of_Honor], $longbow_range) Then Skill_UseSkill($SkillbarSlot[$Ebon_Battle_Standard_Of_Honor])
	If CanUse($SkillbarSlot[$Summon_Spirits_Luxon]) Then Skill_UseSkill($SkillbarSlot[$Summon_Spirits_Luxon])
	If CanUse($SkillbarSlot[$Painful_Bond]) Then Skill_UseSkill($SkillbarSlot[$Painful_Bond], $BestTargetPtr)
	If CanUse($SkillbarSlot[$Boon_Of_Creation]) Then Skill_UseSkill($SkillbarSlot[$Boon_Of_Creation])
EndFunc   ;==>Precast

Func SpreadChants()
	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$echochantshout] = "" Then ContinueLoop
		If CanUse($aSkillSlot) Then Skill_UseSkill($aSkillSlot, $BestTargetPtr)
	Next
EndFunc   ;==>SpreadChants

Func Precastupkeep()
	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$precast] = "" Then ContinueLoop
		If CanUse($aSkillSlot) Then Skill_UseSkill($aSkillSlot, -2)
	Next
EndFunc   ;==>Precastupkeep

Func SpeedBoost()
	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$speedBoost] = "" Then ContinueLoop
		If CanUse($aSkillSlot) Then Skill_UseSkill($aSkillSlot, $BestTargetPtr)
	Next
EndFunc   ;==>SpeedBoost

Func Bind($aAggroRange = $longbow_range)
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $bind)
EndFunc   ;==>Bind

Func Pressure($aAggroRange = $longbow_range)
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $pressure)
EndFunc   ;==>Pressure

Func AttackEnemies($aAggroRange = $longbow_range)
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $attackskill)
EndFunc   ;==>AttackEnemies

Func Heal($aAggroRange = $spellcasting_range)
	Out("Using heal skills")
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $prot)
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $condremove)
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $hexremove)
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $heal)

EndFunc   ;==>Heal

Func Rezz($aAggroRange = 5000)
	Out("Resurrecting")
	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$rezz] = "" Then ContinueLoop
		If CanUse($aSkillSlot) Then Skill_UseSkill($aSkillSlot, $BestTargetPtr)
	Next
EndFunc    ;==>Rezz

Func Interrupt($aAggroRange = $bowpull_range)
	Out("Using interrupt skills")
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $Rupt)
EndFunc   ;==>Interrupt

Func Defend($aAggroRange = $spellcasting_range)
	Out("Using defensive skills")
	UseSkills(Agent_X(), Agent_Y(), $aAggroRange, $defend)
EndFunc   ;==>Defend

#Region Skill Controls
Func IsSurvivalSkill($aSkillID)    ; to be expanded based on your needs
	Switch $aSkillID
		Case $I_Am_Unstoppable, $Shadow_Form, $Shroud_of_Distress, $Glyph_of_Swiftness, $Shadow_Sanctuary_Luxon, $Shadow_Sanctuary_Kurzick _
				, $Heart_of_Shadow, $Way_Of_The_Master, $Shadow_Refuge, $Protective_Spirit, $Shield_of_Absorption, $Shielding_Hands _
				, $Mystic_Regeneration, $Shield_of_Judgment, $Spirit_Bond, $Zealots_Fire
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsSurvivalSkill

Func IsPrecastSkill($aSkillID) ; priority skills used first in a fight, to be expanded based on your needs
	If IsPressureSpiritSkill($aSkillID) Then Return True
	Switch $aSkillID
		Case $Balthazars_Spirit, $Blessed_Aura, $Boon_Of_Creation
			Return True
	EndSwitch
	If IsSelfPrehealSkill($aSkillID) Then Return True
	If IsDisguiseskill($aSkillID) Then Return True
	If Memory_Read(Skill_GetSkillPtr($aSkillID) + 12, "long") = $Ward Then Return True ; Type
	Return False
EndFunc   ;==>IsPrecastSkill

Func IsPressureSkill($aSkillID) ; to be expanded based on your needs

	If IsConditionSpell($aSkillID) Then Return True
	If IsHexSpell($aSkillID) Then Return True
	Switch $aSkillID
		Case $Ebon_Vanguard_Assassin_Support, $Ebon_Battle_Standard_Of_Honor, $Finish_Him, $Dark_Pact, $Spear_of_Fury_Luxon, _
				$Spear_of_Fury_Kurzick
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsPressureSkill

Func NumberOfRechargedSkills()
	Local $lRechargedSkills = 0
	For $i = 1 To 8
		If GetSkillbarSkillRecharge($i) == 0 Then
			$lRechargedSkills += 1
		EndIf
	Next
	Return $lRechargedSkills
EndFunc   ;==>NumberOfRechargedSkills

Func SkillSleep($nSkillID)
	$aSkill = GetSkillByID($nSkillID)
	$nActivationTime = DllStructGetData($aSkill, 'Activation') * 1000
	Sleep($nActivationTime + 100)
EndFunc   ;==>SkillSleep

Func GetAvailableRezz()        ; returns the number of available rezz skills excluding dead party members, use to force move, aggro and death when no more rezz is available
	Local $aHeroRezzSkills = 0
	For $aHeroNumber = 0 To GetPartySize() - 1
		$aHeroPtr = Agent_GetHero($aHeroNumber)
		If Agent_GetAgentInfo($aHeroPtr, "IsDead") Or Agent_GetDistance($aHeroPtr) > 5000 Then ContinueLoop
		;Out($aHeroNumber & " - Hero ID" & ID($aHeroPtr) & " , dead = " & Agent_GetAgentInfo($aHeroPtr))
		For $aSkillSlot = 1 To 8
			$aSkill = GetSkillbarInfo($i, "SkillID")($aSkillSlot, $aHeroNumber)
			If IsResSkill($aSkill) Then
				;Out("Skill " & $aSkillSlot & " on Hero " & $aHeroNumber & "(ID = " & GetHeroID($aHeroNumber) & ") is a rezz. Dead = " & Agent_GetAgentInfo(GetHeroPtr($aHeroNumber)))
				; Out("Hero HP: " & Agent_GetAgentInfo(GetHeroPtr($aHeroNumber, "HP")))
				$aHeroRezzSkills += 1
			EndIf
		Next
	Next
	Return $aHeroRezzSkills
EndFunc   ;==>GetAvailableRezz

Func IsResSkill($aSkill)
	Switch $aSkill
		Case $By_Urals_Hammer, $We_Shall_Return, $Death_Pact_Signet, $Eternal_Aura, $Flesh_of_My_Flesh, $Junundu_Wail, $Light_of_Dwayna, $Lively_Was_Naomei, $Rebirth, $Renew_Life, _
				$Restoration, $Restore_Life, $Resurrect, $Resurrection_Chant, $Resurrection_Signet, $Signet_of_Return, $Sunspear_Rebirth_Signet, $Unyielding_Aura, $Vengeance
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsResSkill

Func IsJununduSkill($aSkill)
	Switch $aSkill
		Case $Blinding_Breath, $Burning_Breath, $Choking_Breath, $Junundu_Bite, $Junundu_Feast, $Junundu_Siege1, $Junundu_Siege2 _
			,$Junundu_Smash, $Junundu_Strike, $Junundu_Tunnel, $Junundu_Wail, $Leave_Junundu, $Unknown_Junundu_Ability
	EndSwitch
	Return False
EndFunc

Func IsTargetedHealSkill($aSkill)    ; incomplete list, add based on your needs
	Switch $aSkill
		Case $Gift_of_Health, $Heal_Other, $Healing_Ribbon, $Healing_Ring, $Healing_Seed, $Infuse_Health, $Jameis_Gaze, $Mend_Body_and_Soul, $Mystic_Healing _
				, $Spirit_Light, $Spirit_Transfer, $Word_of_Healing
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsTargetedHealSkill

Func IsPartyHealSkill($aSkill)    ; incomplete list, add based on your needs
	Switch $aSkill
		Case $Divine_Healing, $Heal_Party, $Heavens_Delight, $Protective_Was_Kaolai, $Mystic_Healing, $Mystic_Healing_PvP, $Courageous_Was_Saidra
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsPartyHealSkill

Func IsSelfPrehealSkill($aSkill)    ; contains only instant, non condititional, self-targeted heals
	Switch $aSkill
		Case $Healing_Breeze, $Healing_Hands, $Mending, $Patient_Spirit, $Restful_Breeze, $Spirit_Bond, $Vigorous_Spirit _                        ; Monk Skills
				, $Conviction, $Faithful_Intervention, $Mystic_Regeneration, $Mystic_Vigor, $Pious_Renewal, $Vital_Boon, $Watchful_Intervention _ ; Dervish Skills
				, $Feigned_Neutrality, $Shadow_Refuge, $Shadow_Sanctuary_Luxon, $Shadow_Sanctuary_Kurzick, $Shroud_of_Distress _                  ; Assassin Skills
				, $Healing_Spring, $Troll_Unguent _                                                                                               ; Ranger Skills
				, $Blood_Renewal, $Hexers_Vigor                                                                                                   ; Necro Skills
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsSelfPrehealSkill

Func IsBondSkill($aSkill)
	Switch $aSkill
		Case $Balthazars_Spirit, $Essence_Bond, $Life_Barrier, $Life_Bond, $Mending, $Protective_Bond, $Purifying_Veil, $Retribution, $Strength_of_Honor, $Succor
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsBondSkill

;~ Tests if a skill is a condition removal skill - to be expanded
Func IsCondRemoveSkill($aSkill)
	Switch $aSkill
		Case $mend_ailment, $purge_conditions, $mending_touch, $Mend_Body_and_Soul, $Spotless_Soul
			Return True
	EndSwitch
	If IsHexAndConditionRemoveSkill($aSkill) Then Return True
	Return False
EndFunc   ;==>IsCondRemoveSkill

;~ Tests if a skill is a hex removal skill
Func IsHexRemoveSkill($aSkill)
	Switch $aSkill
		Case $Smite_Hex, $Divert_Hexes, $Cure_Hex, $Hex_Eater_Vortex, $Shatter_Hex, $Reverse_Hex, $Remove_Hex, $Expel_Hexes, $Inspired_Hex, $Revealed_Hex, $Spotless_Mind, $Convert_Hexes, $Deny_Hexes, _ ; remove hex (me and ally)
				$Hex_Eater_Signet, $Withdraw_Hexes, $Hexbreaker_Aria, $holy_veil, $Pious_Restoration
			Return True
	EndSwitch
	If IsHexAndConditionRemoveSkill($aSkill) Then Return True
	Return False
EndFunc   ;==>IsHexRemoveSkill

Func IsHexAndConditionRemoveSkill($aSkillID)
	Switch $aSkillID
		Case $Peace_and_Harmony, $Empathic_Removal, $Blessed_Light, $Contemplation_of_Purity, $Purge_Signet, $Signet_of_Removal
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsHexAndConditionRemoveSkill

Func IsSpeedBoost($aSkill)
	Switch $aSkill
		Case $Dwarven_Stability    ; used to potentiate running, to be used before stances
			Return True
		Case $Illusion_of_Haste, $Windborne_Speed, $Armor_of_Mist, $Storm_Djinns_Haste, $Rush, $Sprint, $Charge, $Bulls_Charge, $Dodge, $Escape, $Storm_Chaser, $Run_as_One, _
				$Retreat, $Gust, $Torch_Hex, $Torch_Degeneration_Hex, $Dark_Escape, $Dash, $Zojuns_Haste, $Flame_Djinns_Haste, _
				$Enraging_Charge, $Lyssas_Haste, $Lyssas_Haste_PvP, $Avatar_of_Balthazar, $Enchanted_Haste, $Pious_Haste, $Whirling_Charge, $Godspeed, $Make_Haste, $Fall_Back, $Incoming, $Onslaught, _
				$Featherfoot_Grace, $Harriers_Haste, $Hasty_Refrain, $Soldiers_Speed, $Drunken_Master, $Ursan_Roar, $Volfen_Pounce, $Escape_PvP, $Charging_Strike, _
				$Battle_Rage, $Natural_Stride, $Storms_Embrace, $Junundu_Tunnel, $Flee, $Ursan_Force, $Incoming_PvP, $Its_Just_a_Flesh_Wound, $Fall_Back_PvP, _
				$Call_of_Haste, $Call_of_Haste_PvP, $Lead_the_Way, $Fleeting_Stability, $Illusion_of_Haste_PvP, $Mindbender, $Rampage_as_One
			Return True
		Case $Aggressive_Refrain, $Heroic_Refrain, $Theyre_on_Fire, $Burning_Refrain, $To_the_Limit	; ensures Heroic refrain is being ramped up / maintained outside of aggro
			Return True
		Case $Junundu_Wail
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsSpeedBoost

Func IsSpeedAttackBoost($aSkill)
	Switch $aSkill
		Case $Primal_Rage, $Experts_Dexterity, $Experts_Dexterity_PvP, $Soldiers_Stance_PvP, $Soldiers_Stance, $Dwarven_Battle_Stance, $Heart_of_Fury, $Heart_of_Fury_PvP, $Pious_Fury_PvP, $Pious_Fury, $Flail, _
				$Burst_of_Aggression, $Tiger_Stance, $Flurry, $Tigers_Fury, $Bestial_Fury, $Berserker_Stance, $Lightning_Reflexes, $Lightning_Reflexes_PvP, $Hekets_Rampage, $Frenzy, $Volfen_Bloodlust, $Volfen_Bloodlust, _
				$I_Will_Avenge_You, $Aggressive_Refrain, $Critical_Agility, $Drunken_Master, $Feral_Aggression, $Never_Rampage_Alone, $Onslaught, $Predatory_Bond, $Rampage_as_One, $Rapid_Fire, $Soldiers_Fury, _
				$Weapon_of_Aggression, $Way_Of_the_Assassin
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsSpeedAttackBoost

; Returns whether a skill is a hex spell
Func IsHexSpell($aSkill)
; REVIEW: GwAu3 equivalent is Skill_IsHexType()
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Hex
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Hex
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Hex
	EndIf
EndFunc   ;==>IsHexSpell

; Returns whether a skill is a condition spell
Func IsConditionSpell($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Condition
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Condition
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Condition
	EndIf
EndFunc   ;==>IsConditionSpell

; Returns whether a skill is a Ritual spell
Func IsRitualSkill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Local $lskillid = Memory_Read($aSkill + 12, "long") = $Ritual
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Local $lskillid = DllStructGetData($aSkill, "Type") = $Ritual
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Ritual
	EndIf
EndFunc   ;==>IsRitualSkill

Func IsWeaponSpell($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Local $lskillid = Memory_Read($aSkill + 12, "long") = $WeaponSpell
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Local $lskillid = DllStructGetData($aSkill, "Type") = $WeaponSpell
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $WeaponSpell
	EndIf
EndFunc   ;==>IsWeaponSpell

; Returns whether a skill is an enchantment skill
Func IsEnchantmentSkill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Enchantment
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Enchantment
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Enchantment
	EndIf
EndFunc   ;==>IsEnchantmentSkill

; Returns whether a skill is an attack skill
Func IsAttackSkill($aSkill)
; REVIEW: GwAu3 equivalent is Skill_IsAttackType()
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Attack
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Attack
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Attack
	EndIf
EndFunc   ;==>IsAttackSkill

Func IsStanceskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Stance
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Stance
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Stance
	EndIf
EndFunc   ;==>IsStanceskill

Func Skill_IsSpellskill($aSkill)
; REVIEW: GwAu3 equivalent is Skill_IsSpellType() or Skill_IsType($id, $GC_I_SKILL_TYPE_SPELL)
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Spell
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Spell
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Spell
	EndIf
EndFunc   ;==>IsSpellskill

Func IsSignetskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Signet
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Signet
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Signet
	EndIf
EndFunc   ;==>IsSignetskill

Func IsWellskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Well
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Well
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Well
	EndIf
EndFunc   ;==>IsWellskill

Func IsSkill($aSkill)
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $SKILL
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $SKILL
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $SKILL
	EndIf
EndFunc   ;==>IsSkill

Func IsWardskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Ward
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Ward
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Ward
	EndIf
EndFunc   ;==>IsWardskill

Func IsGlyphskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Glyph
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Glyph
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Glyph
	EndIf
EndFunc   ;==>IsGlyphskill

Func IsShoutskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Shout
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Shout
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Shout
	EndIf
EndFunc   ;==>IsShoutskill

Func IsPreparationskill($aSkill)
; REVIEW: GwAu3 equivalent is Skill_IsPreparationType() or Skill_IsType(..., $GC_I_SKILL_TYPE_PREPARATION)
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Preparation
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Preparation
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Preparation
	EndIf
EndFunc   ;==>IsPreparationskill

Func IsTrapskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Trap
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Trap
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Trap
	EndIf
EndFunc   ;==>IsTrapskill

Func IsItemSpellskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $ItemSpell
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $ItemSpell
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $ItemSpell
	EndIf
EndFunc   ;==>IsItemSpellskill

Func IsChantskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Chant
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Chant
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Chant
	EndIf
EndFunc   ;==>IsChantskill

Func IsEchoRefrainskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $EchoRefrain
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $EchoRefrain
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $EchoRefrain
	EndIf
EndFunc   ;==>IsEchoRefrainskill

Func IsDisguiseskill($aSkill)
; REVIEW: GwAu3 has Skill_Is*Type() helpers for this. Consider wrapping later.
	If IsPtr($aSkill) <> 0 Then
		Return Memory_Read($aSkill + 12, "long") = $Disguise
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return DllStructGetData($aSkill, "Type") = $Disguise
	Else
		Return Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long") = $Disguise
	EndIf
EndFunc   ;==>IsDisguiseskill

Func IsBindingSkill($aSkillID)
	Switch $aSkillID
		Case $Ebon_Battle_Standard_of_Honor
			Return True    ; not binding ritual but grouped together for convenience purposes
		Case $Agony, $Agony_PvP, $Anguish, $Anguish_PvP, _
				$Bloodsong, $Bloodsong_PvP, $Call_to_the_Spirit_Realm, $Destruction, $Destruction_PvP, _
				$Disenchantment, $Disenchantment_PvP, $Disenchantment_Togo, $Dissonance, $Dissonance_PvP, _
				$Gaze_of_Fury, $Gaze_of_Fury_PvP, $Jack_Frost, $Life, $Pain, $Pain_PvP, $Wanderlust, $Wanderlust_PvP, _
				$Displacement, $Displacement_PvP, $Earthbind, $Earthbind_PvP, $Empowerment, $Empowerment_PvP, _
				$Preservation, $Preservation_PvP, $Recovery, $Recovery_PvP, $Recuperation, $Recuperation_PvP, _
				$Rejuvenation, $Rejuvenation_PvP, $Shadowsong, $Shadowsong_PvP, $Shelter, $Shelter_PvP, _
				$Signet_of_Creation, $Signet_of_Creation_PvP, $Signet_Of_Spirits, $Signet_of_Spirits_PvP, _
				$Soothing, $Soothing_PvP, $Union, $Union_PvP, $Vampirism
			Return True
		Case $Summon_Spirits_Luxon, $Summon_Spirits_Kurzick ; used in binding builds
			Return True
		Case $Ritual_Lord, $Ritual_Lord_PvP ; used in binding builds
			Return True
		Case $Soul_Twisting ; used in binding builds
			Return True
		Case $Armor_of_Unfeeling, $Armor_of_Unfeeling_PvP, $Signet_of_Ghostly_Might, $Signet_of_Ghostly_Might_PvP ; used in binding builds
			Return True
		Case $Spiritleech_Aura ; used in binding builds
			Return True
		Case $Winter, $Edge_of_Extinction ; Used for DoA
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsBindingSkill

Func IsPressureSpiritSkill($aSkillID)
	Switch $aSkillID
		Case $Agony, $Agony_PvP, $Anguish, $Anguish_PvP, $Bloodsong, $Bloodsong_PvP, $Destruction, $Destruction_PvP, _
				$Disenchantment, $Disenchantment_PvP, $Dissonance, $Dissonance_PvP, $Gaze_of_Fury, $Gaze_of_Fury_PvP, _
				$Pain, $Pain_PvP, $Wanderlust, $Wanderlust_PvP, $Earthbind, $Earthbind_PvP, $Shadowsong, $Shadowsong_PvP, _
				$Signet_Of_Spirits, $Signet_of_Spirits_PvP, $Vampirism
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsPressureSpiritSkill

Func IsProtectiveSkill($aSkill)
	Local $lSkillID = GetSkillID($aSkill)

	Switch $lSkillID
		Case $Spirit_Bond, $Spirit_Bond_PvP, $Protective_Spirit, $Shield_of_Absorption, $Guardian, $Weapon_of_Warding, $Weapon_of_Warding_PvP, $Aegis, $Aegis_PvP, _
		$Reversal_of_Fortune, $Life_Sheath, $Weapon_of_Remedy, $Xinraes_Weapon, $Resilient_Weapon, $Weapon_of_Shadow, $Vengeful_Weapon, $Aura_of_Stability, $Reversal_of_Damage
	EndSwitch
	Return False
EndFunc   ;==>IsRuptSkill

Func IsRuptSkill($aSkill, $hardrupt = False)
; REVIEW: Keep this. Uses Effect2 bit (+0x20) + soft-rupt exceptions. GwAu3 has no direct equivalent.
	Local $lSkillEffect2 = Memory_Read(Skill_GetSkillPtr($aSkill) + 32, 'long')
	Local $lSkillID = GetSkillID($aSkill)

	Switch $lSkillID	; interrupt skills that are incorrectly categorized via Effect2 or soft rupts for separation
		Case $Power_Drain, $Power_Flux, $Power_Leak, $Power_Leech, $Power_Lock, $Power_Return, $Power_Spike, $Leech_Signet    ; soft rupts
			If Not $hardrupt Then Return True
		Case $You_Move_Like_a_Dwarf, $Disarm, $Disrupting_Shot, $Disrupting_Throw, $Distracting_Lunge, $Distracting_Strike, $Magebane_Shot, $Concussion_Shot
			Return True
		Case $Cry_of_Pain, $Overload, $Psychic_Instability, $Psychic_Instability_PvP, $Simple_Thievery, $Tease    ; overoad/SoC lumped here for convenience
			Return True
		Case $Exhausting_Assault, $Temple_Strike, $Lyssas_Assault, $Lyssas_Haste, $Lyssas_Haste_PvP, $Thunderclap
			Return True
		Case $Psychic_Distraction, $Complicate, $Tease, $Web_of_Disruption, $Web_of_Disruption_PvP, $Disrupting_Dagger, $Signet_of_Disruption
			Return True
		Case $Signet_of_Clumsiness
			Return True
		Case $Choking_Breath	; Junundu
			Return True
		Case Else
			If BitAND($lSkillEffect2, 1) Then Return True
	EndSwitch
	Return False
EndFunc   ;==>IsRuptSkill

Func IsHardRuptSkill($aSkillID)
; REVIEW: Thin wrapper around IsRuptSkill(..., True). Keep.
	Return IsRuptSkill($aSkillID, True)
EndFunc   ;==>IsHardRuptSkill

Func IsBlock($aSkill)
	Switch $aSkill
		Case 1142, 380, 388, 345, 376, 1700, 372, 810, 387, 363, 378, 1699, 1698, 3156, 377, 452, 448, 3060, 453, 3141, 1727, 450, 11, 1042, 2208, 1500, 2201
			Return 1
		Case Else
			Return 0
	EndSwitch
EndFunc

Func IsBalanced($aSkill)
	Switch $aSkill
		Case 371, 361, 1701, 1514
			Return 1
		Case Else
			Return 0
	EndSwitch
EndFunc

Func IsAnnoyingSkill($aSkill)
	Local $lSkillID = GetSkillID($aSkill)

	Switch $lSkillID	; interrupt skills that are incorrectly categorized via Effect2 or soft rupts for separation
		Case $Diversion, $Visions_of_Regret, $Visions_of_Regret_PvP, $Backfire, $Soul_Leech, $Guilt, $Mistrust, $Mistrust_PvP
			Return 1 ;For any caster
		Case $Shame, $Mark_of_Subversion
			Return 2 ;If caster target ally
		Case $Wandering_Eye, $Clumsiness, $Ineptitude, $Signet_of_Clumsiness, $Signet_of_Clumsiness_PvP, $Empathy, $Insidious_Parasite, $Spiteful_Spirit
			Return 3 ;For anay attack
		Case $Bulls_Strike, $Enraged_Smash, $Water_Trident, $Slippery_Ground, $Quivering_Blade
			Return 4 ;If i'm moving
		Case $Backbreaker, $Devastating_Hammer, $Earth_Shaker, $Hammer_Bash, $Horns_of_the_Ox, $Trampling_Ox, $Reapers_Sweep
			Return 5 ;Melee Attack can knock down
		Case $Magehunters_Smash, $Grapple, $Shove, $Signet_of_Judgment_PvP, $Earthquake, $Dragons_Stomp, $Gale, $Meteor, $Shock, $Entangling_Asp, $Gust, $Mind_Shock, $Stoning, $Iron_Palm
			Return 6 ;Skill can knock down
		Case $Overbearing_Smash, $Broad_Head_Arrow, $Spear_Swipe, $Stunning_Strike, $Golden_Skull_Strike, $Temple_Strike
			Return 7 ;Attack cause dazed
		Case $Black_Spider_Strike, $Falling_Lotus_Strike, $Falling_Spider, $Vampiric_Assault, $Golden_Phoenix_Strike, $Lotus_Strike, $Moebius_Strike, $Blades_of_Steel, $Critical_Strike, _
			$Death_Blossom, $Death_Blossom_PvP, $Twisting_Fangs, $Golden_Fang_Strike
			Return 8 ;Melee pression attack
		Case $Disrupting_Chop, $Distracting_Blow, $Savage_Slash, $Skull_Crack, $Distracting_Shot, $Punishing_Shot, $Savage_Shot, $Disrupting_Stab, $Signet_of_Distraction, $Power_Block
			Return 9 ;Signet on melee
		Case $Signet_of_Clumsiness, $Signet_of_Clumsiness_PvP, $Wandering_Eye, $Clumsiness, $Ineptitude, $Empathy, $Insidious_Parasite
			Return 10
		Case Else
			Return 0
	EndSwitch
	Return False
EndFunc   ;==>IsAnnoyingSkill

Func IsAoESkill($aSkill)
	Local $lSkillID = GetSkillID($aSkill)

	Switch $lSkillID
		;Area Range and skill with 1sec casting or more
		Case $Chilblains, $Deathly_Swarm, $Deep_Freeze, $Fevered_Dreams, $Fevered_Dreams_PvP, $Meekness, $Unholy_Feast, $Unholy_Feast_PvP, $Contagion, $Hypochondria, $Smite_Hex, _
			$Spiritual_Pain, $Spiritual_Pain_PvP, $Vampiric_Swarm
			Return 1
		;nearby and Skill with more than 1sec casting only
		Case $Arc_Lightning, $Chain_Lightning, $Churning_Earth, $Defile_Enchantments, $Depravity, $Desecrate_Enchantments, _
			$Dragons_Stomp, $Earthquake, $Energy_Surge, $Eruption, $Mistrust, $Mistrust_PvP, $Panic, $Panic_PvP, $Painful_Bond, _
			$Phoenix, $Rodgorts_Invocation, $Shared_Burden, $Shared_Burden_PvP, $Shatterstone, $Signet_of_Weariness, _
			$Ulcerous_Lungs, $Vocal_Minority, $Wandering_Eye, $Wandering_Eye_PvP, $Whirlwind, $Signet_of_Agony, $Signet_of_Agony_PvP, $Air_of_Disenchantment, _
			$Binding_Chains, $Clamor_of_Souls, $Earthen_Shackles, $Enfeebling_Blood, $Enfeebling_Blood_PvP, $Hex_Eater_Vortex, $Icy_Prism, $Icy_Veins, $Invoke_Lightning, _
			$Lamentation, $Lava_Arrows, $Lingering_Curse, $Liquid_Flame, $Mark_of_Rodgort, $Painful_Bond, $Putrid_Bile, $Ravenous_Gaze, $Searing_Flames1, $Suffering
			Return 2
		;adjacent and Skill with more than 1sec casting only
		Case $Arcane_Conundrum, $Clumsiness, $Enchanters_Conundrum, $Epidemic, $Feast_of_Corruption, $Fireball, _
			$Meteor, $Mind_Burn, $Shadow_of_Fear, $Soothing_Images, $Spiteful_Spirit, $Visions_of_Regret, $Visions_of_Regret_PvP, _
			$Aneurysm, $Ash_Blast, $Barbed_Signet, $Barrage, $Blinding_Surge, $Lightning_Touch, $Blood_Bond, $Blurred_Vision, $Chilling_Winds, _
			$Dulled_Weapon, $Fragility, $Glimmering_Mark, $Ineptitude, $Life_Transfer, $Mark_of_Pain, $Oppressive_Gaze, $Pain_of_Disenchantment, _
			$Plague_Sending, $Reckless_Haste, $Ride_the_Lightning, $Ride_the_Lightning_PvP, $Rust, $Signet_of_Judgment, $Signet_of_Judgment_PvP, _
			$Stolen_Speed, $Stolen_Speed_PvP, $Thunderclap, $Unnatural_Signet, $Unnatural_Signet_PvP, $Water_Trident, $Weaken_Armor, $Fireball, $Ice_Spikes
			Return 3
		; can move after casting time
		Case $Sandstorm, $Savannah_Heat, $Savannah_Heat_PvP, $Searing_Heat, $Unsteady_Ground, $Breath_of_Fire, $Chaos_Storm, _
			$Fire_Storm, $Maelstrom, $Meteor_Shower, $Ray_of_Judgment, $Spirit_Rift
			Return 4
		Case Else
			Return 0
	EndSwitch
	Return False
EndFunc   ;==>IsAoESkill
#EndRegion Skill Controls

#Region Requirements
Func RequiresHardRupt($aSkillID)
	Switch DllStructGetData(GetSkillByID($aSkillID), 'Type')
		Case $Hex, $Spell, $Enchantment, $Signet, $Well, $Ward, $ItemSpell, $WeaponSpell
			Return False
	EndSwitch
	Return True
EndFunc   ;==>RequiresHardRupt

Func RequiresBleeding($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 1)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 1)
	Else
		Return BitAND($Mcondition, 1)
	EndIf
EndFunc   ;==>RequiresBleeding

Func RequiresBlind($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 2)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 2)
	Else
		Return BitAND($Mcondition, 2)
	EndIf
EndFunc   ;==>RequiresBlind

Func RequiresBurning($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 4)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 4)
	Else
		Return BitAND($Mcondition, 4)
	EndIf
EndFunc   ;==>RequiresBurning

Func RequiresCripple($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 8)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 8)
	Else
		Return BitAND($Mcondition, 8)
	EndIf
EndFunc   ;==>RequiresCripple

Func RequiresCrippleAndBleed($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 9)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 9)
	Else
		Return BitAND($Mcondition, 9)
	EndIf
EndFunc   ;==>RequiresCrippleAndBleed

Func SkillRequiresDeepwound($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 16)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 16)
	Else
		Return BitAND($Mcondition, 16)
	EndIf
EndFunc   ;==>SkillRequiresDeepwound

Func SkillRequiresDeepWoundAndBleed($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 17)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 17)
	Else
		Return BitAND($Mcondition, 17)
	EndIf
EndFunc   ;==>SkillRequiresDeepWoundAndBleed

Func SkillRequiresDisease($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 32)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 32)
	Else
		Return BitAND($Mcondition, 32)
	EndIf
EndFunc   ;==>SkillRequiresDisease

Func SkillRequiresEarthhex($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 64)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 64)
	Else
		Return BitAND($Mcondition, 64)
	EndIf
EndFunc   ;==>SkillRequiresEarthhex

Func RequiresKnockdown($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 128)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 128)
	Else
		Return BitAND($Mcondition, 128)
	EndIf
EndFunc   ;==>RequiresKnockdown

Func RequiresCrippleAndKnockDown($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 136)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 136)
	Else
		Return BitAND($Mcondition, 136)
	EndIf
EndFunc   ;==>RequiresCrippleAndKnockDown

Func RequiresPoison($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 256)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 256)
	Else
		Return BitAND($Mcondition, 256)
	EndIf
EndFunc   ;==>RequiresPoison

Func RequiresDaze($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 512)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 512)
	Else
		Return BitAND($Mcondition, 512)
	EndIf
EndFunc   ;==>RequiresDaze

Func RequiresDazeAndBlind($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 514)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 514)
	Else
		Return BitAND($Mcondition, 514)
	EndIf
EndFunc   ;==>RequiresDazeAndBlind

Func RequiresWeakness($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 1024)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 1024)
	Else
		Return BitAND($Mcondition, 1024)
	EndIf
EndFunc   ;==>RequiresWeakness

Func RequiresWeaknessAndDeepWound($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 1040)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 1040)
	Else
		Return BitAND($Mcondition, 1040)
	EndIf
EndFunc   ;==>RequiresWeaknessAndDeepWound

Func RequiresWeaknessAndKnockDown($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 1152)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 1152)
	Else
		Return BitAND($Mcondition, 1152)
	EndIf
EndFunc   ;==>RequiresWeaknessAndKnockDown

Func SkillRequiresWaterHex($aSkill)
	Local $Mcondition = Memory_Read(getskillptr($aSkill) + 28, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read($aSkill + 28, "long"), 2048)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, "Condition"), 2048)
	Else
		Return BitAND($Mcondition, 2048)
	EndIf
EndFunc   ;==>SkillRequiresWaterHex

Func RequiresCondition($SkillID)
	Switch $SkillID
		Case $Victory_is_Mine, $Yeti_Smash, $Pestilence, $Scavenger_Strike, $Scavengers_Focus, $Discord, $Necrosis, _
				$Oppressive_Gaze, $Signet_of_Corruption_Luxon, $Signet_of_Corruption_Kurzick, $Vile_Miasma, $Virulence, $Epidemic, $Extend_Conditions, _
				$Fevered_Dreams, $Fragility, $Hypochondria, $Crystal_Wave, $Iron_Palm, $Malicious_Strike, $Sadists_Signet, _
				$Seeping_Wound, $Signet_of_Deadly_Corruption, $Signet_of_Malice, $Disrupting_Throw, $Spear_of_Fury_Luxon, _
				$Spear_of_Fury_Kurzick, $Stunning_Strike, $Armor_of_Sanctity, $Reap_Impurities
			Return True
	EndSwitch
	Return False
EndFunc   ;==>RequiresCondition

Func RequiresHex($SkillID)
	Switch $SkillID
		Case $Convert_Hexes, $Cure_Hex, $Divert_Hexes, $Reverse_Hex, $Smite_Hex, $Discord, $Necrosis, $Drain_Delusions, _
				$Hex_Eater_Signet, $Hex_Eater_Vortex, $Inspired_Hex, $Revealed_Hex, $Shatter_Delusions, $Shatter_Hex
			Return True
	EndSwitch
	Return False
EndFunc   ;==>RequiresHex

Func IsSummonSkill($SkillID)
	Switch $SkillID
		Case $Summon_Ice_Imp, $Summon_Mursaat, $Summon_Naga_Shaman, $Summon_Ruby_Djinn, $Aura_of_the_Lich, $Earthbind
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsSummonSkill

Func IsAntiMeleeSkill($SkillID)
	Switch $SkillID
		Case $Spear_of_Light, $Smite, $Castigation_Signet, $Bane_Signet, _
				$Signet_of_Clumsiness, $Signet_of_Judgment, $Ineptitude, $Clumsiness, _
				$Wandering_Eye
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsAntiMeleeSkill
#EndRegion Requirements

#Region Skill Special
;Return True if it's a boss's Skill
Func IsBossSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 1048576)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 1048576)
	Else
		Return BitAND($Mspecial, 1048576)
	EndIf
EndFunc   ;==>IsBossSkill

;Return True if it's flash enchant with failure risk if don't have recommended attr points
Func IsFlashEnchantFailureSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 8388672)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 8388672)
	Else
		Return BitAND($Mspecial, 8388672)
	EndIf
EndFunc   ;==>IsFlashEnchantFailureSkill

;Return True if it's a Elite Flash Enchantment skill's
Func IsEliteFlashEnchantSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 8388612)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 8388612)
	Else
		Return BitAND($Mspecial, 8388612)
	EndIf
EndFunc   ;==>IsEliteFlashEnchantSkill

;Return True if it's a Flash Enchantment skill's
Func IsFlashEnchantSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 8388608)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 8388608)
	Else
		Return BitAND($Mspecial, 8388608)
	EndIf
EndFunc   ;==>IsFlashEnchantSkill

;Return True if it's a pve rez skill
Func IsRezPveSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 526336)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 526336)
	Else
		Return BitAND($Mspecial, 526336)
	EndIf
EndFunc   ;==>IsRezPveSkill

;Return True if it's pve degen hex
Func IsHexDegenPveSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 524800)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 524800)
	Else
		Return BitAND($Mspecial, 524800)
	EndIf
EndFunc   ;==>IsHexDegenPveSkill

;Return True if it's pve trap skill
Func IsTrapPveSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 524576)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 524576)
	Else
		Return BitAND($Mspecial, 524576)
	EndIf
EndFunc   ;==>IsTrapPveSkill

;Return True if it's pve Ritual skill
Func IsRitualPveSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 524544)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 524544)
	Else
		Return BitAND($Mspecial, 524544)
	EndIf
EndFunc   ;==>IsRitualPveSkill

;Return True if it's capture elite skill's
Func IsCapEliteSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 524304)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 524304)
	Else
		Return BitAND($Mspecial, 524304)
	EndIf
EndFunc   ;==>IsCapEliteSkill

;Return True if it's pve elite skill
Func IsElitePveSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 524292)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 524292)
	Else
		Return BitAND($Mspecial, 524292)
	EndIf
EndFunc   ;==>IsElitePveSkill

;Return True if it's pve touch skill
Func IsTouchPveSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 524290)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 524290)
	Else
		Return BitAND($Mspecial, 524290)
	EndIf
EndFunc   ;==>IsTouchPveSkill

;Return True if it's rest of pve skill
Func IsPveSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 524288)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 524288)
	Else
		Return BitAND($Mspecial, 524288)
	EndIf
EndFunc   ;==>IsPveSkill

;Return True if it's Elite Exploit Corpse skill with Health Regen
Func IsEliteExploitCorpseHealthRegenSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 262656)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 262656)
	Else
		Return BitAND($Mspecial, 262656)
	EndIf
EndFunc   ;==>IsEliteExploitCorpseHealthRegenSkill

;Return True if it's Elite exploit corpse with failure riskif don't have recommanded attr
Func IsEliteExploitCorpseFailureSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 262208)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 262208)
	Else
		Return BitAND($Mspecial, 262208)
	EndIf
EndFunc   ;==>IsEliteExploitCorpseFailureSkill

;Return True if it's Elite exploit corpse skill
Func IsEliteExploitCorpseSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 262148)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 262148)
	Else
		Return BitAND($Mspecial, 262148)
	EndIf
EndFunc   ;==>IsEliteExploitCorpseSkill

;Return True if it's Exploit corpse skill
Func IsExploitCorpseSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 262144)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 262144)
	Else
		Return BitAND($Mspecial, 262144)
	EndIf
EndFunc   ;==>IsExploitCorpseSkill

;Return True if it's Elite off hand skill
Func IsEliteOffHandSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 32772)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 32772)
	Else
		Return BitAND($Mspecial, 32772)
	EndIf
EndFunc   ;==>IsEliteOffHandSkill

;Return True if it's off hand skill
Func IsOffHandSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 32768)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 32768)
	Else
		Return BitAND($Mspecial, 32768)
	EndIf
EndFunc   ;==>IsOffHandSkill

;Return True if it's condition skill
Func IsConditionSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 8192)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 8192)
	Else
		Return BitAND($Mspecial, 8192)
	EndIf
EndFunc   ;==>IsConditionSkill

;Return True if have risk of failure if don't have 8 points in this attr skill
Func IsFailureBelow8Skill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 4100)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 4100)
	Else
		Return BitAND($Mspecial, 4100)
	EndIf
EndFunc   ;==>IsFailureBelow8Skill

;Return True if this spirit skills can rez
Func IsRessurectionSpiritSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 2304)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 2304)
	Else
		Return BitAND($Mspecial, 2304)
	EndIf
EndFunc   ;==>IsRessurectionSpiritSkill

;Return True if it's half range skill
Func IsRessurectionSpellHalfRangeSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 2056)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 2056)
	Else
		Return BitAND($Mspecial, 2056)
	EndIf
EndFunc   ;==>IsRessurectionSpellHalfRangeSkill

;Return True if It's Elite Ressurection Spell Skill
Func IsEliteRessurectionSpellSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 2052)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 2052)
	Else
		Return BitAND($Mspecial, 2052)
	EndIf
EndFunc   ;==>IsEliteRessurectionSpellSkill

;Return True if It's Touch Ressurection Spell
Func IsTouchRessurectionSpellSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 2050)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 2050)
	Else
		Return BitAND($Mspecial, 2050)
	EndIf
EndFunc   ;==>IsTouchRessurectionSpellSkill

;Return True if It's Ressurection Spell
Func IsRessurectionSpellSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 2048)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 2048)
	Else
		Return BitAND($Mspecial, 2048)
	EndIf
EndFunc   ;==>IsRessurectionSpellSkill

;Return True if It's Elite Degen Hex
Func IsEliteDegenHexSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 516)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 516)
	Else
		Return BitAND($Mspecial, 516)
	EndIf
EndFunc   ;==>IsEliteDegenHexSkill

;Return True if It's  Degen Hex
Func IsDegenHexSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 512)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 512)
	Else
		Return BitAND($Mspecial, 512)
	EndIf
EndFunc   ;==>IsDegenHexSkill

;Return True if We have malus armor when using this preparation skill
Func IsPrepLessArmorWhileUsingSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 384)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 384)
	Else
		Return BitAND($Mspecial, 384)
	EndIf
EndFunc   ;==>IsPrepLessArmorWhileUsingSkill

;Return True if is the smoke trap skill
Func IsSmokeTrapSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 292)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 292)
	Else
		Return BitAND($Mspecial, 292)
	EndIf
EndFunc   ;==>IsSmokeTrapSkill

;Return True if it's Trap skill with piercing damage
Func IsTrapPiercingSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 288)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 288)
	Else
		Return BitAND($Mspecial, 288)
	EndIf
EndFunc   ;==>IsTrapPiercingSkill

;Return True if it's Elite Trap and Ritual skill
Func IsElitePrepTrapRitualSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 260)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 260)
	Else
		Return BitAND($Mspecial, 260)
	EndIf
EndFunc   ;==>IsElitePrepTrapRitualSkill

;Return True if it's Trap and Ritual skill
Func IsPrepTrapRitualSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 256)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 256)
	Else
		Return BitAND($Mspecial, 256)
	EndIf
EndFunc   ;==>IsPrepTrapRitualSkill

;Return True if We have malus armor when using this skill
Func IsLessArmorWhileUsingSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 128)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 128)
	Else
		Return BitAND($Mspecial, 128)
	EndIf
EndFunc   ;==>IsLessArmorWhileUsingSkill

;Return True if it's Elite skill with risk of failure if don't have 4 points in this attr skill
Func IsEliteFailureBelow4Skill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 68)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 68)
	Else
		Return BitAND($Mspecial, 68)
	EndIf
EndFunc   ;==>IsEliteFailureBelow4Skill

;Return True if it's Elite skill with risk of failure if don't have 4 points in this attr skill (And knock down us while using)
Func IsFailureBelow4KnockSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 65)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 65)
	Else
		Return BitAND($Mspecial, 65)
	EndIf
EndFunc   ;==>IsFailureBelow4KnockSkill

;Return True if it's skill with risk of failure if don't have 4 points in this attr skill
Func IsFailureBelow4Skill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 64)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 64)
	Else
		Return BitAND($Mspecial, 64)
	EndIf
EndFunc   ;==>IsFailureBelow4Skill

;Return True if we can be Easily Interrupted while using this skill
Func IsEasilyInterruptedSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 32)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 32)
	Else
		Return BitAND($Mspecial, 32)
	EndIf
EndFunc   ;==>IsEasilyInterruptedSkill

;Return True if it's Elite Half Range Skill
Func IsEliteHalfRangeSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 12)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 12)
	Else
		Return BitAND($Mspecial, 12)
	EndIf
EndFunc   ;==>IsEliteHalfRangeSkill

;Return True if it's Half Range Skill
Func IsHalfRangeSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 8)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 8)
	Else
		Return BitAND($Mspecial, 8)
	EndIf
EndFunc   ;==>IsHalfRangeSkill

;Return True if it's Elite Touch Skill
Func IsEliteTouchSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 6)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 6)
	Else
		Return BitAND($Mspecial, 6)
	EndIf
EndFunc   ;==>IsEliteTouchSkill

;Return True if it's Elite Exhaustion skill (Overcast condition)
Func IsEliteExhaustionSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 5)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 5)
	Else
		Return BitAND($Mspecial, 5)
	EndIf
EndFunc   ;==>IsEliteExhaustionSkill

;Return True if it's Elite skill
Func IsEliteSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 4)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 4)
	Else
		Return BitAND($Mspecial, 4)
	EndIf
EndFunc   ;==>IsEliteSkill

;Return True if it's Exhaustion touch skill (Overcast condition)
Func IsExhaustionTouchSkillSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 3)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 3)
	Else
		Return BitAND($Mspecial, 3)
	EndIf
EndFunc   ;==>IsExhaustionTouchSkillSkill

;Return True if it's Touch Skill
;Func IsTouchSkillSkill($aSkill)
;~ 	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
;~ 	If IsPtr($aSkill) <> 0 Then
;~ 		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 2)
;~ 	ElseIf IsDllStruct($aSkill) <> 0 Then
;~ 		Return BitAND(DllStructGetData($aSkill, 'Special'), 2)
;~ 	Else
;~ 		Return BitAND($Mspecial, 2)
;~ 	EndIf
;EndFunc

;Return True if it's Exhaustion skill (Overcast condition)
Func IsExhaustionSkill($aSkill)
	Local $Mspecial = Memory_Read(getskillptr($aSkill) + 16, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 16, "long"), 1)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Special'), 1)
	Else
		Return BitAND($Mspecial, 1)
	EndIf
EndFunc   ;==>IsExhaustionSkill
#EndRegion Skill Special

#Region Skilltypes
Func IsEnchantRemoveSkill($aSkill) ;
	If IsPtr($aSkill) <> 0 Then
		Local $lSkillEffect2 = Memory_Read($aSkill + 32, 'long')
		Local $lSkillID = Memory_Read($aSkill, "long")
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Local $lSkillEffect2 = DllStructGetData($aSkill, 'Effect2')
		Local $lSkillID = DllStructGetData($aSkill, 'ID')
	Else
		Local $lSkillEffect2 = Memory_Read(Skill_GetSkillPtr($aSkill) + 32, 'long')
		Local $lSkillID = $aSkill
	EndIf

	Switch $lskillID
		Case $Chilblains, $Corrupt_Enchantment, $Envenom_Enchantments, $Jaundiced_Gaze, $Pain_of_Disenchantment, $Rend_Enchantments, _        ; Necro Skills
				$Rip_Enchantment, $Strip_Enchantment, _
				$Air_of_Disenchantment, $Discharge_Enchantment, $Drain_Enchantment, $Feedback, $Inspired_Enchantment, $Lyssas_Balance, _    ; Mesmer Skills
				$Mirror_of_Disenchantment, $Revealed_Enchantment, $Shatter_Enchantment, $Shatter_Storm, $Signet_of_Disenchantment, _
				$Assault_Enchantments, $Expunge_Enchantments, $Lift_Enchantment, $Shattering_Assault, $Signet_of_Twilight, _                ; Assasin Skills
				$Rending_Touch, $Test_of_Faith                                                                                                ; Dervish Skills
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsEnchantmentStrip

Func IsBelow50PercentEnemySkill($SKILL) ;
	Switch DllStructGetData($SKILL, 'ID')
;~ PvE only skills
		Case $Finish_Him, _                                    ; PvE only Skills
				$Final_Thrust, _                            ; Warrior Skills
				$Brutal_Strike, $Needling_Shot, _            ; Ranger Skills
				$Word_of_Healing, $Zealous_Benediction, _    ; Monk Skills
				$Signet_of_Lost_Souls, $Taste_of_Pain, _    ; Necro Skills
				$Augury_of_Death                            ; Assasin Skills
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsBelow50PercentEnemySkill

Func IsElementalAttunementSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 131072)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 131072)
	Else
		Return BitAND($Mskilltype, 131072)
	EndIf
EndFunc   ;==>IsElementalAttunementSkill

Func IsKnockMySelfSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 65536)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 65536)
	Else
		Return BitAND($Mskilltype, 65536)
	EndIf
EndFunc   ;==>IsKnockMySelfSkill

Func IsAttackAndSppedMoveSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 32768)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 32768)
	Else
		Return BitAND($Mskilltype, 32768)
	EndIf
EndFunc   ;==>IsAttackAndSppedMoveSkill

Func IsReverseDamageSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 16384)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 16384)
	Else
		Return BitAND($Mskilltype, 16384)
	EndIf
EndFunc   ;==>IsReverseDamageSkill

Func IsLooseEnchantAndHealAndRemoveHexSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 14336)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 14336)
	Else
		Return BitAND($Mskilltype, 14336)
	EndIf
EndFunc   ;==>IsLooseEnchantAndHealAndRemoveHexSkill

Func IsLooseEnchantAndEnergyRegenSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 8448)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 8448)
	Else
		Return BitAND($Mskilltype, 8448)
	EndIf
EndFunc   ;==>IsLooseEnchantAndEnergyRegenSkill

Func IsDervHealSignetWithRemoveDervEnchantSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 8198)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 8198)
	Else
		Return BitAND($Mskilltype, 8198)
	EndIf
EndFunc   ;==>IsDervHealSignetWithRemoveDervEnchantSkill

Func IsDervHealWithRemoveDervEnchantAndHexSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 8196)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 8196)
	Else
		Return BitAND($Mskilltype, 8196)
	EndIf
EndFunc   ;==>IsDervHealWithRemoveDervEnchantAndHexSkill

Func IsRemoveDervEnchantSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 8192)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 8192)
	Else
		Return BitAND($Mskilltype, 8192)
	EndIf
EndFunc   ;==>IsRemoveDervEnchantSkill

Func IsHealAndConditionAndHexRemovalSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 6150)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 6150)
	Else
		Return BitAND($Mskilltype, 6150)
	EndIf
EndFunc   ;==>IsHealAndConditionAndHexRemovalSkill

Func IsConditionAndHexRemovalSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 6144)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 6144)
	Else
		Return BitAND($Mskilltype, 6144)
	EndIf
EndFunc   ;==>IsConditionAndHexRemovalSkill

Func IsConditionTransfertSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 4608)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 4608)
	Else
		Return BitAND($Mskilltype, 4608)
	EndIf
EndFunc   ;==>IsConditionTransfertSkill

Func IsConditionRemovalSpecialSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 4102)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 4102)
	Else
		Return BitAND($Mskilltype, 4102)
	EndIf
EndFunc   ;==>IsConditionRemovalSpecialSkill

Func IsHexRemovalWithEnergyGainSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 2304)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 2304)
	Else
		Return BitAND($Mskilltype, 2304)
	EndIf
EndFunc   ;==>IsHexRemovalWithEnergyGainSkill

Func IsHexRemovalWithHealSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 2054)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 2054)
	Else
		Return BitAND($Mskilltype, 2054)
	EndIf
EndFunc   ;==>IsHexRemovalWithHealSkill

Func IsEnchantOnAllyAffectEnemisSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 1024)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 1024)
	Else
		Return BitAND($Mskilltype, 1024)
	EndIf
EndFunc   ;==>IsEnchantOnAllyAffectEnemisSkill

Func IsEnrgeyDegenSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 768)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 768)
	Else
		Return BitAND($Mskilltype, 768)
	EndIf
EndFunc   ;==>IsEnrgeyDegenSkill

Func IsTouchSkillSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 544)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 544)
	Else
		Return BitAND($Mskilltype, 544)
	EndIf
EndFunc   ;==>IsTouchSkillSkill

Func IsCloseRangeSpell2Skill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 516)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 516)
	Else
		Return BitAND($Mskilltype, 516)
	EndIf
EndFunc   ;==>IsCloseRangeSpell2Skill

Func IsCloseRangeSpellSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 512)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 512)
	Else
		Return BitAND($Mskilltype, 512)
	EndIf
EndFunc   ;==>IsCloseRangeSpellSkill

Func IsEnergyStealSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 320)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 320)
	Else
		Return BitAND($Mskilltype, 320)
	EndIf
EndFunc   ;==>IsEnergyStealSkill

Func IsEnergyGainSpellSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 288)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 288)
	Else
		Return BitAND($Mskilltype, 288)
	EndIf
EndFunc   ;==>IsEnergyGainSpellSkill

Func IsEnergyGainRuptSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 257)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 257)
	Else
		Return BitAND($Mskilltype, 257)
	EndIf
EndFunc   ;==>IsEnergyGainRuptSkill

Func IsEnergyGainSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 256)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 256)
	Else
		Return BitAND($Mskilltype, 256)
	EndIf
EndFunc   ;==>IsEnergyGainSkill

Func IsBlockSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 128)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 128)
	Else
		Return BitAND($Mskilltype, 128)
	EndIf
EndFunc   ;==>IsBlockSkill

Func IsBlockSkill_old($aSkill)
	Switch $aSkill
		Case $Bonettis_Defense, $Protectors_Defense, $Wary_Stance, $Escape, $Escape_PvP, $Gladiators_Defense, $Soldiers_Stance, $Flashing_Blades, $Disciplined_Stance, $Distortion, $Defensive_Stance, _
				$Deflect_Arrows, $Soldiers_Defense, $Shield_Stance, $Dryders_Defenses, $Frenzied_Defense, $Whirling_Defense, $Distortion_Gwen, $Defensive_Anthem, $Defensive_Anthem_PvP, $Aegis, _
				$Guardian, $Pensive_Guardian, $Shield_Guardian, $Shield_of_Deflection, $Dodge, $Magnetic_Aura, $Magnetic_Surge, $Sliver_Armor, $Swirling_Aura, $Ward_Against_Melee, $Critical_Defenses, _
				$Shroud_of_Distress_PvP, $Shroud_of_Distress, $Displacement_PvP, $Displacement, $Weapon_of_Warding_PvP, $Weapon_of_Warding, $Bladeturn_Refrain, $Burning_Shield, $Attackers_Insight, _
				$Mirage_Cloak, $Shield_of_Force, $Mental_Block
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsBlockSkill_old

Func IsSacrReturniceHeal2Skill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 38)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 38)
	Else
		Return BitAND($Mskilltype, 38)
	EndIf
EndFunc   ;==>IsSacrReturniceHeal2Skill

Func IsSacrReturniceHealSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 36)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 36)
	Else
		Return BitAND($Mskilltype, 36)
	EndIf
EndFunc   ;==>IsSacrReturniceHealSkill

Func IsSacrReturniceSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 32)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 32)
	Else
		Return BitAND($Mskilltype, 32)
	EndIf
EndFunc   ;==>IsSacrReturniceSkill

Func IsRezSignetSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 16)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 16)
	Else
		Return BitAND($Mskilltype, 16)
	EndIf
EndFunc   ;==>IsRezSignetSkill

Func IsRezSkill($aSkill)
	Local $Mskilltype = Memory_Read($aSkill + 12, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 12, "long"), 8)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect2'), 8)
	Else
		Return BitAND($Mskilltype, 8)
	EndIf
EndFunc   ;==>IsRezSkill

Func IsHealSkill($aSkill)
	Switch Memory_Read(Skill_GetSkillPtr($aSkill) + 32, 'long')	; Effect 2
		Case 2, 4, 6, 36, 38, 4102, 4096, 6144, 8196, 8198, 14336
			Return True
		Case Else
			Switch GetSkillID($aSkill)	;
				Case $Healing_Hands, $Restful_Breeze, $Signet_Of_Rejuvenation, $Words_of_Comfort, $Conviction, $Faithful_Intervention _
					,$Mystic_Healing, $Mystic_Healing_PvP, $Mystic_Regeneration, $Mystic_Vigor, $Pious_Renewal, $Watchful_Intervention _
					,$Spirit_Transfer, $I_Will_Avenge_You, $I_Will_Survive, $Shadow_Sanctuary_Luxon, $Shadow_Sanctuary_Kurzick _
					,$Shroud_of_Distress, $Healing_Spring, $Hexers_Vigor, $Feel_No_Pain
				Return True
			EndSwitch
	EndSwitch

	If IsPartyHealSkill($aSkill) Then Return True
	Return False
EndFunc   ;==>IsHealSkill

Func IsSelfHealSkill($aSkill)    ; healing skills that can be used on self
	Return IsPartyHealSkill($aSkill) And Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") <> 4
EndFunc   ;==>IsSelfHealSkill

Func IsSelfOnlyHealSkill($aSkill)    ; healing skills that can be used on self
	Return IsPartyHealSkill($aSkill) And Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 0
EndFunc   ;==>IsSelfOnlyHealSkill

Func IsHealOtherSkill($aSkill)    ; healing skills that can only be used on others
	Return IsPartyHealSkill($aSkill) And Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 4
EndFunc   ;==>IsHealOtherSkill

Func IsHealMySelfSkill($aSkill)
	Local $lSkillType = Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long")
	Return BitAND($lSkillType, 4)
EndFunc   ;==>IsHealMySelfSkill

Func IsHealAllySkill($aSkill)
	Local $lSkillType = Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long")
	Return BitAND($lSkillType, 2)
EndFunc   ;==>IsHealAllySkill

Func IsHexRemovalSkill($aSkill)
	Local $lSkillType = Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long")
	Return BitAND($lSkillType, 2048)
EndFunc   ;==>IsHexRemovalSkill

Func IsConditionRemovalSkill($aSkill)
	Local $lSkillType = Memory_Read(Skill_GetSkillPtr($aSkill) + 12, "long")
	Return BitAND($lSkillType, 4096)
EndFunc   ;==>IsConditionRemovalSkill

#EndRegion Skilltypes

#Region Target
Func TargetSelfSkill($aSkill)
	Return Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 0
EndFunc   ;==>TargetSelfSkill

Func TargetSpiritSkill($aSkill)
	Return Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 1
EndFunc   ;==>TargetSpiritSkill

Func TargetAllySkill($aSkill)
	Return Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 3
EndFunc   ;==>TargetAllySkill

Func TargetOtherAllySkill($aSkill)
	Return Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 4
EndFunc   ;==>TargetOtherAllySkill

Func TargetEnemySkill($aSkill)
	Return Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 5
EndFunc   ;==>TargetEnemySkill

Func TargetdeadAllySkill($aSkill)
	Return Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 6
EndFunc   ;==>TargetdeadAllySkill

Func TargetMinionskill($aSkill)
	Return Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 14
EndFunc   ;==>TargetMinionskill

Func TargetGroundskill($aSkill)
	Return Memory_Read(Skill_GetSkillPtr($aSkill) + 49, "byte") = 16
EndFunc   ;==>TargetGroundskill
#EndRegion Target

#Region HeroCast

;~Precasts prots before or during a fight

Func CacheHeroHeals()
	Out("Mapping your Heroe, that have heal")
	For $aHero = 1 To GetPartySize() -1
		For $aSkillSlot = 1 To 8            ; precast wards and binding rituals
			$aSkillID = GetSkillbarInfo($i, "SkillID")($aSkillSlot, $aHero)
			Switch $aSkillID
;~ 				Case $Cautery_Signet, $Martyr, $Extinguish, $Protective_Was_Kaolai, $Heal_Party, $Divine_Healing, $Heavens_Delight, $Mystic_Healing, $Courageous_Was_Saidra
				Case $Martyr, $Extinguish, $Protective_Was_Kaolai, $Heal_Party, $Divine_Healing, $Heavens_Delight, $Mystic_Healing
					ReDim $HeroHeals[UBound($HeroHeals) + 1][3]
					$HeroHeals[UBound($HeroHeals) - 1][0] = $aSkillID
					$HeroHeals[UBound($HeroHeals) - 1][1] = $aHero
					$HeroHeals[UBound($HeroHeals) - 1][2] = $aSkillSlot
				Case $Shatter_Hex, $Hex_Eater_Signet, $Divert_Hexes, $Cure_Hex, $Blessed_Light, $Contemplation_of_Purity, $Withdraw_Hexes, $holy_veil, $Pious_Restoration, _
						$Purge_Signet, $Signet_of_Removal ;
					ReDim $HeroHexRemoval[UBound($HeroHexRemoval) + 1][3]
					$HeroHexRemoval[UBound($HeroHexRemoval) - 1][0] = $aSkillID
					$HeroHexRemoval[UBound($HeroHexRemoval) - 1][1] = $aHero
					$HeroHexRemoval[UBound($HeroHexRemoval) - 1][2] = $aSkillSlot
				Case $Its_Just_a_Flesh_Wound, $Blessed_Light, $Cautery_Signet, $Dismiss_Condition, $Draw_Conditions, $Empathic_Removal, $Extinguish, $Foul_Feast, $Life_Sheath, _
						$Martyr, $Mend_Ailment, $Mend_Body_and_Soul, $Mend_Condition, $Peace_and_Harmony, $Purge_Conditions, $Purifying_Finale, $Restore_Condition, $Smite_Condition, _
						$Spotless_Soul, $Weapon_of_Remedy
					ReDim $HeroConditionRemoval[UBound($HeroConditionRemoval) + 1][3]
					$HeroConditionRemoval[UBound($HeroConditionRemoval) - 1][0] = $aSkillID
					$HeroConditionRemoval[UBound($HeroConditionRemoval) - 1][1] = $aHero
					$HeroConditionRemoval[UBound($HeroConditionRemoval) - 1][2] = $aSkillSlot
			EndSwitch
		Next
	Next
EndFunc   ;==>CacheHeroHeals

Func CacheBiP()
	For $aHero = 1 To GetPartySize() -1
		For $aSkillSlot = 1 To 8            ; precast wards and binding rituals
			If GetSkillbarInfo($i, "SkillID")($aSkillSlot, $aHero) = $Blood_is_Power Then
				$BiP[0] = $aHero
				$BiP[1] = $aSkillSlot
			EndIf
		Next
	Next
EndFunc

Func CacheHeroPrecast()
	Out("Mapping your Heroe, that have Precast")
	$HeroPrecast = 0
	Global $HeroPrecast[100][3]
	$HeroPrecast[0][0] = 0
	$HeroPrecast[0][1] = "hero"
	$HeroPrecast[0][2] = "skill slot"
	For $aHero = 1 To GetPartySize() -1
		For $aSkillSlot = 1 To 8            ; precast wards and binding rituals
			$aSkillID = GetSkillbarInfo($i, "SkillID")($aSkillSlot, $aHero)
			If $aSkillID = 0 Then ContinueLoop
			$aSkillType = Memory_Read(Skill_GetSkillPtr($aSkillID) + 12, "long")
			Switch $aSkillID
				Case $Soul_Twisting , $Signet_Of_Spirits, $Armor_of_Unfeeling
					$HeroPrecast[0][0] += 1
					$HeroPrecast[$HeroPrecast[0][0]][0] = $aSkill_Name[$aSkillID]
					$HeroPrecast[$HeroPrecast[0][0]][1] = $aHero
					$HeroPrecast[$HeroPrecast[0][0]][2] = $aSkillSlot
				Case Else
					If $aSkillType = $Ward Or $aSkillType = $Ritual Then
						$HeroPrecast[0][0] += 1
						$HeroPrecast[$HeroPrecast[0][0]][0] = $aSkill_Name[$aSkillID]
						$HeroPrecast[$HeroPrecast[0][0]][1] = $aHero
						$HeroPrecast[$HeroPrecast[0][0]][2] = $aSkillSlot
					EndIf
			EndSwitch
		Next
	Next
	ReDim $HeroPrecast[$HeroPrecast[0][0]+1][3]
EndFunc

Func CacheMysticHealing()
	Out("Mapping Heroes, that have Mystic Healing")
	Sleep(200)
	Local $i = 1
	Local $j = 1
	Local $k = 1
	For $aHero = 1 To UBound(Getparty()) -2
		For $aSkillSlot = 1 To 8
			If GetSkillbarInfo($i, "SkillID")($aSkillSlot, $aHero) = $Mystic_Healing Then
				ReDim $MysticHealingArray[$i][3]
				$MysticHealingArray[$i - 1][0] = $i
				$MysticHealingArray[$i - 1][1] = $aHero
				$MysticHealingArray[$i - 1][2] = $aSkillSlot
				DisableHeroSkillSlot($aHero, $aSkillSlot)

				If Mod($i, 2) <> 0 Then
					ReDim $MysticHealingGroupOne[$j][3]
					$MysticHealingGroupOne[$j - 1][0] = $j
					$MysticHealingGroupOne[$j - 1][1] = $aHero
					$MysticHealingGroupOne[$j - 1][2] = $aSkillSlot
					$j += 1
				Else
					ReDim $MysticHealingGroupTwo[$k][3]
					$MysticHealingGroupTwo[$k - 1][0] = $k
					$MysticHealingGroupTwo[$k - 1][1] = $aHero
					$MysticHealingGroupTwo[$k - 1][2] = $aSkillSlot
					$k += 1
				EndIf

				$i += 1
			EndIf
		Next
	Next

	If $MysticHealingGroupOne[0][1] <> "" Then $MysticTimerOne = TimerInit()
	If $MysticHealingGroupTwo[0][1] <> "" Then $MysticTimerTwo = TimerInit()
;~ 	_ArrayDisplay($MysticHealingArray)
;~ 	_ArrayDisplay($MysticHealingGroupOne)
;~ 	_ArrayDisplay($MysticHealingGroupTwo)
	Return True
EndFunc   ;==>CacheMysticHealing

Func PrecastWardsAndSpirits($aAggroRange = $spirit_range)
    Do
        Sleep(200)
    Until Not Agent_GetAgentInfo(-2, "Moving")
    For $aSkillSlot In $Skillbar
        If $SkillBarCache[$aSkillSlot][$precast] = "" Then ContinueLoop
        If CanUse($aSkillSlot, $aAggroRange) Then Skill_UseSkill($aSkillSlot, $BestTargetPtr)
		If Agent_IsEnemyNear($aAggroRange) Then ExitLoop
    Next
    Out("Precasting hero wards and binding rituals")
    For $i = 1 to $HeroPrecast[0][0]
		If GetEffectTimeRemaining(GetSkillbarInfo($i, "SkillID")($aSkillSlot)) > 15 Then ContinueLoop
        Skill_UseHero($HeroPrecast[$i][1], $HeroPrecast[$i][2], 0)
        If Mod($i, 3) = 0  And CanUse($SkillbarSlot[$Heroic_Refrain]) Then
            Skill_UseSkill($SkillbarSlot[$Heroic_Refrain], $BestTargetPtr)
            If CanUse($SkillbarSlot[$Burning_Refrain]) Then Skill_UseSkill($SkillbarSlot[$Burning_Refrain])
            If CanUse($SkillbarSlot[$Theyre_on_Fire]) Then Skill_UseSkill($SkillbarSlot[$Theyre_on_Fire])
		EndIf
		If Agent_IsEnemyNear($aAggroRange) Then ExitLoop
    Next
EndFunc   ;==>PrecastWardsAndSpirits

Func ApplyHR()
	While CanUse($SkillbarSlot[$Heroic_Refrain])
        Skill_UseSkill($SkillbarSlot[$Heroic_Refrain], $BestTargetPtr)
		; If $BiP[0] <> 0 And Agent_GetAgentInfo(-2, "CurrentEnergy") < 10 And Not Skill_HasEffect($Blood_is_Power) And Agent_GetAgentInfo($BiP[0], "HP") > 0.4 Then Skill_UseHero($BiP[1], $BiP[2], -2) ;Use Blood is Power on me
		If CanUse($SkillbarSlot[$Theyre_on_Fire]) Then Skill_UseSkill($SkillbarSlot[$Theyre_on_Fire])
		If CanUse($SkillbarSlot[$Burning_Refrain]) Then Skill_UseSkill($SkillbarSlot[$Burning_Refrain])
		Sleep(11000)
    WEnd
EndFunc   ;==>ApplyHR

;~Precasts bonds before or during a fight
Func PrecastBonds($aTargetAlly = 0)
	Out("Precasting wards and binding rituals")
	For $aHero = UBound(Getparty()) - 1 To 0 Step -1
		For $aSkillSlot = 1 To 8            ; precast bonds
			ApplyHR()
			If GetEffectTimeRemaining(GetEffect(GetSkillbarInfo($i, "SkillID")($aSkillSlot))) > 0 Then ContinueLoop
			If IsBondSkill(GetSkillbarInfo($i, "SkillID")($aSkillSlot)) Then
				DisableHeroSkillSlot($aHero, $aSkillSlot)
				Skill_UseHero($aHero, $aSkillSlot, $aTargetAlly)
			EndIf
		Next
	Next
EndFunc   ;==>PrecastBonds

Func UseHeroHeals()
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	For $i = UBound($HeroHeals) - 1 To 0 Step -1
		Switch $HeroHeals[$i][0]
			Out($HeroHeals[$i][0])
			Case $Martyr
				If GetNumberOfConditionedAllies() - Agent_GetAgentInfo(GetHeroID($HeroHeals[$i][1]), "Condition") > 0 Then Skill_UseHero($HeroHeals[$i][1], $HeroHeals[$i][2], 0)
			Case $Cautery_Signet, $Extinguish
				Out("Burning allies: " & GetNumberOfBurningAllies())
				If GetNumberOfBurningAllies() > 0 Then Skill_UseHero($HeroHeals[$i][1], $HeroHeals[$i][2], 0)
			Case Else
				; Out("Party Health: " & GetPartyHealth())
				; Out("Lowest HP: " & Floor(Agent_GetAgentInfo(GetLowestAlly(, "HP")) * 100) & "%")
				If GetPartyHealth() < 0.90 Or Agent_GetAgentInfo(GetLowestAlly(, "HP")) < 0.8 Then Skill_UseHero($HeroHeals[$i][1], $HeroHeals[$i][2], 0)
		EndSwitch
	Next
EndFunc   ;==>UseHeroHeals

Func UseHeroHexRemoval()
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	For $i = UBound($HeroHexRemoval) - 1 To 0 Step -1
		Switch $HeroHexRemoval[$i][0]
			Out($HeroHexRemoval[$i][0])
			Case $Hex_Eater_Signet
				If Skill_GetSkillbarInfo($HeroHexRemoval[$i][2], $HeroHexRemoval[$i][1]) Then
					Skill_UseHero($HeroHexRemoval[$i][1], $HeroHexRemoval[$i][2], -2)
					ExitLoop
				EndIf
			Case $Shatter_Hex
				If Skill_GetSkillbarInfo($HeroHexRemoval[$i][2], $HeroHexRemoval[$i][1]) And Agent_GetAgentInfo(GetHeroID($HeroHexRemoval[$i][1], "CurrentEnergy")) > 10 And Agent_GetNumberOfEnemiesNearAgent($area_range, -2) Then
					Skill_UseHero($HeroHexRemoval[$i][1], $HeroHexRemoval[$i][2], -2)
					ExitLoop
				EndIf
			Case Else
				If Skill_GetSkillbarInfo($HeroHexRemoval[$i][2], $HeroHexRemoval[$i][1]) And Agent_GetAgentInfo(-2, "HP") < 0.8 Then
					Skill_UseHero($HeroHexRemoval[$i][1], $HeroHexRemoval[$i][2], -2)
					ExitLoop
				EndIf
		EndSwitch
	Next
EndFunc

Func UseHeroConditionRemoval()
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	For $i = UBound($HeroConditionRemoval) - 1 To 0 Step -1
		Switch $HeroConditionRemoval[$i][0]
			Out($HeroConditionRemoval[$i][0])
		EndSwitch
	Next
EndFunc

Func MysticHealing()
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	If UBound($MysticHealingArray) - 1 = 0 And $MysticHealingArray[0][1] = "" Then
		Return
	ElseIf UBound($MysticHealingArray) - 1 = 0 And $MysticHealingArray[0][1] <> "" And Agent_GetAgentInfo(-2, "HP") < 0.9 Then
		Skill_UseHero($MysticHealingArray[0][1], $MysticHealingArray[0][2], 0)
	Else
		If Agent_GetAgentInfo(-2, "HP") < 0.9 And $MysticSwitch = 1 And TimerDiff($MysticTimerTwo) > 2000 Then
			If Agent_GetAgentInfo(-2, "IsDead") Then Return
			If TimerDiff($MysticTimerOne) > 5500 Then
				For $i = 0 To UBound($MysticHealingGroupOne) - 1
					Skill_UseHero($MysticHealingGroupOne[$i][1], $MysticHealingGroupOne[$i][2], 0)
				Next
				$MysticTimerOne = TimerInit()
			EndIf
			RndSleep(100)
			$MysticSwitch = 2

		ElseIf Agent_GetAgentInfo(-2, "HP") < 0.9 And $MysticSwitch = 2 And TimerDiff($MysticTimerOne) > 2000 Then
			If Agent_GetAgentInfo(-2, "IsDead") Then Return
			If TimerDiff($MysticTimerTwo) > 5500 Then
				For $i = 0 To UBound($MysticHealingGroupTwo) - 1
					Skill_UseHero($MysticHealingGroupTwo[$i][1], $MysticHealingGroupTwo[$i][2], 0)
				Next
				$MysticTimerTwo = TimerInit()
			EndIf
			RndSleep(100)
			$MysticSwitch = 1
		EndIf
	EndIf

EndFunc   ;==>MysticHealing

#EndRegion HeroCast

#Region Skill Effect 1
Func CausesBleedingSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 1)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 1)
	Else
		Return BitAND($MSkillEffect1, 1)
	EndIf
EndFunc   ;==>CausesBleedingSkill

Func CausesBlindSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 2)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 2)
	Else
		Return BitAND($MSkillEffect1, 2)
	EndIf
EndFunc   ;==>CausesBlindSkill

Func CausesBurningSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 4)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 4)
	Else
		Return BitAND($MSkillEffect1, 4)
	EndIf
EndFunc   ;==>CausesBurningSkill

Func CausesCrippleSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 8)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 8)
	Else
		Return BitAND($MSkillEffect1, 8)
	EndIf
EndFunc   ;==>CausesCrippleSkill

Func CausesDeepWoundSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 16)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 16)
	Else
		Return BitAND($MSkillEffect1, 16)
	EndIf
EndFunc   ;==>CausesDeepWoundSkill

Func CausesDiseaseSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 32)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 32)
	Else
		Return BitAND($MSkillEffect1, 32)
	EndIf
EndFunc   ;==>CausesDiseaseSkill

Func CausesSlowerMoveSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 64)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 64)
	Else
		Return BitAND($MSkillEffect1, 64)
	EndIf
EndFunc   ;==>CausesSlowerMoveSkill

Func CausesKnockdownSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 128)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 128)
	Else
		Return BitAND($MSkillEffect1, 128)
	EndIf
EndFunc   ;==>CausesKnockdownSkill

Func CausesPoisonSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 256)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 256)
	Else
		Return BitAND($MSkillEffect1, 256)
	EndIf
EndFunc   ;==>CausesPoisonSkill

Func CausesDazeSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 512)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 512)
	Else
		Return BitAND($MSkillEffect1, 512)
	EndIf
EndFunc   ;==>CausesDazeSkill

Func CauseWeaknessSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 1024)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 1024)
	Else
		Return BitAND($MSkillEffect1, 1024)
	EndIf
EndFunc   ;==>CauseWeaknessSkill

Func CauseWaterHexSkill($aSkill)
	Local $MSkillEffect1 = Memory_Read($aSkill + 24, "long")
	If IsPtr($aSkill) <> 0 Then
		Return BitAND(Memory_Read(getskillptr($aSkill) + 24, "long"), 2048)
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Return BitAND(DllStructGetData($aSkill, 'Effect1'), 2048)
	Else
		Return BitAND($MSkillEffect1, 2048)
	EndIf
EndFunc   ;==>CauseWaterHexSkill
#EndRegion Skill Effect 1

#Region Skill Weapon Requires
Func SkillAxeAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 1
EndFunc   ;==>SkillAxeAttack

Func SkillBowAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 2
EndFunc   ;==>SkillBowAttack

Func SkillDaggerAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 8
EndFunc   ;==>SkillDaggerAttack

Func SkillHammerAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 16
EndFunc   ;==>SkillHammerAttack

Func SkillScytheAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 32
EndFunc   ;==>SkillScytheAttack

Func SkillSpearAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 64
EndFunc   ;==>SkillSpearAttack

Func SkillRangedAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 70
EndFunc   ;==>SkillRangedAttack

Func SkillAllSwordAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 128
EndFunc   ;==>SkillAllSwordAttack

Func SkillMNoWeaponRequiAttack($SKILL)
	Return DllStructGetData($SKILL, 'WeaponReq') = 185
EndFunc   ;==>SkillMNoWeaponRequiAttack
#EndRegion Skill Weapon Requires

#Region Skill Combo
Func SkillDaggerLeadAttack($SKILL)
	Return DllStructGetData($SKILL, 'Combo') = 1
EndFunc   ;==>SkillDaggerLeadAttack

Func SkillDaggerOffHandAttack($SKILL)
	Return DllStructGetData($SKILL, 'Combo') = 2
EndFunc   ;==>SkillDaggerOffHandAttack

Func SkillDaggerDualAttack($SKILL)
	Return DllStructGetData($SKILL, 'Combo') = 3
EndFunc   ;==>SkillDaggerDualAttack
#EndRegion Skill Combo

#Region Skill Combo Requi
Func IsDaggerRequiDualAttackSkill($SKILL)
	Return BitAND(DllStructGetData($SKILL, 'ComboReq'), 1)
EndFunc   ;==>IsDaggerRequiDualAttackSkill

Func IsDaggerRequiLeadAttackSkill($SKILL)
	Return BitAND(DllStructGetData($SKILL, 'ComboReq'), 2)
EndFunc   ;==>IsDaggerRequiLeadAttackSkill

Func IsDaggerRequiOffHandSkill($SKILL)
	Return BitAND(DllStructGetData($SKILL, 'ComboReq'), 3)
EndFunc   ;==>IsDaggerRequiOffHandSkill

Func IsDaggerRequiHexedFoeSkill($SKILL)
	Return BitAND(DllStructGetData($SKILL, 'ComboReq'), 16)
EndFunc   ;==>IsDaggerRequiHexedFoeSkill
#EndRegion Skill Combo Requi

;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







#Region Classified
;~ #Region Add By Alusion
;~ #Region Flash enchantment spell
;~ ;Flash enchantment Interrupts spells only
;~ Func FlashRuptSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~     Case $Lyssas_Haste, $Lyssas_Haste_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Flash Better result if use during combat
;~ Func FlashInFightSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Aura_of_Thorns, $Aura_of_Thorns_PvP, $Balthazars_Rage, $Dust_Cloak, _
;~ 		$Dust_Cloak_PvP, $Ebon_Dust_Aura, $Ebon_Dust_Aura_PvP, $Grenths_Aura, _
;~ 		$Grenths_Fingers, $Heart_of_Holy_Flame, $Heart_of_Holy_Flame_PvP, $Mirage_Cloak, _
;~ 		$Mystic_Corruption, $Rending_Aura, $Shield_of_Force, $Staggering_Force, _
;~ 		$Veil_of_Thorns, $Zealous_Renewal
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Flash Better result if use before combat
;~ Func FlashBeforeFightSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Attackers_Insight, $Conviction, $Conviction_PvP, $Enchanted_Haste, _
;~ 		$Fleeting_Stability, $Grenths_Grasp, $Harriers_Grasp, $Harriers_Haste, _
;~ 		$Onslaught, $Onslaught_PvP, $Pious_Renewal, $Sand_Shards, $Whirling_Charge
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Item spell
;~ ; Remove Ally's condition, use it and drop it
;~ Func ItemDropToRemoveCondition($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Pure_Was_Li_Ming
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ; Heal all team, use it and dropt it
;~ Func ItemDropToHeal($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	;Rit
;~ 	Case $Protective_Was_Kaolai, $Protective_Was_Kaolai_PvP, _ ;Rit Maybe always use it and drop when need heal
;~ 		$Courageous_Was_Saidra
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Drop it for damage all near enemy
;~ Func ItemDropToDamage($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Cruel_Was_Daoshen, $Defiant_Was_Xinrae, $Destructive_Was_Glaive, $Destructive_Was_Glaive_PvP, _
;~ 		$Grasping_Was_Kuurong, $Blind_Was_Mingson ;Blind, no damage
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ Func ItemAlwaysGotIt($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	;Rit
;~ 	Case $Generous_Was_Tsungrai ;Drop it for Heal my self
;~ 		Return True
;~ 	Case $Resilient_Was_Xiko ;Regen pv for each hex or condition, drop it to remove my condition
;~ 		Return True
;~ 	Case $Tranquil_Was_Tanasen ;Can't be rupt and gain XX armor
;~ 		Return True
;~ 	Case $Vengeful_Was_Khanhei ;Steel XX health at every hit
;~ 		Return True
;~ 	Case $Vocal_Was_Sogolon	;Chant use last XX longer
;~ 		Return True
;~ 	Case $Attuned_Was_Songkai ;Spell and ritual cost less, no effect when drop
;~ 		Return True
;~ 	Case $Energetic_Was_Lee_Sa ;energy regen, gain XX energy when drop
;~ 		Return True
;~ 	Case $Mighty_Was_Vorizun ;More armor, more enegy
;~ 		Return True
;~ 	Case $Anguished_Was_Lingwah ;Always have it and drop when need to recharge ritual hex
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion
#EndRegion Classified



;~ #Region Ward spell
;~ Func DefenseWard($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Banner_of_the_Unseen, $Ebon_Battle_Standard_of_Courage,  $Ebon_Battle_Standard_of_Honor, $Ebon_Battle_Standard_of_Wisdom, _
;~ 		$Ebon_Vanguard_Battle_Standard_of_Power
;~ 		Return True
;~ 	Case $Time_Ward ;Don't know if it work on ally or alli spirit (Translate problem)
;~ 		Return True
;~ 	Case $Ward_Against_Elements,  $Ward_Against_Harm, $Ward_Against_Harm_PvP, $Ward_Against_Melee, $Ward_Against_Melee_PvP, _
;~ 		$Ward_of_Stability
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ Func AgressiveWard($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Ward_of_Weakness ;Weakened condition to enemy if it take elemental damage
;~ 		Return True
;~ 	Case $Ward_Against_Foes ;Slow enemy
;~ 		Return True
;~ 	Case $Radiation_Field ;Degen enemy
;~ 		Return True
;~ 	Case $Teinais_Heat ;Degen enemy
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Weapon spell
;~ Func DefensiveWeaponSpellSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Spirit_Light_Weapon ;Heal more if have a spirit
;~ 		Return True
;~ 	Case $Vengeful_Weapon, $Vital_Weapon
;~ 		Return True
;~ 	Case $Weapon_of_Shadow ;Blind enemy who attack ally with weapon spell
;~ 		Return True
;~ 	Case $Weapon_of_Warding, $Weapon_of_Warding_PvP,  $Xinraes_Weapon
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ Func WeaponSpellConditionSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Weapon_of_Remedy
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ func WeaponSpellConditionOrHexSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Resilient_Weapon
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ func WeaponSpellOnCacSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Guided_Weapon, $Ghostly_Weapon, $Brutal_Weapon, $Great_Dwarf_Weapon, _
;~ 		$Nightmare_Weapon,  $Splinter_Weapon, $Splinter_Weapon_PvP, $Sundering_Weapon, _
;~ 		$Wailing_Weapon, $Warmongers_Weapon, $Weapon_of_Fury, $Weapon_of_Renewal
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ func WeaponSpellOnCasterSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Weapon_of_Quickening
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ func WeaponSpellMySelfSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Weapon_of_Aggression, $Weapons_of_Three_Forges
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Well spell
;~ ;Exploit a corpse
;~ func WellSpellSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Well_Of_Blood, $Well_of_Darkness, $Well_of_Power, $Well_of_Ruin, _
;~ 		$Well_of_Silence, $Well_of_Suffering, $Well_of_Weariness, $Well_of_the_Profane, _
;~ 		$Holiday_Blues, $Tear_Gas
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Form
;~ func FormBeforeFightSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Avatar_of_Balthazar, $Avatar_of_Dwayna, $Avatar_of_Dwayna_PvP, $Avatar_of_Dwayna_snow_fighting_skill, _
;~ 		$Avatar_of_Grenth, $Avatar_of_Grenth_PvP, $Avatar_of_Grenth_snow_fighting_skill, $Avatar_of_Lyssa, _
;~ 		$Avatar_of_Melandru, $Avatar_of_Melandru_PvP, $Raven_Blessing, $Ursan_Blessing, _
;~ 		$Volfen_Blessing
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ func FormSpecialSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Feign_Death, $Hide, $Siege_Devourer
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Glyph
;~ func GlyphSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Glyph_of_Elemental_Power ;Add 2 to elemental power
;~ 		Return True
;~ 	Case $Glyph_of_Energy ;no afflux and add XX elemental power
;~ 		Return True
;~ 	Case $Glyph_of_Essence ; Instant cast (lost all energy)
;~ 		Return True
;~ 	Case $Glyph_of_Immolation ;Burn Target with next skill
;~ 		Return True
;~ 	Case $Glyph_of_Lesser_Energy	;Next spell coast less energy
;~ 		Return True
;~ 	Case $Glyph_of_Renewal ;Next spell Instant recharge
;~ 		Return True
;~ 	Case $Glyph_of_Restoration ;Next spell healing
;~ 		Return True
;~ 	Case $Glyph_of_Sacrifice ; Instant cast (30sec more recharge time)
;~ 		Return True
;~ 	Case $Glyph_of_Swiftness ; nest spell Recharge 25% faster
;~ 		Return True
;~ 	Case $Hidden_Rock; snowball
;~ 		Return True
;~ 	Case $Polymock_Glyph_of_Concentration ;Next spell cannot be interrupt
;~ 		Return True
;~ 	Case $Polymock_Glyph_of_Power ; more damage for nest spell
;~ 		Return True
;~  	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ func GlyphDazedSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Glyph_of_Concentration ;Next skill can't be rupt and unaffected by daze
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Preparation
;~ ;Always use before fight
;~ func PreparationSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Apply_Poison, $Barbed_Arrows, $Choking_Gas, $Corrupted_Breath, _
;~ 		$Disrupting_Accuracy,  $Expert_Focus, $Glass_Arrows, $Glass_Arrows_PvP, _
;~ 		$Ignite_Arrows, $Kindle_Arrows, $Marksmans_Wager, $Melandrus_Arrows, _
;~ 		$Rapid_Fire, $Read_the_Wind, $Read_the_Wind_PvP, $Seeking_Arrows, _
;~ 		$Trappers_Focus, $Yellow_Snow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Nature ritual
;~ ;Always use before fight, not in aggro or just before aggro
;~ func NatureRitualSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Winds, $Brambles, $Conflagration, $Edge_of_Extinction, _
;~ 		$Energizing_Wind, $Equinox, $Famine, $Favorable_Winds, _
;~ 		$Fertile_Season, $Frozen_Soil, $Greater_Conflagration, $Infuriating_Heat, _
;~ 		$Lacerate, $Muddy_Terrain, $Natures_Renewal, $Pestilence, $tory_Season, _
;~ 		$Primal_Echoes, $Quickening_Zephyr, $Quicksand, $Roaring_Winds, $Symbiosis, _
;~ 		$Toxicity, $Tranquility, $Winnowing, $Winter
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Shout
;~ ;Shout best target
;~ func ShoutBestTargetSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $You_Are_All_Weaklings
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout require target 50% hp
;~ func Shout50hpSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Finish_Him, $Ill_Be_Back, $You_Will_Die
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout require Adrenaline
;~ func ShoutAdrenalineSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Save_Yourselves_Kurzick, $Save_Yourselves_Luxon, $Dodge_This, _
;~ 		$Fear_Me, $For_Elona, $Go_for_the_Eyes, $Go_for_the_Eyes_PvP, _
;~ 		$The_Power_Is_Yours, $Watch_Yourself, $Watch_Yourself_PvP, _
;~ 		$Cry_of_Madness
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout only for target ally
;~ func ShoutAllySkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Brace_Yourself, $Brace_Yourself_PvP, $Lead_the_Way, _
;~ 		$Make_Haste, $Godspeed
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ; Shout if dead ally
;~ func ShoutDeadAllySkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $I_Will_Avenge_You
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ; Shout if I have condition
;~ func ShoutConditionSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $I_Will_Survive, $Tango_Down
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout If ally have condition
;~ func ShoutAllyConditionSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Its_Just_a_Flesh_Wound
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout if I need heal
;~ func ShoutHealSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Mmmm_Snowcone
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout
;~ func ShoutSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Cant_Touch_This, $Cant_Touch_This_PvP, $Charge, $Dont_Trip, _
;~ 		$Fall_Back, $Fall_Back_PvP, $For_Great_Justice,  $For_Great_Justice_PvP, _
;~ 		$Form_Up_and_Advance, $I_Am_Unstoppable, $I_Am_the_Strongest, $Incoming, _
;~ 		$Incoming_PvP,  $Lets_Get_Em, $Make_Your_Time, $Never_Give_Up, $Never_Give_Up_PvP, _
;~ 		$Never_Surrender, $Never_Surrender_PvP, $Retreat, $Shields_Up, $Stand_Your_Ground, _
;~ 		$Stand_Your_Ground_PvP, $Theres_Nothing_to_Fear, $Theres_Nothing_to_Fear_Thackeray, _
;~ 		$Theyre_on_Fire, $To_the_Limit, $Together_as_One, $Call_of_Haste, $Call_of_Haste_PvP, _
;~ 		$Call_of_Protection, $Otyughs_Cry, $Predatory_Bond, $Predatory_Bond_PvP, $Raven_Shriek, _
;~ 		$Steady_Aim, $Sticky_Ground, $Strike_as_One, $Sugar_Shock, $Symbiotic_Bond, $Ursan_Roar, _
;~ 		$Ursan_Roar_Blood_Washes_Blood, $Volfen_Bloodlust, $Volfen_Bloodlust_Curse_of_the_Nornbear
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout if target moving
;~ func ShoutTargetMovingSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $None_Shall_Pass
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout if target has conition
;~ func ShoutTargetConditionSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Victory_Is_Mine
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout for cac
;~ func ShoutCacSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Find_Their_Weakness, $Find_Their_Weakness_PvP, $Find_Their_Weakness_Thackeray
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Shout for Healer
;~ func ShoutHealerSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Help_Me, $Help_Me_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Interrupts skills but not regular attacks
;~ func ShoutRuptSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $You_Move_Like_a_Dwarf ;PvE Cause crippled
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and target moving
;~ func ShoutMovingAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Coward
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and if i'm adjacent to knocked down foe
;~ func ShoutNearAndKnockAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $On_Your_Knees
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Signet
;~ ; Use signet on best target
;~ func SignetBestTarget($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Weariness, $Signet_of_the_Unseen, $Tryptophan_Signet, _
;~ 		$Unnatural_Signet,  $Unnatural_Signet_PvP, $Unnatural_Signet_Saul_DAlessio
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use If i'm enchanted
;~ func SignetIHaveEnchantSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Mystic_Wrath, $Signet_of_Pious_Light, _
;~ 		$Signet_of_Pious_Restraint, $Signet_of_Pious_Restraint_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Is touch signet
;~ func SignetTouchSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Midnight
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use Signet If target below 50% hp
;~ func SignetTarget50hpSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Lost_Souls
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use signet if target poisoned
;~ func SignetTargetPoisonedSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Toxic_Shock
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use signet if target blind
;~ func SignetTargetBlindSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Shadows
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use signet if target bleed
;~ func SignetTargetBleedSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Infection
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Signet Remove Ench on target
;~ func SignetRemoveEnchantSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Disenchantment, $Signet_of_Twilight
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Is Heal Signet
;~ func SignetHealAllySkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Devotion, $Signet_of_Rejuvenation, $Signet_of_Synergy
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use Signet If have a spirit
;~ func SignetSpiritAllySkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Creation, $Signet_of_Creation_PvP, $Signet_of_Ghostly_Might, $Signet_of_Ghostly_Might_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use signet if target is spirit enemy
;~ func SignetSpiritEnemySkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Binding
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use signet if enemy is near
;~ func SignetEnemyNearSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Agony, $Signet_of_Agony_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use signet touch ally if he has hex
;~ func SignetTouchAllyHexSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Hex_Eater_Signet
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use signet on target, no requi
;~ func SignetUseSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Barbed_Signet, $Barbed_Signet_PvP, $Candy_Corn_Strike, $Signet_of_Humility, _
;~ 		$Signet_of_Judgment, $Signet_of_Judgment_PvP, $Signet_of_Rage, $Signet_of_Sorrow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use If target attack
;~ func SignetAttackSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Bane_Signet, $Castigation_Signet, $Castigation_Signet_Saul_DAlessio
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ; Use signet for me
;~ func SignetOnMeSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Archers_Signet, $Blessed_Signet, $Boon_Signet, $Dolyak_Signet, _
;~ 		$Keystone_Signet, $Poison_Tip_Signet, $Signet_of_Aggression, $Signet_of_Illusions, _
;~ 		$Signet_of_Mystic_Speed, $Signet_of_Recall, $Signet_of_Spirits, $Signet_of_Spirits_PvP, _
;~ 		$Signet_of_Stamina, $Signet_of_Strength, $Signet_of_Suffering
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ; Remove on all alli condition
;~ func SignetRemoveConditionSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Cautery_Signet
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ; Remove condition on my self
;~ func SignetRemoveMySelfConditionSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Remedy_Signet, $Antidote_Signet, $Lightbringer_Signet
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ; if target has condition
;~ func SignetTargetConditionSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Malice, $Sadists_Signet, $Signet_of_Corruption_Luxons, $Signet_of_Corruption_Kurzicks, _
;~ 		$Signet_of_Deadly_Corruption, $Signet_of_Deadly_Corruption_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ; transfert my condition on target
;~ func SignetTransfetConditionSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Plague_Signet
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use it if target burn
;~ func SignetEnergyTargetBurnSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Glowing_Signet
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use it if don't have energy
;~ func SignetNoMoreEnergySkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Ether_Signet
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use on War, Ranger, Sin, Der, Para to rupt attack
;~ func SignetRuptCac($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Clumsiness,  $Signet_of_Clumsiness_PvP, $Polymock_Signet_of_Clumsiness
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Interrupts skills but not regular attacks
;~ func SignetRuptSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Distraction
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Interrupts skills if target has hex
;~ func SignetRuptSkillIfTargetHasHex($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Signet_of_Disruption
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Chant
;~ ;Chant require adrenaline
;~ func ChantAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Anthem_of_Envy, $Anthem_of_Envy_PvP, $Lyric_of_Zeal, $Anthem_of_Guidance, _
;~ 		$Crippling_Anthem, $Energizing_Chorus, $Song_of_Purification, $Chorus_of_Restoration, _
;~ 		$Hexbreaker_Aria
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Chant
;~ func ChantSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Anthem_of_Disruption, $Anthem_of_Disruption_PvP, $Anthem_of_Flame, $Anthem_of_Fury, _
;~ 		$Anthem_of_Weariness, $Aria_of_Restoration, $Aria_of_Zeal,  $Ballad_of_Restoration, _
;~ 		$Ballad_of_Restoration_PvP, $Defensive_Anthem, $Defensive_Anthem_PvP, $Lyric_of_Purification, _
;~ 		$Presence_of_the_Skale_Lord, $Song_of_Power, $Song_of_Restoration, $Song_of_Restoration_PvP, _
;~ 		$Zealous_Anthem, $Focused_Anger
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use If alli will die
;~ func ChantSaveSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Angelic_Bond, $Angelic_Protection
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Echo
;~ ;Echo on me or ally
;~ func EchoSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Bladeturn_Refrain, $Bladeturn_Refrain_PvP ;Better on caster ally
;~ 		Return True
;~ 	Case $Blazing_Finale, $Blazing_Finale_PvP ;Better on cac ally
;~ 		Return True
;~ 	Case $Enduring_Harmony ;Chant and shout last 50% longer on target ally
;~ 		Return True
;~ 	Case $Energizing_Finale, $Burning_Refrain, $Finale_of_Restoration, $Finale_of_Restoration_PvP, $Hasty_Refrain, _
;~ 		$Heroic_Refrain, $Purifying_Finale, $Mending_Refrain, $Mending_Refrain_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Echo on ally only
;~ func EchoOnAllykill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Inspirational_Speech
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Echo on me only
;~ func EchoMySelfSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Aggressive_Refrain, $Soldiers_Fury, $Burning_Shield, $Natural_Temper, _
;~ 		$Leaders_Zeal
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Echo for heal myself
;~ func EchoHealMySelfSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Leaders_Comfort
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Trap
;~ ;Heal Only me Req adrenaline
;~ func TrapSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Barbed_Trap, $Black_Powder_Mine,  $Dust_Trap, $Flame_Trap, _
;~ 		$Healing_Spring, $Land_Mine, $Piercing_Trap, $Smoke_Trap, _
;~ 		$Snare, $Spike_Trap, $Tripwire, $Vipers_Nest, $Weakness_Trap
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Stance
;~ ;Need to create a func for Stance
;~ ;Expl: I use Mantra Of Earth, Use it again only if i don't have the mantra of earth effect any more
;~ ;Stance Adrenaline use during fight
;~ func StanceAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Bonettis_Defense, $Defensive_Stance, $Defy_Pain, $Defy_Pain_PvP, _
;~ 		$Battle_Rage, $Flail, $Heart_of_Fury, $Heart_of_Fury_PvP, _
;~ 		$Primal_Rage, $Rush, $Auspicious_Parry
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Stance use during fight
;~ func StanceSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Bestial_Fury, $Flashing_Blades, $Elemental_Resistance, $Lightning_Reflexes, _
;~ 		$Lightning_Reflexes_PvP, $Mantra_of_Earth, $Mantra_of_Flame, $Mantra_of_Frost, _
;~ 		$Mantra_of_Inscriptions, $Mantra_of_Lightning, $Mantra_of_Resolve, $Mantra_of_Resolve_PvP, _
;~ 		$Natures_Blessing, $Physical_Resistance, $Pious_Concentration, $Storm_Chaser, _
;~ 		$Symbolic_Posture, $Tigers_Fury, $Wary_Stance, $Whirling_Defense, $Balanced_Stance, _
;~ 		$Berserker_Stance, $Bulls_Charge, $Burst_of_Aggression, $Charging_Strike, $Dark_Escape, _
;~ 		$Dash, $Disciplined_Stance,  $Distortion, $Dodge, $Drunken_Master, $Dryders_Defenses, _
;~ 		$Dwarven_Battle_Stance, $Enraging_Charge, $Escape, $Escape_PvP, $Experts_Dexterity, _
;~ 		$Experts_Dexterity_PvP, $Flurry, $Frenzied_Defense, $Frenzy, $Gladiators_Defense, _
;~ 		$Hekets_Rampage, $Hex_Breaker, $Junundu_Tunnel, $Mantra_of_Concentration, _
;~ 		$Mantra_of_Persistence, $Mantra_of_Recovery, $Mantra_of_Signets, $Mantra_of_Signets_PvP, _
;~ 		$Melandrus_Resilience, $Natural_Stride, $Pious_Fury, $Pious_Fury_PvP, $Pious_Haste, _
;~ 		$Practiced_Stance, $Riot_Shield, $Run_as_One, $Serpents_Quickness, $Seven_Weapons_Stance, _
;~ 		$Shield_Stance, $Smoke_Powder_Defense, $Soldiers_Defense, $Soldiers_Speed, $Soldiers_Stance, _
;~ 		$Soldiers_Stance_PvP,$Sprint, $Steady_Stance, $Storms_Embrace, $Sugar_Rush_Agent_of_the_Mad_King, _
;~ 		$Tiger_Stance, $Trappers_Speed, $Unseen_Fury, $Unseen_Fury_PvP, $Warriors_Endurance, _
;~ 		$Warriors_Endurance_PvP, $Way_of_the_Assassin, $Zojuns_Haste, $Warriors_Cunning
;~ 		Return True
;~ 	Case $Protectors_Defense ;alli can block
;~ 		Return True
;~ 	Case $Riposte ; block next attack
;~ 		Return True
;~ 	Case $Shield_Bash ;block next attack cause knock down
;~ 		Return True
;~ 	Case $Endure_Pain ;more pv
;~ 		Return True
;~ 	Case $Hundred_Blades ;each attack cause more damage
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Pet attack
;~ ;attack pet
;~ func PetAttackSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Enraged_Lunge, $Enraged_Lunge_PvP, $Feral_Lunge, $Ferocious_Strike, _
;~ 		$Maiming_Strike, $Melandrus_Assault, $Melandrus_Assault_PvP, $Poisonous_Bite, _
;~ 		$Pounce, $Predators_Pounce, $Rampage_as_One, $Feral_Aggression, $Never_Rampage_Alone
;~ 		Return True
;~ 	Case $Heal_as_One ;Not attack, heal pet
;~ 		Return True
;~ 	Case $Heal_as_One_PvP ;Not attack, heal pet
;~ 		Return True
;~ 	Case $Companionship ;Not attack, heal pet
;~ 		Return True
;~ 	Case $Revive_Animal ;rez pet
;~ 		Return True
;~ 	Case $Comfort_Animal
;~ 		Return True
;~ 	Case $Comfort_Animal_PvP ;heal and rez pet
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use if target has condition
;~ func PetConditionSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Scavenger_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use if target knock down
;~ func PetTargetKnockSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Bestial_Mauling
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use if target less 50% hp
;~ func PetTarget50HpSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Brutal_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Interrupts by pet
;~ func PetRuptSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Disrupting_Lunge, $Bestial_Pounce, $Savage_Pounce
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Bow attack
;~ ;Bow attack
;~ func BowAttackSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Arcing_Shot, $Called_Shot, $Crossfire, $Determined_Shot, $Focused_Shot, _
;~ 		$Hunters_Shot, $Keen_Arrow, $Keen_Arrow_PvP, $Melandrus_Shot, $Point_Blank_Shot, _
;~ 		$Poison_Arrow, $Prepared_Shot, $Quick_Shot, $Zojuns_Shot, $Burning_Arrow, _
;~ 		$Crippling_Shot, $Debilitating_Shot, $Dual_Shot, $Forked_Arrow, _
;~ 		$Keirans_Sniper_Shot_Hearts_of_the_North, $Marauders_Shot, $Oath_Shot, _
;~ 		$Penetrating_Attack, $Penetrating_Attack_PvP, $Power_Shot, $Precision_Shot, _
;~ 		$Screaming_Shot,  $Sloth_Hunters_Shot, $Sloth_Hunters_Shot_PvP, $Sundering_Attack, _
;~ 		$Sundering_Attack_PvP, $Pin_Down, $Relentless_Assault
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Bow attack on best target
;~ func BowBestTargetAttackSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Barrage, $Incendiary_Arrows, $Rain_of_Arrows, $Volley, _
;~ 		$Splinter_Shot, $Triple_Shot_Kurzicks, $Triple_Shot_Luxons
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Target has condition
;~ func BowTargetHHasCondition($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Scavengers_Focus
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Target has cracked armor
;~ func BowTargetCrackedArmorAttackSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Body_Shot
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Target less 50% hp
;~ func BowTarget50HpAttackSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Needling_Shot
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Target Has weakness
;~ func BowTargetWeaknessAttackSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Gravestone_Marker
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Interrupts skills but not regular attacks
;~ func BowRuptSkill($Skill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Broad_Head_Arrow,  $Concussion_Shot, $Punishing_Shot, $Savage_Shot, _
;~ 		$Magebane_Shot, $Disrupting_Shot, $Distracting_Shot, $Terminal_Velocity
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Spear attack
;~ ;Spear skill
;~ func SpearSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Spear_of_Lightning, $Swift_Javelin, $Vicious_Attack, $Harriers_Toss, _
;~ 		$Harriers_Toss_PvP, $Slayers_Spear, $Spear_Swipe
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Spear attack if target has cracked armor
;~ func SpearTargetCrackedArmorSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Chest_Thumper
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Spear attack if target bleeding
;~ func SpearTargetBleedingSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Maiming_Spear
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Spear attack if target has condition
;~ func SpearTargetConditionSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Spear_of_Fury_Luxon, $Spear_of_Fury_Kurzick
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline
;~ func SpearAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Barbed_Spear, $Blazing_Spear, $Holy_Spear, $Mighty_Throw, _
;~ 		$Spear_of_Redemption, $Unblockable_Throw, $Wearying_Spear
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and Conditioned Target
;~ func SpearTargetConditionedAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Stunning_Strike ; spear
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and Stanced target
;~ func SpearTargetStancedAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Wild_Throw ;Spear
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and 50%hp or less
;~ func Spear50HPLessAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Merciless_Spear ;Distance attack
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Interrupts skills
;~ func SpearRuptSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Jadoths_Storm_of_Judgment
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Interrupts skills If target has condition
;~ func SpearRuptTargetHasCondition($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Disrupting_Throw
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Spear require knockdown arget
;~ func SpearTargetKnockDownSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Awe
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and target don't moving
;~ func SpearDontMovingAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	;Para
;~ 	Case $Cruel_Spear
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Dagger attack
;~ #Region Lead attack
;~ ;Lead Attack
;~ func LeadAttackSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Desperate_Strike, $Golden_Fox_Strike, $Jagged_Strike, $Leaping_Mantis_Sting, _
;~ 		$Unsuspecting_Strike, $Dancing_Daggers, $Shadow_Theft
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Lead Attack if i'm enchanted
;~ func LeadImEnchantSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Golden_Lotus_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Lead Attack if target has hex or condition
;~ func LeadTargetHexOrConditionSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Iron_Palm
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ ;Lead attack, if target hexed
;~ func LeadTargetHexSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Black_Lotus_Strike; Lead Attack
;~ 		Return True
;~ 	Case $Black_Mantis_Thrust
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Lead attack, Interrupts spells only
;~ func LeadRuptSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Disrupting_Stab ; Lead Attack
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Off-hand attack
;~ ;OffHand Attack
;~ ; $Fox_Fangs
;~ ; $Fox_Fangs_PvP
;~ ; $Lotus_Strike
;~ ; $Repeating_Strike
;~ ; $Wild_Strike
;~ ; $Wild_Strike_PvP
;~ ; $Withering_Blade
;~ ; $Mantis_Touch
;~ ; $Palm_Strike

;~ ;OffHand require target knock down
;~ ; $Falling_Lotus_Strike
;~ ; $Falling_Spider

;~ ;OffHand require Hex
;~ ; $Black_Spider_Strike

;~ ;OffHand If I'm enchanted
;~ ; $Golden_Fang_Strike
;~ ; $Golden_Phoenix_Strike

;~ ;OffHand If Target enchanted
;~ ; $Golden_Skull_Strike

;~ ;OffHand If Target Crippled
;~ ; $Jungle_Strike

;~ ;OffHand If Target has less 50% hp
;~ ; $Moebius_Strike

;~ ;Off-Hand attack, Interrupts spells only
;~ func OffHandRuptSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Temple_Strike ; Must follow lead attack
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Dual attack
;~ ;Dual attack
;~ ; $Blades_of_Steel
;~ ; $Critical_Strike
;~ ; $Death_Blossom
;~ ; $Death_Blossom_PvP
;~ ; $Horns_of_the_Ox
;~ ; $Nine_Tail_Strike
;~ ; $Twisting_Fangs
;~ ; $Vampiric_Assault

;~ ;Dual Attack If target enchanted
;~ ; $Shattering_Assault

;~ ;Dual Attack If target Crippled
;~ ; $Trampling_Ox

;~ ;Dual Attack if target has deep wound
;~ ; $Venom_Fang

;~ ;Dual attack, Interrupts spells only
;~ func DualRuptSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Exhausting_Assault ;  Must follow lead attack
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion
;~ #EndRegion Dagger attack

;~ #Region Hit
;~ ;Hit with no requi
;~ func Hit($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Judgment_Strike, $Hamstring, $Jaizhenju_Strike, $Pure_Strike, _
;~ 		$Seeking_Blade, $Cyclone_Axe, $Furious_Axe, $Swift_Chop, _
;~ 		$Triple_Chop, $Crude_Swing, $Enraged_Smash, $Enraged_Smash_PvP, _
;~ 		$Irresistible_Blow, $Mokele_Smash, $Crippling_Sweep, $Eremites_Attack, _
;~ 		$Eremites_Attack_PvP, $Farmers_Scythe, $Irresistible_Sweep, $Zealous_Sweep, _
;~ 		$Banishing_Strike, $Banishing_Strike_PvP, $Brawling_Combo_Punch, $Brawling_Jab1, _
;~ 		$Brawling_Jab2, $Brawling_Straight_Right, $Club_of_a_Thousand_Bears, $Counterattack, _
;~ 		$Desperation_Blow, $Drunken_Blow, $Griffons_Sweep, $Judgment_Strike, $Leviathans_Sweep, _
;~ 		$Magehunter_Strike,  $Pious_Assault, $Pious_Assault_PvP, $Power_Attack, $Sneak_Attack, _
;~ 		$Soldiers_Strike, $Thrill_of_Victory, $Victorious_Sweep
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Melee attack, Interrupts spells only
;~ func HitRupt($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Disarm, $Savage_Slash, $Critical_Chop, $Disrupting_Chop, _
;~ 		$Lyssas_Assault, $Distracting_Blow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Melee attack, Interrupts spells If target cracked armor
;~ func HitRuptCrack($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Distracting_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use if target is knock down
;~ func HitKnock($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Belly_Smash, $Crushing_Blow, $Overbearing_Smash, _
;~ 		$Renewing_Smash, $Renewing_Smash_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Attack If i'm enchanted
;~ func HitIEnch($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Wounding_Strike, $Wounding_Strike_PvP, $Mystic_Sweep, $Mystic_Sweep_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Melee if target moving
;~ func HitMove($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Bulls_Strike, $Protectors_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Melee if target has condition
;~ func HitCondi($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Malicious_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Melee if target has stance
;~ func HitStance($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Wild_Blow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion Hit

;~ #Region Hit Adrenaline
;~ ;Require adrenaline
;~ func HitAdre($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Dragon_Slash, $Dragon_Slash_Turai_Ossa, $Galrath_Slash, $Silverwing_Slash, _
;~ 		$Sun_and_Moon_Slash, $Crippling_Slash, $Standing_Slash, $Sever_Artery, _
;~ 		$Decapitate, $Eviscerate, $Executioners_Strike, $Dismember, _
;~ 		$Penetrating_Blow, $Penetrating_Chop, $Cleave, $Keen_Chop, _
;~ 		$Backbreaker, $Devastating_Hammer, $Mighty_Blow, $Hammer_Bash, _
;~ 		$Staggering_Blow, $Staggering_Blow_PvP, $Radiant_Scythe, $Rending_Sweep, _
;~ 		$Brawling_Uppercut, $Falkens_Fire_Fist, $Brawling_Headbutt, $Brawling_Hook1, _
;~ 		$Brawling_Hook2, $Symbolic_Strike,$Twin_Moon_Sweep, $Twin_Moon_Sweep_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and target has knocked down
;~ func HitAdreKnock($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Steelfang_Slash, $Lacerating_Chop, $Pulverizing_Smash, $Low_Blow, _
;~ 		$Bludgeon, $Falken_Punch
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and Conditioned Target
;~ func HitAdreCondi($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Club_Strike, $Reap_Impurities
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and Crippled target
;~ func HitAdreCrip($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Knee_Cutter
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and target has Weakned
;~ func HitAdreWeak($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Fierce_Blow, $Fierce_Blow_PvP, $Auspicious_Blow, $Heavy_Blow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and target has cracked armor
;~ func HitAdreCrack($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Body_Blow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and target bleeding
;~ func HitAdreBleed($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Gash
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and target deep wound
;~ func HitAdreDeep($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Axe_Rake
;~ 		Return True
;~ 	Case $Axe_Twist
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and target moving
;~ func HitAdreMove($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Quivering_Blade
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and Stanced target
;~ func HitAdreStance($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Whirling_Axe, $Forceful_Blow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and I don't have stance
;~ func HitAdreNoStance($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Barbarous_Slice
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and take best target
;~ func HitAdreBT($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Earth_Shaker, $Yeti_Smash, $Chilling_Victory, $Chilling_Victory_PvP, _
;~ 		$Crippling_Victory, $Whirlwind_Attack, $Annihilator_Knuckle
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and Enchanted target
;~ func HitAdreEnch($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Magehunters_Smash
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and Target attack
;~ func HitAdreAtta($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Counter_Blow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and 50%hp or less
;~ func HitAdre50($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Final_Thrust
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Melee attack require adre, Interrupts spells only if target has deep wound
;~ func HitAdreRuptDeep($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Agonizing_Chop
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and I Have Derv Enchant
;~ func HitAdreDerv($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Reapers_Sweep, $Wearying_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline, Stanced target and Derv Enchantment
;~ func HitAdreStanceDerv($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Irresistible_Sweep_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Require adrenaline and if i'm enchanted
;~ func HitAdreIEnch($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Aura_Slicer
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Melee attack require adre, Interrupts spells only
;~ func HitAdreRupt($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Skull_Crack
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion Hit Adrenaline

;~ #Region Skill (untyped)
;~ func TouchSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Grapple ;Touch skill cause knock down
;~ 		Return True
;~ 	Case $Headbutt ;touch skill (i'm dazed)
;~ 		Return True
;~ 	Case $Throw_Dirt ;blind target
;~ 		Return True
;~ 	Case $Rending_Touch, $Holy_Strike, $Stonesoul_Strike, $Blackout, _
;~ 		$Enfeebling_Touch, $Touch_of_Agony, $Wallows_Bite, $Vile_Touch, _
;~ 		$Vampiric_Bite, $Vampiric_Touch, $Star_Burst, $Lightning_Touch, _
;~ 		$Shock
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Touch if target has enchant
;~ func TouchTargetEnchantSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Expunge_Enchantments
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use touch if i have condition
;~ func TouchConditionSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Plague_Touch
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use heal touch on ally or me
;~ func HealTouchSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Dwaynas_Touch, $Healing_Touch, $Mending_Touch
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Use on ally near enemy
;~ func SkillAllyNearEnemy($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Ancestors_Rage, $Ancestors_Rage_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Heal Only me Req adrenaline
;~ func HealMySelfAdrenalineSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Lions_Comfort
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion

;~ #Region Rez
;~ ;Rez skill
;~ func RezSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Unyielding_Aura, $Unyielding_Aura_PvP ;Bond, need to always activate and remove for rez
;~ 		Return True
;~ 	Case $Light_of_Dwayna, $Rebirth, $Renew_Life, $Resurrect, _
;~ 		$Vengeance, $Death_Pact_Signet, $Death_Pact_Signet_PvP, $Flesh_of_My_Flesh, _
;~ 		$Flesh_of_My_Flesh_PvP, $We_Shall_Return, $We_Shall_Return_PvP, $Signet_of_Return, _
;~ 		$Signet_of_Return_PvP, $Resurrection_Signet, $By_Urals_Hammer, $Eternal_Aura, _
;~ 		$Junundu_Wail, $Sunspear_Rebirth_Signet
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Rez skill, Need to be near from ally or move to ally
;~ func TouchRezSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Resurrection_Chant ;Half Range
;~ 		Return True
;~ 	Case $Restore_Life ;Touch Skill
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ func BindingRitualRezSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Restoration, $Restoration_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Chant require adrenaline and use when ally are dead
;~ func ChantAdrenalineHelpRezSkill($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Song_of_Concentration
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Rez Skill, use it and drop it
;~ func ItemDropToRez($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Lively_Was_Naomei
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion Rez

;~ #Region Heal
;~ ;Heal Only me
;~ func HealMe($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Healing_Signet, $Healing_Signet_Turai_Ossa, $Troll_Unguent, $Healing_Ring, _
;~ 		$Heal_Party, $Aegis, $Heal_Area, $Release_Enchantments, $Hexers_Vigor, _
;~ 		$Blood_Renewal, $Spirit_Transfer, $Mystic_Healing, $Mystic_Healing_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Heal me or ally
;~ Func HealMeOrAlly($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Light_of_Deliverance, $Light_of_Deliverance_PvP, $Glimmer_of_Light, $Healing_Burst, _
;~ 		$Healing_Light, $Patient_Spirit, $Reversal_of_Fortune, $Restful_Breeze, _
;~ 		$Watchful_Healing, $Healing_Seed, $Healing_Breeze, $Vigorous_Spirit, _
;~ 		$Dwaynas_Sorrow, $Orison_of_Healing, $Ethereal_Light, $Heavens_Delight, _
;~ 		$Divine_Healing, $Kareis_Healing_Circle, $Soothing_Memories, $Pious_Restoration, _
;~ 		$Natural_Healing
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Heal if spirit in earshot
;~ Func HealMeOrAllySpirit($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ Case $Mend_Body_and_Soul, $Spirit_Light
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Heal If me or ally has a weapon spell
;~ Func HealWithWeaponSpell($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Wielders_Boon
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Heal ally only
;~ Func HealAllyOnly($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Seed_of_Life, $Holy_Wrath, $Healing_Whisper, $Dwaynas_Kiss, _
;~ 		$Gift_of_Health, $Healing_Ribbon, $Heal_Other, $Jameis_Gaze, _
;~ 		$Ghostmirror_Light, $Imbue_Health
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Heal ally less 50% hp
;~ Func HealAlly50Hp($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Word_of_Healing, $Zealous_Benediction, $Divine_Intervention, $Judges_Intervention
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Heal_ally_less_50%_hp_if_ally_spirit_in_earshot
;~ Func HealAlly50HpSpirit($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Feast_of_Souls
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Heal_ally_less_25%_hp
;~ Func HealAlly25Hp($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Infuse_Health
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Prot_me_or_ally
;~ Func ProtMeOrAlly($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Aura_of_Faith, $Air_of_Enchantment, $Shield_of_Regeneration, $Mark_of_Protection, _
;~ 		$Healing_Hands, $Shield_of_Absorption, $Protective_Spirit, $Shielding_Hands
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;if_the_ally_or_me_suffers_physical_damage
;~ Func ProtPhysical($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Shield_of_Deflection, $Balthazars_Pendulum, $Shield_of_Judgment, $Shield_Guardian, _
;~ 		$Guardian, $Aura_of_Stability, $Pensive_Guardian, $Supportive_Spirit, _
;~ 		$Reversal_of_Damage, $Tainted_Flesh, $Withering_Aura
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;if_the_ally_suffers_magical_damage_or_hex
;~ Func ProtMagical($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Spell_Breaker, $Aegis_PvP, $Spirit_Bond, $Spirit_Bond_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;if_the_ally_or_me_has_conditions
;~ Func AllyOrMeCondi($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Life_Sheath, $Restore_Condition, $Smite_Condition, $Mend_Ailment, _
;~ 		$Purge_Conditions, $Dismiss_Condition
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;if_the_ally_only_has_condition
;~ Func AllyCondi($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Spotless_Soul, $Mend_Condition, $Draw_Conditions, $Foul_Feast
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Remove_condition_If_me_or_ally_has_a_weapon_spell
;~ Func CondiWeaponSpell($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Mending_Grip
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_me_only_if_ally_has_condition
;~ Func MeAllyCondi($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Martyr, $Extinguish,  $Words_of_Comfort, $Angorodons_Gaze
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Bond
;~ Func JamesBond($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Life_Barrier, $Unyielding_Aura, $Unyielding_Aura_PvP, $Succor, _
;~ 		$Mending, $Watchful_Spirit, $Vital_Blessing, $Purifying_Veil, _
;~ 		$Retribution, $Holy_Veil, $Life_Bond, $Blessed_Aura, _
;~ 		$Protective_Bond, $Strength_of_Honor, $Strength_of_Honor_PvP, $Life_Attunement, _
;~ 		$Balthazars_Spirit, $Divine_Boon, $Essence_Bond, $Live_Vicariously, _
;~ 		$Recall, $Shadow_Meld, $Aura_of_Displacement
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion Heal

;~ #Region Spell
;~ ;On_me_only
;~ Func SpellForMe($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Scribes_Insight, $Healers_Boon, $Healers_Covenant, $Amity, $Divine_Spirit, _
;~ 		$Holy_Haste, $Smiters_Boon_PvP, $Spell_Shield, $Selfless_Spirit_Luxons, _
;~ 		$Selfless_Spirit_Kurzicks, $Smiters_Boon, $Soul_Taker, $Cultists_Fervor, _
;~ 		$Contagion, $Order_of_the_Vampire, $Order_of_Apostasy, $Aura_of_the_Lich, _
;~ 		$Order_of_Undeath, $Offering_of_Blood, $Masochism, $Infuse_Condition, _
;~ 		$Awaken_the_Blood, $Masochism_PvP, $Dark_Aura, $Dark_Bond, $Demonic_Flesh, _
;~ 		$Veratas_Aura,  $Order_of_Pain, $Dark_Fury, $Veratas_Sacrifice, $Lyssas_Aura, _
;~ 		$Mantra_of_Recall, $Illusionary_Weaponry, $Illusionary_Weaponry_PvP, $Echo, _
;~ 		$Energy_Drain, $Ancestors_Visage, $Sympathetic_Visage, $Illusion_of_Haste, _
;~ 		$Illusion_of_Haste_PvP, $Channeling, $Arcane_Echo, $Auspicious_Incantation, _
;~ 		$Symbolic_Celerity, $Illusion_of_Weakness, $Master_of_Magic, $Ether_Renewal, _
;~ 		$Ether_Renewal_PvP, $Ether_Prodigy, $Obsidian_Flesh, $Mist_Form, $Mist_Form_PvP, _
;~ 		$Elemental_Attunement, $Over_the_Limit, $Ether_Prism, $Magnetic_Aura, _
;~ 		$Swirling_Aura, $Sliver_Armor, $Windborne_Speed, $Stoneflesh_Aura, _
;~ 		$Elemental_Flame, $Elemental_Flame_PvP, $Stone_Striker, $Burning_Speed, _
;~ 		$Kinetic_Armor, $Flame_Djinns_Haste, $Iron_Mist, $Armor_of_Mist, _
;~ 		$Frigid_Armor, $Storm_Djinns_Haste, $Armor_of_Frost, $Armor_of_Earth, _
;~ 		$Fire_Attunement, $Water_Attunement, $Earth_Attunement, $Air_Attunement, _
;~ 		$Elemental_Lord_Luxons, $Elemental_Lord_Kurzicks, $Aura_of_Restoration, _
;~ 		$Aura_of_Restoration_PvP, $Conjure_Frost, $Conjure_Flame, $Conjure_Lightning, _
;~ 		$Magnetic_Surge, $Ice_Spear, $Intensity, $Wielders_Zeal, $Spirits_Strength, _
;~ 		$Ritual_Lord, $Soul_Twisting,  $Reclaim_Essence, $Consume_Soul, $Ghostly_Haste, _
;~ 		$Renewing_Memories, $Sight_Beyond_Sight, $Wielders_Remedy, $Armor_of_Unfeeling, _
;~ 		$Armor_of_Unfeeling_PvP, $Explosive_Growth, $Boon_of_Creation, $Spirits_Gift, _
;~ 		$Spiritleech_Aura, $Spirit_Siphon, $Foxs_Promise, $Dark_Apostasy, $Shadow_Form, _
;~ 		$Shadow_Form_PvP, $Way_of_the_Empty_Palm, $Locusts_Fury, $Critical_Agility, _
;~ 		$Feigned_Neutrality, $Critical_Defenses, $Sharpen_Daggers, $Shadow_Refuge, _
;~ 		$Shadow_Sanctuary_Luxons, $Shadow_Sanctuary_Kurzicks, $Way_of_the_Fox, _
;~ 		$Deadly_Haste, $Way_of_the_Lotus, $Assassins_Remedy, $Assassins_Remedy_PvP, _
;~ 		$Shroud_of_Distress, $Shroud_of_Distress_PvP, $Way_of_the_Master, $Way_of_Perfection, _
;~ 		$Critical_Eye, $Dash, $Dark_Escape, $Vow_of_Revolution, $Vow_of_Silence, _
;~ 		$Arcane_Zeal, $Vow_of_Strength, $Zealous_Vow, $Featherfoot_Grace, _
;~ 		$Intimidating_Aura, $Mystic_Regeneration, $Mystic_Regeneration_PvP, $Meditation, _
;~ 		$Mystic_Vigor, $Vital_Boon, $Guiding_Hands, $Guiding_Hands_PvP, $Vow_of_Piety, _
;~ 		$Aura_of_Holy_Might_Luxons, $Aura_of_Holy_Might_Kurzicks, $Armor_of_Sanctity, _
;~ 		$Faithful_Intervention, $Eternal_Aura, $Winds_of_Disenchantment
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_any_enemy
;~ Func SpellEnemy($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Word_of_Censure, $Scourge_Healing, $Scourge_Sacrifice, $Smite, _
;~ 		$Banish, $Spear_of_Light, $Vampiric_Spirit, $Wail_of_Doom, _
;~ 		$Spoil_Victor, $Spoil_Victor_PvP, $Reapers_Mark, $Soul_Bind, _
;~ 		$Grenths_Balance, $Atrophy, $Mark_of_Fury, $Malign_Intervention, _
;~ 		$Defile_Flesh, $Spinal_Shivers, $Shivers_of_Dread, $Life_Siphon, _
;~ 		$Parasitic_Bond, $Soul_Barbs, $Barbs, $Dark_Pact, $Bitter_Chill, _
;~ 		$Enfeeble, $Enfeeble_PvP, $Vampiric_Gaze, $Blood_Drinker, $Recurring_Insecurity, _
;~ 		$Conjure_Phantasm, $Conjure_Nightmare, $Illusion_of_Pain, $Illusion_of_Pain_PvP, _
;~ 		$Ignorance, $Shrinking_Armor, $Phantom_Pain, $Arcane_Larceny, $Arcane_Thievery, _
;~ 		$Ether_Feast, $Spiritual_Pain, $Spiritual_Pain_PvP, $Aneurysm, $Mind_Shock, _
;~ 		$Mind_Shock_PvP, $Mind_Blast, $Second_Wind, $Winters_Embrace, $Lightning_Strike, _
;~ 		$Smoldering_Embers, $Energy_Blast, $Lightning_Hammer, $Lightning_Hammer_PvP, _
;~ 		$Immolate, $Obsidian_Flame, $Obsidian_Flame_PvP, $Enervating_Charge, $Ebon_Hawk, _
;~ 		$Lightning_Orb, $Flare, $Stone_Daggers, $Caretakers_Charge, $Renewing_Surge, _
;~ 		$Wielders_Strike, $Channeled_Strike, $Doom, $Seeping_Wound, $Hidden_Caltrops, _
;~ 		$Shadow_Prison, $Shadow_Shroud, $Assassins_Promise, $Siphon_Strength, _
;~ 		$Mark_of_Insecurity, $Wastrels_Collapse, $Shadow_Theft, $Beguiling_Haze, _
;~ 		$Augury_of_Death, $Scorpion_Wire, $Dancing_Daggers, $Shadow_Fang, _
;~ 		$Expose_Defenses, $Shadowy_Burden, $Mark_of_Death, $Enduring_Toxin, _
;~ 		$Shameful_Fear, $Mirrored_Stance, $Mark_of_Instability, $Dark_Prison
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_Best_Target
;~ Func SpellBT($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Ray_of_Judgment, $Lingering_Curse, $Spiteful_Spirit, $Icy_Veins, _
;~ 		$Life_Transfer, $Ravenous_Gaze, $Feast_of_Corruption, $Putrid_Bile, _
;~ 		$Rising_Bile, $Mark_of_Pain, $Shadow_of_Fear, $Blood_Bond, _
;~ 		$Reckless_Haste, $Meekness, $Suffering, $Weaken_Armor, $Deathly_Swarm, _
;~ 		$Rotting_Flesh, $Poisoned_Heart, $Enfeebling_Blood, $Enfeebling_Blood_PvP, _
;~ 		$Vampiric_Swarm, $Migraine, $Migraine__PvP, $Ineptitude, $Fevered_Dreams, _
;~ 		$Fevered_Dreams_PvP, $Stolen_Speed, $Stolen_Speed_PvP, $Visions_of_Regret, _
;~ 		$Visions_of_Regret_PvP, $Panic, $Shared_Burden, $Shared_Burden_PvP, $Energy_Surge, _
;~ 		$Wastrels_Worry, $Wastrels_Demise, $Ether_Nightmare_Luxons, $Ether_Nightmare_Kurzicks, _
;~ 		$Chaos_Storm, $Lightning_Surge, $Shatterstone, $Savannah_Heat, $Savannah_Heat_PvP, _
;~ 		$Sandstorm, $Unsteady_Ground, $Thunderclap, $Ride_the_Lightning, $Ride_the_Lightning_PvP, _
;~ 		$Invoke_Lightning, $Mind_Burn, $Water_Trident, $Searing_Flames, $Star_Burst, _
;~ 		$Incendiary_Bonds, $Earthen_Shackles, $Chilling_Winds, $Ice_Spikes, $Mark_of_Rodgort, _
;~ 		$Rust, $Freezing_Gust, $Ash_Blast, $Bed_of_Coals, $Fire_Storm, $Arc_Lightning, _
;~ 		$Meteor_Shower, $Meteor, $Liquid_Flame, $Maelstrom, $Shell_Shock, _
;~ 		$Teinais_Wind, $Churning_Earth, $Eruption, $Breath_of_Fire, _
;~ 		$Searing_Heat, $Chain_Lightning, $Icy_Prism, $Rodgorts_Invocation, _
;~ 		$Teinais_Crystals, $Earthquake, $Dragons_Stomp, $Fireball, $Phoenix, _
;~ 		$Lightning_Javelin, $Lava_Arrows, $Clamor_of_Souls, $Dulled_Weapon, _
;~ 		$Lamentation, $Painful_Bond, $Binding_Chains, $Spirit_Rift, $Caltrops
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_me_or_ally_near_enemy
;~ Func SpellMeOrAlly($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Gust, $Stone_Sheath, $Double_Dragon, $Energy_Boon, _
;~ 		$Mirror_of_Ice
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_I'm_near_to_Enemy
;~ Func SpellNear($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Balthazars_Aura, $Zealots_Fire, $Kirins_Wrath, $Symbol_of_Wrath, _
;~ 		$Unholy_Feast, $Unholy_Feast_PvP, $Shockwave, $Grasping_Earth, _
;~ 		$Frozen_Burst, $Lava_Font, $Crystal_Wave, $Flame_Burst, _
;~ 		$Aftershock, $Inferno, $Whirlwind, $Eremites_Zeal
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_ally_Caster
;~ Func SpellAllyCaster($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Blood_is_Power, $Blood_Ritual
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_Physical_Enemy,_derv,_war,_sin,_ranger,_para
;~ Func SpellPhysic($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Defenders_Zeal, $Pacifism, $Scourge_Enchantment, $Blood_of_the_Aggressor, _
;~ 		$Faintheartedness, $Insidious_Parasite, $Cacophony, $Price_of_Failure, _
;~ 		$Vocal_Minority, $Ulcerous_Lungs, $Sum_of_All_Fears, $Clumsiness, _
;~ 		$Wandering_Eye, $Wandering_Eye_PvP, $Images_of_Remorse, $Empathy, _
;~ 		$Empathy_PvP, $Spirit_Shackles, $Imagined_Burden, $Ethereal_Burden, _
;~ 		$Kitahs_Burden, $Spirit_of_Failure, $Soothing_Images, $Calculated_Risk, _
;~ 		$Calculated_Risk_PvP,  $Icy_Shackles, $Glimmering_Mark, $Mind_Freeze, _
;~ 		$Mind_Freeze_PvP, $Blinding_Surge, $Ice_Prison, $Blurred_Vision, _
;~ 		$Deep_Freeze, $Shard_Storm, $Blinding_Flash, $Siphon_Speed
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_Enemy_Caster
;~ Func SpellCaster($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Depravity, $Wither, $Soul_Leech, $Defile_Defenses, _
;~ 		$Malaise, $Mark_of_Subversion, $Rigor_Mortis, $Arcane_Languor, _
;~ 		$Confusing_Images, $Overload, $Price_of_Pride, $Frustration, _
;~ 		$Frustration_PvP, $Mind_Wrack, $Mind_Wrack_PvP, $Diversion, _
;~ 		$Ether_Phantom, $Backfire, $Arcane_Conundrum, $Ether_Lord, _
;~ 		$Energy_Burn, $Energy_Tap, $Gale
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_is_monk_or_rit
;~ Func SpellHealer($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Shame
;~ 	Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_is_elem,_mes,_nec
;~ Func SpellEleMesNec($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Guilt, $Mistrust, $Mistrust_PvP
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_undead_servant
;~ Func SpellUndeadServant($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Jagged_Bones, $Death_Nova
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_Moving
;~ Func SpellMoving($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Crippling_Anguish, $Crippling_Anguish_PvP, $Waste_Not_Want_Not, $Lightning_Bolt, _
;~ 		$Weaken_Knees, $Slippery_Ground, $Crippling_Dagger
;~ 			Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_Dead_body
;~ Func SpellDeadBody($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Animate_Flesh_Golem, $Animate_Bone_Fiend, $Animate_Bone_Horror, $Animate_Shambling_Horror, _
;~ 		$Animate_Vampiric_Horror, $Animate_Bone_Minions, $Putrid_Explosion, $Necrotic_Traversal, _
;~ 		$Consume_Corpse, $Soul_Feast
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_enchanted
;~ Func SpellEnch($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Corrupt_Enchantment, $Pain_of_Disenchantment, $Jaundiced_Gaze, $Defile_Enchantments, _
;~ 		$Desecrate_Enchantments, $Chilblains, $Strip_Enchantment, $Rip_Enchantment, _
;~ 		$Rend_Enchantments, $Envenom_Enchantments, $Gaze_of_Contempt, $Air_of_Disenchantment, _
;~ 		$Shatter_Storm, $Shatter_Enchantment, $Drain_Enchantment, $Inspired_Enchantment, _
;~ 		$Revealed_Enchantment, $Discharge_Enchantment, $Lyssas_Balance, $Mirror_of_Disenchantment, _
;~ 		$Mirror_of_Disenchantment_PvP, $Feedback, $Drain_Delusions, $Assault_Enchantments
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_not_enchanted
;~ Func SpellNotEnch($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Enchanters_Conundrum, $Vapor_Blade
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_has_condition
;~ Func SpellCondi($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Oppressive_Gaze, $Fragility, $Fragility_PvP, $Epidemic, _
;~ 		$Hypochondria
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_has_cracked_armor
;~ Func SpellCrack($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Teinais_Prison, $Shock_Arrow
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_weakned
;~ Func SpellWeak($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Glowstone, $Stoning
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_burning
;~ Func SpellBurn($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Glowing_Gaze, $Steam
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_has_Hex
;~ Func SpellHex($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Vile_Miasma, $Accumulated_Pain, $Accumulated_Pain_PvP, $Shatter_Delusions, _
;~ 		$Shatter_Delusions_PvP, $Glowing_Ice
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_has_hex_AND_enchant
;~ Func SpellHexAndEnch($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Discord
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_has_hex_OR_enchant
;~ Func SpellHexOrEnch($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Toxic_Chill, $Necrosis
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_dont_have_condition
;~ Func SpellNoCondi($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Virulence
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;if_target_have_more_50%_hp
;~ Func SpellMore50HP($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Deathly_Chill, $Lifebane_Strike, $Shadow_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;if_target_have_less_50%_hp
;~ Func SpellLess50HP($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Taste_of_Pain
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;If_target_is_knock_down
;~ Func SpellKnock($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Fetid_Ground
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_target_if_i_have_condition
;~ Func SpellMeCondi($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Plague_Sending
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;On_me_if_if_I_have_spirit_in_earshot
;~ Func SpellMeSpirit($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Spirit_Channeling, $Offering_of_Spirit
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;on_target_if_i_hace_spirit_in_earshot
;~ Func SpellSpirit($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Essence_Strike, $Gaze_from_Beyond, $Spirit_Burn, $Spirit_Boon_Strike
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc

;~ ;Rupt
;~ Func SpellRupt($aSkill)
;~ 	Switch DllStructGetData($Skill, 'ID')
;~ 	Case $Power_Leech, $Power_Flux, $Power_Block, $Tease, $Psychic_Distraction, _
;~ 		$Simple_Thievery, $Psychic_Instability, $Psychic_Instability_PvP, $Persistence_of_Memory, _
;~ 		$Web_of_Disruption, $Web_of_Disruption_PvP, $Leech_Signet, $Cry_of_Pain, _
;~ 		$Cry_of_Frustration, $Complicate, $Power_Leak, $Power_Spike, $Power_Lock, _
;~ 		$Power_Return, $Power_Drain, $Disrupting_Dagger
;~ 		Return True
;~ 	Case Else
;~ 		Return False
;~ 	EndSwitch
;~ EndFunc
;~ #EndRegion Spell
;~ #Endregion Add by Alusion
; ===== EXTRACTED FROM logic.au3 FOR INTERRUPT PATH =====

; ===== CLEAN EXTRACTED CORE FROM logic.au3 =====

Func GetSkillPtr($aSkillID)
	Local $Skillptr = $mSkillBase + 160 * $aSkillID
	Return Ptr($Skillptr)
EndFunc

Func IsRecharged($aSkillSlot, $aHeroNumber = 0, $aSkillbarPtr = 0)
	; Simplified: rely on GwAu3 Skill_IsRecharged when possible
	Return Skill_GetSkillbarInfo($aSkillSlot, "IsRecharged")
EndFunc

Func GetIsKnocked($aAgent = -2)
	Return Agent_GetAgentInfo($aAgent, "Knocked")
EndFunc

Func GetEnergy($aAgent = -2)
	Return Agent_GetAgentInfo($aAgent, "CurrentEnergy")
EndFunc

Func GetHP($aAgent = -2)
	Return Agent_GetAgentInfo($aAgent, "HP")
EndFunc

Func GetAgentPtr($aAgent = -2)
	Return Agent_GetAgentPtr($aAgent)
EndFunc

Func GetPing()
	Return 50 ; placeholder; replace with real ping if needed
EndFunc

Func CancelAction()
	Agent_CancelAction()
EndFunc


; ===== COMPATIBILITY BLOCK (Logic functions with no GwAu3 equivalent) =====

Func GetAttributeByID($aAttributeID, $aHero = False)
    ; Thin wrapper – adjust the second arg if your GwAu3 build differs
    If $aHero Then
        Return Attribute_GetPartyAttributeInfo($aAttributeID, 0, "Level")
    Else
        Return Attribute_GetAttributeInfo($aAttributeID, "Level")
    EndIf
EndFunc


; ===== GetSkillByID wrapper (returns DllStruct for existing call sites) =====
Func GetSkillByID($aSkillID)
	Local $p = Skill_GetSkillPtr($aSkillID)
	If Not IsPtr($p) Then Return 0
	Local $s = DllStructCreate("long ID; long Type; dword Adrenaline")
	DllStructSetData($s, "ID", Memory_Read($p, "long"))
	DllStructSetData($s, "Type", Memory_Read($p + 12, "long"))
	DllStructSetData($s, "Adrenaline", Memory_Read($p + 56, "dword"))
	Return $s
EndFunc


Func Skill_HasEffect($aSkillID)
    Local $pEffects = World_GetWorldInfo("AgentEffectsArray")
    Local $iSize = World_GetWorldInfo("AgentEffectsArraySize")
    If $pEffects = 0 Or $iSize = 0 Then Return False
    Local $lMyID = Agent_GetMyID()
    For $i = 0 To $iSize - 1
        Local $lAgentID = Memory_Read($pEffects + $i * 0x24, "long")
        If $lAgentID = $lMyID Then
            Local $lEffectPtr = Memory_Read($pEffects + $i * 0x24 + 0x14, "ptr")
            Local $lEffectCount = Memory_Read($pEffects + $i * 0x24 + 0x1C, "long")
            If $lEffectPtr = 0 Or $lEffectCount = 0 Then Return False
            For $j = 0 To $lEffectCount - 1
                Local $lSkillID = Memory_Read($lEffectPtr + $j * 0x18, "long")
                If $lSkillID = $aSkillID Then Return True
            Next
        EndIf
    Next
    Return False
EndFunc

; Untested, we can test effets on self with Skill_HasEffect, need to see if this follows the same offsets for heroes as in logic
Func Skill_GetSkillEffectPtr($aSkillID, $aHeroID = 0)
    Local $pEffects = World_GetWorldInfo("AgentEffectsArray")
    Local $iSize = World_GetWorldInfo("AgentEffectsArraySize")
    If $pEffects = 0 Or $iSize = 0 Then Return 0
    If $aHeroID = 0 Then $aHeroID = Agent_GetMyID()
    For $i = 0 To $iSize - 1
        Local $lAgentID = Memory_Read($pEffects + $i * 0x24, "long")
        If $lAgentID = $aHeroID Then
            Local $lEffectPtr = Memory_Read($pEffects + $i * 0x24 + 0x14, "ptr")
            Local $lEffectCount = Memory_Read($pEffects + $i * 0x24 + 0x1C, "long")
            If $lEffectPtr = 0 Or $lEffectCount = 0 Then Return 0
            For $j = 0 To $lEffectCount - 1
                Local $lSkillID = Memory_Read($lEffectPtr + $j * 0x18, "long")
                If $lSkillID = $aSkillID Then Return Ptr($lEffectPtr + $j * 0x18)
            Next
        EndIf
    Next
    Return 0
EndFunc

