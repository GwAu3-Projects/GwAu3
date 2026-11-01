#include-once

Func Friend_GetMyStatus()
    Return Memory_Read($g_p_FriendList + 0xA0, 'dword')
EndFunc

Func Friend_GetFriendListPtr()
    Return $g_p_FriendList
EndFunc

Func Friend_GetFriendListInfo($a_s_Info = "")
    Local $l_p_Ptr = Friend_GetFriendListPtr()
    If $l_p_Ptr = 0 Or $a_s_Info = "" Then Return 0

    Switch $a_s_Info
        Case "NumberOfFriend"
            Return Memory_Read($l_p_Ptr + 0x24, "dword")
        Case "NumberOfIgnore"
            Return Memory_Read($l_p_Ptr + 0x28, "dword")
        Case "NumberOfPartner"
            Return Memory_Read($l_p_Ptr + 0x2C, "dword")
        Case "NumberOfTrade"
            Return Memory_Read($l_p_Ptr + 0x30, "dword")
        Case "PlayerStatus"
            Return Memory_Read($l_p_Ptr + 0xA0, "dword")
    EndSwitch

    Return 0
EndFunc

Func Friend_GetFriendInfo($a_v_FriendIdentifier = "", $a_s_Info = "")
    If $a_v_FriendIdentifier = "" Or $a_s_Info = "" Then Return 0

    Local $l_p_FriendPtr = 0
    Local $l_i_FriendNumber = 0

    Local $l_i_TotalFriends = Memory_Read($g_p_FriendList + 0x24, "dword") + _  ; Friends
                              Memory_Read($g_p_FriendList + 0x28, "dword") + _  ; Ignores
                              Memory_Read($g_p_FriendList + 0x2C, "dword") + _  ; Partners
                              Memory_Read($g_p_FriendList + 0x30, "dword")      ; Traders

    ; By friend number or Friend Name
    If IsNumber($a_v_FriendIdentifier) Then
        $l_i_FriendNumber = $a_v_FriendIdentifier
        If $l_i_FriendNumber < 1 Or $l_i_FriendNumber > $l_i_TotalFriends Then Return 0

        Local $l_ai_Offset[3] = [0, 0x4 * $l_i_FriendNumber, 0]
        Local $l_av_Result = Memory_ReadPtr($g_p_FriendList, $l_ai_Offset, "ptr")
        $l_p_FriendPtr = $l_av_Result[0]
    Else
        ; Find by name
        For $l_i_Idx = 1 To $l_i_TotalFriends
            Local $l_ai_Offset[3] = [0, 0x4 * $l_i_Idx, 0x40]
            Local $l_av_NameResult = Memory_ReadPtr($g_p_FriendList, $l_ai_Offset, 'WCHAR[20]')
            If $l_av_NameResult[1] = $a_v_FriendIdentifier Then
                $l_i_FriendNumber = $l_i_Idx
                $l_p_FriendPtr = $l_av_NameResult[0] - 0x40
                ExitLoop
            EndIf
        Next

        ; Find by alias
        If $l_p_FriendPtr = 0 Then
            For $l_i_Idx = 1 To $l_i_TotalFriends
                Local $l_ai_Offset[3] = [0, 0x4 * $l_i_Idx, 0x18]
                Local $l_av_NameResult = Memory_ReadPtr($g_p_FriendList, $l_ai_Offset, 'WCHAR[20]')
                If $l_av_NameResult[1] = $a_v_FriendIdentifier Then
                    $l_i_FriendNumber = $l_i_Idx
                    $l_p_FriendPtr = $l_av_NameResult[0] - 0x18
                    ExitLoop
                EndIf
            Next
        EndIf
    EndIf

    Switch $a_s_Info
        Case "Type", "FriendType"
            Return Memory_Read($l_p_FriendPtr + 0x0, "dword")

        Case "Status", "FriendStatus"
            Return Memory_Read($l_p_FriendPtr + 0x4, "dword")

        Case "UUID"
            Local $l_s_UUID = ""
            For $l_i_Idx = 0 To 15
                $l_s_UUID &= Hex(Memory_Read($l_p_FriendPtr + 0x8 + $l_i_Idx, 'byte'), 2)
            Next
            Return Binary("0x" & $l_s_UUID)

        Case "Name", "Alias"
            Return Memory_Read($l_p_FriendPtr + 0x18, 'wchar[20]')

        Case "ConnectedName", "CharName", "Playing"
            Return Memory_Read($l_p_FriendPtr + 0x40, 'wchar[20]')

        Case "FriendID"
            Return Memory_Read($l_p_FriendPtr + 0x68, "dword")

        Case "MapID", "ZoneID"
            Return Memory_Read($l_p_FriendPtr + 0x6C, "dword")

        Case "TypeName"
            Local $l_i_Type = Memory_Read($l_p_FriendPtr + 0x0, "dword")
            Return Friend_GetFriendTypeName($l_i_Type)

        Case "StatusName"
            Local $l_i_Status = Memory_Read($l_p_FriendPtr + 0x4, "dword")
            Return Friend_GetFriendStatusName($l_i_Status)

        Case "IsOnline"
            Return Memory_Read($l_p_FriendPtr + 0x4, "dword") = $GC_I_FRIEND_STATUS_ONLINE

        Case "IsOffline"
            Return Memory_Read($l_p_FriendPtr + 0x4, "dword") = $GC_I_FRIEND_STATUS_OFFLINE

        Case "IsFriend"
            Return Memory_Read($l_p_FriendPtr + 0x0, "dword") = $GC_I_FRIEND_TYPE_FRIEND

        Case "IsIgnored"
            Return Memory_Read($l_p_FriendPtr + 0x0, "dword") = $GC_I_FRIEND_TYPE_IGNORE

        Case "Number", "Index"
            Return $l_i_FriendNumber

        Case "Ptr"
            Return $l_p_FriendPtr

        Case Else
            Return 0
    EndSwitch
EndFunc

Func Friend_IsFriend($a_s_CharacterName)
    Local $l_p_FriendPtr = Friend_GetFriendInfo($a_s_CharacterName, "Ptr")
    If $l_p_FriendPtr = 0 Then Return False

    Return Friend_GetFriendInfo($a_s_CharacterName, "Type") = $GC_I_FRIEND_TYPE_FRIEND
EndFunc

Func Friend_IsIgnored($a_s_CharacterName)
    Local $l_p_FriendPtr = Friend_GetFriendInfo($a_s_CharacterName, "Ptr")
    If $l_p_FriendPtr = 0 Then Return False

    Return Friend_GetFriendInfo($a_s_CharacterName, "Type") = $GC_I_FRIEND_TYPE_IGNORE
EndFunc

Func Friend_GetFriendStatusName($a_i_FriendStatus)
    Switch $a_i_FriendStatus
        Case $GC_I_FRIEND_STATUS_OFFLINE
            Return "Offline"
        Case $GC_I_FRIEND_STATUS_ONLINE
            Return "Online"
        Case $GC_I_FRIEND_STATUS_DND
            Return "Do Not Disturb"
        Case $GC_I_FRIEND_STATUS_AWAY
            Return "Away"
        Case Else
            Return "Unknown"
    EndSwitch
EndFunc

Func Friend_GetFriendTypeName($a_i_FriendType)
    Switch $a_i_FriendType
        Case $GC_I_FRIEND_TYPE_FRIEND
            Return "Friend"
        Case $GC_I_FRIEND_TYPE_IGNORE
            Return "Ignore"
        Case $GC_I_FRIEND_TYPE_PLAYER
            Return "Player"
        Case $GC_I_FRIEND_TYPE_TRADE
            Return "Trade"
        Case Else
            Return "Unknown"
    EndSwitch
EndFunc
