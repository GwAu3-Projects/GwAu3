#include-once
#include "UtilityAI_DynamicSkillCache.au3"

Global Enum $GC_UAI_CACHE_MODE_ALL = 0, $GC_UAI_CACHE_MODE_PLAYER

; Script Start - Add your code below here
Func Cache_SkillBar()
	If Not Map_GetInstanceInfo("IsExplorable") Then Return False

	UAI_CacheSkillBar()

	For $i = 1 To 8
		$g_as_BestTargetCache[$i] = UAI_GetBestTargetFunc($i)
		$g_as_CanUseCache[$i] = UAI_GetCanUseFunc($i)
	Next

	If $g_b_CacheWeaponSet Then UAI_DetermineWeaponSets()

	Return True
EndFunc   ;==>Cache_SkillBar

Func Cache_FormChangeBuild($a_i_SkillSlot)
	Switch UAI_GetStaticSkillInfo($a_i_SkillSlot, $GC_UAI_STATIC_SKILL_SkillID)
		Case $GC_I_SKILL_ID_URSAN_BLESSING, $GC_I_SKILL_ID_VOLFEN_BLESSING, $GC_I_SKILL_ID_RAVEN_BLESSING
			UAI_CacheSkillBar()
			Return True
		Case Else
			Return False
	EndSwitch
EndFunc

Func Cache_EndFormChangeBuild($a_i_SkillSlot)
	Switch UAI_GetStaticSkillInfo($a_i_SkillSlot, $GC_UAI_STATIC_SKILL_SkillID)
		Case $GC_I_SKILL_ID_URSAN_STRIKE, $GC_I_SKILL_ID_URSAN_RAGE, $GC_I_SKILL_ID_URSAN_ROAR, $GC_I_SKILL_ID_URSAN_FORCE, $GC_I_SKILL_ID_Totem_of_Man
			Return False
		Case $GC_I_SKILL_ID_RAVEN_TALONS, $GC_I_SKILL_ID_RAVEN_SWOOP, $GC_I_SKILL_ID_RAVEN_SHRIEK, $GC_I_SKILL_ID_Raven_Flight
			Return False
		Case $GC_I_SKILL_ID_VOLFEN_CLAW, $GC_I_SKILL_ID_VOLFEN_POUNCE, $GC_I_SKILL_ID_VOLFEN_BLOODLUST, $GC_I_SKILL_ID_VOLFEN_AGILITY
			Return False
		Case Else
			UAI_CacheSkillBar()
			Return True
	EndSwitch
EndFunc

Func UAI_UpdateAgentCache($a_f_AggroRange)
	UAI_CacheAgentInfo($a_f_AggroRange + 500)
	UAI_CacheAgentEffectsAndBonds()
	UAI_CacheAgentVisibleEffects()
	UAI_CacheDynamicSkillbarInfo()
EndFunc

Func UAI_UpdatePlayerCache()
	UAI_CachePlayerInfo()
	UAI_CachePlayerEffectsAndBonds()
	UAI_CachePlayerVisibleEffects()
	UAI_CacheDynamicSkillbarInfo()
EndFunc

Func UAI_ResetRuntime()
	$g_i_BestTarget = 0
	$g_i_ForceTarget = 0
	$g_i_AttackTarget = 0
	$g_i_LastCalledTarget = 0

	$g_b_SkillChanged = False
	$g_b_CanUseSkill = True

	Global $g_as_BestTargetCache[9]
	Global $g_as_CanUseCache[9]
	Global $g_amx2_DynamicSkillCache[$GC_UAI_DYNAMIC_SKILL_SLOTS + 1][$GC_UAI_DYNAMIC_SKILL_COUNT]
	$g_p_StaticSkillbarPtr = 0

	$g_i_LastFeederEnchTimestamp = 0
EndFunc