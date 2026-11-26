; How many inventory bags scripts may touch (1..4). Higher bags stay protected from sell/salvage/empty checks.
; Set manually in bots (e.g. Global $UseBags = 3). Bag IDs 1..N = backpack..bagN.
Global $UseBags = 4

; Core Item_CountEmptySlots wants a bag-ID array built from $UseBags.
Func InventoryBagList($aCount = -1)
	If $aCount < 0 Then $aCount = $UseBags
	If $aCount < 1 Then $aCount = 1
	If $aCount > 4 Then $aCount = 4
	Local $lAll[4] = [$GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2]
	Local $lBags[$aCount]
	Local $i
	For $i = 0 To $aCount - 1
		$lBags[$i] = $lAll[$i]
	Next
	Return $lBags
EndFunc   ;==>InventoryBagList
Global $RareSkinsCount = 0
Global $questNPC = 0
; Dialog chain for TalkToNPC / EnterMission / TakeQuest (Logic multi-step pattern):
;   Talk To NPC waypoint → dialog1=wp[2], dialog2=$dialog, dialog3=$dialog3
;   Enter Mission waypoint → dialog1=wp[2], dialog2=$dialog
;   TakeQuest follow-up → $dialog only (Froggy 132, BDS 1, etc.)
; Scripts may override $dialog2/$dialog3 for longer chains; 0 = skip that step.
Global $dialog = 0
Global $dialog2 = 0
Global $dialog3 = 0x84
; Brazier phase / Fight with Torch: when True, AggroMoveToEX may loot the torch (CanPickUpEx).
; Fight with Torch also uses it to drop on martial engage and pick up after; Light Brazier and Drop Torch sets False so we leave it.
Global $PickupTorch = False
Global $droptorch = False
; Throttle timer for AggroMoveToEX "slow progress" Out() spam
Global $g_h_SlowProgressOut = 0
; Set when we die mid-AggroMoveToEX so MoveAndAggro exits the incubi/current WP and snaps to rez shrine after shrine rez.
Global $g_b_DiedOnWaypoint = False

Global $TotalSeconds = 0
Global $CumulatedTime = 0
Global $TimeTotal = TimerInit()
Global $TimeRun = 0
Global $TimeUpdater = 0
Global $bAsuraBlessing = False
Global $bDwarvenBlessing = False
Global $bSunspearsBlessing = False
Global $bLightBringerBlessing = False
Global $aPlayerAgent = Agent_GetAgentInfo(-2, "ID")
Global $nBestRunTime = 5000000
Global $nCurrentRunTime = 0
Global $OpenedChestAgentIDs[1]    ;dirty fix for not using TargetNearestItem() (black list variable as previously opened chests were not targeted using TargetNearestItem(), now they are)
; True when Lit_Torch failed / went out — MoveAndAggro backtracks via RekindleTorch (not "first grab").
Global $unlit = False
Global $lCantMoveCounter = 0
Global $LastWaypoint = 0
;~ Store the value of useful skills for the fight function if present


#Region Movement & Aggro
Func CheckArea($aX, $aY, $aRadius = 500)
    $pX = X()
	$pY = Y()

    If ($pX < $aX + $aRadius) And ($pX > $aX - $aRadius) And ($pY < $aY + $aRadius) And ($pY > $aY - $aRadius) Then
        Return True
    EndIf
    Return False
EndFunc   ;==>CheckArea

#include-once

; Logic-compatible wait: old WaitMapLoading($mapID, $timeout[, $waitAgents])
; GwAu3 Map_WaitMapLoading is ($mapID, $instanceType, $timeout) — do not pass timeout as arg2.

; Legacy Logic name → Modules Map_GetInstanceUpTime (ms).

; Walk into a dungeon/explorable portal until MapID changes.
; Old Portal case called WaitMapLoading(30s) every loop tick — once near the portal coords the
; character stopped moving (already at destination) and stood AFK with no Fight for minutes.
Func EnterPortalWaypoint($aX, $aY, $aTargetMap, $aTimeout = 180000)
	Local $lDeadlock = TimerInit()
	Local $lStartMap = Map_GetMapID()
	Local $lLastOut = 0
	Out("Entering portal → map " & $aTargetMap & " (from " & $lStartMap & ")")

	Do
		If Bot_HaltIfStopped() Then Return False
		If Wipe() Then Return False

		; Loading screen — WaitMapLoading gates skillbar/agents (not just MapID).
		If Map_GetInstanceInfo("Type") = 2 Then
			Out("Portal loading…")
			If Not WaitMapLoading($aTargetMap, 60000) Then Return False
			Out("Portal OK — now on map " & $aTargetMap)
			Return True
		EndIf

		; MapID can flip before skillbar is live — never return on MapID alone (L2 empty-bar race).
		If Map_GetMapID() = $aTargetMap Then
			Out("Portal map ID matched — waiting for skillbar/agents…")
			If WaitMapLoading($aTargetMap, 60000) Then
				Out("Portal OK — now on map " & $aTargetMap)
				Return True
			EndIf
			Return False
		EndIf

		; Keep issuing moves with light jitter so we actually cross the portal volume.
		Map_Move($aX + Random(-40, 40), $aY + Random(-40, 40), 0)

		; Enemies that pull while we wait at the portal — do not stand still.
		If Agent_IsEnemyNear(1350) Then Fight($aX, $aY, 1350)

		If TimerDiff($lLastOut) > 5000 Or $lLastOut = 0 Then
			Out("Portal wait… map=" & Map_GetMapID() & " dist=" & Floor(Agent_GetDistanceToXY($aX, $aY)))
			$lLastOut = TimerInit()
		EndIf
		Sleep(250)
	Until TimerDiff($lDeadlock) > $aTimeout

	Out("Portal timeout — still on map " & Map_GetMapID() & " (wanted " & $aTargetMap & ")")
	Return False
EndFunc   ;==>EnterPortalWaypoint

; Logic ChangeWeaponSet: wait out knockdown, then F-key set 1–4 (0x81–0x84).
Func ChangeWeaponSet($aSet)
	If $aSet < 1 Or $aSet > 4 Then Return False
	Local $lWait = TimerInit()
	While Agent_GetAgentInfo(-2, "IsKnocked") And TimerDiff($lWait) < 5000
		Sleep(100)
	WEnd
	If Agent_GetAgentInfo(-2, "IsDead") Then Return False
	Local $lAction
	Switch $aSet
		Case 1
			$lAction = $GC_I_CONTROL_INVENTORY_ACTIVATE_WEAPON_SET_1
		Case 2
			$lAction = $GC_I_CONTROL_INVENTORY_ACTIVATE_WEAPON_SET_2
		Case 3
			$lAction = $GC_I_CONTROL_INVENTORY_ACTIVATE_WEAPON_SET_3
		Case 4
			$lAction = $GC_I_CONTROL_INVENTORY_ACTIVATE_WEAPON_SET_4
	EndSwitch
	Core_PerformAction($lAction, $GC_I_CONTROL_TYPE_ACTIVATE)
	Return True
EndFunc   ;==>ChangeWeaponSet

; Inventory weapon sets are 0–3 (F1–F4). Returns 1–4 for ChangeWeaponSet, or 0 if none.
Func FindWeaponSetByItemType($aItemType)
	For $s = 0 To 3
		Local $lPtr = Item_GetInventoryInfo("WeaponSet" & $s & "WeaponPtr")
		If $lPtr = 0 Then ContinueLoop
		If Number(Item_GetItemInfoByPtr($lPtr, "ItemType")) = Number($aItemType) Then Return $s + 1
	Next
	Return 0
EndFunc   ;==>FindWeaponSetByItemType

Func MoveAndAggro($aWaypoints, $WipeManagment = True)
	Local $MyOldMap = Map_GetMapID(), $lMapLoadingOld = Map_GetInstanceInfo("Type")
	; Do not clear $PickupTorch / $unlit from nearest-WP name — that desyncs mid-torch / RekindleTorch
	; (standing near Group/Room clears flags → never loot torch → circle). Explicit WP cases + WM set them.

	For $i = GetNearestWaypointIndex($aWaypoints) To UBound($aWaypoints) - 1 Step 1
		If Bot_HaltIfStopped() Then Return
		If Map_GetMapID() <> $MyOldMap Then ExitLoop
		If Map_GetInstanceInfo("Type") == 2 Then Connection_CheckAndReconnect()
		If Map_GetInstanceInfo("Type") <> $lMapLoadingOld Then ExitLoop
		If Not Agent_Exists() Then ExitLoop
		If Cinematic_DetectSkipCinematics() Then ContinueLoop

		; Death / shrine rez: wait if needed, then WipeManagement redirects when rez shrine is inconvenient
		; (SoO, Bogroot, Melandru, …). Do not clamp $i after WipeManagement — that undoes those redirects.
		; Dead with wipe=False still needs this path (Fight used to hold the thread so $i stayed on Thorn/Gokir).
		If $g_b_DiedOnWaypoint Or Agent_GetAgentInfo(-2, "IsDead") Then
			; For...Next / ContinueLoop already stepped past the pad where AggroMoveToEX set DiedOnWaypoint
			; (e.g. died on Boss / Dungeon Key → $i is Exit → WipeManagement wrongly sent Boss lock).
			If $g_b_DiedOnWaypoint And $i > 0 Then
				$LastWaypoint = $i - 1
			Else
				$LastWaypoint = $i
			EndIf
			CancelAll()    ; Logic: clear pull flags when we die (in case we were pulling)
			; Wipe → WipeManagement. Soft death in place → stay on pad. Soft death + shrine dump (nearest << last) → WipeManagement
			; (Room 2 death rez'd at start was "Recovered at Dwarven Blessing" and replayed Chest/Grab Torch).
			If $WipeManagment And Wipe() Then
				GUI_SetWipes(GUI_GetWipes() + 1)
				Out("We wiped at " & $aWaypoints[$LastWaypoint][3] & ", waiting for rezz")
				Local $lDeadlock = TimerInit()
				Do
					Sleep(500)
					If Bot_HaltIfStopped() Then Return
					If TimerDiff($lDeadlock) > 120000 Then Out("Party health "& Party_GetPartyHealth() & "%!")
					; Ally rez makes you alive early — still wait for party HP like Logic (don't Or Not IsDead).
					; Party health 0 is the full wipe; the dungeon shrine-rezzes in place. Do not resign.
				Until Party_GetPartyHealth() > 0.5
				CancelAll()    ; again after shrine rez — flags can stick through death
				$i = WipeManagement($aWaypoints, GetNearestWaypointIndex($aWaypoints), $LastWaypoint)
				Out("Restarting at : " & $aWaypoints[$i][3])
				Sleep(2000)
				ChangeWeaponSet(2)
				Sleep(2000)
			ElseIf Agent_GetAgentInfo(-2, "IsDead") Then
				Out("Soft death at " & $aWaypoints[$LastWaypoint][3] & " — waiting for rez")
				Local $lDeadlock = TimerInit()
				Do
					Sleep(500)
					If Bot_HaltIfStopped() Then Return
					If Party_IsDefeated() Then Return ResignAndReturn()
					If TimerDiff($lDeadlock) > 180000 Then ExitLoop
				Until Not Agent_GetAgentInfo(-2, "IsDead")
				Sleep(500)
				CancelAll()
				Local $lNear = GetNearestWaypointIndex($aWaypoints)
				If $WipeManagment And $lNear + 2 < $LastWaypoint Then
					$i = WipeManagement($aWaypoints, $lNear, $LastWaypoint)
					Out("Shrine dump after soft death — WipeManagement to " & $aWaypoints[$i][3])
				Else
					$i = $LastWaypoint
					Out("Resume fighting at : " & $aWaypoints[$i][3])
				EndIf
				If Agent_GetAgentInfo(-2, "IsDead") Then
					Sleep(500)
					$i -= 1
					ContinueLoop
				EndIf
				Sleep(2000)
				ChangeWeaponSet(2)
				Sleep(2000)
			ElseIf $g_b_DiedOnWaypoint Then
				CancelAll()
				Local $lNear = GetNearestWaypointIndex($aWaypoints)
				If $WipeManagment And $lNear + 2 < $LastWaypoint Then
					$i = WipeManagement($aWaypoints, $lNear, $LastWaypoint)
					Out("Shrine dump on recover — WipeManagement to " & $aWaypoints[$i][3])
				Else
					$i = $LastWaypoint
					Out("Recovered — resume fighting at : " & $aWaypoints[$i][3])
				EndIf
				Sleep(2000)
				ChangeWeaponSet(2)
				Sleep(2000)
			EndIf
			$g_b_DiedOnWaypoint = False
			; Keep $PickupTorch / $unlit across soft death — clearing by pad name broke rekindle after Group/Room deaths.
		EndIf

		; (SoO only) unlit effect intercept - backtracks until lit effect is reapplied and resumes at light torch waypoint
		If $unlit Then $i = RekindleTorch($aWaypoints, GetNearestWaypointIndex($aWaypoints))

		Out("Nearest waypoint - " & $aWaypoints[GetNearestWaypointIndex($aWaypoints)][3])
		Out("Moving to - " & $aWaypoints[$i][3])

		Switch ($aWaypoints[$i][3])
			Case "Function Call"            ; Calls the function defined in the third column of the Waypoint array
				Call($aWaypoints[$i][2])

			Case "Function Call with Coordinates"    ; Calls the function defined in the third column of the Waypoint array with coordinate parameters
				Call($aWaypoints[$i][2], $aWaypoints[$i][0], $aWaypoints[$i][1])

			Case "Flag Heroes Away"	; Flags heroes and waits for them to reach destination
				CommandAll($aWaypoints[$i][0], $aWaypoints[$i][1], True, $aWaypoints[$i][2])
				Out("Waiting for heroes to reach destination")

			Case "Flag Heroes"
				CommandAll($aWaypoints[$i][0], $aWaypoints[$i][1])

			Case "Flag Hero"
				CommandHero($aWaypoints[$i][2], $aWaypoints[$i][0], $aWaypoints[$i][1])

			Case "Unflag Heroes"
				CancelAll()

			Case "Hero Skill"
				UseHeroSkill($aWaypoints[$i][0], $aWaypoints[$i][1])

			Case "Random Boss 1", "Room 1 - Boss", "Room 2 - Boss", "Room 3 - Boss", "Room 4 - Boss", "Room 5 - Boss", "Room 6 - Boss", "Room 7 - Boss"
				If GetBossSF() <> 0 Then AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Backtracking"                                ; use to backtrack without replicating existing waypoints
				For $j = $aWaypoints[$i][0] To $aWaypoints[$i][1] Step -1
					Out("Backtracking - " & $aWaypoints[$j][3])
					AggroMoveToEX($aWaypoints[$j][0], $aWaypoints[$j][1], $aWaypoints[$j][2])
				Next

			Case "Skip Cinematic"
				Map_Move($aWaypoints[$i][0], $aWaypoints[$i][1])
				Cinematic_WaitSkipCinematic()
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Accept Items"
				AcceptAllItems()

			Case "Boss lock", "Boss Lock"
				; Exclude loot chests — log showed "Going to Locked Chest" at 3441 instead of Boss Lock.
				If Wipe() = 0 Then Agent_GoToSignpostNearXY($aWaypoints[$i][0], $aWaypoints[$i][1], True)
				Sleep(1000)
				PickupLootEx(3000)

			Case "Chest", "Signpost"
				If Wipe() = 0 Then Agent_GoToSignpostNearXY($aWaypoints[$i][0], $aWaypoints[$i][1], False)
				Sleep(1000)
				PickupLootEx(3000)

			Case "End Chest"
				If Agent_GetNumberOfEnemies(1250) = 0 And GetEndChest <> 0 And Wipe() = 0 Then Endchest($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Chest and Reward"
				If Agent_GetAgentInfo(-2, "IsDead") Or Wipe() Then ContinueLoop
				; Clear leftovers (empty Case used to fall through → SoOLevel3 restart spam).
				If Agent_GetNumberOfEnemies(1250) > 0 Then AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], 1250)
				If GetEndChest() = 0 Then
					; Locked Chest 8141 is ignored — wait for real dungeon ExtraType.
					Out("Chest and Reward: waiting for dungeon chest spawn")
					Local $lChestWait = TimerInit()
					Do
						If Bot_HaltIfStopped() Or Agent_GetAgentInfo(-2, "IsDead") Or Wipe() Then ExitLoop
						Sleep(500)
					Until GetEndChest() <> 0 Or TimerDiff($lChestWait) > 60000
				EndIf
				If GetEndChest() <> 0 Then
					Return ChestAndReward($aWaypoints, $aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $questNPC)
				EndIf
				; No chest: fall through. Next MoveAndAggro starts at GetNearestWaypointIndex (KillFendi if still there).

			Case "PrecastUpkeep"
				PrecastUpkeep()

			Case "Precast"
				Precast()

			Case "Grab Torch and Light Next Brazier"    ; Grab torch before lighting; keeps $PickupTorch True for loot recovery
				$PickupTorch = True
				LightBrazier($aWaypoints[$i][0], $aWaypoints[$i][1], True)

			Case "Light Brazier"                        ; Light brazier closest to coords
				LightBrazier($aWaypoints[$i][0], $aWaypoints[$i][1], False)

			Case "Light Brazier and Drop Torch"            ; light then leave torch (Logic: always DropBundle after the poke)
				$PickupTorch = False
				LightBrazier($aWaypoints[$i][0], $aWaypoints[$i][1], False, True)

			; Martial: drop on engage + pick up after (AggroMoveToEX). Casters keep torch. Same flag enables torch loot.
			Case "Fight with Torch", "Fight and Grab Torch", "Drop Torch and Aggro"
				$PickupTorch = True
				; Ensure torch is in hand after Clear Spawn / loot — otherwise engage skips drop.
				If Agent_IsMartialPrimary(-2) And Not HoldingBundle() Then PickupTorch()
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				$PickupTorch = False

			Case "Grab Torch"
				$PickupTorch = True
				PickupTorch()

			Case "Drop Keg"
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				Sleep(500)
				DropBundle()
				Sleep(500)

			Case "Wait"
				Sleep($aWaypoints[$i][2])

			Case "Change Weapon"
				Sleep(250)
                ChangeWeaponSet($aWaypoints[$i][2])
				Sleep(250)

;~ NPC INTERACTIONS
			Case "Go to NPC"
				Agent_GoToNPCnearXY($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], False)

			Case "NPC at Coords"
				Agent_GoToNPCnearXY($aWaypoints[$i][0], $aWaypoints[$i][1], $questNPC)

			Case "Follow NPC Until Coords"
				$npcPtr = Agent_GetNearestNPCToXY()
				Do
					CampNPC($npcPtr, $aWaypoints[$i][2])
				Until Agent_GetDistanceToXY($aWaypoints[$i][0], $aWaypoints[$i][1]) < 500

			Case "Talk To NPC by Player Number"
				; dialog1=wp[1], dialog2 skipped (0), player=wp[0], dialog3=$dialog3
				TalkToNPC(X(), Y(), $aWaypoints[$i][1], 0, $aWaypoints[$i][0], $dialog3)

			Case "Talk To NPC"
				; dialog1=wp[2], dialog2=$dialog (script global), player=$questNPC, dialog3=$dialog3
				TalkToNPC($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $dialog, $questNPC, $dialog3)

			Case "Dialog"
				Dialog($aWaypoints[$i][2])

			Case "Take Quest"
				; Logic: quest-log hygiene belongs at the take-quest step (activate mid-quest / abandon completed).
				CheckForQuest($aWaypoints[$i][2], True)
				TakeQuest($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $questNPC)

			Case "Take NPC Quest"
				CheckForQuest($aWaypoints[$i][1], True)
				TakeQuest(X(), Y(), $aWaypoints[$i][1], $aWaypoints[$i][0])

			Case "Update Quest"
				UpdateQuest($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $questNPC)

			Case "Reward"
				GetReward($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $questNPC)

			Case "NPC Reward"
				GetReward(X(), Y(), $aWaypoints[$i][1], $aWaypoints[$i][0])

			Case "Asuran Blessing"
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				If Wipe() = 0 Then Effect_GetAsuranBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
				ApplyHR()

			Case "Dwarven Blessing"
				If Wipe() = 0 Then Effect_GetDwarvenBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
				ApplyHR()

			Case "Norn Blessing"
				If Wipe() = 0 Then Effect_GetNornBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
				ApplyHR()

			Case "Vanguard Blessing"
				If Wipe() = 0 Then Effect_GetVanguardBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
				ApplyHR()

			Case "Sunspears Blessing"
				If Wipe() = 0 Then GEffect_etSunspearsBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
				ApplyHR()

			Case "LightBringer Blessing"
				If Wipe() = 0 Then Effect_GetLightBringerBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
				ApplyHR()

			Case "Kurzicks Blessing"
				If Wipe() = 0 Then Effect_GetKurzicksBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
				ApplyHR()

			Case "Luxon Blessing"
				If Wipe() = 0 Then Effect_GetLuxonsBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
				ApplyHR()

;~ MISSION AND TRAVEL
			Case "Setup"
				Setup($aWaypoints[$i][2], True)

			Case "Map Travel"
				Out("Traveling to " & $MAP_ID[$aWaypoints[$i][2]])
				Map_TravelTo($aWaypoints[$i][2])
				Return True

			Case "Portal"                        ; Each waypoint array should end with a "portal" waypoint with the mapID as a parameter
				If Not EnterPortalWaypoint($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2]) Then
					If Wipe() Then ExitLoop
				EndIf
				; Map changed — leave MoveAndAggro so the farm Switch can start the next level.
				If Map_GetMapID() <> $MyOldMap Then ExitLoop

			Case "Enter Mission"
				EnterMission($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $dialog, $questNPC)

			Case "Enter Challenge"
				EnterChallenge(False)
				Do
					Sleep(Random(750, 1250, 1))
				Until Map_GetInstanceInfo("Type") = 1 And Agent_Exists(-2)

			Case "Wait for Loading"
				Do
					Sleep(100)
				Until WaitMapLoading($aWaypoints[$i][2], 30000)

;~ MOVEMENT AND AGGRO

			Case "Move 55 HP"
				If Agent_GetAgentInfo(-2, "Dead") Or TimerDiff($lDeadlock) > 240000 Then Return ResignAndReturn()
				Move55HP($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Move to", "Location"
				Agent_MoveToXY($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Move and Survive"
				MoveAndSurvive($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Move, Survive and Wait"
				MoveAndSurvive($aWaypoints[$i][0], $aWaypoints[$i][1])
				Sleep($aWaypoints[$i][2])

			Case "Clear Spawn"    ; use to ensure enemies are being targeted within a wider radius
				; Martial needs drop/pickup here too — do not rely on leftover $PickupTorch from braziers.
				$PickupTorch = True
				$nearestenemy = Agent_GetNearestAgent(-2, 0xDB, 3)
				Out(Floor(Agent_GetDistance(-2)))
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $longbow_Range)
				While Agent_GetNumberOfEnemies($aWaypoints[$i][2]) > 0
					Out(Agent_GetNumberOfEnemies($aWaypoints[$i][2]))
					AggroMoveToEX(X(Agent_GetNearestAgent(-2, 0xDB, 3)), Y(Agent_GetNearestAgent(-2, 0xDB, 3)), $aWaypoints[$i][2])
				WEnd
				$PickupTorch = False

			Case "Kite Enemies"
				Move_ToCoord($aWaypoints[$i][0], $aWaypoints[$i][1])
				Do
					Sleep(100)
				Until Agent_GetNumberOfEnemies($aWaypoints[$i][2]) > 0

			Case "Brace for Enemies"
				BraceForEnemies($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Vigilant"
				Out("Stay here and fight " & $aWaypoints[$i][2] & "ms")
				VigilantSleep($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Camp Area"
				Out("Stay here and fight " & $aWaypoints[$i][2] & "ms")
				If Agent_GetNumberOfEnemies(5000) = 0 Then ContinueLoop        ; ensures we don't wait when we come back to the waypoint after a wipe
				VigilantSleep($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Pull Group"    ; pack sits at longbow of pad — spellcasting missed them; spirit_range (2500) covers pull without room_range next group.
				If Agent_GetNumberOfEnemiesNearXY($aWaypoints[$i][0], $aWaypoints[$i][1], $spirit_range) = 0 Then
					Out("Pull Group: no enemies within spirit range of pad — skip bow pull")
					AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $spellcasting_range)
				Else
					PullGroup($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				EndIf

			Case "Pull Enemies"    ; uses a more complex function that calculates hero coordinates automatically based on aggro range
				Out(Agent_GetNumberOfEnemies(3000) & " enemies within " & $aWaypoints[$i][2] & " distance")
				PullEnemies($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Careful Aggro"
				; Wipe/rezz restart: skip flag/stand/precast when nothing is left at this pad.
				If Agent_GetNumberOfEnemiesNearXY($aWaypoints[$i][0], $aWaypoints[$i][1], $spellcasting_range) = 0 Then
					Out("Careful Aggro: no enemies near pad — skip careful")
					AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				Else
					CarefulAggro($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				EndIf

			Case "Follow"
				FollowPartyLeader($aWaypoints[$i][2], $i)

			Case "Boss", "Boss / Dungeon Key"
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $longbow_range)
				While Agent_GetBoss() > 0
					If Bot_HaltIfStopped() Then Return
					CarefulAggro($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
					AggroMoveToEX(X(Agent_GetBoss()), Y(Agent_GetBoss()), $longbow_range)
				WEnd
		;~ SKILLS
			Case "Apply Heroic Refrain"
				ApplyHR()

			Case Else
				If Map_GetInstanceInfo("Type") = 1 Then AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				If Map_GetInstanceInfo("Type") = 0 Then Move_ToCoord($aWaypoints[$i][0], $aWaypoints[$i][1])
		EndSwitch
	Next
EndFunc   ;==>MoveandAggro

Func MoveandAggro_Light($aWaypoints, $WipeManagment = True)
	; Same as MoveAndAggro: never clear torch flags from nearest-WP name.
	For $i = GetNearestWaypointIndex($aWaypoints) To UBound($aWaypoints) - 1 Step 1
		If Bot_HaltIfStopped() Then Return
		If Map_GetInstanceInfo("Type") == 2 Then Connection_CheckAndReconnect()
		If $g_b_DiedOnWaypoint Or Agent_GetAgentInfo(-2, "IsDead") Then
			; For...Next already stepped past the pad where DiedOnWaypoint was set.
			If $g_b_DiedOnWaypoint And $i > 0 Then
				$LastWaypoint = $i - 1
			Else
				$LastWaypoint = $i
			EndIf
			CancelAll()    ; Logic: clear pull flags when we die
			If $WipeManagment And Wipe() Then
				GUI_SetWipes(GUI_GetWipes() + 1)
				Out("We wiped at " & $aWaypoints[$LastWaypoint][3] & ", waiting for rezz")
				Local $lDeadlock = TimerInit()
				Do
					Sleep(500)
					If Bot_HaltIfStopped() Then Return
					If TimerDiff($lDeadlock) > 120000 Then Out("Party heath "& Party_GetPartyHealth() & "%!")
				Until Party_GetPartyHealth() > 0.5
				CancelAll()    ; again after shrine rez
				$i = WipeManagement($aWaypoints, GetNearestWaypointIndex($aWaypoints), $LastWaypoint)
				Out("Restarting at : " & $aWaypoints[$i][3])
				Sleep(2000)
				ChangeWeaponSet(2)
				Sleep(2000)
			ElseIf Agent_GetAgentInfo(-2, "IsDead") Then
				Out("Soft death at " & $aWaypoints[$LastWaypoint][3] & " — waiting for rez")
				Local $lDeadlock = TimerInit()
				Do
					Sleep(500)
					If Bot_HaltIfStopped() Then Return
					If Party_IsDefeated() Then Return ResignAndReturn($Outpost, $Language)
					If TimerDiff($lDeadlock) > 180000 Then ExitLoop
				Until Not Agent_GetAgentInfo(-2, "IsDead")
				Sleep(500)
				CancelAll()
				Local $lNear = GetNearestWaypointIndex($aWaypoints)
				If $WipeManagment And $lNear + 2 < $LastWaypoint Then
					$i = WipeManagement($aWaypoints, $lNear, $LastWaypoint)
					Out("Shrine dump after soft death — WipeManagement to " & $aWaypoints[$i][3])
				Else
					$i = $LastWaypoint
					Out("Resume fighting at : " & $aWaypoints[$i][3])
				EndIf
				If Agent_GetAgentInfo(-2, "IsDead") Then
					Sleep(500)
					$i -= 1
					ContinueLoop
				EndIf
				Sleep(2000)
				ChangeWeaponSet(2)
				Sleep(2000)
			ElseIf $g_b_DiedOnWaypoint Then
				CancelAll()
				Local $lNear = GetNearestWaypointIndex($aWaypoints)
				If $WipeManagment And $lNear + 2 < $LastWaypoint Then
					$i = WipeManagement($aWaypoints, $lNear, $LastWaypoint)
					Out("Shrine dump on recover — WipeManagement to " & $aWaypoints[$i][3])
				Else
					$i = $LastWaypoint
					Out("Recovered — resume fighting at : " & $aWaypoints[$i][3])
				EndIf
				Sleep(2000)
				ChangeWeaponSet(2)
				Sleep(2000)
			EndIf
			$g_b_DiedOnWaypoint = False
		EndIf

		If $unlit Then $i = RekindleTorch($aWaypoints, GetNearestWaypointIndex($aWaypoints))

		Out("Nearest waypoint - " & $aWaypoints[GetNearestWaypointIndex($aWaypoints)][3])
		Out("Moving to - " & $aWaypoints[$i][3])
		Switch ($aWaypoints[$i][3])
			Case "Function Call"
				Call($aWaypoints[$i][2])
			Case "Function Call with Coordinates"
				Call($aWaypoints[$i][2], $aWaypoints[$i][0], $aWaypoints[$i][1])
			Case "Move 55 HP"
				If Agent_GetAgentInfo(-2, "IsDead") Or TimerDiff($lDeadlock) > 240000 Then Return ResignAndReturn($Outpost, $Language)
				Move55HP($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
			Case "Move to", "Location"
				Move_ToCoord($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
			Case "Go to NPC"
				Agent_GoToNPCnearXY($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], False)
			Case "Talk To NPC"
				TalkToNPC($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $dialog, $questNPC, $dialog3)
			Case "Flag Heroes"
				CommandAll($aWaypoints[$i][0], $aWaypoints[$i][1])
			Case "Boss lock", "Boss Lock"
				If Wipe() = 0 Then Agent_GoToSignpostNearXY($aWaypoints[$i][0], $aWaypoints[$i][1], True)
				PickupLootEx()
			Case "Chest", "Signpost"
				If Wipe() = 0 Then Agent_GoToSignpostNearXY($aWaypoints[$i][0], $aWaypoints[$i][1], False)
				PickupLootEx()
			Case "PrecastUpkeep"
				PrecastUpkeep()
			Case "Wait"
				Sleep($aWaypoints[$i][2])
			Case "Chest and Reward"
				If Agent_GetAgentInfo(-2, "IsDead") Or Wipe() Then ContinueLoop
				If Agent_GetNumberOfEnemies(3000) > 0 Then AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], 1250)
				If GetEndChest() = 0 Then
					Out("Chest and Reward: waiting for dungeon chest spawn")
					Local $lChestWaitLite = TimerInit()
					Do
						If Bot_HaltIfStopped() Or Agent_GetAgentInfo(-2, "IsDead") Or Wipe() Then ExitLoop
						Sleep(500)
					Until GetEndChest() <> 0 Or TimerDiff($lChestWaitLite) > 60000
				EndIf
				If GetEndChest() <> 0 Then
					Return ChestAndReward($aWaypoints, $aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $questNPC)
				EndIf
			Case "Take Quest"
				CheckForQuest($aWaypoints[$i][2], True)
				TakeQuest($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $questNPC)
			Case "Asuran Blessing"
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				If Wipe() = 0 Then Effect_GetAsuranBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
			Case "Dwarven Blessing"
				If Wipe() = 0 Then Effect_GetDwarvenBlessing($aWaypoints[$i][0], $aWaypoints[$i][1])
			Case "Portal"
				If Not EnterPortalWaypoint($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2]) Then
					If Wipe() Then ExitLoop
				EndIf
				; MoveandAggro_Light has no map-change ExitLoop; return so farm Switch can run next level.
				If Map_GetMapID() = $aWaypoints[$i][2] Then Return
			Case "Boss", "Boss / Dungeon Key"
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $longbow_range)
				While Agent_GetBoss() > 0
					If Bot_HaltIfStopped() Then Return
					Agent_MoveToDistanceAway($longbow_range, Agent_GetBoss($aWaypoints[$i][2]))
					AggroMoveToEX(X(Agent_GetBoss()), Y(Agent_GetBoss()), $longbow_range)
				WEnd
			Case Else
				If Map_GetInstanceInfo("Type") = 1 Then AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])
				If Map_GetInstanceInfo("Type") = 0 Then Move_ToCoord($aWaypoints[$i][0], $aWaypoints[$i][1])
		EndSwitch
	Next
EndFunc   ;==>MoveandAggro_Light

;~Run and aggro management for chest running
Func MoveChestrunning($aWaypoints, $UseHoS = False)

	For $i = GetNearestWaypointIndex($aWaypoints) To UBound($aWaypoints) - 1 Step 1
		If Bot_HaltIfStopped() Then Return
		If Map_GetInstanceInfo("Type") == 2 Then Connection_CheckAndReconnect()

		If Agent_GetAgentInfo(-2, "IsDead") And $aWaypoints[$i][3] <> "Please Go Die" And $aWaypoints[$i][3] <> "Wait for Rez" Then Return ResignAndReturn($Outpost, $Language)

		Out("Nearest waypoint - " & $aWaypoints[$NearestWaypoint][3])
		Out("Moving to - " & $aWaypoints[$i][3])

		Switch ($aWaypoints[$i][3])
			Case "Function Call"            ; Calls the function defined in the third column of the Waypoint array
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				Call($aWaypoints[$i][2])

			Case "Function Call with Coordinates"    ; Calls the function defined in the third column of the Waypoint array with coordinate parameters
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				Call($aWaypoints[$i][2], $aWaypoints[$i][0], $aWaypoints[$i][1])

			Case "Find The Damn Chest"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				CheckForChest(True)

			Case "Please Go Die" ; Move to your death
				Move_ToCoord($aWaypoints[$i][0], $aWaypoints[$i][1])
				Do
					Sleep(250)
				Until Agent_GetAgentInfo(-2, "Dead")

			Case "Wait for Rez"    ; Wait to get ressurected
				Do
					Sleep(250)
				Until Not Agent_GetAgentInfo(-2, "Dead")

			Case "Normal Movement"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				Move_ToCoord($aWaypoints[$i][0], $aWaypoints[$i][1])

			Case "Flag Heroes"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				CommandAll($aWaypoints[$i][0], $aWaypoints[$i][1])

			Case "Flag Hero"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				CommandHero($aWaypoints[$i][2], $aWaypoints[$i][0], $aWaypoints[$i][1])

			Case "Unflag Heroes"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				CancelAll()

			Case "Backtracking"                                ; use to backtrack without replicating existing waypoints
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				For $j = $aWaypoints[$i][0] To $aWaypoints[$i][1] Step -1
					Out("Backtracking - " & $aWaypoints[$j][3])
					MoveAndSurvive($aWaypoints[$j][0], $aWaypoints[$j][1], $aWaypoints[$j][2], $UseHoS)
				Next

			Case "Take Quest"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				CheckForQuest($aWaypoints[$i][2], True)
				TakeQuest($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $questNPC)

			Case "Take NPC Quest"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				CheckForQuest($aWaypoints[$i][1], True)
				TakeQuest(X(), Y(), $aWaypoints[$i][1], $aWaypoints[$i][0])

			Case "Select quest"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				Dialog($aWaypoints[$i][2])

			Case "Skip Cinematic"
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				Map_Move($aWaypoints[$i][0], $aWaypoints[$i][1])
				Cinematic_WaitSkipCinematic()
				MoveAndSurvive($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $UseHoS)

			Case "Map Travel"
				Out("Traveling to " & $MAP_ID[$aWaypoints[$i][2]])
				Map_TravelTo($aWaypoints[$i][2], $Language)
				Return True

			Case "Portal"                        ; Each waypoint array should end with a "portal" waypoint with the mapID as a parameter
				If Not EnterPortalWaypoint($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2]) Then
					If Wipe() Then ExitLoop
				EndIf
				If Map_GetMapID() = $aWaypoints[$i][2] Then Return

			Case "Aggro"
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2])

			Case "Use Skill"
				If ShouldUse($SkillbarSlot[$aWaypoints[$i][2]]) Then  UseSkills($SkillbarSlot[$aWaypoints[$i][2]])

			Case Else
				If Agent_GetAgentInfo(-2, "Dead") Then Return
				MoveAndSurvive($aWaypoints[$i][0], $aWaypoints[$i][1], $aWaypoints[$i][2], $UseHoS)
		EndSwitch
	Next
EndFunc   ;==>MoveChestrunning

Func WipeManagement($aWaypoints, $NearestWaypoint, $LastWaypoint)                     ; after a wipe, converts nearest waypoint to the desired waypoint based on last waypoint
	Out("Last waypoint - " & $aWaypoints[$LastWaypoint][3])
	; Wipe rewrite walks AggroMoveToEX — do not loot torches mid-path. Switch re-sets $PickupTorch on Fight/Grab pads.
	$PickupTorch = False
	$droptorch = False
	$unlit = False

	Switch Map_GetMapID()
		Case $Shards_of_Oor_Lvl1
			Switch $LastWaypoint
				Case 14 To 20                                                           ; on level 1, when wiping before portal need to restart from before boss lock
					Return 14
				Case "Rezz Shrine"
					If $NearestWaypoint <> 0 Then Return 10                               ; it is possible we get rezzed to the first rezz shrine instead of second one
			EndSwitch

		Case $Shards_of_Oor_Lvl2
			; Logic: AggroMoveToEX rewrite only — never Return into Light Brazier Switch without a torch
			; (that sets $unlit → RekindleTorch → Grab Torch and Light → fail → loop).
			Switch $aWaypoints[$LastWaypoint][3]
				Case "Clear Spawn"
					Out("Died at cemetery")
					For $j = 4 To 12                                                                    ; go from chest to clearing spawn again
						Out("Going back to last waypoint. Moving to " & $aWaypoints[$j][3])
						AggroMoveToEX($aWaypoints[$j][0], $aWaypoints[$j][1], $aWaypoints[$j][2])
					Next
					Return $j                                                                           ; resume regular loop at Fight with Torch
				Case "Fight with Torch", "Fight and Grab Torch", "Drop Torch and Aggro", "Braziers", "Light Brazier", "Light Brazier and Drop Torch", "Boss / Dungeon Key"
					; Before key: walk path, skip first Light Brazier pads (8..12), land on Fight with Torch so Switch PickupTorch runs before Braziers.
					Out("Died at before dungeon key")
					For $j = 4 To 13
						If $j = 8 Then $j = 13                                                           ; skip first brazier lighting + Clear Spawn
						Out("Going back to last waypoint. Moving to " & $aWaypoints[$j][3])
						AggroMoveToEX($aWaypoints[$j][0], $aWaypoints[$j][1], $aWaypoints[$j][2])
					Next
					Return $j + 1                                                                       ; resume at next Fight with Torch
				Case "Exit", "Last Group", "Last group", "Careful Aggro", "Boss lock", "Boss Lock", "Portal"
					; Mislabel / shrine mid-map: treat as before-key (do not walk to portal without key path).
					Switch $aWaypoints[$NearestWaypoint][3]
						Case "Braziers", "Light Brazier", "Light Brazier and Drop Torch", "Boss / Dungeon Key", "Fight with Torch", "Fight and Grab Torch", "Clear Spawn", "Grab Torch", "Brigand", "Dwarven Blessing"
							Out("Died labeled post-key but nearest is mid-level (" & $aWaypoints[$NearestWaypoint][3] & ") — before-key rewrite")
							For $j = 4 To 13
								If $j = 8 Then $j = 13
								Out("Going back to last waypoint. Moving to " & $aWaypoints[$j][3])
								AggroMoveToEX($aWaypoints[$j][0], $aWaypoints[$j][1], $aWaypoints[$j][2])
							Next
							Return $j + 1
					EndSwitch
					; After key: skip all brazier lighting, walk to boss lock approach
					Out("Died at last group before portal")
					For $j = 4 To UBound($aWaypoints) - 6
						If $j = 8 Then $j = UBound($aWaypoints) - 7                                      ; skip braziers → boss lock
						Out("Going back to last waypoint. Moving to " & $aWaypoints[$j][3])
						AggroMoveToEX($aWaypoints[$j][0], $aWaypoints[$j][1], $aWaypoints[$j][2])
					Next
					Return $j + 1
			EndSwitch

		Case $Shards_of_Oor_Lvl3
			; Careful Aggro inserted after Group 1 (+1 vs Logic). Pull Group = index 6.
			Switch $LastWaypoint
				Case 1 To 5
					Out("Died before rezz shrine")
					Return 1							; Group 1 — re-stage then Careful Aggro
				Case 6 To 26
					; Pull Group → Room 2 / second torch — skip Chest + Grab Torch + Light (Logic Return Pull Group).
					Out("Died before running the torch — resume at Pull Group")
					For $j = 0 To UBound($aWaypoints) - 1
						If $aWaypoints[$j][3] = "Pull Group" Then Return $j
					Next
					Return 6
				Case 41 To 45
					Out("Died before getting the key")		; return to Last Group / key area
					Return UBound($aWaypoints) - 8
				Case 46 To 49
					; Mid-map Rezz Shrine is before Boss lock — never resume there (torch run). Logic: UBound-6.
					Local $lFendiRestart = UBound($aWaypoints) - 6
					If $NearestWaypoint >= $lFendiRestart Then
						Out("Died at Bone Dragons / Fendi — already near approach (" & $aWaypoints[$NearestWaypoint][3] & ")")
						Return $NearestWaypoint
					EndIf
					Out("Died at Bone Dragons / Fendi — resume at " & $aWaypoints[$lFendiRestart][3])
					Return $lFendiRestart
				Case Else
					; Room 3 / Second / Third / mid-shrine / final Light Brazier — Logic UBound-23; name-stable Room 3.
					Out("Died in Room 3 / mid-shrine — resume at Room 3")
					For $j = 0 To UBound($aWaypoints) - 1
						If $aWaypoints[$j][3] = "Room 3" Then Return $j
					Next
					Return UBound($aWaypoints) - 23
			EndSwitch

		Case $Bogroot_Growths_Lvl1
			Switch $aWaypoints[$NearestWaypoint][3]
				Case "Gokir"
					Return 9
			EndSwitch

		Case $Bogroot_Growths_Lvl2
			Switch $aWaypoints[$NearestWaypoint][3]
				Case "Dwarven Blessing", "Ayahuasca/Incubus"
					Return 1
			EndSwitch

		Case $Melandrus_Hope
			Switch $aWaypoints[$LastWaypoint][3]
				Case "Function Call with Coordinates", "Farming Spot", "Map Travel"
					Return 3
			EndSwitch

	EndSwitch
	Return $NearestWaypoint
EndFunc   ;==>WipeManagement

;~ Resign via chat, then travel back to outpost (farm scripts set Global $Outpost).
Func Resign()
	Chat_SendChat('resign', '/')
EndFunc   ;==>Resign

Func ResignAndReturn($aMapID = 0, $aLanguage = -1, $aRegion = -1)
	Out("Resigning")
	Resign()
	If $GUI_RunCounter > 0 Then GUI_SetFailCounter()
	Other_PingSleep(5000)
	Out("Returning To Outpost")
	If $aLanguage = -1 Then $aLanguage = Map_GetCharacterInfo("Language")
	If $aRegion = -1 Then $aRegion = Map_GetCharacterInfo("Region")
	If $aMapID = 0 And IsDeclared("Outpost") Then $aMapID = Eval("Outpost")
	If $aMapID = 0 Then
		Map_ReturnToOutpost()
		Sleep(1000)
		WaitMapLoading(-1, 10000)
	Else
		Map_TravelTo($aMapID, $aLanguage, $aRegion)
	EndIf
	If $GUI_RunCounter > 0 Then
		GUI_SetAvgRunTime(AvgRunTime())
		AdlibUnRegister("CurrentRunTime")
	EndIf
EndFunc   ;==>ResignAndReturn

;~O ptionally loads best skill template using the hero build declared under $herobuild global variable
;~ 1= $PISurge, 2= $PISurgeRezz, 3= $PanicSurge, 4= $ROJ, 5= $DualRoJ, 6= $Signets, 7= $HeroicRefrain, 8= $DOASoloSupport
Func Setup($aMapID = $Outpost, $loadskilltemplate = True)
	If GUI_IsSellChecked() And Item_CountEmptySlots(InventoryBagList()) < 25 Then Trade_ClearInventory()
	Map_TravelTo($aMapID)
	Sleep(500)
	;~ CheckForQuest($quest)
	If $loadskilltemplate And $GUI_RunCounter = 0 And GUI_IsLoadSkillsChecked() Then LoadBestSkillTemplate()
	; Modules: Ui_SetDifficulty(True/False). Legacy Game_SwitchMode(2) is not a valid difficulty (0=NM, 1=HM).
	Local $lHM = GUI_IsHMChecked()
	Ui_SetDifficulty($lHM)
	Out("Setup: Hard Mode " & ($lHM ? "ON" : "OFF") & " (IsHardMode=" & Party_GetPartyContextInfo("IsHardMode") & ")")
EndFunc   ;==>Setup


Func Agent_GoToSignpostEX($x, $y) ; Open dungeon lock, torch chest
	Local $lDeadlock
	$lDeadlock = TimerInit()

	Sleep(50)
	If Wipe() = 1 Then Return
	If Wipe() = 0 Then Move_ToCoord($x, $y)

	Do
		RndSleep(250)
		Local $lNearestAgent, $lNearestDistance = 100000000
		Local $lDistance
		Local $lAgentArray = Agent_GetAgentArray(0x200)

		For $i = 1 To $lAgentArray[0]
			$lDistance = ($x - X($lAgentArray[$i])) ^ 2 + ($y - Y($lAgentArray[$i])) ^ 2
			If Agent_GetAgentInfo($lAgentArray[$i], "Type") = 0x200 And $lDistance < $lNearestDistance Then
				$lNearestAgent = $lAgentArray[$i]
				$lNearestDistance = $lDistance
			EndIf
		Next
	Until ($lNearestAgent <> 0 And Agent_GetAgentInfo($lNearestAgent, "ID") <> 0) Or Wipe() = 1 Or TimerDiff($lDeadlock) > 30000
	If Wipe() = 0 And $lNearestAgent <> 0 Then Agent_ChangeTarget($lNearestAgent)
	RndSleep(250)
	Do
		RndSleep(500)
		ActionInteract()
	Until Agent_GetDistance($lNearestAgent) < 150 Or Wipe() = 1
	Sleep(500)
EndFunc   ;==>Agent_GoSignpost

Func ChestAndReward($aWaypoints, $x, $y, $reloadmap = 0, $aPlayerID = 0)

	Endchest($x, $y)                                    ;~ Find and open end chest
	If $GUI_RunCounter > 0 Then
		GUI_SetAvgRunTime(AvgRunTime())
		GUI_SetBestRunTime(BestRunTime())
	EndIf
	AdlibUnRegister("CurrentRunTime")

	FindRewardNPCByPlayerID($aWaypoints, $aPlayerID)    ;~Backtrack as far as necessary to find Reward NPC
	GetReward($x, $y, $quest, $aPlayerID)               ;~Accept reward

	If $GUI_GroupSettings_CheckSell = True And Item_CountEmptySlots(InventoryBagList()) < 8 Then Return Trade_ClearInventory()
	; Dungeon eject → outpost/explorable (Logic WaitMapLoading).
	If $reloadmap <> 0 Then
		Out("ChestAndReward: waiting for map " & $reloadmap & " (now " & Map_GetMapID() & ")")
		Do
			If Bot_HaltIfStopped() Then Return
			Sleep(100)
		Until WaitMapLoading($reloadmap, 180000) Or Map_GetMapID() = $reloadmap
		Out("ChestAndReward: zoned — MapID=" & Map_GetMapID())
	EndIf

EndFunc   ;==>ChestAndReward

Func Endchest($x, $y, $reloadmap = 0)
	Out("Boss Group Dead")
	Out("Opening Chest")
	AggroMoveToEX($x, $y, $danger_range)

	Agent_GoToSignPost(GetEndChest())
	Other_PingSleep(1500)
	Out("Pick Up Drops")
	PickupLootEx(5000)

	If Agent_GetAgentInfo(-2, "Dead") Then Return
	If $reloadmap <> 0 Then
		Do
			Sleep(100)
		Until WaitMapLoading($reloadmap, 180000)
	EndIf

EndFunc   ;==>Endchest

; Find dungeon end chest among Type 0x200 gadgets via $aChestID[ExtraType] (Bogroot 8932, SoO 8934, etc.).
; Prefer EotN dungeon ExtraTypes 8926–8934 (nearest); else nearest any mapped chest.
Func GetEndChest()
	Local $lAgentPtrArray = Agent_GetAgentArray(0x200) ; type-only — never Allegiance-filter gadgets
	Local $lBest = 0, $lBestDist = 999999999.0
	Local $lFallback = 0, $lFallbackDist = 999999999.0
	Local $lExtraType, $lName, $lDist, $i
	If Not IsArray($lAgentPtrArray) Or $lAgentPtrArray[0] < 1 Then
		Local Static $iLastEmpty = 0
		If TimerDiff($iLastEmpty) > 15000 Or $iLastEmpty = 0 Then
			$iLastEmpty = TimerInit()
			Out("GetEndChest: no gadgets (Type 0x200)")
		EndIf
		Return 0
	EndIf
	For $i = 1 To $lAgentPtrArray[0]
		$lExtraType = Agent_GetAgentInfo($lAgentPtrArray[$i], "ExtraType")
		If Not IsNumber($lExtraType) Or $lExtraType < 0 Or $lExtraType >= UBound($aChestID) Then ContinueLoop
		$lName = $aChestID[$lExtraType]
		If $lName = "" Then ContinueLoop
		$lDist = Agent_GetDistance($lAgentPtrArray[$i])
		If $lExtraType >= 8926 And $lExtraType <= 8934 Then
			If $lDist < $lBestDist Then
				$lBestDist = $lDist
				$lBest = $lAgentPtrArray[$i]
			EndIf
		ElseIf $lDist < $lFallbackDist Then
			$lFallbackDist = $lDist
			$lFallback = $lAgentPtrArray[$i]
		EndIf
	Next
	If $lBest <> 0 Then
		$lExtraType = Agent_GetAgentInfo($lBest, "ExtraType")
		Out("End chest found: " & $aChestID[$lExtraType] & " (ExtraType " & $lExtraType & ")")
		Return $lBest
	EndIf
	; A Locked Chest (8141) is not the boss chest. Returning it made Chest and Reward run while Fendi was still up.
	If $lFallback <> 0 Then
		$lExtraType = Agent_GetAgentInfo($lFallback, "ExtraType")
		Local Static $sIgnored = ","
		If Not StringInStr($sIgnored, "," & $lExtraType & ",") Then
			$sIgnored &= $lExtraType & ","
			Out("End chest ignored: " & $aChestID[$lExtraType] & " (ExtraType " & $lExtraType & ") — not a dungeon chest")
		EndIf
		Return 0
	EndIf
	; Dump gadgets once every 15s so a new ExtraType can be added without flooding the log.
	Local Static $iLastDump = 0
	If TimerDiff($iLastDump) > 15000 Or $iLastDump = 0 Then
		$iLastDump = TimerInit()
		Out("GetEndChest: no mapped chest. Gadgets:")
		For $i = 1 To $lAgentPtrArray[0]
			Out("  ID=" & Agent_GetAgentInfo($lAgentPtrArray[$i], "ID") & _
				" ExtraType=" & Agent_GetAgentInfo($lAgentPtrArray[$i], "ExtraType") & _
				" Dist=" & Floor(Agent_GetDistance($lAgentPtrArray[$i])))
		Next
	EndIf
	Return 0
EndFunc   ;==>GetEndChest

; Logic FindRewardNPC — backtrack until quest NPC is within 3000. Uses Agent_GetAgentByPlayerNumber (not broken Agent_GetByPlayerNumber).
Func FindRewardNPCByPlayerID($aWaypoints, $aPlayerID)
	Out("Find Reward NPC")
	Local $Timer = TimerInit()
	Local $i, $lNpc
	Switch Map_GetMapID()
		Case $Shards_of_Oor_Lvl3
			For $i = UBound($aWaypoints) - 2 To 1 Step -1
				Out("Reward NPC player number " & $aPlayerID)
				$lNpc = Agent_GetAgentByPlayerNumber($aPlayerID)
				If $aWaypoints[$i][3] <> "Fendi's Lair" And $lNpc <> 0 And Agent_GetDistance($lNpc) < 3000 Or Wipe() = 1 Then Return
				Out("Where the f*ck is Shandra?! Searching at - " & $aWaypoints[$i][3])
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $spellcasting_range)
				If $i = UBound($aWaypoints) - 7 Then $i = 26    ; skip to Room 3 (index +1 after Group 1 pad)
				If TimerDiff($Timer) > 160000 Then Return False
			Next
		Case Else
			For $i = UBound($aWaypoints) - 2 To 1 Step -1
				AggroMoveToEX($aWaypoints[$i][0], $aWaypoints[$i][1], $spellcasting_range)
				$lNpc = Agent_GetAgentByPlayerNumber($aPlayerID)
				If ($lNpc <> 0 And Agent_GetDistance($lNpc) < 3000) Or Wipe() = 1 Then Return
				If TimerDiff($Timer) > 160000 Then Return False
			Next
	EndSwitch
EndFunc   ;==>FindRewardNPCByPlayerID

; Logic GetReward + Logic QuestReward retry (SendPacket 0x008QQQ07 until quest leaves log).
Func GetReward($x, $y, $aQuestID, $aPlayerID = 0)
	Out($Quest_ID[$aQuestID] & ", Status: " & Quest_GetQuestInfo($aQuestID, "LogState"))
	If Quest_GetQuestInfo($aQuestID, "LogState") < 2 Then Return
	; Exact PlayerNumber when known — GoToNPCNearXY fallback once hit a spirit after Fendi.
	If $aPlayerID <> 0 Then
		Local $lNpc = Agent_GetAgentByPlayerNumber($aPlayerID)
		If $lNpc = 0 Then
			Out("GetReward: PlayerNumber " & $aPlayerID & " not loaded")
			Return
		EndIf
		Agent_GoToNPC($lNpc)
	Else
		Agent_GoToNPCnearXY($x, $y, 0)
	EndIf
	Out("Accepting reward")
	Local $Timer = TimerInit()
	Do
		Other_PingSleep(200)
		Quest_QuestReward($aQuestID)
	Until Not Quest_GetQuestInfo($aQuestID, "HasQuest") Or TimerDiff($Timer) > 1000
	If Quest_GetQuestInfo($aQuestID, "HasQuest") Then _
		Out("No reward collected " & $Quest_ID[$aQuestID] & " (Status = " & Quest_GetQuestInfo($aQuestID, "LogState") & ")")
	Other_PingSleep(500)
EndFunc   ;==>GetReward

#Region Chest
; Thin Logic → Core aliases used by chest/loot/torch paths.
Func RndSleep($aMs = 100)
	Sleep($aMs + Random(0, 50, 1))
EndFunc   ;==>RndSleep

Func OpenChest($aWithLockpick = True)
	Return Item_OpenChest($aWithLockpick)
EndFunc   ;==>OpenChest

Func PickUpItem($aAgent)
	Return Item_PickUpItem($aAgent)
EndFunc   ;==>PickUpItem

Func DropBundle()
	Return Item_DropBundle()
EndFunc   ;==>DropBundle

; Unlit torch often reports WeaponItemType=46 (TYPE_NOT_EQUIPPED), not TYPE_BUNDLE=6.
; BundleItemID from inventory is the reliable "something in hands" flag.
Func HoldingBundle()
	If Number(Item_GetInventoryInfo("BundleItemID")) <> 0 Then Return True
	If Number(Agent_GetAgentInfo(-2, "WeaponItemType")) = $TYPE_BUNDLE Then Return True
	If Skill_HasEffect($Lit_Torch) Then Return True
	Return False
EndFunc   ;==>HoldingBundle

Func GoSignpost($aAgent)
	Return Agent_GoSignpost($aAgent)
EndFunc   ;==>GoSignpost

; Logic → GwAu3 party flag aliases
Func CancelHero($aHeroNumber)
	Return Party_CancelHero($aHeroNumber)
EndFunc   ;==>CancelHero

Func CancelAll()
	Party_CancelAll()
	; Party_CancelAll alone can leave heptagon flags after shrine rez — clear commands too.
	Core_PerformAction($GC_I_CONTROL_ACTION_CLEAR_PARTY_COMMANDS, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>CancelAll

Func CommandHero($aHeroNumber, $x, $y)
	Return Party_CommandHero($aHeroNumber, $x, $y)
EndFunc   ;==>CommandHero

; Logic CommandAll optionally waits until heroes reach the flag.
Func CommandAll($x, $y, $WaitForDestination = False, $aDistanceToDestination = $area_range)
	Party_CommandAll($x, $y)
	If $WaitForDestination Then
		Local $Timer = TimerInit()
		Do
			Sleep(500)
			Out(Agent_GetNumberOfAlliesNearXY($aDistanceToDestination, $x, $y))
		Until Agent_GetNumberOfAlliesNearXY($aDistanceToDestination, $x, $y) = GetPartySize() Or Agent_GetNumberOfAllies(5000) < 2 Or Agent_GetAgentInfo(-2, "IsDead") Or TimerDiff($Timer) > 60000
	EndIf
	Return True
EndFunc   ;==>CommandAll

Func ChangeTarget($aAgent)
	Return Agent_ChangeTarget($aAgent)
EndFunc   ;==>ChangeTarget

Func ActionInteract()
	Local $lTarget = Agent_GetCurrentTarget()
	If $lTarget = 0 Then Return
	Return Agent_GoSignpost($lTarget)
EndFunc   ;==>ActionInteract

Func MoveTo($aX, $aY, $aRandom = 50)
	Return Agent_MoveToXY($aX, $aY, $aRandom)
EndFunc   ;==>MoveTo

Func Move_ToCoord($aX, $aY, $aRandom = 50)
	Return Agent_MoveToXY($aX, $aY, $aRandom)
EndFunc   ;==>Move_ToCoord

; Logic-main RandomMoveTo — multi-stop path to look less bot-like in outposts (Merchant / traders / Xunlai).
Func RandomMoveTo($x, $y, $aRandom = 50, $StopsMin = 1, $StopsMax = 5, $Stops = -1)
	If $Stops = -1 Then $Stops = Random($StopsMin, $StopsMax, 1)
	If $Stops = 0 Or Agent_GetDistanceToXY($x, $y) < 200 Then Return Move_ToCoord($x, $y, $aRandom)

	Local $m = Random(0, 1)
	Local $n = $Stops - $m
	Local $StepX = (($m * $x) + ($n * X(-2))) / ($m + $n)
	Local $StepY = (($m * $y) + ($n * Y(-2))) / ($m + $n)
	Move_ToCoord($StepX, $StepY, $aRandom)
	RandomMoveTo($x, $y, $aRandom, $StopsMin, $StopsMax, $Stops - 1)
EndFunc   ;==>RandomMoveTo

; Logic OpenChestNoLockpick / OpenChest → Item_OpenChest(False/True).
Func OpenChestNoLockpick()
	Return Item_OpenChest(False)
EndFunc   ;==>OpenChestNoLockpick

; $aChestName is $aChestID[ExtraType] (display name). Uses matching key if in bags, else lockpick.
; (logic-main indexed $aArray_Chest_And_Key by the name string — broken; lookup by name col instead.)
Func OpenChestByExtraType($aChestName)
	Local $i, $lKeyModel = 0, $lKeyName = "Lockpick"
	For $i = 0 To UBound($aArray_Chest_And_Key) - 1
		If $aArray_Chest_And_Key[$i][1] <> $aChestName Then ContinueLoop
		$lKeyModel = $aArray_Chest_And_Key[$i][2]
		$lKeyName = $aArray_Chest_And_Key[$i][3]
		ExitLoop
	Next
	If $lKeyModel <> 0 And $lKeyModel <> 22751 And Item_GetBagsItembyModelID($lKeyModel) <> 0 Then
		Out("Use " & $lKeyName)
		Return OpenChestNoLockpick()
	EndIf
	Out("Use Lockpick")
	Return Item_OpenChest(True)
EndFunc   ;==>OpenChestByExtraType

; logic-main SurvivePickup: pick up items within $iMaxDist, moving with MoveAndSurvive.
Func SurvivePickup($iMaxDist = 5000, $aPickupTorch = False)
	Local $lAgentPtrArray = Agent_GetAgentArray(0x400)
	Local $i, $lAgentPtr, $lAgentID, $lItemPtr, $lOwner, $lDeadlock
	For $i = 1 To $lAgentPtrArray[0]
		If Agent_GetAgentInfo(-2, "IsDead") Then Return
		$lAgentPtr = $lAgentPtrArray[$i]
		$lAgentID = Agent_ID($lAgentPtr)
		$lItemPtr = Item_GetItemPtr(Item_GetItemInfoByAgentID($lAgentID, "ItemID"))
		If $lItemPtr = 0 Then ContinueLoop
		$lOwner = Agent_GetAgentInfo($lAgentPtr, "Owner")
		If $lOwner <> 0 And $lOwner <> Agent_GetMyID() Then ContinueLoop
		If CanPickUpEx($lItemPtr, $aPickupTorch) And Agent_GetDistance($lAgentID) < $iMaxDist Then
			MoveAndSurvive(X($lAgentPtr), Y($lAgentPtr))
			$lDeadlock = TimerInit()
			Do
				Item_PickUpItem($lAgentID)
				Other_PingSleep(250)
				Out("Pickup")
			Until Agent_GetAgentPtr($lAgentID) = 0 Or Agent_GetAgentInfo(-2, "IsDead") Or TimerDiff($lDeadlock) > 25000
		EndIf
	Next
EndFunc   ;==>SurvivePickup

; Logic-main CheckForChest: nearest mapped gadget chest, interact in place (GoSignpost only — no cross-map walk).
; Called every AggroMoveToEX tick when chests are enabled.
Func CheckForChest($chestrun = False)
	Local $AgentArray, $lAgent, $lExtraType, $lType, $lDist
	Local $ChestFound = False
	; Only open chests already near the party — Logic never pathfinds to a remote chest from here.
	Local Const $lMaxChestDist = $longbow_range
	If Agent_GetAgentInfo(-2, "IsDead") Then Return
	$AgentArray = Agent_GetDistanceSortedArray(0x200) ; 0x200 = static / gadget
	If Not IsArray($AgentArray) Then Return
	For $i = 0 To UBound($AgentArray) - 1
		$lAgent = $AgentArray[$i][0]
		If $lAgent = 0 Or $lAgent = "" Then ContinueLoop
		$lType = Agent_GetAgentInfo($lAgent, "Type")
		$lExtraType = Agent_GetAgentInfo($lAgent, "ExtraType")
		If $lType <> 512 Then ContinueLoop
		If Not IsNumber($lExtraType) Or $lExtraType < 0 Or $lExtraType >= UBound($aChestID) Then ContinueLoop
		If $aChestID[$lExtraType] = "" Then ContinueLoop
		If _ArraySearch($OpenedChestAgentIDs, $lAgent) >= 0 Then ContinueLoop
		$lDist = Agent_GetDistance($lAgent)
		; Sorted list can still include far gadgets; skip them (do not blacklist — open later when we pass by).
		If $lDist > $lMaxChestDist Then ContinueLoop
		If $OpenedChestAgentIDs[0] = "" Then
			$OpenedChestAgentIDs[0] = $lAgent
		Else
			_ArrayAdd($OpenedChestAgentIDs, $lAgent)
		EndIf
		$ChestFound = True
		Out("Find " & $aChestID[$lExtraType] & " (dist " & Floor($lDist) & ")")
		ExitLoop
	Next
	If Not $ChestFound Then Return
	Out("opening " & $aChestID[$lExtraType])
	Agent_ChangeTarget($lAgent)
	; Logic: GoSignpost only. Short approach if slightly out of interact range; never Agent_GoToSignpost across the map.
	If Agent_GetDistance($lAgent) > 150 Then Agent_MoveToDistanceAway(60, $lAgent)
	Agent_GoSignpost($lAgent)
	OpenChestByExtraType($aChestID[$lExtraType])
	GUI_SetChestsOpened(GUI_GetChestsOpened() + 1)
	GUI_SetLockpicks(GetPicksCount())
	Other_PingSleep(500)
	$AgentArray = Agent_GetDistanceSortedArray(0x400) ; 0x400 = item
	If IsArray($AgentArray) And UBound($AgentArray) > 0 And $AgentArray[0][0] <> "" And $AgentArray[0][0] <> 0 Then
		Agent_ChangeTarget($AgentArray[0][0])
	EndIf
	If $chestrun Then
		SurvivePickup(5000)
	Else
		PickupLootEx(3500)
	EndIf
EndFunc   ;==>CheckForChest

Func ForceOpenChest($x, $y)
	Local $Chest = 0
	Local $lDeadlock = TimerInit()
	If Wipe() = 1 Then Return
	Do
		RndSleep(250)
		$Chest = Agent_GetNearestSignpostToXY($x, $y)
	Until $Chest <> 0 Or TimerDiff($lDeadlock) > 300000
	If $Chest = 0 Then Return

	Out("opening chest")
	AggroMoveToEX(X($Chest), Y($Chest))
	Agent_ChangeTarget($Chest)
	Sleep(250)
	Do
		Sleep(200)
		ActionInteract()
	Until Agent_GetDistance($Chest) < 150 Or Agent_GetAgentInfo(-2, "IsDead")
	Item_OpenChest(True)
	Sleep(500)
EndFunc   ;==>ForceOpenChest
#EndRegion Chest

; returns the index of the nearest waypoint in an array of waypoints
Func GetNearestWaypointIndex($aWaypoints)
	Local $lNearestWaypoint, $lNearestDistance = 100000000
	Local $lDistance
	For $Index = 0 To UBound($aWaypoints) - 1
		$lDistance = Agent_GetDistanceToXY($aWaypoints[$Index][0], $aWaypoints[$Index][1])
		If $lDistance < $lNearestDistance Then
			$lNearestWaypoint = $Index
			$lNearestDistance = $lDistance
		EndIf
	Next
	Return $lNearestWaypoint
EndFunc   ;==>GetNearestWaypointIndex


;~ Description: Returns the party leader agent pointer via GwAu3 party member ordering (slot 1 = leader).
Func Party_GetPartyLeader()
	If Party_AmILeader() Then Return Agent_GetAgentPtr(-2)
	Local $l_i_LeaderID = Party_GetMemberAgentID(1)
	If $l_i_LeaderID = 0 Then Return 0
	Return Agent_GetAgentPtr($l_i_LeaderID)
EndFunc   ;==>Party_GetPartyLeader

; Flag 0x80 can drop for a moment after zoning. Slot 1 of the party window is the leader.
Func Party_AmILeader()
	If Party_GetPartyContextInfo("IsPartyLeader") Then Return True
	Local $lMyID = Agent_GetMyID()
	If $lMyID = 0 Then Return False
	Return Party_GetMemberAgentID(1) = $lMyID
EndFunc   ;==>Party_AmILeader

Func FollowPartyLeader($aFollowRange = 200, $aPartyLeader = 0)
    ; If $aPartyLeader isn't passed, find the leader's agent ID
    If $aPartyLeader <= 0 Then $aPartyLeader = Party_GetPartyLeader()

    Local $iInstanceType = Map_GetInstanceInfo("Type")
    If $iInstanceType == 0 Then Return
    If $iInstanceType == 2 Then Connection_CheckAndReconnect()

    If Agent_GetAgentInfo(-2, "IsDead") Then Return
    If $aPartyLeader = 0 Or Agent_ConvertID($aPartyLeader) = Agent_GetMyID() Then Return

    ; Walk up even when the leader is standing. The old IsMoving check left followers at the portal.
    If Agent_GetDistance($aPartyLeader) > $aFollowRange Then
        AggroMoveToLeader(Agent_GetAgentInfo($aPartyLeader, "X"), Agent_GetAgentInfo($aPartyLeader, "Y"), 1320, $aFollowRange, $aPartyLeader)
    EndIf

    Other_PingSleep(100)
EndFunc   ;==>FollowPartyLeader

Func AggroMoveToLeader($x, $y, $aRange = 1320, $aFollowRange = 200, $aPartyLeader = 0)
    Local $random = 10
    If CantExplore() Then Return

    If Agent_GetDistance($aPartyLeader) > $aFollowRange Then Agent_MoveToXY($x, $y)

    Do
        If Bot_HaltIfStopped() Then ExitLoop
        ; SpeedBoost() ; Replace with native speed boost skill/item call if available
        If $aPartyLeader <= 0 Then $aPartyLeader = Party_GetLeaderAgentID()

        Local $fNearestDist = Agent_GetDistance(Agent_GetBestTarget($aRange))
        ConsoleWrite("Nearest Enemy: " & Floor($fNearestDist) & ", Leader Dist: " & Floor(Agent_GetDistance($aPartyLeader)) & @CRLF)

        If GetAgents(-2, $aRange, 0, 0, "Agent_IsLivingEnemy") > 0 And Agent_GetDistance($aPartyLeader) < $aFollowRange Then
            ; careful=False; leash=follow range (was 0 — treated as distance 0 / always leash-break).
            Fight($x, $y, $aRange, False, $aFollowRange, $aPartyLeader)
            If Bot_HaltIfStopped() Then ExitLoop
            PickupLootEx()
            Sleep(200)
        EndIf

        Agent_MoveToXY(Agent_GetAgentInfo($aPartyLeader, "X"), Agent_GetAgentInfo($aPartyLeader, "Y"))
        Sleep(100)

    Until (Agent_GetDistance($aPartyLeader) < 250 And GetAgents(-2, $aRange, 0, 0, "Agent_IsLivingEnemy") = 0) Or Agent_GetAgentInfo(-2, "IsDead") Or CantExplore()
EndFunc   ;==>AggroMoveToLeader

;~ Run and aggro management
Func AggroMoveToEX($x, $y, $aFightRange = 1350)
; REVIEW: Core movement+aggro. Calls Fight() from logiccast. GwAu3 has Map_Move and UAI_Fight.
; Logic Move() defaults to ±50; AggroMoveToEX historically passed 100 (extra zigzag on every re-issue).
	If CantExplore() Then Return
	; Pull Group wp[2] is hero-flag coords ("9754, 18972") — Number()→9754 and Fight pulls half the room with no prep.
	If Not IsNumber($aFightRange) Or Number($aFightRange) <= 0 Then $aFightRange = 1350
	Local $MyMap, $lMapLoading
	Local $MyOldMap = Map_GetMapID(), $lMapLoadingOld = Map_GetInstanceInfo("Type")
	Local $lDeadlock, $lBlocked, $aOldX, $aOldY
	Local $random = 50
	Local $lTorchDropX = 0, $lTorchDropY = 0, $lDroppedTorch = False
	; Want torch on ground: explicit flag OR mid-rekindle ($unlit). Don't depend on nearest-WP clears.
	Local $lWantTorch = ($PickupTorch Or $unlit)

	If Party_GetPartyHealth() > 0.80 And Agent_GetNumberOfPartyInRange(1700) = Party_GetPartyContextInfo("TotalPartySize") Then Map_Move($x, $y, $random)

	$TimerAggro = TimerInit()
	Do
		If Bot_HaltIfStopped() Then ExitLoop
		$aOldX = X(-2)
		$aOldY = Y(-2)
		If Map_GetMapID() <> $MyOldMap Or Map_GetInstanceInfo("Type") <> $lMapLoadingOld Then ExitLoop
		; Must leave current WP on death — otherwise shrine rez keeps this Do targeting incubi coords ("slow progress").
		If Agent_GetAgentInfo(-2, "IsDead") Then
			$g_b_DiedOnWaypoint = True
			ExitLoop
		EndIf
		$lWantTorch = ($PickupTorch Or $unlit)
		If Agent_IsEnemyNear($aFightRange) Then
			; Fight with Torch / Clear Spawn / rekindle: martial drops at engage XY, picks up after Fight.
			If $lWantTorch And Not $lDroppedTorch And Agent_IsMartialPrimary(-2) Then
				If Not HoldingBundle() Then
					Out("Torch drop: not holding (Lit=" & Skill_HasEffect($Lit_Torch) & _
							" WeaponItemType=" & Number(Agent_GetAgentInfo(-2, "WeaponItemType")) & _
							" BundleItemID=" & Number(Item_GetInventoryInfo("BundleItemID")) & ") — trying pickup")
					PickupTorch()
				EndIf
				If HoldingBundle() Then
					$lTorchDropX = X(-2)
					$lTorchDropY = Y(-2)
					Out("Dropped torch for martial fight (BundleItemID=" & Number(Item_GetInventoryInfo("BundleItemID")) & _
							" WeaponItemType=" & Number(Agent_GetAgentInfo(-2, "WeaponItemType")) & ")")
					Item_DropBundle()
					Sleep(250)
					$lDroppedTorch = True
				Else
					Out("Torch drop: still no bundle after pickup — fighting armed")
				EndIf
			EndIf
			Fight($x, $y, $aFightRange)
			If $lWantTorch And $lDroppedTorch And Not Wipe() And Not Agent_GetAgentInfo(-2, "IsDead") Then
				Out("Picking up torch after fight")
				Agent_MoveToXY($lTorchDropX, $lTorchDropY)
				PickupTorch()
				If Not HoldingBundle() Then PickupLootEx(5000, True)
				$lDroppedTorch = False
			EndIf
		EndIf
		If Bot_HaltIfStopped() Then ExitLoop
		If GUI_IsChestChecked() Then CheckForChest()
		; Honor torch need so a dropped torch can be recovered during brazier / Fight with Torch / rekindle.
		PickupLootEx(3000, $lWantTorch)

		If CanMove($aFightRange) Or TimerDiff($TimerAggro) > 60000 Then
			Map_Move($x, $y, $random)
			SpeedBoost()
			; Lit torch: renew HR via shouts (SpeedBoost already skips casting HR while Lit).
			If Skill_HasEffect($Lit_Torch) Then
				If ShouldUse($SkillbarSlot[$Theyre_on_Fire]) Then Skill_TryUseSkill($SkillbarSlot[$Theyre_on_Fire])
				If ShouldUse($SkillbarSlot[$Burning_Refrain]) Then Skill_TryUseSkill($SkillbarSlot[$Burning_Refrain])
			EndIf
			Sleep(50)
			If X(-2) = $aOldX And Y(-2) = $aOldY Then
				$lBlocked += 1
				Map_Move(X(-2), Y(-2), 500)
				Other_PingSleep(350)
				Map_Move($x, $y, $random)
			EndIf
		EndIf
		If TimerDiff($TimerAggro) > 120000 Then
			; Throttle: AggroMoveToEX loops every ~50ms; don't spam the console.
			If $g_h_SlowProgressOut = 0 Or TimerDiff($g_h_SlowProgressOut) > 5000 Then
				Out("We are making slow progress...")
				$g_h_SlowProgressOut = TimerInit()
			EndIf
		EndIf
		If TimerDiff($TimerAggro) > 240000 Then
			Out("Crashed...")
			Out(" RE_LOADING! ")
			; Logic Disconnected/reconnect uses the GW window handle; Core exposes Scanner_GetWindowHandle / $g_h_GWWindow.
			Connection_CheckAndReconnect()
			Opt("SendKeyDelay", 500)
			Sleep(1000)
			Local $l_h_GW = GetWindowHandle()
			If $l_h_GW <> 0 Then
				ControlSend($l_h_GW, "", "", "{Enter}{Enter}")
				ControlSend($l_h_GW, "", "", "{ALT}{ALT}")
				Sleep(1000)
				ControlSend($l_h_GW, "", "", "{Enter}{Enter}")
			EndIf
			Opt("SendKeyDelay", 5)
			Sleep(5000)
			$TimerAggro = TimerInit()
		EndIf
	Until Agent_GetDistanceToXY($x, $y) < 250 Or $lBlocked > 30 Or TimerDiff($TimerAggro) > 300000 Or CantExplore() Or Agent_GetAgentInfo(-2, "IsDead")
	If Agent_GetAgentInfo(-2, "IsDead") Then $g_b_DiedOnWaypoint = True
	If ($PickupTorch Or $unlit) And $lDroppedTorch And Not Agent_GetAgentInfo(-2, "IsDead") And Not Wipe() Then
		Agent_MoveToXY($lTorchDropX, $lTorchDropY)
		PickupTorch()
	EndIf
EndFunc   ;==>AggroMoveToEX

Func AggroMoveToPvP($x, $y, $aFightRange = 1350)
	If CantExplore() Then Return
	Local $MyMap, $lMapLoading
	Local $MyOldMap = Map_GetMapID(), $lMapLoadingOld = Map_GetInstanceInfo("Type")
	Local $lDeadlock, $lBlocked, $aOldX, $aOldY
	Local $random = 50

	If Party_GetPartyHealth() > 0.80 And Agent_GetNumberOfPartyInRange(1700) = Party_GetPartyContextInfo("TotalPartySize") Then Map_Move($x, $y, $random)

	$TimerAggro = TimerInit()
	Do
		If Bot_HaltIfStopped() Then ExitLoop
		$aOldX = X(-2)
		$aOldY = Y(-2)
		If Map_GetMapID() <> $MyOldMap Or Map_GetInstanceInfo("Type") <> $lMapLoadingOld Then ExitLoop
		If Agent_GetAgentInfo(-2, "IsDead") Then
			$g_b_DiedOnWaypoint = True
			ExitLoop
		EndIf
		If Agent_IsEnemyNear($aFightRange) Then Fight($x, $y, $aFightRange)
		If Bot_HaltIfStopped() Then ExitLoop

		If CanMove($aFightRange) Or TimerDiff($TimerAggro) > 60000 Then
			Map_Move($x, $y, $random)
			SpeedBoost()
			Sleep(50)
			If X(-2) = $aOldX And Y(-2) = $aOldY Then
				$lBlocked += 1
				Map_Move(X(-2), Y(-2), 500)
				Other_PingSleep(350)
				Map_Move($x, $y, $random)
			EndIf
		EndIf
	Until Agent_GetDistanceToXY($x, $y) < 250 Or $lBlocked > 30 Or CantExplore() Or Agent_GetAgentInfo(-2, "IsDead")
	If Agent_GetAgentInfo(-2, "IsDead") Then $g_b_DiedOnWaypoint = True
EndFunc   ;==>AggroMoveToPvP

Func CantExplore()
	If Cinematic_DetectSkipCinematics() Then
		Return True
	ElseIf Map_GetInstanceInfo("Type") == 2 Then
		Connection_CheckAndReconnect()
	EndIf
	If Map_GetInstanceInfo("Type") == 0 Then Return True
	If Agent_GetAgentInfo(-2, "IsDead") Then
		$g_b_DiedOnWaypoint = True
		Return True
	EndIf
	If Wipe() Then Return True
	Return False
EndFunc

;~ Flag heroes at aRange+margin (near-side sector), walk self to aRange while they path,
;~ ApplyHR + precast, then AggroMoveToEX(WP) with flags still set (CancelHero before pull reballs heroes).
; Uses Agent_GetClosestXYinRange — refresh each tick so stand tracks the foe (stale XY left us far past casting range).
; $spellcasting_range (1341) > $danger_range (1065) — stand at casting range does not aggro.
Func CarefulAggro($x, $y, $aRange = $spellcasting_range, $hero_increment = 500)
	If CantExplore() Then Return
	; avoir setting hero flags too far from ennemies if moving
	Do
		Sleep(100)
		$nearestenemy = Agent_GetNearestAgent(-2, 0xDB, 3)
	Until Agent_GetAgentInfo($nearestenemy, "IsMoving") = False or Agent_GetDistance($nearestenemy) <= $aRange
	Local $nearestenemy = Agent_GetNearestAgent(-2, 0xDB, 3)
	If $nearestenemy <> 0 And Not Agent_GetAgentInfo($nearestenemy, "IsDead") Then
		; Soft-death / mid-fight resume: already in aggro — do not FlagHeptagon (heroes stop fighting).
		If Agent_GetDistance($nearestenemy) <= $danger_range Then
			Out("CarefulAggro: already in contact (dist=" & Floor(Agent_GetDistance($nearestenemy)) & ") — CancelAll + engage")
			CancelAll()
		Else
			; Flag first so heroes move in parallel and stay in shout/HR range while we walk.
			Local $heroXY = Agent_GetClosestXYinRange($aRange + $hero_increment, $nearestenemy)
			Out("Flagging heroes " & ($aRange + $hero_increment) & " from target (near-side sector)")
			FlagHeptagon(300, $heroXY[0], $heroXY[1])

			Out("Moving within casting range (" & $aRange & "), undetected until < " & $danger_range)
			Do
				If Bot_HaltIfStopped() Or CantExplore() Then Return
				$nearestenemy = Agent_GetNearestAgent(-2, 0xDB, 3)
				If $nearestenemy = 0 Or Agent_GetAgentInfo($nearestenemy, "IsDead") Then ExitLoop
				If Agent_GetDistance($nearestenemy) <= $danger_range Then
					Out("CarefulAggro: pack closed in during approach — CancelAll + engage")
					CancelAll()
					ExitLoop
				EndIf
				Local $pullXY = Agent_GetClosestXYinRange($aRange, $nearestenemy)
				SpeedBoost()
				Map_Move($pullXY[0], $pullXY[1], 50)
				Sleep(50)
			Until Agent_GetDistance($nearestenemy) <= $aRange + 50 Or Agent_GetAgentInfo(-2, "IsDead")
			If $nearestenemy <> 0 And Not Agent_GetAgentInfo($nearestenemy, "IsDead") And Agent_GetDistance($nearestenemy) > $danger_range Then
				Out("CarefulAggro stand: foe dist=" & Floor(Agent_GetDistance($nearestenemy)) & " (want ~" & $aRange & ")")
				ApplyHR()
				PrecastWardsAndSpirits($spirit_range, $danger_range)
				Local $lSpiritWait = TimerInit()
				Do
					If Bot_HaltIfStopped() Or CantExplore() Then Return
					SpeedBoost()
					Sleep(250)
				Until TimerDiff($lSpiritWait) > 3000 Or Agent_IsEnemyNear($danger_range)
				If ShouldUse($SkillbarSlot[$Theyre_on_Fire]) Then Skill_TryUseSkill($SkillbarSlot[$Theyre_on_Fire])
				If ShouldUse($SkillbarSlot[$Burning_Refrain]) Then Skill_TryUseSkill($SkillbarSlot[$Burning_Refrain])
			EndIf
		EndIf
	EndIf

	Out("CarefulAggro: engaging WP")
	; Keep heptagon through a fresh pull — CancelAll above if we were already in contact.
	AggroMoveToEX($x, $y, $aRange)
	Core_PerformAction($GC_I_CONTROL_ACTION_CLEAR_PARTY_COMMANDS, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>CarefulAggro

Func FlagHeroesAroundXY($x, $y, $aPlayerID = 0, $aRange = 600)
	If $aPlayerID <> 0 Then
		$lPtr = Agent_GetAgentByPlayerNumber($aPlayerID)
		$x = X($lPtr)
		$y = Y($lPtr)
	EndIf
	CommandHero(1, $x + $aRange, $y)
	CommandHero(2, $x, $y + $aRange)
	CommandHero(3, $x + $aRange, $y + $aRange)
	CommandHero(4, $x - $aRange, $y)
	CommandHero(5, $x, $y - $aRange)
	CommandHero(6, $x - $aRange, $y - $aRange)
EndFunc   ;==>FlagHeroesAroundXY

; Lag/heal wait clocks — reset when party is together / healthy so timeouts don't stick.
Global $g_tCanMoveLagWait = 0
Global $g_tCanMoveHealWait = 0
Global $g_tCanMoveCritWait = 0
Global $g_tCanMoveEnemyOut = 0

; Returns whether the party can move based on death and health status; uses the $PartyPtrArray global variable if different than zero to test for party health
Func CanMove($aRange = $longbow_Range)
	Local $heroXY[2]
	If Wipe() Then Return
	If Agent_IsEnemyNear($aRange) Then
		; Throttle — AggroMoveToEX polls every ~50ms.
		If $g_tCanMoveEnemyOut = 0 Or TimerDiff($g_tCanMoveEnemyOut) > 2000 Then
			Out("Enemies are still around (n=" & Agent_GetNumberOfEnemies($aRange) & ", nearest=" & Floor(Agent_GetNearestDistance()) & ")")
			$g_tCanMoveEnemyOut = TimerInit()
		EndIf
		Return False
	EndIf
	If Agent_GetAgentInfo(-2, "IsCasting") THen Return False
	If Agent_GetAgentInfo(-2, "IsDead") Then
		If Skill_HasEffect($Sulfurous_Haze) Then ResignAndReturn(); heroes cannot rezz and cannot suicide while in sulferoud haze (can't leave junundu)
		Return False
	EndIf
	Local $OldPartyHP = Party_GetPartyHealth()
	; If party HP could not be resolved, do not block movement (avoids false "heal" waits)
	If $OldPartyHP <= 0 Then Return True
	Local $DeadAlliesCount = Agent_GetNumberOfDeadAllies(5000)
	Local $iPartySize = Party_GetPartyContextInfo("TotalPartySize")

	If $DeadAlliesCount = 0 Then
		; Critically low living ally (poison degen, etc.) — do not advance until they recover.
		Local $lCritHP = 1.0, $lCritAlly = 0
		For $i = 1 To $iPartySize
			Local $iMemberID = Party_GetMemberAgentID($i)
			If $iMemberID = 0 Or Agent_GetAgentInfo($iMemberID, "IsDead") Then ContinueLoop
			Local $fMemberHP = Agent_GetAgentInfo($iMemberID, "HP")
			If $fMemberHP < $lCritHP Then
				$lCritHP = $fMemberHP
				$lCritAlly = $iMemberID
			EndIf
		Next
		If $lCritAlly <> 0 And $lCritHP < 0.20 Then
			If $g_tCanMoveCritWait = 0 Then $g_tCanMoveCritWait = TimerInit()
			If TimerDiff($g_tCanMoveCritWait) < 20000 Then
				Out("Waiting for ally HP (" & Round($lCritHP * 100) & "%)")
				CancelAction()
				Return False
			EndIf
		Else
			$g_tCanMoveCritWait = 0
		EndIf

		If Agent_GetNumberOfPartyInRange(1700) < $iPartySize Then
			If Agent_GetNumberOfPartyInRange(5000) = $iPartySize And Agent_GetAgentInfo(Agent_GetFarthestAlly(), "IsMoving") Then
				If $g_tCanMoveLagWait = 0 Then $g_tCanMoveLagWait = TimerInit()
				If TimerDiff($g_tCanMoveLagWait) < 20000 Then
					Out("We left a party member behind — waiting for full party")
					CancelAction()
					Return False
				EndIf
			Else
				$g_tCanMoveLagWait = 0
			EndIf
		Else
			$g_tCanMoveLagWait = 0
			If $OldPartyHP < 0.80 Then
				Other_PingSleep(100)
				Local $nPartyHP = Party_GetPartyHealth()
				If $nPartyHP >= 0.99 * $OldPartyHP Then
					If $g_tCanMoveHealWait = 0 Then $g_tCanMoveHealWait = TimerInit()
					If TimerDiff($g_tCanMoveHealWait) < 20000 Then
						Out("Waiting for party to heal (" & $nPartyHP & ")")
						CancelAction()
						Return False
					EndIf
				ElseIf $nPartyHP < 0.99 * $OldPartyHP Then
					$g_tCanMoveHealWait = 0
					Out("Moving out of AoE area")
					Local $lTheta = Random(0, 360)
					Local $lHighestAlly = Agent_GetHighestAlly()
					If $lHighestAlly = 0 Then $lHighestAlly = -2
					Map_Move(50 * Cos($lTheta * 0.01745) + X($lHighestAlly), 50 * Sin($lTheta * 0.01745) + Y($lHighestAlly), 0)
					Sleep(300)
				EndIf
			Else
				$g_tCanMoveHealWait = 0
			EndIf
		EndIf
	ElseIf $DeadAlliesCount > 0 And GetAvailableRezz() > 0 Then
		Out(GetAvailableRezz() & " rezzes remaining")
		$FrozensoilPtr = Agent_GetAgentByPlayerNumber($PID_Frozen_Soil)
		If $FrozensoilPtr = 0 Then
			Out("Waiting for dead ally to be rezzed")
			$NearestDeadAllyPtr = Agent_GetNearestDeadAlly()
			If $NearestDeadAllyPtr = 0 Then Return True
			; One MoveToDistanceAway often stalls (MoveToXY aborts after 14 blocks) when corpse is 3k+ away.
			; Keep walking toward the corpse until in cast range, then hold for hero/player rez.
			$RezzTimer = TimerInit()
			Do
				$NearestDeadAllyPtr = Agent_GetNearestDeadAlly()
				If $NearestDeadAllyPtr = 0 Then ExitLoop
				Local $lRezDist = Agent_GetDistance($NearestDeadAllyPtr)
				If $lRezDist > $spellcasting_range Then
					Out("Approaching dead ally " & Agent_GetAgentInfo($NearestDeadAllyPtr, "Name") & " dist=" & Floor($lRezDist))
					; Direct walk to corpse XY — more reliable than a single circle-point MoveTo across the map
					Agent_MoveToXY(X($NearestDeadAllyPtr), Y($NearestDeadAllyPtr), 80)
				Else
					; In cast range — hold here so heroes can rez (Logic: MoveToDistanceAway + wait)
					Agent_MoveToDistanceAway($spellcasting_range * 0.6, $NearestDeadAllyPtr)
					$BestTarget = $NearestDeadAllyPtr
					For $aSkillSlot In $Skillbar
						If $SkillBarCache[$aSkillSlot][$rezz] = "" Then ContinueLoop
						If ShouldUse($aSkillSlot, $spellcasting_range) Then Skill_TryUseSkill($aSkillSlot, $NearestDeadAllyPtr, False, 0)
					Next
				EndIf
				Out("Party health: " & Party_GetPartyHealth() & ", Dead Ally: " & Agent_ID($NearestDeadAllyPtr) & " dist=" & Floor(Agent_GetDistance($NearestDeadAllyPtr)))
				If TimerDiff($RezzTimer) > 60000 Then Return Out("Failed to rezz dead ally, continuing...")
				Sleep(250)
			Until Not Agent_GetAgentInfo($NearestDeadAllyPtr, "IsDead") Or GetAvailableRezz() = 0 Or Wipe()
		Else
			Out("Looking for frozen soil")
			$heroXY = Agent_GetClosestXYinRange($spellcasting_range, $FrozensoilPtr)
			If IsArray($heroXY) Then
				Out("Frozen soil is up, dispatching")
				CommandAll($heroXY[0], $heroXY[1])
			EndIf
			Agent_CallTarget($FrozensoilPtr)
			Do
				Sleep(250)
			Until Not Agent_Exists($FrozensoilPtr) Or Wipe()
			CancelAll()
		EndIf
	EndIf
	Return True
	;If Party_GetPartyHealth() < 0.96 * $OldPartyHP Then Out("Losing " & Floor((Party_GetPartyHealth() - $OldPartyHP) / $OldPartyHP) * 5 & "% HP per second")
EndFunc   ;==>CanMove

Func MoveAndSurvive($lDestX, $lDestY, $lRandom = 100, $UseHoS = False, $safe_distance = 1750)
	Local $lDeadlock
	Local $lBlocked, $OldPartyHP
	Local $lHosCount
	Local $lAngle
	Local $stuckTimer = TimerInit()
	If Agent_GetAgentInfo(-2, "Dead") Then Return False
	If Map_GetInstanceInfo("Type") <> 1 Then Return True
	If Map_GetInstanceInfo("Type") = 2 Then Return False ; loading screen
	$lDeadlock = TimerInit()
	Map_Move($lDestX, $lDestY, $lRandom)
	Do
		RndSleep(100)
		If Agent_GetAgentInfo(-2, "Dead") Then ExitLoop
		SpeedBoost()
		Map_Move($lDestX, $lDestY, $lRandom)
		If $UseHoS = True Then
			If Agent_GetNearestDistance() < $safe_distance Then Survive($safe_distance)
				If IsRecharged($SkillbarSlot[$Heart_of_Shadow]) Then ; use Heart of Shadow on recharge with the right angle in order to avoid stuck/go faster
				$lTarget = GetGoodAngle($lDestX, $lDestY)
				If $lTarget <> -3 And Agent_GetAgentInfo(-2, $lTarget, "Dead") < 1100 And Agent_GetAgentInfo(-2, "CurrentEnergy") > 10 Then
					Skill_UseSkill($SkillbarSlot[$Heart_of_Shadow], $lTarget)
				EndIf
			EndIf
		EndIf

		If Not Agent_GetAgentInfo(-2, "Moving") Then
			If Agent_GetAgentInfo(-2, "Dead") Then ExitLoop
			If Agent_GetNearestDistance() < $safe_distance Then Survive($safe_distance)
			If $lHosCount > 6 Then
				Do    ; suicide
					Sleep(100)
				Until Agent_GetAgentInfo(-2, "Dead")
				Return False
			EndIf
			$lBlocked += 1
			If $lBlocked < 5 Then
				Map_Move($lDestX, $lDestY, $lRandom)
			ElseIf $lBlocked < 10 Then
				$lAngle += 40
				Map_Move(X(-2) + 300 * Sin($lAngle), Y(-2) + 300 * Cos($lAngle))
			ElseIf $lBlocked > 9 Then
				If $lHosCount == 0 And Agent_GetNearestDistance() < 1000 Then
					Skill_UseSkill($SkillbarSlot[$Heart_of_Shadow], Agent_GetNearestAgent(-2, 0xDB, 3))
				Else
					Skill_UseSkill($SkillbarSlot[$Heart_of_Shadow], Agent_GetAgentPtr(-2))
				EndIf
				$lBlocked = 0
				$lHosCount += 1
			EndIf
		Else
			If Agent_GetAgentInfo(-2, "Dead") Then ExitLoop
			If Agent_GetNearestDistance() < $safe_distance Then Survive($safe_distance)
			If $lBlocked > 0 Then
				$ChatStuckTimer = TimerInit()
				If TimerDiff($ChatStuckTimer) > 3000 Then    ; use a timer to avoid spamming /stuck
					SendChat("stuck", "/")
				EndIf
				$lBlocked = 0
				$lHosCount = 0
			EndIf
			If Agent_GetNearestDistance() > 1100 Then ; target is far, we probably got stuck.
				$ChatStuckTimer = TimerInit()
				If TimerDiff($ChatStuckTimer) > 3000 Then ; dont spam
					SendChat("stuck", "/")
					$ChatStuckTimer = TimerInit()
					RndSleep(GetPing())
				EndIf
			EndIf
		EndIf
	Until Agent_GetDistanceToXY($lDestX, $lDestY) < 250 Or $lBlocked > 20 Or Agent_GetAgentInfo(-2, "Dead") Or TimerDiff($lDeadlock) > 60000
	Return True
EndFunc   ;==>MoveAndSurvive

Func MoveAndSurvive_($lDestX, $lDestY, $SurviveFunc, $lRandom = 100, $safe_distance = 1750)
	Local $lBlocked
	Local $lHosCount
	Local $lAngle
	Local $lMe = Agent_GetAgentInfo(-2, "ID")
	If Agent_GetAgentInfo($lMe, "Dead") Then Return False
	If Map_GetInstanceInfo("Type") <> 1 Then Return True
	If Map_GetInstanceInfo("Type") = 2 Then Return False ; loading screen
	$lDeadlock = TimerInit()
	Map_Move($lDestX, $lDestY, $lRandom)
	Do
		RndSleep(100)
		If Agent_GetAgentInfo($lMe, "Dead") Then ExitLoop
		SpeedBoost()
		Map_Move($lDestX, $lDestY, $lRandom)
		If Agent_IsEnemyNear($safe_distance) Then Call($SurviveFunc, $safe_distance)

		If IsRecharged($SkillbarSlot[$Heart_of_Shadow]) Then ; use Heart of Shadow on recharge with the right angle in order to avoid stuck/go faster
			$lTarget = GetGoodAngle($lDestX, $lDestY)
			If $lTarget <> -3 And Agent_GetAgentInfo($lMe, $lTarget, "Dead") < 1100 And Agent_GetAgentInfo($lMe, "CurrentEnergy") > 10 Then
				Skill_UseSkill($SkillbarSlot[$Heart_of_Shadow], $lTarget)
			EndIf
		EndIf

		If Not Agent_GetAgentInfo(-2, "Moving") Then
			If Agent_GetAgentInfo($lMe, "Dead") Then ExitLoop
			If Agent_IsEnemyNear($safe_distance) Then Call($SurviveFunc, $safe_distance)
			If $lHosCount > 6 Then
				Do    ; suicide
					Sleep(100)
				Until Agent_GetAgentInfo(-2, "Dead")
				Return False
			EndIf
			$lBlocked += 1
			If $lBlocked < 5 Then
				Map_Move($lDestX, $lDestY, $lRandom)
			ElseIf $lBlocked < 10 Then
				$lAngle += 40
				Map_Move(X() + 300 * Sin($lAngle), Y() + 300 * Cos($lAngle))
			ElseIf $lBlocked > 9 Then
				If $lHosCount == 0 And Agent_IsEnemyNear($safe_distance) Then
					Skill_UseSkill($SkillbarSlot[$Heart_of_Shadow], Agent_GetNearestAgent(-2, 0xDB, 3))
				Else
					Skill_UseSkill($SkillbarSlot[$Heart_of_Shadow])
				EndIf
				$lBlocked = 0
				$lHosCount += 1
			EndIf
		Else
			If Agent_GetAgentInfo($lMe, "Dead") Then ExitLoop
			If Agent_IsEnemyNear($safe_distance) Then Call($SurviveFunc, $safe_distance)
			If $lBlocked > 0 Then
				$ChatStuckTimer = TimerInit()
				If TimerDiff($ChatStuckTimer) > 3000 Then    ; use a timer to avoid spamming /stuck
					SendChat("stuck", "/")
				EndIf
				$lBlocked = 0
				$lHosCount = 0
			EndIf
			If Agent_IsEnemyNear($safe_distance) Then ; target is far, we probably got stuck.
				$ChatStuckTimer = TimerInit()
				If TimerDiff($ChatStuckTimer) > 3000 Then ; dont spam
					SendChat("stuck", "/")
					$ChatStuckTimer = TimerInit()
					Other_PingSleep()
				EndIf
			EndIf
		EndIf
	Until Agent_GetDistanceToXY($lDestX, $lDestY) < 250 Or $lBlocked > 20 Or Agent_GetAgentInfo(-2, "Dead") Or TimerDiff($lDeadlock) > 60000
	Return True
EndFunc   ;==>MoveAndSurvive

Func GetGoodAngle($lDestX, $lDestY)
    RndSleep(100)
    Local $lBestHosTarget = -1, $lBestHosAngle = 90, $lPI = 3.14159
    Local $lWantedAngle = _ATan2(($lDestY - Y()), ($lDestX - X())) * 180 / $lPI
    Local $aAgentArray = Agent_GetArray(4, 0xDB, 3, 1150)
	If ComputeDistance($lDestX, $lDestY, X(), Y()) < 200 Then Return -3
    For $i = 1 to $aAgentArray[0]
		If Agent_GetAgentInfo(Agent_GetAgentPtr(-2, "Dead"), $aAgentArray[$i]) > 1000 Then ContinueLoop
        $lTargetAngle = _ATan2((Y() - Y($aAgentArray[$i])), (X() - X($aAgentArray[$i]))) * 180 / $lPI
        If Abs($lWantedAngle - $lTargetAngle) < $lBestHosAngle Then
            $lBestHosTarget = $aAgentArray[$i]
            $lBestHosAngle = Abs($lWantedAngle - $lTargetAngle)
        EndIf
    Next
    Return $lBestHosTarget
EndFunc

Func _ATan2($y, $x)
	$lPI = 3.14159
	Select
		Case $x > 0
			Return ATan($y / $x)
		Case $x < 0 And $y >= 0
			Return ATan($y / $x) + $lPI
		Case $x < 0 And $y < 0
			Return ATan($y / $x) - $lPI
		Case $x = 0 And $y > 0
			Return $lPI / 2
		Case $x = 0 And $y < 0
			Return -$lPI / 2
		Case $x = 0 And $y = 0
			Return  @Error
	EndSelect
EndFunc

Func Move55HP($lDestX, $lDestY, $lRandom = 100, $safe_distance = $bowpull_range)
	If CantExplore() Then Return False
	Local $lDeadlock
	Local $lBlocked, $OldPartyHP
	Local $lAngle
	Local $stuckTimer = TimerInit()
	$lDeadlock = TimerInit()
	If ShouldUse($SkillbarSlot[$Protective_Spirit]) Then Skill_UseSkill($SkillbarSlot[$Protective_Spirit], -2)
	If ShouldUse($SkillbarSlot[$Shielding_Hands]) Then Skill_UseSkill($SkillbarSlot[$Shielding_Hands], -2)
	Map_Move($lDestX, $lDestY, $lRandom)
	Do
		RndSleep(100)
		If Agent_GetAgentInfo(-2, "Dead") Then ExitLoop
		Map_Move($lDestX, $lDestY, $lRandom)
		If Agent_GetNearestDistance() < $safe_distance Then Survive($safe_distance)

		If Not Agent_GetAgentInfo(-2, "Moving") Then
			If Agent_GetAgentInfo(-2, "Dead") Then ExitLoop
			If Agent_GetNearestDistance() < $safe_distance Then Survive($safe_distance)
			$lBlocked += 1
			If $lBlocked < 5 Then
				Map_Move($lDestX, $lDestY, $lRandom)
				Survive($safe_distance)
			ElseIf $lBlocked < 10 Then
				$lAngle += 40
				Map_Move(X(-2) + 300 * Sin($lAngle), Y(-2) + 300 * Cos($lAngle))
				Survive($safe_distance)
			EndIf
		Else
			If Agent_GetAgentInfo(-2, "Dead") Then ExitLoop
			If Agent_GetNearestDistance() < $safe_distance Then Survive($safe_distance)
			If $lBlocked > 0 Then
				If TimerDiff($stuckTimer) > 3000 Then    ; use a timer to avoid spamming /stuck
					SendChat("stuck", "/")
					$stuckTimer = TimerInit()
				EndIf
				$lBlocked = 0
			EndIf
			If Agent_GetNearestDistance() > 1100 Then ; target is far, we probably got stuck.
				If TimerDiff($stuckTimer) > 3000 Then ; dont spam
					SendChat("stuck", "/")
					$stuckTimer = TimerInit()
					RndSleep(GetPing())
				EndIf
			EndIf
		EndIf
	Until Agent_GetDistanceToXY($lDestX, $lDestY) < 250 Or $lBlocked > 20 Or Agent_GetAgentInfo(-2, "Dead") Or TimerDiff($lDeadlock) > 60000
	Return True
EndFunc   ;==>Move55HP

; Staging WP (x,y) = fight pad; $sCoords kept for waypoint format (poke unused — pull is enemy-relative).
; Careful-style: stand at longbow of foe, heroes at longbow+500, bow-hit, wait until they move in,
; switch to set 2, then AggroMoveToEX(pad) once within spellcasting.
Func PullGroup($x, $y, $sCoords, $aRange = $room_range, $hero_increment = 500)
	#forceref $sCoords, $aRange
	If CantExplore() Then Return
	Out("PullGroup: staging at pad (" & Floor($x) & ", " & Floor($y) & ")")
	Do
		If Bot_HaltIfStopped() Or CantExplore() Then Return
		SpeedBoost()
		Map_Move($x, $y, 50)
		Sleep(50)
	Until Agent_GetDistanceToXY($x, $y) < 250 Or Agent_GetAgentInfo(-2, "IsDead")

	Local $nearestenemy = Agent_GetNearestAgent(-2, 0xDB, 3)
	If $nearestenemy = 0 Or Agent_GetAgentInfo($nearestenemy, "IsDead") Then
		Out("PullGroup: no foe near pad — AggroMoveToEX")
		AggroMoveToEX($x, $y, $spellcasting_range)
		Return
	EndIf

	; Soft-death / mid-fight resume: already in aggro — do not reflag (heroes stop fighting).
	If Agent_GetDistance($nearestenemy) <= $danger_range Then
		Out("PullGroup: already in contact (dist=" & Floor(Agent_GetDistance($nearestenemy)) & ") — CancelAll + engage pad")
		CancelAll()
		AggroMoveToEX($x, $y, 1250)
		Core_PerformAction($GC_I_CONTROL_ACTION_CLEAR_PARTY_COMMANDS, $GC_I_CONTROL_TYPE_ACTIVATE)
		Return
	EndIf

	; Heroes further from foe than our longbow stand (same geometry as CarefulAggro).
	Local $heroXY = Agent_GetClosestXYinRange($longbow_range + $hero_increment, $nearestenemy)
	Out("PullGroup: flagging heroes " & ($longbow_range + $hero_increment) & " from target")
	FlagHeptagon(300, $heroXY[0], $heroXY[1])

	Out("PullGroup: moving within longbow (" & $longbow_range & ")")
	Do
		If Bot_HaltIfStopped() Or CantExplore() Then Return
		$nearestenemy = Agent_GetNearestAgent(-2, 0xDB, 3)
		If $nearestenemy = 0 Or Agent_GetAgentInfo($nearestenemy, "IsDead") Then ExitLoop
		Local $standXY = Agent_GetClosestXYinRange($longbow_range, $nearestenemy)
		SpeedBoost()
		Map_Move($standXY[0], $standXY[1], 50)
		Sleep(50)
	Until Agent_GetDistance($nearestenemy) <= $longbow_range + 50 Or Agent_GetAgentInfo(-2, "IsDead")
	Out("PullGroup stand: foe dist=" & Floor(Agent_GetDistance($nearestenemy)) & " (want ~" & $longbow_range & ")")

	ApplyHR()
	PrecastWardsAndSpirits($spirit_range, $danger_range)
	Local $lSpiritWait = TimerInit()
	Do
		If Bot_HaltIfStopped() Or CantExplore() Then Return
		SpeedBoost()
		Sleep(250)
	Until TimerDiff($lSpiritWait) > 3000 Or Agent_IsEnemyNear($danger_range)
	If ShouldUse($SkillbarSlot[$Theyre_on_Fire]) Then Skill_TryUseSkill($SkillbarSlot[$Theyre_on_Fire])
	If ShouldUse($SkillbarSlot[$Burning_Refrain]) Then Skill_TryUseSkill($SkillbarSlot[$Burning_Refrain])

	Local $lBowSet = FindWeaponSetByItemType($TYPE_BOW)
	If $lBowSet = 0 Then $lBowSet = 4
	Out("PullGroup: bow on weapon set " & $lBowSet)
	ChangeWeaponSet($lBowSet)
	Sleep(250)
	$nearestenemy = Agent_GetNearestAgent(-2, 0xDB, 3)
	If CanAttack($longbow_range) Then Agent_Attack($BestTarget, False)

	; Hold at longbow until pack is moving in — do not body into <1000.
	Local $TimerToPull = TimerInit()
	Local $bPackMoving = False
	Do
		If Bot_HaltIfStopped() Or CantExplore() Then Return
		$nearestenemy = Agent_GetNearestAgent(-2, 0xDB, 3)
		If $nearestenemy = 0 Or Agent_GetAgentInfo($nearestenemy, "IsDead") Then ExitLoop
		If CanAttack($longbow_range) Then Agent_Attack($BestTarget, False)
		If Agent_GetAgentInfo($nearestenemy, "IsMoving") Then $bPackMoving = True
		; Ease back toward the fight pad while they close.
		If $bPackMoving Then
			SpeedBoost()
			Map_Move($x, $y, 50)
		EndIf
		RndSleep(100)
	Until ($bPackMoving And Agent_GetNearestDistance() <= $spellcasting_range) Or TimerDiff($TimerToPull) > 10000 Or CantExplore()
	Out("PullGroup: packMoving=" & $bPackMoving & " nearest=" & Floor(Agent_GetNearestDistance()) & " — engage pad")

	ChangeWeaponSet(2)
	Sleep(100)
	AggroMoveToEX($x, $y, 1250)
	Core_PerformAction($GC_I_CONTROL_ACTION_CLEAR_PARTY_COMMANDS, $GC_I_CONTROL_TYPE_ACTIVATE)
EndFunc   ;==>PullGroup

;Flag Heroes as heptagon, Hero 1 will be always flag northbound and clockwise.
Func FlagHeptagon($FlagDistance = 300, $x = X(), $y = Y())
		If CantExplore() Then Return False
		Local $Angle = 51.4285714285714286 ;conscript circle
		;Local $Angle = 64.29 ;inscribed circle
		Local $Radiant = 0.0174533 ;Radian 1°
		;Local $Radiant = 0.89011791851489996397 ;Radian 51°
		;Local $Radiant = 1.11701 ;Radian 64°
 		Local $MyAngle = Round(Agent_GetAgentInfo(-2, "Rotation"), 10)
		Local $ArrayXY[2]

;~ 		For $i = 1 to 7
;~ 			$PartySize = GetPartySize() - 1
;~ 			If $PartySize > 1 Then $Angle = 360 / $PartySize
;~ 			$theta = ($i * $Angle)
;~ 			CommandHero($i, $FlagDistance * Cos($theta * $Radiant) + $ArrayXY[0], $FlagDistance * Sin($theta * $Radiant) + $ArrayXY[1])
;~ 			Sleep(50)
;~ 		Next

		;10 = ~ 500 // 20 = ~ 1000
		Out($MyAngle)
		If $MyAngle < $NorthWest And $MyAngle > $NorthEast Then ;North 1.125 And 1.875
			Out("Flag Option: North")
			$lFlagDistance = $FlagDistance / 50
			CommandHero(1, $x + ($lFlagDistance * 15),		$y + ($lFlagDistance * 31.15)) ;Front
			Other_PingSleep(150)
			CommandHero(2, $x - ($lFlagDistance * 15),		$y + ($lFlagDistance * 31.15)) ;Front
			Other_PingSleep(150)
			CommandHero(3, $x + ($lFlagDistance * 33.7),	$y + ($lFlagDistance * 7.69))  ;Front Right side
			Other_PingSleep(150)
			CommandHero(4, $x - ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Front Left Side
			Other_PingSleep(150)
			CommandHero(5, $x + ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Back Right side
			Other_PingSleep(150)
			CommandHero(6, $x - ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Back Left Side
			Other_PingSleep(150)
			CommandHero(7, $x + ($lFlagDistance * 0), 		$y - ($lFlagDistance * 34.57)) ;Back
			Other_PingSleep(150)
		EndIf

		If $MyAngle > $SouthWest And $MyAngle < $SouthEast Then ;South -1.125 And -1.875
			Out("Flag Option: South")
			$lFlagDistance = $FlagDistance / 50
			CommandHero(1, $x + ($lFlagDistance * 0), 		$y - ($lFlagDistance * 34.57)) ;Front
			Other_PingSleep(150)
			CommandHero(2, $x + ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Front Right side
			Other_PingSleep(150)
			CommandHero(3, $x - ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Front Left Side
			Other_PingSleep(150)
			CommandHero(4, $x + ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Back Right side
			Other_PingSleep(150)
			CommandHero(5, $x - ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Back Left Side
			Other_PingSleep(150)
			CommandHero(6, $x + ($lFlagDistance * 15),	 	$y + ($lFlagDistance * 31.15)) ;Back
			Other_PingSleep(150)
			CommandHero(7, $x - ($lFlagDistance * 15), 		$y + ($lFlagDistance * 31.15)) ;Back
			Other_PingSleep(150)
		EndIf

		If $MyAngle < $NorthEast And $MyAngle > $SouthEast Then ;East 0.375 And -0.375
			Out("Flag Option: East")
			$lFlagDistance = $FlagDistance / 50
			CommandHero(1, $x + ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Front
			Other_PingSleep(150)
			CommandHero(2, $x + ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Front Right side
			Other_PingSleep(150)
			CommandHero(3, $x + ($lFlagDistance * 0), 		$y - ($lFlagDistance * 34.57)) ;Right
			Other_PingSleep(150)
			CommandHero(4, $x + ($lFlagDistance * 15), 		$y + ($lFlagDistance * 31.15)) ;Left
			Other_PingSleep(150)
			CommandHero(5, $x - ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Back Right Side
			Other_PingSleep(150)
			CommandHero(6, $x - ($lFlagDistance * 15), 		$y + ($lFlagDistance * 31.15)) ;Back Left
			Other_PingSleep(150)
			CommandHero(7, $x - ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Back
			Other_PingSleep(150)
		EndIf

		If $MyAngle > $NorthWest And $MyAngle < 3.2 Then ;West 2.625 And -2.625
			Out("Flag Option: West +")
			$lFlagDistance = $FlagDistance / 50
			CommandHero(7, $x + ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Front
			Other_PingSleep(150)
			CommandHero(6, $x + ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Front Right side
			Other_PingSleep(150)
			CommandHero(5, $x + ($lFlagDistance * 0), 		$y - ($lFlagDistance * 34.57)) ;Right
			Other_PingSleep(150)
			CommandHero(4, $x + ($lFlagDistance * 15), 	$y + ($lFlagDistance * 31.15)) ;Left
			Other_PingSleep(150)
			CommandHero(3, $x - ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Back Right Side
			Other_PingSleep(150)
			CommandHero(2, $x - ($lFlagDistance * 15), 	$y + ($lFlagDistance * 31.15)) ;Back Left
			Other_PingSleep(150)
			CommandHero(1, $x - ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Back
			Other_PingSleep(150)
		EndIf

		If $MyAngle < $SouthWest And $MyAngle < 0.1 Then
			Out("Flag Option: West -")
			$lFlagDistance = $FlagDistance / 50
			CommandHero(1, $x - ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Front
			Other_PingSleep(150)
			CommandHero(2, $x - ($lFlagDistance * 15), 	$y + ($lFlagDistance * 31.15)) ;Front Right Side
			Other_PingSleep(150)
			CommandHero(3, $x - ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Front Left Side
			Other_PingSleep(150)
			CommandHero(4, $x + ($lFlagDistance * 15), 	$y + ($lFlagDistance * 31.15)) ;Back Right Side
			Other_PingSleep(150)
			CommandHero(5, $x + ($lFlagDistance * 0), 		$y - ($lFlagDistance * 34.57)) ;Back Left Side
			Other_PingSleep(150)
			CommandHero(7, $x + ($lFlagDistance * 33.7), 	$y + ($lFlagDistance * 7.69))  ;Back
			Other_PingSleep(150)
			CommandHero(6, $x + ($lFlagDistance * 27.03), 	$y - ($lFlagDistance * 21.55)) ;Back
			Other_PingSleep(150)
		EndIf
		Return True
EndFunc

;~Flag heroes within pulling range plus a safety increment near a waypoint, go within pulling range to do the pull and aggro
Func PullEnemies($x, $y, $aRange = $bowpull_range, $hero_increment = 500, $target = Agent_GetNearestAgent(-2, 0xDB, 3))
	Out("Pulling ennemies")
	Move_ToCoord($x, $x, 50)
	If Agent_IsEnemyNear($aRange) Then
		$heroXY = Agent_GetClosestXYtoWaypointInRange($x, $x, $aRange + $hero_increment * 2, $target)
		AggroMoveToEX($heroXY[0], $heroXY[1])
		Out("Flagging heroes " & ($aRange + $hero_increment * 2) & " from target")
		FlagHeptagon(300, $heroXY[0], $heroXY[1])
		Local $iBowDist = ($target <> 0) ? Floor(Agent_GetDistance($target)) : -1
		Out("PullEnemies precast: foe dist=" & $iBowDist & " (bowpull=" & $aRange & _
				", spirit=" & $spirit_range & ", room=" & $room_range & ")")
		ApplyHR()
		PrecastWardsAndSpirits($spirit_range, $danger_range)
		For $aSkillSlot In $Skillbar
			If $SkillBarCache[$aSkillSlot][$precast] = "" Then ContinueLoop
			If ShouldUse($aSkillSlot, $aRange) Then Skill_UseSkill($aSkillSlot, $besttarget)
		Next
		Local $lBowSet = FindWeaponSetByItemType($TYPE_BOW)
		If $lBowSet = 0 Then $lBowSet = 4
		Out("PullEnemies: bow on weapon set " & $lBowSet)
		ChangeWeaponSet($lBowSet)
		Sleep(250)

		Out("Moving within " & $aRange & "distance of enemies")
		Agent_MoveToClosestXYtoWaypoint($x, $x, $aRange, $target)

		If ShouldUse($SkillbarSlot[$Ebon_Battle_Standard_Of_Honor]) Then Skill_UseSkill($SkillbarSlot[$Ebon_Battle_Standard_Of_Honor])
		If $Summon_Spirits > 0 And ShouldUse($Summon_Spirits) Then Skill_UseSkill($Summon_Spirits)
		If CanAttack($spirit_range) Then    ; sets $besttarget global variable to best target
			Agent_ChangeTarget($BestTarget)
			RndSleep(150)
			Agent_Attack($BestTarget)        ; returns false if besttarget does not exist anymore
		EndIf

		Local $TimerToPull = TimerInit()
		Do
			Sleep(200)
		Until Agent_GetAgentInfo($besttarget, "Moving") = True Or TimerDiff($TimerToPull) > 5000 Or CantExplore()
		ChangeWeaponSet(2)
		Out("Deball with heroes")
		$XY = Agent_GetClosestXYtoWaypointInRange($x, $x, 500, Agent_GetNearestAlly())
		Move_ToCoord($XY[0], $XY[1], 100)
	EndIf

	For $i = 1 to GetPartySize() - 1
		CancelHero($i)
		Other_PingSleep(200)
	Next
	AggroMoveToEX($x, $y, $spellcasting_range)

EndFunc   ;==>PullEnemies

#EndRegion Movement & Aggro

#Region Skills

Func LoadBestSkillTemplate()
	Out("Loading optimal skill bar for your profession")
	If Map_GetInstanceInfo("Type") <> $Map_Outpost Then Return
	Switch Agent_GetHeroProfession(0)
		Case $Warrior

		Case $Ranger
			LoadSkillTemplate("OgcSc5OTj1vlFHzkOMDfMMHM", 0)
		Case $Monk
			LoadSkillTemplate("OwcT4Y44ZaBaX8mstchwlg6z6DA", 0)
		Case $Necromancer
			LoadSkillTemplate("OABCUsxUu4uoCYaQVFVwWocA", 0)
		Case $Mesmer
			LoadSkillTemplate("OQBDAqwDS5inAuA5AmODBZA2gA", 0)
		Case $Elementalist

		Case $Assassin
			LoadSkillTemplate("OwFj0xfzITk1OMMMHM1g6Pxg4OA", 0)
		Case $Ritualist
			LoadSkillTemplate("OACjAaiM5S4iXTlT+gQTVTMTDgA", 0)
		Case $Paragon
			LoadSkillTemplate("OQGkUVlmpiyEPRPmoHQYNmWxO2ZN", 0)
			$herobuild = 0 ? LoadStandardHeroSetup($HeroicRefrain, $PartySize) : LoadStandardHeroSetup($herobuild, $PartySize)
		Case $Dervish
			LoadSkillTemplate("OgCjkyqDLTjeoXjbjXSXvlIYxXA", 0)
	EndSwitch
	CacheSkillBar()
	$herobuild = 0 ? LoadStandardHeroSetup($herobuild, $PartySize) : LoadStandardHeroSetup($PISurgeRezz, $PartySize)
	; LoadStandardHeroSetup refreshes hero caches after templates land.
EndFunc   ;==>LoadBestSkillTemplate

Func LoadStandardHeroSetup($Build = 1, $PartySize = 8)
;~ $Build1 = Panic/Ineptitude/E-Surge Wastrel
;~ $Build2 = PI Wastrel /Ineptitude/Esurge Spiritual Pain
;~ $Build3 = $Build 2 with rezz on Esurge mesmer
;~ $Build4 = Panic/Ineptitude/E-Surge Wastrel/Well of the Profane
;~ $Build5 = Replace esurge with RoJ mesmer
;~ $Build6 = Replace MM with RoJ + EoE monk
;~ $Build7 = Signet Mesmers + RoJ Smite Monk
;~ $Build8 = Customized for Heroic Refrain


	KickAllHeroes()

	;~ Hero 1: Master of Whispers or Mercenary Hero
	If $Build = 8 Then ; Nercenry Hero 1 (mesmer)
		AddHero($HERO_ID_MERCENARY_1)
		Sleep(200)
		If Agent_GetHeroProfession(1) = $Mesmer Then
			Other_PingSleep(200)
			ChangeSecondProfession($Ritualist, 1)
			Other_PingSleep(200)
			LoadSkillTemplate("OQBDAswzInw0nDmugnBDRRA", 1)
		Else ;~ Master of Whispers (Curses)
			KickHero($HERO_ID_MERCENARY_1)
			AddHero($HERO_ID_Master)
			Other_PingSleep(200)
			ChangeSecondProfession($Ritualist, 1)
			Other_PingSleep(200)
			LoadSkillTemplate("OAhjYgHcoOP1qqdARg0GmSzJHA", 1)
		EndIf
	ElseIf $Build < 8 Then
		AddHero($HERO_ID_Master)
		Other_PingSleep(200)
		ChangeSecondProfession($Ritualist, 1)
		Other_PingSleep(200)
		LoadSkillTemplate("OAhjYgHb4OP1qqdwSUGGmSzJHA", 1)

	EndIf

	;~ Hero 2: Livia (BiP Healer)
	AddHero($HERO_ID_Livia)
	Other_PingSleep(200)
	ChangeSecondProfession($Ritualist, 2)
	Other_PingSleep(200)
	If $Build < 7 Then LoadSkillTemplate("OAhjQoGYIP3hq6QbcOMncSThHA", 2)
	If $Build > 6 Then LoadSkillTemplate("OAhjQoGYIP3hqq0cyJ8GmU7LGA", 2)    ; Replace blood bond wit rezz in non physical team

	;~ Hero 3: Olias, Dunkoro or Mercenary 2
	Switch $Build
		Case 1 to 6
			AddHero($HERO_ID_Olias)     ; Olias / AotL
			Other_PingSleep(200)
			ChangeSecondProfession($Paragon, 3)
			Other_PingSleep(200)
			If $Build <> 4 And $Build <> 5 Then LoadSkillTemplate("OAlkUwG4RZmkcQV1R1ngC4OWN2WI", 3)
			If $Build = 4 Then LoadSkillTemplate("OAlkUwGpJeWESlCYJDVAeQV1OmKG", 3) ; Change from AotL to Oder of Undeath for Heroic Refrain
			If $Build = 5 Then LoadSkillTemplate("OAljUwGopSyBVVeBHVKg7Y1YbhA", 3) ; Modified bar with Well of the Profane
		Case 7
			AddHero($Hero_ID_Dunkoro)        ; RoJ
			Other_PingSleep(200)
			ChangeSecondProfession($Paragon, 3)
			Other_PingSleep(200)
			LoadSkillTemplate("Owkj4wQjJP+MqvLBva9dr14dMA", 3) ; RoJ + Fall Back
		Case 8 ;
			AddHero($HERO_ID_MERCENARY_2)
			If Agent_GetHeroProfession(1) = $Mesmer Then
				Other_PingSleep(200)
				ChangeSecondProfession($Ritualist, 3)
				Other_PingSleep(200)
				LoadSkillTemplate("OQZDAswjInw0nDmeMkBDByA", 3)
			Else ;~ Olias (Order of Undeath)
				KickHero($HERO_ID_MERCENARY_2)
				AddHero($HERO_ID_Olias)
				Other_PingSleep(200)
				ChangeSecondProfession($Paragon, 3)
				Other_PingSleep(200)
				LoadSkillTemplate("OAlkUwGpJeWESlCYJDVAeQV1OmKG", 3)
			EndIf
	EndSwitch
	Other_PingSleep(200)

;~ Norgu
	AddHero($HERO_ID_Norgu)
	Other_PingSleep(200)
	ChangeSecondProfession($Ritualist, 4)
	Other_PingSleep(200)
	;ClearAttributes(4)
	If $Build < 8 Then LoadSkillTemplate("OQhkAgBsgGK0LAJQeWOgpDCYRwFD", 4)
	If $Build = 8 Then LoadSkillTemplate("OQhkAsB8gFK0LAJACYe2I0bDH0FD", 4)

;~ Gwen
	AddHero($HERO_ID_Gwen)
	Other_PingSleep(200)
	ChangeSecondProfession($Ritualist, 5)
	Other_PingSleep(200)
	;ClearAttributes(5)
	Switch $Build
		Case 1, 4 to 7
			LoadSkillTemplate("OQhkAkBpAHOENw0TOgpzQQeGC4FD", 5)    ; Panic
		Case 2
			LoadSkillTemplate("OQhkAsC8gFKTIc6Z6yB30MwQ4iB", 5)		; Psychic Instability Wastrels
		Case 3
			LoadSkillTemplate("OQhkAkBpAHOUI00TOgpzQQeGC4FD", 5)	; Psychic Instability Clumsiness
		Case 8
			LoadSkillTemplate("OQhkAwC8gEKzJY6lDMdCuMgGAnC", 5)		; E-Surge + overload for Heroic Refrain
	EndSwitch

;~ Optional 7th (Razah or Dunkoro)
	If $PartySize = 8 Then
		Switch $Build
			Case 5
				AddHero($Hero_ID_Dunkoro)    ; RoJ
				Other_PingSleep(200)
				ChangeSecondProfession($Paragon, 6)
				Other_PingSleep(200)
				LoadSkillTemplate("Owkj4wQopO+MqvLBva9dr14dMA+omAdAA", 6)    ; RoJ + EoE

			Case Else
				AddHero($HERO_ID_Razah)        ; Razah / e-Surge
				Other_PingSleep(200)
				ChangeSecondProfession($Ritualist, 6)
				Other_PingSleep(200)
				If $Build <> 2 And $Build < 7 Then LoadSkillTemplate("OQhkAsC8gFKzJY6lDMd30hQG4iB", 6)    ; E-Surge wastrels
				If $Build = 2 Then LoadSkillTemplate("OQhkAsC8gFKzJY6lDMd40hQG4iB", 6)    ; E-Surge spirital pain
				If $Build = 7 Then LoadSkillTemplate("OQhkAsC8gFKTIc6Z6yB30MwQ4iB", 6)    ; PI Wastrels
				If $Build = 8 Then LoadSkillTemplate("OQhkAwC8gEKzJY6lDMd30MwQ4iB", 6)    ; E-Surge + Watrels for Heroic Refrain
		EndSwitch
	EndIf

;~ Xandra / ST Ritualist
	If $PartySize > 6 Then
		AddHero($HERO_ID_Xandra)
		Other_PingSleep(200)
		ChangeSecondProfession($Ritualist, 7)
		Other_PingSleep(200)
		Switch GetPrimaryProfession()
			Case $Paragon, $Ritualist
				LoadSkillTemplate("OAmjAyks5MYTrX48xBNVnIXnJA", 7)
			Case Else
				LoadSkillTemplate("OACjEaiM5SXTlTdiYMVTMTOOXMA", 7)
		EndSwitch
	EndIf

	; UI "Load skills" / LoadBestSkillTemplate end here — bars must be re-cached after templates.
	Other_PingSleep(500)
	CacheHeroHeals()
	CacheHeroPrecast()
	CacheHeroProts()
	CacheBiP()
EndFunc   ;==>LoadStandardHeroSetup

#Region Quest

; Thin Logic shims → GwAu3 Modules/Cmd (Quest_GetQuestInfo / Ui_* / Quest_*).





; True when quest is completed / rewardable (old Logic LogState cases).


#EndRegion Quest

#Region Loot

Func PickupLootEx($iMaxDist = 2000, $aPickupTorch = False)
	Local $lAgentPtr, $lAgentID, $lItemPtr, $lOwner, $lDeadlock
	Local $lAgentPtrArray = Agent_GetAgentArray(0x400)
	For $i = 1 To $lAgentPtrArray[0]
		If Bot_HaltIfStopped() Then Return
		If Agent_GetAgentInfo(-2, "IsDead") Then Return
		$lAgentPtr = $lAgentPtrArray[$i]
		$lAgentID = Agent_ID($lAgentPtr)
		$lItemPtr = Item_GetItemPtr(Item_GetItemInfoByAgentID($lAgentID, "ItemID"))
		If $lItemPtr = 0 Then ContinueLoop
		$lOwner = Agent_GetAgentInfo($lAgentPtr, "Owner")
		If $lOwner <> 0 And $lOwner <> Agent_GetMyID() Then ContinueLoop ; assigned to another player
		If CanPickUpEx($lItemPtr, $aPickupTorch) And Agent_GetDistance($lAgentID) < $iMaxDist Then
			Agent_MoveToXY(X($lAgentPtr), Y($lAgentPtr))
			$lDeadlock = TimerInit()
			Do
				If Bot_HaltIfStopped() Then Return
				Item_PickUpItem($lAgentID)
				Other_PingSleep(250)
			Until Agent_GetAgentPtr($lAgentID) = 0 Or Agent_GetAgentInfo(-2, "IsDead") Or TimerDiff($lDeadlock) > 6000
		EndIf
	Next
EndFunc   ;==>PickupLootEx

; Shared torch pickup (BDS / SoO waypoint cases). Model 22342 via CanPickUpEx.
Func PickupTorch()
	PickupLootEx(5000, True)
EndFunc   ;==>PickupTorch

; Light nearest brazier at XY; optional torch pickup / drop afterward.
; Matches Logic: success = Lit remaining > 28s (already-lit counts); $unlit only if no Lit effect after try.
Func LightBrazier($x, $y, $aPickupTorch = False, $aDropTorch = False)
	Sleep(50)
	If Wipe() = 1 Then Return
	If $aPickupTorch Then PickupTorch()
	; Logic: no ApplyHR here — that stalled 45s on empty pads. SpeedBoost on the walk only.
	If Wipe() = 0 Then
		Do
			If Bot_HaltIfStopped() Or Wipe() = 1 Or Agent_GetAgentInfo(-2, "IsDead") Then Return
			SpeedBoost()
			Map_Move($x, $y, 50)
			Sleep(50)
		Until Agent_GetDistanceToXY($x, $y) < 250 Or Wipe() = 1 Or Agent_GetAgentInfo(-2, "IsDead")
	EndIf

	Local $lDeadlock = TimerInit()
	Local $lBrazier = 0
	Do
		$lBrazier = GetNearestBrazierToCoords($x, $y)
		Sleep(500)
	Until $lBrazier <> 0 Or Wipe() = 1 Or TimerDiff($lDeadlock) > 300000
	If $lBrazier = 0 Or Wipe() = 1 Then Return

	Agent_ChangeTarget($lBrazier)
	Out("Lit effect remaining: " & Floor(GetEffectTimeRemaining($Lit_Torch) / 1000) & "s, rekindling")
	Local $lTimer = TimerInit()
	Do
		RndSleep(200)
		ActionInteract()
		Sleep(100)
		Agent_GoSignpost($lBrazier)
	Until GetEffectTimeRemaining($Lit_Torch) > 28000 Or TimerDiff($lTimer) > 5000 Or Agent_GetAgentInfo(-2, "IsDead")

	; Logic: set $unlit if Lit missing, but still DropBundle when requested (before any Return).
	If Not Skill_HasEffect($Lit_Torch) And Not Agent_GetAgentInfo(-2, "IsDead") Then
		Out("No Lit effect after brazier — will backtrack")
		$unlit = True
	Else
		$unlit = False
	EndIf
	Sleep(50)
	If $aDropTorch And Not Agent_GetAgentInfo(-2, "IsDead") Then
		Item_DropBundle()
		Out("Dropped torch after brazier")
	EndIf
EndFunc   ;==>LightBrazier

; SoO braziers use low gadget agent IDs (< 12) near the waypoint.
Func GetNearestBrazierToCoords($x, $y)
	Local $lAgentPtrArray = Agent_GetAgentArray(0x200)
	Local $i, $lID, $lDistance
	For $i = 1 To $lAgentPtrArray[0]
		$lID = Agent_ID($lAgentPtrArray[$i])
		If $lID > 11 Then ContinueLoop
		$lDistance = Agent_GetDistanceToXY($x, $y, $lID)
		If $lDistance < 500 Then Return $lAgentPtrArray[$i]
	Next
	Return 0
EndFunc   ;==>GetNearestBrazierToCoords

Func CanPickUpEx($aItem, $PickupTorch = False)
	Local $lItemPtr = Item_GetItemPtr($aItem)
	If $lItemPtr = 0 Then Return False
	Local $lType = Item_GetItemInfoByPtr($lItemPtr, "ItemType")
	Local $lExtraID = Item_GetItemInfoByPtr($lItemPtr, "ExtraID")
	Local $lModelID = Item_GetItemInfoByPtr($lItemPtr, "ModelID")
	Local $lRarity = Item_GetItemInfoByPtr($lItemPtr, "Rarity")
	Local $lQuantity = Item_GetItemInfoByPtr($lItemPtr, "Quantity")
	Local $lValue = Item_GetItemInfoByPtr($lItemPtr, "Value")
	Local $lReq = Item_GetItemReq($lItemPtr)
	Local $lDmg = Item_GetItemMaxDmg($lItemPtr)

	If Item_CountEmptySlots(InventoryBagList()) < 2 And $lType <> $TYPE_BUNDLE And $lType <> $TYPE_GOLD_COINS Then Return False

	If IsReq7Max($aItem) Then Return True
	If IsReq8Max($aItem)  Then Return True
	If IsPerfectShield($aItem) Then Return True
	If IsPerfectStaff($aItem) Then Return True
	If IsPerfectCaster($aItem) Then Return True
	If IsRareRune($aItem) Then Return True

	If $aRareSkin[$lModelID] <> "" Then
		If $lRarity = $RARITY_Gold Or $lRarity = $RARITY_Green Then
			Out("Picking up " & $aRareSkin[$lModelID])
			$RareSkinsCount += 1
			GUI_SetRareSkins($RareSkinsCount)
			Return True
		ElseIf $lRarity = $RARITY_Purple Then
			Switch $lModelID
				Case 114, 117, 118, 205, 399
					Out("Picking up " & $aRareSkin[$lModelID])
					$RareSkinsCount += 1
					GUI_SetRareSkins($RareSkinsCount)
					Return True
			EndSwitch
		EndIf
	EndIf

	Switch $lModelID
		Case 2619, 36985 ;Unholy text from Fow, misterial commendations
			Return True
		Case 2605, 2606, 501 To 503, 2566, 2607, 6102, 6104, 6531, 15564, 15565, 15867, 15869 To 15871, 17054, 17055 _
				, 17075, 22781, 22782, 25410, 25413, 25416, 24628, 24582 ; General quest items: Prison key (25413), etc.
			Return True
		Case 472, 474, 476, 522
			Return True
	EndSwitch

	Switch $lRarity ; green items are picked up by ModelID via the $aRareSkin array.
		Case $RARITY_Gold ; Gold Items
			GUI_SetGolds(GUI_GetGolds() + 1)
			Return True
;~ 		Case $RARITY_Green
;~ 			Return True
	EndSwitch

	Switch $lType
		Case $TYPE_BUNDLE
			; Param OR global $unlit — RekindleTorch / desynced $PickupTorch still grab the torch.
			If $lModelID = 22342 And ($PickupTorch Or $unlit) Then
				Out("Grab unlit torch")
				Return True
			EndIf

		Case $TYPE_DYE
			If $lExtraID = 10 Then ; Black dye
				GUI_SetBlackDyes(GUI_GetBlackDyes() + 1)
				Return True
			EndIf
		Case $TYPE_GOLD_COINS
			If $lModelID = 2511 And GetPartySize() < 3 And Item_GetGoldCharacter() + $lValue < 100000 Then Return True
			; gold / plat, only worth it in small party
		Case $TYPE_KEY
			If $lModelID = 22751 Then GUI_SetDroppedLockpicks(GUI_GetDroppedLockpicks() + 1)
			If $lModelID = 22751 Then GUI_SetLockpicks(GetPicksCount())
			If $lModelID = 25410 Or $lModelID = 25416 Then Out("Grab Dungeon Key")
			Return True

		Case $TYPE_MATERIAL_AND_ZCOINS, $TYPE_SCROLL	; , $TYPE_TROPHY
			Return True
		Case $TYPE_USABLE
			Switch $lModelID
				Case 21786 To 21805
					GUI_SetTomes(GUI_GetTomes() + 1)    ; update GUI for tomes only
			EndSwitch
			Return True
		Case $TYPE_OFFHAND
			If $lDmg == 12 And $lReq == 8 And $lRarity = $RARITY_Gold Then Return True
		Case $TYPE_SWORD
			If $lDmg == 22 And $lReq == 8 And $lRarity = $RARITY_Gold Then Return True
		Case $TYPE_SHIELD ; shields
			If $lReq = 8 And $lDmg = 16 And ($lRarity = $RARITY_Gold Or $lRarity = $RARITY_Purple) Then Return True ; Req8 Shields
			If $lReq = 7 And $lDmg = 15 And ($lRarity = $RARITY_Gold Or $lRarity = $RARITY_Purple) Then Return True ; Req7 Shields
			If $lReq = 6 And $lDmg = 14 And ($lRarity = $RARITY_Gold Or $lRarity = $RARITY_Purple) Then Return True ; Req6 Shields
			If $lReq = 5 And $lDmg = 13 And ($lRarity = $RARITY_Gold Or $lRarity = $RARITY_Purple) Then Return True ; Req5 Shields
			If $lReq = 4 And $lDmg = 12 And ($lRarity = $RARITY_Gold Or $lRarity = $RARITY_Purple) Then Return True ; Req4 Shields
	EndSwitch

	Return False
EndFunc   ;==>CanPickUpEx

Func GetTargetItemModelID()
	Local $iAgentID = Agent_GetCurrentTarget()
	If $iAgentID = 0 Then Return 0
	Return Item_GetItemInfoByAgentID($iAgentID, "ModelID")
	Return $lModelID
EndFunc   ;==>GetTargetItemModelID

Func GetTargetExtratype()
	Local $iAgentID = Agent_GetCurrentTarget()
	If $iAgentID = 0 Then Return 0
	Return Item_GetItemInfoByAgentID($iAgentID, "ExtraID")
	Out($lExtraID)
	Return $lExtraID
EndFunc   ;==>GetTargetExtratype

Func TakePowder($x, $y)
	Agent_GoToNPCnearXY($x, $y, 6179)
	Other_PingSleep(500)
	Move_ToCoord($x, $y)
	DropBundle()
	AggroMoveToEX($x, $y)
EndFunc   ;==>TakePowder

Func MountJunundu($x, $y)
	If GetSkillbarSkillID(8) = $Leave_Junundu Then Return
	Out("Mounting Junundu")
	AggroMoveToEx($x, $y)
	CommandAll($x, $y, True, $earshot_range)	; waits for heroes to reach destination
	Agent_GoToSignpostNearXY($x, $y)
	Do
		Sleep(1000)
	Until GetSkillbarSkillID(8) = $Leave_Junundu
	CacheSkillBar()
	CancelAll()
EndFunc

Func UnmountJunundu($x, $y)
	Out("Unmounting Junundu")
	AggroMoveToEx($x, $y)
	If ShouldUse($SkillbarSlot[$Leave_Junundu]) Then Skill_UseSkill($SkillbarSlot[$Leave_Junundu])
	Do
		Sleep(1000)
	Until GetSkillbarSkillID(8) <> $Leave_Junundu
	CacheSkillBar()
EndFunc

#EndRegion Loot

#Region Item Use
; Scrolls / stones / consets only fire inside dungeon maps (RegionType Dungeon), not open explorables.
Func _ItemUse_IsDungeon()
	Return Map_GetInstanceInfo("IsExplorable") And Map_GetCurrentAreaInfo("RegionType") = $GC_I_MAP_REGIONTYPE_Dungeon
EndFunc   ;==>_ItemUse_IsDungeon

Func UseAlcohol($aAlcohol = 0) ;Uses Alcohol if in inventory remaining effect is less than 2 seconds
	If $aAlcohol <> 0 Then Item_UseItem(Item_GetBagsItembyModelID($aAlcohol))
EndFunc   ;==>UseAlcohol

Func UseItemByModelId($iModelID)
	Local $lItemID = Item_GetBagsItembyModelID($iModelID)
	If $lItemID = 0 Then Return False
	Item_UseItem($lItemID)
	Return True
EndFunc   ;==>UseItemByModelId

Func UseScroll() ;Uses scroll if in inventory based on GUI checkbox
	If Not _ItemUse_IsDungeon() Then Return
	For $i = 0 To UBound($XP_Scrolls) - 1
		If Skill_HasEffect($XP_Scrolls[$i][1]) Then Return Out("Already under the effect of a scroll")
	Next
	Local $lItemID
	For $i = 0 To UBound($XP_Scrolls) - 1
		$lItemID = Item_GetBagsItembyModelID($XP_Scrolls[$i][0])
		If $lItemID <> 0 Then Return Item_UseItem($lItemID)
	Next
	Out("No scrolls found")
EndFunc   ;==>UseScroll

Func UseStones($aStone = 0) ;Uses summoning stone if in inventory based on GUI checkbox
	If Not _ItemUse_IsDungeon() Then Return
	If Skill_HasEffect($Summoning_Sickness) Then Return Out("Can't summon (summoning sickeness)")
	Local $lItemID
	If $aStone <> 0 Then
		$lItemID = Item_GetBagsItembyModelID($aStone)
		If $lItemID <> 0 Then Return Item_UseItem($lItemID)
	Else
		For $i = 0 To UBound($Summoning_Stones) - 1
			If $Summoning_Stones[$i] = $Stone_Igneous And Agent_GetAgentInfo(-2, "Level") > 19 Then ContinueLoop
			$lItemID = Item_GetBagsItembyModelID($Summoning_Stones[$i])
			If $lItemID <> 0 Then Return Item_UseItem($lItemID)
		Next
	EndIf
	Out("No summoning stones found")
EndFunc   ;==>UseStones

Func UseIgneous()
	UseStones($Stone_Igneous)
EndFunc   ;==>UseIgneous

Func UseLegion() ; Helps a lot with Hard mode
	UseStones($Stone_Legionnaire)
EndFunc   ;==>UseLegion

Func UseZaishen()
	UseStones($Stone_Zaishen)
EndFunc   ;==>UseZaishen

Func UseAutomaton()
	UseStones($Stone_Automaton)
EndFunc   ;==>UseAutomaton

Func UseChitinous()
	UseStones($Stone_Chitinous)
EndFunc   ;==>UseChitinous

Func UseAmber()
	UseStones($Stone_Amber)
EndFunc   ;==>UseAmber

Func UseArtic()
	UseStones($Stone_Artic)
EndFunc   ;==>UseArtic

Func UseDemonic()
	UseStones($Stone_Demonic)
EndFunc   ;==>UseDemonic

Func UseGeletinous()
	UseStones($Stone_Geletinous)
EndFunc   ;==>UseGeletinous

Func UseFossilized()
	UseStones($Stone_Fossilized)
EndFunc   ;==>UseFossilized

Func UseJadeite()
	UseStones($Stone_Jadeite)
EndFunc   ;==>UseJadeite

Func UseMischievous()
	UseStones($Stone_Mischievous)
EndFunc   ;==>UseMischievous

Func UseFrosty()
	UseStones($Stone_Frosty)
EndFunc   ;==>UseFrosty

Func UseGhastly()
	UseStones($Stone_Ghastly)
EndFunc   ;==>UseGhastly

Func UseCelestial()
	UseStones($Stone_Celestial)
EndFunc   ;==>UseCelestial

Func UseMystical()
	UseStones($Stone_Mystical)
EndFunc   ;==>UseMystical

Func UseMysterious()
	UseStones($Stone_Mysterious)
EndFunc   ;==>UseMysterious

Func UseShiningBlade()
	UseStones($Stone_Shining_Blade) ; may be incorrect
EndFunc   ;==>UseShiningBlade

Func UseImperialGuard()
	UseStones($Stone_Imperial_Guard)
EndFunc   ;==>UseImperialGuard

Func UseTengu()
	UseStones($Stone_Tengu)
EndFunc   ;==>UseTengu

Func UseMerchant()
	UseStones($Stone_Merchant)
EndFunc   ;==>UseMerchant

Func UseConsets($aConset = 0) ;Uses Consets if in inventory based on GUI checkbox and remaining effect is less than 1 minute
	If Not _ItemUse_IsDungeon() Then Return
	Local $lItemID
	If $aConset <> 0 Then
		$lItemID = Item_GetBagsItembyModelID($aConset)
		If $lItemID <> 0 Then Return Item_UseItem($lItemID)
		Return
	EndIf
	For $i = 0 To UBound($Consets) - 1
		$lItemID = Item_GetBagsItembyModelID($Consets[$i][0])
		If $lItemID <> 0 And GetEffectTimeRemaining($Consets[$i][1]) < 60000 Then Item_UseItem($lItemID)
	Next
EndFunc   ;==>UseConsets

Func UseArmor()
	UseConsets($Armor_Of_Salvation)
EndFunc   ;==>UseArmor

Func UseEssence()
	UseConsets($Essence_Of_Celerity)
EndFunc   ;==>UseEssence

Func UseGrail()
	UseConsets($Grail_Of_Might)
EndFunc   ;==>UseGrail

Func UseDPRemoval($aDP_Removal = 0) ;Uses DP removal if in inventory while morale is below 0
	If Map_GetInstanceInfo("Type") <> 1 Then Return
	Local $lItemID
	While GetMorale() < 0
		If $aDP_Removal <> 0 Then
			$lItemID = Item_GetBagsItembyModelID($aDP_Removal)
			If $lItemID <> 0 And GetMorale() < 0 Then Item_UseItem($lItemID)
		Else
			For $i In $DP_Removal
				$lItemID = Item_GetBagsItembyModelID($i)
				If $lItemID <> 0 And GetMorale() < 0 Then Item_UseItem($lItemID)
			Next
		EndIf
		Sleep(200)
	WEnd
EndFunc   ;==>UseDPRemoval

Func UseClover()
	UseDPRemoval($DP_Clover)
EndFunc   ;==>UseClover

Func UseHoneycomb()
	UseDPRemoval($DP_Honeycomb)
EndFunc   ;==>UseHoneycomb

Func UsePumpkinCookie()
	UseDPRemoval($DP_Pumpkin_Cookie)
EndFunc   ;==>UsePumpkinCookie

Func UseRefinedJelly()
	UseDPRemoval($DP_Refined_Jelly)
EndFunc   ;==>UseRefinedJelly

Func UseWintergreenCandyCane()
	UseDPRemoval($DP_Wintergreen_Candy_Cane)
EndFunc   ;==>UseWintergreenCandyCane

Func UseRainbowCandyCane()
	UseDPRemoval($DP_Rainbow_Candy_Cane)
EndFunc   ;==>UseRainbowCandyCane

Func UsePeppermintCandyCane()
	UseDPRemoval($DP_Peppermint_Candy_Cane)
EndFunc   ;==>UsePeppermintCandyCane

Func UsePcons($aPcon = 0)
	If Map_GetInstanceInfo("Type") <> 1 Then Return
	Local $lItemID
	If $aPcon <> 0 Then
		$lItemID = Item_GetBagsItembyModelID($aPcon)
		If $lItemID <> 0 Then Return Item_UseItem($lItemID)
		Return
	EndIf
	For $i = 1 To UBound($Pcons) - 1
		$lItemID = Item_GetBagsItembyModelID($Pcons[$i][0])
		If $lItemID <> 0 And GetEffectTimeRemaining($Pcons[$i][1]) < 5000 Then Item_UseItem($lItemID)
	Next
EndFunc   ;==>UsePcons

Func UseCupcake()
	UsePcons($Pcons_Cupcake)
EndFunc   ;==>UseCupcake

Func UsePumpkin()
	UsePcons($Pcons_Pumpkin_Pie)
EndFunc   ;==>UsePumpkin

Func UseDrakeKabob()
	UsePcons($Pcons_Drake_Kabob)
EndFunc   ;==>UseDrakeKabob

Func UseSkalefinSoup()
	UsePcons($Pcons_Skalefin_Soup)
EndFunc   ;==>UseSkalefinSoup

Func UsePahnaiSalad()
	UsePcons($Pcons_Pahnai_Salad)
EndFunc   ;==>UsePahnaiSalad

Func UseGoldeEgg()
	UsePcons($Pcons_Golde_Egg)
EndFunc   ;==>UseGoldeEgg

Func UseCandyCorn()
	UsePcons($Pcons_Candy_Corn)
EndFunc   ;==>UseCandyCorn

Func UseCandyApple()
	UsePcons($Pcons_Candy_Apple)
EndFunc   ;==>UseCandyApple

Func UseLunarFortune()
	UsePcons($Pcons_Lunar_Fortune)
EndFunc   ;==>UseLunarFortune

Func UseLunarFortune2()
	UsePcons($Pcons_Lunar_Fortune_2)
EndFunc   ;==>UseLunarFortune2

Func UseWarSupplies()
	UsePcons($Pcons_War_Supplies)
EndFunc   ;==>UseWarSupplies

Func UseBlueRock()
	UsePcons($Pcons_Blue_Rock)
EndFunc   ;==>UseBlueRock

Func UseGreenRock()
	UsePcons($Pcons_Green_Rock)
EndFunc   ;==>UseGreenRock

Func UseRedRock()
	UsePcons($Pcons_Red_Rock)
EndFunc   ;==>UseRedRock

; Logic-main Wipe: player dead AND (no rez left / party mostly dead / HP collapsed).
; IsDefeated alone misses shrine deaths — MoveAndAggro never ran WipeManagement / rez-waypoint snap.
Func Wipe()
	If Party_GetPartyContextInfo("IsDefeated") Then Return True
	If Not Agent_GetAgentInfo(-2, "IsDead") Then Return False

	Local $l_i_PartySize = Party_GetPartyContextInfo("TotalPartySize")
	If $l_i_PartySize <= 0 Then $l_i_PartySize = GetPartySize()
	Local $l_i_DeadPartyMembers = 0
	Local $i, $l_i_AgentID
	For $i = 1 To $l_i_PartySize
		$l_i_AgentID = Party_GetMemberAgentID($i)
		If $l_i_AgentID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($l_i_AgentID, "IsDead") Then $l_i_DeadPartyMembers += 1
	Next

	If GetAvailableRezz() = 0 Or $l_i_DeadPartyMembers >= $l_i_PartySize - 1 Or Party_GetPartyHealth() < 0.15 Then Return True
	Return False
EndFunc   ;==>Wipe


Func GetAgentNameArraySorted($lAgentName)     ;returns a 2-dimensional array([agentID, [distance]) sorted by distance
	Local $lDistance
	Local $lAgentArray = GetAgentArray($lAgentName)
	Local $lReturnArray[1][2]
	Local $lMe = Agent_GetAgentInfo(-2, "ID")
	Local $AgentID
	For $i = 1 To $lAgentArray[0]
		$lDistance = (X(-2) - X($lAgentArray[$i])) ^ 2 + (Y(-2) - Y($lAgentArray[$i])) ^ 2
		$AgentID = DllStructGetData($lAgentArray[$i], 'ID')
		ReDim $lReturnArray[$i][2]
		$lReturnArray[$i - 1][0] = $AgentID
		$lReturnArray[$i - 1][1] = Sqrt($lDistance)
	Next
	_ArraySort($lReturnArray, 0, 0, 0, 1)
	Return $lReturnArray
EndFunc   ;==>GetAgentNameArraySorted

#EndRegion Item Use

#Region Inventory

Func Trade_ClearInventory()
	Local $aItem, $aMod, $Timer
	Out("Cleaning Inventory")
	Map_TravelGH()
	CheckGuildHall()
	Other_PingSleep(500)
	If GUI_IsRareSkinsChecked() Then Item_StoreRareSkins()
	Item_StoreTomes()
	Item_SalvageSellItems()
	Sleep(500)
	Map_LeaveGH()
	Sleep(500)
	Map_TravelGH()
	Sleep(500)
	SellRunes()
	SellMaterials()
	Sleep(500)
;~ 	BuyScrolls()
	Map_LeaveGH()
EndFunc   ;==>ClearInventory

;~ Description: Cleaned up Salvage & Sell routine with automated kit purchasing.
Func Item_SalvageSellItems()
	Item_DepositGold(800000)
	Merchant()

	If Item_GetGoldCharacter() < 2500 Then
		Out("Withdrawing gold")
		Item_WithdrawGold(3000 - Item_GetGoldCharacter())
	EndIf
	Other_PingSleep(500)

	; Initial kit checks
	Merchant_RefillKits(60)
	Item_IdentifyAll()

	For $bag = 1 To $UseBags
		$lBagPtr = Item_GetBagPtr($bag)
		If $lBagPtr = 0 Then ContinueLoop

		For $slot = 1 To Item_GetBagInfo($bag, "Slots")
			$lItemPtr = Item_GetItemBySlot($bag, $slot)
			If $lItemPtr = 0 Then ContinueLoop
			If Not Item_CanSell($lItemPtr) Then ContinueLoop

			If Item_HasUsefulMod($lItemPtr) Then
				Merchant_RefillKits(60)
				; Item_SalvageMod is gone. Expert kit salvages the prefix/insignia slot.
				Item_SalvageItem($lItemPtr, "Expert", "Prefix")
				Other_PingSleep(50)
			Else
				Merchant_SellItem($lItemPtr)
			EndIf
		Next
	Next

EndFunc   ;==>Item_SalvageSellItems

Func Item_HasUsefulMod($aItem)
	Local $Mods[184][4]
	If FileExists($MOD_INI_PATH) Then
		Local $lIniMods = _iniToArray($MOD_INI_PATH, "array_weaponmods")
		If IsArray($lIniMods) Then
			$array_weaponmods_ini = $lIniMods
		Else
			$array_weaponmods_ini = $array_weaponmods
		EndIf
	Else
		$array_weaponmods_ini = $array_weaponmods
	EndIf

	$aModStruct = Item_GetModStruct($aItem)
	$atype = Item_GetItemInfoByPtr(Item_GetItemPtr($aItem), "ItemType")

	Switch $atype
		Case 0
			Out("Type Salvage")
			For $i = 0 To UBound($array_armormods) - 1
				If $array_armormods[$i][4] = 1 And StringInStr($aModStruct, $array_armormods[$i][3]) > 0 Then
					Out("Item has useful mod " & $array_armormods[$i][0])
					SetExtended($array_armormods[$i][2])
					Return True
				EndIf
			Next

		Case 2, 5, 12, 15, 22, 24, 26, 27, 32, 35, 36
			; Type Weapon
			For $j = 0 To 10
				For $i = 0 To UBound($array_weaponmods) - 1
					If $atype = $TYPE_ID[$j] And StringInStr($aModStruct, $array_weaponmods_ini[$i][2]) > 0 And $array_weaponmods_ini[$i][$j + 4] = 1 Then ; if type is weapon type and modstruct corresponds and the relevant weapon type is marked as a 1
						Out("Item has useful mod " & $array_weaponmods[$i][0] & " with index " & $array_weaponmods_ini[$i][1])
						SetExtended($array_weaponmods_ini[$i][1])
						Return True
					EndIf
				Next
			Next
	EndSwitch

	Return False

EndFunc   ;==>HasUsefulMod

Func SellRunes()
	RuneTrader()
	Sleep(GetPing() + 1000)
	For $bag = 1 To $UseBags
		$lBagPtr = Item_GetBagPtr($bag)
		If $lBagPtr = 0 Then ContinueLoop
		For $slot = 1 To Item_GetBagInfo($bag, "Slots")
			$lItemPtr = Item_GetItemBySlot($bag, $slot)
			If $lItemPtr = 0 Then ContinueLoop
			$lItemType = Item_GetItemInfoByPtr($lItemPtr, "ItemType")
			$lItemModelID = Item_GetItemInfoByPtr($lItemPtr, "ModelID")
			If $lItemType == $TYPE_RUNE_AND_MOD And Item_CanSellRune($lItemModelID) Then
				If Item_GetGoldCharacter() >= 50000 Then Item_DepositGold(90000)
				Merchant_SellItem($lItemPtr, 0, True)
			EndIf
		Next
	Next
EndFunc   ;==>SellRunes

Func SellMaterials()

	For $bag = 1 To $UseBags
		$lBagPtr = Item_GetBagPtr($bag)
		If $lBagPtr = 0 Then ContinueLoop
		For $slot = 1 To Item_GetBagInfo($bag, "Slots")
			$lItemPtr = Item_GetItemBySlot($bag, $slot)
			If $lItemPtr = 0 Then ContinueLoop
			If Item_GetItemInfoByPtr($lItemPtr, "ItemType") <> 11 Then ContinueLoop
			Switch MaterialRarity($lItemPtr)
				Case 2
					RareMaterialTrader()
					Out("Sell rare material in " & $bag & ", " & $slot)
					Merchant_SellItem($lItemPtr, 0, True)
				Case 1
					Out("material detected" & $bag & ", " & $slot)
					$TotalStacks = Item_GetItemInfoByPtr($lItemPtr, "Quantity") / 10
					If  $TotalStacks < 1 Then ContinueLoop
					Agent_GoToNPCnearXY(X(), Y(), GetMaterialTrader())
					Out("Sell materials in " & $bag & ", " & $slot)
					Merchant_SellItem($lItemPtr, 0, True)
			EndSwitch
		Next
	Next
EndFunc   ;==>SellMaterials

Func SellScrolls()
	ScrollTrader()
	For $bag = 1 To 4
		$lBagPtr = Item_GetBagPtr($bag)
		If $lBagPtr = 0 Then ContinueLoop
		For $slot = 1 To Item_GetBagInfo($bag, "Slots")
			$lItemPtr = Item_GetItemBySlot($bag, $slot)
			If $lItemPtr = 0 Then ContinueLoop
			If Item_GetItemInfoByPtr($lItemPtr, "ItemType") <> 31 Then ContinueLoop
			If Item_GetItemInfoByPtr($lItemPtr, "Rarity") <> 2624 Then ContinueLoop
			Out("Sell Scroll: " & $bag & ", " & $slot)
			Merchant_SellItem($lItemPtr, 0, True)
		Next
	Next
EndFunc   ;==>SellScrolls

Func BuyScrolls()
	If Item_GetGoldStorage() < 600000 Then Return
	ScrollTrader()
	Do
		Item_WithdrawGold(100000)
		Other_PingSleep(200)
		Merchant_BuyItem(21233, 1, True) ; Lightbringer scroll
		Out("Buying scroll")
		Other_PingSleep(250)
		TraderBuy()
		Other_PingSleep(250)
	Until Item_GetGoldStorage() <= 200000 Or Trade_GeldGoldCharacter() = 100000
EndFunc   ;==>BuyScrolls

Func MaterialRarity($aMaterial)
	Switch Agent_ID($aMaterial)
		Case 930, 935 To 538, 945, 6532, 6533    ; ectos, diamond, onyx, ruby, saphire, obsidian shards, amber, jadeite
			Return 0
		Case 929, 933, 934     ; Dust, Feather, Fiber
			Return 0
		Case 955, 948, 921    ; Granite, Iron, Bone
			Return 0
		Case 925, 940, 946, 953, 954 ; cloth, tanned hide, wood scales, chitin
			Return 1
		Case 922, 923, 926 To 928, 931, 932, 939, 941 To 944, 949 To 952, 956 ; other rare materials
			Return 2
		Case 6532, 6533
			Return 0
	EndSwitch
EndFunc   ;==>MaterialRarity

Func CountTotalSlots($NumOfBags = 4)
	Local $lCount = 0
	For $lBag = 1 To $NumOfBags
		$lBagPtr = Item_GetBagPtr($lBag)
		If $lBagPtr = 0 Then ContinueLoop
		$lCount += Item_GetBagInfo($lBag, "Slots")
	Next
	Return $lCount

EndFunc   ;==>CountTotalSlots


;~ $aBag defines up to which bag it will look for salvage kits -> 16 = complete inventory and complete chest | 4 = inventory only
Func Item_Sell($bagIndex, $numOfSlots)
	$numOfSlots = DllStructGetData($bagIndex, 'slots')
	Sleep(Random(150, 250))
	For $i = 0 To $numOfSlots - 1
		$aItem = Item_GetItemBySlot($bagIndex, $i)
		If Item_CanSell($aItem) Then
			Merchant_SellItem($aItem)
			Sleep(Random(500, 550))
		EndIf
	Next
EndFunc   ;==>Sell

Func BestStorageSlotbyModelID($ItemModelID, $FirstBag, $LastBag) ; finds the best storage bag and slot to store an item of a given Model ID: existing stack > empty slot position > no slot (returns false)
	; $BAG_Backpack = 1, $BAG_BeltPouch, $BAG_Bag1, $BAG_Bag2, $BAG_EquipmentPack, $BAG_UnclaimedItems = 7, $BAG_Storage1, $BAG_Storage2, _
	; $BAG_Storage3, $BAG_Storage4, $BAG_Storage5, $BAG_Storage6, $BAG_Storage7, $BAG_Storage8, $BAG_StorageAnniversary
	Local $StorageIndex[2]

	For $bag = $LastBag To $FirstBag Step -1                            ; bags in reverse order so that found empty slot will be in an early bag
		$lBagPtr = Item_GetBagPtr($bag)
		If $lBagPtr = 0 Then ContinueLoop
		For $slot = 1 To Item_GetBagInfo($bag, "Slots")
			$lItemPtr = Item_GetItemBySlot($bag, $slot)
			If Item_GetItemInfoByPtr($lItemPtr, "ModelID") = $ItemModelID Then    ; tome stack of exact Model ID found in current bag
				$StorageIndex[0] = $bag
				$StorageIndex[1] = $slot
				Return $StorageIndex                                    ; --> stop cycling through bags, this is the best slot
			ElseIf Item_GetItemInfoByPtr($lItemPtr, "ModelID") = 0 Then             ; slot in current bag is empty, temp best slot
				$StorageIndex[0] = $bag
				$StorageIndex[1] = $slot
			EndIf
		Next
	Next
	Return $StorageIndex
EndFunc   ;==>BestStorageSlotbyModelID


Func FindEmptySlot($FirstBag, $LastBag) ;Parameter = bag index to start searching from. Returns integer with item slot. This function also searches the storage. If any of the returns = 0, then no empty slots were found
	; $BAG_Backpack = 1, $BAG_BeltPouch, $BAG_Bag1, $BAG_Bag2, $BAG_EquipmentPack, $BAG_UnclaimedItems = 7, $BAG_Storage1, $BAG_Storage2, _
	; $BAG_Storage3, $BAG_Storage4, $BAG_Storage5, $BAG_Storage6, $BAG_Storage7, $BAG_Storage8, $BAG_StorageAnniversary

	Local $StorageIndex[2]
	For $bag = $FirstBag To $LastBag
		$lBagPtr = Item_GetBagPtr($bag)
		If $lBagPtr = 0 Then ContinueLoop        ; bags in reverse order so that found empty slot will be in an early bag
		For $slot = 1 To Item_GetBagInfo($bag, "Slots")
			$lItemPtr = GetItemBySlot($bag, $slot)
			If $lItemPtr = 0 Then
				Out($bag & ", " & $slot & "  <-Empty! " & @CRLF)
				$StorageIndex[0] = $bag
				$StorageIndex[1] = $slot
				ExitLoop
			EndIf
		Next
	Next
	Return $StorageIndex
EndFunc   ;==>FindEmptySlot

Func Item_StoreGoldItems()
	StoreGoldItem(1, 20)
	StoreGoldItem(2, 10)
	StoreGoldItem(3, 15)
	StoreGoldItem(4, 15)
EndFunc   ;==>Item_StoreGoldItems

Func Item_StoreRareSkins()
	Out("Storing Rare Skins...")
	Item_StoreRare(1, 20)
	Item_StoreRare(2, 10)
	Item_StoreRare(3, 15)
	Item_StoreRare(4, 15)
EndFunc   ;==>Item_StoreRareSkins

Func Item_StoreGolds()
	Out("Storing Rare Skins...")
	StoreGold(1, 20)
	StoreGold(2, 10)
	StoreGold(3, 15)
	StoreGold(4, 15)
EndFunc   ;==>Item_StoreGolds

Func Item_StoreTomes()
	Out("Storing Tomes")
	Item_StoreTome(1, 20)
	Item_StoreTome(2, 10)
	Item_StoreTome(3, 15)
	Item_StoreTome(4, 15)
EndFunc   ;==>Item_StoreTomes

Func Item_StoreGoldItem($lBag, $numOfSlots)
	For $lSlot = 1 To CountTotalSlots()
		ConsoleWrite("Checking items: " & $lBag & ", " & $lSlot & @CRLF)
		$lItemPtr = Item_GetItemBySlot($lBag, $lSlot)
		$aModelID = Item_GetItemInfoByPtr($lItemPtr, "ModelID")
		If $lItemPtr <> 0 And Item_GetItemInfoByPtr($lItemPtr, "Rarity") = $RARITY_Gold Then
			$StorageIndex = BestStorageSlotbyModelID($aModelID, 8, 12)                                ; looking in bags 8 to 12 (change based on available storage)
			If $StorageIndex[0] > 0 Then Item_MoveItem($lItemPtr, $StorageIndex[0], $StorageIndex[1])
			Out("Moving gold item to bag " & $StorageIndex[0] & ", slot " & $StorageIndex[1])
			Sleep(Random(450, 550))
		EndIf
	Next
EndFunc   ;==>StoreGoldItem

Func Item_StoreRare($bag, $numOfSlots)
	$lBagPtr = Item_GetBagPtr($bag)
	For $slot = 1 To Item_GetBagInfo($bag, "Slots")
		;	  Out("Checking items: " & $bagIndex & ", " & $i & @CRLF)
		$lItemPtr = Item_GetItemBySlot($bag, $slot)
		$aModelID = Item_GetItemInfoByPtr($lItemPtr, "ModelID")
		If $lItemPtr <> 0 And Item_GetItemInfoByPtr($lItemPtr, "Rarity") = $RARITY_Gold And Item_GetItemReq($lItemPtr) < 12 And $aRareSkin[$aModelID] <> "" Then
			Out("Storing " & $aRareSkin[$aModelID])
			$StorageIndex = BestStorageSlotbyModelID($aModelID, 8, 12)                                ; looking in bags 8 to 12 (change based on available storage)
			If $StorageIndex[0] > 0 Then Item_MoveItem($lItemPtr, $StorageIndex[0], $StorageIndex[1])
		EndIf
	Next
EndFunc   ;==>Item_StoreRare

Func Item_StoreGold($bag, $numOfSlots)
	$lBagPtr = Item_GetBagPtr($bag)
	For $slot = 1 To Item_GetBagInfo($bag, "Slots")
		;	  Out("Checking items: " & $bagIndex & ", " & $i & @CRLF)
		$lItemPtr = Item_GetItemBySlot($bag, $slot)
		$aModelID = Item_GetItemInfoByPtr($lItemPtr, "ModelID")
		If $lItemPtr <> 0 And Item_GetItemInfoByPtr($lItemPtr, "Rarity") = $RARITY_Gold And Item_GetItemReq($lItemPtr) < 13 Then
			Out("Storing " & $aRareSkin[$aModelID])
			$StorageIndex = BestStorageSlotbyModelID($aModelID, 8, 12)                                ; looking in bags 8 to 12 (change based on available storage)
			If $StorageIndex[0] > 0 Then Item_MoveItem($lItemPtr, $StorageIndex[0], $StorageIndex[1])
		EndIf
	Next
EndFunc   ;==>StoreGold

Func Item_StoreTome($lBag, $numOfSlots)                                                    ;store the tomes of a given bag considering the total number of slots in that bag
	For $lSlot = 1 To CountTotalSlots()
		$lItemPtr = Item_GetItemBySlot($lBag, $lSlot)
		$lModelID = Item_GetItemInfoByPtr($lItemPtr, "ModelID")                       ; model ID of item in inventory bag $lBag and slot $lSlot
		If _ArrayBinarySearch($Tomes, $lModelID) = -1 Then ContinueLoop               ; continues loop if the Model ID of item does not correspond to a tome
		Out("The item in bag " & $lBag & ", Slot " & $lSlot & " is a tome")
		$StorageIndex = BestStorageSlotbyModelID($lModelID, 8, 12)                      ; looking in bags 8 to 12 (change based on available storage)
		If $StorageIndex[0] > 0 Then Item_MoveItem($lItemPtr, $StorageIndex[0], $StorageIndex[1])
		Out("Moving tome to bag " & $StorageIndex[0] & ", slot " & $StorageIndex[1])
		Other_PingSleep(200)
	Next
EndFunc   ;==>Item_StoreTome

Func Item_CanSell($aItem, $lItemPtr = 0)
	If $lItemPtr = 0 Then $lItemPtr = Item_GetItemPtr($aItem)
	Local $lType = Item_GetItemInfoByPtr($lItemPtr, "ItemType")
	Local $lModelID = Item_GetItemInfoByPtr($lItemPtr, "ModelID")
	; Local $lQuantity = Item_GetItemInfoByPtr($lItemPtr, "Quantity"), $lValue = GetItemValue($lItemPtr)

	If Item_GetItemInfoByPtr($lItemPtr, "Equipped") <> 0 Then Return False		; Is equipped
	If Item_GetItemInfoByPtr($lItemPtr, "Value") = 0 Then Return False	; Value is zero
	If Item_GetItemInfoByPtr($lItemPtr, "Rarity") = $RARITY_Green Then Return False
;~ 	If Item_GetItemInfoByPtr($lItemPtr, "Rarity") = $RARITY_Gold Then Return False

	If IsReq7Max($aItem) Then Return False
	If IsReq8Max($aItem)  Then Return False
	If IsPerfectShield($aItem) Then Return False
	If IsPerfectStaff($aItem) Then Return False
	If IsPerfectCaster($aItem) Then Return False
	If IsRareRune($aItem) Then Return False

	Switch $lType
		Case $TYPE_RUNE_AND_MOD, $TYPE_USABLE, $TYPE_KIT, $TYPE_SCROLL, $TYPE_DYE, $TYPE_KEY    ; we only pick up the dye that we intend to keep
			Return False
		Case $TYPE_MATERIAL_AND_ZCOINS
			$lModelID = Item_GetItemInfoByPtr($lItemPtr, "ModelID")
			Switch $lModelID
				Case 921 To 956, 6532, 6533
					Return False
				;Case 925 To 928, 940 To 943, 946, 953, 954
				;	Return True
			EndSwitch
		;Case $TYPE_SALVAGE
		;	Return True
		Case $TYPE_SHIELD
			Local $lReq = Item_GetItemReq($lItemPtr), $lDmg = Item_GetItemMaxDmg($lItemPtr)
			If $lReq = 9 And $lDmg = 16 And $aRareSkin[$lModelID] <> "" Then Return False    ; Req9 Shields
			If $lReq = 8 And $lDmg = 16 Then Return False    ; Req8 Shields
			If $lReq = 7 And $lDmg = 15 Then Return False    ; Req7 Shields
			If $lReq = 6 And $lDmg = 14 Then Return False    ; Req6 Shields
			If $lReq = 5 And $lDmg = 13 Then Return False    ; Req5 Shields
			If $lReq = 4 And $lDmg = 12 Then Return False    ; Req4 Shields
		Case $TYPE_OFFHAND
			Local $lReq = Item_GetItemReq($lItemPtr), $lDmg = Item_GetItemMaxDmg($lItemPtr)
			If $lReq = 9 And $lDmg = 12 And $aRareSkin[$lModelID] <> "" Then Return False
			If $lReq = 8 And $lDmg = 12 Then Return False     ; Req8 Offhand
		Case $TYPE_SWORD
			Local $lReq = Item_GetItemReq($lItemPtr), $lDmg = Item_GetItemMaxDmg($lItemPtr)
			If $lReq = 9 And $lDmg = 22 And $aRareSkin[$lModelID] <> "" Then Return False
			If $lReq = 8 And $lDmg = 22 Then Return False    ; Req8 Sword
	EndSwitch

	If $aRareSkin[$lModelID] <> "" Then
		Return False
	EndIf

	Return True
EndFunc   ;==>CanSell

Func Item_CanSellRune($aItem)
	Local $aModelID = DllStructGetData($aItem, 'ModelID')

	Switch $aModelID
		Case 5551 ; sup vigor
			Return False
		Case Else
			Return True
	EndSwitch

EndFunc   ;==>CanSellRune

Func UpgradeArmor($aArmor, $aUpgrade)
	Local $lArmorType = Item_GetItemInfoByPtr(Item_GetItemPtr($aArmor), "ItemType")
	Local $lUpgradeModelID = Item_GetItemInfoByPtr(Item_GetItemPtr($aUpgrade), "ModelID")
	Local $lArmorMod = Item_GetModStruct($aArmor)
	Local $lUpgradeType = Item_IsRuneOrInsignia($lUpgradeModelID)
	If $lUpgradeType = 0 Then Return
	If $lUpgradeType = 2 Then $lUpgradeType = 0
	Local $lOffset[4] = [0, 24, 44, 1580]
	Local $lSessionID = Memory_Read($mBasePointer, $lOffset)
	If Not IsArmor($lArmorType) Then Return False
	DllStructSetData($mUpgrade, 2, $lUpgradeModelID)
	DllStructSetData($mUpgrade, 3, Agent_ID($aUpgrade))
	DllStructSetData($mUpgrade, 4, $lUpgradeType)
	Enqueue($mUpgradePtr, 16)
	SendPacket(12, $HEADER_ITEM_USE, $lSessionID[1], $lUpgradeModelID)
	Other_PingSleep(125)
	SendPacket(4, $HEADER_ITEM_USE + 3)
EndFunc   ;==>UpgradeArmor

#EndRegion Inventory

#Region GUI Functions

Func GetPicksCount() ;Counts Lockpicks in your inventory
	Local $AmountPicks
	Local $aBag
	Local $aItem
	Local $i
	For $i = 1 To 4 ;change 1 To 16 if you want to count storage also or 1 to 4 for just personal inv.  Will display on GUI
		$aBag = Item_GetBagPtr($i)
		For $j = 1 To DllStructGetData($aBag, "Slots")
			$aItem = GetItemBySlot($aBag, $j)
			If DllStructGetData($aItem, "ModelID") == 22751 Then
				$AmountPicks += DllStructGetData($aItem, "Quantity")
			Else
				ContinueLoop
			EndIf
		Next
	Next
	Return $AmountPicks
EndFunc   ;==>GetPicksCount

Func ToggleRenderingEX()
	If $Rendering Then
		DisableRendering()
		WinSetState(GetWindowHandle(), "", @SW_HIDE)
		ClearMemory()
	Else
		EnableRendering()
		WinSetState(GetWindowHandle(), "", @SW_SHOW)
	EndIf
	$Rendering = Not $Rendering
EndFunc   ;==>ToggleRenderingEX


Func Purgehook()
	If Not $Rendering Then
		Out("PurgeHook")
		Enablerendering()
		Other_PingSleep(3000)
		Disablerendering()
	EndIf
EndFunc   ;==>Purgehook

Func TimeUpdater()
	GUI_SetTotalTime(TimerDiff($TimeTotal))
	If $BotRunning Then
		;		$TimeRun += 500
	EndIf
EndFunc   ;==>TimeUpdater

Func CurrentRunTime()
	GUI_SetRunTime(TimerDiff($nCurrentRunTime))
EndFunc   ;==>CurrentRunTime

Func AvgRunTime()
	Local $CurrentRunTime = Floor(TimerDiff($nCurrentRunTime))
	$CumulatedTime += $CurrentRunTime
	Out("Cumulated Time: " & $CumulatedTime)
	Out("Run Counter: " & $GUI_RunCounter)
	$AvgRunTime = $CumulatedTime / ($GUI_RunCounter - $GUI_FailCounter)

	Local $iHours, $iMins, $iSecs
	Local $TimeStamp = ""
	_TicksToTime($AvgRunTime, $iHours, $iMins, $iSecs)
	If $iHours < 10 Then $TimeStamp = "0"
	$TimeStamp &= $iHours & ":"
	If $iMins < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iMins & ":"
	If $iSecs < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iSecs
	Out($TimeStamp)
	Return $TimeStamp
EndFunc   ;==>AvgRunTime

Func AvgRunTime_alt()
	Local $Hours, $Mins, $Secs
	Local $iTime = _TicksToTime(Floor(TimerDiff($nCurrentRunTime)), $Hours, $Mins, $Secs)
	Local $Seconds = Floor($Secs + 60 * $Mins + 60 * 60 * $Hours)
	$TotalSeconds += $Seconds
	Local $AvgSeconds = Floor($TotalSeconds / $GUI_RunCounter)
	Out("Spent " & $TotalSeconds & "seconds over " & $GUI_RunCounter & "runs for an average of " & $AvgSeconds & "seconds per run")
	Local $Minutes = Floor($AvgSeconds / 60)
	Out("equivalent to " & Floor($Minutes) & "Minutes")

	Local $iHours = Floor($Minutes / 60)
	Local $iSecs = $AvgSeconds - $Minutes * 60
	Local $iMins = $Minutes - $Hours * 60

	Local $TimeStamp = ""
	If $iHours < 10 Then $TimeStamp = "0"
	$TimeStamp &= $iHours & ":"
	If $iMins < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iMins & ":"
	If $iSecs < 10 Then $TimeStamp &= "0"
	$TimeStamp &= $iSecs

	Return $TimeStamp
EndFunc   ;==>AvgRunTime_alt

Func BestRunTime()
	If TimerDiff($nCurrentRunTime) < $nBestRunTime Then $nBestRunTime = TimerDiff($nCurrentRunTime)
	Return $nBestRunTime
EndFunc   ;==>BestRunTime

Func onStart()
	$BotRunning = True
	$PickupTorch = False
	$droptorch = False
	$unlit = False
	Out("Start pressed")
	Global $iAsuraTitle = GetTitleProgress("Asura")
	Global $iDeldrimorTitle = GetTitleProgress("Deldrimor")
	GUI_SetLockpicks(GetPicksCount())
	GUI_SetWipes(0)
	GUI_SetGolds(0)
	GUI_SetTomes(0)
	GUI_SetChestsOpened(0)
	AdlibRegister("TimeUpdater", 500)
	AdlibRegister("UpdateStats", 1000)
	CacheSkillBar()
	CacheHeroHeals()
	CacheHeroPrecast()
	CacheHeroProts()
	CacheBiP()
EndFunc   ;==>onStart

Func BasicOnStart()
	$BotRunning = True
	$PickupTorch = False
	$droptorch = False
	$unlit = False
	Out("Start pressed")
	Global $iAsuraTitle = GetTitleProgress("Asura")
	Global $iDeldrimorTitle = GetTitleProgress("Deldrimor")
	GUI_SetLockpicks(GetPicksCount())
	GUI_SetWipes(0)
	GUI_SetGolds(0)
	GUI_SetTomes(0)
	GUI_SetChestsOpened(0)
	AdlibRegister("TimeUpdater", 500)
	AdlibRegister("UpdateStats", 1000)
EndFunc   ;==>onStart

; Stop only flips $BotRunning. Move/fight loops must poll this or the button looks dead.
Func Bot_HaltIfStopped()
	If Not IsDeclared("BotRunning") Then Return False
	If $BotRunning Then Return False
	Agent_CancelAction()
	Return True
EndFunc   ;==>Bot_HaltIfStopped

Func onStop()
	$BotRunning = False
	Agent_CancelAction()
	Out("Paused")
EndFunc   ;==>onStop

Func onResume()
	$BotRunning = True
	Out("Resume pressed")
EndFunc   ;==>onResume

Func UpdateStats()
	GUI_SetAsura(GetTitleProgress("Asura") - $iAsuraTitle)
	GUI_SetDeldrimor(GetTitleProgress("Deldrimor") - $iDeldrimorTitle)
EndFunc   ;==>UpdateStats

#EndRegion GUI Functions

#Region Checking Guild Hall
;~ Checks to see which Guild Hall you are in and the spawn point
Func CheckGuildHall()
	If Map_GetMapID() = $Guild_Hall_Isle_of_Wurms Then
		If CheckArea(8682, 2265) Then Move_ToCoord(8263, 2971)
		If CheckArea(6697, 3631) Then
			Move_ToCoord(7086, 2983)
			Move_ToCoord(8263, 2971)
		EndIf
		If CheckArea(6716, 2929) Then Move_ToCoord(8263, 2971)
		Return True
	EndIf
EndFunc   ;==>CheckGuildHall

Func Chest()
	Dim $Waypoints_by_XunlaiChest[16][3] = [ _
			[$Guild_Hall_Burning_Isle, -5285, -2545], _
			[$Guild_Hall_Druids_Isle, -1792, 5444], _
			[$Guild_Hall_Frozen_Isle, -115, 3775], _
			[$Guild_Hall_Hunters_Isle, 4855, 7527], _
			[$Guild_Hall_Isle_of_the_Dead, -4562, -1525], _
			[$Guild_Hall_Nomads_Isle, 4630, 4580], _
			[$Guild_Hall_Warriors_Isle, 3322, 7292], _
			[$Guild_Hall_Warriors_Isle, 4229, 6798], _
			[$Guild_Hall_Imperial_Isle, 2184, 13125], _
			[$Guild_Hall_Isle_of_Jade, 8614, 2660], _
			[$Guild_Hall_Isle_of_Meditation, -726, 7630], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -1573, 7303], _
			[$Guild_Hall_Corrupted_Isle, -4868, 5998], _
			[$Guild_Hall_Isle_of_Solitude, 4478, 3055], _
			[$Guild_Hall_Isle_of_Wurms, 8586, 3603], _
			[$Guild_Hall_Uncharted_Isle, 4522, -4451]]

	Out("Going to Xunlai Chest")
	For $i = 0 To (UBound($Waypoints_by_XunlaiChest) - 1)
		If $Waypoints_by_XunlaiChest[$i][0] <> Map_GetMapID() Then ContinueLoop
		RandomMoveTo($Waypoints_by_XunlaiChest[$i][1], $Waypoints_by_XunlaiChest[$i][2], Random(60, 80, 2))
	Next
	Other_PingSleep(500)
	; No PlayerNumber — nearest Allegiance-6 NPC (Xunlai); never self.
	Agent_GoToNPCnearXY(X(-2), Y(-2))
EndFunc   ;==>Chest

Func Merchant()
	Dim $Merchant_Waypoints[29][3] = [ _
			[$Guild_Hall_Burning_Isle, -4439, -2088], _
			[$Guild_Hall_Burning_Isle, -4772, -362], _
			[$Guild_Hall_Burning_Isle, -3637, 1088], _
			[$Guild_Hall_Burning_Isle, -2506, 988], _
			[$Guild_Hall_Druids_Isle, -2037, 2964], _
			[$Guild_Hall_Frozen_Isle, 99, 2660], _
			[$Guild_Hall_Frozen_Isle, 71, 834], _
			[$Guild_Hall_Frozen_Isle, -299, 79], _
			[$Guild_Hall_Hunters_Isle, 5156, 7789], _
			[$Guild_Hall_Hunters_Isle, 4416, 5656], _
			[$Guild_Hall_Isle_of_the_Dead, -4066, -1203], _
			[$Guild_Hall_Nomads_Isle, 5129, 4748], _
			[$Guild_Hall_Warriors_Isle, 3322, 7292], _
			[$Guild_Hall_Warriors_Isle, 5608.00, 9137.00], _
			[$Guild_Hall_Wizards_Isle, 4288, 8263], _
			[$Guild_Hall_Wizards_Isle, 3583, 9040], _
			[$Guild_Hall_Imperial_Isle, 1415, 12448], _
			[$Guild_Hall_Imperial_Isle, 1891, 11729], _
			[$Guild_Hall_Isle_of_Jade, 8825, 3384], _
			[$Guild_Hall_Isle_of_Jade, 10142, 3116], _
			[$Guild_Hall_Isle_of_Meditation, -331, 8084], _
			[$Guild_Hall_Isle_of_Meditation, -1745, 8681], _
			[$Guild_Hall_Isle_of_Meditation, -2197, 8076], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -3095, 8535], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -3988, 7588], _
			[$Guild_Hall_Corrupted_Isle, -4670, 5630], _
			[$Guild_Hall_Isle_of_Solitude, 2970, 1532], _
			[$Guild_Hall_Isle_of_Wurms, 8284, 3578], _
			[$Guild_Hall_Uncharted_Isle, 1503, -2830]]
	Out("Going to Merchant")

	For $i = 0 To (UBound($Merchant_Waypoints) - 1)
		If $Merchant_Waypoints[$i][0] <> Map_GetMapID() Then ContinueLoop
		RandomMoveTo($Merchant_Waypoints[$i][1], $Merchant_Waypoints[$i][2], Random(60, 80, 2))
	Next
	Agent_GoToNPCnearXY(X(-2), Y(-2), GetMerchant())

EndFunc   ;==>Merchant

Func RuneTrader()            ; waypoints need to be updated unless it states "updated"
	Dim $Runetrader_Waypoints[34][3] = [ _
			[$Guild_Hall_Burning_Isle, -3793, 1069], _
			[$Guild_Hall_Burning_Isle, -2798, -74], _
			[$Guild_Hall_Druids_Isle, -989, 4493], _
			[$Guild_Hall_Frozen_Isle, 71, 834], _
			[$Guild_Hall_Frozen_Isle, 99, 2660], _
			[$Guild_Hall_Frozen_Isle, -385, 3254], _
			[$Guild_Hall_Frozen_Isle, -983, 3195], _
			[$Guild_Hall_Hunters_Isle, 3267, 6557], _
			[$Guild_Hall_Isle_of_the_Dead, -3654, -2400], _                   ; updated
			[$Guild_Hall_Nomads_Isle, 3142, 4289], _                        ; updated
			[$Guild_Hall_Nomads_Isle, -514, 3581], _                        ; updated
			[$Guild_Hall_Warriors_Isle, 3322, 7292], _
			[$Guild_Hall_Warriors_Isle, 4588, 7116], _
			[$Guild_Hall_Warriors_Isle, 3971.00, 3443.00], _
			[$Guild_Hall_Wizards_Isle, 3610, 9619], _
			[$Guild_Hall_Imperial_Isle, 816, 11798], _
			[$Guild_Hall_Isle_of_Jade, 8919, 3459], _
			[$Guild_Hall_Isle_of_Jade, 6789, 2781], _
			[$Guild_Hall_Isle_of_Jade, 6566, 2248], _
			[$Guild_Hall_Isle_of_Meditation, -166, 7939], _                  ; updated
			[$Guild_Hall_Isle_of_Meditation, -696, 8825], _                  ; updated
			[$Guild_Hall_Isle_of_Meditation, -879, 9430], _                  ; updated
			[$Guild_Hall_Isle_of_Meditation, -32, 10382], _                  ; updated
			[$Guild_Hall_Isle_of_Weeping_Stone, -3988, 7588], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -3095, 8535], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -2431, 7946], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -1618, 8797], _
			[$Guild_Hall_Corrupted_Isle, -4424, 5645], _
			[$Guild_Hall_Corrupted_Isle, -4443, 4679], _
			[$Guild_Hall_Isle_of_Solitude, 3172, 3728], _                    ; updated
			[$Guild_Hall_Isle_of_Solitude, 2343, 5512], _                    ; updated
			[$Guild_Hall_Isle_of_Wurms, 8353, 2995], _                       ; updated
			[$Guild_Hall_Isle_of_Wurms, 6825, 4537], _                       ; updated
			[$Guild_Hall_Uncharted_Isle, 2530, -2403]]
	Out("Going to Rune Trader")
	For $i = 0 To (UBound($Runetrader_Waypoints) - 1)
		If $Runetrader_Waypoints[$i][0] <> Map_GetMapID() Then ContinueLoop
		RandomMoveTo($Runetrader_Waypoints[$i][1], $Runetrader_Waypoints[$i][2], Random(60, 80, 2))
	Next
	Agent_GoToNPCnearXY(X(-2), Y(-2), GetRuneTrader(Map_GetMapID()))

EndFunc   ;==>RuneTrader

Func ScrollTrader()        ; waypoints need to be updated unless it states "updated"
	Dim $ScrollTrader_Waypoints[33][3] = [ _
			[$Guild_Hall_Burning_Isle, -3793, 1069], _
			[$Guild_Hall_Burning_Isle, -2798, -74], _
			[$Guild_Hall_Druids_Isle, -989, 4493], _
			[$Guild_Hall_Frozen_Isle, 71, 834], _
			[$Guild_Hall_Frozen_Isle, 99, 2660], _
			[$Guild_Hall_Frozen_Isle, -385, 3254], _
			[$Guild_Hall_Frozen_Isle, -983, 3195], _
			[$Guild_Hall_Hunters_Isle, 3267, 6557], _
			[$Guild_Hall_Isle_of_the_Dead, -4033, -3860], _         ; updated
			[$Guild_Hall_Nomads_Isle, 3142, 4289], _
			[$Guild_Hall_Nomads_Isle, -514, 3581], _
			[$Guild_Hall_Warriors_Isle, 3322, 7292], _
			[$Guild_Hall_Warriors_Isle, 3971.00, 3443.00], _
			[$Guild_Hall_Wizards_Isle, 3610, 9619], _
			[$Guild_Hall_Imperial_Isle, -508, 11560], _
			[$Guild_Hall_Isle_of_Jade, 8919, 3459], _
			[$Guild_Hall_Isle_of_Jade, 6789, 2781], _
			[$Guild_Hall_Isle_of_Jade, 6566, 2248], _
			[$Guild_Hall_Isle_of_Meditation, -166, 7939], _
			[$Guild_Hall_Isle_of_Meditation, -696, 8825], _
			[$Guild_Hall_Isle_of_Meditation, -879, 9430], _
			[$Guild_Hall_Isle_of_Meditation, -32, 10382], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -3988, 7588], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -3095, 8535], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -2431, 7946], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -1618, 8797], _
			[$Guild_Hall_Corrupted_Isle, -4424, 5645], _
			[$Guild_Hall_Corrupted_Isle, -4443, 4679], _
			[$Guild_Hall_Isle_of_Solitude, 3172, 3728], _
			[$Guild_Hall_Isle_of_Solitude, 3240, 5433], _
			[$Guild_Hall_Isle_of_Wurms, 8353, 2995], _
			[$Guild_Hall_Isle_of_Wurms, 6825, 4537], _
			[$Guild_Hall_Uncharted_Isle, 2530, -2403]]
	Out("Going to Scroll Trader")
	For $i = 0 To (UBound($ScrollTrader_Waypoints) - 1)
		If $ScrollTrader_Waypoints[$i][0] <> Map_GetMapID() Then ContinueLoop
		RandomMoveTo($ScrollTrader_Waypoints[$i][1], $ScrollTrader_Waypoints[$i][2], Random(60, 80, 2))
	Next
	Agent_GoToNPCnearXY(X(-2), Y(-2), GetScrollTrader(Map_GetMapID()))

EndFunc   ;==>ScrollTrader

Func RareMaterialTrader()
	Dim $RareMatTrader_Waypoints[36][3] = [ _
			[$Guild_Hall_Burning_Isle, -3793, 1069], _
			[$Guild_Hall_Burning_Isle, -2798, -74], _
			[$Guild_Hall_Druids_Isle, -989, 4493], _
			[$Guild_Hall_Frozen_Isle, 71, 834], _
			[$Guild_Hall_Frozen_Isle, 99, 2660], _
			[$Guild_Hall_Frozen_Isle, -385, 3254], _
			[$Guild_Hall_Frozen_Isle, -983, 3195], _
			[$Guild_Hall_Hunters_Isle, 3267, 6557], _
			[$Guild_Hall_Isle_of_the_Dead, -3415, -1658], _
			[$Guild_Hall_Nomads_Isle, 1930, 4129], _
			[$Guild_Hall_Nomads_Isle, 462, 4094], _
			[$Guild_Hall_Warriors_Isle, 3322, 7292], _
			[$Guild_Hall_Warriors_Isle, 3417.03, 5545.89], _
			[$Guild_Hall_Warriors_Isle, 4003.00, 6014.00], _
			[$Guild_Hall_Wizards_Isle, 3610, 9619], _
			[$Guild_Hall_Imperial_Isle, 217, 11807], _
			[$Guild_Hall_Isle_of_Jade, 8919, 3459], _
			[$Guild_Hall_Isle_of_Jade, 6789, 2781], _
			[$Guild_Hall_Isle_of_Jade, 6566, 2248], _
			[$Guild_Hall_Isle_of_Meditation, -2197, 8076], _
			[$Guild_Hall_Isle_of_Meditation, -1745, 8681], _
			[$Guild_Hall_Isle_of_Meditation, -331, 8084], _
			[$Guild_Hall_Isle_of_Meditation, 422, 8769], _
			[$Guild_Hall_Isle_of_Meditation, 549, 9531], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -3988, 7588], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -3095, 8535], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -2431, 7946], _
			[$Guild_Hall_Isle_of_Weeping_Stone, -1618, 8797], _
			[$Guild_Hall_Corrupted_Isle, -4424, 5645], _
			[$Guild_Hall_Corrupted_Isle, -4443, 4679], _
			[$Guild_Hall_Isle_of_Solitude, 3172, 3728], _
			[$Guild_Hall_Isle_of_Solitude, 3221, 4789], _
			[$Guild_Hall_Isle_of_Solitude, 3745, 4542], _
			[$Guild_Hall_Isle_of_Wurms, 8353, 2995], _
			[$Guild_Hall_Isle_of_Wurms, 6708, 3093], _
			[$Guild_Hall_Uncharted_Isle, 2530, -2403]]
	Out("Going to Rare Material Trader")
	For $i = 0 To (UBound($RareMatTrader_Waypoints) - 1)
		If $RareMatTrader_Waypoints[$i][0] <> Map_GetMapID() Then ContinueLoop
		RandomMoveTo($RareMatTrader_Waypoints[$i][1], $RareMatTrader_Waypoints[$i][2], Random(60, 80, 2))
	Next
	Agent_GoToNPCnearXY(X(-2), Y(-2), GetRareMaterialTrader(Map_GetMapID()))
;~This section does the buying
	;TraderRequest($MatID)
	;Sleep(500 + 3 * GetPing())
	;While Trade_GeldGoldCharacter() > 20 * 1000
	;	TraderRequest($MatID)
	;	Sleep(500 + 3 * GetPing())
	;	TraderBuy()
	;WEnd
EndFunc   ;==>RareMaterialTrader

;~ Description: Return merchant depending on MapID.
Func GetMerchant($aMapID = Map_GetMapID())
	Switch $aMapID
		Case 4, 5, 6, 52, 176, 177, 178, 179 ; proph gh
			Return 209
		Case 275, 276, 359, 360, 529, 530, 537, 538 ; factions and nf gh
			Return 196
		Case 10, 11, 12, 139, 141, 142, 49, 857
			Return 2036
		Case 109, 120, 154
			Return 1993
		Case 116, 117, 118, 152, 153, 38
			Return 1994
		Case 122, 35
			Return 2136
		Case 123, 124
			Return 2137
		Case 129, 348, 390
			Return 3402
		Case 130, 218, 230, 287, 349, 388
			Return 3403
		Case 131, 21, 25, 36
			Return 2086
		Case 132, 135, 28, 29, 30, 32, 39, 40
			Return 2101
		Case 133, 155, 156, 157, 158, 159, 206, 22, 23, 24
			Return 2107
		Case 134, 81
			Return 2011
		Case 136, 137, 14, 15, 16, 19, 57, 73
			Return 1989
		Case 138
			Return 1975
		Case 193, 234, 278, 288, 391
			Return 3618
		Case 194, 213, 214, 225, 226, 242, 250, 283, 284, 291, 292
			Return 3275
		Case 216, 217, 249, 251
			Return 3271
		Case 219, 224, 273, 277, 279, 289, 297, 350, 389
			Return 3617
		Case 220, 274, 51
			Return 3273
		Case 222, 272, 286, 77
			Return 3401
		Case 248
			Return 1207
		Case 303
			Return 3272
		Case 376, 378, 425, 426, 477, 478
			Return 5385
		Case 381, 387, 421, 424, 427, 554
			Return 5386
		Case 393, 396, 403, 414, 476
			Return 5666
		Case 398, 407, 428, 433, 434, 435
			Return 5665
		Case 431
			Return 4721
		Case 438, 545
			Return 5621
		Case 440, 442, 469, 473, 480, 494, 496
			Return 5613
		Case 450, 559
			Return 4989
		Case 474, 495
			Return 5614
		Case 479, 487, 489, 491, 492, 502, 818
			Return 4720
		Case 555
			Return 4988
		Case 624
			Return 6758
		Case 638
			Return 6060
		Case 639, 640
			Return 6757
		Case 641
			Return 6063
		Case 642
			Return 6047
		Case 643, 645, 650
			Return 6383
		Case 644
			Return 6384
		Case 648
			Return 6589
		Case 652
			Return 6231
		Case 675
			Return 6190
		Case 808
			Return 7448
		Case 814
			Return 104
	EndSwitch
EndFunc   ;==>GetMerchant

;~ Description: Return material trader depending on MapID.
Func GetMaterialTrader($aMapID = Map_GetMapID())
	Switch $aMapID
		Case 4, 5, 6, 52, 176, 177, 178, 179 ; proph gh
			Return 204
		Case 275, 276, 359, 360, 529, 530, 537, 538 ; factions and nf gh
			Return 191
		Case 109, 49, 81
			Return 2017
		Case 193
			Return 3624
		Case 194, 242, 857
			Return 3285
		Case 250
			Return 3286
		Case 376
			Return 5391
		Case 398
			Return 5671
		Case 414
			Return 5674
		Case 424
			Return 5392
		Case 433
			Return 5672
		Case 438
			Return 5624
		Case 491
			Return 4726
		Case 492
			Return 4727
		Case 638
			Return 6763
		Case 640
			Return 6764
		Case 641
			Return 6065
		Case 642
			Return 6050
		Case 643
			Return 6389
		Case 644
			Return 6390
		Case 652
			Return 6233
		Case 77
			Return 3415
		Case 808
			Return 7452
		Case 818
			Return 4729
	EndSwitch
EndFunc   ;==>GetMaterialTrader

;~ Description: Return rare material trader depending on MapID.
Func GetRareMaterialTrader($aMapID)
	Switch $aMapID
		Case 4, 5, 6, 52, 176, 177, 178, 179 ; proph gh
			Return 205
		Case 275, 276, 359, 360, 529, 530, 537, 538 ; factions and nf gh
			Return 192
		Case 109
			Return 2003
		Case 193
			Return 3627
		Case 194, 250, 857
			Return 3288
		Case 242
			Return 3287
		Case 376
			Return 5394
		Case 398, 433
			Return 5673
		Case 414
			Return 5674
		Case 424
			Return 5393
		Case 438
			Return 5619
		Case 49
			Return 2044
		Case 491, 818
			Return 4729
		Case 492
			Return 4728
		Case 638
			Return 6766
		Case 640
			Return 6765
		Case 641
			Return 6066
		Case 642
			Return 6051
		Case 643
			Return 6392
		Case 644
			Return 6391
		Case 652
			Return 6234
		Case 77
			Return 3416
		Case 81
			Return 2089
	EndSwitch
EndFunc   ;==>GetRareMaterialTrader

;~ Description: Return rune trader depending on MapID.
Func GetRuneTrader($aMapID)
	Switch $aMapID
		Case 4, 5, 6, 52, 176, 177, 178, 179 ; proph gh
			Return 203
		Case 275, 276, 359, 360, 529, 530, 537, 538 ; factions and nf gh
			Return 190
		Case 109, 814
			Return 2005
		Case 193
			Return 3630
		Case 194, 242, 250
			Return 3291
		Case 248, 857
			Return 1981
		Case 396
			Return 5678
		Case 414
			Return 5677
		Case 438
			Return 5626
		Case 477
			Return 5396
		Case 487
			Return 4732
		Case 49
			Return 2045
		Case 502
			Return 4733
		Case 624
			Return 6770
		Case 640
			Return 6769
		Case 642
			Return 6052
		Case 643, 645
			Return 6395
		Case 644
			Return 6396
		Case 77
			Return 3421
		Case 808
			Return 7456
		Case 81
			Return 2091
		Case 818
			Return 4711
	EndSwitch
EndFunc   ;==>GetRuneTrader

;~ Description: Return dye trader depending on MapID.
Func GetDyeTrader($aMapID)
	Switch $aMapID
		Case 4, 5, 6, 52, 176, 177, 178, 179 ; proph gh
			Return 206
		Case 275, 276, 359, 360, 529, 530, 537, 538 ; factions and nf gh
			Return 193
		Case 109, 49, 81, 857
			Return 2016
		Case 193
			Return 3623
		Case 194, 242
			Return 3284
		Case 250
			Return 3283
		Case 286
			Return 3408
		Case 381, 477
			Return 5389
		Case 403
			Return 5669
		Case 414
			Return 5670
		Case 640
			Return 6762
		Case 642
			Return 6049
		Case 644
			Return 6388
		Case 77
			Return 3407
		Case 812
			Return 2113
		Case 818
			Return 4725
	EndSwitch
EndFunc   ;==>GetDyeTrader

; ~ Description: Return scroll trader depending on MapID.
Func GetScrollTrader($aMapID)
	Switch $aMapID
		Case 4, 5, 6, 52, 176, 177, 178, 179 ; proph gh
			Return 207
		Case 275, 276, 359, 360, 529, 530, 537, 538 ; factions and nf gh
			Return 194
		Case 109
			Return 2004
		Case 193
			Return 3629
		Case 194
			Return 3289
		Case 287
			Return 3419
		Case 396, 414
			Return 5675
		Case 426, 857
			Return 5398
		Case 442, 480
			Return 5627
		Case 49
			Return 2046
		Case 624
			Return 6767
		Case 638
			Return 6062
		Case 639, 640
			Return 6768
		Case 643, 644
			Return 6393
		Case 645
			Return 6394
		Case 77
			Return 3418
		Case 808
			Return 7454
	EndSwitch
EndFunc   ;==>GetScrollTrader
#EndRegion Checking Guild Hall

; Modified CampCoords Function from GWBible.au3
Func VigilantSleep($x, $y, $VigilantTime = 0)
; REVIEW: Calls Fight() from logiccast. Useful for interrupt testing.
	Local $MyOldMap = Map_GetMapID(), $lMapLoadingOld = Map_GetInstanceInfo("Type")
	AggroMoveToEX($x, $y, 250)
	FlagHeptagon(400)
	Precast($compass_range, True)

	If $VigilantTime <> 0 Then $TimerVigilantSleep = TimerInit()
	Do
		If Map_GetMapID() <> $MyOldMap Then ExitLoop
		If Map_GetInstanceInfo("Type") <> $lMapLoadingOld Then ExitLoop
		If Agent_IsEnemyNear(1250) Then Fight($x, $y, 1250, False, 1400)
		If Agent_GetDistanceToXY($x, $y) > 1400 Then Agent_MoveToClosestXYtoWaypoint($x, $y, 1000)
		If Cinematic_WaitCinematic() Then Return
	Until TimerDiff($TimerVigilantSleep) > $VigilantTime Or Wipe() Or Map_GetMapID() <> $MyOldMap Or Map_GetInstanceInfo("Type") <> $lMapLoadingOld Or Cinematic_WaitCinematic()

	For $i = 1 to GetPartySize() - 1
		CancelHero($i)
		Other_PingSleep(200)
	Next
EndFunc   ;==>VigilantSleep

; Move to location and wait for enemies keeping wards and spirits up
Func BraceForEnemies($x, $y, $delay)
	Local $lDistance, $lBlocked
	Local $lMapLoading = Map_GetInstanceInfo("Type"), $lMapLoadingOld
	$Timer = TimerInit()
	Do
		$lBlocked += 1
		$lDistance += 50
		If $lDistance > 300 Then Return False
		$lMapLoadingOld = $lMapLoading
		$lMapLoading = Map_GetInstanceInfo("Type")
		If $lMapLoading <> $lMapLoadingOld Then ExitLoop
		Move_ToCoord($x, $y, $lDistance)
	Until ComputeDistance(X(-2), Y(-2), $x, $y) < 250 Or $lBlocked > 14 Or Agent_GetAgentInfo(-2, "Dead")
	Sleep($delay)
	Precast($compass_range, True)

	Do
		Sleep(1000)
	Until Agent_GetNumberOfEnemies() <> 0 Or TimerDiff($Timer) > 60000
	CancelAll()
	CancelHero(1)
	CancelHero(2)
	CancelHero(3)
EndFunc   ;==>BraceForEnemies

; Follow an npc by ID
Func CampNPC($npc = Agent_GetNearestNPCToXY(X(), Y()), $Time = 0, $Interval = 500)    ; accepts both struct and ID as NPC
	Local $Timer = 0, $tDiff = 0
	Local $MyOldMap = Map_GetMapID(), $lMapLoadingOld = Map_GetInstanceInfo("Type")
	Local $lDistance, $lMovingA, $lMovingB
	$Interval /= 2
	If $Time <> 0 Then
		$Timer = TimerInit()
	EndIf
	While 1
		If Map_GetMapID() <> $MyOldMap Then ExitLoop
		If Map_GetInstanceInfo("Type") <> $lMapLoadingOld Then ExitLoop
		Cinematic_WaitCinematic()
		If Agent_GetAgentInfo($npc, "Dead") < 200 Then
			AggroMoveToEX(X($npc), Y($npc), 1350)
		Else
			AggroMoveToEX(X($npc), Y($npc), 1350)
		EndIf
		Sleep($Interval)
		$lMovingA = Agent_GetAgentInfo($npc, "Moving")
		Sleep(1000)
		$lMovingB = Agent_GetAgentInfo($npc, "Moving")
		If Not $lMovingA And Not $lMovingB Then
			$theta = Random(0, 360)
			AggroMoveToEX(50 * Cos($theta * 0.01745) + X($npc), 50 * Sin($theta * 0.01745) + Y($npc), 0)
		EndIf
		$tDiff = TimerDiff($Timer)
		If $Time > 0 Then
			If $tDiff > $Time Then ExitLoop
		EndIf
	WEnd
EndFunc   ;==>CampNPC

; Returns true if not too far away
Func AgentIsNearXY($x, $y, $aRange = 1000, $aAgent = -2)
	If Agent_GetDistanceToXY($x, $y, $aAgent) < $aRange Then Return True
	Return False
EndFunc   ;==>AgentIsNearXY

;~ Description: Logic GetWindowHandle / Win_GetWindowHandle shim — Core stores the HWND as $g_h_GWWindow.
Func GetWindowHandle()
	Return Scanner_GetWindowHandle()
EndFunc   ;==>GetWindowHandle

Func Win_GetWindowHandle()
	Return Scanner_GetWindowHandle()
EndFunc   ;==>Win_GetWindowHandle

;~ Description: Logic Disconnected() port — monitors connection and attempts Enter-based reconnect.
Func Disconnected()
	Connection_CheckAndReconnect()
EndFunc   ;==>Disconnected

;~ Description: Monitors connection state and attempts automatic reconnection loops if disconnected.
Func Connection_CheckAndReconnect()
	Local $l_b_Check = False
	Local $l_h_Timer = TimerInit()
	Local $l_h_GW = GetWindowHandle()

	Do
		Sleep(20)
		$l_b_Check = (Not Map_GetInstanceInfo("IsLoading")) And Agent_GetAgentPtr(-2) <> 0
	Until $l_b_Check Or TimerDiff($l_h_Timer) > 5000

	If Not $l_b_Check Then
		Out('Disconnected!')
		Out('Attempting to reconnect.')
		If $l_h_GW <> 0 Then ControlSend($l_h_GW, '', '', '{Enter}')

		$l_h_Timer = TimerInit()
		Do
			Sleep(20)
			$l_b_Check = (Not Map_GetInstanceInfo("IsLoading")) And Agent_GetAgentPtr(-2) <> 0
		Until $l_b_Check Or TimerDiff($l_h_Timer) > 60000

		If Not $l_b_Check Then
			Out('Failed to Reconnect 1!')
			Out('Retrying.')
			If $l_h_GW <> 0 Then ControlSend($l_h_GW, '', '', '{Enter}')

			$l_h_Timer = TimerInit()
			Do
				Sleep(20)
				$l_b_Check = (Not Map_GetInstanceInfo("IsLoading")) And Agent_GetAgentPtr(-2) <> 0
			Until $l_b_Check Or TimerDiff($l_h_Timer) > 60000

			If Not $l_b_Check Then
				Out('Failed to Reconnect 2!')
				Out('Retrying.')
				If $l_h_GW <> 0 Then ControlSend($l_h_GW, '', '', '{Enter}')

				$l_h_Timer = TimerInit()
				Do
					Sleep(20)
					$l_b_Check = (Not Map_GetInstanceInfo("IsLoading")) And Agent_GetAgentPtr(-2) <> 0
				Until $l_b_Check Or TimerDiff($l_h_Timer) > 60000

				If Not $l_b_Check Then
					Out('Could not reconnect!')
					Out('Exiting.')
					Graphics_EnableRendering()
					Exit 1
				EndIf
			EndIf
		EndIf
		Out('Reconnected!')
		Sleep(5000)
	EndIf
EndFunc   ;==>Connection_CheckAndReconnect






