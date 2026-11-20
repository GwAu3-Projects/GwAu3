#include-once
; Thin Data wrappers over Modules (Logic-facing names).
; Fat skill classification lists (IsRuptSkill, IsHealSkill, …) stay in LogicCast.

#Region Skill ID + SkillType

Func SkillID($a_v_Skill)
	If IsPtr($a_v_Skill) Then Return Skill_GetSkillInfo($a_v_Skill, "SkillID")
	If IsDllStruct($a_v_Skill) Then Return DllStructGetData($a_v_Skill, "ID")
	Return $a_v_Skill
EndFunc   ;==>SkillID

Func IsHexSpell($a_v_Skill)
	Return Skill_IsHexType(SkillID($a_v_Skill))
EndFunc   ;==>IsHexSpell

Func IsConditionSpell($a_v_Skill)
	Return Skill_IsConditionType(SkillID($a_v_Skill))
EndFunc   ;==>IsConditionSpell

Func IsRitualSkill($a_v_Skill)
	Return Skill_IsRitualType(SkillID($a_v_Skill))
EndFunc   ;==>IsRitualSkill

Func IsWeaponSpell($a_v_Skill)
	Return Skill_IsWeaponSpellType(SkillID($a_v_Skill))
EndFunc   ;==>IsWeaponSpell

Func IsEnchantmentSkill($a_v_Skill)
	Return Skill_IsEnchantmentType(SkillID($a_v_Skill))
EndFunc   ;==>IsEnchantmentSkill

Func IsAttackSkill($a_v_Skill)
	Return Skill_IsAttackType(SkillID($a_v_Skill))
EndFunc   ;==>IsAttackSkill

Func IsStanceskill($a_v_Skill)
	Return Skill_IsStanceType(SkillID($a_v_Skill))
EndFunc   ;==>IsStanceskill

Func Skill_IsSpellskill($a_v_Skill)
	Return Skill_IsSpellType(SkillID($a_v_Skill))
EndFunc   ;==>Skill_IsSpellskill

Func IsSignetskill($a_v_Skill)
	Return Skill_IsSignetType(SkillID($a_v_Skill))
EndFunc   ;==>IsSignetskill

Func IsWellskill($a_v_Skill)
	Return Skill_IsWellType(SkillID($a_v_Skill))
EndFunc   ;==>IsWellskill

Func IsSkill($a_v_Skill)
	Return Skill_IsSkillType(SkillID($a_v_Skill))
EndFunc   ;==>IsSkill

Func IsWardskill($a_v_Skill)
	Return Skill_IsWardType(SkillID($a_v_Skill))
EndFunc   ;==>IsWardskill

Func IsGlyphskill($a_v_Skill)
	Return Skill_IsGlyphType(SkillID($a_v_Skill))
EndFunc   ;==>IsGlyphskill

Func IsShoutskill($a_v_Skill)
	Return Skill_IsShoutType(SkillID($a_v_Skill))
EndFunc   ;==>IsShoutskill

Func IsPreparationskill($a_v_Skill)
	Return Skill_IsPreparationType(SkillID($a_v_Skill))
EndFunc   ;==>IsPreparationskill

Func IsTrapskill($a_v_Skill)
	Return Skill_IsTrapType(SkillID($a_v_Skill))
EndFunc   ;==>IsTrapskill

Func IsItemSpellskill($a_v_Skill)
	Return Skill_IsItemSpellType(SkillID($a_v_Skill))
EndFunc   ;==>IsItemSpellskill

Func IsChantskill($a_v_Skill)
	Return Skill_IsChantType(SkillID($a_v_Skill))
EndFunc   ;==>IsChantskill

Func IsEchoRefrainskill($a_v_Skill)
	Return Skill_IsEchoType(SkillID($a_v_Skill))
EndFunc   ;==>IsEchoRefrainskill

Func IsDisguiseskill($a_v_Skill)
	Return Skill_IsDisguiseType(SkillID($a_v_Skill))
EndFunc   ;==>IsDisguiseskill

#EndRegion Skill ID + SkillType

#Region Skill Target

Func TargetSelfSkill($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "Target") = 0
EndFunc   ;==>TargetSelfSkill

Func TargetSpiritSkill($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "Target") = 1
EndFunc   ;==>TargetSpiritSkill

Func TargetAllySkill($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "Target") = 3
EndFunc   ;==>TargetAllySkill

Func TargetOtherAllySkill($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "Target") = 4
EndFunc   ;==>TargetOtherAllySkill

Func TargetEnemySkill($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "Target") = 5
EndFunc   ;==>TargetEnemySkill

Func TargetdeadAllySkill($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "Target") = 6
EndFunc   ;==>TargetdeadAllySkill

Func TargetMinionskill($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "Target") = 14
EndFunc   ;==>TargetMinionskill

Func TargetGroundskill($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "Target") = 16
EndFunc   ;==>TargetGroundskill

#EndRegion Skill Target

#Region SkillType bit flags (Logic SkillType masks via Modules)

Func IsHealMySelfSkill($a_v_Skill)
	Return BitAND(Skill_GetSkillInfo(SkillID($a_v_Skill), "SkillType"), 4)
EndFunc   ;==>IsHealMySelfSkill

Func IsHealAllySkill($a_v_Skill)
	Return BitAND(Skill_GetSkillInfo(SkillID($a_v_Skill), "SkillType"), 2)
EndFunc   ;==>IsHealAllySkill

Func IsHexRemovalSkill($a_v_Skill)
	Return BitAND(Skill_GetSkillInfo(SkillID($a_v_Skill), "SkillType"), 2048)
EndFunc   ;==>IsHexRemovalSkill

Func IsConditionRemovalSkill($a_v_Skill)
	Return BitAND(Skill_GetSkillInfo(SkillID($a_v_Skill), "SkillType"), 4096)
EndFunc   ;==>IsConditionRemovalSkill

#EndRegion SkillType bit flags

#Region WeaponReq / Combo

Func SkillAxeAttack($a_v_Skill)
	Return Skill_IsWeaponReqAxe(SkillID($a_v_Skill))
EndFunc   ;==>SkillAxeAttack

Func SkillBowAttack($a_v_Skill)
	Return Skill_IsWeaponReqBow(SkillID($a_v_Skill))
EndFunc   ;==>SkillBowAttack

Func SkillDaggerAttack($a_v_Skill)
	Return Skill_IsWeaponReqDagger(SkillID($a_v_Skill))
EndFunc   ;==>SkillDaggerAttack

Func SkillHammerAttack($a_v_Skill)
	Return Skill_IsWeaponReqHammer(SkillID($a_v_Skill))
EndFunc   ;==>SkillHammerAttack

Func SkillScytheAttack($a_v_Skill)
	Return Skill_IsWeaponReqScythe(SkillID($a_v_Skill))
EndFunc   ;==>SkillScytheAttack

Func SkillSpearAttack($a_v_Skill)
	Return Skill_IsWeaponReqSpear(SkillID($a_v_Skill))
EndFunc   ;==>SkillSpearAttack

Func SkillRangedAttack($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "WeaponReq") = 70
EndFunc   ;==>SkillRangedAttack

Func SkillAllSwordAttack($a_v_Skill)
	Return Skill_IsWeaponReqSword(SkillID($a_v_Skill))
EndFunc   ;==>SkillAllSwordAttack

Func SkillMNoWeaponRequiAttack($a_v_Skill)
	Return Skill_GetSkillInfo(SkillID($a_v_Skill), "WeaponReq") = 185
EndFunc   ;==>SkillMNoWeaponRequiAttack

Func SkillDaggerLeadAttack($a_v_Skill)
	Return Skill_IsComboLeadAttack(SkillID($a_v_Skill))
EndFunc   ;==>SkillDaggerLeadAttack

Func SkillDaggerOffHandAttack($a_v_Skill)
	Return Skill_IsComboOffHandAttack(SkillID($a_v_Skill))
EndFunc   ;==>SkillDaggerOffHandAttack

Func SkillDaggerDualAttack($a_v_Skill)
	Return Skill_IsComboDualAttack(SkillID($a_v_Skill))
EndFunc   ;==>SkillDaggerDualAttack

Func IsDaggerRequiDualAttackSkill($a_v_Skill)
	Return BitAND(Skill_GetSkillInfo(SkillID($a_v_Skill), "ComboReq"), 1)
EndFunc   ;==>IsDaggerRequiDualAttackSkill

Func IsDaggerRequiLeadAttackSkill($a_v_Skill)
	Return BitAND(Skill_GetSkillInfo(SkillID($a_v_Skill), "ComboReq"), 2)
EndFunc   ;==>IsDaggerRequiLeadAttackSkill

Func IsDaggerRequiOffHandSkill($a_v_Skill)
	Return BitAND(Skill_GetSkillInfo(SkillID($a_v_Skill), "ComboReq"), 3)
EndFunc   ;==>IsDaggerRequiOffHandSkill

Func IsDaggerRequiHexedFoeSkill($a_v_Skill)
	Return BitAND(Skill_GetSkillInfo(SkillID($a_v_Skill), "ComboReq"), 16)
EndFunc   ;==>IsDaggerRequiHexedFoeSkill

#EndRegion WeaponReq / Combo

#Region Agent field getters

Func Agent_Exists($a_v_Agent = -2)
	Return Agent_GetAgentPtr($a_v_Agent) <> 0
EndFunc   ;==>Agent_Exists

; Returns agent ID. For skill pointers/structs use Skill_GetSkillInfo(..., "SkillID") instead.
Func Agent_ID($a_v_Agent = -2)
	If IsDllStruct($a_v_Agent) Then Return DllStructGetData($a_v_Agent, "ID")
	If IsPtr($a_v_Agent) Then Return Agent_GetAgentInfo($a_v_Agent, "ID")
	If $a_v_Agent = -2 Or $a_v_Agent = 0 Then Return Agent_GetMyID()
	Return Agent_GetAgentInfo($a_v_Agent, "ID")
EndFunc   ;==>Agent_ID

Func X($a_v_Agent = -2)
	Return Agent_GetAgentInfo($a_v_Agent, "X")
EndFunc   ;==>X

Func Y($a_v_Agent = -2)
	Return Agent_GetAgentInfo($a_v_Agent, "Y")
EndFunc   ;==>Y

Func XY($a_v_Agent = -2)
	Local $a_f_XY[2] = [Agent_GetAgentInfo($a_v_Agent, "X"), Agent_GetAgentInfo($a_v_Agent, "Y")]
	Return $a_f_XY
EndFunc   ;==>XY

Func GetIsKnocked($a_v_Agent = -2)
	Return Agent_GetAgentInfo($a_v_Agent, "IsKnocked")
EndFunc   ;==>GetIsKnocked

Func GetEnergy($a_v_Agent = -2)
	Return Agent_GetAgentInfo($a_v_Agent, "CurrentEnergy")
EndFunc   ;==>GetEnergy

Func GetHP($a_v_Agent = -2)
	Return Agent_GetAgentInfo($a_v_Agent, "HP")
EndFunc   ;==>GetHP

Func GetAgentPtr($a_v_Agent = -2)
	Return Agent_GetAgentPtr($a_v_Agent)
EndFunc   ;==>GetAgentPtr

Func CancelAction()
	Agent_CancelAction()
EndFunc   ;==>CancelAction

#EndRegion Agent field getters

#Region Skillbar / skill / effect / misc Module leverage

; GetSkillbarInfo($slot[, $hero]) -> SkillID
; GetSkillbarInfo($slot, "SkillID"|"IsRecharged"|..., [$hero]) -> GwAu3 info form
Func GetSkillbarInfo($a_i_SkillSlot, $a_v_InfoOrHero = 0, $a_i_HeroNumber = 0)
	If IsString($a_v_InfoOrHero) Then
		Return Skill_GetSkillbarInfo($a_i_SkillSlot, $a_v_InfoOrHero, $a_i_HeroNumber)
	EndIf
	Return Skill_GetSkillbarInfo($a_i_SkillSlot, "SkillID", $a_v_InfoOrHero)
EndFunc   ;==>GetSkillbarInfo

Func GetSkillPtr($a_v_SkillID)
	Return Skill_GetSkillPtr($a_v_SkillID)
EndFunc   ;==>GetSkillPtr

Func IsRecharged($a_i_SkillSlot, $a_i_HeroNumber = 0, $a_p_SkillbarPtr = 0)
	#forceref $a_p_SkillbarPtr
	Return Skill_GetSkillbarInfo($a_i_SkillSlot, "IsRecharged", $a_i_HeroNumber)
EndFunc   ;==>IsRecharged

Func GetPing()
	Local $l_i_Ping = Other_GetPing()
	If $l_i_Ping <= 0 Then Return 50
	Return $l_i_Ping
EndFunc   ;==>GetPing

Func GetAttributeByID($a_i_AttributeID, $a_b_Hero = False)
	If $a_b_Hero Then
		Return Attribute_GetPartyAttributeInfo($a_i_AttributeID, 0, "Level")
	EndIf
	Return Attribute_GetAttributeInfo($a_i_AttributeID, "Level")
EndFunc   ;==>GetAttributeByID

; Returns a small DllStruct for legacy call sites that still expect ID/Type/Adrenaline fields.
Func GetSkillByID($a_i_SkillID)
	Local $l_p_Skill = Skill_GetSkillPtr($a_i_SkillID)
	If Not IsPtr($l_p_Skill) Then Return 0
	Local $l_t_Skill = DllStructCreate("long ID; long Type; dword Adrenaline")
	DllStructSetData($l_t_Skill, "ID", Skill_GetSkillInfo($l_p_Skill, "SkillID"))
	DllStructSetData($l_t_Skill, "Type", Skill_GetSkillInfo($l_p_Skill, "SkillType"))
	DllStructSetData($l_t_Skill, "Adrenaline", Skill_GetSkillInfo($l_p_Skill, "Adrenaline"))
	Return $l_t_Skill
EndFunc   ;==>GetSkillByID

Func Skill_HasEffect($a_v_SkillID, $a_v_Agent = -2)
	Return Agent_GetAgentEffectInfo($a_v_Agent, SkillID($a_v_SkillID), "HasEffect") = True
EndFunc   ;==>Skill_HasEffect

Func GetEffectTimeRemaining($a_v_SkillID, $a_v_Agent = -2)
	If IsDllStruct($a_v_SkillID) Then $a_v_SkillID = DllStructGetData($a_v_SkillID, "SkillID")
	Local $l_i_Remaining = Agent_GetAgentEffectInfo($a_v_Agent, $a_v_SkillID, "TimeRemaining")
	If Not IsNumber($l_i_Remaining) Then Return 0
	Return $l_i_Remaining
EndFunc   ;==>GetEffectTimeRemaining

Func Skill_GetSkillEffectPtr($a_v_SkillID, $a_i_HeroID = 0)
	If $a_i_HeroID = 0 Then $a_i_HeroID = -2
	Return Agent_GetAgentEffectInfo($a_i_HeroID, SkillID($a_v_SkillID), "")
EndFunc   ;==>Skill_GetSkillEffectPtr

#EndRegion Skillbar / skill / effect / misc Module leverage

#Region Skill bitflag wrappers (Condition / Special / Effect1 / Effect2)
; Rewritten from logiccast BitAND(ptr/struct/id) branches → GwAu3 Has*Flag helpers.

Func IsBossSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 1048576)
EndFunc   ;==>IsBossSkill

Func IsFlashEnchantFailureSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 8388672)
EndFunc   ;==>IsFlashEnchantFailureSkill

Func IsEliteFlashEnchantSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 8388612)
EndFunc   ;==>IsEliteFlashEnchantSkill

Func IsFlashEnchantSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 8388608)
EndFunc   ;==>IsFlashEnchantSkill

Func IsRezPveSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 526336)
EndFunc   ;==>IsRezPveSkill

Func IsHexDegenPveSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 524800)
EndFunc   ;==>IsHexDegenPveSkill

Func IsTrapPveSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 524576)
EndFunc   ;==>IsTrapPveSkill

Func IsRitualPveSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 524544)
EndFunc   ;==>IsRitualPveSkill

Func IsCapEliteSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 524304)
EndFunc   ;==>IsCapEliteSkill

Func IsElitePveSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 524292)
EndFunc   ;==>IsElitePveSkill

Func IsTouchPveSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 524290)
EndFunc   ;==>IsTouchPveSkill

Func IsPveSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 524288)
EndFunc   ;==>IsPveSkill

Func IsEliteExploitCorpseHealthRegenSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 262656)
EndFunc   ;==>IsEliteExploitCorpseHealthRegenSkill

Func IsEliteExploitCorpseFailureSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 262208)
EndFunc   ;==>IsEliteExploitCorpseFailureSkill

Func IsEliteExploitCorpseSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 262148)
EndFunc   ;==>IsEliteExploitCorpseSkill

Func IsExploitCorpseSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 262144)
EndFunc   ;==>IsExploitCorpseSkill

Func IsEliteOffHandSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 32772)
EndFunc   ;==>IsEliteOffHandSkill

Func IsOffHandSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 32768)
EndFunc   ;==>IsOffHandSkill

Func IsConditionSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 8192)
EndFunc   ;==>IsConditionSkill

Func IsFailureBelow8Skill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 4100)
EndFunc   ;==>IsFailureBelow8Skill

Func IsRessurectionSpiritSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 2304)
EndFunc   ;==>IsRessurectionSpiritSkill

Func IsRessurectionSpellHalfRangeSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 2056)
EndFunc   ;==>IsRessurectionSpellHalfRangeSkill

Func IsEliteRessurectionSpellSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 2052)
EndFunc   ;==>IsEliteRessurectionSpellSkill

Func IsTouchRessurectionSpellSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 2050)
EndFunc   ;==>IsTouchRessurectionSpellSkill

Func IsRessurectionSpellSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 2048)
EndFunc   ;==>IsRessurectionSpellSkill

Func IsEliteDegenHexSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 516)
EndFunc   ;==>IsEliteDegenHexSkill

Func IsDegenHexSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 512)
EndFunc   ;==>IsDegenHexSkill

Func IsPrepLessArmorWhileUsingSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 384)
EndFunc   ;==>IsPrepLessArmorWhileUsingSkill

Func IsSmokeTrapSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 292)
EndFunc   ;==>IsSmokeTrapSkill

Func IsTrapPiercingSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 288)
EndFunc   ;==>IsTrapPiercingSkill

Func IsElitePrepTrapRitualSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 260)
EndFunc   ;==>IsElitePrepTrapRitualSkill

Func IsPrepTrapRitualSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 256)
EndFunc   ;==>IsPrepTrapRitualSkill

Func IsLessArmorWhileUsingSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 128)
EndFunc   ;==>IsLessArmorWhileUsingSkill

Func IsEliteFailureBelow4Skill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 68)
EndFunc   ;==>IsEliteFailureBelow4Skill

Func IsFailureBelow4KnockSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 65)
EndFunc   ;==>IsFailureBelow4KnockSkill

Func IsFailureBelow4Skill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 64)
EndFunc   ;==>IsFailureBelow4Skill

Func IsEasilyInterruptedSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 32)
EndFunc   ;==>IsEasilyInterruptedSkill

Func IsEliteHalfRangeSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 12)
EndFunc   ;==>IsEliteHalfRangeSkill

Func IsHalfRangeSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 8)
EndFunc   ;==>IsHalfRangeSkill

Func IsEliteTouchSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 6)
EndFunc   ;==>IsEliteTouchSkill

Func IsEliteExhaustionSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 5)
EndFunc   ;==>IsEliteExhaustionSkill

Func IsEliteSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 4)
EndFunc   ;==>IsEliteSkill

Func IsExhaustionTouchSkillSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 3)
EndFunc   ;==>IsExhaustionTouchSkillSkill

Func IsExhaustionSkill($a_v_Skill)
	Return Skill_HasSpecialFlag(SkillID($a_v_Skill), 1)
EndFunc   ;==>IsExhaustionSkill

Func IsElementalAttunementSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 131072)
EndFunc   ;==>IsElementalAttunementSkill

Func IsKnockMySelfSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 65536)
EndFunc   ;==>IsKnockMySelfSkill

Func IsAttackAndSppedMoveSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 32768)
EndFunc   ;==>IsAttackAndSppedMoveSkill

Func IsReverseDamageSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 16384)
EndFunc   ;==>IsReverseDamageSkill

Func IsLooseEnchantAndHealAndRemoveHexSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 14336)
EndFunc   ;==>IsLooseEnchantAndHealAndRemoveHexSkill

Func IsLooseEnchantAndEnergyRegenSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 8448)
EndFunc   ;==>IsLooseEnchantAndEnergyRegenSkill

Func IsDervHealSignetWithRemoveDervEnchantSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 8198)
EndFunc   ;==>IsDervHealSignetWithRemoveDervEnchantSkill

Func IsDervHealWithRemoveDervEnchantAndHexSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 8196)
EndFunc   ;==>IsDervHealWithRemoveDervEnchantAndHexSkill

Func IsRemoveDervEnchantSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 8192)
EndFunc   ;==>IsRemoveDervEnchantSkill

Func IsHealAndConditionAndHexRemovalSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 6150)
EndFunc   ;==>IsHealAndConditionAndHexRemovalSkill

Func IsConditionAndHexRemovalSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 6144)
EndFunc   ;==>IsConditionAndHexRemovalSkill

Func IsConditionTransfertSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 4608)
EndFunc   ;==>IsConditionTransfertSkill

Func IsConditionRemovalSpecialSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 4102)
EndFunc   ;==>IsConditionRemovalSpecialSkill

Func IsHexRemovalWithEnergyGainSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 2304)
EndFunc   ;==>IsHexRemovalWithEnergyGainSkill

Func IsHexRemovalWithHealSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 2054)
EndFunc   ;==>IsHexRemovalWithHealSkill

Func IsEnchantOnAllyAffectEnemisSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 1024)
EndFunc   ;==>IsEnchantOnAllyAffectEnemisSkill

Func IsEnrgeyDegenSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 768)
EndFunc   ;==>IsEnrgeyDegenSkill

Func IsTouchSkillSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 544)
EndFunc   ;==>IsTouchSkillSkill

Func IsCloseRangeSpell2Skill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 516)
EndFunc   ;==>IsCloseRangeSpell2Skill

Func IsCloseRangeSpellSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 512)
EndFunc   ;==>IsCloseRangeSpellSkill

Func IsEnergyStealSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 320)
EndFunc   ;==>IsEnergyStealSkill

Func IsEnergyGainSpellSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 288)
EndFunc   ;==>IsEnergyGainSpellSkill

Func IsEnergyGainSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 256)
EndFunc   ;==>IsEnergyGainSkill

Func IsBlockSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 128)
EndFunc   ;==>IsBlockSkill

Func IsSacrReturniceHeal2Skill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 38)
EndFunc   ;==>IsSacrReturniceHeal2Skill

Func IsSacrReturniceHealSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 36)
EndFunc   ;==>IsSacrReturniceHealSkill

Func IsSacrReturniceSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 32)
EndFunc   ;==>IsSacrReturniceSkill

Func IsRezSignetSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 16)
EndFunc   ;==>IsRezSignetSkill

Func IsRezSkill($a_v_Skill)
	Return Skill_HasEffect2Flag(SkillID($a_v_Skill), 8)
EndFunc   ;==>IsRezSkill

Func CausesBleedingSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 1)
EndFunc   ;==>CausesBleedingSkill

Func CausesBlindSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 2)
EndFunc   ;==>CausesBlindSkill

Func CausesBurningSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 4)
EndFunc   ;==>CausesBurningSkill

Func CausesCrippleSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 8)
EndFunc   ;==>CausesCrippleSkill

Func CausesDeepWoundSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 16)
EndFunc   ;==>CausesDeepWoundSkill

Func CausesDiseaseSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 32)
EndFunc   ;==>CausesDiseaseSkill

Func CausesSlowerMoveSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 64)
EndFunc   ;==>CausesSlowerMoveSkill

Func CausesKnockdownSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 128)
EndFunc   ;==>CausesKnockdownSkill

Func CausesPoisonSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 256)
EndFunc   ;==>CausesPoisonSkill

Func CausesDazeSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 512)
EndFunc   ;==>CausesDazeSkill

Func CauseWeaknessSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 1024)
EndFunc   ;==>CauseWeaknessSkill

Func CauseWaterHexSkill($a_v_Skill)
	Return Skill_HasEffect1Flag(SkillID($a_v_Skill), 2048)
EndFunc   ;==>CauseWaterHexSkill

#EndRegion Skill bitflag wrappers

#Region RequireCondition wrappers
Func RequiresBleeding($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 1)
EndFunc   ;==>RequiresBleeding

Func RequiresBlind($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 2)
EndFunc   ;==>RequiresBlind

Func RequiresBurning($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 4)
EndFunc   ;==>RequiresBurning

Func RequiresCripple($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 8)
EndFunc   ;==>RequiresCripple

Func RequiresCrippleAndBleed($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 9)
EndFunc   ;==>RequiresCrippleAndBleed

Func SkillRequiresDeepwound($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 16)
EndFunc   ;==>SkillRequiresDeepwound

Func SkillRequiresDeepWoundAndBleed($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 17)
EndFunc   ;==>SkillRequiresDeepWoundAndBleed

Func SkillRequiresDisease($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 32)
EndFunc   ;==>SkillRequiresDisease

Func SkillRequiresEarthhex($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 64)
EndFunc   ;==>SkillRequiresEarthhex

Func RequiresKnockdown($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 128)
EndFunc   ;==>RequiresKnockdown

Func RequiresCrippleAndKnockDown($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 136)
EndFunc   ;==>RequiresCrippleAndKnockDown

Func RequiresPoison($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 256)
EndFunc   ;==>RequiresPoison

Func RequiresDaze($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 512)
EndFunc   ;==>RequiresDaze

Func RequiresDazeAndBlind($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 514)
EndFunc   ;==>RequiresDazeAndBlind

Func RequiresWeakness($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 1024)
EndFunc   ;==>RequiresWeakness

Func RequiresWeaknessAndDeepWound($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 1040)
EndFunc   ;==>RequiresWeaknessAndDeepWound

Func RequiresWeaknessAndKnockDown($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 1152)
EndFunc   ;==>RequiresWeaknessAndKnockDown

Func SkillRequiresWaterHex($a_v_Skill)
	Return Skill_HasRequireConditionFlag(SkillID($a_v_Skill), 2048)
EndFunc   ;==>SkillRequiresWaterHex

#EndRegion RequireCondition wrappers
