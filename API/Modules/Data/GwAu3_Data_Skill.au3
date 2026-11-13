#include-once

Func Skill_GetLastUsedSkill()
    Return $g_i_LastSkillUsed
EndFunc

Func Skill_GetLastTarget()
    Return $g_i_LastSkillTarget
EndFunc

Func Skill_GetSkillTimer()
    Local $l_i_TickCount = DllCall($g_h_Kernel32, 'dword', 'GetTickCount')[0]
    Return BitAND($l_i_TickCount + $g_i_GWExeStart, 0xFFFFFFFF)
EndFunc

Func Skill_GetSkillPtr($a_v_SkillID)
    If IsPtr($a_v_SkillID) Then Return $a_v_SkillID
    Local $l_p_SkillPtr = $g_p_SkillBase + 0xA4 * $a_v_SkillID
    Return Ptr($l_p_SkillPtr)
EndFunc

Func Skill_GetSkillInfo($a_v_SkillID, $a_s_Info = "")
    Local $l_p_Ptr = Skill_GetSkillPtr($a_v_SkillID)
    If $l_p_Ptr = 0 Or $a_s_Info = "" Then Return 0

    Switch $a_s_Info
        Case "SkillID"
            Return Memory_Read($l_p_Ptr, "long")
        Case "h0004", "GwVersion" ;Skill available from the gw version
            Return Memory_Read($l_p_Ptr + 0x4, "long")
        Case "Campaign"
            Return Memory_Read($l_p_Ptr + 0x8, "long")
        Case "SkillType"
            Return Memory_Read($l_p_Ptr + 0xC, "long")
        Case "Special"
            Return Memory_Read($l_p_Ptr + 0x10, "long")
        Case "ComboReq"
            Return Memory_Read($l_p_Ptr + 0x14, "long")
        Case "Effect1", "InflictsCondition"
            Return Memory_Read($l_p_Ptr + 0x18, "long")
        Case "Condition", "RequireCondition"
            Return Memory_Read($l_p_Ptr + 0x1C, "long")
        Case "Effect2", "EffectFlag"
            Return Memory_Read($l_p_Ptr + 0x20, "long")
        Case "WeaponReq"
            Return Memory_Read($l_p_Ptr + 0x24, "long")
        Case "Profession"
            Return Memory_Read($l_p_Ptr + 0x28, "byte")
        Case "Attribute"
            Return Memory_Read($l_p_Ptr + 0x29, "byte")
        Case "Title"
            Return Memory_Read($l_p_Ptr + 0x2A, "word")
        Case "SkillIDPvP"
            Return Memory_Read($l_p_Ptr + 0x2C, "long")
        Case "Combo"
            Return Memory_Read($l_p_Ptr + 0x30, "byte")
        Case "Target"
            Return Memory_Read($l_p_Ptr + 0x31, "byte")
        Case "h0032" ;Seems related to melee
            Return Memory_Read($l_p_Ptr + 0x32, "byte")
        Case "SkillEquipType"
            Return Memory_Read($l_p_Ptr + 0x33, "byte")
        Case "Overcast"
            Local $l_i_OverCast = Memory_Read($l_p_Ptr + 0x34, "byte")

			Switch $l_i_OverCast
				Case 5
					Return 5
				Case 10
					Return 10
				Case Else
					Return 0
			EndSwitch
        Case "EnergyCost"
            Local $l_i_EnergyCost = Memory_Read($l_p_Ptr + 0x35, "byte")

            Switch $l_i_EnergyCost
                Case 11
                    Return 15
                Case 12
                    Return 25
                Case Else
                    Return $l_i_EnergyCost
            EndSwitch
        Case "HealthCost"
            Return Memory_Read($l_p_Ptr + 0x36, "byte")
        Case "h0037" ;Always 0
            Return Memory_Read($l_p_Ptr + 0x37, "byte")
        Case "Adrenaline"
            Return Memory_Read($l_p_Ptr + 0x38, "dword")
        Case "Activation"
            Return Memory_Read($l_p_Ptr + 0x3C, "float")
        Case "Aftercast"
            Return Memory_Read($l_p_Ptr + 0x40, "float")
        Case "Duration0"
            Return Memory_Read($l_p_Ptr + 0x44, "dword")
        Case "Duration15"
            Return Memory_Read($l_p_Ptr + 0x48, "dword")
        Case "Recharge"
            Return Memory_Read($l_p_Ptr + 0x4C, "dword")
        Case "h0050" ;Weapons Animation Type ID ?
            Return Memory_Read($l_p_Ptr + 0x50, "word")
        Case "h0052" ;Variant Weapons Animation Type ID ?
            Return Memory_Read($l_p_Ptr + 0x52, "word")
        Case "h0054" ;Weapons Animation Template ?
            Return Memory_Read($l_p_Ptr + 0x54, "word")
        Case "h0056" ;Variant Weapons Animation Template ?
            Return Memory_Read($l_p_Ptr + 0x56, "word")
        Case "SkillArguments"
            Return Memory_Read($l_p_Ptr + 0x58, "dword")
        Case "Scale0"
            Return Memory_Read($l_p_Ptr + 0x5C, "dword")
        Case "Scale15"
            Return Memory_Read($l_p_Ptr + 0x60, "dword")
        Case "BonusScale0"
            Return Memory_Read($l_p_Ptr + 0x64, "dword")
        Case "BonusScale15"
            Return Memory_Read($l_p_Ptr + 0x68, "dword")
        Case "AoeRange", "EffectConstant1"
            Return Memory_Read($l_p_Ptr + 0x6C, "float")
        Case "ConstEffect", "EffectConstant2"
            Return Memory_Read($l_p_Ptr + 0x70, "float")
        Case "CasterOverheadAnimationID"
            Return Memory_Read($l_p_Ptr + 0x74, "dword")
        Case "CasterBodyAnimationID"
            Return Memory_Read($l_p_Ptr + 0x78, "dword")
        Case "TargetBodyAnimationID"
            Return Memory_Read($l_p_Ptr + 0x7C, "dword")
        Case "TargetOverheadAnimationID"
            Return Memory_Read($l_p_Ptr + 0x80, "dword")
        Case "ProjectileAnimation1ID"
            Return Memory_Read($l_p_Ptr + 0x84, "dword")
        Case "ProjectileAnimation2ID"
            Return Memory_Read($l_p_Ptr + 0x88, "dword")
        Case "IconFileID"
            Return Memory_Read($l_p_Ptr + 0x8C, "dword")
        Case "IconFileID2"
            Return Memory_Read($l_p_Ptr + 0x90, "dword")
		Case "IconFileIDHD"
            Return Memory_Read($l_p_Ptr + 0x94, "dword")

        ; String IDs (uint32) - use these for raw IDs
        Case "SkillNameID", "NameID"
            Return Memory_Read($l_p_Ptr + 0x98, "dword")
        Case "ConciseID"
            Return Memory_Read($l_p_Ptr + 0x9C, "dword")
        Case "DescriptionID"
            Return Memory_Read($l_p_Ptr + 0xA0, "dword")

        Case "SkillName"
            Local $l_i_StringID = Memory_Read($l_p_Ptr + 0x98, "dword")
            Return Utils_DecodeStringID($l_i_StringID)
        Case "Concise"
            Local $l_i_StringID = Memory_Read($l_p_Ptr + 0x9C, "dword")
            Return Utils_DecodeStringID($l_i_StringID)
        Case "Description"
            Local $l_i_StringID = Memory_Read($l_p_Ptr + 0xA0, "dword")
            Return Utils_DecodeStringID($l_i_StringID)

        Case "CompleteConcise"
            Local $l_i_StringID = Memory_Read($l_p_Ptr + 0x9C, "dword")
            Local $l_s_Text = Utils_SkillDecodeStringID($l_i_StringID)
            Return _Skill_ReplaceScalePlaceholders($l_p_Ptr, $l_s_Text)

        Case "CompleteDescription"
            Local $l_i_StringID = Memory_Read($l_p_Ptr + 0xA0, "dword")
            Local $l_s_Text = Utils_SkillDecodeStringID($l_i_StringID)
            Return _Skill_ReplaceScalePlaceholders($l_p_Ptr, $l_s_Text)
    EndSwitch

    Return 0
EndFunc

; Helper function to convert scale values - detects if fixed-point or direct value
Func _Skill_ConvertScaleValue($a_i_RawValue)
    If $a_i_RawValue > 65536 Then
        Return Floor($a_i_RawValue / 65536)
    EndIf
    Return $a_i_RawValue
EndFunc

; Helper function to replace scale placeholders in skill descriptions
Func _Skill_ReplaceScalePlaceholders($a_p_SkillPtr, $a_s_Text)
    If $a_s_Text = "" Then Return ""

    ; Read scale values from skill struct
    Local $l_i_Scale0 = _Skill_ConvertScaleValue(Memory_Read($a_p_SkillPtr + 0x5C, "dword"))
    Local $l_i_Scale15 = _Skill_ConvertScaleValue(Memory_Read($a_p_SkillPtr + 0x60, "dword"))
    Local $l_i_BonusScale0 = _Skill_ConvertScaleValue(Memory_Read($a_p_SkillPtr + 0x64, "dword"))
    Local $l_i_BonusScale15 = _Skill_ConvertScaleValue(Memory_Read($a_p_SkillPtr + 0x68, "dword"))
    Local $l_i_Duration0 = Memory_Read($a_p_SkillPtr + 0x44, "dword")
    Local $l_i_Duration15 = Memory_Read($a_p_SkillPtr + 0x48, "dword")

    ; Build replacement strings (format: min...max or just value if equal)
    Local $l_s_Scale = ($l_i_Scale0 = $l_i_Scale15) ? String($l_i_Scale0) : ($l_i_Scale0 & "..." & $l_i_Scale15)
    Local $l_s_BonusScale = ($l_i_BonusScale0 = $l_i_BonusScale15) ? String($l_i_BonusScale0) : ($l_i_BonusScale0 & "..." & $l_i_BonusScale15)
    Local $l_s_Duration = ($l_i_Duration0 = $l_i_Duration15) ? String($l_i_Duration0) : ($l_i_Duration0 & "..." & $l_i_Duration15)

    ; Replace placeholder strings with actual values
    ; The decoder outputs these as decimal strings "991", "992", "993"
    Local $l_s_Result = $a_s_Text
    $l_s_Result = StringReplace($l_s_Result, "991", $l_s_Scale)
    $l_s_Result = StringReplace($l_s_Result, "992", $l_s_BonusScale)
    $l_s_Result = StringReplace($l_s_Result, "993", $l_s_Duration)

    Return $l_s_Result
EndFunc

#Region Skillbar Related
Func Skill_GetSkillbarInfo($a_i_SkillSlot = 1, $a_s_Info = "", $a_i_HeroNumber = 0)
    Local $l_p_Ptr = World_GetWorldInfo("SkillbarArray")
    Local $l_i_Size = World_GetWorldInfo("SkillbarArraySize")

    If $l_p_Ptr = 0 Or $a_i_HeroNumber < 0 Or $a_i_HeroNumber >= $l_i_Size Then Return 0
    If $a_i_SkillSlot < 1 Or $a_i_SkillSlot > 8 Then Return 0

    If $a_i_HeroNumber <> 0 Then
        Local $l_i_HeroID = Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID")
    Else
        Local $l_i_HeroID = Agent_GetMyID()
    EndIf

    If $l_i_HeroID = 0 Then Return 0

    Local $l_i_ReadHeroID, $l_p_SkillbarPtr
    For $l_i_Idx = 0 To $l_i_Size - 1
        $l_p_SkillbarPtr = $l_p_Ptr + (0xBC * $l_i_Idx)
        $l_i_ReadHeroID = Memory_Read($l_p_SkillbarPtr, "long")
        If $l_p_SkillbarPtr <> 0 And $l_i_ReadHeroID = $l_i_HeroID Then ExitLoop
    Next
    If $l_p_SkillbarPtr = 0 Or $l_i_ReadHeroID <> $l_i_HeroID Then Return 0

    Switch $a_s_Info
        Case "AgentID"
            Return Memory_Read($l_p_SkillbarPtr, "long")
        Case "Disabled"
            Return Memory_Read($l_p_SkillbarPtr + 0xA4, "dword")
        Case "Casting"
            Return Memory_Read($l_p_SkillbarPtr + 0xB0, "dword")
        Case "h00A8[2]"
            Return Memory_Read($l_p_SkillbarPtr + 0xA8, "dword")
        Case "h00B4[2]"
            Return Memory_Read($l_p_SkillbarPtr + 0xB4, "dword")
        Case "Queued"
            Return Memory_Read($l_p_SkillbarPtr + 0xB8, "dword")

        Case "SkillID"
            Return Memory_Read($l_p_SkillbarPtr + 0x10 + (($a_i_SkillSlot - 1) * 0x14), "dword")

        Case "IsRecharged"
            Local $l_i_Timestamp = Memory_Read($l_p_SkillbarPtr + 0xC + (($a_i_SkillSlot - 1) * 0x14), "dword")
            If $l_i_Timestamp = 0 Then Return True
            Return ($l_i_Timestamp - Skill_GetSkillTimer()) = 0

        Case "RechargeTime"
			Local $l_i_RechargeTimestamp = Memory_Read($l_p_SkillbarPtr + 0xC + (($a_i_SkillSlot - 1) * 0x14), "dword")
			If $l_i_RechargeTimestamp = 0 Then Return 0

			Local $l_i_RechargeTimestampSigned = Utils_MakeInt32($l_i_RechargeTimestamp)
			Local $l_i_SkillTimerSigned = Utils_MakeInt32(Skill_GetSkillTimer())

			Local $l_i_TimeRemaining = $l_i_RechargeTimestampSigned - $l_i_SkillTimerSigned
			If $l_i_TimeRemaining <= 0 Then
				Return 0
			Else
				Return $l_i_TimeRemaining
			EndIf

        Case "Adrenaline"
            Return Memory_Read($l_p_SkillbarPtr + 0x4 + (($a_i_SkillSlot - 1) * 0x14), "dword")

        Case "AdrenalineB"
            Return Memory_Read($l_p_SkillbarPtr + 0x8 + (($a_i_SkillSlot - 1) * 0x14), "dword")

        Case "Event"
            Return Memory_Read($l_p_SkillbarPtr + 0x14 + (($a_i_SkillSlot - 1) * 0x14), "dword")

        Case "HasSkill"
            Return Memory_Read($l_p_SkillbarPtr + 0x10 + (($a_i_SkillSlot - 1) * 0x14), "dword") <> 0

        Case "SlotBySkillID"
            For $l_i_Slot = 1 To 8
                If Memory_Read($l_p_SkillbarPtr + 0x10 + (($l_i_Slot - 1) * 0x14), "dword") = $a_i_SkillSlot Then
                    Return $l_i_Slot
                EndIf
            Next
            Return 0

        Case "HasSkillID"
            For $l_i_Slot = 1 To 8
                If Memory_Read($l_p_SkillbarPtr + 0x10 + (($l_i_Slot - 1) * 0x14), "dword") = $a_i_SkillSlot Then
                    Return True
                EndIf
            Next
            Return False

        Case Else
            Return 0
    EndSwitch
EndFunc   ;==>GetSkillbarInfo
#EndRegion Skillbar Related

#Region Campaign
Func Skill_GetSkillCampaign($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Campaign")
EndFunc

Func Skill_IsSkillCampaign($a_i_SkillID, $a_i_campaignType)
	Return Skill_GetSkillCampaign($a_i_SkillID) = $a_i_campaignType
EndFunc

Func Skill_IsCoreCampaign($a_i_SkillID)
	Return Skill_IsSkillCampaign($a_i_SkillID, $GC_I_SKILL_CAMPAIGN_CORE)
EndFunc

Func Skill_IsPropheciesCampaign($a_i_SkillID)
	Return Skill_IsSkillCampaign($a_i_SkillID, $GC_I_SKILL_CAMPAIGN_PROPHECIES)
EndFunc

Func Skill_IsFactionsCampaign($a_i_SkillID)
	Return Skill_IsSkillCampaign($a_i_SkillID, $GC_I_SKILL_CAMPAIGN_FACTIONS)
EndFunc

Func Skill_IsNightfallCampaign($a_i_SkillID)
	Return Skill_IsSkillCampaign($a_i_SkillID, $GC_I_SKILL_CAMPAIGN_NIGHTFALL)
EndFunc

Func Skill_IsEotNCampaign($a_i_SkillID)
	Return Skill_IsSkillCampaign($a_i_SkillID, $GC_I_SKILL_CAMPAIGN_EOTN)
EndFunc

Func Skill_IsBonusMissionPackCampaign($a_i_SkillID)
	Return Skill_IsSkillCampaign($a_i_SkillID, $GC_I_SKILL_CAMPAIGN_BONUSPACK)
EndFunc

Func Skill_GetCampaignName($a_i_CampaignID)
    Switch $a_i_CampaignID
        Case $GC_I_SKILL_CAMPAIGN_CORE
            Return "Core"
        Case $GC_I_SKILL_CAMPAIGN_PROPHECIES
            Return "Prophecies"
        Case $GC_I_SKILL_CAMPAIGN_FACTIONS
            Return "Factions"
        Case $GC_I_SKILL_CAMPAIGN_NIGHTFALL
            Return "Nightfall"
        Case $GC_I_SKILL_CAMPAIGN_EOTN
            Return "EotN"
        Case $GC_I_SKILL_CAMPAIGN_BONUSPACK
            Return "Bonus Pack"
        Case Else
            Return "Unknown"
    EndSwitch
EndFunc
#EndRegion Campaign

#Region SkillType
Func Skill_GetSkillType($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "SkillType")
EndFunc

Func Skill_IsType($a_i_SkillID, $skillType)
	Return Skill_GetSkillType($a_i_SkillID) = $skillType
EndFunc

Func Skill_IsBountyType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_BOUNTY)
EndFunc

Func Skill_IsScrollType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_SCROLL)
EndFunc

Func Skill_IsStanceType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_STANCE)
EndFunc

Func Skill_IsHexType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_HEX)
EndFunc

Func Skill_IsSpellType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_SPELL)
EndFunc

Func Skill_IsEnchantmentType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_ENCHANTMENT)
EndFunc

Func Skill_IsSignetType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_SIGNET)
EndFunc

Func Skill_IsConditionType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_CONDITION)
EndFunc

Func Skill_IsWellType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_WELL)
EndFunc

Func Skill_IsSkillType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_SKILL)
EndFunc

Func Skill_IsWardType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_WARD)
EndFunc

Func Skill_IsGlyphType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_GLYPH)
EndFunc

Func Skill_IsTitleType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_TITLE)
EndFunc

Func Skill_IsAttackType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_ATTACK)
EndFunc

Func Skill_IsShoutType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_SHOUT)
EndFunc

Func Skill_IsSkill2Type($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_SKILL2)
EndFunc

Func Skill_IsPassiveType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_PASSIVE)
EndFunc

Func Skill_IsEnvironmentalType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_ENVIRONMENTAL)
EndFunc

Func Skill_IsPreparationType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_PREPARATION)
EndFunc

Func Skill_IsPetAttackType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_PETATTACK)
EndFunc

Func Skill_IsTrapType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_TRAP)
EndFunc

Func Skill_IsRitualType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_RITUAL)
EndFunc

Func Skill_IsEnvironmentalTrapType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_ENVIRONMENTALTRAP)
EndFunc

Func Skill_IsItemSpellType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_ITEM_SPELL)
EndFunc

Func Skill_IsWeaponSpellType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_WEAPON_SPELL)
EndFunc

Func Skill_IsFormType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_FORM)
EndFunc

Func Skill_IsChantType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_CHANT)
EndFunc

Func Skill_IsEchoType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_ECHO_REFRAIN)
EndFunc

Func Skill_IsDisguiseType($a_i_SkillID)
	Return Skill_IsType($a_i_SkillID, $GC_I_SKILL_TYPE_DISGUISE)
EndFunc
#EndRegion SkillType

#Region Skill Special
Func Skill_GetSkillSpecial($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Special")
EndFunc

Func Skill_HasSpecialFlag($a_i_SkillID, $i_Flag)
	Local $i_Special = Skill_GetSkillSpecial($a_i_SkillID)
	Return BitAND($i_Special, $i_Flag) <> 0
EndFunc

Func Skill_IsAnySpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_ANY)
EndFunc

Func Skill_IsOvercastSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_OVERCAST)
EndFunc

Func Skill_IsTouchSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_TOUCH)
EndFunc

Func Skill_IsEliteSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_ELITE)
EndFunc

Func Skill_IsHalfRangeSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_HALF_RANGE)
EndFunc

Func Skill_IsCaptureSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_CAPTURE)
EndFunc

Func Skill_IsInterruptedEasilySpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_INTERRUPTED_EASILY)
EndFunc

Func Skill_IsAttrFailureSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_ATTR_FAILURE)
EndFunc

Func Skill_IsArmorLessSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_ARMOR_LESS)
EndFunc

Func Skill_IsTrapRitualPrepSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_TRAP_RITUAL_PREP)
EndFunc

Func Skill_IsHexHealthDegenSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_HEX_HEALTH_DEGEN)
EndFunc

Func Skill_IsEventSkillSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_EVENT_SKILL)
EndFunc

Func Skill_IsResurrectionSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_RESURRECTION)
EndFunc

Func Skill_IsOathShotSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_OATH_SHOT)
EndFunc

Func Skill_IsConditionSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_CONDITION)
EndFunc

Func Skill_IsMonsterSkillSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_MONSTER_SKILL)
EndFunc

Func Skill_IsMustFollowOhaSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_MUST_FOLLOW_OHA)
EndFunc

Func Skill_IsCorpseSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_CORPSE)
EndFunc

Func Skill_IsPVESpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_PVE)
EndFunc

Func Skill_IsBlessingDisguiseSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_BLESSING_DISGUISE)
EndFunc

Func Skill_IsPassiveMonsterSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_PASSIVE_MONSTER)
EndFunc

Func Skill_IsPVPSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_PVP)
EndFunc

Func Skill_IsEnchantFlashSpecial($a_i_SkillID)
	Return Skill_HasSpecialFlag($a_i_SkillID, $GC_I_SKILL_SPECIAL_FLAG_ENCHANT_FLASH)
EndFunc

Func Skill_HasSeveralSpecialFlags($a_i_SkillID, $i_Flags)
	Local $i_Special = Skill_GetSkillSpecial($a_i_SkillID)
	Return BitAND($i_Special, $i_Flags) = $i_Flags
EndFunc

;~ Func Skill_IsEliteTouch($a_i_SkillID)
;~ 	Return Skill_HasAllSpecialFlags($a_i_SkillID, BitOR($GC_I_SKILL_SPECIAL_FLAG_ELITE, $GC_I_SKILL_SPECIAL_FLAG_TOUCH))
;~ EndFunc

;~ Func Skill_IsEliteTouchWithExhaustion($a_i_SkillID)
;~ 	Local $i_Flags = BitOR($GC_I_SKILL_SPECIAL_FLAG_ELITE, $GC_I_SKILL_SPECIAL_FLAG_TOUCH, $GC_I_SKILL_SPECIAL_FLAG_OVERCAST)
;~ 	Return Skill_HasAllSpecialFlags($a_i_SkillID, $i_Flags)
;~ EndFunc
#EndRegion Skill Special

#Region Combo
Func Skill_GetSkillCombo($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Combo")
EndFunc

Func Skill_IsSkillCombo($a_i_SkillID, $comboType)
	Return Skill_GetSkillCombo($a_i_SkillID) = $comboType
EndFunc

Func Skill_IsComboAny($a_i_SkillID)
	Return Skill_IsSkillCombo($a_i_SkillID, $GC_I_SKILL_COMBO_ANY)
EndFunc

Func Skill_IsComboLeadAttack($a_i_SkillID)
	Return Skill_IsSkillCombo($a_i_SkillID, $GC_I_SKILL_COMBO_LEAD_ATTACK)
EndFunc

Func Skill_IsComboOffHandAttack($a_i_SkillID)
	Return Skill_IsSkillCombo($a_i_SkillID, $GC_I_SKILL_COMBO_OFF_HAND_ATTACK)
EndFunc

Func Skill_IsComboDualAttack($a_i_SkillID)
	Return Skill_IsSkillCombo($a_i_SkillID, $GC_I_SKILL_COMBO_DUAL_ATTACK)
EndFunc
#EndRegion Combo

#Region ComboRequirement
Func Skill_GetSkillComboReq($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "ComboReq")
EndFunc

Func Skill_IsSkillComboReq($a_i_SkillID, $comboReqType)
	Return Skill_GetSkillComboReq($a_i_SkillID) = $comboReqType
EndFunc

Func Skill_IsComboReqAny($a_i_SkillID)
	Return Skill_IsSkillComboReq($a_i_SkillID, $GC_I_SKILL_COMBO_REQ_ANY)
EndFunc

Func Skill_IsComboReqDualAttack($a_i_SkillID)
	Return Skill_IsSkillComboReq($a_i_SkillID, $GC_I_SKILL_COMBO_REQ_DUAL_ATTACK)
EndFunc

Func Skill_IsComboReqLeadAttack($a_i_SkillID)
	Return Skill_IsSkillComboReq($a_i_SkillID, $GC_I_SKILL_COMBO_REQ_LEAD_ATTACK)
EndFunc

Func Skill_IsComboReqOffHandAttack($a_i_SkillID)
	Return Skill_IsSkillComboReq($a_i_SkillID, $GC_I_SKILL_COMBO_REQ_OFF_HAND_ATTACK)
EndFunc

Func Skill_IsComboReqHexedFoe($a_i_SkillID)
	Return Skill_IsSkillComboReq($a_i_SkillID, $GC_I_SKILL_COMBO_REQ_HEXED_FOE)
EndFunc
#EndRegion ComboRequirement

#Region Effect1
Func Skill_GetSkillEffect1($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Effect1")
EndFunc

Func Skill_IsSkillEffect1($a_i_SkillID, $effectType)
	Return Skill_GetSkillEffect1($a_i_SkillID) = $effectType
EndFunc

Func Skill_HasEffect1Flag($a_i_SkillID, $i_Flag)
	Local $i_Effect1 = Skill_GetSkillEffect1($a_i_SkillID)
	Return BitAND($i_Effect1, $i_Flag) <> 0
EndFunc

Func Skill_IsAnyEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_ANY)
EndFunc

Func Skill_IsBleedEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_BLEEDING)
EndFunc

Func Skill_IsBlindEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_BLINDED)
EndFunc

Func Skill_IsBurnEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_BURNING)
EndFunc

Func Skill_IsCrippleEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_CRIPPLED)
EndFunc

Func Skill_IsDeepWoundEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_DEEP_WOUND)
EndFunc

Func Skill_IsDiseaseEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_DISEASED)
EndFunc

Func Skill_IsSlowEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_50_SLOWER_MOVEMENT)
EndFunc

Func Skill_IsKnockDownEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_KNOCKDOWN)
EndFunc

Func Skill_IsPoisonEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_POISONED)
EndFunc

Func Skill_IsDazeEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_DAZED)
EndFunc

Func Skill_IsWeakEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_WEAKNESS)
EndFunc

Func Skill_IsWaterHexEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_WATER_HEX)
EndFunc

Func Skill_IsHealEffect1($a_i_SkillID)
	Return Skill_HasEffect1Flag($a_i_SkillID, $GC_I_SKILL_EFFECT1_HEAL)
EndFunc

Func Skill_HasSeveralEffect1Flags($a_i_SkillID, $i_Flags)
	Local $i_Effect1 = Skill_GetSkillEffect1($a_i_SkillID)
	Return BitAND($i_Effect1, $i_Flags) = $i_Flags
EndFunc

Func Skill_IsBleedAndCripple($a_i_SkillID)
	Return Skill_HasSeveralEffect1Flags($a_i_SkillID, BitOR($GC_I_SKILL_EFFECT1_BLEEDING, $GC_I_SKILL_EFFECT1_CRIPPLED))
EndFunc

Func Skill_IsDazeAndBlind($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT1_BLINDED, $GC_I_SKILL_EFFECT1_DAZED)
	Return Skill_HasSeveralEffect1Flags($a_i_SkillID, $i_Flags)
EndFunc
#EndRegion Effect1

#Region Effect2
Func Skill_GetSkillEffect2($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Effect2")
EndFunc

Func Skill_IsSkillEffect2($a_i_SkillID, $effectType)
	Return Skill_GetSkillEffect2($a_i_SkillID) = $effectType
EndFunc

Func Skill_HasEffect2Flag($a_i_SkillID, $i_Flag)
	Local $i_Effect2 = Skill_GetSkillEffect2($a_i_SkillID)
	Return BitAND($i_Effect2, $i_Flag) <> 0
EndFunc

Func Skill_IsAnyEffect2($a_i_SkillID)
	Return Skill_GetSkillEffect2($a_i_SkillID) <> 0
EndFunc

Func Skill_IsInterruptEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_INTERRUPT)
EndFunc

Func Skill_CanHealOtherEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_CAN_HEAL_OTHER)
EndFunc

Func Skill_CanHealSelfEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_CAN_HEAL_SELF)
EndFunc

Func Skill_IsResurrectionEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_RESURRECTION)
EndFunc

Func Skill_IsResSignetEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_RES_SIGNET)
EndFunc

Func Skill_IsSacrificingEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_SACRIFICING)
EndFunc

Func Skill_IsEnergyStealEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_ENERGY_STEAL)
EndFunc

Func Skill_IsBlockingEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_BLOCKING)
EndFunc

Func Skill_IsEnergyGainEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_ENERGY_GAIN)
EndFunc

Func Skill_IsCloseRangeEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_CLOSE_RANGE)
EndFunc

Func Skill_IsSurroundingEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_SURROUNDING)
EndFunc

Func Skill_IsHexRemovalEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_HEX_REMOVAL)
EndFunc

Func Skill_IsConditionRemovalEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_CONDITION_REMOVAL)
EndFunc

Func Skill_IsSelfEnchantRemovalEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_SELF_ENCHANT_REMOVAL)
EndFunc

Func Skill_IsReversalDamageEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_REVERSAL_DAMAGE)
EndFunc

Func Skill_IsAttackMovementSpeedEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_ATTACK_MOVEMENT_SPEED)
EndFunc

Func Skill_IsSelfKnockdownEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_SELF_KNOCKDOWN)
EndFunc

Func Skill_IsSelfTargetEnchantEffect2($a_i_SkillID)
	Return Skill_HasEffect2Flag($a_i_SkillID, $GC_I_SKILL_EFFECT2_SELF_TARGET_ENCHANT)
EndFunc

; === Combined Checks ===
Func Skill_HasSeveralEffect2Flags($a_i_SkillID, $i_Flags)
	Local $i_Effect2 = Skill_GetSkillEffect2($a_i_SkillID)
	Return BitAND($i_Effect2, $i_Flags) = $i_Flags
EndFunc

; Heal (self or other)
Func Skill_IsHealEffect2($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT2_CAN_HEAL_SELF, $GC_I_SKILL_EFFECT2_CAN_HEAL_OTHER)
	Local $i_Effect2 = Skill_GetSkillEffect2($a_i_SkillID)
	Return BitAND($i_Effect2, $i_Flags) <> 0
EndFunc

; Heal Both (self AND other)
Func Skill_CanHealBothEffect2($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT2_CAN_HEAL_SELF, $GC_I_SKILL_EFFECT2_CAN_HEAL_OTHER)
	Return Skill_HasSeveralEffect2Flags($a_i_SkillID, $i_Flags)
EndFunc

; Sacrificing + Heal Self
Func Skill_IsSacrificingHealSelf($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT2_SACRIFICING, $GC_I_SKILL_EFFECT2_CAN_HEAL_SELF)
	Return Skill_HasSeveralEffect2Flags($a_i_SkillID, $i_Flags)
EndFunc

; Sacrificing + Heal Other
Func Skill_IsSacrificingHealOther($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT2_SACRIFICING, $GC_I_SKILL_EFFECT2_CAN_HEAL_OTHER)
	Return Skill_HasSeveralEffect2Flags($a_i_SkillID, $i_Flags)
EndFunc

; Interrupt + Energy Gain
Func Skill_IsInterruptEnergyGain($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT2_INTERRUPT, $GC_I_SKILL_EFFECT2_ENERGY_GAIN)
	Return Skill_HasSeveralEffect2Flags($a_i_SkillID, $i_Flags)
EndFunc

; Hex + Condition Removal
Func Skill_IsHexConditionRemoval($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT2_HEX_REMOVAL, $GC_I_SKILL_EFFECT2_CONDITION_REMOVAL)
	Return Skill_HasSeveralEffect2Flags($a_i_SkillID, $i_Flags)
EndFunc

; Hex + Condition Removal + Heal
Func Skill_IsHexConditionRemovalHeal($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT2_HEX_REMOVAL, $GC_I_SKILL_EFFECT2_CONDITION_REMOVAL)
	$i_Flags = BitOR($i_Flags, BitOR($GC_I_SKILL_EFFECT2_CAN_HEAL_SELF, $GC_I_SKILL_EFFECT2_CAN_HEAL_OTHER))
	Local $i_Effect2 = Skill_GetSkillEffect2($a_i_SkillID)
	; Au moins heal + (hex ou condition)
	Return BitAND($i_Effect2, $GC_I_SKILL_EFFECT2_HEX_REMOVAL) <> 0 Or _
	       BitAND($i_Effect2, $GC_I_SKILL_EFFECT2_CONDITION_REMOVAL) <> 0 And _
	       Skill_IsHealEffect2($a_i_SkillID)
EndFunc

; Resurrection (any type)
Func Skill_IsAnyResurrection($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_EFFECT2_RESURRECTION, $GC_I_SKILL_EFFECT2_RES_SIGNET)
	Local $i_Effect2 = Skill_GetSkillEffect2($a_i_SkillID)
	Return BitAND($i_Effect2, $i_Flags) <> 0
EndFunc
#EndRegion Effect2

#Region RequireCondition
Func Skill_GetSkillRequireCondition($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "RequireCondition")
EndFunc

Func Skill_IsSkillRequireCondition($a_i_SkillID, $conditionType)
	Return Skill_GetSkillRequireCondition($a_i_SkillID) = $conditionType
EndFunc

Func Skill_HasRequireConditionFlag($a_i_SkillID, $i_Flag)
	Local $i_Require = Skill_GetSkillRequireCondition($a_i_SkillID)
	Return BitAND($i_Require, $i_Flag) <> 0
EndFunc

Func Skill_RequiresAnyCondition($a_i_SkillID)
	Return Skill_GetSkillRequireCondition($a_i_SkillID) <> 0
EndFunc

Func Skill_RequiresBleeding($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_BLEEDING)
EndFunc

Func Skill_RequiresBlinded($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_BLINDED)
EndFunc

Func Skill_RequiresBurning($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_BURNING)
EndFunc

Func Skill_RequiresCrippled($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_CRIPPLED)
EndFunc

Func Skill_RequiresDeepWound($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_DEEP_WOUND)
EndFunc

Func Skill_RequiresDiseased($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_DISEASED)
EndFunc

Func Skill_RequiresSlowerMovement($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_SLOWER_MOVEMENT)
EndFunc

Func Skill_RequiresKnockdown($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_KNOCKDOWN)
EndFunc

Func Skill_RequiresPoisoned($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_POISONED)
EndFunc

Func Skill_RequiresDazed($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_DAZED)
EndFunc

Func Skill_RequiresWeakness($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_WEAKNESS)
EndFunc

Func Skill_RequiresUnknownFlag($a_i_SkillID)
	Return Skill_HasRequireConditionFlag($a_i_SkillID, $GC_I_SKILL_REQUIRE_UNKNOWN)
EndFunc

; === Combined Checks ===
Func Skill_HasSeveralRequireConditionFlags($a_i_SkillID, $i_Flags)
	Local $i_Require = Skill_GetSkillRequireCondition($a_i_SkillID)
	Return BitAND($i_Require, $i_Flags) = $i_Flags
EndFunc

; Crippled + Bleeding
Func Skill_RequiresCrippledAndBleeding($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_CRIPPLED, $GC_I_SKILL_REQUIRE_BLEEDING)
	Return Skill_HasSeveralRequireConditionFlags($a_i_SkillID, $i_Flags)
EndFunc

; Deep Wound + Bleeding
Func Skill_RequiresDeepWoundAndBleeding($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_DEEP_WOUND, $GC_I_SKILL_REQUIRE_BLEEDING)
	Return Skill_HasSeveralRequireConditionFlags($a_i_SkillID, $i_Flags)
EndFunc

; Knockdown + Crippled
Func Skill_RequiresKnockdownAndCrippled($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_KNOCKDOWN, $GC_I_SKILL_REQUIRE_CRIPPLED)
	Return Skill_HasSeveralRequireConditionFlags($a_i_SkillID, $i_Flags)
EndFunc

; Dazed + Blinded
Func Skill_RequiresDazedAndBlinded($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_DAZED, $GC_I_SKILL_REQUIRE_BLINDED)
	Return Skill_HasSeveralRequireConditionFlags($a_i_SkillID, $i_Flags)
EndFunc

; Weakness + Deep Wound
Func Skill_RequiresWeaknessAndDeepWound($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_WEAKNESS, $GC_I_SKILL_REQUIRE_DEEP_WOUND)
	Return Skill_HasSeveralRequireConditionFlags($a_i_SkillID, $i_Flags)
EndFunc

; Knockdown + Weakness
Func Skill_RequiresKnockdownAndWeakness($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_KNOCKDOWN, $GC_I_SKILL_REQUIRE_WEAKNESS)
	Return Skill_HasSeveralRequireConditionFlags($a_i_SkillID, $i_Flags)
EndFunc

; Random (Deep Wound OR Crippled OR Bleeding OR Weakness)
Func Skill_RequiresDCBW($a_i_SkillID)
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_DEEP_WOUND, $GC_I_SKILL_REQUIRE_CRIPPLED)
	$i_Flags = BitOR($i_Flags, $GC_I_SKILL_REQUIRE_BLEEDING)
	$i_Flags = BitOR($i_Flags, $GC_I_SKILL_REQUIRE_WEAKNESS)
	Return Skill_HasSeveralRequireConditionFlags($a_i_SkillID, $i_Flags)
EndFunc

; Check if requires ANY of the specified conditions (OR logic)
Func Skill_RequiresAnyOfConditions($a_i_SkillID, $i_Flags)
	Local $i_Require = Skill_GetSkillRequireCondition($a_i_SkillID)
	Return BitAND($i_Require, $i_Flags) <> 0
EndFunc

; Common condition groups
Func Skill_RequiresMovementCondition($a_i_SkillID)
	; Crippled OR Slower Movement
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_CRIPPLED, $GC_I_SKILL_REQUIRE_SLOWER_MOVEMENT)
	Return Skill_RequiresAnyOfConditions($a_i_SkillID, $i_Flags)
EndFunc

Func Skill_RequiresDamageCondition($a_i_SkillID)
	; Bleeding OR Burning OR Poisoned OR Deep Wound
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_BLEEDING, $GC_I_SKILL_REQUIRE_BURNING)
	$i_Flags = BitOR($i_Flags, $GC_I_SKILL_REQUIRE_POISONED)
	$i_Flags = BitOR($i_Flags, $GC_I_SKILL_REQUIRE_DEEP_WOUND)
	Return Skill_RequiresAnyOfConditions($a_i_SkillID, $i_Flags)
EndFunc

Func Skill_RequiresDisableCondition($a_i_SkillID)
	; Knockdown OR Dazed OR Blinded OR Weakness
	Local $i_Flags = BitOR($GC_I_SKILL_REQUIRE_KNOCKDOWN, $GC_I_SKILL_REQUIRE_DAZED)
	$i_Flags = BitOR($i_Flags, $GC_I_SKILL_REQUIRE_BLINDED)
	$i_Flags = BitOR($i_Flags, $GC_I_SKILL_REQUIRE_WEAKNESS)
	Return Skill_RequiresAnyOfConditions($a_i_SkillID, $i_Flags)
EndFunc

#EndRegion RequireCondition

#Region WeaponReq
Func Skill_GetSkillWeaponReq($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "WeaponReq")
EndFunc

Func Skill_IsSkillWeaponReq($a_i_SkillID, $weaponType)
	Return Skill_GetSkillWeaponReq($a_i_SkillID) = $weaponType
EndFunc

Func Skill_IsWeaponReqAxe($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_AXE)
EndFunc

Func Skill_IsWeaponReqBow($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_BOW)
EndFunc

Func Skill_IsWeaponReqDagger($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_DAGGER)
EndFunc

Func Skill_IsWeaponReqHammer($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_HAMMER)
EndFunc

Func Skill_IsWeaponReqScythe($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_SCYTHE)
EndFunc

Func Skill_IsWeaponReqSpear($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_SPEAR)
EndFunc

Func Skill_IsWeaponReqNoWeapon($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_NO_WEAPON)
EndFunc

Func Skill_IsWeaponReqSword($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_SWORD)
EndFunc

Func Skill_IsWeaponReqMeleeWeapon($a_i_SkillID)
	Return Skill_IsSkillWeaponReq($a_i_SkillID, $GC_I_SKILL_REQUIRE_MELEE_WEAPON)
EndFunc
#EndRegion WeaponReq

#Region Profession
Func Skill_GetSkillProfession($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Profession")
EndFunc

Func Skill_IsSkillProfession($a_i_SkillID, $professionType)
	Return Skill_GetSkillProfession($a_i_SkillID) = $professionType
EndFunc

Func Skill_IsProfessionNone($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_NONE)
EndFunc

Func Skill_IsProfessionWarrior($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_WARRIOR)
EndFunc

Func Skill_IsProfessionRanger($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_RANGER)
EndFunc

Func Skill_IsProfessionMonk($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_MONK)
EndFunc

Func Skill_IsProfessionNecromancer($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_NECROMANCER)
EndFunc

Func Skill_IsProfessionMesmer($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_MESMER)
EndFunc

Func Skill_IsProfessionElementalist($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_ELEMENTALIST)
EndFunc

Func Skill_IsProfessionAssassin($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_ASSASSIN)
EndFunc

Func Skill_IsProfessionRitualist($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_RITUALIST)
EndFunc

Func Skill_IsProfessionParagon($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_PARAGON)
EndFunc

Func Skill_IsProfessionDervish($a_i_SkillID)
	Return Skill_IsSkillProfession($a_i_SkillID, $GC_I_PROFESSION_DERVISH)
EndFunc

; Fonction pour obtenir le nom de la profession
Func Skill_GetProfessionName($a_i_ProfessionID)
    Switch $a_i_ProfessionID
        Case $GC_I_PROFESSION_NONE
            Return "None"
        Case $GC_I_PROFESSION_WARRIOR
            Return "Warrior"
        Case $GC_I_PROFESSION_RANGER
            Return "Ranger"
        Case $GC_I_PROFESSION_MONK
            Return "Monk"
        Case $GC_I_PROFESSION_NECROMANCER
            Return "Necromancer"
        Case $GC_I_PROFESSION_MESMER
            Return "Mesmer"
        Case $GC_I_PROFESSION_ELEMENTALIST
            Return "Elementalist"
        Case $GC_I_PROFESSION_ASSASSIN
            Return "Assassin"
        Case $GC_I_PROFESSION_RITUALIST
            Return "Ritualist"
        Case $GC_I_PROFESSION_PARAGON
            Return "Paragon"
        Case $GC_I_PROFESSION_DERVISH
            Return "Dervish"
        Case Else
            Return "Unknown"
    EndSwitch
EndFunc
#EndRegion Profession

#Region Attribute
Func Skill_GetSkillAttribute($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Attribute")
EndFunc

Func Skill_IsSkillAttribute($a_i_SkillID, $attributeType)
	Return Skill_GetSkillAttribute($a_i_SkillID) = $attributeType
EndFunc

Func Skill_IsAttributeFastCasting($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_FAST_CASTING)
EndFunc

Func Skill_IsAttributeIllusionMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_ILLUSION_MAGIC)
EndFunc

Func Skill_IsAttributeDominationMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_DOMINATION_MAGIC)
EndFunc

Func Skill_IsAttributeInspirationMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_INSPIRATION_MAGIC)
EndFunc

Func Skill_IsAttributeBloodMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_BLOOD_MAGIC)
EndFunc

Func Skill_IsAttributeDeathMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_DEATH_MAGIC)
EndFunc

Func Skill_IsAttributeSoulReaping($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_SOUL_REAPING)
EndFunc

Func Skill_IsAttributeCurses($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_CURSES)
EndFunc

Func Skill_IsAttributeAirMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_AIR_MAGIC)
EndFunc

Func Skill_IsAttributeEarthMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_EARTH_MAGIC)
EndFunc

Func Skill_IsAttributeFireMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_FIRE_MAGIC)
EndFunc

Func Skill_IsAttributeWaterMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_WATER_MAGIC)
EndFunc

Func Skill_IsAttributeEnergyStorage($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_ENERGY_STORAGE)
EndFunc

Func Skill_IsAttributeHealingPrayers($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_HEALING_PRAYERS)
EndFunc

Func Skill_IsAttributeSmitingPrayers($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_SMITING_PRAYERS)
EndFunc

Func Skill_IsAttributeProtectionPrayers($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_PROTECTION_PRAYERS)
EndFunc

Func Skill_IsAttributeDivineFavor($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_DIVINE_FAVOR)
EndFunc

Func Skill_IsAttributeStrength($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_STRENGTH)
EndFunc

Func Skill_IsAttributeAxeMastery($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_AXE_MASTERY)
EndFunc

Func Skill_IsAttributeHammerMastery($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_HAMMER_MASTERY)
EndFunc

Func Skill_IsAttributeSwordsmanship($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_SWORDSMANSHIP)
EndFunc

Func Skill_IsAttributeTactics($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_TACTICS)
EndFunc

Func Skill_IsAttributeBeastMastery($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_BEAST_MASTERY)
EndFunc

Func Skill_IsAttributeExpertise($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_EXPERTISE)
EndFunc

Func Skill_IsAttributeWildernessSurvival($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_WILDERNESS_SURVIVAL)
EndFunc

Func Skill_IsAttributeMarksmanship($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_MARKSMANSHIP)
EndFunc

Func Skill_IsAttributeDaggerMastery($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_DAGGER_MASTERY)
EndFunc

Func Skill_IsAttributeDeadlyArts($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_DEADLY_ARTS)
EndFunc

Func Skill_IsAttributeShadowArts($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_SHADOW_ARTS)
EndFunc

Func Skill_IsAttributeCommuning($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_COMMUNING)
EndFunc

Func Skill_IsAttributeRestorationMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_RESTORATION_MAGIC)
EndFunc

Func Skill_IsAttributeChannelingMagic($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_CHANNELING_MAGIC)
EndFunc

Func Skill_IsAttributeCriticalStrikes($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_CRITICAL_STRIKES)
EndFunc

Func Skill_IsAttributeSpawningPower($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_SPAWNING_POWER)
EndFunc

Func Skill_IsAttributeSpearMastery($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_SPEAR_MASTERY)
EndFunc

Func Skill_IsAttributeCommand($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_COMMAND)
EndFunc

Func Skill_IsAttributeMotivation($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_MOTIVATION)
EndFunc

Func Skill_IsAttributeLeadership($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_LEADERSHIP)
EndFunc

Func Skill_IsAttributeScytheMastery($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_SCYTHE_MASTERY)
EndFunc

Func Skill_IsAttributeWindPrayers($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_WIND_PRAYERS)
EndFunc

Func Skill_IsAttributeEarthPrayers($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_EARTH_PRAYERS)
EndFunc

Func Skill_IsAttributeMysticism($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_MYSTICISM)
EndFunc

Func Skill_IsAttributeNone($a_i_SkillID)
	Return Skill_IsSkillAttribute($a_i_SkillID, $GC_I_ATTRIBUTE_NONE)
EndFunc
#EndRegion Attribute

#Region Target
Func Skill_GetSkillTarget($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Target")
EndFunc

Func Skill_IsSkillTarget($a_i_SkillID, $targetType)
	Return Skill_GetSkillTarget($a_i_SkillID) = $targetType
EndFunc

Func Skill_IsTargetSelf($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_SELF)
EndFunc

Func Skill_IsTargetNone($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_NONE)
EndFunc

Func Skill_IsTargetSpirit($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_SPIRIT)
EndFunc

Func Skill_IsTargetAnimal($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_ANIMAL)
EndFunc

Func Skill_IsTargetCorpse($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_CORPSE)
EndFunc

Func Skill_IsTargetAlly($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_ALLY)
EndFunc

Func Skill_IsTargetOtherAlly($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_OTHER_ALLY)
EndFunc

Func Skill_IsTargetEnemy($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_ENEMY)
EndFunc

Func Skill_IsTargetDeadAlly($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_DEAD_ALLY)
EndFunc

Func Skill_IsTargetMinion($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_MINION)
EndFunc

Func Skill_IsTargetGround($a_i_SkillID)
	Return Skill_IsSkillTarget($a_i_SkillID, $GC_I_SKILL_TARGET_GROUND)
EndFunc
#EndRegion Target

#Region Title
Func Skill_GetSkillTitle($a_i_SkillID)
	Return Skill_GetSkillInfo($a_i_SkillID, "Title")
EndFunc

Func Skill_IsSkillTitle($a_i_SkillID, $titleType)
	Return Skill_GetSkillTitle($a_i_SkillID) = $titleType
EndFunc

Func Skill_IsTitleKurzick($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_KURZICK)
EndFunc

Func Skill_IsTitleLuxon($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_LUXON)
EndFunc

Func Skill_IsTitleSunspear($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_SUNSPEAR)
EndFunc

Func Skill_IsTitleLightbringer($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_LIGHTBRINGER)
EndFunc

Func Skill_IsTitleAsura($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_ASURA)
EndFunc

Func Skill_IsTitleDeldrimor($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_DELDRIMOR)
EndFunc

Func Skill_IsTitleEbonVanguard($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_EBON_VANGUARD)
EndFunc

Func Skill_IsTitleNorn($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_NORN)
EndFunc

Func Skill_IsTitleNone($a_i_SkillID)
	Return Skill_IsSkillTitle($a_i_SkillID, $GC_I_SKILL_TITLE_NONE)
EndFunc
#EndRegion Title

#Region Cracked Armor
Func Skill_InflictCA($a_i_SkillID)
	Switch $a_i_SkillID
		Case 2236, 159, 228, 1099, 2148, 1498, 910, 2054, 937, 2059, 1765, 1360, 2214, 232, 205, 865, 2070, 2211, 2353
			Return True
		Case Else
			Return False
	EndSwitch
EndFunc

Func Skill_RequireCA($a_i_SkillID)
	If $a_i_SkillID = 2074 Then Return True
	Return False
EndFunc

Func Skill_BenefitWithCA($a_i_SkillID)
	Switch $a_i_SkillID
		Case 2197, 2198, 2228, 2194, 2140, 1082, 2299, 1097
			Return True
		Case Else
			Return False
	EndSwitch
EndFunc
#EndRegion Cracked Armor

#Region Argument
Func Skill_GetSkillArg($a_i_SkillID, $a_s_Argument = "", $a_i_HeroNumber = 0)
	Switch $a_s_Argument
		Case "Duration"
			Local $l_i_Duration0 = Skill_GetSkillInfo($a_i_SkillID, "Duration0")
			Local $l_i_Duration15 = Skill_GetSkillInfo($a_i_SkillID, "Duration15")
			Local $l_i_AttrID = Skill_GetSkillInfo($a_i_SkillID, "Attribute")
			Local $l_i_AttrLevel = Attribute_GetPartyAttributeInfo($l_i_AttrID, $a_i_HeroNumber, "CurrentLevel")

			Return Round($l_i_Duration0 + (($l_i_Duration15 - $l_i_Duration0) / 15) * $l_i_AttrLevel)
		Case "Scale"
			Local $l_i_Scale0 = _Skill_ConvertScaleValue(Skill_GetSkillInfo($a_i_SkillID, "Scale0"))
			Local $l_i_Scale15 = _Skill_ConvertScaleValue(Skill_GetSkillInfo($a_i_SkillID, "Scale15"))
			Local $l_i_AttrID = Skill_GetSkillInfo($a_i_SkillID, "Attribute")
			Local $l_i_AttrLevel = Attribute_GetPartyAttributeInfo($l_i_AttrID, $a_i_HeroNumber, "CurrentLevel")

			Return Floor($l_i_Scale0 + (($l_i_Scale15 - $l_i_Scale0) / 15) * $l_i_AttrLevel)
		Case "BonusScale"
			Local $l_i_BonusScale0 = _Skill_ConvertScaleValue(Skill_GetSkillInfo($a_i_SkillID, "BonusScale0"))
			Local $l_i_BonusScale15 = _Skill_ConvertScaleValue(Skill_GetSkillInfo($a_i_SkillID, "BonusScale15"))
			Local $l_i_AttrID = Skill_GetSkillInfo($a_i_SkillID, "Attribute")
			Local $l_i_AttrLevel = Attribute_GetPartyAttributeInfo($l_i_AttrID, $a_i_HeroNumber, "CurrentLevel")

			Return Floor($l_i_BonusScale0 + (($l_i_BonusScale15 - $l_i_BonusScale0) / 15) * $l_i_AttrLevel)
		Case Else
			Return 0
	EndSwitch
EndFunc
#EndRegion Argument

;~ Description: Milliseconds until our skill lands on $a_v_TargetID.
;~ Applies Fast Casting (Mesmer primary) for spells/signets, halves attack activation,
;~ adds bow/spear projectile travel from distance to target, then ping*1.5.
;~ Pass target 0 for activation+ping only (busy clock / no projectile).
Func Skill_GetMyActivationTime($a_v_SkillID, $a_v_TargetID = 0)
	Local $l_i_SkillID = Number($a_v_SkillID)
	If IsPtr($a_v_SkillID) Then $l_i_SkillID = Number(Skill_GetSkillInfo($a_v_SkillID, "SkillID"))
	If $l_i_SkillID <= 0 Then Return 0

	Local $l_i_Act = Number(Skill_GetSkillInfo($l_i_SkillID, "Activation")) * 1000
	Local $l_i_Type = Number(Skill_GetSkillInfo($l_i_SkillID, "SkillType"))
	If $l_i_Type = $GC_I_SKILL_TYPE_ATTACK Then $l_i_Act *= 0.5

	If $l_i_Act > 0 And Number(Agent_GetAgentInfo(-2, "Primary")) = $GC_I_PROFESSION_MESMER Then
		Local $l_b_Spell = ($l_i_Type = $GC_I_SKILL_TYPE_SPELL Or $l_i_Type = $GC_I_SKILL_TYPE_HEX Or $l_i_Type = $GC_I_SKILL_TYPE_ENCHANTMENT)
		Local $l_b_Signet = ($l_i_Type = $GC_I_SKILL_TYPE_SIGNET)
		Local $l_b_MesmerSkill = (Number(Skill_GetSkillInfo($l_i_SkillID, "Profession")) = $GC_I_PROFESSION_MESMER)
		If ($l_b_Spell Or $l_b_Signet) And ($l_b_MesmerSkill Or $l_i_Act >= 2000) Then
			Local $l_i_FC = Number(Attribute_GetPartyAttributeInfo($GC_I_ATTRIBUTE_FAST_CASTING, 0, "Level"))
			If $l_i_FC > 0 Then $l_i_Act = $l_i_Act * (2 ^ (-$l_i_FC / 15))
		EndIf
	EndIf

	Local $l_i_Travel = 0
	If Number($a_v_TargetID) <> 0 Then
		Local $l_f_Speed = 0
		Switch Number(Skill_GetSkillInfo($l_i_SkillID, "WeaponReq"))
			Case $GC_I_SKILL_REQUIRE_BOW
				$l_f_Speed = $GC_F_PROJECTILE_ARROW_SPEED
			Case $GC_I_SKILL_REQUIRE_SPEAR
				$l_f_Speed = $GC_F_PROJECTILE_SPEAR_SPEED
		EndSwitch
		If $l_f_Speed > 0 Then
			Local $l_f_Dist = Agent_GetDistance($a_v_TargetID)
			If $l_f_Dist > 0 Then $l_i_Travel = Int($l_f_Dist / $l_f_Speed)
		EndIf
	EndIf

	Local $l_i_Ping = Number(Other_GetPing())
	If $l_i_Ping <= 0 Then $l_i_Ping = 50
	Return Int($l_i_Act + $l_i_Travel + $l_i_Ping * 1.5)
EndFunc   ;==>Skill_GetMyActivationTime
