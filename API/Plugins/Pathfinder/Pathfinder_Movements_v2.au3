#include-once

#include "Pathfinder_Core.au3"

; =============================================================================
; Return codes
; =============================================================================
Global Const $PATHFINDER_OK = 1
Global Const $PATHFINDER_ERROR_DLL = 0
Global Const $PATHFINDER_DEFEATED = -1
Global Const $PATHFINDER_MAP_CHANGED = -2
Global Const $PATHFINDER_CANCELLED = -3

; =============================================================================
; Movement state
; =============================================================================
Global $g_aPathfinder_CurrentPath[0][4]  ; x, y, layer, tp_type
Global $g_iPathfinder_CurrentPathIndex = 0
Global $g_hPathfinder_LastPathUpdateTime = 0
Global $g_bPathfinder_CancelMovement = False
Global $g_aPathfinder_SwitchTP_PreScan[0]    ; Pre-scanned gadget order (filled during approach)
Global $g_bPathfinder_SwitchTP_Scanning = False
Global $g_bPathfinder_SwitchTP_Active = False ; True during puzzle solving (disables combat)

; =============================================================================
; Configuration
; =============================================================================
Global $g_iPathfinder_WaypointReachedDistance = 250   ; Distance to consider waypoint reached
Global $g_iPathfinder_ArrivalDistance = 125            ; Distance to consider destination reached
Global $g_iPathfinder_SimplifyRange = 1250             ; Path simplification range
Global $g_iPathfinder_ObstacleUpdateInterval = 1000    ; Interval for dynamic obstacle updates (ms)
Global $g_iPathfinder_StuckCheckInterval = 500         ; Interval to check if stuck (ms)
Global $g_iPathfinder_StuckDistance = 100              ; If moved less than this, consider stuck
Global $g_iPathfinder_DeviationThreshold = 400         ; Distance from path segment to trigger recalc
Global $g_iPathfinder_UnstuckDirectionIndex = 0        ; Fallback direction index for unstuck (cycles through 8)

Global $g_iPathfinder_RecalcCooldown = 500             ; Minimum interval between path recalculations (ms)
Global $g_iPathfinder_DirectMoveDistance = 1500         ; Skip pathfinding if destination is closer than this
Global $g_sPathfinder_SwitchTeleportFunc = ""           ; Callback for switch-activated teleporters: MyFunc($x, $y) - overrides built-in solver
Global $g_iPathfinder_SwitchTP_ArrivalDist = 100        ; Must be within this distance of switch TP position
Global $g_iPathfinder_SwitchTP_GadgetRange = 1400       ; Range to search for puzzle gadgets around TP
Global $g_iPathfinder_SwitchTP_SequenceTimeout = 30000  ; Timeout for detecting gadget activation sequence (ms)
Global $g_sPathfinder_SwitchTP_GadgetFilter = ""        ; Optional filter function for puzzle gadgets: MyFilter($agentPtr)

; =============================================================================
; Move to a destination using pathfinding with obstacle avoidance
; Returns: $PATHFINDER_OK (1), $PATHFINDER_ERROR_DLL (0), $PATHFINDER_DEFEATED (-1),
;          $PATHFINDER_MAP_CHANGED (-2), $PATHFINDER_CANCELLED (-3)
; =============================================================================
Func Pathfinder_MoveTo($aDestX, $aDestY, $aDestLayer = -1, $aObstacles = 0, $aAggroRange = 1320, $aFightRangeOut = 3500, $aFinisherMode = 0, $aCallFunc = "")
	$g_bPathfinder_CancelMovement = False

	; Wait for map to fully load
	Local $lMyX = Agent_GetAgentInfo(-2, "X")
	Local $lMyY = Agent_GetAgentInfo(-2, "Y")
	Local $lMyOldMap = Map_GetMapID()
	Local $lMapLoadingOld = Map_GetInstanceInfo("Type")
	Local $lLayer = Agent_GetAgentInfo(-2, "Plane")

	If $lMyX = 0 Or $lMyY = 0 Or $lMyOldMap = 0 Or $lMapLoadingOld = $GC_I_MAP_TYPE_LOADING Then
		Do
			Sleep(16)
		Until Map_GetMapID() <> 0 And (Agent_GetAgentInfo(-2, "X") <> 0 Or Agent_GetAgentInfo(-2, "Y") <> 0)

		Other_WaitPingStabilized(1500)

		$lMyOldMap = Map_GetMapID()
		$lMapLoadingOld = Map_GetInstanceInfo("Type")
		$lMyX = Agent_GetAgentInfo(-2, "X")
		$lMyY = Agent_GetAgentInfo(-2, "Y")
		$lLayer = Agent_GetAgentInfo(-2, "Plane")
	EndIf

	; Initialize DLL if needed (keep it loaded across calls)
	If Not _Pathfinder_EnsureDLL() Then
		_Pathfinder_SafeMove($aDestX, $aDestY, $lLayer, $lMyOldMap)
		Return $PATHFINDER_ERROR_DLL
	EndIf

	If Party_GetPartyContextInfo("IsDefeated") Then Return $PATHFINDER_DEFEATED

	; Resolve obstacles
	Local $lIsDynamicObstacles = IsString($aObstacles) And $aObstacles <> "" And $aObstacles <> "0"
	Local $lCurrentObstacles = 0
	If $lIsDynamicObstacles Then
		$lCurrentObstacles = Call($aObstacles)
	ElseIf IsArray($aObstacles) Then
		$lCurrentObstacles = $aObstacles
	EndIf

	; Direct mode: skip pathfinding if destination is very close AND no obstacles
	Local $lHasObstacles = ($lIsDynamicObstacles Or (IsArray($lCurrentObstacles) And UBound($lCurrentObstacles) > 0))
	Local $lDirectMode = (Not $lHasObstacles And _Pathfinder_Distance($lMyX, $lMyY, $aDestX, $aDestY) < $g_iPathfinder_DirectMoveDistance)

	; Initial path calculation
	Local $lPath
	If $lDirectMode Then
		_Pathfinder_Log("Direct mode: destination within " & $g_iPathfinder_DirectMoveDistance & " units, skipping pathfinding")
		Local $lEmptyPath[0][4]
		$lPath = $lEmptyPath
		_Pathfinder_SafeMove($aDestX, $aDestY, $lLayer, $lMyOldMap)
	Else
		$lPath = _Pathfinder_GetPath($lMyX, $lMyY, $lLayer, $aDestX, $aDestY, $aDestLayer, $lCurrentObstacles)
		If Not IsArray($lPath) Or UBound($lPath) = 0 Then
			Local $lEmptyPath2[0][4]
			$lPath = $lEmptyPath2
			_Pathfinder_SafeMove($aDestX, $aDestY, $lLayer, $lMyOldMap)
		EndIf
	EndIf

	$g_aPathfinder_CurrentPath = $lPath
	$g_iPathfinder_CurrentPathIndex = 0
	$g_hPathfinder_LastPathUpdateTime = TimerInit()

	; Stuck detection state
	Local $lLastObstacleUpdate = TimerInit()
	Local $lLastStuckCheckTime = TimerInit()
	Local $lLastStuckCheckX = $lMyX
	Local $lLastStuckCheckY = $lMyY
	Local $lStuckCount = 0
	Local $lNeedPathUpdate = False
	Local $lWasDead = False

	; === Main movement loop ===
	Do
		; --- Phase 1: Exit conditions ---
		If $g_bPathfinder_CancelMovement Then
			Agent_CancelAction()
			Return $PATHFINDER_CANCELLED
		EndIf

		; Detect map loading or map change - cancel movement immediately
		If Map_GetInstanceInfo("Type") = $GC_I_MAP_TYPE_LOADING Then
			Agent_CancelAction()
			Return $PATHFINDER_MAP_CHANGED
		EndIf

		If (Map_GetMapID() <> $lMyOldMap And Not Game_GetGameInfo("IsCinematic")) Or Map_GetInstanceInfo("Type") <> $lMapLoadingOld Then
			Agent_CancelAction()
			Return $PATHFINDER_MAP_CHANGED
		EndIf

		If Party_GetPartyContextInfo("IsDefeated") Then Return $PATHFINDER_DEFEATED

		; --- Phase 2: Wait while dead ---
		If Agent_GetAgentInfo(-2, "IsDead") Then
			$lNeedPathUpdate = True
			$lWasDead = True
			ContinueLoop
		EndIf

		$lMyX = Agent_GetAgentInfo(-2, "X")
		$lMyY = Agent_GetAgentInfo(-2, "Y")

		; Reset stuck state after resurrection (avoid false positives from stale position)
		If $lWasDead Then
			$lLastStuckCheckX = $lMyX
			$lLastStuckCheckY = $lMyY
			$lLastStuckCheckTime = TimerInit()
			$lStuckCount = 0
			$lWasDead = False
		EndIf

		; --- Phase 3: Dynamic obstacle update ---
		If $lIsDynamicObstacles And TimerDiff($lLastObstacleUpdate) > $g_iPathfinder_ObstacleUpdateInterval Then
			$lCurrentObstacles = Call($aObstacles)
			$lLastObstacleUpdate = TimerInit()
			$lNeedPathUpdate = True
		EndIf

		; --- Phase 4: Stuck detection ---
		If TimerDiff($lLastStuckCheckTime) > $g_iPathfinder_StuckCheckInterval Then
			If _Pathfinder_Distance($lMyX, $lMyY, $lLastStuckCheckX, $lLastStuckCheckY) < $g_iPathfinder_StuckDistance Then
				$lStuckCount += 1
				If $lStuckCount >= 2 Then
					_Pathfinder_Unstuck($lMyX, $lMyY, $lLayer, $lStuckCount, $lMyOldMap)
					$lStuckCount = 0
					$lNeedPathUpdate = True
				EndIf
			Else
				$lStuckCount = 0
			EndIf
			$lLastStuckCheckX = $lMyX
			$lLastStuckCheckY = $lMyY
			$lLastStuckCheckTime = TimerInit()
		EndIf

		; --- Phase 5: Path recalculation (event-driven with cooldown) ---
		If Not $lDirectMode Then
			Local $lShouldRecalc = $lNeedPathUpdate Or _Pathfinder_HasDeviated($lMyX, $lMyY, $g_aPathfinder_CurrentPath, $g_iPathfinder_CurrentPathIndex, $g_iPathfinder_DeviationThreshold)
			If $lShouldRecalc And TimerDiff($g_hPathfinder_LastPathUpdateTime) > $g_iPathfinder_RecalcCooldown Then
				$lLayer = Agent_GetAgentInfo(-2, "Plane")
				$lPath = _Pathfinder_GetPath($lMyX, $lMyY, $lLayer, $aDestX, $aDestY, $aDestLayer, $lCurrentObstacles)
				If IsArray($lPath) And UBound($lPath) > 0 Then
					$g_aPathfinder_CurrentPath = $lPath
					; Find the closest waypoint in the new path instead of resetting to 0
					$g_iPathfinder_CurrentPathIndex = _Pathfinder_FindClosestWaypointIndex($lMyX, $lMyY, $lPath)
				Else
					Local $lEmptyPath3[0][4]
					$g_aPathfinder_CurrentPath = $lEmptyPath3
					$g_iPathfinder_CurrentPathIndex = 0
				EndIf
				$g_hPathfinder_LastPathUpdateTime = TimerInit()
				$lNeedPathUpdate = False
			EndIf
		EndIf

		; --- Phase 6: Follow waypoints ---
		_Pathfinder_FollowWaypoints($lMyX, $lMyY, $aDestX, $aDestY, $lLayer, $lMyOldMap)

		; --- Phase 7: Combat & party management (skipped during switch TP puzzle) ---
		If Map_GetInstanceInfo("Type") = $GC_I_MAP_TYPE_EXPLORABLE And Not $g_bPathfinder_SwitchTP_Active Then
			If _Pathfinder_HandleCombatPhase($lMyX, $lMyY, $aAggroRange, $aFightRangeOut, $aFinisherMode) Then
				$lNeedPathUpdate = True
			EndIf
		EndIf

		Sleep(32)

		If $aCallFunc <> "" Then Call($aCallFunc)
		If Game_GetGameInfo("IsCinematic") Then Other_WaitPingStabilized(2000)

	Until Agent_GetDistanceToXY($aDestX, $aDestY) < $g_iPathfinder_ArrivalDistance

	Agent_CancelAction()
	Return $PATHFINDER_OK
EndFunc

; =============================================================================
; Cancel a running MoveTo from external code
; =============================================================================
Func Pathfinder_CancelMoveTo()
	$g_bPathfinder_CancelMovement = True
EndFunc

; =============================================================================
; Ensure DLL is loaded and initialized (does NOT shutdown between calls)
; Returns True if ready, False on failure
; =============================================================================
Func _Pathfinder_EnsureDLL()
	If $g_hPathfinderDLL <> 0 And $g_hPathfinderDLL <> -1 Then Return True

	Local $lResult = Pathfinder_Initialize()
	If $lResult = 0 Then
		Out("[Pathfinder] ERROR: Failed to initialize DLL")
		Return False
	ElseIf $lResult = 2 Then
		Out("[Pathfinder] WARNING: maps.rar and maps/ folder not found - pathfinding may not work")
	EndIf
	Return True
EndFunc

; =============================================================================
; Safe move: sends movement command if still on same map, cancels otherwise
; =============================================================================
Func _Pathfinder_SafeMove($aX, $aY, $aLayer, $aExpectedMap)
	If Map_GetMapID() = $aExpectedMap Then
		Map_MoveLayer($aX, $aY, $aLayer)
	Else
		Agent_CancelAction()
	EndIf
EndFunc

; =============================================================================
; Smart unstuck: perpendicular to path first, then fallback to 8 directions
; =============================================================================
Func _Pathfinder_Unstuck($aMyX, $aMyY, $aLayer, $aStuckCount, $aExpectedMap)
	Local $lAngle

	If $g_iPathfinder_CurrentPathIndex < UBound($g_aPathfinder_CurrentPath) Then
		; Compute angle from player to current waypoint
		Local $lWpX = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][0]
		Local $lWpY = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][1]
		Local $lBaseAngle = _Pathfinder_AngleTo($aMyX, $aMyY, $lWpX, $lWpY)

		If $aStuckCount <= 4 Then
			; Try perpendicular: alternate left (+PI/2) and right (-PI/2)
			If Mod($aStuckCount, 2) = 0 Then
				$lAngle = $lBaseAngle + 1.5707963
			Else
				$lAngle = $lBaseAngle - 1.5707963
			EndIf
		Else
			; Fallback: cycle through 8 fixed directions
			Local $lFallbackAngles[8] = [1.5707963, 4.7123890, 0.0, 3.1415927, 0.7853982, 3.9269908, 2.3561945, 5.4977871]
			$lAngle = $lFallbackAngles[Mod($g_iPathfinder_UnstuckDirectionIndex, 8)]
			$g_iPathfinder_UnstuckDirectionIndex = Mod($g_iPathfinder_UnstuckDirectionIndex + 1, 8)
		EndIf
	Else
		; No waypoint available, use fallback directions
		Local $lFallbackAngles2[8] = [1.5707963, 4.7123890, 0.0, 3.1415927, 0.7853982, 3.9269908, 2.3561945, 5.4977871]
		$lAngle = $lFallbackAngles2[Mod($g_iPathfinder_UnstuckDirectionIndex, 8)]
		$g_iPathfinder_UnstuckDirectionIndex = Mod($g_iPathfinder_UnstuckDirectionIndex + 1, 8)
	EndIf

	_Pathfinder_SafeMove($aMyX + Cos($lAngle) * 500, $aMyY + Sin($lAngle) * 500, $aLayer, $aExpectedMap)
	Sleep(500)
EndFunc

; =============================================================================
; Check if player has deviated from the current path segment
; =============================================================================
Func _Pathfinder_HasDeviated($aMyX, $aMyY, $aPath, $aIndex, $aThreshold)
	If UBound($aPath) = 0 Or $aIndex >= UBound($aPath) Then Return False
	If $aIndex = 0 Then Return False ; No previous waypoint to form a segment

	Local $lPrevX = $aPath[$aIndex - 1][0]
	Local $lPrevY = $aPath[$aIndex - 1][1]
	Local $lCurX = $aPath[$aIndex][0]
	Local $lCurY = $aPath[$aIndex][1]

	Return (_Pathfinder_DistToSegment($aMyX, $aMyY, $lPrevX, $lPrevY, $lCurX, $lCurY) > $aThreshold)
EndFunc

; =============================================================================
; Perpendicular distance from point P to line segment AB
; =============================================================================
Func _Pathfinder_DistToSegment($px, $py, $ax, $ay, $bx, $by)
	Local $dx = $bx - $ax
	Local $dy = $by - $ay
	Local $lenSq = $dx * $dx + $dy * $dy

	If $lenSq = 0 Then Return _Pathfinder_Distance($px, $py, $ax, $ay)

	; Project point onto line, clamped to [0, 1]
	Local $t = (($px - $ax) * $dx + ($py - $ay) * $dy) / $lenSq
	If $t < 0 Then $t = 0
	If $t > 1 Then $t = 1

	Return _Pathfinder_Distance($px, $py, $ax + $t * $dx, $ay + $t * $dy)
EndFunc

; =============================================================================
; Find the closest waypoint index in a path from current position
; Skips waypoints we've already passed (closest that is ahead of us)
; =============================================================================
Func _Pathfinder_FindClosestWaypointIndex($aMyX, $aMyY, $aPath)
	If Not IsArray($aPath) Or UBound($aPath) = 0 Then Return 0

	Local $lBestIndex = 0
	Local $lBestDist = _Pathfinder_Distance($aMyX, $aMyY, $aPath[0][0], $aPath[0][1])

	For $i = 1 To UBound($aPath) - 1
		Local $lDist = _Pathfinder_Distance($aMyX, $aMyY, $aPath[$i][0], $aPath[$i][1])
		If $lDist < $lBestDist Then
			$lBestDist = $lDist
			$lBestIndex = $i
		EndIf
	Next

	If $lBestIndex > 0 Then
		_Pathfinder_Log("Path recalc: resuming at waypoint " & $lBestIndex & "/" & UBound($aPath) & " (tp_type=" & $aPath[$lBestIndex][3] & ")")
	EndIf
	Return $lBestIndex
EndFunc

; =============================================================================
; Follow current path waypoints and issue movement commands
; =============================================================================
Func _Pathfinder_FollowWaypoints($aMyX, $aMyY, $aDestX, $aDestY, ByRef $aLayer, $aExpectedMap)
	If $g_iPathfinder_CurrentPathIndex >= UBound($g_aPathfinder_CurrentPath) Then
		_Pathfinder_SafeMove($aDestX, $aDestY, $aLayer, $aExpectedMap)
		Return
	EndIf

	Local $lWaypointX = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][0]
	Local $lWaypointY = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][1]
	$aLayer = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][2]
	Local $lTpType = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][3]

	; Check if this switch TP needs activation: the next waypoint is far away (teleport jump)
	; If the next waypoint is nearby, we're on the exit side and don't need to activate
	Local $lSwitchNeedsActivation = False
	If $lTpType = 3 And ($g_iPathfinder_CurrentPathIndex + 1) < UBound($g_aPathfinder_CurrentPath) Then
		Local $lNextWpX = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex + 1][0]
		Local $lNextWpY = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex + 1][1]
		If _Pathfinder_Distance($lWaypointX, $lWaypointY, $lNextWpX, $lNextWpY) > 1000 Then $lSwitchNeedsActivation = True
	EndIf

	; Pre-scan: start monitoring gadgets when approaching a switch TP (within gadget range)
	; This catches the activation sequence even if it starts before the player arrives at the exact TP position
	Local $lDistToWp = _Pathfinder_Distance($aMyX, $aMyY, $lWaypointX, $lWaypointY)
	If $lSwitchNeedsActivation And Not $g_bPathfinder_SwitchTP_Scanning And $lDistToWp < $g_iPathfinder_SwitchTP_GadgetRange Then
		_Pathfinder_Log("SwitchTP: Pre-scanning gadgets (approaching TP, dist=" & Round($lDistToWp, 0) & ")")
		_Pathfinder_StartPreScan($lWaypointX, $lWaypointY)
	EndIf

	; Use tighter distance threshold for switch teleporters that need activation
	Local $lReachDist = $g_iPathfinder_WaypointReachedDistance
	If $lSwitchNeedsActivation Then $lReachDist = $g_iPathfinder_SwitchTP_ArrivalDist

	If $lDistToWp < $lReachDist Then
		; Handle switch teleporter only if we need to activate it (entering the TP, not exiting)
		If $lSwitchNeedsActivation Then
			If $g_sPathfinder_SwitchTeleportFunc <> "" Then
				_Pathfinder_Log("Switch TP reached at (" & Round($lWaypointX, 1) & ", " & Round($lWaypointY, 1) & ") - calling user callback")
				Call($g_sPathfinder_SwitchTeleportFunc, $lWaypointX, $lWaypointY)
			Else
				; Try puzzle + teleport up to 3 times
				Local $lTeleported = False
				Local $lExpectedLayer = -1
				If ($g_iPathfinder_CurrentPathIndex + 2) < UBound($g_aPathfinder_CurrentPath) Then
					$lExpectedLayer = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex + 1][2]
				EndIf

				For $lAttempt = 1 To 3
					If $lAttempt > 1 Then
						_Pathfinder_Log("SwitchTP: Attempt " & $lAttempt & "/3 - backing up to retrigger")
						Local $lBackupIndex = $g_iPathfinder_CurrentPathIndex - 3
						If $lBackupIndex < 0 Then $lBackupIndex = 0
						Local $lBkX = $g_aPathfinder_CurrentPath[$lBackupIndex][0]
						Local $lBkY = $g_aPathfinder_CurrentPath[$lBackupIndex][1]
						_Pathfinder_MoveToPoint($lBkX, $lBkY, 200, 10000)
						$g_bPathfinder_SwitchTP_Scanning = False
						Local $lEmptyPS[0]
						$g_aPathfinder_SwitchTP_PreScan = $lEmptyPS
						_Pathfinder_MoveToPoint($lWaypointX, $lWaypointY, $g_iPathfinder_SwitchTP_ArrivalDist, 15000)
					EndIf

					If Not _Pathfinder_HandleSwitchTeleporter($lWaypointX, $lWaypointY) Then ContinueLoop

					; Wait for teleport and verify it actually happened
					If $lExpectedLayer >= 0 Then
						_Pathfinder_WaitForTeleport($lExpectedLayer)
						If Agent_GetAgentInfo(-2, "Plane") = $lExpectedLayer Then
							$lTeleported = True
							_Pathfinder_Log("SwitchTP: Teleport confirmed to layer " & $lExpectedLayer)
							ExitLoop
						Else
							_Pathfinder_Log("SwitchTP: Teleport FAILED (still on layer " & Agent_GetAgentInfo(-2, "Plane") & ") - will retry")
						EndIf
					Else
						$lTeleported = True
						ExitLoop
					EndIf

					If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then ExitLoop
				Next

				If $lTeleported Then
					$aLayer = Agent_GetAgentInfo(-2, "Plane")
					Local $lEmptyPathTP[0][4]
					$g_aPathfinder_CurrentPath = $lEmptyPathTP
					$g_iPathfinder_CurrentPathIndex = 0
					$g_hPathfinder_LastPathUpdateTime = 0
					_Pathfinder_Log("Post-teleport: path invalidated, will recalculate from new position")
					Return
				Else
					_Pathfinder_Log("SwitchTP: Failed after 3 attempts, continuing path anyway")
				EndIf
			EndIf
		ElseIf $lTpType = 3 Then
			_Pathfinder_Log("Switch TP exit at (" & Round($lWaypointX, 1) & ", " & Round($lWaypointY, 1) & ") - no activation needed")
		EndIf

		$g_iPathfinder_CurrentPathIndex += 1

		; Wait for teleport transition for non-switch TPs
		If $lTpType <> 0 And $lTpType <> 3 And $g_iPathfinder_CurrentPathIndex < UBound($g_aPathfinder_CurrentPath) Then
			Local $lNextLayer = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][2]
			If $lNextLayer <> $aLayer Then
				_Pathfinder_WaitForTeleport($lNextLayer)
				$aLayer = Agent_GetAgentInfo(-2, "Plane")
				Local $lEmptyPathTP2[0][4]
				$g_aPathfinder_CurrentPath = $lEmptyPathTP2
				$g_iPathfinder_CurrentPathIndex = 0
				$g_hPathfinder_LastPathUpdateTime = 0
				_Pathfinder_Log("Post-teleport: path invalidated, will recalculate from new position")
				Return
			EndIf
		EndIf

		; Look-ahead: skip waypoints we've already passed (find closest upcoming waypoint)
		If $g_iPathfinder_CurrentPathIndex < UBound($g_aPathfinder_CurrentPath) Then
			Local $lBestIndex = $g_iPathfinder_CurrentPathIndex
			Local $lBestDist = _Pathfinder_Distance($aMyX, $aMyY, _
				$g_aPathfinder_CurrentPath[$lBestIndex][0], $g_aPathfinder_CurrentPath[$lBestIndex][1])

			For $i = $g_iPathfinder_CurrentPathIndex + 1 To UBound($g_aPathfinder_CurrentPath) - 1
				; Don't skip teleporter waypoints (tp_type != 0)
				If $g_aPathfinder_CurrentPath[$i][3] <> 0 Then ExitLoop
				; Don't skip layer transitions
				If $g_aPathfinder_CurrentPath[$i][2] <> $g_aPathfinder_CurrentPath[$lBestIndex][2] Then ExitLoop

				Local $lDist = _Pathfinder_Distance($aMyX, $aMyY, _
					$g_aPathfinder_CurrentPath[$i][0], $g_aPathfinder_CurrentPath[$i][1])
				If $lDist < $lBestDist Then
					$lBestDist = $lDist
					$lBestIndex = $i
				Else
					ExitLoop ; Distance increasing, stop scanning
				EndIf
			Next

			If $lBestIndex > $g_iPathfinder_CurrentPathIndex Then
				_Pathfinder_Log("Look-ahead: skipped " & ($lBestIndex - $g_iPathfinder_CurrentPathIndex) & " waypoints")
				$g_iPathfinder_CurrentPathIndex = $lBestIndex
			EndIf
		EndIf

		If $g_iPathfinder_CurrentPathIndex < UBound($g_aPathfinder_CurrentPath) Then
			$lWaypointX = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][0]
			$lWaypointY = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][1]
			$aLayer = $g_aPathfinder_CurrentPath[$g_iPathfinder_CurrentPathIndex][2]
		Else
			$lWaypointX = $aDestX
			$lWaypointY = $aDestY
		EndIf
	EndIf

	_Pathfinder_SafeMove($lWaypointX, $lWaypointY, $aLayer, $aExpectedMap)
EndFunc

; =============================================================================
; Switch Teleporter Puzzle Solver
; 1. Finds nearby gadgets
; 2. Monitors NameProperties to detect activation order
; 3. Moves to each gadget in order and interacts
; 4. Returns to TP position
; =============================================================================
Func _Pathfinder_HandleSwitchTeleporter($aTpX, $aTpY)
	Local $aOrder

	; Use pre-scanned order if available (detected during approach)
	If $g_bPathfinder_SwitchTP_Scanning And IsArray($g_aPathfinder_SwitchTP_PreScan) And UBound($g_aPathfinder_SwitchTP_PreScan) > 0 Then
		$aOrder = $g_aPathfinder_SwitchTP_PreScan
		_Pathfinder_Log("SwitchTP: Using pre-scanned order (" & UBound($aOrder) & " gadgets)")
	Else
		; Fallback: detect now (if pre-scan didn't catch it)
		Local $aGadgets = _Pathfinder_FindPuzzleGadgets($aTpX, $aTpY, $g_iPathfinder_SwitchTP_GadgetRange)
		If Not IsArray($aGadgets) Or UBound($aGadgets) = 0 Then
			_Pathfinder_Log("SwitchTP: No puzzle gadgets found within range " & $g_iPathfinder_SwitchTP_GadgetRange)
			$g_bPathfinder_SwitchTP_Scanning = False
			Return False
		EndIf

		_Pathfinder_Log("SwitchTP: Found " & UBound($aGadgets) & " gadgets, waiting for activation sequence...")
		$aOrder = _Pathfinder_DetectGadgetActivationOrder($aGadgets)
	EndIf

	; Reset pre-scan state and re-enable combat
	$g_bPathfinder_SwitchTP_Scanning = False
	$g_bPathfinder_SwitchTP_Active = False
	Local $lEmptyPreScan[0]
	$g_aPathfinder_SwitchTP_PreScan = $lEmptyPreScan

	If Not IsArray($aOrder) Or UBound($aOrder) = 0 Then
		_Pathfinder_Log("SwitchTP: Failed to detect activation order")
		Return False
	EndIf

	_Pathfinder_Log("SwitchTP: Order detected (" & UBound($aOrder) & " gadgets), executing sequence...")

	; Move to each gadget in order and interact
	For $i = 0 To UBound($aOrder) - 1
		If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then Return False

		Local $gX = Agent_GetAgentInfo($aOrder[$i], "X")
		Local $gY = Agent_GetAgentInfo($aOrder[$i], "Y")
		Local $gID = Agent_GetAgentInfo($aOrder[$i], "ID")

		_Pathfinder_Log("SwitchTP: Moving to gadget #" & ($i + 1) & " (ID=" & $gID & ") at (" & Round($gX, 1) & ", " & Round($gY, 1) & ")")
		_Pathfinder_MoveToPoint($gX, $gY, $g_iPathfinder_SwitchTP_ArrivalDist)
		Agent_GoSignpost($aOrder[$i])
		Sleep(250)
	Next

	; Return to TP position
	_Pathfinder_Log("SwitchTP: Returning to TP position")
	_Pathfinder_MoveToPoint($aTpX, $aTpY, $g_iPathfinder_SwitchTP_ArrivalDist)

	Return True
EndFunc

; =============================================================================
; Start pre-scanning gadgets during approach (non-blocking baseline + monitoring)
; Called when player enters gadget range but hasn't reached TP yet
; =============================================================================
Func _Pathfinder_StartPreScan($aTpX, $aTpY)
	$g_bPathfinder_SwitchTP_Scanning = True
	$g_bPathfinder_SwitchTP_Active = True
	Local $lEmptyPreScan[0]
	$g_aPathfinder_SwitchTP_PreScan = $lEmptyPreScan

	; Find gadgets and start monitoring
	Local $aGadgets = _Pathfinder_FindPuzzleGadgets($aTpX, $aTpY, $g_iPathfinder_SwitchTP_GadgetRange)
	If Not IsArray($aGadgets) Or UBound($aGadgets) = 0 Then
		_Pathfinder_Log("SwitchTP PreScan: No gadgets found")
		$g_bPathfinder_SwitchTP_Scanning = False
		$g_bPathfinder_SwitchTP_Active = False
		Return
	EndIf

	_Pathfinder_Log("SwitchTP PreScan: Found " & UBound($aGadgets) & " gadgets, recording baseline and detecting order...")

	; Run full detection (baseline → phase 1 → phase 2)
	; This runs while the player is still walking towards the TP
	Local $aOrder = _Pathfinder_DetectGadgetActivationOrder($aGadgets)

	If IsArray($aOrder) And UBound($aOrder) > 0 Then
		$g_aPathfinder_SwitchTP_PreScan = $aOrder
		_Pathfinder_Log("SwitchTP PreScan: Order captured (" & UBound($aOrder) & " gadgets) - ready for execution on arrival")
	Else
		_Pathfinder_Log("SwitchTP PreScan: Failed to detect order during approach")
		$g_bPathfinder_SwitchTP_Scanning = False
		$g_bPathfinder_SwitchTP_Active = False
	EndIf
EndFunc

; =============================================================================
; Move to an exact point using direct movement (no pathfinding)
; Used for short-range movement during puzzles
; =============================================================================
Func _Pathfinder_MoveToPoint($aX, $aY, $aDist, $aTimeout = 10000)
	Local $lTimer = TimerInit()
	Do
		If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then Return
		Map_Move($aX, $aY, 0)
		Sleep(100)
	Until Agent_GetDistanceToXY($aX, $aY) < $aDist Or TimerDiff($lTimer) > $aTimeout
EndFunc

; =============================================================================
; Find puzzle gadgets within range of a position
; Returns: 0-indexed array of agent pointers, or 0 on failure
; =============================================================================
Func _Pathfinder_FindPuzzleGadgets($aCenterX, $aCenterY, $aRange)
	Local $aAllGadgets = Agent_GetAgentArray($GC_I_AGENT_TYPE_GADGET)
	If Not IsArray($aAllGadgets) Or $aAllGadgets[0] = 0 Then Return 0

	Local $aResult[0]
	For $i = 1 To $aAllGadgets[0]
		Local $gPtr = $aAllGadgets[$i]

		; Apply optional user filter
		If $g_sPathfinder_SwitchTP_GadgetFilter <> "" Then
			If Not Call($g_sPathfinder_SwitchTP_GadgetFilter, $gPtr) Then ContinueLoop
		EndIf

		; Filter by distance from TP position
		Local $gX = Agent_GetAgentInfo($gPtr, "X")
		Local $gY = Agent_GetAgentInfo($gPtr, "Y")
		If _Pathfinder_Distance($gX, $gY, $aCenterX, $aCenterY) <= $aRange Then
			ReDim $aResult[UBound($aResult) + 1]
			$aResult[UBound($aResult) - 1] = $gPtr
		EndIf
	Next

	If UBound($aResult) = 0 Then Return 0
	Return $aResult
EndFunc

; =============================================================================
; Detect gadget activation order by monitoring NameProperties changes
; Phase 1: Wait for all gadgets to activate (all NameProperties change from baseline)
; Phase 2: Wait for individual NameProperties changes to determine order
; Returns: Ordered array of agent pointers, or 0 on failure
; =============================================================================
Func _Pathfinder_DetectGadgetActivationOrder($aGadgets)
	Local $iCount = UBound($aGadgets)

	; Record baseline NameProperties
	Local $aBaseline[$iCount]
	For $i = 0 To $iCount - 1
		$aBaseline[$i] = Agent_GetAgentInfo($aGadgets[$i], "NameProperties")
	Next
	_Pathfinder_Log("SwitchTP: Baseline recorded for " & $iCount & " gadgets")

	; Phase 1: Wait for all gadgets to change from baseline (simultaneous activation)
	Local $lTimer = TimerInit()
	Local $bAllChanged = False
	Do
		$bAllChanged = True
		For $i = 0 To $iCount - 1
			If Agent_GetAgentInfo($aGadgets[$i], "NameProperties") = $aBaseline[$i] Then
				$bAllChanged = False
				ExitLoop
			EndIf
		Next
		Sleep(50)
		If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then Return 0
	Until $bAllChanged Or TimerDiff($lTimer) > $g_iPathfinder_SwitchTP_SequenceTimeout

	If Not $bAllChanged Then
		_Pathfinder_Log("SwitchTP: Timeout waiting for initial activation")
		Return 0
	EndIf
	_Pathfinder_Log("SwitchTP: All gadgets activated (phase 1 complete)")

	; Record phase 1 activated values to detect when they change away from it
	Local $aActivatedValues[$iCount]
	For $i = 0 To $iCount - 1
		$aActivatedValues[$i] = Agent_GetAgentInfo($aGadgets[$i], "NameProperties")
	Next

	; Phase 2: Wait for all gadgets to deactivate (leave their activated state)
	_Pathfinder_Log("SwitchTP: Waiting for deactivation phase...")
	$lTimer = TimerInit()
	Do
		Local $lDeactivatedCount = 0
		For $i = 0 To $iCount - 1
			If Agent_GetAgentInfo($aGadgets[$i], "NameProperties") <> $aActivatedValues[$i] Then $lDeactivatedCount += 1
		Next
		If $lDeactivatedCount >= $iCount Then ExitLoop
		Sleep(50)
		If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then Return 0
	Until TimerDiff($lTimer) > $g_iPathfinder_SwitchTP_SequenceTimeout

	_Pathfinder_Log("SwitchTP: Deactivation complete, now detecting sequential order (phase 3)...")

	; Record current state as baseline for phase 3 (should be back to ~baseline values)
	Local $aPhase3Baseline[$iCount]
	For $i = 0 To $iCount - 1
		$aPhase3Baseline[$i] = Agent_GetAgentInfo($aGadgets[$i], "NameProperties")
	Next

	; Phase 3: Detect individual sequential activation (one by one, with delay between each)
	Local $aOrder[0]
	Local $aDetected[$iCount]
	For $i = 0 To $iCount - 1
		$aDetected[$i] = False
	Next

	$lTimer = TimerInit()
	While UBound($aOrder) < $iCount And TimerDiff($lTimer) < $g_iPathfinder_SwitchTP_SequenceTimeout
		For $i = 0 To $iCount - 1
			If $aDetected[$i] Then ContinueLoop
			Local $lCurrent = Agent_GetAgentInfo($aGadgets[$i], "NameProperties")
			If $lCurrent <> $aPhase3Baseline[$i] Then
				$aDetected[$i] = True
				ReDim $aOrder[UBound($aOrder) + 1]
				$aOrder[UBound($aOrder) - 1] = $aGadgets[$i]
				_Pathfinder_Log("SwitchTP: Gadget #" & UBound($aOrder) & " in sequence: ID=" & Agent_GetAgentInfo($aGadgets[$i], "ID") & " (dt=" & Round(TimerDiff($lTimer)) & "ms)")
			EndIf
		Next
		Sleep(50)
		If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then Return 0
	WEnd

	_Pathfinder_Log("SwitchTP: Detected " & UBound($aOrder) & "/" & $iCount & " gadgets in sequence")
	Return $aOrder
EndFunc

; =============================================================================
; Wait for a teleport transition to complete (player reaches expected layer)
; =============================================================================
Func _Pathfinder_WaitForTeleport($aExpectedLayer)
	_Pathfinder_Log("Waiting for teleport to layer " & $aExpectedLayer)
	Local $lTimeout = TimerInit()
	Do
		Sleep(100)
		If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then Return
	Until Agent_GetAgentInfo(-2, "Plane") = $aExpectedLayer Or TimerDiff($lTimeout) > 5000
	_Pathfinder_Log("Teleport wait finished (layer=" & Agent_GetAgentInfo(-2, "Plane") & ")")
EndFunc

; =============================================================================
; Handle combat, party wait, and resurrection in one phase
; Returns True if player moved significantly (triggers path recalc)
; =============================================================================
Func _Pathfinder_HandleCombatPhase($aMyX, $aMyY, $aAggroRange, $aFightRangeOut, $aFinisherMode)
	UAI_Fight($aMyX, $aMyY, $aAggroRange, $aFightRangeOut, $aFinisherMode)

	; Wait for heroes if they are too far
	If _Pathfinder_ShouldWaitForParty(2000, 1320) Then
		Local $lWaitTimer = TimerInit()
		Do
			If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then ExitLoop
			Agent_CancelAction()
			Sleep(250)
		Until _Pathfinder_PartyWithinRange(1320) Or TimerDiff($lWaitTimer) > 30000
	EndIf

	; Wait for resurrection if needed
	If _Pathfinder_ShouldWaitForResurrection() Then
		_Pathfinder_WaitForResurrection()
	EndIf

	; Check if player moved significantly during combat/wait
	Local $lNewX = Agent_GetAgentInfo(-2, "X")
	Local $lNewY = Agent_GetAgentInfo(-2, "Y")
	Return (_Pathfinder_Distance($aMyX, $aMyY, $lNewX, $lNewY) > 200)
EndFunc

; =============================================================================
; Angle from point A to point B (radians)
; =============================================================================
Func _Pathfinder_AngleTo($x1, $y1, $x2, $y2)
	Local $dx = $x2 - $x1
	Local $dy = $y2 - $y1
	If $dx = 0 Then
		If $dy >= 0 Then Return 1.5707963
		Return -1.5707963
	EndIf
	Local $lAngle = ATan($dy / $dx)
	If $dx < 0 Then $lAngle += 3.14159265
	Return $lAngle
EndFunc

; =============================================================================
; Internal: Get path from current position to destination
; =============================================================================
Func _Pathfinder_GetPath($aStartX, $aStartY, $aStartLayer, $aDestX, $aDestY, $aDestLayer, $aObstacles)
	Local $lMapID = Map_GetMapID()
	Local $lInstanceType = Map_GetInstanceInfo("Type") ; 0=Outpost, 1=Explorable, 2=Loading
	If $lInstanceType < 0 Or $lInstanceType > 1 Then $lInstanceType = -1
	Local $lObstacleCount = 0
	If IsArray($aObstacles) Then $lObstacleCount = UBound($aObstacles)

	_Pathfinder_Log("GetPath: Map=" & $lMapID & " InstanceType=" & $lInstanceType & " Start=(" & Round($aStartX, 1) & ", " & Round($aStartY, 1) & ") Layer=" & $aStartLayer & " Dest=(" & Round($aDestX, 1) & ", " & Round($aDestY, 1) & ") Obstacles=" & $lObstacleCount)

	Local $lPath = Pathfinder_FindPath($lMapID, $lInstanceType, $aStartX, $aStartY, $aStartLayer, $aDestX, $aDestY, $aDestLayer, $aObstacles, $g_iPathfinder_SimplifyRange)
	Local $lError = @error
	Local $lExtended = @extended

	If $lError Then
		_Pathfinder_Log("ERROR: FindPath failed - @error=" & $lError & " @extended=" & $lExtended)
		Return 0
	EndIf

	If Not IsArray($lPath) Then
		_Pathfinder_Log("ERROR: FindPathWithObstacles returned non-array")
		Return 0
	EndIf

	; Log teleporter waypoints for diagnosis
	Local $lTpInfo = ""
	For $i = 0 To UBound($lPath) - 1
		If $lPath[$i][3] <> 0 Then
			$lTpInfo &= " [" & $i & ":tp=" & $lPath[$i][3] & " (" & Round($lPath[$i][0], 0) & "," & Round($lPath[$i][1], 0) & ")]"
		EndIf
	Next
	_Pathfinder_Log("SUCCESS: Path found with " & UBound($lPath) & " points" & ($lTpInfo <> "" ? " | TPs:" & $lTpInfo : ""))
	Return $lPath
EndFunc

; =============================================================================
; Internal: Calculate distance between two points
; =============================================================================
Func _Pathfinder_Distance($aX1, $aY1, $aX2, $aY2)
	Return Sqrt(($aX2 - $aX1) ^ 2 + ($aY2 - $aY1) ^ 2)
EndFunc

; =============================================================================
; Get current path for debugging/visualization
; =============================================================================
Func Pathfinder_GetCurrentPath()
	Return $g_aPathfinder_CurrentPath
EndFunc

; =============================================================================
; Get current waypoint index
; =============================================================================
Func Pathfinder_GetCurrentWaypointIndex()
	Return $g_iPathfinder_CurrentPathIndex
EndFunc

; =============================================================================
; Setters
; =============================================================================
Func Pathfinder_SetWaypointReachedDistance($aDistance)
	$g_iPathfinder_WaypointReachedDistance = $aDistance
EndFunc

Func Pathfinder_SetArrivalDistance($aDistance)
	$g_iPathfinder_ArrivalDistance = $aDistance
EndFunc

Func Pathfinder_SetSimplifyRange($aRange)
	$g_iPathfinder_SimplifyRange = $aRange
EndFunc

Func Pathfinder_SetObstacleUpdateInterval($aInterval)
	$g_iPathfinder_ObstacleUpdateInterval = $aInterval
EndFunc

Func Pathfinder_SetDeviationThreshold($aThreshold)
	$g_iPathfinder_DeviationThreshold = $aThreshold
EndFunc


Func Pathfinder_SetRecalcCooldown($aCooldown)
	$g_iPathfinder_RecalcCooldown = $aCooldown
EndFunc

Func Pathfinder_SetDirectMoveDistance($aDistance)
	$g_iPathfinder_DirectMoveDistance = $aDistance
EndFunc

Func Pathfinder_SetSwitchTeleportCallback($sFuncName)
	$g_sPathfinder_SwitchTeleportFunc = $sFuncName
EndFunc

Func Pathfinder_SetSwitchTP_ArrivalDist($aDistance)
	$g_iPathfinder_SwitchTP_ArrivalDist = $aDistance
EndFunc

Func Pathfinder_SetSwitchTP_GadgetRange($aRange)
	$g_iPathfinder_SwitchTP_GadgetRange = $aRange
EndFunc

Func Pathfinder_SetSwitchTP_SequenceTimeout($aTimeout)
	$g_iPathfinder_SwitchTP_SequenceTimeout = $aTimeout
EndFunc

Func Pathfinder_SetSwitchTP_GadgetFilter($sFuncName)
	$g_sPathfinder_SwitchTP_GadgetFilter = $sFuncName
EndFunc

Func Pathfinder_SetDebug($bEnabled)
	$g_bPathfinder_Debug = $bEnabled
EndFunc

; =============================================================================
; Internal: Log debug message
; =============================================================================
Func _Pathfinder_Log($sMessage)
	If $g_bPathfinder_Debug Then
		Out("[Pathfinder] " & $sMessage)
	EndIf
EndFunc

; =============================================================================
; Helper: Check if party members are too far and need to wait
; =============================================================================
Func _Pathfinder_ShouldWaitForParty($fMaxDistance = 1800, $fResumeDistance = 1400)
	Local $iEnemyCount = GetAgents(-2, 1250, $GC_I_AGENT_TYPE_LIVING, 0, "_Pathfinder_FilterIsEnemy")
	If $iEnemyCount > 0 Then Return False

	Local $aFlagAll = World_GetWorldInfo("FlagAll")
	If IsArray($aFlagAll) Then
		Local $fX = $aFlagAll[0]
		Local $fY = $aFlagAll[1]
		If _IsFinite($fX) And _IsFinite($fY) Then Return False
	EndIf

	Local $iPartySize = Party_GetPartyContextInfo("TotalPartySize")
	Local $iNearbyCount = _Pathfinder_CountPartyMembersInRange($fResumeDistance)
	If $iNearbyCount >= $iPartySize - 1 Then Return False

	Local $iTotalCount = _Pathfinder_CountPartyMembersInRange(5000)
	If $iTotalCount < $iPartySize - 1 Then Return False

	Local $iFarthestID = _Pathfinder_GetFarthestPartyMember()
	If $iFarthestID = 0 Then Return False

	Return True
EndFunc

Func _IsFinite($fValue)
	Return ($fValue > -1e30 And $fValue < 1e30)
EndFunc

; =============================================================================
; Helper: Check if all party members are close enough to resume movement
; =============================================================================
Func _Pathfinder_PartyWithinRange($fResumeDistance = 1400)
	Local $iEnemyCount = GetAgents(-2, 1200, $GC_I_AGENT_TYPE_LIVING, 0, "_Pathfinder_FilterIsEnemy")
	If $iEnemyCount > 0 Then Return True

	Local $aFlagAll = World_GetWorldInfo("FlagAll")
	If IsArray($aFlagAll) Then
		Local $fX = $aFlagAll[0]
		Local $fY = $aFlagAll[1]
		If _IsFinite($fX) And _IsFinite($fY) Then Return True
	EndIf

	Local $iPartySize = Party_GetPartyContextInfo("TotalPartySize")
	Local $iNearbyCount = _Pathfinder_CountPartyMembersInRange($fResumeDistance)
	Return ($iNearbyCount >= $iPartySize - 1)
EndFunc

; =============================================================================
; Helper: Count party members (heroes + henchmen) within range
; =============================================================================
Func _Pathfinder_CountPartyMembersInRange($fRange)
	Local $iCount = 0
	Local $iMyID = Agent_GetMyID()

	Local $iHeroCount = Party_GetPartyContextInfo("HeroCount")
	For $i = 1 To $iHeroCount
		Local $iHeroAgentID = Party_GetMyPartyHeroInfo($i, "AgentID")
		If $iHeroAgentID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($iHeroAgentID, "IsDead") Then ContinueLoop
		If Agent_GetDistance($iHeroAgentID, $iMyID) <= $fRange Then $iCount += 1
	Next

	Local $iHenchCount = Party_GetPartyContextInfo("HenchmanCount")
	For $i = 1 To $iHenchCount
		Local $iHenchAgentID = Party_GetMyPartyHenchmanInfo($i, "AgentID")
		If $iHenchAgentID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($iHenchAgentID, "IsDead") Then ContinueLoop
		If Agent_GetDistance($iHenchAgentID, $iMyID) <= $fRange Then $iCount += 1
	Next

	Return $iCount
EndFunc

; =============================================================================
; Helper: Get the farthest party member (hero or henchman)
; =============================================================================
Func _Pathfinder_GetFarthestPartyMember()
	Local $iFarthestID = 0
	Local $fFarthestDist = 0
	Local $iMyID = Agent_GetMyID()

	Local $iHeroCount = Party_GetPartyContextInfo("HeroCount")
	For $i = 1 To $iHeroCount
		Local $fFlagX = Party_GetHeroFlagInfo($i, "FlagX")
		Local $fFlagY = Party_GetHeroFlagInfo($i, "FlagY")
		If $fFlagX <> 0 Or $fFlagY <> 0 Then ContinueLoop

		Local $iHeroAgentID = Party_GetMyPartyHeroInfo($i, "AgentID")
		If $iHeroAgentID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($iHeroAgentID, "IsDead") Then ContinueLoop

		Local $fDist = Agent_GetDistance($iHeroAgentID, $iMyID)
		If $fDist > $fFarthestDist Then
			$fFarthestDist = $fDist
			$iFarthestID = $iHeroAgentID
		EndIf
	Next

	Local $iHenchCount = Party_GetPartyContextInfo("HenchmanCount")
	For $i = 1 To $iHenchCount
		Local $iHenchAgentID = Party_GetMyPartyHenchmanInfo($i, "AgentID")
		If $iHenchAgentID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($iHenchAgentID, "IsDead") Then ContinueLoop

		Local $fDist = Agent_GetDistance($iHenchAgentID, $iMyID)
		If $fDist > $fFarthestDist Then
			$fFarthestDist = $fDist
			$iFarthestID = $iHenchAgentID
		EndIf
	Next

	Return $iFarthestID
EndFunc

; =============================================================================
; Helper: Check if there are dead party members that can be resurrected
; =============================================================================
Func _Pathfinder_ShouldWaitForResurrection()
	Local $iEnemyCount = GetAgents(-2, 1200, $GC_I_AGENT_TYPE_LIVING, 0, "_Pathfinder_FilterIsEnemy")
	If $iEnemyCount > 0 Then Return False

	If _Pathfinder_CountDeadPartyMembers() = 0 Then Return False
	If _Pathfinder_CountAvailableResurrections() = 0 Then Return False

	Return True
EndFunc

; =============================================================================
; Helper: Count dead party members (heroes + henchmen)
; =============================================================================
Func _Pathfinder_CountDeadPartyMembers()
	Local $iCount = 0

	Local $iHeroCount = Party_GetPartyContextInfo("HeroCount")
	For $i = 1 To $iHeroCount
		Local $iHeroAgentID = Party_GetMyPartyHeroInfo($i, "AgentID")
		If $iHeroAgentID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($iHeroAgentID, "IsDead") Then $iCount += 1
	Next

	Local $iHenchCount = Party_GetPartyContextInfo("HenchmanCount")
	For $i = 1 To $iHenchCount
		Local $iHenchAgentID = Party_GetMyPartyHenchmanInfo($i, "AgentID")
		If $iHenchAgentID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($iHenchAgentID, "IsDead") Then $iCount += 1
	Next

	Return $iCount
EndFunc

; =============================================================================
; Helper: Count available resurrection skills on living heroes (not on cooldown)
; =============================================================================
Func _Pathfinder_CountAvailableResurrections()
	Local $iCount = 0
	Local $iMyID = Agent_GetMyID()

	If Not Agent_GetAgentInfo(-2, "IsDead") Then
		For $iSlot = 1 To 8
			Local $iSkillID = Skill_GetSkillbarInfo($iSlot, "SkillID", 0)
			If $iSkillID = 0 Then ContinueLoop
			If Skill_IsAnyResurrection($iSkillID) Or Skill_IsResurrectionSpecial($iSkillID) Then
				If Skill_GetSkillbarInfo($iSlot, "IsRecharged", 0) Then $iCount += 1
			EndIf
		Next
	EndIf

	Local $iHeroCount = Party_GetPartyContextInfo("HeroCount")
	For $iHero = 1 To $iHeroCount
		Local $iHeroAgentID = Party_GetMyPartyHeroInfo($iHero, "AgentID")
		If $iHeroAgentID = 0 Then ContinueLoop
		If Agent_GetAgentInfo($iHeroAgentID, "IsDead") Then ContinueLoop
		If Agent_GetDistance($iHeroAgentID, $iMyID) > 5000 Then ContinueLoop

		For $iSlot = 1 To 8
			Local $iSkillID2 = Skill_GetSkillbarInfo($iSlot, "SkillID", $iHero)
			If $iSkillID2 = 0 Then ContinueLoop
			If Skill_IsAnyResurrection($iSkillID2) Or Skill_IsResurrectionSpecial($iSkillID2) Then
				If Skill_GetSkillbarInfo($iSlot, "IsRecharged", $iHero) Then $iCount += 1
			EndIf
		Next
	Next

	Return $iCount
EndFunc

; =============================================================================
; Helper: Get nearest dead party member (AgentID or 0)
; =============================================================================
Func _Pathfinder_GetNearestDeadPartyMember()
	Local $iNearestID = 0
	Local $fNearestDist = 999999
	Local $iMyID = Agent_GetMyID()

	Local $iHeroCount = Party_GetPartyContextInfo("HeroCount")
	For $i = 1 To $iHeroCount
		Local $iHeroAgentID = Party_GetMyPartyHeroInfo($i, "AgentID")
		If $iHeroAgentID = 0 Then ContinueLoop
		If Not Agent_GetAgentInfo($iHeroAgentID, "IsDead") Then ContinueLoop

		Local $fDist = Agent_GetDistance($iHeroAgentID, $iMyID)
		If $fDist < $fNearestDist Then
			$fNearestDist = $fDist
			$iNearestID = $iHeroAgentID
		EndIf
	Next

	Local $iHenchCount = Party_GetPartyContextInfo("HenchmanCount")
	For $i = 1 To $iHenchCount
		Local $iHenchAgentID = Party_GetMyPartyHenchmanInfo($i, "AgentID")
		If $iHenchAgentID = 0 Then ContinueLoop
		If Not Agent_GetAgentInfo($iHenchAgentID, "IsDead") Then ContinueLoop

		Local $fDist = Agent_GetDistance($iHenchAgentID, $iMyID)
		If $fDist < $fNearestDist Then
			$fNearestDist = $fDist
			$iNearestID = $iHenchAgentID
		EndIf
	Next

	Return $iNearestID
EndFunc

; =============================================================================
; Helper: Wait for dead party member to be resurrected
; =============================================================================
Func _Pathfinder_WaitForResurrection()
	Local $iDeadAllyID = _Pathfinder_GetNearestDeadPartyMember()
	If $iDeadAllyID = 0 Then Return

	Local $fDeadX = Agent_GetAgentInfo($iDeadAllyID, "X")
	Local $fDeadY = Agent_GetAgentInfo($iDeadAllyID, "Y")
	Local $fDist = Agent_GetDistanceToXY($fDeadX, $fDeadY)

	Local $lRezTimer = TimerInit()
	Do
		; Early exit on cancel or defeat
		If $g_bPathfinder_CancelMovement Or Party_GetPartyContextInfo("IsDefeated") Then Return

		; If Frozen Soil is active, find and kill the spirit
		If Agent_GetAgentEffectInfo(-2, 471, "HasEffect") Then
			Local $iFrozenSoilSpirit = GetAgents(-2, 5000, $GC_I_AGENT_TYPE_LIVING, 1, "_Pathfinder_FilterIsFrozenSoilSpirit")
			If $iFrozenSoilSpirit <> 0 Then
				Agent_ChangeTarget($iFrozenSoilSpirit)
				Agent_Attack($iFrozenSoilSpirit)
			EndIf
		Else
			If $fDist > 1000 Then Map_Move($fDeadX, $fDeadY, 0)

			; If player has a res skill ready, use it
			For $iSlot = 1 To 8
				Local $iSkillID = Skill_GetSkillbarInfo($iSlot, "SkillID", 0)
				If $iSkillID = 0 Then ContinueLoop
				If Not (Skill_IsAnyResurrection($iSkillID) Or Skill_IsResurrectionSpecial($iSkillID)) Then ContinueLoop
				If Not Skill_GetSkillbarInfo($iSlot, "IsRecharged", 0) Then ContinueLoop
				Skill_UseSkill($iSlot, $iDeadAllyID)
				ExitLoop
			Next
		EndIf

		Sleep(250)

		Local $iEnemyCount = GetAgents(-2, 1200, $GC_I_AGENT_TYPE_LIVING, 0, "_Pathfinder_FilterIsEnemy")
		If $iEnemyCount > 0 Then Return

		If Not Agent_GetAgentInfo($iDeadAllyID, "IsDead") Then
			$iDeadAllyID = _Pathfinder_GetNearestDeadPartyMember()
			If $iDeadAllyID = 0 Then Return
		EndIf

	Until _Pathfinder_CountAvailableResurrections() = 0 Or _Pathfinder_CountDeadPartyMembers() = 0 Or TimerDiff($lRezTimer) > 30000
EndFunc

; =============================================================================
; Filter: Is living enemy
; =============================================================================
Func _Pathfinder_FilterIsEnemy($aAgentPtr)
	If Agent_GetAgentInfo($aAgentPtr, "Allegiance") <> $GC_I_ALLEGIANCE_ENEMY Then Return False
	If Agent_GetAgentInfo($aAgentPtr, "HP") <= 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, "IsDead") Then Return False
	Return True
EndFunc

; =============================================================================
; Filter: Is Frozen Soil spirit (PlayerNumber 2882) and alive
; =============================================================================
Func _Pathfinder_FilterIsFrozenSoilSpirit($aAgentPtr)
	If Agent_GetAgentInfo($aAgentPtr, "PlayerNumber") <> 2882 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, "IsDead") Then Return False
	If Agent_GetAgentInfo($aAgentPtr, "HP") <= 0 Then Return False
	Return True
EndFunc