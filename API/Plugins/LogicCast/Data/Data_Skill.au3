#include-once
; Pre-staging skill Data helpers for Modules review.
; Prefer Skill_GetSkillInfo / Skill_Is*Type (offsets unchanged in Reforged).

Func Logic_SkillID($aSkill)
	If IsPtr($aSkill) Then Return Skill_GetSkillInfo($aSkill, "SkillID")
	If IsDllStruct($aSkill) Then Return DllStructGetData($aSkill, "ID")
	Return $aSkill
EndFunc

Func GetSkillID($aSkill)
	Return Logic_SkillID($aSkill)
EndFunc

; --- SkillType wrappers (Logic names → Modules Skill_Is*Type) ---
Func IsHexSpell($aSkill)
	Return Skill_IsHexType(Logic_SkillID($aSkill))
EndFunc

Func IsConditionSpell($aSkill)
	Return Skill_IsConditionType(Logic_SkillID($aSkill))
EndFunc

Func IsRitualSkill($aSkill)
	Return Skill_IsRitualType(Logic_SkillID($aSkill))
EndFunc

Func IsWeaponSpell($aSkill)
	Return Skill_IsWeaponSpellType(Logic_SkillID($aSkill))
EndFunc

Func IsEnchantmentSkill($aSkill)
	Return Skill_IsEnchantmentType(Logic_SkillID($aSkill))
EndFunc

Func IsAttackSkill($aSkill)
	Return Skill_IsAttackType(Logic_SkillID($aSkill))
EndFunc

Func IsStanceskill($aSkill)
	Return Skill_IsStanceType(Logic_SkillID($aSkill))
EndFunc

Func Skill_IsSpellskill($aSkill)
	Return Skill_IsSpellType(Logic_SkillID($aSkill))
EndFunc

Func IsSignetskill($aSkill)
	Return Skill_IsSignetType(Logic_SkillID($aSkill))
EndFunc

Func IsWellskill($aSkill)
	Return Skill_IsWellType(Logic_SkillID($aSkill))
EndFunc

Func IsSkill($aSkill)
	Return Skill_IsSkillType(Logic_SkillID($aSkill))
EndFunc

Func IsWardskill($aSkill)
	Return Skill_IsWardType(Logic_SkillID($aSkill))
EndFunc

Func IsGlyphskill($aSkill)
	Return Skill_IsGlyphType(Logic_SkillID($aSkill))
EndFunc

Func IsShoutskill($aSkill)
	Return Skill_IsShoutType(Logic_SkillID($aSkill))
EndFunc

Func IsPreparationskill($aSkill)
	Return Skill_IsPreparationType(Logic_SkillID($aSkill))
EndFunc

Func IsTrapskill($aSkill)
	Return Skill_IsTrapType(Logic_SkillID($aSkill))
EndFunc

Func IsItemSpellskill($aSkill)
	Return Skill_IsItemSpellType(Logic_SkillID($aSkill))
EndFunc

Func IsChantskill($aSkill)
	Return Skill_IsChantType(Logic_SkillID($aSkill))
EndFunc

Func IsEchoRefrainskill($aSkill)
	Return Skill_IsEchoType(Logic_SkillID($aSkill))
EndFunc

Func IsDisguiseskill($aSkill)
	Return Skill_IsDisguiseType(Logic_SkillID($aSkill))
EndFunc

; Special-bit / custom-list Is* remain in logiccast until migrated to Skill_Is*Special.
