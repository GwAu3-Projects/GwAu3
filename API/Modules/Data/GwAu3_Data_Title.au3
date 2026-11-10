#include-once

#Region Title Related
; Title structure size: 0x2C (44 bytes)
; Updated after GW client update - structure changed from 0x28
Func Title_GetTitleInfo($a_i_Title = 0, $a_s_Info = "")
    Local $l_p_Ptr = World_GetWorldInfo("TitleArray")
    Local $l_i_Size = World_GetWorldInfo("TitleArraySize")
    If $l_p_Ptr = 0 Or $a_i_Title < 0 Or $a_i_Title >= $l_i_Size Then Return 0

    $l_p_Ptr = $l_p_Ptr + ($a_i_Title * 0x2C)
    If $l_p_Ptr = 0 Or $a_s_Info = "" Then Return 0

    Switch $a_s_Info
        Case "Props"
            Return Memory_Read($l_p_Ptr, "dword")
        Case "CurrentPoints"
            Return Memory_Read($l_p_Ptr + 0x4, "dword")
        Case "CurrentTitleTierIndex", "CurrentTitleTier"
            Return Memory_Read($l_p_Ptr + 0x8, "dword")
        Case "PointsNeededCurrentRank"
            Return Memory_Read($l_p_Ptr + 0xC, "dword")
        Case "Unknown10" ; dhuum/reforged
            Return Memory_Read($l_p_Ptr + 0x10, "dword")
        Case "NextTitleTierIndex", "NextTitleTier"
            Return Memory_Read($l_p_Ptr + 0x14, "dword")
        Case "PointsNeededNextRank"
            Return Memory_Read($l_p_Ptr + 0x18, "dword")
        Case "MaxTitleRank"
            Return Memory_Read($l_p_Ptr + 0x1C, "dword")
        Case "MaxTitleTierIndex", "MaxTitleTier"
            Return Memory_Read($l_p_Ptr + 0x20, "dword")
		Case "PointsDescriptionEnc"
			Local $l_p_NamePtr = Memory_Read($l_p_Ptr + 0x24, "ptr")
            Return Utils_DecodeEncString($l_p_NamePtr)
		Case "PointsDescription" ; Points description (points/missions/elite skills...)
			Local $l_p_NamePtr = Memory_Read($l_p_Ptr + 0x24, "ptr")
            Return Utils_DecodeEncStringAsync($l_p_NamePtr)
		Case "TitleDescriptionEnc"
			Local $l_p_NamePtr = Memory_Read($l_p_Ptr + 0x28, "ptr")
            Return Utils_DecodeEncString($l_p_NamePtr)
		Case "TitleDescription"
			Local $l_p_NamePtr = Memory_Read($l_p_Ptr + 0x28, "ptr")
            Return Utils_DecodeEncStringAsync($l_p_NamePtr)
    EndSwitch

    Return 0
EndFunc
#EndRegion Title Related