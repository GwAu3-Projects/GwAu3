#include-once

Func Map_Move($a_f_X, $a_f_Y, $a_f_Randomize = 50)
    ; Add randomization if requested
    If $a_f_Randomize > 0 Then
        $a_f_X += Random(-$a_f_Randomize, $a_f_Randomize)
        $a_f_Y += Random(-$a_f_Randomize, $a_f_Randomize)
    EndIf

    ; Store last move coordinates
    $g_f_LastMoveX = $a_f_X
    $g_f_LastMoveY = $a_f_Y

    ; Set move data
    DllStructSetData($g_d_Move, 2, $a_f_X)
    DllStructSetData($g_d_Move, 3, $a_f_Y)
    DllStructSetData($g_d_Move, 4, 0)  ; Z coordinate (usually 0)

    Core_Enqueue($g_p_Move, 16)

    Return True
EndFunc

Func Map_MoveLayer($a_f_X, $a_f_Y, $a_f_Layer = 0)
    ; Set move data
    DllStructSetData($g_d_Move, 2, $a_f_X)
    DllStructSetData($g_d_Move, 3, $a_f_Y)
    DllStructSetData($g_d_Move, 4, $a_f_Layer)  ; layer number

    Core_Enqueue($g_p_Move, 16)

    Return True
EndFunc

;~ Description: Internal use for map travel.
Func Map_MoveMap($a_i_MapID, $a_i_Region, $a_i_District, $a_i_Language)
    Return Core_SendPacket(0x18, $GC_I_HEADER_PARTY_TRAVEL, $a_i_MapID, $a_i_Region, $a_i_District, $a_i_Language, False)
EndFunc   ;==>MoveMap

;~ Description: Returns to outpost after resigning/failure.
Func Map_ReturnToOutpost($a_WaitToLoad = True)
	Map_InitMapIsLoaded()
    Core_SendPacket(0x4, $GC_I_HEADER_PARTY_RETURN_TO_OUTPOST)
	If $a_WaitToLoad Then Return Map_WaitMapIsLoaded()
EndFunc   ;==>ReturnToOutpost

;~ Description: Enter a challenge mission/pvp.
Func Map_EnterChallenge($a_WaitToLoad = True)
	Map_InitMapIsLoaded()
    Core_SendPacket(0x8, $GC_I_HEADER_PARTY_ENTER_CHALLENGE, 1)
	If $a_WaitToLoad Then Return Map_WaitMapIsLoaded()
EndFunc   ;==>EnterChallenge

;~ Description: Enter a foreign challenge mission/pvp.
;~ Func EnterChallengeForeign()
;~     Return Core_SendPacket(0x8, $GC_I_HEADER_PARTY_ENTER_FOREIGN_CHALLENGE, 0)
;~ EndFunc   ;==>EnterChallengeForeign

;~ Description: Travel to your guild hall.
Func Map_TravelGH($a_WaitToLoad = True)
    Local $l_ai_Offset[3] = [0, 0x18, 0x3C]
    Local $l_ap_GH = Memory_ReadPtr($g_p_BasePointer, $l_ai_Offset)

	Map_InitMapIsLoaded()
    Core_SendPacket(0x18, $GC_I_HEADER_PARTY_ENTER_GUILD_HALL, Memory_Read($l_ap_GH[1] + 0x64), Memory_Read($l_ap_GH[1] + 0x68), Memory_Read($l_ap_GH[1] + 0x6C), Memory_Read($l_ap_GH[1] + 0x70), 1)
    If $a_WaitToLoad Then Return Map_WaitMapIsLoaded()
EndFunc   ;==>TravelGH

;~ Description: Leave your guild hall.
Func Map_LeaveGH($a_WaitToLoad = True)
	Map_InitMapIsLoaded()
    Core_SendPacket(0x8, $GC_I_HEADER_PARTY_LEAVE_GUILD_HALL, 1)
    If $a_WaitToLoad Then Return Map_WaitMapIsLoaded()
EndFunc   ;==>LeaveGH

;~ Description: Map travel to an outpost.
Func Map_TravelTo($a_i_MapID, $a_i_Language = Map_GetCharacterInfo("Language"), $a_i_Region = Map_GetCharacterInfo("Region"), $a_i_District = 0, $a_WaitToLoad = True)
    If Map_GetCharacterInfo("MapID") = $a_i_MapID _
    And Map_GetInstanceInfo("IsOutpost") _
    And $a_i_Language = Map_GetCharacterInfo("Language") _
    And $a_i_Region = Map_GetCharacterInfo("Region") Then
        Return True
    EndIf
	Map_InitMapIsLoaded()
    Map_MoveMap($a_i_MapID, $a_i_Region, $a_i_District, $a_i_Language)
    If $a_WaitToLoad Then Return Map_WaitMapIsLoaded()
EndFunc   ;==>TravelTo

;~ Description: Travel to a map in a random district
;~ Modes: 0 = All, 1 = EU-only, 2 = US-only, 3 = Asia-only
Func Map_RndTravel($a_i_MapID, $a_WaitToLoad = True, $a_b_SwitchDistrict = True, $a_i_Mode = 0)
    Local Const $LC_AI_REGIONS[] = [2, 2, 2, 2, 2, 2, 2, 0, -2, 1, 3, 4]
    Local Const $LC_AI_LANGUAGES[] = [0, 2, 3, 4, 5, 9, 10, 0, 0, 0, 0, 0]

    Local $l_i_DistrictMin = 0, $l_i_DistrictMax = 11
    Switch $a_i_Mode
        Case 1 ; EU-only
            $l_i_DistrictMax = 6
        Case 2 ; US-only
            $l_i_DistrictMin = 7
            $l_i_DistrictMax = 8
        Case 3 ; Asia-only
            $l_i_DistrictMin = 9
    EndSwitch

    Local $l_i_ValidDistricts = $l_i_DistrictMax - $l_i_DistrictMin + 1

    Local $l_i_CurrentMap = Map_GetCharacterInfo("MapID")
    Local $l_i_CurrentRegion = Map_GetCharacterInfo("Region")
    Local $l_i_CurrentLanguage = Map_GetCharacterInfo("Language")

    If $l_i_CurrentMap <> $a_i_MapID Or Map_GetInstanceInfo("IsExplorable") Then
        Local $l_i_Idx = Random($l_i_DistrictMin, $l_i_DistrictMax, 1)
    Else
        If $a_b_SwitchDistrict Then
            If $l_i_ValidDistricts = 1 Then Return True
            Local $l_i_Idx = Random($l_i_DistrictMin, $l_i_DistrictMax, 1)
            If $LC_AI_REGIONS[$l_i_Idx] = $l_i_CurrentRegion And $LC_AI_LANGUAGES[$l_i_Idx] = $l_i_CurrentLanguage Then
                $l_i_Idx = Mod(($l_i_Idx - $l_i_DistrictMin) + 1, $l_i_ValidDistricts) + $l_i_DistrictMin
            EndIf
        Else
            Return True
        EndIf
    EndIf

    Map_InitMapIsLoaded()
    Map_MoveMap($a_i_MapID, $LC_AI_REGIONS[$l_i_Idx], 0, $LC_AI_LANGUAGES[$l_i_Idx])
    If $a_WaitToLoad Then Return Map_WaitMapIsLoaded()
EndFunc   ;==>Map_RndTravel

Func Map_WaitMapLoading($a_i_MapID = -1, $a_i_InstanceType = -1, $a_i_Timeout = 30000)
	Local $l_b_TimedOut = False, $l_h_Timeout = TimerInit()

    Do
        Sleep(250)
        If Game_GetGameInfo("IsCinematic") Then
            Cinematic_SkipCinematic()
            Sleep(1000)
        EndIf
        $l_b_TimedOut = (TimerDiff($l_h_Timeout) >= $a_i_Timeout)
    Until ( _
        Agent_GetAgentPtr(-2) <> 0 _
        And Agent_GetMaxAgents() <> 0 _
        And World_GetWorldInfo("SkillbarArray") <> 0 _
        And Party_GetPartyContextPtr() <> 0 _
        And ($a_i_InstanceType = -1 Or Map_GetInstanceInfo("Type") = $a_i_InstanceType) _
        And ($a_i_MapID = -1 Or Map_GetCharacterInfo("MapID") = $a_i_MapID) _
        And Not Game_GetGameInfo("IsCinematic") _
        And Other_GetPing() <> 0 _
    ) Or $l_b_TimedOut
	If $l_b_TimedOut Then Return False

    Sleep(250)

	Return True
EndFunc

Func Map_InitMapIsLoaded()
    Memory_Write($g_p_MapIsLoaded, 0)
EndFunc

Func Map_MapIsLoaded()
    If Memory_Read($g_p_MapIsLoaded) = 1 Then
        Memory_Write($g_p_MapIsLoaded, 0)
        Return True
    EndIf
    Return False
EndFunc

Func Map_WaitMapIsLoaded($a_i_Timeout = 30000)
    If Map_MapIsLoaded() Then Return True

    Local $l_b_TimedOut = False, $l_h_Timeout = TimerInit()
    Do
        Sleep(50)
        $l_b_TimedOut = (TimerDiff($l_h_Timeout) >= $a_i_Timeout)
    Until Map_MapIsLoaded() Or $l_b_TimedOut
    If $l_b_TimedOut Then Return False

    Sleep(500)

    Return True
EndFunc

Func Map_WaitMapIsLoaded_Ping($a_i_Timeout = 30000)
    If Memory_Read($g_p_MapIsLoaded) = 1 And Other_GetPing() <> 0 Then
        Map_InitMapIsLoaded()
        Return True
    EndIf

    Local $l_b_TimedOut = False, $l_h_Timeout = TimerInit()
    Do
        Sleep(50)
        $l_b_TimedOut = (TimerDiff($l_h_Timeout) >= $a_i_Timeout)
    Until (Memory_Read($g_p_MapIsLoaded) = 1 And Other_GetPing() <> 0) Or $l_b_TimedOut
    
    Map_InitMapIsLoaded()

    Return Not $l_b_TimedOut
EndFunc