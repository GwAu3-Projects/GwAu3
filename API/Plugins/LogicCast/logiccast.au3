#Region Cast Functions
Global Enum $all = 0, $ptr, $energyreq, $adrereq, $type, $activation, $aftercast, $target, $hexes, $pressure, $bind, $speedBoost, $survive, $attackskill, $heal, $prot, $bond, $condremove, $hexremove, $enchantremove, $rupt, $hardrupt, $precast, $echochantshout, $junundu, $rezz
Global $SkillBarCache[9][26]
Global $Skillbar[8] = [1, 2, 3, 4, 5, 6, 7, 8]
Global $RuptSlots[9]
Global $ProtSlots[9]
Global $HeroPrecast[100][3]
Global $HeroProts[0][3]		; [skillID, hero#, slot] — same IsProtectiveSkill filter as $ProtSlots
Global $BiP[3] = [0, 0, 0]
Global $SkillbarSlot[3500]	; used to store the skillslot of skill ID's present in the skill bar
Global $aSkillRange
Global $Summon_Spirits
Global $PressureSpiritSkills = 0
; Our cast clock: slot + start time. Durations from $SkillBarCache (FC on activation only).
; OnSpell / RuptEX both use these — must live here (bots must not rely on declaring them).
Global $MySkillSlot = 0			; bar slot of the skill we last started (0 = none)
Global $MyTargetID = 0			; target at cast start (cancel / context)
Global $MySkillID = 0			; skill ID we last started
Global $MyActivation = 0		; our activation ms (aftercast gate in OnSpell)
Global $MyAftercast = 0			; our aftercast ms
Global $AftercastTimer = 0
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
; $aLastCast / agent-poll cast watch â†’ see logiccast_AgentCastWatch_archived.au3
Global $BestTarget = 0		; set by CanAttack / GetBestTargetBySkillSlot; used by Fight / UseSkills
Global $aCalledTarget = 0		; last party-called target ID (Logic Attack: call once per target)

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

		; BASE activation/aftercast (ms). FC applied live in GetSkillActivationMs; aftercast is never FC-reduced (wiki).
		$SkillBarCache[$i][$activation] = Skill_GetSkillInfo($SkillBarCache[$i][$ptr], "Activation") * 1000
		$SkillBarCache[$i][$aftercast] = Skill_GetSkillInfo($SkillBarCache[$i][$ptr], "Aftercast") * 750
		If $SkillBarCache[$i][$type] = $Attack Then $SkillBarCache[$i][$activation] *= 0.5


		; recoding of target = 1 into the appropriate target categories
		If $SkillBarCache[$i][$target] = 1 Then
			Switch $SkillBarCache[$i][$all]
				Case $Summon_Spirits_Kurzick, $Summon_Spirits_Luxon, $Air_of_Superiority, $Summon_Mursaat, $Summon_Ruby_Djinn, $Summon_Ice_Imp, $Summon_Naga_Shaman
					$SkillBarCache[$i][$target] = 0 ; self
				Case $Gust, $Double_Dragon, $Stone_Sheath
					$SkillBarCache[$i][$target] = 3 ;ally
				Case $Heart_of_Shadow, $Vipers_Defense, $Ride_the_Lightning, $Mirror_of_Ice, $Charm_Animal, $Wandering_Eye, $Clumsiness, $Ineptitude, $Signet_of_Clumsiness, _
					$Signet_of_Clumsiness_PvP, $Empathy, $Insidious_Parasite, $Accumulated_Pain, $Arcane_Conundrum, $Panic, $Panic_PvP, $Overload, $Mistrust, $Mistrust_PvP, _
					$Shame, $Mark_of_Subversion, $Guilt, $Diversion, $Backfire, $Visions_of_Regret, $Visions_of_Regret_PvP
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
		If IsHexRemoveSkill($aSkillID) Then
			$SkillBarCache[$i][$hexremove] = $aSkillID
			$RuptEventSystem = True
		EndIf
		If IsEnchantRemoveSkill($aSkillID) Then $SkillBarCache[$i][$enchantremove] = $aSkillID
		If IsRuptSkill($aSkillID) Then
			$RuptSlots[0] += 1
			$RuptSlots[$RuptSlots[0]] = $i
			$SkillBarCache[$i][$rupt] = $aSkillID
		EndIf
		If $i = 8 Then
			ReDim $RuptSlots[$RuptSlots[0]+1]
			If $RuptSlots[0] > 0 Then
				Out("Rupts detected â€” SkillLog responders OnSpell / OnMelee")
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
				Out("Prot detected â€” SkillLog responders OnSpell / OnMelee")
				$ProtEventSystem = True
			EndIf
		EndIf
	Next
	If $SkillbarSlot[$Signet_Of_Spirits] > 0 Then $PressureSpiritSkills += 2    ; add 2 spirits for Signet of Spirits
	Out($PressureSpiritSkills & " pressure sprits on your skillbar")
	$Summon_Spirits = $SkillbarSlot[$Summon_Spirits_Luxon] + $SkillbarSlot[$Summon_Spirits_Kurzick]
	Out("Mapping your skill bar - completed")
	OutSkillBarSummary()
	Debug_ShowHardRuptColumn()

	; Arm SkillLog once at cache time. Fight / bots only toggle live.
	If $RuptEventSystem Or $ProtEventSystem Then
		If SkillLog_Respond("OnSpell", "OnMelee") Then
			SkillLog_SetLive(False)
		Else
			Out("SkillLog Respond arm failed â€” check SkillLog_DumpScan")
		EndIf
	EndIf

	Return True
EndFunc   ;==>CacheSkillBar


Func Debug_ShowHardRuptColumn()
	If Not IsArray($SkillBarCache) Or UBound($SkillBarCache, 0) < 2 Then
		Out("[HardRuptDebug] $SkillBarCache is not initialized")
		Return
	EndIf

	Local $iMaxSlot = UBound($SkillBarCache, 1) - 1
	If $iMaxSlot > 8 Then $iMaxSlot = 8

	Out("[HardRuptDebug] Showing $hardrupt (col " & $hardrupt & ") vs $rupt (col " & $rupt & "):")
	For $i = 1 To $iMaxSlot
		Local $iSkillID = Number($SkillBarCache[$i][$all])
		Local $vRupt = $SkillBarCache[$i][$rupt]
		Local $vHardRupt = $SkillBarCache[$i][$hardrupt]
		Local $sName = Skill_NameFromID($iSkillID)
		Out(StringFormat("[Slot %d] SkillID=%d (%s) | $rupt=%s | $hardrupt=%s (IsRuptSkill(True)=%s)", _
			$i, _
			$iSkillID, _
			$sName, _
			String($vRupt), _
			String($vHardRupt), _
			String(IsRuptSkill($iSkillID, True))))
	Next
EndFunc   ;==>Debug_ShowHardRuptColumn


; Cast detect is SkillLog (OnSpell / OnMelee / RuptEX). Do not add EnemySkillWatch or Listen back.
; $aMaxDistanceToXY: default 5000 = no leash; tighter values checked inside UseSkills.

Func Fight($x = X(-2), $y = Y(-2), $aAggroRange = 1320, $careful = False, $aMaxDistanceToXY = 5000, $aAgent = 0)
; REVIEW: GwAu3 equivalent is UAI_Fight(). Call this one when you want the Logic interrupt path.
	If Agent_NoEnemiesAround($aAggroRange) Then
		Agent_CancelAction()
		Return
	EndIf
	Out("Fighting enemies")
	Local $TimerToGetOut = TimerInit()
	; CacheSkillBar already SkillLog_Respond(OnSpell/OnMelee). Live on while fighting.
	If $RuptEventSystem Or $ProtEventSystem Then SkillLog_SetLive(True)
	Do
		If Bot_HaltIfStopped() Then ExitLoop
		; Dead must leave Fight immediately — otherwise CanAttack FAIL + Precast spam while
		; AggroMoveToEX never exits, and after shrine rez $i stays on incubi/Thorn/Gokir.
		If Agent_GetAgentInfo(-2, "IsDead") Or Wipe() Then
			$g_b_DiedOnWaypoint = True
			Agent_CancelAction()
			$BestTarget = 0
			$aCalledTarget = 0
			ExitLoop
		EndIf
		If Agent_NoEnemiesAround($aAggroRange) Then
			Agent_CancelAction()
			$BestTarget = 0
			ExitLoop
		EndIf

		Local $lCan = CanAttack($aAggroRange)
		If $lCan Then
			; Select nearest once when target changes (not party CallTarget spam).
			If $aCalledTarget <> Agent_ConvertID($BestTarget) Then
				Agent_ChangeTarget($BestTarget)
				$aCalledTarget = Agent_ConvertID($BestTarget)
			EndIf
			Agent_Attack($BestTarget, False)
		Else
			; Logic: no CancelAction here. Canceling every CanAttack-fail tick aborts HR
			; (torch/bundle → FAIL → CancelAction → UseSkills starts HR → next tick cancels it).
			$BestTarget = 0
			$aCalledTarget = 0
		EndIf
		; Precast 2nd arg is precastspirits (bool). Skip wards/spirits mid-fight —
		; CarefulAggro/Pull already precast; calling them every tick abort@2500-spammed.
		Precast($aAggroRange, False)
		; Do not CancelAll + Map_Move onto the foe when $careful — that walks spears/paras
		; into adjacent and cancels Attack's weapon-range pathing. CarefulAggro handles
		; ApplyHR / hero flags; Attack keeps martial range. $careful reserved for callers.
		#forceref $careful
		; Bar pass; UseSkills already drains Listen between slots.
		UseSkills($x, $y, $aAggroRange, $all, $aMaxDistanceToXY, $aAgent)
	Until Agent_NoEnemiesAround($aAggroRange) Or TimerDiff($TimerToGetOut) > 240000 Or Agent_GetAgentInfo(-2, "IsDead") Or Wipe()
	If Agent_GetAgentInfo(-2, "IsDead") Or Wipe() Then $g_b_DiedOnWaypoint = True
	Agent_CancelAction()
	$BestTarget = 0
	$aCalledTarget = 0
	; Keep detours; ignore SkillLog activates until next Fight.
	If $RuptEventSystem Or $ProtEventSystem Then SkillLog_SetLive(False)
EndFunc   ;==>Fight

; OnSpell / OnMelee are the SkillLog_Respond handlers (bodies below).
; Agent-poll cast watch archived: logiccast_AgentCastWatch_archived.au3

;~ $skilltype filters the bar pass. $all skips rupt / enchantremove / hexremove (SkillLog owns those).
; $aMaxDistanceToXY = 5000 (default) disables the leash; any other value is checked once after a full bar pass.
Func UseSkills($x, $y, $aAggroRange = 1320, $skilltype = $all, $aMaxDistanceToXY = 5000, $aAgent = 0)
	If Agent_GetAgentInfo(-2, "IsDead") Or Map_GetInstanceInfo("Type") == 2 Then Return False
	If $BestTarget <> 0 And Agent_GetAgentInfo($BestTarget, "Allegiance") = 3 And Agent_GetAgentInfo($BestTarget, "IsDead") Then $BestTarget = 0
	If Agent_NoEnemiesAround($aAggroRange) Then Return False

	For $aSkillSlot In $Skillbar
		If Agent_GetAgentInfo(-2, "IsDead") Or Map_GetInstanceInfo("Type") == 2 Then Return False
		If Agent_NoEnemiesAround($aAggroRange) Then Return False

		; $all skips rupt / strip columns. SkillLog (RuptEX / OnSpell) owns those.
		If $skilltype = $all Then
			If Agent_GetAgentInfo(-2, "IsDead") Then Return False
			If $BestTarget <> 0 And Agent_GetAgentInfo($BestTarget, "Allegiance") = 3 And Agent_GetAgentInfo($BestTarget, "IsDead") Then $BestTarget = 0
			If $SkillBarCache[$aSkillSlot][$rupt] <> "" Then ContinueLoop
			If $SkillBarCache[$aSkillSlot][$enchantremove] <> "" Then ContinueLoop
			If $SkillBarCache[$aSkillSlot][$hexremove] <> "" Then ContinueLoop
		EndIf

		If ShouldUse($aSkillSlot, $aAggroRange, $skilltype) Then Skill_TryUseSkill($aSkillSlot, $BestTarget, False, 0)
	Next

	If $aAgent <> 0 Then
		If Agent_GetDistance($aAgent) > $aMaxDistanceToXY Then Return False
	ElseIf $aMaxDistanceToXY <> 5000 Then
		If Agent_GetDistanceToXY($x, $y) > $aMaxDistanceToXY Then Return False
	EndIf
	Return True
EndFunc   ;==>UseSkills

; Quiet interrupt line: "I interrupted Foo's Overload in 42ms"
Func LogMyInterrupt($aCasterID, $aEnemySkillID, $aSuccess, $aElapsedMs)
	Local $sName = Agent_GetAgentInfo($aCasterID, "Name")
	If Not IsString($sName) Or $sName = "" Then $sName = "#" & Agent_ConvertID($aCasterID)
	Local $sSkill = Skill_NameFromID($aEnemySkillID)
	If Not IsString($sSkill) Or $sSkill = "" Then $sSkill = "#" & Number($aEnemySkillID)
	Local $iMs = Floor($aElapsedMs)
	If $aSuccess Then
		Out("Interrupted " & $sName & "'s " & $sSkill & " in " & $iMs & "ms")
	Else
		Out("Failed to interrupt " & $sName & "'s " & $sSkill & " in " & $iMs & "ms")
	EndIf
EndFunc   ;==>LogMyInterrupt

; Fire path after ShouldUse (policy + CanUse already done). No second CanUse here.
; $MyActivation is for OnSpell/rupt timing — not armed here (Logic TryUseSkill same).
; $aTimeout <= 0 returns after send.
Func Skill_TryUseSkill($aSkillSlot, $aTarget = -2, $aCallTarget = False, $aTimeout = 10000)
	If $aSkillSlot < 1 Or $aSkillSlot > 8 Then Return False
	Local $lAgentID = Agent_ConvertID($aTarget)
	If $lAgentID = 0 Or Agent_GetAgentInfo(-2, "IsDead") Then Return False
	If Not Skill_UseSkill($aSkillSlot, $lAgentID, $aCallTarget) Then Return False
	$AftercastTimer = TimerInit()
	$MyActivation = GetAdjustedActivation($SkillBarCache[$aSkillSlot][$all], -2, $aTarget) ; accounts for fast casting and (when target is passed through) projectile travel time.
	If $aTimeout <= 0 Then Return True
	Return True
EndFunc   ;==>Skill_TryUseSkill

; Light fire for OnSpell / OnMelee interrupts — Diversion/Backfire/VoR/… via CanUseRuptEffects
; (no busy/aftercast; GetBestRupt already checked recharge/energy).
Func Skill_TryRuptSkill($aSkillSlot, $aTarget = -2, $aCallTarget = False, $aTimeout = 10000)
	If $aSkillSlot < 1 Or $aSkillSlot > 8 Then Return False
	If Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "IsKnocked") Then Return False
	If Not CanUseRuptEffects($aSkillSlot) Then Return False
	Return Skill_TryUseSkill($aSkillSlot, $aTarget, $aCallTarget, $aTimeout)
EndFunc   ;==>Skill_TryRuptSkill

Func GetRemainingAftercastMs()
	If Not IsDeclared("AftercastTimer") Or $AftercastTimer = 0 Then Return 0
	If Not IsDeclared("$MyActivation") Or $MyActivation <= 0 Then Return 0

	Local $lElapsed = TimerDiff($AftercastTimer)
	If $lElapsed >= $MyActivation Then Return 0

	Return $MyActivation - $lElapsed
EndFunc   ;==>GetRemainingAftercastMs

Func GetAdjustedActivation($aSkillID, $aCasterID = -2, $aTargetID = -1)
	Local $lActivation = $GC_AMX2_SKILL_DATA[$aSkillID][$GC_F_SKILL_ACTIVATION_TIME] * 1000
	Local $lSkillType = Skill_GetSkillInfo($aSkillID, "SkillType")
	Local $lWeaponType = Agent_GetAgentInfo($aCasterID, "WeaponType")

	Switch $lSkillType

		Case $Spell, $Hex
			If Agent_GetAgentInfo($aCasterID, "Primary") = $Mesmer Then Return $lActivation * (0.5 ^ (GetAttributeByID($Fast_Casting, True) / 15))
		Case $Signet
			If Agent_GetAgentInfo($aCasterID, "Primary") = $Mesmer Then Return $lActivation * (1 - 0.03 * GetAttributeByID($Fast_Casting, True))
		Case $Attack
			Local $iDist = Agent_GetDistance($aCasterID, $aTargetID)
			Local $lAttackSpeedModifier = Agent_GetAgentInfo($aCasterID, "AttackSpeedModifier")
			If $lAttackSpeedModifier <= 0 Then $lAttackSpeedModifier = 1.0
			Switch $lWeaponType
				Case $Bow
					If $lActivation > 0 Then Return 750 * $lAttackSpeedModifier + $iDist * 0.42
				Case $Spear
					If $lActivation > 0 Then Return 500 * $lAttackSpeedModifier + $iDist * 0.6
				Case Else
					If $lActivation > 0 Then Return 500 * $lAttackSpeedModifier
		EndSwitch
	EndSwitch
	Return $lActivation

EndFunc   ;==>GetAdjustedActivation

; SkillLog_Respond caster handler. Return: 0 = ignore/handled, 1 = reaction used.
; Cast detect = SkillLog.
; $aCastStart = TimerInit() from when we first saw this cast (for remaining-time math).
Func OnSpell($aCasterID, $aTargetID, $aSkillID, $aActivation, $aCastStart = 0, $aAggroRange = 1320)
	#forceref $aActivation
	$RuptTimer = TimerInit()
	If $aCastStart = 0 Then $aCastStart = $RuptTimer
	If Map_GetInstanceInfo("Type") <> $GC_I_MAP_TYPE_EXPLORABLE Or Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "IsKnocked") Then Return 0

	Local $lMyID = Agent_GetMyID()

	; Self cast — do not react to our own spell start here.
	If Number($aCasterID) = Number($lMyID) Then Return 0

	; Spirit attacks (Bloodsong, Agony, …) are not casts worth reacting to.
	; The ritualist's binding ritual is a different agent and still goes through.
	If Agent_IsSpiritAgent($aCasterID) Then Return 0

	; Cancel our cast if a hard rupt is coming at us (before busy gate).
	If IsHardRuptSkill($aSkillID) And Number($aTargetID) = Number($lMyID) Then
		Out($aCasterID & " is interrupting my " & Skill_NameFromID(OurSkillID()))
		Local $lEnemyActivation = GetAdjustedActivation($aSkillID, $aCasterID, $aTargetID)
		If $lEnemyActivation <= 0 Then $lEnemyActivation = 500
		Local $lElapsedSinceLast = ($g_hAftercastTimer <> 0) ? TimerDiff($g_hAftercastTimer) : 999999
		If $lEnemyActivation > $lElapsedSinceLast Then Return 0
		If $g_iLastSkillLockMs > 250 Or OurSkillActivationMs() > 250 Then CancelAction()
		Return 0
	EndIf

	If Agent_GetAgentInfo(-2, "IsCasting") Then Return 0

	; Rupt / strip / hex — factor remaining aftercast into timing rather than blocking early.
	If $RuptEventSystem And Agent_GetAgentInfo($aCasterID, "Allegiance") = 3 Then
		Local $lTargetAllegiance = ($aTargetID <> 0) ? Agent_GetAgentInfo($aTargetID, "Allegiance") : 0

		; Caster has Shame or Mark of Subversion and is casting on themselves or their ally ($aTargetID = 0 or Allegiance 3)
		If ($aTargetID = 0 Or $lTargetAllegiance = 3) _
				And (Skill_HasEffect($aCasterID, $Shame) Or Skill_HasEffect($aCasterID, $Mark_of_Subversion)) Then Return 0

		; Caster has Mistrust or Guilt and is casting on MY ally (Allegiance 1 or self)
		If $aTargetID <> 0 And ($lTargetAllegiance = 1 Or Number($aTargetID) = Number($lMyID)) _
				And (Skill_HasEffect($aCasterID, $Mistrust) Or Skill_HasEffect($aCasterID, $Mistrust_PvP) Or Skill_HasEffect($aCasterID, $Guilt)) Then Return 0

		Local $lRuptSlot = GetBestRupt($aSkillID, $aCasterID, $aAggroRange)
		If $lRuptSlot > 0 And Agent_GetDistance($aCasterID) < 1200 Then
			Local $lEnemyActivation = GetAdjustedActivation($aSkillID, $aCasterID, $aTargetID)
			Local $lMyActivation = GetAdjustedActivation($SkillBarCache[$lRuptSlot][$all], -2, $aCasterID)
			Local $lPing = GetPing()
			Local $lRemainingAftercast = GetRemainingAftercastMs()
			Local $lEffectiveMyTime = $lRemainingAftercast + $lMyActivation + $lPing

			If $lEnemyActivation > $lEffectiveMyTime Then
				Local $lOk = False
				If $lEnemyActivation <= 250 Then
					$lOk = Skill_TryRuptSkill($lRuptSlot, $aCasterID, False, 0)
				Else
					Local $lSleep = ($lEnemyActivation * 0.5) - $lEffectiveMyTime - Random(0, 150)
					If $lSleep > 0 Then Sleep($lSleep)
					$lOk = Skill_TryRuptSkill($lRuptSlot, $aCasterID, False)
				EndIf
				LogMyInterrupt($aCasterID, $aSkillID, $lOk, TimerDiff($aCastStart))
				If $lOk Then Return 1
			EndIf
		EndIf

		; Enchant removal — only when we see an enchantment being cast
		If IsEnchantmentSkill($aSkillID) Or Skill_GetSkillInfo($aSkillID, "SkillType") = $Enchantment Then
			For $i = 1 To 8
				If $SkillBarCache[$i][$enchantremove] = "" Then ContinueLoop
				If Not Skill_GetSkillbarInfo($i, "IsRecharged") Then ContinueLoop
				If $SkillBarCache[$i][$energyreq] > Agent_GetAgentInfo(-2, "CurrentEnergy") Then ContinueLoop
				If Not CanUseRuptEffects($i) Then ContinueLoop

				Local $lStripTarget = 0
				; Self/ally enchants -> strip the caster; else caster if already enchanted, else balled.
				If SkillTargetsSelfOrAlly($aSkillID) And Agent_GetAgentInfo($aCasterID, "IsEnchanted") Then
					$lStripTarget = $aCasterID
				Else
					$lStripTarget = Agent_GetBalledEnchantedEnemy($aAggroRange)
				EndIf
				If $lStripTarget = 0 Or Agent_GetDistance($lStripTarget) > $aAggroRange Then ContinueLoop
				; Shatter needs an enchanted target — fresh self-enchant at cast start is not ready yet.
				If Not Agent_GetAgentInfo($lStripTarget, "IsEnchanted") Then ContinueLoop
				If Skill_TryUseSkill($i, $lStripTarget, False, 0) Then Return 1
			Next
		EndIf

		; Hex removal — only when we see a hex being cast
		If IsHexSpell($aSkillID) Then
			For $i = 1 To 8
				If $SkillBarCache[$i][$hexremove] = "" Then ContinueLoop
				If Not Skill_GetSkillbarInfo($i, "IsRecharged") Then ContinueLoop
				If $SkillBarCache[$i][$energyreq] > Agent_GetAgentInfo(-2, "CurrentEnergy") Then ContinueLoop
				If Not CanUseRuptEffects($i) Then ContinueLoop

				Local $lHexTarget = 0
				; Prefer cast target if it is an ally; else most-hexed ally in range.
				If $aTargetID <> 0 And Agent_GetAgentInfo($aTargetID, "Allegiance") = 1 And Not Agent_GetAgentInfo($aTargetID, "IsDead") Then
					$lHexTarget = $aTargetID
				Else
					$lHexTarget = Agent_GetMostHexedAlly($aAggroRange)
				EndIf
				If $lHexTarget = 0 Then ContinueLoop

				If Skill_TryUseSkill($i, $lHexTarget, False, 0) Then Return 1
			Next
		EndIf
	EndIf

	; Prot skills
	If $ProtSlots[0] > 0 Then
		If Agent_GetAgentInfo($aCasterID, "Allegiance") <> 3 Or Agent_GetDistance($aTargetID) > 1250 Then Return 0
		Local $lProtSlot = GetProtSlot($aSkillID, $aCasterID, $aTargetID)
		If $lProtSlot > 0 And CanUseRuptEffects($lProtSlot) Then
			If Skill_TryUseSkill($lProtSlot, $aTargetID, False, 0) Then Return 1
		EndIf
	EndIf

;~ ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		Move to Avoid AoE	<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	;~ Area Range
	If IsAoESkill($aSkillID) = 1 Then
		If $aTargetID <> Agent_GetMyID() Then
			$AOEDangerXYLocation = XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 362 Then ;312 + 50
				Out("Ally: " & $aTargetID & " is the area AoE Target of " & $aCasterID & ", move !")
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 362)
			EndIf
			Return
		EndIf
	EndIf

	;~ Area Nearby
	If IsAoESkill($aSkillID) = 2 Then
		If $aTargetID <> Agent_GetMyID() Then
			$AOEDangerXYLocation = XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 290 Then ;240 + 50
				Out("Ally: " & $aTargetID & " is the nearby AoE Target of " & $aCasterID & ", move !")
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 290)
			EndIf
			Return
		EndIf
	EndIf

	;~ Area Adjacent
	If IsAoESkill($aSkillID) = 3 Then
		If $aTargetID <> Agent_GetMyID() Then
			$AOEDangerXYLocation = XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 256 Then ;156 + 50
				Out("Ally: " & $aTargetID & " is the nearby AoE Target of " & $aCasterID & ", move !")
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 256)
			EndIf
			Return
		EndIf
	EndIf

	;~ Static Area
	If IsAoESkill($aSkillID) = 4 Then
		If $aTargetID = Agent_GetMyID() Then
			$AOEDangerXYLocation = XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 290 Then ;240 + 50
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 290)
			EndIf
		Else
			$AOEDangerXYLocation = XY($aTargetID)
			$DistanceToAOEZone = Agent_GetDistance($aTargetID)
			If $DistanceToAOEZone <= 290 Then ;240 + 50
				Out("Ally: " & $aTargetID & " is the Static AoE Target of " & $aCasterID & ", move !")
				MoveToSafeSpot($AOEDangerXYLocation[0], $AOEDangerXYLocation[1], 290)
			EndIf
		EndIf
		Return
	EndIf

;~ ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		Cancel, switch defensive set, stop moving		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	;~ Cancel casting to avoid damage
	If (IsAnnoyingSkill($aSkillID) = 1 And $aTargetID = Agent_GetMyID()) Or (IsAnnoyingSkill($aSkillID) = 2 And $aTargetID = Agent_GetMyID()) Then
		Out($aCasterID & " Hurt me " & Skill_NameFromID(OurSkillID()))
		If $g_hAftercastTimer <> 0 And TimerDiff($g_hAftercastTimer) > OurSkillActivationMs() Then Return
		If OurSkillActivationMs() > 250 Then DoubleCancel()
		Return
	EndIf

	;~ Cancel Skill to avoid Melee rupt
	If IsAnnoyingSkill($aSkillID) = 9 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " Hurt me " & Skill_NameFromID(OurSkillID()))
		If $g_hAftercastTimer <> 0 And TimerDiff($g_hAftercastTimer) > OurSkillActivationMs() Then Return
		If OurSkillActivationMs() > 250 Then DoubleCancel()
		Return
	EndIf

	;~ Cancel Cast If Dazed or use block skill
	If IsAnnoyingSkill($aSkillID) = 7 And $aTargetID = Agent_GetMyID() Then
		If Skill_HasEffect($Dazed) Then
			If UseBlock() Then
				Out("Use Block Skill to avoid Melee and Daze")
			Else
				Out("Can't use block, cancel action")
				If $g_hAftercastTimer = 0 Or TimerDiff($g_hAftercastTimer) <= OurSkillActivationMs() Then
					If OurSkillActivationMs() > 250 Then DoubleCancel()
				EndIf
			EndIf
		EndIf
		Return
	EndIf

	;~ Cancel Attack to avoid damage
	If IsAnnoyingSkill($aSkillID) = 3 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " counter attack me " & Skill_NameFromID(OurSkillID()))
		If Agent_GetAgentInfo(-2, "Attacking") Then DoubleCancel()
		Out("Stop Attacking to avoid Damage")
		Return
	EndIf

	;~ Cancel Moving cause melee try to KD me
	If IsAnnoyingSkill($aSkillID) = 4 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " KD me " & Skill_NameFromID(OurSkillID()))
		If Agent_GetAgentInfo(-2, "Moving") Then DoubleCancel()
		Out("Stop Moving to avoid KD")
		Return
	EndIf

	;~ Cancel Action to use Block and Balance skill and defensif set
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

	;~ Cancel Action to use Balance skill and defensif set
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

	;~ UseBlock or Defsenive set if melee pressure is on me
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

	;~ Cancel Action
	If IsAnnoyingSkill($aSkillID) = 10 And $aTargetID = Agent_GetMyID() Then
		If Agent_GetAgentInfo(-2, "Attacking") Then DoubleCancel()
		Return
	EndIf

EndFunc   ;==>OnSpell

; SkillLog_Respond melee handler.
Func OnMelee($aCasterID, $aTargetID, $aSkillID, $aActivation, $aCastStart = 0, $aAggroRange = 1320)
	#forceref $aActivation
	$RuptTimer = TimerInit()
	If $aCastStart = 0 Then $aCastStart = $RuptTimer
	If Map_GetInstanceInfo("Type") <> $GC_I_MAP_TYPE_EXPLORABLE Or Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "IsKnocked") Then Return 0

	Local $lMyID = Agent_GetMyID()

	If Number($aCasterID) = Number($lMyID) Then Return 0
	If Agent_IsSpiritAgent($aCasterID) Then Return 0

	If $RuptEventSystem And Agent_GetAgentInfo($aCasterID, "Allegiance") = 3 Then
		Local $lTargetAllegiance = ($aTargetID <> 0) ? Agent_GetAgentInfo($aTargetID, "Allegiance") : 0

		; Caster has Shame or Mark of Subversion and is casting on themselves or their ally ($aTargetID = 0 or Allegiance 3)
		If ($aTargetID = 0 Or $lTargetAllegiance = 3) _
				And (Skill_HasEffect($aCasterID, $Shame) Or Skill_HasEffect($aCasterID, $Mark_of_Subversion)) Then Return 0

		; Caster has Mistrust or Guilt and is casting on MY ally (Allegiance 1 or self)
		If $aTargetID <> 0 And ($lTargetAllegiance = 1 Or Number($aTargetID) = Number($lMyID)) _
				And (Skill_HasEffect($aCasterID, $Mistrust) Or Skill_HasEffect($aCasterID, $Mistrust_PvP) Or Skill_HasEffect($aCasterID, $Guilt)) Then Return 0

		If Not Agent_GetAgentInfo(-2, "IsCasting") Then
			Local $lRuptSlot = GetBestRupt($aSkillID, $aCasterID, $aAggroRange)
			If $lRuptSlot > 0 Then
				Local $lEnemyActivation = GetAdjustedActivation($aSkillID, $aCasterID, $aTargetID)
				Local $lMyActivation = GetAdjustedActivation($SkillBarCache[$lRuptSlot][$all], -2, $aCasterID)
				Local $lPing = GetPing()
				Local $lRemainingAftercast = GetRemainingAftercastMs()
				Local $lEffectiveMyTime = $lRemainingAftercast + $lMyActivation + $lPing

				If $lEnemyActivation > $lEffectiveMyTime Then
					Local $lOk = False
					If $lEnemyActivation <= 250 Then
						$lOk = Skill_TryRuptSkill($lRuptSlot, $aCasterID, False, 0)
					Else
						Local $lSleep = ($lEnemyActivation * 0.5) - $lEffectiveMyTime - Random(0, 150)
						If $lSleep > 0 Then Sleep($lSleep)
						$lOk = Skill_TryRuptSkill($lRuptSlot, $aCasterID, False)
					EndIf
					LogMyInterrupt($aCasterID, $aSkillID, $lOk, TimerDiff($aCastStart))
					If $lOk Then Return 1
				EndIf
			EndIf
		EndIf
	EndIf

	;~ Cancel casting to avoid interruption
	If IsHardRuptSkill($aSkillID) And Number($aTargetID) = Number($lMyID) Then
		Local $lEnemyActivation = Number(Skill_GetSkillInfo($aSkillID, "Activation")) * 1000
		If $lEnemyActivation <= 0 Then $lEnemyActivation = 500
		If $lEnemyActivation > TimerDiff($AftercastTimer) Then Return
		If $MyActivation > 250 Then CancelAction()
		Return
	EndIf

	If Agent_GetAgentInfo(-2, "IsCasting") Then Return 0
	If Agent_GetAgentInfo($aCasterID, "Allegiance") <> 3 Then Return

	If $ProtSlots[0] > 0 Then
		If Agent_GetAgentInfo($aCasterID, "Allegiance") <> 3 Or Agent_GetDistance($aTargetID) > 1250 Then Return 0
		Local $lProtSlot = GetProtSlot($aSkillID, $aCasterID, $aTargetID)
		If $lProtSlot > 0 And CanUseRuptEffects($lProtSlot) Then
			If Skill_TryUseSkill($lProtSlot, $aTargetID, False, 0) Then Return 1
		EndIf
	EndIf

;~ ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		Cancel, switch defensive set, stop moving		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	;~ Cancel casting to avoid damage
	If (IsAnnoyingSkill($aSkillID) = 1 And $aTargetID = Agent_GetMyID()) Or (IsAnnoyingSkill($aSkillID) = 2 And $aTargetID = Agent_GetMyID()) Then
		Out($aCasterID & " Hurt me " & Skill_NameFromID(OurSkillID()))
		If $g_hAftercastTimer <> 0 And TimerDiff($g_hAftercastTimer) > OurSkillActivationMs() Then Return
		If OurSkillActivationMs() > 250 Then DoubleCancel()
		Return
	EndIf

	;~ Cancel Skill to avoid Melee rupt
	If IsAnnoyingSkill($aSkillID) = 9 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " Hurt me " & Skill_NameFromID(OurSkillID()))
		If $g_hAftercastTimer <> 0 And TimerDiff($g_hAftercastTimer) > OurSkillActivationMs() Then Return
		If OurSkillActivationMs() > 250 Then DoubleCancel()
		Return
	EndIf

	;~ Cancel Cast If Dazed or use block skill
	If IsAnnoyingSkill($aSkillID) = 7 And $aTargetID = Agent_GetMyID() Then
		If Skill_HasEffect($Dazed) Then
			If UseBlock() Then
				Out("Use Block Skill to avoid Melee and Daze")
			Else
				Out("Can't use block, cancel action")
				If $g_hAftercastTimer = 0 Or TimerDiff($g_hAftercastTimer) <= OurSkillActivationMs() Then
					If OurSkillActivationMs() > 250 Then DoubleCancel()
				EndIf
			EndIf
		EndIf
		Return
	EndIf

	;~ Cancel Attack to avoid damage
	If IsAnnoyingSkill($aSkillID) = 3 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " counter attack me " & Skill_NameFromID(OurSkillID()))
		If Agent_GetAgentInfo(-2, "Attacking") Then DoubleCancel()
		Out("Stop Attacking to avoid Damage")
		Return
	EndIf

	;~ Cancel Moving cause melee try to KD me
	If IsAnnoyingSkill($aSkillID) = 4 And $aTargetID = Agent_GetMyID() Then
		Out($aCasterID & " KD me " & Skill_NameFromID(OurSkillID()))
		If Agent_GetAgentInfo(-2, "Moving") Then DoubleCancel()
		Out("Stop Moving to avoid KD")
		Return
	EndIf

	;~ Cancel Action to use Block and Balance skill and defensif set
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

	;~ Cancel Action to use Balance skill and defensif set
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

	;~ UseBlock or Defsenive set if melee pressure is on me
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

	;~ Cancel Action
	If IsAnnoyingSkill($aSkillID) = 10 And $aTargetID = Agent_GetMyID() Then
		If Agent_GetAgentInfo(-2, "Attacking") Then DoubleCancel()
		Return
	EndIf
	Out("OnMelee debug: myID=" & Agent_GetMyID() & " alleg=" & Agent_GetAgentInfo($aCasterID, "Allegiance") & " annoy=" & IsAnnoyingSkill($aSkillID))

EndFunc   ;==>OnMelee

; Pick a ready interrupt slot for this enemy cast. Soft rupts (Power Drain etc.) are valid unless
; the cast RequiresHardRupt (attack skills) or we are hexed with Backfire/Guilt/Mistrust (spell-punish).
; Energy-gain rupts win first when CurrentEnergy < 20 (and still allowed).
Func GetBestRupt($aSkillID, $aCasterID, $aAggroRange = 1320)
	Local $iDist = Agent_GetDistance($aCasterID)
	If $iDist > $aAggroRange Or $iDist = 0 Then Return 0
	; Shame already fails their next ally-targeted spell — don't spend a rupt.
	If Skill_HasEffect($Shame, $aCasterID) Then Return 0

	; Soft spell rupts trigger Backfire / Guilt / Mistrust — only hard rupts then.
	Local $bNeedsHardRupt = RequiresHardRupt($aSkillID) _
			Or Skill_HasEffect($Backfire) _
			Or Skill_HasEffect($Guilt) _
			Or Skill_HasEffect($Mistrust) _
			Or Skill_HasEffect($Mistrust_PvP)
	Local $lEnergy = Agent_GetAgentInfo(-2, "CurrentEnergy")
	Local $lReadySlot = 0
	Local $lOverloadSlot = 0


	For $i = 1 To $RuptSlots[0]
		Local $aSkillSlot = $RuptSlots[$i]
		If Not Skill_GetSkillbarInfo($aSkillSlot, "IsRecharged") Then ContinueLoop

		If $SkillBarCache[$aSkillSlot][$energyreq] > $lEnergy Then ContinueLoop
		; $hardrupt column = IsRuptSkill(id, True) at CacheSkillBar.
		If $bNeedsHardRupt And $SkillBarCache[$aSkillSlot][$hardrupt] = "" Then ContinueLoop

		; Signet of Disruption interrupts spells either way. A non-spell only lands if that foe is hexed.
		If Number($SkillBarCache[$aSkillSlot][$all]) = $Signet_of_Disruption Then
			If RequiresHardRupt($aSkillID) And Not Agent_GetAgentInfo($aCasterID, "IsHexed") Then ContinueLoop
		EndIf
		Out("Skillbarslot hardrupt ID1: " & $SkillBarCache[$aSkillSlot][$hardrupt])
		; Ignorance/Rust/VoR/Backfire type gates (CanUse without busy — we may stage while casting).
		If Not CanUseRuptEffects($aSkillSlot) Then ContinueLoop
		; Overload is a soft rupt but never preferred over real interrupts.
		Out("Skillbarslot hardrupt ID2: " & $SkillBarCache[$aSkillSlot][$hardrupt])

		If Number($SkillBarCache[$aSkillSlot][$all]) = Number($Overload) Then
			$lOverloadSlot = $aSkillSlot
			ContinueLoop
		EndIf
		Out("Skillbarslot hardrupt ID3: " & $SkillBarCache[$aSkillSlot][$hardrupt])
		; Priority: Power Drain / energy-gain rupt when low energy.
		If IsEnergyGainRuptSkill($SkillBarCache[$aSkillSlot][$all]) And $lEnergy < 20 Then Return $aSkillSlot
		Out("Skillbarslot hardrupt ID4: " & $SkillBarCache[$aSkillSlot][$hardrupt])
		If $lReadySlot = 0 Then $lReadySlot = $aSkillSlot
	Next
	If $lReadySlot > 0 Then Return $lReadySlot
	Return $lOverloadSlot
EndFunc   ;==>GetBestRupt

; CanUse type/hex gates for a rupt slot, ignoring IsCasting / aftercast busy (staging OK while busy).
Func CanUseRuptEffects($aSkillSlot)
	If $aSkillSlot < 1 Or $aSkillSlot > 8 Then Return False
	If Skill_HasEffect($Diversion) Then Return False
	Switch $SkillBarCache[$aSkillSlot][$type]
		Case $Hex, $Spell, $Enchantment, $Well, $Ward, $ItemSpell, $WeaponSpell
			If Skill_HasEffect($Backfire) Or Skill_HasEffect($Soul_Leech) _
					Or Skill_HasEffect($Visions_of_Regret) Or Skill_HasEffect($Visions_of_Regret_PvP) _
					Or Skill_HasEffect($Mistrust) Or Skill_HasEffect($Mistrust_PvP) _
					Or Skill_HasEffect($Guilt) Or Skill_HasEffect($Mark_of_Subversion) _
					Or Skill_HasEffect($Spiteful_Spirit) Then Return False
		Case $Signet
			If Skill_HasEffect($Visions_of_Regret) Or Skill_HasEffect($Visions_of_Regret_PvP) _
					Or Skill_HasEffect($Spiteful_Spirit) Then Return False
			If Skill_HasEffect($Ignorance) Or Skill_HasEffect($Rust) Then Return False
		Case $Ritual, $Glyph, $Shout, $Preparation, $Trap, $Chant, $EchoRefrain, $Disguise
			If Skill_HasEffect($Visions_of_Regret) Or Skill_HasEffect($Visions_of_Regret_PvP) _
					Or Skill_HasEffect($Spiteful_Spirit) Then Return False
	EndSwitch
	Return True
EndFunc   ;==>CanUseRuptEffects

; GetSkillbarInfo → Wrappers\GwAu3_Data_Wrappers.au3

Func UnFight($x, $y, $aAggroRange = 1320, $aMaxDistanceToXY = 5000, $aAgent = 0)
	UseUnfightSkills($x, $y, $aAggroRange, $all, $aMaxDistanceToXY, $aAgent)
EndFunc   ;==>Fight

; For skills (pointer, struct, or ID) ? skill ID

Func UseUnfightSkills($x, $y, $aAggroRange = 1320, $skilltype = $all, $aMaxDistanceToXY = 5000, $aAgent = 0)
	; Unfight: single column pass.
	For $aSkillSlot In $Skillbar
		If Agent_GetAgentInfo(-2, "IsDead") Or Map_GetInstanceInfo("Type") == 2 Then Return False
		If $BestTarget <> 0 And Agent_GetAgentInfo($BestTarget, "Allegiance") = 3 And Agent_GetAgentInfo($BestTarget, "IsDead") Then Return False
		If $SkillBarCache[$aSkillSlot][$skilltype] = "" Then ContinueLoop
		If ShouldUse($aSkillSlot, $aAggroRange, $skilltype) Then Skill_TryUseSkill($aSkillSlot, $BestTarget)
	Next
	If $aAgent <> 0 Then
		If Agent_GetDistance($aAgent) > $aMaxDistanceToXY Then Return False
	ElseIf $aMaxDistanceToXY <> 5000 Then
		If Agent_GetDistanceToXY($x, $y) > $aMaxDistanceToXY Then Return False
	EndIf
	Return True
EndFunc   ;==>UseUnfightSkills

Func SkillCancel($aCasterID, $aTargetID, $aSkillID)
	Local $lCasterPtr = Agent_GetAgentPtr($aCasterID), $lTargetPtr = Agent_GetAgentPtr($aTargetID), $lSkillPtr = Skill_GetSkillPtr($aSkillID)
	If Map_GetInstanceInfo("Type") <> $Map_Explorable Or Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "IsKnocked") Then Return

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
	If Map_GetInstanceInfo("Type") <> $Map_Explorable Or Agent_GetAgentInfo(-2, "IsDead") Or Agent_GetAgentInfo(-2, "IsKnocked") Then Return

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
				Skill_TryUseSkill($i, -2)
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
				Skill_TryUseSkill($i, -2)
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

   For $i = 0 To 99
	  $theta += 3.6
	  $TempX = ($radius * Cos($theta * $d2r)) + $aX
	  $TempY = ($radius * Sin($theta * $d2r)) + $aY

	  $TestDistance = Agent_GetDistanceToXY($TempX, $TempY, -2)
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
EndFunc   ;==>GetProtSlot

Func CanAttack($aRange = 1320)
	Local $lMapType = Map_GetInstanceInfo("Type")
	Out("CanAttack: mapType=" & $lMapType & " range=" & $aRange)
	If $lMapType == 2 Then Connection_CheckAndReconnect()
	If $lMapType == 0 Then
		Out("CanAttack FAIL: mapType=0 (not explorable)")
		Return False
	EndIf

	Local $lKnocked = Agent_GetAgentInfo(-2, "IsKnocked")
	Local $lDead = Agent_GetAgentInfo(-2, "IsDead")
	Local $lWipe = Wipe()
	Out("CanAttack: knocked=" & $lKnocked & " dead=" & $lDead & " wipe=" & $lWipe)
	If $lKnocked Or $lDead Or $lWipe Then
		Out("CanAttack FAIL: knocked/dead/wipe")
		Return False
	EndIf
	; Torch/keg/ashes — no weapon swing. Unlit torch often reports WeaponItemType=46, not TYPE_BUNDLE.
	If Number(Item_GetInventoryInfo("BundleItemID")) <> 0 Or Number(Agent_GetAgentInfo(-2, "WeaponItemType")) = $TYPE_BUNDLE Then
		Out("CanAttack FAIL: holding bundle (BundleItemID=" & Number(Item_GetInventoryInfo("BundleItemID")) & _
				" WeaponItemType=" & Number(Agent_GetAgentInfo(-2, "WeaponItemType")) & ")")
		Return False
	EndIf

	Local $lEnemyCount = Agent_GetNumberOfEnemies($aRange)
	Out("CanAttack: Agent_GetNumberOfEnemies(" & $aRange & ")=" & $lEnemyCount)

	; Modules API — returns ptr; test <> 0 (not an ID).
	Local $lNearestPtr = Agent_GetNearestAgent(-2, 0xDB, 3)
	Local $lNearDist = 0
	Local $lNearName = ""
	If $lNearestPtr <> 0 Then
		$lNearDist = Agent_GetDistance($lNearestPtr)
		$lNearName = Agent_GetAgentInfo($lNearestPtr, "Name")
		If $lNearName = "" Or $lNearName = "0" Then $lNearName = "id=" & Agent_ConvertID($lNearestPtr)
	EndIf
	Local $lNearWorm = False
	If $lNearestPtr <> 0 Then $lNearWorm = Agent_IsWormAgent($lNearestPtr)
	Out("CanAttack nearest=" & $lNearName & " dist=" & Floor($lNearDist) & " inRange=" & ($lNearDist <= $aRange) & " worm=" & $lNearWorm)
	If $lNearestPtr <> 0 And $lNearDist <= $aRange And Not $lNearWorm Then
		$BestTarget = $lNearestPtr
		Return True
	EndIf
	If $lNearestPtr = 0 Then
		Out("CanAttack nearest FAIL: none")
	ElseIf $lNearDist > $aRange Then
		Out("CanAttack nearest FAIL: dist " & Floor($lNearDist) & " > range " & $aRange)
	ElseIf $lNearWorm Then
		Out("CanAttack nearest FAIL: worm agent")
	EndIf

	$BestTarget = Agent_GetBestTarget($aRange)
	Local $lBestName = ""
	If $BestTarget <> 0 Then
		$lBestName = Agent_GetAgentInfo($BestTarget, "Name")
		If $lBestName = "" Or $lBestName = "0" Then $lBestName = "id=" & Agent_ConvertID($BestTarget)
	EndIf
	Out("CanAttack GetBestTarget=" & $lBestName)
	If $BestTarget = 0 Then
		Out("CanAttack FAIL: GetBestTarget none")
		Return False
	EndIf
	Local $lBestDist = Agent_GetDistance($BestTarget)
	Out("CanAttack best dist=" & Floor($lBestDist) & " worm=" & Agent_IsWormAgent($BestTarget))
	If $lBestDist > $aRange Then
		Out("CanAttack FAIL: best dist " & Floor($lBestDist) & " > range " & $aRange)
		$BestTarget = 0
		Return False
	EndIf
	If Agent_IsWormAgent($BestTarget) Then
		Out("CanAttack FAIL: best is worm")
		$BestTarget = 0
		Return False
	EndIf
	Out("CanAttack OK via GetBestTarget BestTarget=" & $lBestName)
	Return True
EndFunc   ;==>CanAttack

;~ CanUse: whether we *can* fire a skill (any type) — recharge/energy/adrenaline,
;~ hard shut-downs (knocked/dead/busy), and type-punish hexes (Backfire/Diversion/…).
;~ (OnSpell IsAnnoyingSkill=1/2 only DoubleCancels mid-cast when those hexes are cast AT you.)
Func CanUse($aSkillSlot = 0)
	; REVIEW: GwAu3 equivalent is UAI_CanUse() + per-skill CanUse_* handlers. This one uses $SkillBarCache.
	UAI_CachePlayerEffectsAndBonds()

	If Map_GetInstanceInfo("Type") = 2 Then Connection_CheckAndReconnect()
	If Map_GetInstanceInfo("Type") = 0 Then Return False
	If Agent_GetAgentInfo(-2, "IsKnocked") Or Agent_GetAgentInfo(-2, "IsDead") Or Wipe() Then Return False
	If GetRemainingAftercastMs() > 0 Or Agent_GetAgentInfo(-2, "IsCasting") Then Return False

	; Diversion: next skill (any) takes huge recharge — never start one while hexed.
	If Skill_HasEffect($Diversion) Then Return False

	If $aSkillSlot <> 0 Then
		If Not Skill_GetSkillbarInfo($aSkillSlot, "IsRecharged") Then Return False
		Local $lEnergyReq = Number($SkillBarCache[$aSkillSlot][$energyreq])
		If Skill_HasEffect($Quickening_Zephyr) Then $lEnergyReq = $lEnergyReq * 1.3
		If Agent_GetAgentInfo(-2, "CurrentEnergy") < $lEnergyReq Then Return False
		; Adrenaline gate — Number() so empty/string cache never bypasses the compare.
		Local $lAdreReq = Number($SkillBarCache[$aSkillSlot][$adrereq])
		If $lAdreReq > 0 And Number(Skill_GetSkillbarInfo($aSkillSlot, "Adrenaline")) < $lAdreReq Then Return False
	EndIf

	If $aSkillSlot = 0 Then Return True

	; AutoIt Switch does not fall through — Signet/Shout/Chant need their own Cases (not a shared list + later Case).
	Switch $SkillBarCache[$aSkillSlot][$type]
		Case $Hex, $Spell, $Enchantment, $Well, $Ward, $ItemSpell, $WeaponSpell
			; Spell-punish hexes (IsAnnoyingSkill type 1 + close cousins). Soft rupts are $Spell — blocked here.
			If Skill_HasEffect($Backfire) Or Skill_HasEffect($Soul_Leech) _
					Or Skill_HasEffect($Visions_of_Regret) Or Skill_HasEffect($Visions_of_Regret_PvP) _
					Or Skill_HasEffect($Mistrust) Or Skill_HasEffect($Mistrust_PvP) _
					Or Skill_HasEffect($Guilt) Or Skill_HasEffect($Mark_of_Subversion) _
					Or Skill_HasEffect($Spiteful_Spirit) Then Return False
		Case $Stance
			If Skill_HasEffect($SkillBarCache[$aSkillSlot][$all]) Then Return False
		Case $Attack
			If Skill_HasEffect($Ineptitude) Or Skill_HasEffect($Clumsiness) Or Skill_HasEffect($Spiteful_Spirit) _
					Or Skill_HasEffect($Wandering_Eye) Or Skill_HasEffect($Wandering_Eye_PvP) Then Return False
		Case $Signet
			If Skill_HasEffect($Visions_of_Regret) Or Skill_HasEffect($Visions_of_Regret_PvP) _
					Or Skill_HasEffect($Spiteful_Spirit) Then Return False
			If Skill_HasEffect($Ignorance) Or Skill_HasEffect($Rust) Then Return False
		Case $Shout, $Chant
			If Skill_HasEffect($Visions_of_Regret) Or Skill_HasEffect($Visions_of_Regret_PvP) _
					Or Skill_HasEffect($Spiteful_Spirit) Then Return False
			If Skill_HasEffect($Cacophony) Or Skill_HasEffect($Ulcerous_Lungs) _
					Or Skill_HasEffect($Vocal_Minority) Or Skill_HasEffect($Well_of_Silence) Then Return False
		Case $Ritual, $Glyph, $Preparation, $Trap, $EchoRefrain, $Disguise
			If Skill_HasEffect($Visions_of_Regret) Or Skill_HasEffect($Visions_of_Regret_PvP) _
					Or Skill_HasEffect($Spiteful_Spirit) Then Return False
	EndSwitch
	Return True

EndFunc   ;==>CanUse

Func OurSkillActivationMs()
	If $MySkillSlot < 1 Or $MySkillSlot > 8 Then Return 0
	Local $iSkill = $SkillBarCache[$MySkillSlot][$all]
	If $iSkill = 0 Then Return 0
	; Busy clock: activation+ping only (no projectile travel).
	Return Skill_GetMyActivationTime($iSkill, 0)
EndFunc   ;==>OurSkillActivationMs

Func OurSkillID()
	If $MySkillSlot < 1 Or $MySkillSlot > 8 Then Return 0
	Return $SkillBarCache[$MySkillSlot][$all]
EndFunc   ;==>OurSkillID

; LogicCast constants.au3 â†’ $aSkill_Name[id]
Func Skill_NameFromID($a_i_SkillID)
	Local $i = Number($a_i_SkillID)
	If $i < 1 Or $i >= UBound($aSkill_Name) Then Return "#" & $i
	Local $s = $aSkill_Name[$i]
	If Not IsString($s) Or $s = "" Then Return "#" & $i
	Return $s
EndFunc   ;==>Skill_NameFromID

; Fixed-width pad for OutSkillBarSummary.
Func _OutPad($aText, $aWidth, $aRightAlign = False)
	Local $s = String($aText)
	If StringLen($s) > $aWidth Then Return StringLeft($s, $aWidth)
	If $aRightAlign Then Return StringFormat("%" & $aWidth & "s", $s)
	Return StringFormat("%-" & $aWidth & "s", $s)
EndFunc

; Log-friendly skillbar dump — energy/adre/type/target after CacheSkillBar (no _ArrayDisplay).
Func OutSkillBarSummary()
	Out("Slot  ID    Name                      Ene  Adr  Type  Tgt")
	Out("----  ----  ------------------------  ---  ---  ----  ---")
	For $i = 1 To 8
		Local $iID = Number($SkillBarCache[$i][$all])
		If $iID = 0 Then
			Out(_OutPad($i, 4) & "  " & _OutPad("-", 4) & "  " & _OutPad("(empty)", 24) & "  " & _
					_OutPad("-", 3, True) & "  " & _OutPad("-", 3, True) & "  " & _OutPad("-", 4, True) & "  " & _OutPad("-", 3, True))
			ContinueLoop
		EndIf
		Local $sName = Skill_NameFromID($iID)
		$sName = StringReplace($sName, "_", " ")
		Out(_OutPad($i, 4) & "  " & _OutPad($iID, 4) & "  " & _OutPad($sName, 24) & "  " & _
				_OutPad(Number($SkillBarCache[$i][$energyreq]), 3, True) & "  " & _
				_OutPad(Number($SkillBarCache[$i][$adrereq]), 3, True) & "  " & _
				_OutPad(Number($SkillBarCache[$i][$type]), 4, True) & "  " & _
				_OutPad(Number($SkillBarCache[$i][$target]), 3, True))
	Next
EndFunc   ;==>OutSkillBarSummary

;~ ShouldUse: whether we *should* fire — policy + valid $BestTarget.
;~ $aSkillType = SkillBarCache column ($rupt / $enchantremove / $hexremove / $all / …).
;~ Calls CanUse for afford/gates; TryUseSkill stays outside.
Func ShouldUse($aSkillSlot, $aAggroRange = 1320, $aSkillType = $all)
; REVIEW: GwAu3 equivalent is UAI_CanUse(). Keep this while using Logic cache.
	If $aSkillSlot = "" Then Return

	; Reactive columns: aftercast must not block; still require energy/recharge via ShouldUse.
	If Not CanUse($aSkillSlot) Then Return False

	If Skill_HasEffect($Glyph_Of_Sacrifice) And $aSkillSlot <> $SkillbarSlot[$Meteor_Shower] Then Return False

	;~  ECHOES, CHANTS AND SHOUTS - Needs to be before CanUse test for energy since this block requests BiP from hero.
	If $SkillBarCache[$aSkillSlot][$echochantshout] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$echochantshout]
			Case $To_the_Limit
				If Agent_GetNumberOfEnemies($Earshot_Range) = 0 Then Return False
			Case $Save_Yourselves_Kurzick, $Save_Yourselves_Luxon, $Theres_Nothing_to_Fear
				If Skill_HasEffect($Cacophony) Or Skill_HasEffect($Vocal_Minority) Then UseHeroHexRemoval()
				; If GetNumberOfEnemies(1400) = 0 Then Return False We don't need this because when are not using those skills when enemies are not around
				Local $lLowestAlly = Agent_GetLowestAlly()
				If $lLowestAlly = 0 Or Agent_GetAgentInfo($lLowestAlly, "HP") > 0.90 Then Return False
			Case $Heroic_Refrain, $Mending_Refrain, $Bladeturn_Refrain, $Burning_Refrain
				If $BiP[0] <> 0 And Agent_GetAgentInfo(-2, "CurrentEnergy") < 20 And Not Skill_HasEffect($Blood_is_Power) Then
					Local $lBiPHero = Agent_GetHero($BiP[0])
					Local $lBiPMinHP = 0.4
					; Scourge Sacrifice amplifies BiP's HP loss — skip if it would likely kill Livia.
					If $lBiPHero <> 0 And Skill_HasEffect($Scourge_Sacrifice, $lBiPHero) Then $lBiPMinHP = 0.55
					If $lBiPHero <> 0 And Not Agent_GetAgentInfo($lBiPHero, "IsDead") And Agent_GetAgentInfo($lBiPHero, "HP") > $lBiPMinHP Then Skill_UseHeroSkill($BiP[0], $BiP[1], -2)
				EndIf
			Case Else
					If Skill_HasEffect($SkillBarCache[$aSkillSlot][$echochantshout]) Or Skill_HasEffect($Vocal_Minority) Then Return False
		EndSwitch
	EndIf

	Switch $aSkillType
		Case $rupt
			; Slot choice for a known cast is GetBestRupt (Listen_TryRupt). Bar ShouldUse only needs a casting foe.
			If $SkillBarCache[$aSkillSlot][$rupt] = "" Then Return False
			If GetBestTargetBySkillSlot($aSkillSlot, $aAggroRange) = 0 Then Return False
			Return True

		Case $enchantremove
			If $SkillBarCache[$aSkillSlot][$enchantremove] = "" Then Return False
			$BestTarget = Agent_GetBalledEnchantedEnemy($aAggroRange)
			If $BestTarget = 0 Or Agent_GetDistance($BestTarget) > $aAggroRange Then
				$BestTarget = 0
				Return False
			EndIf
			Return True

		Case $hexes
			If $SkillBarCache[$aSkillSlot][$hexes] = "" Then Return False
			If GetBestTargetBySkillSlot($aSkillSlot, $aAggroRange) = 0 Then Return False
			; Fall through â€” Diversion/Shame/BF/Guilt gates below.

		Case Else
			; Else / category passes: never steal pool-driven slots.
			If $aSkillType = $all Then
				If $SkillBarCache[$aSkillSlot][$rupt] <> "" Then Return False
				If $SkillBarCache[$aSkillSlot][$enchantremove] <> "" Then Return False
				If $SkillBarCache[$aSkillSlot][$hexremove] <> "" Then Return False
			ElseIf $SkillBarCache[$aSkillSlot][$aSkillType] = "" Then
				Return False
			EndIf
			If GetBestTargetBySkillSlot($aSkillSlot, $aAggroRange) = 0 Then Return False
	EndSwitch

;~ BINDING RITUALS
	If $SkillBarCache[$aSkillSlot][$bind] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$bind]     ; binding ritual skills
			Case $Summon_Spirits_Kurzick, $Summon_Spirits_Luxon
				; UAI-aligned: any controlled spirit — pull stragglers, or refresh when one is low HP.
				Local $nFar = Agent_GetMySpiritCount(5000)
				If $nFar = 0 Then Return False
				Local $nNear = Agent_GetMySpiritCount(1250)
				If $nNear < $nFar Then Return True
				Local $lLowestSpirit = Agent_GetLowestSpirit()
				If $lLowestSpirit = 0 Then Return False
				If Agent_GetAgentInfo($lLowestSpirit, "HP") >= 0.85 Then Return False
			Case $Spirit_Siphon
				Out("Spirit Energy" & Agent_GetAgentInfo(Agent_GetNearestSpirit(), "CurrentEnergy"))
				If Agent_GetAgentInfo(-2, "CurrentEnergy") > 30 Or Agent_GetAgentInfo(Agent_GetNearestSpirit(), "CurrentEnergy") < 19 Then Return False
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
				If Skill_GetSkillbarInfo($SkillbarSlot[$Soul_Twisting], "IsRecharged") And Not Skill_HasEffect($Soul_Twisting) Then Skill_TryUseSkill($SkillbarSlot[$Soul_Twisting], -2)
		EndSwitch
	EndIf

;~ SURVIVAL SKILLS
	If $SkillBarCache[$aSkillSlot][$survive] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$survive]
			Case $I_Am_Unstoppable
				If GetEffectTimeRemaining($Shadow_Form) > 5000 And Not Agent_GetAgentInfo(-2, "IsKnocked") Then Return False
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
				If Agent_GetAgentInfo(-2, "HP") < 0.15 Then Return False
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
				Local $nFarP = Agent_GetMySpiritCount(5000)
				If $nFarP = 0 Then Return False
				If Agent_GetMySpiritCount(1250) >= $nFarP Then
					Local $lLowestPrecast = Agent_GetLowestSpirit()
					If $lLowestPrecast = 0 Or Agent_GetAgentInfo($lLowestPrecast, "HP") >= 0.85 Then Return False
				EndIf
		EndSwitch
	EndIf

;~ HEAL SKILLS
	If $SkillBarCache[$aSkillSlot][$heal] <> "" Then
		$lowestally = Agent_GetLowestAlly()
		Switch $SkillBarCache[$aSkillSlot][$heal]
			Case $Word_of_Healing
				If Agent_GetAgentInfo($lowestally, "HP") > 0.5 Then Return False
			Case $Healing_Spring
				If Agent_GetAgentInfo(-2, "HP") > 0.95 Then Return False
			Case $Mend_Body_and_Soul
				If Agent_GetAgentInfo($lowestally, "HP") > 0.5 And Not Agent_GetAgentInfo($lowestally, "IsDead") Then Return False
			Case $Divine_Healing, $Heal_Party, $Heavens_Delight, $Protective_Was_Kaolai, $Protective_Was_Kaolai_PvP, $Heal_Party, $Mystic_Healing, $Mystic_Healing_PvP, $Courageous_Was_Saidra
				If Party_GetPartyHealth() > 0.90 Or Agent_GetAgentInfo($lowestally, "HP") > 0.75 Then Return False
			Case Else
				If IsHealSkill($SkillBarCache[$aSkillSlot][$heal]) And Agent_GetAgentInfo($lowestally, "HP") > 0.8 Then Return False
				If IsSelfHealSkill($SkillBarCache[$aSkillSlot][$heal]) And Agent_GetAgentInfo(-2, "HP") > 0.8 Then Return False
		EndSwitch
	EndIf

;~ CONDITION REMOVE SKILLS
	If $SkillBarCache[$aSkillSlot][$condremove] <> "" Then
		If RequiresCondition($SkillBarCache[$aSkillSlot][$condremove]) And Not Agent_GetAgentInfo($MostConditionedAllyPtr, "IsDead") Then Return False
		$lowestally = Agent_GetLowestAlly()
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
		$MostHexedAllyPtr = Agent_GetMostHexedAlly()

		; Requires a living hexed target (old check inverted IsDead and blocked every living ally).
		If RequiresHex($SkillBarCache[$aSkillSlot][$hexremove]) Then
			If $BestTarget = 0 Or Agent_GetAgentInfo($BestTarget, "IsDead") Then Return False
			If Not Agent_GetAgentInfo($BestTarget, "IsHexed") Then Return False
		EndIf

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
			Case Else ;$Reverse_Hex, $Remove_Hex, $Expel_Hexes, $Inspired_Hex, $Revealed_Hex, $Spotless_Mind, $Convert_Hexes, $Deny_Hexes, $Shatter_Hex, Ã¯Â¿Â½
				Return True
		EndSwitch
	EndIf

;~ INTERRUPTS skill log respond passes owns $rupt; never cast them from Else / category ShouldUse.
	If $SkillBarCache[$aSkillSlot][$rupt] <> "" Then Return False

;~ JUNUNDU
	If $SkillBarCache[$aSkillSlot][$junundu] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$junundu]
			Case $Junundu_Strike	; only affects adjacent range but will run to enemy
				If Agent_GetNearestDistance() > $Earshot_Range Then Return False
				MoveTo(X($BestTarget), Y($BestTarget))
			Case $Burning_Breath, $Junundu_Siege1	; skill fails if target is closer than nearbyrange, check if we should move out of range before using
				If Agent_GetDistance($BestTarget) < $Nearby_Range Then Return False
			Case $Blinding_Breath, $Choking_Breath, $Junundu_Smash ; untargeted skill, only affects adjacent foes
				If CanUse($SkillbarSlot[$Burning_Breath]) Or CanUse($SkillbarSlot[$Junundu_Siege1]) Then Return False
				MoveTo(X($BestTarget), Y($BestTarget))
			Case $Junundu_Bite	; does not heal if target is not knocked down and easily reachable
				If Not Agent_GetAgentInfo($BestTarget, "Knocked") And Agent_GetDistance($BestTarget) < $Nearby_Range Then Return False
			Case $Junundu_Feast
				If GetNumberOfCorpses($Adjacent_Range) = 0 Then Return False
			Case $Junundu_Tunnel	; stance is used on recharge as per CanUse() conditions
				For $aHero = 1 To GetPartySize() -1	; make heroes run with us, they won't use on their own
					For $aSkillSlot = 1 To 8
						$aSkillID = Skill_GetSkillbarInfo($aSkillSlot, "SkillID", $aHero)
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

;~ HEX â€” IsAnnoyingSkill gates (Diversion/BF/Shame/Guilt etc.)
	If $SkillBarCache[$aSkillSlot][$hexes] <> "" Then
		If $BestTarget = 0 Then Return False
		Switch $SkillBarCache[$aSkillSlot][$hexes]
			Case $Panic, $Panic_PvP
				If Agent_GetAgentInfo($BestTarget, "Knocked") Then Return False
		EndSwitch
	EndIf

;~  OTHER
	If $SkillBarCache[$aSkillSlot][$all] <> "" Then
		Switch $SkillBarCache[$aSkillSlot][$all]
			Case $Ineptitude, $Wandering_Eye, $Clumsiness, $Signet_of_Clumsiness, $Signet_of_Clumsiness_PvP
				If Agent_GetAgentInfo($BestTarget, "Knocked") Then Return False
			Case $Accumulated_Pain
				If Not Agent_GetAgentInfo($BestTarget, "IsDead") Then Return False
			Case $Vow_of_Piety
				If Skill_HasEffect($Vow_of_Piety) Then Return False
			Case $Glyph_Of_Sacrifice
				If Agent_GetAgentInfo(-2, "CurrentEnergy") < 30 Then Return False
				If Not CanUse($SkillbarSlot[$Meteor_Shower]) Then Return False
			Case $Meteor_Shower
				If Not Skill_HasEffect($Glyph_Of_Sacrifice) Then Return False
			Case $Ether_Signet
				If Agent_GetAgentInfo(-2, "CurrentEnergy") > 4 Then Return False
		EndSwitch
	EndIf

	Return True
EndFunc   ;==>ShouldUse

; Best target for a skillslot. Shame/Guilt/Mistrust/Mark of Subversion scoring lives here
; (not separate helpers). CounterEnemyCasts uses the same function for rupt targeting.
Func GetBestTargetBySkillSlot($aSkillSlot, $aAggroRange = 1320)
	If Map_GetInstanceInfo("Type") == 2 Then Connection_CheckAndReconnect()
	If Map_GetInstanceInfo("Type") == 0 Then Return 0
	$MyPtr = Agent_GetAgentPtr(-2)
	$BestTarget = 0

	Switch $SkillBarCache[$aSkillSlot][$hexes]
		Case $Panic, $Panic_PvP, $Wastrels_Worry, $Wastrels_Demise, $Wastrels_Demise_PvP
			$BestTarget = Agent_GetBestTarget($aAggroRange)
			Return $BestTarget
	EndSwitch

	Switch $SkillBarCache[$aSkillSlot][$all]
		Case $Meteor_Shower, $Meteor
			$BestTarget = Agent_GetBestTarget($aAggroRange)
			Return $BestTarget
	EndSwitch

	; Ally helpers: ($aRange [, $excludeself=False]). Only Case 4 (other ally) passes True.
	; All of these return ptrs — test with <> 0 / IsPtr, never treat as raw IDs.
	Switch $SkillBarCache[$aSkillSlot][$target]
		Case 0	; self
			Local $lNearEnemy = Agent_GetNearestAgent(-2, 0xDB, 3)
			Switch $SkillBarCache[$aSkillSlot][$type]
				Case $Ward, $Ritual, $Signet
					If $lNearEnemy = 0 Or Agent_GetDistance($lNearEnemy) > $aAggroRange Then Return 0
					$BestTarget = $MyPtr
				Case Else
					If $SkillBarCache[$aSkillSlot][$precast] == 0 Then
						If $lNearEnemy = 0 Or Agent_GetDistance($lNearEnemy) > $aAggroRange Then Return 0
					EndIf
					$BestTarget = $MyPtr
			EndSwitch

		Case 3	; ally — self allowed (default excludeself=False)
			If $SkillBarCache[$aSkillSlot][$condremove] <> "" Then
				$BestTarget = Agent_GetMostCondsAlly($aAggroRange)
			ElseIf $SkillBarCache[$aSkillSlot][$hexremove] <> "" Then
				Switch $SkillBarCache[$aSkillSlot][$hexremove]
					Case $Hex_Eater_Signet, $Hex_Eater_Vortex, $Shatter_Hex, $Smite_Hex
						$BestTarget = Agent_GetMostBalledHexedAlly($aAggroRange)
						If $BestTarget = 0 Then $BestTarget = Agent_GetMostHexedAlly($aAggroRange)
					Case Else
						$BestTarget = Agent_GetMostHexedAlly($aAggroRange)
				EndSwitch
			ElseIf $SkillBarCache[$aSkillSlot][$precast] <> "" Then
				$BestTarget = $MyPtr
			ElseIf $SkillBarCache[$aSkillSlot][$survive] <> "" Then
				$BestTarget = $MyPtr
			ElseIf $SkillBarCache[$aSkillSlot][$type] = $EchoRefrain Then
				$BestTarget = Agent_NeedEchoAlly($SkillBarCache[$aSkillSlot][$echochantshout])
			Else
				$BestTarget = Agent_GetLowestAlly($aAggroRange)
			EndIf

		Case 4	; other ally — exclude self (only case that passes True)
			If $SkillBarCache[$aSkillSlot][$condremove] <> "" Then
				$BestTarget = Agent_GetMostCondsAlly($aAggroRange, True)
			ElseIf $SkillBarCache[$aSkillSlot][$hexremove] <> "" Then
				Switch $SkillBarCache[$aSkillSlot][$hexremove]
					Case $Hex_Eater_Signet, $Hex_Eater_Vortex, $Shatter_Hex, $Smite_Hex
						$BestTarget = Agent_GetMostBalledHexedAlly($aAggroRange, True)
						If $BestTarget = 0 Then $BestTarget = Agent_GetMostHexedAlly($aAggroRange, True)
					Case Else
						$BestTarget = Agent_GetMostHexedAlly($aAggroRange, True)
				EndSwitch
			ElseIf $SkillBarCache[$aSkillSlot][$heal] <> "" Then
				$BestTarget = Agent_GetLowestAlly($aAggroRange, True)
			ElseIf $SkillBarCache[$aSkillSlot][$precast] <> "" Then
				$BestTarget = $MyPtr
			ElseIf $SkillBarCache[$aSkillSlot][$survive] <> "" Then
				$BestTarget = $MyPtr
			ElseIf $SkillBarCache[$aSkillSlot][$type] = $EchoRefrain Then
				$BestTarget = Agent_NeedEchoAlly($SkillBarCache[$aSkillSlot][$echochantshout])
			Else
				$BestTarget = Agent_GetLowestAlly($aAggroRange, True)
			EndIf

		Case 5	; enemy
			If $SkillBarCache[$aSkillSlot][$hexes] <> "" Then
				$BestTarget = Agent_GetBestHexTarget($SkillBarCache[$aSkillSlot][$hexes], $aAggroRange)
			ElseIf $SkillBarCache[$aSkillSlot][$type] = $Signet Then
				$BestTarget = Agent_GetBestSignetTarget($SkillBarCache[$aSkillSlot][$all], $aAggroRange)
			ElseIf $SkillBarCache[$aSkillSlot][$enchantremove] <> "" Then
				$BestTarget = Agent_GetBalledEnchantedEnemy($aAggroRange)
			ElseIf $SkillBarCache[$aSkillSlot][$attackskill] <> "" Then
				$BestTarget = GetBestMeleeTarget($SkillBarCache[$aSkillSlot][$attackskill])
			ElseIf $SkillBarCache[$aSkillSlot][$rupt] <> "" Then
				; CastingOnly=True is 2nd arg of Agent_GetBestTarget (via MostBalledCastingEnemy).
				$BestTarget = Agent_GetMostBalledCastingEnemy($aAggroRange)
			ElseIf Skill_GetSkillInfo($SkillBarCache[$aSkillSlot][$all], "AoERange") = $adjacent_range Or Skill_GetSkillInfo($SkillBarCache[$aSkillSlot][$all], "AoERange") = $Nearby_Range Then
				$BestTarget = Agent_GetBestTarget($aAggroRange , False, False, False, False, True) ; do not target stationary foes
			Else
				$BestTarget = Agent_GetBestTarget($aAggroRange)
			EndIf

		Case 6	; dead ally
			$BestTarget = Agent_GetNearestDeadAlly($aAggroRange)
		Case 14	; spirit, minion
			$BestTarget = Agent_GetNearestMinionAlly()
		Case 16 ; Spells targeting the ground, like snow storm
			Local $lSkillID = $SkillBarCache[$aSkillSlot][$all]
			If $lSkillID = "" Then $lSkillID = Skill_GetSkillbarInfo($aSkillSlot, "SkillID")
			Local $lAoE = Skill_GetSkillInfo($lSkillID, "AoERange")
			If $lAoE = $adjacent_range Or $lAoE = $Nearby_Range Then
				$BestTarget = Agent_GetBestTarget($aAggroRange, False, False, False, False, True)
			Else
				$BestTarget = Agent_GetBestTarget($aAggroRange)
			EndIf
	EndSwitch

	; Never hand Fight/UseSkills an enemy outside the requested range.
	If $BestTarget <> 0 Then
		If Agent_GetAgentInfo($BestTarget, "Allegiance") = 3 And Agent_GetDistance($BestTarget) > $aAggroRange Then
			$BestTarget = 0
			Return 0
		EndIf
		Return $BestTarget
	EndIf
	Return 0
EndFunc   ;==>GetBestTargetBySkillSlot

Func Survive($aAggroRange = 1500)
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	If ShouldUse($SkillbarSlot[$I_Am_Unstoppable], $aAggroRange) Then Skill_TryUseSkill($SkillbarSlot[$I_Am_Unstoppable])
	If ShouldUse($SkillbarSlot[$Glyph_of_Swiftness], $aAggroRange) Then Skill_TryUseSkill($SkillbarSlot[$Glyph_of_Swiftness])
	If ShouldUse($SkillbarSlot[$Shadow_Form], $aAggroRange) Then Skill_TryUseSkill($SkillbarSlot[$Shadow_Form])

	If ShouldUse($SkillbarSlot[$Protective_Spirit], $aAggroRange) Then Skill_TryUseSkill($SkillbarSlot[$Protective_Spirit])
	If ShouldUse($SkillbarSlot[$Shielding_Hands], $aAggroRange) Then Skill_TryUseSkill($SkillbarSlot[$Shielding_Hands])
;~ 	If ShouldUse($SkillbarSlot[$Spirit_Bond]) Then Skill_TryUseSkill($SkillbarSlot[$Spirit_Bond])

	For $aSkillSlot In $Skillbar
		If Agent_GetAgentInfo(-2, "IsDead") Then ExitLoop
		If Agent_GetAgentInfo(-2, "HP") < 0.9 And TimerDiff($MysticTimer) > 500 And UBound($HeroHeals) <> 0 Then
			Skill_UseHeroSkill($HeroHeals[$HealCount][1], $HeroHeals[$HealCount][2], 0)
			$MysticTimer = TimerInit()
			$HealCount += 1
			If $HealCount > UBound($HeroHeals) - 1 Then $HealCount = 0
		EndIf

		If $SkillBarCache[$aSkillSlot][$survive] = "" Then ContinueLoop
		If ShouldUse($aSkillSlot, $aAggroRange) Then Skill_TryUseSkill($aSkillSlot, $BestTarget)
	Next
EndFunc   ;==>Survive

Func Precast($aAggroRange = $compass_range, $precastspirits = True)
	If $precastspirits Then PrecastWardsAndSpirits()
	If ShouldUse($SkillbarSlot[$Ebon_Battle_Standard_Of_Honor], $longbow_range) Then Skill_TryUseSkill($SkillbarSlot[$Ebon_Battle_Standard_Of_Honor])
	If $Summon_Spirits > 0 And ShouldUse($Summon_Spirits) Then Skill_TryUseSkill($Summon_Spirits)
	If ShouldUse($SkillbarSlot[$Painful_Bond]) Then Skill_TryUseSkill($SkillbarSlot[$Painful_Bond], $BestTarget)
	If ShouldUse($SkillbarSlot[$Boon_Of_Creation]) Then Skill_TryUseSkill($SkillbarSlot[$Boon_Of_Creation])
EndFunc   ;==>Precast

Func SpreadChants()
	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$echochantshout] = "" Then ContinueLoop
		If ShouldUse($aSkillSlot) Then Skill_TryUseSkill($aSkillSlot, $BestTarget)
	Next
EndFunc   ;==>SpreadChants

Func Precastupkeep()
	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$precast] = "" Then ContinueLoop
		If ShouldUse($aSkillSlot) Then Skill_TryUseSkill($aSkillSlot, -2)
	Next
EndFunc   ;==>Precastupkeep

Func SpeedBoost()
	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$speedBoost] = "" Then ContinueLoop
		; Lit torch: keep Fall Back / ToF etc., but do not start HR (1s activation).
		If Skill_HasEffect($Lit_Torch) And Number($SkillBarCache[$aSkillSlot][$all]) = $Heroic_Refrain Then ContinueLoop
		If ShouldUse($aSkillSlot) Then Skill_TryUseSkill($aSkillSlot, $BestTarget)
	Next
EndFunc   ;==>SpeedBoost

Func Bind($aAggroRange = $longbow_range)
	UseSkills(X(), Y(), $aAggroRange, $bind)
EndFunc   ;==>Bind

Func Pressure($aAggroRange = $longbow_range)
	UseSkills(X(), Y(), $aAggroRange, $pressure)
EndFunc   ;==>Pressure

Func AttackEnemies($aAggroRange = $longbow_range)
	UseSkills(X(), Y(), $aAggroRange, $attackskill)
EndFunc   ;==>AttackEnemies

Func Heal($aAggroRange = $spellcasting_range)
	Out("Using heal skills")
	UseSkills(X(), Y(), $aAggroRange, $prot)
	UseSkills(X(), Y(), $aAggroRange, $condremove)
	UseSkills(X(), Y(), $aAggroRange, $hexremove)
	UseSkills(X(), Y(), $aAggroRange, $heal)

EndFunc   ;==>Heal

Func Rezz($aAggroRange = 5000)
	Out("Resurrecting")
	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$rezz] = "" Then ContinueLoop
		If ShouldUse($aSkillSlot) Then Skill_TryUseSkill($aSkillSlot, $BestTarget)
	Next
EndFunc    ;==>Rezz

Func Interrupt($aAggroRange = $bowpull_range)
	Out("Using interrupt skills")
	UseSkills(X(), Y(), $aAggroRange, $Rupt)
EndFunc   ;==>Interrupt

Func Defend($aAggroRange = $spellcasting_range)
	Out("Using defensive skills")
	UseSkills(X(), Y(), $aAggroRange, $defend)
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
		Case $Balthazars_Spirit, $Blessed_Aura, $Boon_Of_Creation, $Summon_Spirits_Luxon, $Summon_Spirits_Kurzick
			Return True
	EndSwitch
	If IsSelfPrehealSkill($aSkillID) Then Return True
	If IsDisguiseskill($aSkillID) Then Return True
	If Skill_GetSkillInfo($aSkillID, "SkillType") = $Ward Then Return True ; Type
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
			$aSkill = Skill_GetSkillbarInfo($aSkillSlot, "SkillID", $aHeroNumber)
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
		Case $mend_ailment, $purge_conditions, $mending_touch, $Mend_Body_and_Soul, $Spotless_Soul, _
				$Smite_Condition, $Smite_Condition2
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

; Returns whether a skill is a condition spell

; Returns whether a skill is a Ritual spell


; Returns whether a skill is an enchantment skill

; Returns whether a skill is an attack skill















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
	Local $lSkillID = SkillID($aSkill)

	Switch $lSkillID
		Case $Spirit_Bond, $Spirit_Bond_PvP, $Protective_Spirit, $Shield_of_Absorption, $Guardian, $Weapon_of_Warding, $Weapon_of_Warding_PvP, $Aegis, $Aegis_PvP, _
				$Reversal_of_Fortune, $Life_Sheath, $Weapon_of_Remedy, $Xinraes_Weapon, $Resilient_Weapon, $Weapon_of_Shadow, $Vengeful_Weapon, $Aura_of_Stability, $Reversal_of_Damage
			Return True
	EndSwitch
	Return False
EndFunc   ;==>IsProtectiveSkill

Func IsRuptSkill($aSkill, $hardrupt = False)
; REVIEW: Keep this. Uses Effect2 bit (+0x20) + soft-rupt exceptions. GwAu3 has no direct equivalent.
	Local $lSkillEffect2 = Skill_GetSkillInfo($aSkill, "Effect2")
	Local $lSkillID = SkillID($aSkill)

	; Punish-on-cast hexes: Effect2 often looks like an interrupt, but they are too slow for
	; dispatch rupt and belong on the skillbar as hexes (Shame ~2s activation).
	Switch $lSkillID
		Case $Shame, $Mark_of_Subversion, $Guilt, $Diversion, $Backfire, $Mistrust, $Mistrust_PvP, _
				$Visions_of_Regret, $Visions_of_Regret_PvP, $Soul_Leech
			Return False
	EndSwitch

	Switch $lSkillID	; interrupt skills that are incorrectly categorized via Effect2 or soft rupts for separation
		Case $Power_Drain, $Power_Flux, $Power_Leak, $Power_Leech, $Power_Lock, $Power_Return, $Power_Spike, $Leech_Signet, $Overload    ; soft rupts
			If Not $hardrupt Then Return True
		Case $You_Move_Like_a_Dwarf, $Disarm, $Disrupting_Shot, $Disrupting_Throw, $Distracting_Lunge, $Distracting_Strike, $Magebane_Shot, $Concussion_Shot
			Return True
		Case $Cry_of_Pain, $Psychic_Instability, $Psychic_Instability_PvP, $Simple_Thievery, $Tease
			Return True
		Case $Exhausting_Assault, $Temple_Strike, $Lyssas_Assault, $Lyssas_Haste, $Lyssas_Haste_PvP, $Thunderclap
			Return True
		Case $Psychic_Distraction, $Complicate, $Tease, $Web_of_Disruption, $Web_of_Disruption_PvP, $Disrupting_Dagger
			Return True
		Case $Signet_of_Disruption
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
	Local $lSkillID = SkillID($aSkill)

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
	Local $lSkillID = SkillID($aSkill)

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
; Attack skills need a hard/fast interrupt. Soft rupts (Power Drain, Leech Signet, Ã¯Â¿Â½) can stop
; spells/hexes/chants/signets and most NPC "Skill" activations Ã¯Â¿Â½ whitelist was too narrow before
; True = soft rupts (Power Spike/Drain/Leech Signetâ€¦) cannot interrupt this cast.
; Soft interrupts only stop spells (Spell / Hex / Enchantment). Signets, attacks, rituals,
; wards, shouts, etc. need a hard rupt or we waste the slot (user: "rupts happen on signets").
Func RequiresHardRupt($aSkillID)
	Switch Number(Skill_GetSkillInfo($aSkillID, "SkillType"))
		Case $Spell, $Hex, $Enchantment, _
				$GC_I_SKILL_TYPE_ITEM_SPELL, $GC_I_SKILL_TYPE_WEAPON_SPELL
			; Soft rupts ("Interrupt target foe's spell") work here.
			Return False
		Case Else
			; Signet, Attack, Ritual, Ward, Well, Skill, Shout, Stance, Chant, â€¦
			Return True
	EndSwitch
EndFunc   ;==>RequiresHardRupt

; RequiresBleeding → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresBlind → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresBurning → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresCripple → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresCrippleAndBleed → Wrappers\GwAu3_Data_Wrappers.au3


; SkillRequiresDeepwound → Wrappers\GwAu3_Data_Wrappers.au3


; SkillRequiresDeepWoundAndBleed → Wrappers\GwAu3_Data_Wrappers.au3


; SkillRequiresDisease → Wrappers\GwAu3_Data_Wrappers.au3


; SkillRequiresEarthhex → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresKnockdown → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresCrippleAndKnockDown → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresPoison → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresDaze → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresDazeAndBlind → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresWeakness → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresWeaknessAndDeepWound → Wrappers\GwAu3_Data_Wrappers.au3


; RequiresWeaknessAndKnockDown → Wrappers\GwAu3_Data_Wrappers.au3


; SkillRequiresWaterHex → Wrappers\GwAu3_Data_Wrappers.au3


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
; IsBossSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's flash enchant with failure risk if don't have recommended attr points
; IsFlashEnchantFailureSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's a Elite Flash Enchantment skill's
; IsEliteFlashEnchantSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's a Flash Enchantment skill's
; IsFlashEnchantSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's a pve rez skill
; IsRezPveSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's pve degen hex
; IsHexDegenPveSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's pve trap skill
; IsTrapPveSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's pve Ritual skill
; IsRitualPveSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's capture elite skill's
; IsCapEliteSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's pve elite skill
; IsElitePveSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's pve touch skill
; IsTouchPveSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's rest of pve skill
; IsPveSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite Exploit Corpse skill with Health Regen
; IsEliteExploitCorpseHealthRegenSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite exploit corpse with failure riskif don't have recommanded attr
; IsEliteExploitCorpseFailureSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite exploit corpse skill
; IsEliteExploitCorpseSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Exploit corpse skill
; IsExploitCorpseSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite off hand skill
; IsEliteOffHandSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's off hand skill
; IsOffHandSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's condition skill
; IsConditionSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if have risk of failure if don't have 8 points in this attr skill
; IsFailureBelow8Skill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if this spirit skills can rez
; IsRessurectionSpiritSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's half range skill
; IsRessurectionSpellHalfRangeSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if It's Elite Ressurection Spell Skill
; IsEliteRessurectionSpellSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if It's Touch Ressurection Spell
; IsTouchRessurectionSpellSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if It's Ressurection Spell
; IsRessurectionSpellSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if It's Elite Degen Hex
; IsEliteDegenHexSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if It's  Degen Hex
; IsDegenHexSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if We have malus armor when using this preparation skill
; IsPrepLessArmorWhileUsingSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if is the smoke trap skill
; IsSmokeTrapSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Trap skill with piercing damage
; IsTrapPiercingSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite Trap and Ritual skill
; IsElitePrepTrapRitualSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Trap and Ritual skill
; IsPrepTrapRitualSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if We have malus armor when using this skill
; IsLessArmorWhileUsingSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite skill with risk of failure if don't have 4 points in this attr skill
; IsEliteFailureBelow4Skill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite skill with risk of failure if don't have 4 points in this attr skill (And knock down us while using)
; IsFailureBelow4KnockSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's skill with risk of failure if don't have 4 points in this attr skill
; IsFailureBelow4Skill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if we can be Easily Interrupted while using this skill
; IsEasilyInterruptedSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite Half Range Skill
; IsEliteHalfRangeSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Half Range Skill
; IsHalfRangeSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite Touch Skill
; IsEliteTouchSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite Exhaustion skill (Overcast condition)
; IsEliteExhaustionSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Elite skill
; IsEliteSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Exhaustion touch skill (Overcast condition)
; IsExhaustionTouchSkillSkill → Wrappers\GwAu3_Data_Wrappers.au3


;Return True if it's Touch Skill
;Func IsTouchSkillSkill($aSkill)
;~ 	Local $Mspecial = Skill_GetSkillInfo($aSkill, "Special")
;~ 	If IsPtr($aSkill) <> 0 Then
;~ 		Return BitAND(Skill_GetSkillInfo($aSkill, "Special"), 2)
;~ 	ElseIf IsDllStruct($aSkill) <> 0 Then
;~ 		Return BitAND(DllStructGetData($aSkill, 'Special'), 2)
;~ 	Else
;~ 		Return BitAND($Mspecial, 2)
;~ 	EndIf
;EndFunc

;Return True if it's Exhaustion skill (Overcast condition)
; IsExhaustionSkill → Wrappers\GwAu3_Data_Wrappers.au3

#EndRegion Skill Special

#Region Skilltypes
Func IsEnchantRemoveSkill($aSkill) ;
	If IsPtr($aSkill) <> 0 Then
		Local $lSkillEffect2 = Skill_GetSkillInfo($aSkill, "Effect2")
		Local $lSkillID = Skill_GetSkillInfo($aSkill, "SkillID")
	ElseIf IsDllStruct($aSkill) <> 0 Then
		Local $lSkillEffect2 = DllStructGetData($aSkill, 'Effect2')
		Local $lSkillID = DllStructGetData($aSkill, 'ID')
	Else
		Local $lSkillEffect2 = Skill_GetSkillInfo($aSkill, "Effect2")
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

; Interrupts that restore energy on land (Power Drain Effect2=257; others lack that tag).
Func IsEnergyGainRuptSkill($aSkill)
	Local $lID = 0
	If IsPtr($aSkill) Or IsDllStruct($aSkill) Then
		$lID = Skill_GetSkillInfo($aSkill, "SkillID")
	Else
		$lID = Number($aSkill)
	EndIf
	; Power Drain, Leech Signet, Power Leech, Power Return
	Switch $lID
		Case 25, 61, 803, 931
			Return True
	EndSwitch
	Local $lEffect2 = 0
	If IsDllStruct($aSkill) <> 0 Then
		$lEffect2 = DllStructGetData($aSkill, 'Effect2')
	Else
		$lEffect2 = Skill_GetSkillInfo($lID, "Effect2")
	EndIf
	Return $lEffect2 = 257
EndFunc   ;==>IsEnergyGainRuptSkill

; IsEnergyGainSkill → Wrappers\GwAu3_Data_Wrappers.au3


; IsBlockSkill → Wrappers\GwAu3_Data_Wrappers.au3


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

; IsSacrReturniceHeal2Skill → Wrappers\GwAu3_Data_Wrappers.au3


; IsSacrReturniceHealSkill → Wrappers\GwAu3_Data_Wrappers.au3


; IsSacrReturniceSkill → Wrappers\GwAu3_Data_Wrappers.au3


; IsRezSignetSkill → Wrappers\GwAu3_Data_Wrappers.au3


; IsRezSkill → Wrappers\GwAu3_Data_Wrappers.au3


Func IsHealSkill($aSkill)
	; Smite Condition is condition removal (Effect2 4096). Keep it off the heal column so the HP gate does not block it.
	Local $iID = SkillID($aSkill)
	If $iID = $Smite_Condition Or $iID = $Smite_Condition2 Then Return False
	Switch Skill_GetSkillInfo($aSkill, "Effect2")	; Effect 2
		Case 2, 4, 6, 36, 38, 4102, 4096, 6144, 8196, 8198, 14336
			Return True
		Case Else
			Switch SkillID($aSkill)	;
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

; Self / ally / other-ally targeting (prot, heal, etc.) â€” Shame-side cast mode.
Func SkillTargetsSelfOrAlly($aSkill)
	Local $iID = SkillID($aSkill)
	If $iID = 0 Then $iID = Number($aSkill)
	If IsHealSkill($iID) Then Return True
	Switch Number(Skill_GetSkillInfo($iID, "Target"))
		Case $GC_I_SKILL_TARGET_SELF, $GC_I_SKILL_TARGET_ALLY, $GC_I_SKILL_TARGET_OTHER_ALLY, $GC_I_SKILL_TARGET_DEAD_ALLY
			Return True
	EndSwitch
	Return False
EndFunc   ;==>SkillTargetsSelfOrAlly

; Party-heal Target filters (depend on IsPartyHealSkill ID list above).
Func IsSelfHealSkill($aSkill)
	Return IsPartyHealSkill($aSkill) And Not TargetOtherAllySkill($aSkill)
EndFunc   ;==>IsSelfHealSkill

Func IsSelfOnlyHealSkill($aSkill)
	Return IsPartyHealSkill($aSkill) And TargetSelfSkill($aSkill)
EndFunc   ;==>IsSelfOnlyHealSkill

Func IsHealOtherSkill($aSkill)
	Return IsPartyHealSkill($aSkill) And TargetOtherAllySkill($aSkill)
EndFunc   ;==>IsHealOtherSkill

; IsHealMySelfSkill / IsHealAllySkill / IsHexRemovalSkill / IsConditionRemovalSkill
; and Target*Skill → Modules\Data\GwAu3_Data_Wrappers.au3

#EndRegion Skilltypes

#Region HeroCast

;~Precasts prots before or during a fight

Func CacheHeroHeals()
	Out("Mapping your Heroe, that have heal")
	For $aHero = 1 To GetPartySize() -1
		For $aSkillSlot = 1 To 8            ; precast wards and binding rituals
			$aSkillID = Skill_GetSkillbarInfo($aSkillSlot, "SkillID", $aHero)
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
	$BiP[0] = 0
	$BiP[1] = 0
	For $aHero = 1 To GetPartySize() - 1
		For $aSkillSlot = 1 To 8
			If Skill_GetSkillbarInfo($aSkillSlot, "SkillID", $aHero) = $Blood_is_Power Then
				$BiP[0] = $aHero
				$BiP[1] = $aSkillSlot
				Return
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
			$aSkillID = Skill_GetSkillbarInfo($aSkillSlot, "SkillID", $aHero)
			If $aSkillID = 0 Then ContinueLoop
			$aSkillType = Skill_GetSkillInfo($aSkillID, "SkillType")
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

; Same IsProtectiveSkill filter as CacheSkillBar → $ProtSlots; aimed at the player during PrecastWardsAndSpirits.
Func CacheHeroProts()
	Out("Mapping heroes that have prots")
	$HeroProts = 0
	Global $HeroProts[0][3]
	For $aHero = 1 To GetPartySize() - 1
		For $aSkillSlot = 1 To 8
			Local $aSkillID = Skill_GetSkillbarInfo($aSkillSlot, "SkillID", $aHero)
			If $aSkillID = 0 Or Not IsProtectiveSkill($aSkillID) Then ContinueLoop
			ReDim $HeroProts[UBound($HeroProts) + 1][3]
			$HeroProts[UBound($HeroProts) - 1][0] = $aSkillID
			$HeroProts[UBound($HeroProts) - 1][1] = $aHero
			$HeroProts[UBound($HeroProts) - 1][2] = $aSkillSlot
			Party_DisableHeroSkill($aHero, $aSkillSlot)
		Next
	Next
	Out("Hero prots cached: " & UBound($HeroProts))
EndFunc   ;==>CacheHeroProts

Func CacheMysticHealing()
	Out("Mapping Heroes, that have Mystic Healing")
	Sleep(200)
	Local $i = 1
	Local $j = 1
	Local $k = 1
	For $aHero = 1 To UBound(Getparty()) -2
		For $aSkillSlot = 1 To 8
			If Skill_GetSkillbarInfo($aSkillSlot, "SkillID", $aHero) = $Mystic_Healing Then
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

; $aAbortEnemyRange: stop if foes this close (0 = never abort). Staging pulls use $danger_range.
Func PrecastWardsAndSpirits($aAggroRange = $spirit_range, $aAbortEnemyRange = $spirit_range)
	; Never block forever — approach Map_Move can leave Moving=True after CarefulAggro stand.
	Local $lMoveWait = TimerInit()
	Do
		Sleep(50)
	Until Not Agent_GetAgentInfo(-2, "Moving") Or TimerDiff($lMoveWait) > 5000
	; Bars may still be empty if onStart ran before party / load-skills — refresh once.
	If Number($HeroPrecast[0][0]) = 0 Then CacheHeroPrecast()
	If UBound($HeroProts) < 0 Then CacheHeroProts()

	For $aSkillSlot In $Skillbar
		If $SkillBarCache[$aSkillSlot][$precast] = "" Then ContinueLoop
		If ShouldUse($aSkillSlot, $aAggroRange) Then Skill_TryUseSkill($aSkillSlot, $BestTarget)
	Next
	Out("Precasting hero wards and binding rituals (" & Number($HeroPrecast[0][0]) & ")")
	; Skill_UseHeroSkill only flags the next cast — a second flag to the same hero cancels the first.
	Local $lPrevHero = 0, $lPrevSlot = 0, $lPrevSkillID = 0
	For $i = 1 To $HeroPrecast[0][0]
		Local $lHero = $HeroPrecast[$i][1]
		Local $lHeroSlot = $HeroPrecast[$i][2]
		Local $lHeroSkillID = Skill_GetSkillbarInfo($lHeroSlot, "SkillID", $lHero)
		; Binding rituals are spirits, not self-effects — never skip them via GetEffectTimeRemaining.
		Local $lType = Skill_GetSkillInfo($lHeroSkillID, "SkillType")
		If $aAbortEnemyRange > 0 And Agent_IsEnemyNear($aAbortEnemyRange) Then Return
		Out("Hero precast: hero " & $lHero & " slot " & $lHeroSlot & " " & $HeroPrecast[$i][0])
		Skill_UseHeroSkill($lHero, $lHeroSlot, 0)

		; Logic: refresh HR / shouts every 3rd hero skill so echo doesn't drop mid-precast
		If Mod($i, 3) = 0 Then
			If ShouldUse($SkillbarSlot[$Heroic_Refrain]) Then Skill_TryUseSkill($SkillbarSlot[$Burning_Refrain], $BestTarget)
			If ShouldUse($SkillbarSlot[$Burning_Refrain]) Then Skill_TryUseSkill($SkillbarSlot[$Burning_Refrain])
			If ShouldUse($SkillbarSlot[$Theyre_on_Fire]) Then Skill_TryUseSkill($SkillbarSlot[$Theyre_on_Fire])
		EndIf

		Other_PingSleep(1000)
	Next

	; Ally-target prots (PS, Spirit Bond, …) on the player after spirits/wards are down.
	If UBound($HeroProts) >= 0 Then Out("Precasting hero prots on player (" & (UBound($HeroProts) + 1) & ")")

	For $i = 0 To UBound($HeroProts) - 1
		Local $lProtID = $HeroProts[$i][0]
		Local $lProtHero = $HeroProts[$i][1]
		Local $lProtSlot = $HeroProts[$i][2]
		If $aAbortEnemyRange > 0 And Agent_IsEnemyNear($aAbortEnemyRange) Then Return
		If $lProtID <> 0 And GetEffectTimeRemaining($lProtID, -2) > 15000 Then ContinueLoop
		Skill_UseHeroSkill($lProtHero, $lProtSlot, -2)
		ApplyHR()
		Other_PingSleep(1000)
	Next
EndFunc   ;==>PrecastWardsAndSpirits

; Keep casting HR until nobody needs it (NeedEchoAlly) or timeout.
; Wiki: HR reapplied whenever a chant/shout *ends* on that ally — shouts do not cancel the echo.
; ToF / BR are the upkeep; always top them up before return so HR does not fall off during Flag/Precast/Cancel.
; After starting HR (1s activation), sleep activation so the next UseSkill does not interrupt the cast.
Func ApplyHR()
	If $SkillbarSlot[$Heroic_Refrain] = 0 Then Return
	Out("ApplyHR start (Lead=" & Number(Attribute_GetPartyAttributeInfo($Leadership, 0, "Level")) & ")")

	While ShouldUse($SkillbarSlot[$Heroic_Refrain])
        Skill_TryUseSkill($SkillbarSlot[$Heroic_Refrain], $BestTarget)
		If ShouldUse($SkillbarSlot[$Theyre_on_Fire]) Then Skill_TryUseSkill($SkillbarSlot[$Theyre_on_Fire])
		If ShouldUse($SkillbarSlot[$Burning_Refrain]) Then Skill_TryUseSkill($SkillbarSlot[$Burning_Refrain])
		Sleep(11000)
    WEnd
EndFunc   ;==>ApplyHR

;~Precasts bonds before or during a fight
Func PrecastBonds($aTargetAlly = 0)
	Out("Precasting wards and binding rituals")
	For $aHero = UBound(Getparty()) - 1 To 0 Step -1
		For $aSkillSlot = 1 To 8            ; precast bonds
			ApplyHR()
			If GetEffectTimeRemaining(GetEffect(Skill_GetSkillbarInfo($aSkillSlot))) > 0 Then ContinueLoop
			If IsBondSkill(Skill_GetSkillbarInfo($aSkillSlot, "SkillID", $aHero)) Then
				DisableHeroSkillSlot($aHero, $aSkillSlot)
				Skill_UseHeroSkill($aHero, $aSkillSlot, $aTargetAlly)
			EndIf
		Next
	Next
EndFunc   ;==>PrecastBonds

Func UseHeroHeals()
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	For $i = UBound($HeroHeals) - 1 To 0 Step -1
		Out($HeroHeals[$i][0])
		Switch $HeroHeals[$i][0]
			Case $Martyr
				If GetNumberOfConditionedAllies() - Agent_GetAgentInfo(GetHeroID($HeroHeals[$i][1]), "Condition") > 0 Then Skill_UseHeroSkill($HeroHeals[$i][1], $HeroHeals[$i][2], 0)
			Case $Cautery_Signet, $Extinguish
				Out("Burning allies: " & GetNumberOfBurningAllies())
				If GetNumberOfBurningAllies() > 0 Then Skill_UseHeroSkill($HeroHeals[$i][1], $HeroHeals[$i][2], 0)
			Case Else
				; Out("Party Health: " & Party_GetPartyHealth())
				; Out("Lowest HP: " & Floor(Agent_GetAgentInfo(Agent_GetLowestAlly(), "HP") * 100) & "%")
				If Party_GetPartyHealth() < 0.90 Or Agent_GetAgentInfo(Agent_GetLowestAlly(), "HP") < 0.8 Then Skill_UseHeroSkill($HeroHeals[$i][1], $HeroHeals[$i][2], 0)
		EndSwitch
	Next
EndFunc   ;==>UseHeroHeals

Func UseHeroHexRemoval()
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	For $i = UBound($HeroHexRemoval) - 1 To 0 Step -1
		Out($HeroHexRemoval[$i][0])
		Switch $HeroHexRemoval[$i][0]
			Case $Hex_Eater_Signet
				If Skill_GetSkillbarInfo($HeroHexRemoval[$i][2], $HeroHexRemoval[$i][1]) Then
					Skill_UseHeroSkill($HeroHexRemoval[$i][1], $HeroHexRemoval[$i][2], -2)
					ExitLoop
				EndIf
			Case $Shatter_Hex
				; Prefer damage when foes are near, but still strip the hex with no one around.
				If Skill_GetSkillbarInfo($HeroHexRemoval[$i][2], $HeroHexRemoval[$i][1]) And Agent_GetAgentInfo(GetHeroID($HeroHexRemoval[$i][1]), "CurrentEnergy") > 10 Then
					Skill_UseHeroSkill($HeroHexRemoval[$i][1], $HeroHexRemoval[$i][2], -2)
					ExitLoop
				EndIf
			Case Else
				If Skill_GetSkillbarInfo($HeroHexRemoval[$i][2], $HeroHexRemoval[$i][1]) And Agent_GetAgentInfo(-2, "HP") < 0.8 Then
					Skill_UseHeroSkill($HeroHexRemoval[$i][1], $HeroHexRemoval[$i][2], -2)
					ExitLoop
				EndIf
		EndSwitch
	Next
EndFunc

Func UseHeroConditionRemoval()
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	For $i = UBound($HeroConditionRemoval) - 1 To 0 Step -1
		Out($HeroConditionRemoval[$i][0])
	Next
EndFunc

Func MysticHealing()
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	If UBound($MysticHealingArray) - 1 = 0 And $MysticHealingArray[0][1] = "" Then
		Return
	ElseIf UBound($MysticHealingArray) - 1 = 0 And $MysticHealingArray[0][1] <> "" And Agent_GetAgentInfo(-2, "HP") < 0.9 Then
		Skill_UseHeroSkill($MysticHealingArray[0][1], $MysticHealingArray[0][2], 0)
	Else
		If Agent_GetAgentInfo(-2, "HP") < 0.9 And $MysticSwitch = 1 And TimerDiff($MysticTimerTwo) > 2000 Then
			If Agent_GetAgentInfo(-2, "IsDead") Then Return
			If TimerDiff($MysticTimerOne) > 5500 Then
				For $i = 0 To UBound($MysticHealingGroupOne) - 1
					Skill_UseHeroSkill($MysticHealingGroupOne[$i][1], $MysticHealingGroupOne[$i][2], 0)
				Next
				$MysticTimerOne = TimerInit()
			EndIf
			RndSleep(100)
			$MysticSwitch = 2

		ElseIf Agent_GetAgentInfo(-2, "HP") < 0.9 And $MysticSwitch = 2 And TimerDiff($MysticTimerOne) > 2000 Then
			If Agent_GetAgentInfo(-2, "IsDead") Then Return
			If TimerDiff($MysticTimerTwo) > 5500 Then
				For $i = 0 To UBound($MysticHealingGroupTwo) - 1
					Skill_UseHeroSkill($MysticHealingGroupTwo[$i][1], $MysticHealingGroupTwo[$i][2], 0)
				Next
				$MysticTimerTwo = TimerInit()
			EndIf
			RndSleep(100)
			$MysticSwitch = 1
		EndIf
	EndIf

EndFunc   ;==>MysticHealing

#EndRegion HeroCast

