#include-once

#Region Party Context
Func Party_GetPartyContextPtr()
    Local $l_ai_Offset[3] = [0, 0x18, 0x4C]
    Local $l_ap_PartyPtr = Memory_ReadPtr($g_p_BasePointer, $l_ai_Offset, 'ptr')
    Return $l_ap_PartyPtr[1]
EndFunc

Func Party_GetPartyContextInfo($a_s_Info = "")
    Local $l_p_Ptr = Party_GetPartyContextPtr()
    If $l_p_Ptr = 0 Or $a_s_Info = "" Then Return 0

    Switch $a_s_Info
        Case "Flags"
            Return Memory_Read($l_p_Ptr + 0x14, "long")
        Case "IsHardMode"
            Local $l_i_Flags = Memory_Read($l_p_Ptr + 0x14, "long")
            Return BitAND($l_i_Flags, 0x10) <> 0
        Case "IsDefeated"
            Local $l_i_Flags = Memory_Read($l_p_Ptr + 0x14, "long")
            Return BitAND($l_i_Flags, 0x20) <> 0
        Case "IsPartyLeader"
            Local $l_i_Flags = Memory_Read($l_p_Ptr + 0x14, "long")
            Return BitAND(BitShift($l_i_Flags, 7), 1) <> 0
        Case "IsWaitingForMission"
            Local $l_i_Flags = Memory_Read($l_p_Ptr + 0x14, "long")
            Return BitAND($l_i_Flags, 0x8) <> 0

        Case "InvitationRequestsCount"
            Return Memory_Read($l_p_Ptr + 0x28, "long")

        Case "InvitationSendingCount"
            Return Memory_Read($l_p_Ptr + 0x38, "long")

        Case "MyPartyPtr"
            Return Memory_Read($l_p_Ptr + 0x54, "ptr")

        Case "PlayerPartyID"
            Local $l_p_PartyPtr = Memory_Read($l_p_Ptr + 0x54, "ptr")
            Return Memory_Read($l_p_PartyPtr, "long")

        Case "PlayerCount"
            Local $l_p_PartyPtr = Memory_Read($l_p_Ptr + 0x54, "ptr")
            Return Memory_Read($l_p_PartyPtr + 0xC, "long")

        Case "HenchmenCount"
            Local $l_p_PartyPtr = Memory_Read($l_p_Ptr + 0x54, "ptr")
            Return Memory_Read($l_p_PartyPtr + 0x1C, "long")

        Case "HeroCount"
            Local $l_p_PartyPtr = Memory_Read($l_p_Ptr + 0x54, "ptr")
            Return Memory_Read($l_p_PartyPtr + 0x2C, "long")

        Case "OtherCount" ; Spirit, Minions, Pets (not the Spirits and Minions of heroes, only your character)
            Local $l_p_PartyPtr = Memory_Read($l_p_Ptr + 0x54, "ptr")
            Return Memory_Read($l_p_PartyPtr + 0x3C, "long")

        Case "TotalPartySize"
            Local $l_i_PlayerCount = Party_GetPartyContextInfo("PlayerCount")
            Local $l_i_HenchmenCount = Party_GetPartyContextInfo("HenchmenCount")
            Local $l_i_HeroCount = Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
            Return $l_i_PlayerCount + $l_i_HenchmenCount + $l_i_HeroCount

    EndSwitch
    Return 0
EndFunc

Func Party_GetMyPartyInfo($a_s_Info = "")
    Local $l_p_PartyPtr = Party_GetPartyContextInfo("MyPartyPtr")
    If $l_p_PartyPtr = 0 Or $a_s_Info = "" Then Return 0

    Switch $a_s_Info
        Case "PartyID"
            Return Memory_Read($l_p_PartyPtr, "long")
        Case "ArrayPlayerPartyMember"
            Return Memory_Read($l_p_PartyPtr + 0x4, "ptr")
        Case "ArrayPlayerPartyMemberSize"
            Return Memory_Read($l_p_PartyPtr + 0xC, "long")

        Case "ArrayHenchmanPartyMember"
            Return Memory_Read($l_p_PartyPtr + 0x14, "ptr")
        Case "ArrayHenchmanPartyMemberSize"
            Return Memory_Read($l_p_PartyPtr + 0x1C, "long")

        Case "ArrayHeroPartyMember"
            Return Memory_Read($l_p_PartyPtr + 0x24, "ptr")
        Case "ArrayHeroPartyMemberSize"
            Return Memory_Read($l_p_PartyPtr + 0x2C, "long")

        Case "ArrayOthersPartyMember"
            Return Memory_Read($l_p_PartyPtr + 0x34, "ptr")
        Case "ArrayOthersPartyMemberSize"
            Return Memory_Read($l_p_PartyPtr + 0x3C, "long")
    EndSwitch

    Return 0
EndFunc

Func Party_GetMyPartyPlayerMemberInfo($a_i_PartyMemberNumber = 1, $a_s_Info = "")
    Local $l_p_PlayerPartyPtr = Party_GetMyPartyInfo("ArrayPlayerPartyMember")
    Local $l_i_PlayerPartySize = Party_GetMyPartyInfo("ArrayPlayerPartyMemberSize")
    $a_i_PartyMemberNumber = $a_i_PartyMemberNumber - 1
    If $l_p_PlayerPartyPtr = 0 Or $a_i_PartyMemberNumber < 0 Or $a_i_PartyMemberNumber >= $l_i_PlayerPartySize Then Return 0

    Local $l_p_PlayerPtr = $l_p_PlayerPartyPtr + ($a_i_PartyMemberNumber * 0xC)
    If $l_p_PlayerPtr = 0 Or $a_s_Info = "" Then Return 0

    Switch $a_s_Info
        Case "LoginNumber"
            Return Memory_Read($l_p_PlayerPtr, "long")

        Case "CalledTargetID"
            Return Memory_Read($l_p_PlayerPtr + 0x4, "long")

        Case "State"
            Return Memory_Read($l_p_PlayerPtr + 0x8, "long")

        Case "IsConnected"
            Local $l_i_State = Memory_Read($l_p_PlayerPtr + 0x8, "long")
            Return BitAND($l_i_State, 1) <> 0

        Case "IsTicked"
            Local $l_i_State = Memory_Read($l_p_PlayerPtr + 0x8, "long")
            Return BitAND($l_i_State, 2) <> 0
    EndSwitch

    Return 0
EndFunc

Func Party_GetMyPartyHeroInfo($a_i_HeroNumber = 1, $a_s_Info = "", $a_b_IncludeOtherHeroPlayers = False)
    Local $l_p_PlayerPartyPtr = Party_GetMyPartyInfo("ArrayHeroPartyMember")
    Local $l_i_PlayerPartySize = Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")

    If $l_p_PlayerPartyPtr = 0 Or $a_i_HeroNumber < 1 Or $a_i_HeroNumber > $l_i_PlayerPartySize Then Return 0

    If $a_b_IncludeOtherHeroPlayers Then
        $a_i_HeroNumber = $a_i_HeroNumber - 1
        Local $l_p_HeroPtr = $l_p_PlayerPartyPtr + ($a_i_HeroNumber * 0x18)
    Else
        Local $l_i_PlayerNumber = Map_GetCharacterInfo("PlayerNumber")
        Local $l_i_MatchedCount = 0
        Local $l_p_HeroPtr = 0
        If $l_i_PlayerNumber = 0 Then Return 0

        For $l_i_Idx = 0 To $l_i_PlayerPartySize - 1
            Local $l_p_CurrentHeroPtr = $l_p_PlayerPartyPtr + ($l_i_Idx * 0x18)
            Local $l_i_OwnerPlayerNumber = Memory_Read($l_p_CurrentHeroPtr + 0x4, "long")

            If $l_i_OwnerPlayerNumber = $l_i_PlayerNumber Then
                $l_i_MatchedCount += 1
                If $l_i_MatchedCount = $a_i_HeroNumber Then
                    $l_p_HeroPtr = $l_p_CurrentHeroPtr
                    ExitLoop
                EndIf
            EndIf
        Next

        If $l_p_HeroPtr = 0 Then Return 0
    EndIf

    Switch $a_s_Info
        Case "AgentID"
            Return Memory_Read($l_p_HeroPtr, "long")
        Case "OwnerPlayerNumber"
            If Not $a_b_IncludeOtherHeroPlayers Then Return $l_i_OwnerPlayerNumber
            Return Memory_Read($l_p_HeroPtr + 0x4, "long")
        Case "HeroID"
            Return Memory_Read($l_p_HeroPtr + 0x8, "long")
        Case "Level"
            Return Memory_Read($l_p_HeroPtr + 0x14, "long")
        Case Else
            Return 0
    EndSwitch
EndFunc   ;==>GetMyPartyHeroInfo

Func Party_GetMyPartyHenchmanInfo($a_i_HenchmanNumber = 1, $a_s_Info = "")
    Local $l_p_PlayerPartyPtr = Party_GetMyPartyInfo("ArrayHenchmanPartyMember")
    Local $l_i_PlayerPartySize = Party_GetMyPartyInfo("ArrayHenchmanPartyMemberSize")
    $a_i_HenchmanNumber = $a_i_HenchmanNumber - 1
    If $l_p_PlayerPartyPtr = 0 Or $a_i_HenchmanNumber < 0 Or $a_i_HenchmanNumber >= $l_i_PlayerPartySize Then Return 0

    Local $l_p_HenchmanPtr = $l_p_PlayerPartyPtr + ($a_i_HenchmanNumber * 0x34)
    If $l_p_HenchmanPtr = 0 Or $a_s_Info = "" Then Return 0

    Switch $a_s_Info
        Case "AgentID"
            Return Memory_Read($l_p_HenchmanPtr, "long")

        Case "Profession"
            Return Memory_Read($l_p_HenchmanPtr + 0x2C, "long")

        Case "Level"
            Return Memory_Read($l_p_HenchmanPtr + 0x30, "long")
    EndSwitch

    Return 0
EndFunc
#EndRegion Party Context

#Region Party Morale Related
Func Party_GetMoraleInfo($a_v_AgentID = -2, $a_s_Info = "")
    Local $l_i_AgentID = Agent_ConvertID($a_v_AgentID)

    Local $l_ai_Offset[4] = [0, 0x18, 0x2C, 0x638]
    Local $l_ai_Index = Memory_ReadPtr($g_p_BasePointer, $l_ai_Offset)

    ReDim $l_ai_Offset[6]
    $l_ai_Offset[3] = 0x62C
    $l_ai_Offset[4] = 8 + 0xC * BitAND($l_i_AgentID, $l_ai_Index[1])
    $l_ai_Offset[5] = 0x18
    Local $l_av_Return = Memory_ReadPtr($g_p_BasePointer, $l_ai_Offset)

    If Not IsArray($l_av_Return) Or $l_av_Return[0] = 0 Then Return 0

    Switch $a_s_Info
        Case "Morale"
            Return $l_av_Return[1] - 100
        Case "RawMorale"
            Return $l_av_Return[1]
        Case "IsMaxMorale"
            Return ($l_av_Return[1] >= 110)
        Case "IsMinMorale"
            Return ($l_av_Return[1] <= 40)
        Case "IsMoraleBoost"
            Return ($l_av_Return[1] > 100)
        Case "IsMoralePenalty"
            Return ($l_av_Return[1] < 100)
        Case Else
            Return 0
    EndSwitch
EndFunc

#EndRegion  Party Morale Related

#Region Party Profession Related
Func Party_GetPartyProfessionInfo($a_v_AgentID = 0, $a_s_Info = "")
    Local $l_p_Ptr = World_GetWorldInfo("PartyProfessionArray")
    Local $l_i_Size = World_GetWorldInfo("PartyProfessionArraySize")
    Local $l_p_AgentPtr = 0

    For $l_i_Idx = 0 To $l_i_Size
        Local $l_p_AgentEffectsPtr = $l_p_Ptr + ($l_i_Idx * 0x14)
        If Memory_Read($l_p_AgentEffectsPtr, "dword") = Agent_ConvertID($a_v_AgentID) Then
            $l_p_AgentPtr = $l_p_AgentEffectsPtr
            ExitLoop
        EndIf
    Next

    If $l_p_AgentPtr = 0 Then Return 0

    Switch $a_s_Info
        Case "AgentID"
            Return Memory_Read($l_p_AgentPtr, "dword")
        Case "Primary"
            Return Memory_Read($l_p_AgentPtr + 0x4, "dword")
        Case "Secondary"
            Return Memory_Read($l_p_AgentPtr + 0x8, "dword")
        Case Else
            Return 0
    EndSwitch
EndFunc

#EndRegion  Party Profession Related

#Region Pet Related
Func Party_GetPetInfo($a_i_PetNumber = 1, $a_s_Info = "")
    Local $l_p_PetPtr = World_GetWorldInfo("PetInfoArray")
    Local $l_i_PetSize = World_GetWorldInfo("PetInfoArraySize")
    $a_i_PetNumber = $a_i_PetNumber - 1
    If $l_p_PetPtr = 0 Or $a_i_PetNumber < 0 Or $a_i_PetNumber >= $l_i_PetSize Then Return 0

    $l_p_PetPtr = $l_p_PetPtr + ($a_i_PetNumber * 0x1C)
    If $l_p_PetPtr = 0 Or $a_s_Info = "" Then Return 0

    Switch $a_s_Info
        Case "AgentID"
            Return Memory_Read($l_p_PetPtr, "dword")
        Case "OwnerAgentID"
            Return Memory_Read($l_p_PetPtr + 0x4, "dword")
        Case "PetNamePtr"
            Return Memory_Read($l_p_PetPtr + 0x8, "ptr")
        Case "PetNameEnc"
            Local $l_p_NamePtr = Memory_Read($l_p_PetPtr + 0x8, "ptr")
            If $l_p_NamePtr <= 0x10000 Then Return ""
            Return Utils_DecodeEncString($l_p_NamePtr)
        Case "PetName"
            Local $l_p_NamePtr = Memory_Read($l_p_PetPtr + 0x8, "ptr")
            If $l_p_NamePtr <= 0x10000 Then Return "Unknown"
            Return Utils_DecodeEncStringAsync($l_p_NamePtr)
        Case "ModelFileID1"
            Return Memory_Read($l_p_PetPtr + 0xC, "dword")
        Case "ModelFileID2"
            Return Memory_Read($l_p_PetPtr + 0x10, "dword")
        Case "Behavior"
            Return Memory_Read($l_p_PetPtr + 0x14, "dword")
        Case "LockedTargetID"
            Return Memory_Read($l_p_PetPtr + 0x18, "dword")
        Case "IsFighting"
            Return Memory_Read($l_p_PetPtr + 0x14, "dword") = 0
        Case "IsGuarding"
            Return Memory_Read($l_p_PetPtr + 0x14, "dword") = 1
        Case "IsAvoiding"
            Return Memory_Read($l_p_PetPtr + 0x14, "dword") = 2
        Case "HasLockedTarget"
            Return Memory_Read($l_p_PetPtr + 0x18, "dword") <> 0
        Case Else
            Return 0
    EndSwitch
EndFunc

;~ Description: Whether an agent is a charmed pet.
Func Party_IsPet($a_v_AgentID)
    Return Party_GetPetNumberByAgentID($a_v_AgentID) <> 0
EndFunc

;~ Description: The 1-based pet number for an agent, or 0 if that agent is not a pet.
Func Party_GetPetNumberByAgentID($a_v_AgentID)
    Local $l_i_AgentID = Agent_ConvertID($a_v_AgentID)
    If $l_i_AgentID = 0 Then Return 0

    Local $l_i_Count = World_GetWorldInfo("PetInfoArraySize")
    If $l_i_Count <= 0 Then Return 0

    For $i = 1 To $l_i_Count
        If Party_GetPetInfo($i, "AgentID") = $l_i_AgentID Then Return $i
    Next
    Return 0
EndFunc

;~ Description: The owner of a pet agent, or 0 if that agent is not a pet.
Func Party_GetPetOwnerByAgentID($a_v_AgentID)
    Local $l_i_Number = Party_GetPetNumberByAgentID($a_v_AgentID)
    If $l_i_Number = 0 Then Return 0
    Return Party_GetPetInfo($l_i_Number, "OwnerAgentID")
EndFunc
#EndRegion Pet Related

#Region Controlled Minion Related
Func Party_GetControlledMinionsInfo($a_v_AgentID = 0, $a_s_Info = "")
    Local $l_p_Ptr = World_GetWorldInfo("ControlledMinionsArray")
    Local $l_i_Size = World_GetWorldInfo("ControlledMinionsArraySize")
    Local $l_p_AgentPtr = 0

    For $l_i_Idx = 0 To $l_i_Size
        Local $l_p_AgentEffectsPtr = $l_p_Ptr + ($l_i_Idx * 0x8)
        If Memory_Read($l_p_AgentEffectsPtr, "dword") = Agent_ConvertID($a_v_AgentID) Then
            $l_p_AgentPtr = $l_p_AgentEffectsPtr
            ExitLoop
        EndIf
    Next

    If $l_p_AgentPtr = 0 Then Return 0

    Switch $a_s_Info
        Case "AgentID"
            Return Memory_Read($l_p_AgentPtr, "dword")
        Case "MinionCount"
            Return Memory_Read($l_p_AgentPtr + 0x4, "dword")
        Case Else
            Return 0
    EndSwitch
EndFunc

#EndRegion

#Region Hero Related
Func Party_GetHeroFlagInfo($a_i_HeroNumber = 1, $a_s_Info = "")
    Local $l_p_Ptr = World_GetWorldInfo("HeroFlagArray")
    Local $l_i_Size = World_GetWorldInfo("HeroFlagArraySize")
    If $l_p_Ptr = 0 Or $a_i_HeroNumber < 1 Or $a_i_HeroNumber > $l_i_Size Then Return 0

    Local $l_i_HeroID = Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID")
    If $l_i_HeroID = 0 Then Return 0

    Local $l_i_ReadHeroID, $l_p_HeroFlagPtr
    For $l_i_Idx = 0 To $l_i_Size - 1
        $l_p_HeroFlagPtr = $l_p_Ptr + (0x24 * $l_i_Idx)
        $l_i_ReadHeroID = Memory_Read($l_p_HeroFlagPtr + 0x4, "dword")
        If $l_p_HeroFlagPtr <> 0 And $l_i_ReadHeroID = $l_i_HeroID Then ExitLoop
    Next
    If $l_p_HeroFlagPtr = 0 Or $l_i_ReadHeroID <> $l_i_HeroID Then Return 0

    Switch $a_s_Info
        Case "HeroID"
            Return Memory_Read($l_p_HeroFlagPtr, "dword")
        Case "AgentID"
            Return Memory_Read($l_p_HeroFlagPtr + 0x4, "dword")
        Case "InventoryID"
            Return Memory_Read($l_p_HeroFlagPtr + 0x8, "dword")
        Case "Behavior"
            Return Memory_Read($l_p_HeroFlagPtr + 0xC, "dword")
        Case "FlagX"
            Return Memory_Read($l_p_HeroFlagPtr + 0x10, "float")
        Case "FlagY"
            Return Memory_Read($l_p_HeroFlagPtr + 0x14, "float")
        Case "LockedTargetID"
            Return Memory_Read($l_p_HeroFlagPtr + 0x20, "dword")
    EndSwitch

    Return 0
EndFunc

Func Party_GetHeroInfo($a_i_HeroNumber = 1, $a_s_Info = "")
    Local $l_p_Ptr = World_GetWorldInfo("HeroInfoArray")
    Local $l_i_Size = World_GetWorldInfo("HeroInfoArraySize")
    If $l_p_Ptr = 0 Or $a_i_HeroNumber < 1 Or $a_i_HeroNumber >= $l_i_Size Then Return 0

    Local $l_i_HeroID = Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID")
    If $l_i_HeroID = 0 Then Return 0

    Local $l_i_ReadHeroID, $l_p_HeroPtr
    For $l_i_Idx = 0 To $l_i_Size - 1
        $l_p_HeroPtr = $l_p_Ptr + (0x9C * $l_i_Idx)
        $l_i_ReadHeroID = Memory_Read($l_p_HeroPtr + 0x4, "dword")
        If $l_p_HeroPtr <> 0 And $l_i_ReadHeroID = $l_i_HeroID Then ExitLoop
    Next
    If $l_p_HeroPtr = 0 Or $l_i_ReadHeroID <> $l_i_HeroID Then Return 0

    Switch $a_s_Info
        Case "HeroID"
            Return Memory_Read($l_p_HeroPtr, "dword")
        Case "AgentID"
            Return Memory_Read($l_p_HeroPtr + 0x4, "dword")
        Case "Level"
            Return Memory_Read($l_p_HeroPtr + 0x8, "dword")
        Case "Primary"
            Return Memory_Read($l_p_HeroPtr + 0xC, "dword")
        Case "Secondary"
            Return Memory_Read($l_p_HeroPtr + 0x10, "dword")
        Case "HeroFileID"
            Return Memory_Read($l_p_HeroPtr + 0x14, "dword")
        Case "ModelFileID"
            Return Memory_Read($l_p_HeroPtr + 0x18, "dword")
		Case "Name"
			Local $lHeroID = Memory_Read($l_p_HeroPtr, "dword")
			If $lHeroID >= 28 And $lHeroID <= 35 Then
				Local $l_s_Name = Memory_Read($l_p_HeroPtr + 0x74, "wchar[20]")
				If $l_s_Name <> "" Then Return $l_s_Name
			EndIf
			Return $GC_AM2_HERO_DATA[$lHeroID][1]
    EndSwitch

    Return 0
EndFunc
#EndRegion Hero Related

; Get the AgentID of a party member by their position in the party window (1-based index)
; $aPartyMember: The position of the party member (1 = first member, 2 = second, etc.)
; Returns: The AgentID of the party member at the specified position, or 0 if not found
Func Party_GetMemberAgentID($aPartyMember)
    If $aPartyMember < 1 Then Return 0

    Local $lCurrentPosition = 0
    Local $lAgentID = 0

    ; Step 1: Iterate through all players first
    Local $lPlayerCount = Party_GetMyPartyInfo("ArrayPlayerPartyMemberSize")
    If $lPlayerCount > 0 Then
        For $i = 1 To $lPlayerCount
            $lCurrentPosition += 1

            If $lCurrentPosition = $aPartyMember Then
                ; Get the LoginNumber for this player position
                Local $lLoginNumber = Party_GetMyPartyPlayerMemberInfo($i, "LoginNumber")
                If $lLoginNumber = 0 Then Return 0

                ; Check if this is us
                Local $lMyLoginNumber = Agent_GetAgentInfo(-2, "LoginNumber")
                If $lLoginNumber = $lMyLoginNumber Then
                    Return Agent_GetMyID()
                EndIf

                ; Find the agent with this LoginNumber
                Local $lAgentArray = Agent_GetAgentArray(0xDB) ; Living agents
                If IsArray($lAgentArray) And $lAgentArray[0] > 0 Then
                    For $j = 1 To $lAgentArray[0]
                        If Agent_GetAgentInfo($lAgentArray[$j], "LoginNumber") = $lLoginNumber Then
                            Return Agent_GetAgentInfo($lAgentArray[$j], "ID")
                        EndIf
                    Next
                EndIf
                Return 0
            EndIf
        Next
    EndIf

    ; Step 2: Iterate through all heroes (including heroes from other players)
    Local $lHeroCount = Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
    If $lHeroCount > 0 Then
        For $i = 1 To $lHeroCount
            $lCurrentPosition += 1

            If $lCurrentPosition = $aPartyMember Then
                $lAgentID = Party_GetMyPartyHeroInfo($i, "AgentID", True) ; True = include other players' heroes
                Return $lAgentID
            EndIf
        Next
    EndIf

    ; Step 3: Iterate through all henchmen
    Local $lHenchmanCount = Party_GetMyPartyInfo("ArrayHenchmanPartyMemberSize")
    If $lHenchmanCount > 0 Then
        For $i = 1 To $lHenchmanCount
            $lCurrentPosition += 1

            If $lCurrentPosition = $aPartyMember Then
                $lAgentID = Party_GetMyPartyHenchmanInfo($i, "AgentID")
                Return $lAgentID
            EndIf
        Next
    EndIf

    Return 0 ; Member not found
EndFunc
