#include-once

Func Anti_Hex()
	;~ Check if target is spirit
	If UAI_Filter_IsSpirit($g_i_BestTarget) Then Return True ;can't cast hex on spirit

	;~ Generic hex checks
	If Not UAI_GetPlayerInfo($GC_UAI_AGENT_IsHexed) Then Return False

	;~ Specific hex checks
	If UAI_PlayerHasEffect($GC_I_SKILL_ID_GUILT) Then Return True
	If UAI_PlayerHasEffect($GC_I_SKILL_ID_MISTRUST) Then Return True
	If UAI_PlayerHasEffect($GC_I_SKILL_ID_DIVERSION) Then Return True

	;~ Check for hexes that punish casting by damage
	Local $l_i_IncomingDamage = 0
	If UAI_PlayerHasEffect($GC_I_SKILL_ID_BACKFIRE) Then $l_i_IncomingDamage += UAI_GetPlayerEffectInfo($GC_I_SKILL_ID_BACKFIRE, $GC_UAI_EFFECT_Scale)
	If UAI_PlayerHasEffect($GC_I_SKILL_ID_VISIONS_OF_REGRET) Then
		$l_i_IncomingDamage += UAI_GetPlayerEffectInfo($GC_I_SKILL_ID_VISIONS_OF_REGRET, $GC_UAI_EFFECT_Scale)
		If Not UAI_PlayerHasOtherMesmerHex($GC_I_SKILL_ID_VISIONS_OF_REGRET) Then $l_i_IncomingDamage += Effect_GetEffectArg($GC_I_SKILL_ID_VISIONS_OF_REGRET, $GC_UAI_EFFECT_BonusScale)
	EndIf
	If UAI_PlayerHasEffect($GC_I_SKILL_ID_SOUL_LEECH) Then $l_i_IncomingDamage += UAI_GetPlayerEffectInfo($GC_I_SKILL_ID_SOUL_LEECH, $GC_UAI_EFFECT_Scale)
	If UAI_PlayerHasEffect($GC_I_SKILL_ID_SPITEFUL_SPIRIT) Then $l_i_IncomingDamage += UAI_GetPlayerEffectInfo($GC_I_SKILL_ID_SPITEFUL_SPIRIT, $GC_UAI_EFFECT_Scale)
	If UAI_PlayerHasEffect($GC_I_SKILL_ID_SPOIL_VICTOR) And UAI_GetAgentInfoByID($g_i_BestTarget, $GC_UAI_AGENT_HP) < UAI_GetPlayerInfo($GC_UAI_AGENT_HP) Then
		$l_i_IncomingDamage += UAI_GetPlayerEffectInfo($GC_I_SKILL_ID_SPOIL_VICTOR, $GC_UAI_EFFECT_Scale)
	EndIf

	Return ($l_i_IncomingDamage > (UAI_GetPlayerInfo($GC_UAI_AGENT_CurrentHP) + UAI_GetPlayerInfo($GC_UAI_AGENT_MaxHP * 0.15)))
EndFunc

; Skill ID: 19 - $GC_I_SKILL_ID_FRAGILITY
Func CanUse_Fragility()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Fragility($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes adjacent to target (8...18...20 seconds). These foes take 5...17...20 damage each time they gain or lose a condition.
	; Concise description
	; Spell. Also hexes foes adjacent to target (8...18...20 seconds). These foes take 5...17...20 damage each time they gain or lose a condition.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 20 - $GC_I_SKILL_ID_CONFUSION
Func CanUse_Confusion()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Confusion($a_f_AggroRange)
	; Description
	; Hex Spell. (8...18...21 seconds.) Target foe's attacks may damage any character in range, including the target.
	; Concise description
	; Spell. (8...18...21 seconds.) Target foe's attacks may damage any character in range, including the target.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 26 - $GC_I_SKILL_ID_EMPATHY
Func CanUse_Empathy()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Empathy($a_f_AggroRange)
	; Description
	; Hex Spell. (5...13...15 seconds.) Target foe's attacks deal 1...12...15 less damage, and that foe takes 10...46...55 damage with each attack.
	; Concise description
	; Spell. (5...13...15 seconds.) Target foe's attacks deal 1...12...15 less damage, and that foe takes 10...46...55 damage with each attack.
	; Target attacking enemies for maximum effect
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 28 - $GC_I_SKILL_ID_BACKFIRE
Func CanUse_Backfire()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Backfire($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Target foe takes 35...119...140 damage whenever it casts a spell.
	; Concise description
	; Spell. (10 seconds.) Target foe takes 35...119...140 damage whenever it casts a spell.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 30 - $GC_I_SKILL_ID_DIVERSION
Func CanUse_Diversion()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Diversion($a_f_AggroRange)
	; Description
	; Hex Spell. (6 seconds.) Target foe's next skill takes +10...47...56 seconds to recharge.
	; Concise description
	; Spell. (6 seconds.) Target foe's next skill takes +10...47...56 seconds to recharge.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 31 - $GC_I_SKILL_ID_CONJURE_PHANTASM
Func CanUse_ConjurePhantasm()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ConjurePhantasm($a_f_AggroRange)
	; Description
	; Hex Spell. (2...13...16 seconds.) Causes -5 Health degeneration.
	; Concise description
	; Spell. (2...13...16 seconds.) Causes -5 Health degeneration.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 35 - $GC_I_SKILL_ID_IGNORANCE
Func CanUse_Ignorance()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Ignorance($a_f_AggroRange)
	; Description
	; Hex Spell. (8...18...20 seconds.) Target foe cannot use signets.
	; Concise description
	; Spell. (8...18...20 seconds.) Target foe cannot use signets.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 36 - $GC_I_SKILL_ID_ARCANE_CONUNDRUM
Func CanUse_ArcaneConundrum()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ArcaneConundrum($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 41 - $GC_I_SKILL_ID_ETHER_LORD
Func CanUse_EtherLord()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EtherLord($a_f_AggroRange)
	; Description
	; Hex Spell. You lose all Energy. Target foe has -1...3...3 Energy degeneration and you have +1...3...3 Energy regeneration (5...9...10 seconds).
	; Concise description
	; Spell. You lose all Energy. Target foe has -1...3...3 Energy degeneration and you have +1...3...3 Energy regeneration (5...9...10 seconds).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 43 - $GC_I_SKILL_ID_CLUMSINESS
Func CanUse_Clumsiness()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Clumsiness($a_f_AggroRange)
	; Description
	; Hex Spell. (4 seconds.) Also hexes adjacent foes. Interrupts next attack. Interruption effect: deals 10...76...92 damage.
	; Concise description
	; Spell. (4 seconds.) Also hexes adjacent foes. Interrupts next attack. Interruption effect: deals 10...76...92 damage.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 44 - $GC_I_SKILL_ID_PHANTOM_PAIN
Func CanUse_PhantomPain()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PhantomPain($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Causes -1...3...4 Health degeneration. End effect: inflicts Deep Wound condition (5...17...20 seconds).
	; Concise description
	; Spell. (10 seconds.) Causes -1...3...4 Health degeneration. End effect: inflicts Deep Wound condition (5...17...20 seconds).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 45 - $GC_I_SKILL_ID_ETHEREAL_BURDEN
Func CanUse_EtherealBurden()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EtherealBurden($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Target foe moves 50% slower. End effect: you gain 10...16...18 Energy.
	; Concise description
	; Spell. (10 seconds.) Target foe moves 50% slower. End effect: you gain 10...16...18 Energy.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 46 - $GC_I_SKILL_ID_GUILT
Func CanUse_Guilt()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Guilt($a_f_AggroRange)
	; Description
	; Hex Spell. (6 seconds.) Target foe's next spell fails and you steal 5...12...14 Energy. No effect unless this foe's spell targets one of your allies.
	; Concise description
	; Spell. (6 seconds.) Target foe's next spell fails and you steal 5...12...14 Energy. No effect unless this foe's spell targets one of your allies.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 47 - $GC_I_SKILL_ID_INEPTITUDE
Func CanUse_Ineptitude()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Ineptitude($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (4 seconds.) Also hexes foes adjacent to target. Deals 30...114...135 damage. Inflicts Blindness condition (10 seconds). No effect unless hexed foe attacks.
	; Concise description
	; Hex Spell. (4 seconds.) Also hexes foes adjacent to target. Deals 30...114...135 damage. Inflicts Blindness condition (10 seconds). No effect unless hexed foe attacks.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 48 - $GC_I_SKILL_ID_SPIRIT_OF_FAILURE
Func CanUse_SpiritOfFailure()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpiritOfFailure($a_f_AggroRange)
	; Description
	; Hex Spell. (30 seconds.) Target foe has 25% chance to miss. You gain 1...3...3 Energy whenever this foe misses.
	; Concise description
	; Spell. (30 seconds.) Target foe has 25% chance to miss. You gain 1...3...3 Energy whenever this foe misses.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 49 - $GC_I_SKILL_ID_MIND_WRACK
Func CanUse_MindWrack()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MindWrack($a_f_AggroRange)
	; Description
	; Hex Spell. (5...33...40 seconds.) Causes 1 Energy loss each time foe is the target of your non-hex Mesmer skills. Deals 5...21...25 damage per point of Energy lost. If target foe's Energy drops to 0, it takes 15...83...100 damage and Mind Wrack ends.
	; Concise description
	; Spell. (5...33...40 seconds.) Causes 1 Energy loss each time foe is the target of your non-hex Mesmer skills. Deals 5...21...25 damage per point of Energy lost. If target foe's Energy drops to 0, it takes 15...83...100 damage and Mind Wrack ends.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 50 - $GC_I_SKILL_ID_WASTRELS_WORRY
Func CanUse_WastrelsWorry()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WastrelsWorry($a_f_AggroRange)
	; Description
	; Hex Spell. (3 seconds). End effect: causes 20...84...100 damage to target and adjacent foes. No effect and ends early if target foe uses a skill.
	; Concise description
	; Spell. (3 seconds). End effect: causes 20...84...100 damage to target and adjacent foes. No effect and ends early if target foe uses a skill.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 51 - $GC_I_SKILL_ID_SHAME
Func CanUse_Shame()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Shame($a_f_AggroRange)
	; Description
	; Hex Spell. (6 seconds.) Target foe's next spell fails and you steal 5...12...14 Energy. No effect unless this foe's spell targeted one of its allies.
	; Concise description
	; Spell. (6 seconds.) Target foe's next spell fails and you steal 5...12...14 Energy. No effect unless this foe's spell targeted one of its allies.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 52 - $GC_I_SKILL_ID_PANIC
Func CanUse_Panic()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Panic($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Also hexes foes near your target (1...8...10 second[s]). Interrupts all other nearby foes whenever a hexed foe successfully activates a skill.
	; Concise description
	; Hex Spell. Also hexes foes near your target (1...8...10 second[s]). Interrupts all other nearby foes whenever a hexed foe successfully activates a skill.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 53 - $GC_I_SKILL_ID_MIGRAINE
Func CanUse_Migraine()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Migraine($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (5...17...20 seconds.) Causes -1...7...8 Health degeneration and doubles skill activation time.
	; Concise description
	; Hex Spell. (5...17...20 seconds.) Causes -1...7...8 Health degeneration and doubles skill activation time.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 54 - $GC_I_SKILL_ID_CRIPPLING_ANGUISH
Func CanUse_CripplingAnguish()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CripplingAnguish($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (5...17...20 seconds.) Target foe moves and attacks 50% slower and has -1...7...8 Health degeneration.
	; Concise description
	; Hex Spell. (5...17...20 seconds.) Target foe moves and attacks 50% slower and has -1...7...8 Health degeneration.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 55 - $GC_I_SKILL_ID_FEVERED_DREAMS
Func CanUse_FeveredDreams()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_FeveredDreams($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (10...22...25 seconds.) Foes in the area also have any new conditions that target foe acquires. Inflicts Dazed on target foe (1...3...3 second[s]) if that foe has two or more conditions.
	; Concise description
	; Hex Spell. (10...22...25 seconds.) Foes in the area also have any new conditions that target foe acquires. Inflicts Dazed on target foe (1...3...3 second[s]) if that foe has two or more conditions.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 56 - $GC_I_SKILL_ID_SOOTHING_IMAGES
Func CanUse_SoothingImages()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SoothingImages($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foe adjacent to target. (8...18...20 seconds). These foes cannot gain adrenaline.
	; Concise description
	; Spell. Also hexes foe adjacent to target. (8...18...20 seconds). These foes cannot gain adrenaline.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 66 - $GC_I_SKILL_ID_SPIRIT_SHACKLES
Func CanUse_SpiritShackles()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpiritShackles($a_f_AggroRange)
	; Description
	; Hex Spell. (5...17...20). Target foe loses 5 Energy whenever it attacks.
	; Concise description
	; Spell. (5...17...20). Target foe loses 5 Energy whenever it attacks.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 76 - $GC_I_SKILL_ID_IMAGINED_BURDEN
Func CanUse_ImaginedBurden()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ImaginedBurden($a_f_AggroRange)
	; Description
	; Hex Spell. (8...18...20 seconds.) Target foe moves 50% slower.
	; Concise description
	; Spell. (8...18...20 seconds.) Target foe moves 50% slower.
	; Target moving enemies for snare effect
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 99 - $GC_I_SKILL_ID_PARASITIC_BOND
Func CanUse_ParasiticBond()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ParasiticBond($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) Causes -1 Health degeneration. End effect: you are healed for 30...102...120 Health.
	; Concise description
	; Spell. (20 seconds.) Causes -1 Health degeneration. End effect: you are healed for 30...102...120 Health.
	Return UAI_GetBestSingleTarget(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|-UAI_Filter_IsHexed")
EndFunc

; Skill ID: 100 - $GC_I_SKILL_ID_SOUL_BARBS
Func CanUse_SoulBarbs()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SoulBarbs($a_f_AggroRange)
	; Description
	; Hex Spell. (30 seconds.) Deals 15...27...30 damage when an enchantment or hex is cast on target foe.
	; Concise description
	; Spell. (30 seconds.) Deals 15...27...30 damage when an enchantment or hex is cast on target foe.
	Return UAI_GetNearestAgent(-2, $a_f_AggroRange, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 101 - $GC_I_SKILL_ID_BARBS
Func CanUse_Barbs()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Barbs($a_f_AggroRange)
	; Description
	; Hex Spell. (30 seconds.) Target foe takes 1...12...15 damage whenever it takes physical damage.
	; Concise description
	; Spell. (30 seconds.) Target foe takes 1...12...15 damage whenever it takes physical damage.
	; Target attacking enemies for maximum effect
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 103 - $GC_I_SKILL_ID_PRICE_OF_FAILURE
Func CanUse_PriceOfFailure()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PriceOfFailure($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) Also hexes nearby foes. The next skill used by target foes cost 25 Energy and recharges in 90 seconds.
	; Concise description
	; Spell. (20 seconds.) Also hexes nearby foes. The next skill used by target foes cost 25 Energy and recharges in 90 seconds.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 108 - $GC_I_SKILL_ID_SUFFERING
Func CanUse_Suffering()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Suffering($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes near target (6...25...30 seconds). These foes have -0...2...3 Health degeneration.
	; Concise description
	; Spell. Also hexes foes near target (6...25...30 seconds). These foes have -0...2...3 Health degeneration.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 109 - $GC_I_SKILL_ID_LIFE_SIPHON
Func CanUse_LifeSiphon()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_LifeSiphon($a_f_AggroRange)
	; Description
	; Hex Spell. (12...22...24 seconds.) Target foe has -1...3...3 Health degeneration. You have +1...3...3 Health regeneration.
	; Concise description
	; Spell. (12...22...24 seconds.) Target foe has -1...3...3 Health degeneration. You have +1...3...3 Health regeneration.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 121 - $GC_I_SKILL_ID_SPITEFUL_SPIRIT
Func CanUse_SpitefulSpirit()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpitefulSpirit($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (8...18...20 seconds.) Deals 5...29...35 damage to target and adjacent foes whenever this foe attacks or uses a skill.
	; Concise description
	; Hex Spell. (8...18...20 seconds.) Deals 5...29...35 damage to target and adjacent foes whenever this foe attacks or uses a skill.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 122 - $GC_I_SKILL_ID_MALIGN_INTERVENTION
Func CanUse_MalignIntervention()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MalignIntervention($a_f_AggroRange)
	; Description
	; Hex Spell. (5...17...20 seconds.) Target foe receives 20% less from healing. If this foe dies while suffering from this hex, a level 1...14...17 masterless bone horror is summoned.
	; Concise description
	; Spell. (5...17...20 seconds.) Target foe receives 20% less from healing. If this foe dies while suffering from this hex, a level 1...14...17 masterless bone horror is summoned.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 123 - $GC_I_SKILL_ID_INSIDIOUS_PARASITE
Func CanUse_InsidiousParasite()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_InsidiousParasite($a_f_AggroRange)
	; Description
	; Hex Spell. (5...13...15 seconds.) Steal 15...39...45 Health whenever target foe hits with an attack.
	; Concise description
	; Spell. (5...13...15 seconds.) Steal 15...39...45 Health whenever target foe hits with an attack.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 124 - $GC_I_SKILL_ID_SPINAL_SHIVERS
Func CanUse_SpinalShivers()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpinalShivers($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 125 - $GC_I_SKILL_ID_WITHER
Func CanUse_Wither()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Wither($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (5...29...35 seconds.) Causes -2...4...4 Health degeneration and -1 Energy degeneration. Deals 15...63...75 damage if target foe's Energy drops to 0. Ends if this foe's Energy drops to 0.
	; Concise description
	; Hex Spell. (5...29...35 seconds.) Causes -2...4...4 Health degeneration and -1 Energy degeneration. Deals 15...63...75 damage if target foe's Energy drops to 0. Ends if this foe's Energy drops to 0.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 126 - $GC_I_SKILL_ID_LIFE_TRANSFER
Func CanUse_LifeTransfer()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_LifeTransfer($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Also hexes foes adjacent to target (6...11...12 second). Causes -3...7...8 Health degeneration. You have +3...7...8 Health regeneration.
	; Concise description
	; Hex Spell. Also hexes foes adjacent to target (6...11...12 second). Causes -3...7...8 Health degeneration. You have +3...7...8 Health regeneration.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 127 - $GC_I_SKILL_ID_MARK_OF_SUBVERSION
Func CanUse_MarkOfSubversion()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MarkOfSubversion($a_f_AggroRange)
	; Description
	; Hex Spell. (6 seconds.) Target foe's next spell fails and you steal 10...76...92 Health. No effect unless this foe's spell targeted one of its allies.
	; Concise description
	; Spell. (6 seconds.) Target foe's next spell fails and you steal 10...76...92 Health. No effect unless this foe's spell targeted one of its allies.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 128 - $GC_I_SKILL_ID_SOUL_LEECH
Func CanUse_SoulLeech()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SoulLeech($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (10 seconds.) Steal 16...67...80 Health whenever target foe casts a spell.
	; Concise description
	; Hex Spell. (10 seconds.) Steal 16...67...80 Health whenever target foe casts a spell.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 129 - $GC_I_SKILL_ID_DEFILE_FLESH
Func CanUse_DefileFlesh()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_DefileFlesh($a_f_AggroRange)
	; Description
	; Hex Spell. (5...29...35 seconds.) Reduces healing target foe receives by 33%. Only skills with the word "heal" in the description are affected.
	; Concise description
	; Spell. (5...29...35 seconds.) Reduces healing target foe receives by 33%. Only skills with the word "heal" in the description are affected.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 135 - $GC_I_SKILL_ID_FAINTHEARTEDNESS
Func CanUse_Faintheartedness()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Faintheartedness($a_f_AggroRange)
	; Description
	; Hex Spell. (3...13...16 seconds.) Target foe attacks 50% slower and has -0...2...3 Health degeneration.
	; Concise description
	; Spell. (3...13...16 seconds.) Target foe attacks 50% slower and has -0...2...3 Health degeneration.
	; Target attacking enemies for maximum effect
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 136 - $GC_I_SKILL_ID_SHADOW_OF_FEAR
Func CanUse_ShadowOfFear()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShadowOfFear($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes adjacent to target (5...25...30 seconds). They attack 50% slower.
	; Concise description
	; Spell. Also hexes foes adjacent to target (5...25...30 seconds). They attack 50% slower.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 137 - $GC_I_SKILL_ID_RIGOR_MORTIS
Func CanUse_RigorMortis()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_RigorMortis($a_f_AggroRange)
	; Description
	; Hex Spell. (8...18...20 seconds.) Target foe cannot block.
	; Concise description
	; Spell. (8...18...20 seconds.) Target foe cannot block.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 140 - $GC_I_SKILL_ID_MALAISE
Func CanUse_Malaise()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Malaise($a_f_AggroRange)
	; Description
	; Hex Spell. (5...29...35 seconds.) Causes -1 Energy degeneration. Deals 5...41...50 damage if target foe's Energy drops to 0. You have -1 Health degeneration. Ends if this foe's Energy drops to 0.
	; Concise description
	; Spell. (5...29...35 seconds.) Causes -1 Energy degeneration. Deals 5...41...50 damage if target foe's Energy drops to 0. You have -1 Health degeneration. Ends if this foe's Energy drops to 0.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 142 - $GC_I_SKILL_ID_LINGERING_CURSE
Func CanUse_LingeringCurse()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_LingeringCurse($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (6...25...30 seconds.) Target and nearby foes have -0...2...3 Health degeneration and receive 20% less benefit from healing.
	; Concise description
	; Hex Spell. (6...25...30 seconds.) Target and nearby foes have -0...2...3 Health degeneration and receive 20% less benefit from healing.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 150 - $GC_I_SKILL_ID_MARK_OF_PAIN
Func CanUse_MarkOfPain()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MarkOfPain($a_f_AggroRange)
	; Description
	; Hex Spell. (30 seconds.) Deals 10...34...40 damage to adjacent foes whenever target foe takes physical damage.
	; Concise description
	; Spell. (30 seconds.) Deals 10...34...40 damage to adjacent foes whenever target foe takes physical damage.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 173 - $GC_I_SKILL_ID_GRASPING_EARTH
Func CanUse_GraspingEarth()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_GraspingEarth($a_f_AggroRange)
	; Description
	; Hex Spell. Hexes foes near you for (5...17...20 seconds). These foes move 50% slower.
	; Concise description
	; Spell. Hexes foes near you for (5...17...20 seconds). These foes move 50% slower.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 179 - $GC_I_SKILL_ID_INCENDIARY_BONDS
Func CanUse_IncendiaryBonds()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_IncendiaryBonds($a_f_AggroRange)
	; Description
	; Hex Spell. (3 seconds.) End effect: deals 20...68...80 fire damage and inflicts Burning condition (1...3...3 second[s]) to foes near your target. Also triggers if foe dies.
	; Concise description
	; Spell. (3 seconds.) End effect: deals 20...68...80 fire damage and inflicts Burning condition (1...3...3 second[s]) to foes near your target. Also triggers if foe dies.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 190 - $GC_I_SKILL_ID_MARK_OF_RODGORT
Func CanUse_MarkOfRodgort()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MarkOfRodgort($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes near your target (10...30...35 seconds). Inflicts Burning condition (1...3...4 second[s]) when these foes take fire damage.
	; Concise description
	; Spell. Also hexes foes near your target (10...30...35 seconds). Inflicts Burning condition (1...3...4 second[s]) when these foes take fire damage.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 204 - $GC_I_SKILL_ID_RUST
Func CanUse_Rust()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Rust($a_f_AggroRange)
	; Description
	; Hex Spell. Deals 10...58...70 cold damage to target and adjacent foes. Hexes target and adjacent foes (5...17...20 seconds). Doubles signet activation time. Interrupts and disables signets for 1...8...10 second[s] if you are Overcast.
	; Concise description
	; Spell. Deals 10...58...70 cold damage to target and adjacent foes. Hexes target and adjacent foes (5...17...20 seconds). Doubles signet activation time. Interrupts and disables signets for 1...8...10 second[s] if you are Overcast.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 205 - $GC_I_SKILL_ID_LIGHTNING_SURGE
Func CanUse_LightningSurge()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_LightningSurge($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (3 seconds.) End effect: deals 14...83...100 lightning damage, causes knock-down, and inflicts Cracked Armor (5...17...20 seconds). 25% armor penetration.
	; Concise description
	; Hex Spell. (3 seconds.) End effect: deals 14...83...100 lightning damage, causes knock-down, and inflicts Cracked Armor (5...17...20 seconds). 25% armor penetration.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 209 - $GC_I_SKILL_ID_MIND_FREEZE
Func CanUse_MindFreeze()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MindFreeze($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Deals 10...50...60 cold damage. If you have more Energy than target foe, deals +10...50...60 cold damage and causes 90% slower movement (1...4...5 second[s]).
	; Concise description
	; Hex Spell. Deals 10...50...60 cold damage. If you have more Energy than target foe, deals +10...50...60 cold damage and causes 90% slower movement (1...4...5 second[s]).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 210 - $GC_I_SKILL_ID_ICE_PRISON
Func CanUse_IcePrison()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_IcePrison($a_f_AggroRange)
	; Description
	; Hex Spell. (8...18...20 seconds.) Target foe moves 66% slower.
	; Concise description
	; Spell. (8...18...20 seconds.) Target foe moves 66% slower.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 211 - $GC_I_SKILL_ID_ICE_SPIKES
Func CanUse_IceSpikes()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_IceSpikes($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes adjacent to target (2...5...6 seconds). These foes move 66% slower. Initial effect: deals 20...68...80 cold damage.
	; Concise description
	; Spell. Also hexes foes adjacent to target (2...5...6 seconds). These foes move 66% slower. Initial effect: deals 20...68...80 cold damage.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 212 - $GC_I_SKILL_ID_FROZEN_BURST
Func CanUse_FrozenBurst()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_FrozenBurst($a_f_AggroRange)
	; Description
	; Hex Spell. Hexes foes near you. These foes move 66% slower (3...7...8 seconds). Initial effect: deals 10...70...85 cold damage to foes near you.
	; Concise description
	; Spell. Hexes foes near you. These foes move 66% slower (3...7...8 seconds). Initial effect: deals 10...70...85 cold damage to foes near you.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 213 - $GC_I_SKILL_ID_SHARD_STORM
Func CanUse_ShardStorm()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShardStorm($a_f_AggroRange)
	; Description
	; Hex Spell. Projectile: deals 10...70...85 cold damage. Target foe moves 66% slower (2...5...6 seconds).
	; Concise description
	; Spell. Projectile: deals 10...70...85 cold damage. Target foe moves 66% slower (2...5...6 seconds).
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 222 - $GC_I_SKILL_ID_LIGHTNING_STRIKE
Func CanUse_LightningStrike()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_LightningStrike($a_f_AggroRange)
	; Description
	; Hex Spell. Deals 5...41...50 lightning damage. 25% armor penetration. Hex for 3 seconds if Overcast. End effect: deals 5...41...50 lightning damage.
	; Concise description
	; Spell. Deals 5...41...50 lightning damage. 25% armor penetration. Hex for 3 seconds if Overcast. End effect: deals 5...41...50 lightning damage.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 227 - $GC_I_SKILL_ID_GLIMMERING_MARK
Func CanUse_GlimmeringMark()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_GlimmeringMark($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 234 - $GC_I_SKILL_ID_DEEP_FREEZE
Func CanUse_DeepFreeze()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_DeepFreeze($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes in the area of your target (10 seconds). These foes move 66% slower. Initial effect: deals 10...70...85 cold damage.
	; Concise description
	; Spell. Also hexes foes in the area of your target (10 seconds). These foes move 66% slower. Initial effect: deals 10...70...85 cold damage.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_AREA, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 235 - $GC_I_SKILL_ID_BLURRED_VISION
Func CanUse_BlurredVision()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_BlurredVision($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes adjacent to target (4...9...10 seconds). They have 50% chance to miss.
	; Concise description
	; Spell. Also hexes foes adjacent to target (4...9...10 seconds). They have 50% chance to miss.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 251 - $GC_I_SKILL_ID_SCOURGE_HEALING
Func CanUse_ScourgeHealing()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ScourgeHealing($a_f_AggroRange)
	; Description
	; Hex Spell. (30 seconds.) Whenever target foe is healed, the healer takes 15...67...80 holy damage.
	; Concise description
	; Spell. (30 seconds.) Whenever target foe is healed, the healer takes 15...67...80 holy damage.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 253 - $GC_I_SKILL_ID_SCOURGE_SACRIFICE
Func CanUse_ScourgeSacrifice()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ScourgeSacrifice($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes adjacent to target (8...18...20 seconds). Doubles Health sacrifice.
	; Concise description
	; Spell. Also hexes foes adjacent to target (8...18...20 seconds). Doubles Health sacrifice.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 264 - $GC_I_SKILL_ID_PACIFISM
Func CanUse_Pacifism()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Pacifism($a_f_AggroRange)
	; Description
	; Hex Spell. (8...18...20 seconds.) Target foe cannot attack. Ends if this foe takes damage.
	; Concise description
	; Spell. (8...18...20 seconds.) Target foe cannot attack. Ends if this foe takes damage.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 265 - $GC_I_SKILL_ID_AMITY
Func CanUse_Amity()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Amity($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (8...18...20 seconds.) Foes adjacent to you cannot attack. Ends on any foes that take damage.
	; Concise description
	; Hex Spell. (8...18...20 seconds.) Foes adjacent to you cannot attack. Ends on any foes that take damage.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 505 - $GC_I_SKILL_ID_BURDEN_TOTEM
Func CanUse_BurdenTotem()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_BurdenTotem($a_f_AggroRange)
	; Description
	; Hex Spell. (30 seconds.) Target foe moves 33% slower.
	; Concise description
	; Spell. (30 seconds.) Target foe moves 33% slower.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 533 - $GC_I_SKILL_ID_CRYSTAL_HAZE
Func CanUse_CrystalHaze()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CrystalHaze($a_f_AggroRange)
	; Description
	; Hex Spell. (monster only) (30 seconds.) Also affects foes near target. Causes -1 Energy degeneration. Causes 10 Overcast whenever foes use an Energy skill.
	; Concise description
	; Spell. (monster only) (30 seconds.) Also affects foes near target. Causes -1 Energy degeneration. Causes 10 Overcast whenever foes use an Energy skill.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 534 - $GC_I_SKILL_ID_CRYSTAL_BONDS
Func CanUse_CrystalBonds()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CrystalBonds($a_f_AggroRange)
	; Description
	; Hex Spell. (monster only) Remove 1 enchantment. Target foe has reduced movement (15 seconds) and may not be the target of enchantments.
	; Concise description
	; Spell. (monster only) Remove 1 enchantment. Target foe has reduced movement (15 seconds) and may not be the target of enchantments.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsEnchanted")
EndFunc

; Skill ID: 542 - $GC_I_SKILL_ID_ORACLE_LINK
Func CanUse_OracleLink()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_OracleLink($a_f_AggroRange)
	; Description
	; Hex Spell. You share a portion of your Energy regeneration with the Oracle.
	; Concise description
	; Spell. You share a portion of your Energy regeneration with the Oracle.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 567 - $GC_I_SKILL_ID_SPONTANEOUS_COMBUSTION
Func CanUse_SpontaneousCombustion()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpontaneousCombustion($a_f_AggroRange)
	; Description
	; Hex Spell. Target starts burning and explodes.
	; Concise description
	; Spell. Target starts burning and explodes.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 570 - $GC_I_SKILL_ID_MARK_OF_INSECURITY
Func CanUse_MarkOfInsecurity()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MarkOfInsecurity($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (5...21...25 seconds.) Causes 1...3...3 Health degeneration. Enchantments and stances expire 30...70...80% faster on target foe. Disables your non-Assassin skills (10 seconds).
	; Concise description
	; Hex Spell. (5...21...25 seconds.) Causes 1...3...3 Health degeneration. Enchantments and stances expire 30...70...80% faster on target foe. Disables your non-Assassin skills (10 seconds).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 764 - $GC_I_SKILL_ID_WAIL_OF_DOOM
Func CanUse_WailOfDoom()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WailOfDoom($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (1...3...4 second[s].) Target foe's attributes are 0.
	; Concise description
	; Hex Spell. (1...3...4 second[s].) Target foe's attributes are 0.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 785 - $GC_I_SKILL_ID_MARK_OF_DEATH
Func CanUse_MarkOfDeath()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MarkOfDeath($a_f_AggroRange)
	; Description
	; Hex Spell. (4...9...10 seconds.) Target foe receives 33% less from healing.
	; Concise description
	; Spell. (4...9...10 seconds.) Target foe receives 33% less from healing.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 800 - $GC_I_SKILL_ID_ENDURING_TOXIN
Func CanUse_EnduringToxin()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EnduringToxin($a_f_AggroRange)
	; Description
	; Hex Spell. (5 seconds.) Causes -1...4...5 Health degeneration. Renewal: if the target foe is moving when this hex ends.
	; Concise description
	; Spell. (5 seconds.) Causes -1...4...5 Health degeneration. Renewal: if the target foe is moving when this hex ends.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 801 - $GC_I_SKILL_ID_SHROUD_OF_SILENCE
Func CanUse_ShroudOfSilence()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShroudOfSilence($a_f_AggroRange)
	; Description
	; Hex Spell. (1...3...3 second[s].) Target foe cannot cast spells. Your spells are disabled for 15 seconds.
	; Concise description
	; Spell. (1...3...3 second[s].) Target foe cannot cast spells. Your spells are disabled for 15 seconds.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 802 - $GC_I_SKILL_ID_EXPOSE_DEFENSES
Func CanUse_ExposeDefenses()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ExposeDefenses($a_f_AggroRange)
	; Description
	; Hex Spell. (1...9...11 second[s].) Target foe cannot block your attacks.
	; Concise description
	; Spell. (1...9...11 second[s].) Target foe cannot block your attacks.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 803 - $GC_I_SKILL_ID_POWER_LEECH
Func CanUse_PowerLeech()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PowerLeech($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Interrupt a spell or a chant. Interruption effect: steal 5...13...15 Energy whenever target foe casts a spell (10 seconds).
	; Concise description
	; Hex Spell. Interrupt a spell or a chant. Interruption effect: steal 5...13...15 Energy whenever target foe casts a spell (10 seconds).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 804 - $GC_I_SKILL_ID_ARCANE_LANGUOR
Func CanUse_ArcaneLanguor()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ArcaneLanguor($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (1...8...10 second[s].) Target foe's spells cause 10 Overcast.
	; Concise description
	; Hex Spell. (1...8...10 second[s].) Target foe's spells cause 10 Overcast.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 808 - $GC_I_SKILL_ID_REAPERS_MARK1
Func CanUse_ReapersMark1()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ReapersMark1($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (30 seconds.) Causes -1...4...5 Health degeneration. You gain 5...13...15 Energy if target foe dies while suffering from this hex.
	; Concise description
	; Hex Spell. (30 seconds.) Causes -1...4...5 Health degeneration. You gain 5...13...15 Energy if target foe dies while suffering from this hex.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 809 - $GC_I_SKILL_ID_SHATTERSTONE
Func CanUse_Shatterstone()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Shatterstone($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (3 seconds.) Initial effect: deals 25...85...100 cold damage. End effect: deals 25...85...100 cold damage to target and all nearby foes.
	; Concise description
	; Hex Spell. (3 seconds.) Initial effect: deals 25...85...100 cold damage. End effect: deals 25...85...100 cold damage to target and all nearby foes.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 815 - $GC_I_SKILL_ID_SCORPION_WIRE
Func CanUse_ScorpionWire()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ScorpionWire($a_f_AggroRange)
	; Description
	; Hex Spell. (8...18...20 seconds.) Shadow Step to target foe and cause knock-down the next time this foe is more than 100' away from you.
	; Concise description
	; Spell. (8...18...20 seconds.) Shadow Step to target foe and cause knock-down the next time this foe is more than 100' away from you.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 816 - $GC_I_SKILL_ID_MIRRORED_STANCE
Func CanUse_MirroredStance()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MirroredStance($a_f_AggroRange)
	; Description
	; Hex Spell. (10...30...35 seconds.) You enter any stance used by target foe.
	; Concise description
	; Spell. (10...30...35 seconds.) You enter any stance used by target foe.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 820 - $GC_I_SKILL_ID_DEPRAVITY
Func CanUse_Depravity()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Depravity($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (5...17...20 seconds.) Causes 1...4...5 Energy loss whenever target foe casts a spell. One foe near your target also loses Energy.
	; Concise description
	; Hex Spell. (5...17...20 seconds.) Causes 1...4...5 Energy loss whenever target foe casts a spell. One foe near your target also loses Energy.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 821 - $GC_I_SKILL_ID_ICY_VEINS
Func CanUse_IcyVeins()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_IcyVeins($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (10...30...35 seconds.) Deals 20...92...110 cold damage to nearby foes if target foe dies. Initial effect: deals 10...74...90 cold damage.
	; Concise description
	; Hex Spell. (10...30...35 seconds.) Deals 20...92...110 cold damage to nearby foes if target foe dies. Initial effect: deals 10...74...90 cold damage.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 822 - $GC_I_SKILL_ID_WEAKEN_KNEES
Func CanUse_WeakenKnees()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WeakenKnees($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (1...13...16 second[s].) Target foe has -1...3...4 Health degeneration and takes 5...9...10 damage while moving.
	; Concise description
	; Hex Spell. (1...13...16 second[s].) Target foe has -1...3...4 Health degeneration and takes 5...9...10 damage while moving.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 827 - $GC_I_SKILL_ID_SIPHON_STRENGTH
Func CanUse_SiphonStrength()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SiphonStrength($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (5...17...20 seconds.) Target foe deals -5...41...50 attack damage. You have +33% chance to land a critical hit on this foe.
	; Concise description
	; Hex Spell. (5...17...20 seconds.) Target foe deals -5...41...50 attack damage. You have +33% chance to land a critical hit on this foe.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 828 - $GC_I_SKILL_ID_VILE_MIASMA
Func CanUse_VileMiasma()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_VileMiasma($a_f_AggroRange)
	; Description
	; Hex Spell. Causes -1...4...5 Health degeneration (10 seconds). Initial effect: deals 10...54...65 cold damage. Hex is only applied if target foe has a condition.
	; Concise description
	; Spell. Causes -1...4...5 Health degeneration (10 seconds). Initial effect: deals 10...54...65 cold damage. Hex is only applied if target foe has a condition.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 834 - $GC_I_SKILL_ID_RECKLESS_HASTE
Func CanUse_RecklessHaste()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_RecklessHaste($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes adjacent to your target (6...11...12 seconds). These foes have 50% chance to miss, but attack 25% faster.
	; Concise description
	; Spell. Also hexes foes adjacent to your target (6...11...12 seconds). These foes have 50% chance to miss, but attack 25% faster.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 835 - $GC_I_SKILL_ID_BLOOD_BOND
Func CanUse_BloodBond()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_BloodBond($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes adjacent to your target (3...10...12 seconds). Allies hitting these foes gain 5...17...20 health. If any of these foes dies while hexed, adjacent allies are healed for 20...84...100.
	; Concise description
	; Spell. Also hexes foes adjacent to your target (3...10...12 seconds). Allies hitting these foes gain 5...17...20 health. If any of these foes dies while hexed, adjacent allies are healed for 20...84...100.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 859 - $GC_I_SKILL_ID_CONJURE_NIGHTMARE
Func CanUse_ConjureNightmare()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ConjureNightmare($a_f_AggroRange)
	; Description
	; Hex Spell. (2...13...16 seconds.) Causes -8 Health degeneration.
	; Concise description
	; Spell. (2...13...16 seconds.) Causes -8 Health degeneration.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 861 - $GC_I_SKILL_ID_DISSIPATION
Func CanUse_Dissipation()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Dissipation($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 878 - $GC_I_SKILL_ID_VISIONS_OF_REGRET
Func CanUse_VisionsOfRegret()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_VisionsOfRegret($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Also hexes foes adjacent to target (10 seconds). These foes take 15...39...45 damage whenever they use a skill and 5...41...50 additional damage if not under the effects of another Mesmer hex.
	; Concise description
	; Hex Spell. Also hexes foes adjacent to target (10 seconds). These foes take 15...39...45 damage whenever they use a skill and 5...41...50 additional damage if not under the effects of another Mesmer hex.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 879 - $GC_I_SKILL_ID_ILLUSION_OF_PAIN
Func CanUse_IllusionOfPain()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_IllusionOfPain($a_f_AggroRange)
	; Description
	; Hex Spell. (8 seconds.) Causes -3...9...10 Health degeneration and target foe takes 3...9...10 damage each second. End effect: that foe is healed for 36...103...120.
	; Concise description
	; Spell. (8 seconds.) Causes -3...9...10 Health degeneration and target foe takes 3...9...10 damage each second. End effect: that foe is healed for 36...103...120.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 880 - $GC_I_SKILL_ID_STOLEN_SPEED
Func CanUse_StolenSpeed()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_StolenSpeed($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Also hexes adjacent foes (1...8...10 seconds). Doubles spell casting time. Spells cast by you or your allies have -50% casting times.
	; Concise description
	; Hex Spell. Also hexes adjacent foes (1...8...10 seconds). Doubles spell casting time. Spells cast by you or your allies have -50% casting times.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 883 - $GC_I_SKILL_ID_VOCAL_MINORITY
Func CanUse_VocalMinority()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_VocalMinority($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes near target (5...17...20 seconds). These foes cannot use shouts or chants.
	; Concise description
	; Spell. Also hexes foes near target (5...17...20 seconds). These foes cannot use shouts or chants.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 898 - $GC_I_SKILL_ID_OVERLOAD
Func CanUse_Overload()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Overload($a_f_AggroRange)
	; Description
	; Hex Spell. (5 seconds.) Causes -1...3...3 Health degeneration. If target foe is using a skill, that foe and all adjacent foes take 15...63...75 damage.
	; Concise description
	; Spell. (5 seconds.) Causes -1...3...3 Health degeneration. If target foe is using a skill, that foe and all adjacent foes take 15...63...75 damage.

	; Only hexed foes (stack / pay off existing hexes).
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsHexed")
EndFunc

; Skill ID: 899 - $GC_I_SKILL_ID_IMAGES_OF_REMORSE
Func CanUse_ImagesOfRemorse()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ImagesOfRemorse($a_f_AggroRange)
	; Description
	; Hex Spell. (5...9...10 seconds.) Causes -1...3...3 Health degeneration. Initial effect: 10...44...52 damage if target foe is attacking.
	; Concise description
	; Spell. (5...9...10 seconds.) Causes -1...3...3 Health degeneration. Initial effect: 10...44...52 damage if target foe is attacking.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 900 - $GC_I_SKILL_ID_SHARED_BURDEN
Func CanUse_SharedBurden()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SharedBurden($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Also hexes foes near your target (5...17...20 seconds). These foes attack, cast spells, and move 50% slower.
	; Concise description
	; Hex Spell. Also hexes foes near your target (5...17...20 seconds). These foes attack, cast spells, and move 50% slower.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 901 - $GC_I_SKILL_ID_SOUL_BIND
Func CanUse_SoulBind()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SoulBind($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (30 seconds.) Every time target foe is healed, the healer takes 20...68...80 damage. Ends if target is suffering from a Smiting Prayers hex.
	; Concise description
	; Hex Spell. (30 seconds.) Every time target foe is healed, the healer takes 20...68...80 damage. Ends if target is suffering from a Smiting Prayers hex.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 916 - $GC_I_SKILL_ID_LAMENTATION
Func CanUse_Lamentation()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Lamentation($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes near your target (5...17...20 seconds). Causes -0...2...3 Health degeneration. Initial effect: Deals 10...42...50 damage to these foes if you are within earshot of a spirit or corpse.
	; Concise description
	; Spell. Also hexes foes near your target (5...17...20 seconds). Causes -0...2...3 Health degeneration. Initial effect: Deals 10...42...50 damage to these foes if you are within earshot of a spirit or corpse.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 927 - $GC_I_SKILL_ID_SHAMEFUL_FEAR
Func CanUse_ShamefulFear()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShamefulFear($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Target foe takes 5...17...20 damage each second while moving, but moves 10% faster.
	; Concise description
	; Spell. (10 seconds.) Target foe takes 5...17...20 damage each second while moving, but moves 10% faster.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 928 - $GC_I_SKILL_ID_SHADOW_SHROUD
Func CanUse_ShadowShroud()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShadowShroud($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (3...8...9 seconds.) Target foe cannot be the target of enchantments.
	; Concise description
	; Hex Spell. (3...8...9 seconds.) Target foe cannot be the target of enchantments.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 935 - $GC_I_SKILL_ID_RISING_BILE
Func CanUse_RisingBile()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_RisingBile($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) End effect: deals 1...5...6 damage for each second Rising Bile was in effect. Also damages other foes in the area.
	; Concise description
	; Spell. (20 seconds.) End effect: deals 1...5...6 damage for each second Rising Bile was in effect. Also damages other foes in the area.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_AREA, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 939 - $GC_I_SKILL_ID_ICY_SHACKLES
Func CanUse_IcyShackles()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_IcyShackles($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (1...8...10 second[s].) Target foe moves 66% slower. This foe moves 90% slower if enchanted.
	; Concise description
	; Hex Spell. (1...8...10 second[s].) Target foe moves 66% slower. This foe moves 90% slower if enchanted.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsEnchanted")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 950 - $GC_I_SKILL_ID_SHADOWY_BURDEN
Func CanUse_ShadowyBurden()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShadowyBurden($a_f_AggroRange)
	; Description
	; Hex Spell. (3...13...15 seconds.) Target foe moves 25% slower and has 20 less armor against your attacks. Armor reduction only affects this foe while it has no other hexes.
	; Concise description
	; Spell. (3...13...15 seconds.) Target foe moves 25% slower and has 20 less armor against your attacks. Armor reduction only affects this foe while it has no other hexes.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 951 - $GC_I_SKILL_ID_SIPHON_SPEED
Func CanUse_SiphonSpeed()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SiphonSpeed($a_f_AggroRange)
	; Description
	; Hex Spell. (5...13...15 seconds.) Target foe moves 33% slower and you move 33% faster. Recharges 50% faster if cast on a moving foe.
	; Concise description
	; Spell. (5...13...15 seconds.) Target foe moves 33% slower and you move 33% faster. Recharges 50% faster if cast on a moving foe.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 953 - $GC_I_SKILL_ID_POWER_FLUX
Func CanUse_PowerFlux()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PowerFlux($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Interrupts a spell or chant. Interruption effect: -2 Energy degeneration (4...9...10 seconds).
	; Concise description
	; Hex Spell. Interrupts a spell or chant. Interruption effect: -2 Energy degeneration (4...9...10 seconds).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 978 - $GC_I_SKILL_ID_MARK_OF_INSTABILITY
Func CanUse_MarkOfInstability()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MarkOfInstability($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) Causes knock-down the next time you hit target foe with a dual attack.
	; Concise description
	; Spell. (20 seconds.) Causes knock-down the next time you hit target foe with a dual attack.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 979 - $GC_I_SKILL_ID_MISTRUST
Func CanUse_Mistrust()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Mistrust($a_f_AggroRange)
	; Description
	; Hex Spell. (6 seconds.) The next spell that target foe casts on one of your allies fails and deals 10...82...100 damage to target and nearby foes.
	; Concise description
	; Spell. (6 seconds.) The next spell that target foe casts on one of your allies fails and deals 10...82...100 damage to target and nearby foes.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 998 - $GC_I_SKILL_ID_TORCH_HEX
Func CanUse_TorchHex()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_TorchHex($a_f_AggroRange)
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 999 - $GC_I_SKILL_ID_TORCH_DEGENERATION_HEX
Func CanUse_TorchDegenerationHex()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_TorchDegenerationHex($a_f_AggroRange)
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 1009 - $GC_I_SKILL_ID_SNOW_DOWN_THE_SHIRT
Func CanUse_SnowDownTheShirt()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SnowDownTheShirt($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) Interrupts target foe whenever it takes damage.
	; Concise description
	; Spell. (20 seconds.) Interrupts target foe whenever it takes damage.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1012 - $GC_I_SKILL_ID_ICICLES
Func CanUse_Icicles()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Icicles($a_f_AggroRange)
	; Description
	; Hex Spell. Deals 75 cold damage to target and adjacent foes. These foes move 66% slower (5 seconds).
	; Concise description
	; Spell. Deals 75 cold damage to target and adjacent foes. These foes move 66% slower (5 seconds).
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1034 - $GC_I_SKILL_ID_SEEPING_WOUND
Func CanUse_SeepingWound()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SeepingWound($a_f_AggroRange)
	; Description
	; Hex Spell. (1...6...7 second[s].) Target foe moves 33% slower. This foe takes 5...21...25 damage each second while suffering from a condition.
	; Concise description
	; Spell. (1...6...7 second[s].) Target foe moves 33% slower. This foe takes 5...21...25 damage each second while suffering from a condition.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1035 - $GC_I_SKILL_ID_ASSASSINS_PROMISE
Func CanUse_AssassinsPromise()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_AssassinsPromise($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (5...13...15 seconds.) You gain 5...17...20 Energy and all your skills recharge if target foe dies.
	; Concise description
	; Hex Spell. (5...13...15 seconds.) You gain 5...17...20 Energy and all your skills recharge if target foe dies.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1044 - $GC_I_SKILL_ID_DARK_PRISON
Func CanUse_DarkPrison()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_DarkPrison($a_f_AggroRange)
	; Description
	; Hex Spell. Shadow Step to target foe. This foe moves 33% slower (1...5...6 seconds).
	; Concise description
	; Spell. Shadow Step to target foe. This foe moves 33% slower (1...5...6 seconds).
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1051 - $GC_I_SKILL_ID_EMPATHY_KORO
Func CanUse_EmpathyKoro()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EmpathyKoro($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 1055 - $GC_I_SKILL_ID_RECURRING_INSECURITY
Func CanUse_RecurringInsecurity()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_RecurringInsecurity($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (10 seconds.) Causes -1...4...5 Health degeneration. Renewal: if target foe has another hex when Recurring Insecurity would end.
	; Concise description
	; Hex Spell. (10 seconds.) Causes -1...4...5 Health degeneration. Renewal: if target foe has another hex when Recurring Insecurity would end.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1056 - $GC_I_SKILL_ID_KITAHS_BURDEN
Func CanUse_KitahsBurden()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_KitahsBurden($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Target foe moves 50% slower. End effect: you gain 10...16...18 Energy.
	; Concise description
	; Spell. (10 seconds.) Target foe moves 50% slower. End effect: you gain 10...16...18 Energy.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1066 - $GC_I_SKILL_ID_SPOIL_VICTOR
Func CanUse_SpoilVictor()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpoilVictor($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (3...13...15 seconds.) Causes 25...85...100 Health loss whenever target foe attacks or casts spells on a creature with less Health.
	; Concise description
	; Hex Spell. (3...13...15 seconds.) Causes 25...85...100 Health loss whenever target foe attacks or casts spells on a creature with less Health.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 1071 - $GC_I_SKILL_ID_SHIVERS_OF_DREAD
Func CanUse_ShiversOfDread()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShiversOfDread($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1085 - $GC_I_SKILL_ID_ASH_BLAST
Func CanUse_AshBlast()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_AshBlast($a_f_AggroRange)
	; Description
	; Hex Spell. Deals 35...59...65 earth damage. Burning foes are hexed for 5 seconds and miss 20...64...75% of attacks. Also strikes adjacent.
	; Concise description
	; Spell. Deals 35...59...65 earth damage. Burning foes are hexed for 5 seconds and miss 20...64...75% of attacks. Also strikes adjacent.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1090 - $GC_I_SKILL_ID_SMOLDERING_EMBERS
Func CanUse_SmolderingEmbers()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SmolderingEmbers($a_f_AggroRange)
	; Description
	; Hex Spell. Deals 10...58...70 fire damage to target. If you are Overcast, foe is hexed for 3 seconds, taking 5...21...25 fire damage each second.
	; Concise description
	; Spell. Deals 10...58...70 fire damage to target. If you are Overcast, foe is hexed for 3 seconds, taking 5...21...25 fire damage each second.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1097 - $GC_I_SKILL_ID_TEINAIS_PRISON
Func CanUse_TeinaisPrison()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_TeinaisPrison($a_f_AggroRange)
	; Description
	; Hex Spell. (1...5...6 second[s].) Target foe moves 66% slower. Foes with Cracked Armor have 5...8...9 Health degeneration.
	; Concise description
	; Spell. (1...5...6 second[s].) Target foe moves 66% slower. Foes with Cracked Armor have 5...8...9 Health degeneration.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1098 - $GC_I_SKILL_ID_MIRROR_OF_ICE
Func CanUse_MirrorOfIce()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MirrorOfIce($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Deals 15...59...70 cold damage and slows foes by 66% (2...5...6 seconds). Hits foes near you and target ally. Recharges 50% faster if it hits a foe hexed with Water Magic.
	; Concise description
	; Hex Spell. Deals 15...59...70 cold damage and slows foes by 66% (2...5...6 seconds). Hits foes near you and target ally. Recharges 50% faster if it hits a foe hexed with Water Magic.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1157 - $GC_I_SKILL_ID_STAR_SHARDS
Func CanUse_StarShards()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_StarShards($a_f_AggroRange)
	; Description
	; Hex Spell. Whenever a Celestial creature dies, all nearby foes are hexed with Star Shards (30 seconds). Star Shards does damage equal to the next skill damage that foe takes.
	; Concise description
	; Spell. Whenever a Celestial creature dies, all nearby foes are hexed with Star Shards (30 seconds). Star Shards does damage equal to the next skill damage that foe takes.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 1169 - ;  $GC_I_SKILL_ID_UNKNOWN
; Skill ID: 1235 - $GC_I_SKILL_ID_DULLED_WEAPON
Func CanUse_DulledWeapon()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_DulledWeapon($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes adjacent to your target (5...13...15 seconds). Removes ability to land a critical hit. Reduces damage by 1...12...15.
	; Concise description
	; Spell. Also hexes foes adjacent to your target (5...13...15 seconds). Removes ability to land a critical hit. Reduces damage by 1...12...15.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1236 - $GC_I_SKILL_ID_BINDING_CHAINS
Func CanUse_BindingChains()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_BindingChains($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes near your target. (3 seconds.) These foes move 90% slower and takes 1...24...30 damage each second while moving.
	; Concise description
	; Spell. Also hexes foes near your target. (3 seconds.) These foes move 90% slower and takes 1...24...30 damage each second while moving.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1237 - $GC_I_SKILL_ID_PAINFUL_BOND
Func CanUse_PainfulBond()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PainfulBond($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes near your target (10...18...20 seconds). Spirits do 8...18...20 more damage against these foes.
	; Concise description
	; Spell. Also hexes foes near your target (10...18...20 seconds). Spirits do 8...18...20 more damage against these foes.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1260 - $GC_I_SKILL_ID_MEEKNESS
Func CanUse_Meekness()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Meekness($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes in the area of target (5...25...30 seconds). These foes attack 50% slower.
	; Concise description
	; Spell. Also hexes foes in the area of target (5...25...30 seconds). These foes attack 50% slower.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_AREA, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1272 - $GC_I_SKILL_ID_SUICIDAL_IMPULSE
Func CanUse_SuicidalImpulse()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SuicidalImpulse($a_f_AggroRange)
	; Description
	; Hex Spell. All foes in the area must attack Shiro within 10 seconds or lose half their Health.
	; Concise description
	; Spell. All foes in the area must attack Shiro within 10 seconds or lose half their Health.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 1335 - $GC_I_SKILL_ID_WASTRELS_DEMISE
Func CanUse_WastrelsDemise()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WastrelsDemise($a_f_AggroRange)
	; Description
	; Hex Spell. (5 seconds.) Each second while hexed, target foe and all foes adjacent to that foe take 1...8...10 damage. Foes take +1...8...10 damage each second this hex is in effect. Ends early if target foe uses a skill.
	; Concise description
	; Spell. (5 seconds.) Each second while hexed, target foe and all foes adjacent to that foe take 1...8...10 damage. Foes take +1...8...10 damage each second this hex is in effect. Ends early if target foe uses a skill.

	; Target enemy with most adjacent enemies (AOE damage)
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1341 - $GC_I_SKILL_ID_FRUSTRATION
Func CanUse_Frustration()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Frustration($a_f_AggroRange)
	; Description
	; Hex Spell. (5...17...20 seconds.) Causes 50% slower spell casting. Target foe takes 5...41...50 damage whenever interrupted. Deals double damage on skill interrupt.
	; Concise description
	; Spell. (5...17...20 seconds.) Causes 50% slower spell casting. Target foe takes 5...41...50 damage whenever interrupted. Deals double damage on skill interrupt.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 1343 - $GC_I_SKILL_ID_ETHER_PHANTOM
Func CanUse_EtherPhantom()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EtherPhantom($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Causes -1 Energy degeneration. Causes 1...4...5 Energy loss if this hex ends early.
	; Concise description
	; Spell. (10 seconds.) Causes -1 Energy degeneration. Causes 1...4...5 Energy loss if this hex ends early.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 1344 - $GC_I_SKILL_ID_WEB_OF_DISRUPTION
Func CanUse_WebOfDisruption()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WebOfDisruption($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Initial effect: interrupts a skill. End effect: interrupts a skill.
	; Concise description
	; Spell. (10 seconds.) Initial effect: interrupts a skill. End effect: interrupts a skill.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 1345 - $GC_I_SKILL_ID_ENCHANTERS_CONUNDRUM
Func CanUse_EnchantersConundrum()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EnchantersConundrum($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Causes 100...180...200% slower enchantment casting (10 seconds). Initial effect: deals 10...82...100 damage to target and adjacent foes if target foe is not enchanted.
	; Concise description
	; Hex Spell. Causes 100...180...200% slower enchantment casting (10 seconds). Initial effect: deals 10...82...100 damage to target and adjacent foes if target foe is not enchanted.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1358 - $GC_I_SKILL_ID_ULCEROUS_LUNGS
Func CanUse_UlcerousLungs()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_UlcerousLungs($a_f_AggroRange)
	; Description
	; Hex Spell. Also hexes foes near your target (10...22...25 seconds). Causes -4 Health degeneration to any of these foes that are Bleeding. Inflicts Bleeding (3...13...15 seconds) whenever these foes use a shout or chant.
	; Concise description
	; Spell. Also hexes foes near your target (10...22...25 seconds). Causes -4 Health degeneration to any of these foes that are Bleeding. Inflicts Bleeding (3...13...15 seconds) whenever these foes use a shout or chant.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1360 - $GC_I_SKILL_ID_MARK_OF_FURY
Func CanUse_MarkOfFury()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MarkOfFury($a_f_AggroRange)
	; Description
	; Hex Spell. (5 seconds.) Allies hitting target foe gain 0...2...2 strike[s] of adrenaline. End effect: inflicts Cracked Armor (1...12...15 second[s].)
	; Concise description
	; Spell. (5 seconds.) Allies hitting target foe gain 0...2...2 strike[s] of adrenaline. End effect: inflicts Cracked Armor (1...12...15 second[s].)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 1361 - $GC_I_SKILL_ID_RECURRING_SCOURGE
Func CanUse_RecurringScourge()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_RecurringScourge($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1362 - $GC_I_SKILL_ID_CORRUPT_ENCHANTMENT
Func CanUse_CorruptEnchantment()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CorruptEnchantment($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Removes one enchantment from target foe. Removal effect: -1...7...8 Health degeneration (10 seconds).
	; Concise description
	; Hex Spell. Removes one enchantment from target foe. Removal effect: -1...7...8 Health degeneration (10 seconds).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsEnchanted")
EndFunc

; Skill ID: 1368 - $GC_I_SKILL_ID_CHILLING_WINDS
Func CanUse_ChillingWinds()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ChillingWinds($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) The next water hex on target foe lasts 25...85...100% longer. Initial effect: 30...54...60 cold damage. Also strikes adjacent.
	; Concise description
	; Spell. (10 seconds.) The next water hex on target foe lasts 25...85...100% longer. Initial effect: 30...54...60 cold damage. Also strikes adjacent.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1382 - $GC_I_SKILL_ID_FREEZING_GUST
Func CanUse_FreezingGust()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_FreezingGust($a_f_AggroRange)
	; Description
	; Hex Spell. Deals 20...68...80 cold damage if target foe is hexed with Water Magic. Otherwise, this foe moves 66% slower (1...4...5 second[s]).
	; Concise description
	; Spell. Deals 20...68...80 cold damage if target foe is hexed with Water Magic. Otherwise, this foe moves 66% slower (1...4...5 second[s]).
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1398 - $GC_I_SKILL_ID_SCOURGE_ENCHANTMENT
Func CanUse_ScourgeEnchantment()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ScourgeEnchantment($a_f_AggroRange)
	; Description
	; Hex Spell. (30 seconds.) Deals 15...63...75 damage to anyone casting an enchantment on target foe.
	; Concise description
	; Spell. (30 seconds.) Deals 15...63...75 damage to anyone casting an enchantment on target foe.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1417 - $GC_I_SKILL_ID_VIAL_OF_PURIFIED_WATER
Func CanUse_VialOfPurifiedWater()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_VialOfPurifiedWater($a_f_AggroRange)
	; Description
	; Hex Spell. The purified waters of the vial affect one target (10 seconds). Harbingers become vulnerable to damage from all sources.
	; Concise description
	; Spell. The purified waters of the vial affect one target (10 seconds). Harbingers become vulnerable to damage from all sources.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsHarbingers")
EndFunc

; Skill ID: 1433 - $GC_I_SKILL_ID_CORSAIRS_NET
Func CanUse_CorsairsNet()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CorsairsNet($a_f_AggroRange)
	; Description
	; Hex Spell. Quarter speed projectile: target and foes in the area move slower (10 seconds).
	; Concise description
	; Spell. Quarter speed projectile: target and foes in the area move slower (10 seconds).
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_AREA, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1449 - $GC_I_SKILL_ID_LAST_RITES_OF_TORMENT
Func CanUse_LastRitesOfTorment()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_LastRitesOfTorment($a_f_AggroRange)
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 1458 - $GC_I_SKILL_ID_ENCHANTMENT_COLLAPSE
Func CanUse_EnchantmentCollapse()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EnchantmentCollapse($a_f_AggroRange)
	; Description
	; Hex Spell. Target foe loses all enchantments each time this foe loses an enchantment.
	; Concise description
	; Spell. Target foe loses all enchantments each time this foe loses an enchantment.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsEnchanted")
EndFunc

; Skill ID: 1459 - $GC_I_SKILL_ID_CALL_OF_SACRIFICE
Func CanUse_CallOfSacrifice()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CallOfSacrifice($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) Target loses 20 Health each second. Ends sooner if target is at less than 20% Health.
	; Concise description
	; Spell. (20 seconds.) Target loses 20 Health each second. Ends sooner if target is at less than 20% Health.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1478 - $GC_I_SKILL_ID_RENEWING_SURGE
Func CanUse_RenewingSurge()
	If Anti_Hex() Then Return False
	If UAI_GetPlayerInfo($GC_UAI_AGENT_CurrentEnergy) > 20 Then Return False
	Return True
EndFunc

Func BestTarget_RenewingSurge($a_f_AggroRange)
	; Description
	; Hex Spell. (8 seconds.) Deals 2...10...12 damage each second. End effect: You gain 1...7...8 energy.
	; Concise description
	; Spell. (8 seconds.) Deals 2...10...12 damage each second. End effect: You gain 1...7...8 energy.
	Return UAI_GetAgentHighest(-2, 1320, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1642 - $GC_I_SKILL_ID_HIDDEN_CALTROPS
Func CanUse_HiddenCaltrops()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_HiddenCaltrops($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (1...8...10 seconds.) Causes 50% slower movement. End effect: inflicts Crippled condition (1...12...15 seconds). Your non-Assassin skills are disabled (10 seconds.)
	; Concise description
	; Hex Spell. (1...8...10 seconds.) Causes 50% slower movement. End effect: inflicts Crippled condition (1...12...15 seconds). Your non-Assassin skills are disabled (10 seconds.)
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1646 - $GC_I_SKILL_ID_AUGURY_OF_DEATH
Func CanUse_AuguryOfDeath()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_AuguryOfDeath($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1652 - $GC_I_SKILL_ID_SHADOW_PRISON
Func CanUse_ShadowPrison()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShadowPrison($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Shadow Step to target foe. This foe moves 66% slower (1...6...7 seconds).
	; Concise description
	; Hex Spell. Shadow Step to target foe. This foe moves 66% slower (1...6...7 seconds).
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1655 - $GC_I_SKILL_ID_PRICE_OF_PRIDE
Func CanUse_PriceOfPride()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PriceOfPride($a_f_AggroRange)
	; Description
	; Hex Spell. (5...17...20 seconds.) Causes 1...6...7 Energy loss the next time target foe uses an elite skill.
	; Concise description
	; Spell. (5...17...20 seconds.) Causes 1...6...7 Energy loss the next time target foe uses an elite skill.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 1656 - $GC_I_SKILL_ID_AIR_OF_DISENCHANTMENT
Func CanUse_AirOfDisenchantment()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_AirOfDisenchantment($a_f_AggroRange)
	; Description
	; Elite Hex Spell. Also hexes foes near your target (5...17...20 seconds). Remove one enchantment from target and nearby foes. Enchantments expire 150...270...300% faster on those foes.
	; Concise description
	; Hex Spell. Also hexes foes near your target (5...17...20 seconds). Remove one enchantment from target and nearby foes. Enchantments expire 150...270...300% faster on those foes.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1688 - $GC_I_SKILL_ID_DEFENDERS_ZEAL
Func CanUse_DefendersZeal()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_DefendersZeal($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (5...21...25 seconds.) You gain 2 Energy whenever target foe hits with an attack.
	; Concise description
	; Hex Spell. (5...21...25 seconds.) You gain 2 Energy whenever target foe hits with an attack.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 1707 - $GC_I_SKILL_ID_WORDS_OF_MADNESS_QWYTZYLKAK
Func CanUse_WordsOfMadnessQwytzylkak()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WordsOfMadnessQwytzylkak($a_f_AggroRange)
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 1710 - $GC_I_SKILL_ID_MADNESS_DART
Func CanUse_MadnessDart()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MadnessDart($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1881 - $GC_I_SKILL_ID_BONDS_OF_TORMENT
Func CanUse_BondsOfTorment()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_BondsOfTorment($a_f_AggroRange)
	; Description
	; Hex Spell. Any time the caster takes damage, all foes hexed with Bonds of Torment take equal cold damage.
	; Concise description
	; Spell. Any time the caster takes damage, all foes hexed with Bonds of Torment take equal cold damage.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1949 - $GC_I_SKILL_ID_ETHER_NIGHTMARE_LUXON
Func CanUse_EtherNightmareLuxon()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EtherNightmareLuxon($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1996 - $GC_I_SKILL_ID_SUM_OF_ALL_FEARS
Func CanUse_SumOfAllFears()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SumOfAllFears($a_f_AggroRange)
	; Description
	; Hex Spell. (1...8...10 second[s].) Target foe moves, attacks, and casts spells 33% slower.
	; Concise description
	; Spell. (1...8...10 second[s].) Target foe moves, attacks, and casts spells 33% slower.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1998 - $GC_I_SKILL_ID_CACOPHONY
Func CanUse_Cacophony()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Cacophony($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Deals 35...91...105 damage whenever target foe uses a shout or chant.
	; Concise description
	; Spell. (10 seconds.) Deals 35...91...105 damage whenever target foe uses a shout or chant.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 1999 - $GC_I_SKILL_ID_WINTERS_EMBRACE
Func CanUse_WintersEmbrace()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WintersEmbrace($a_f_AggroRange)
	; Description
	; Hex Spell. (2...5...6 seconds.) Target foe moves 66% slower and takes 5...13...15 damage while moving.
	; Concise description
	; Spell. (2...5...6 seconds.) Target foe moves 66% slower and takes 5...13...15 damage while moving.
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2000 - $GC_I_SKILL_ID_EARTHEN_SHACKLES
Func CanUse_EarthenShackles()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EarthenShackles($a_f_AggroRange)
	; Description
	; Hex Spell. (3 seconds.) Target and nearby foes move 90% slower. Applies Weakness for 5...17...20 seconds when it ends.
	; Concise description
	; Spell. (3 seconds.) Target and nearby foes move 90% slower. Applies Weakness for 5...17...20 seconds when it ends.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2052 - $GC_I_SKILL_ID_SHADOW_FANG
Func CanUse_ShadowFang()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShadowFang($a_f_AggroRange)
	; Description
	; Hex Spell. Shadow Step to target foe. End effect after 10 seconds: inflicts Deep Wound condition (5...17...20 seconds); you return to your original location.
	; Concise description
	; Spell. Shadow Step to target foe. End effect after 10 seconds: inflicts Deep Wound condition (5...17...20 seconds); you return to your original location.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2053 - $GC_I_SKILL_ID_CALCULATED_RISK
Func CanUse_CalculatedRisk()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CalculatedRisk($a_f_AggroRange)
	; Description
	; Hex Spell. Target foe does +10 damage with attacks (3...20...24 seconds). There is a 50% chance that the damage from each attack (maximum 15...83...100) will be done to that foe instead.
	; Concise description
	; Spell. Target foe does +10 damage with attacks (3...20...24 seconds). There is a 50% chance that the damage from each attack (maximum 15...83...100) will be done to that foe instead.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 2054 - $GC_I_SKILL_ID_SHRINKING_ARMOR
Func CanUse_ShrinkingArmor()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ShrinkingArmor($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) Causes -1...3...4 Health degeneration. End effect: inflicts Cracked Armor condition (5...17...20 seconds).
	; Concise description
	; Spell. (10 seconds.) Causes -1...3...4 Health degeneration. End effect: inflicts Cracked Armor condition (5...17...20 seconds).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2056 - $GC_I_SKILL_ID_WANDERING_EYE
Func CanUse_WanderingEye()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WanderingEye($a_f_AggroRange)
	; Description
	; Hex Spell. (4 seconds.) Interrupts target foe's next attack. Interruption effect: 30...94...110 damage to nearby foes.
	; Concise description
	; Spell. (4 seconds.) Interrupts target foe's next attack. Interruption effect: 30...94...110 damage to nearby foes.
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2058 - $GC_I_SKILL_ID_PUTRID_BILE
Func CanUse_PutridBile()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PutridBile($a_f_AggroRange)
	; Description
	; Hex Spell. (5...17...20 seconds.) Causes -1...3...3 Health degeneration. Deals 25...73...85 damage to all nearby foes if target foe dies.
	; Concise description
	; Spell. (5...17...20 seconds.) Causes -1...3...3 Health degeneration. Deals 25...73...85 damage to all nearby foes if target foe dies.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2086 - $GC_I_SKILL_ID_SNARING_WEB
Func CanUse_SnaringWeb()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SnaringWeb($a_f_AggroRange)
	; Description
	; Hex Spell. Projectile: target and nearby foes are Crippled and activate skills 100% slower (15 seconds.)
	; Concise description
	; Spell. Projectile: target and nearby foes are Crippled and activate skills 100% slower (15 seconds.)
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2089 - $GC_I_SKILL_ID_WURM_BILE
Func CanUse_WurmBile()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WurmBile($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) Deals 40 damage each second to nearby foes.
	; Concise description
	; Spell. (20 seconds.) Deals 40 damage each second to nearby foes.
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2092 - $GC_I_SKILL_ID_ETHER_NIGHTMARE_KURZICK
Func CanUse_EtherNightmareKurzick()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EtherNightmareKurzick($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2122 - $GC_I_SKILL_ID_SPIRIT_WORLD_RETREAT
Func CanUse_SpiritWorldRetreat()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpiritWorldRetreat($a_f_AggroRange)
	; Description
	; Hex Spell. (3 seconds.) Hide in the Spirit World and hex all foes with -2 Energy degeneration. For each foe hexed, gain 75 Health.
	; Concise description
	; Spell. (3 seconds.) Hide in the Spirit World and hex all foes with -2 Energy degeneration. For each foe hexed, gain 75 Health.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 2137 - $GC_I_SKILL_ID_CONFUSING_IMAGES
Func CanUse_ConfusingImages()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ConfusingImages($a_f_AggroRange)
	; Description
	; Hex Spell. (2...8...10 seconds). Target foe takes twice as long to activate non-attack skills.
	; Concise description
	; Spell. (2...8...10 seconds). Target foe takes twice as long to activate non-attack skills.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 2188 - $GC_I_SKILL_ID_DEFILE_DEFENSES
Func CanUse_DefileDefenses()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_DefileDefenses($a_f_AggroRange)
	; Description
	; Hex Spell. (5...17...20 seconds.) Deals 30...102...120 damage the next time target foe blocks.
	; Concise description
	; Spell. (5...17...20 seconds.) Deals 30...102...120 damage the next time target foe blocks.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 2237 - $GC_I_SKILL_ID_ATROPHY
Func CanUse_Atrophy()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Atrophy($a_f_AggroRange)
	; Description
	; Hex Spell. (3...6...7 seconds.) Reduces this foe's primary attribute to 0.
	; Concise description
	; Spell. (3...6...7 seconds.) Reduces this foe's primary attribute to 0.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2254 - $GC_I_SKILL_ID_POLYMOCK_GLYPH_DESTABILIZATION
Func CanUse_PolymockGlyphDestabilization()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockGlyphDestabilization($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2255 - $GC_I_SKILL_ID_POLYMOCK_MIND_WRECK
Func CanUse_PolymockMindWreck()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockMindWreck($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 2261 - $GC_I_SKILL_ID_POLYMOCK_RISING_BILE
Func CanUse_PolymockRisingBile()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockRisingBile($a_f_AggroRange)
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_AREA, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2281 - $GC_I_SKILL_ID_POLYMOCK_GLYPH_FREEZE
Func CanUse_PolymockGlyphFreeze()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockGlyphFreeze($a_f_AggroRange)
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_AREA, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2284 - $GC_I_SKILL_ID_POLYMOCK_CALCULATED_RISK
Func CanUse_PolymockCalculatedRisk()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockCalculatedRisk($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 2285 - $GC_I_SKILL_ID_POLYMOCK_RECURRING_INSECURITY
Func CanUse_PolymockRecurringInsecurity()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockRecurringInsecurity($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2286 - $GC_I_SKILL_ID_POLYMOCK_BACKFIRE
Func CanUse_PolymockBackfire()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockBackfire($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 2287 - $GC_I_SKILL_ID_POLYMOCK_GUILT
Func CanUse_PolymockGuilt()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockGuilt($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 2290 - $GC_I_SKILL_ID_POLYMOCK_PAINFUL_BOND
Func CanUse_PolymockPainfulBond()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockPainfulBond($a_f_AggroRange)
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2292 - $GC_I_SKILL_ID_POLYMOCK_MIGRAINE
Func CanUse_PolymockMigraine()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockMigraine($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 2304 - $GC_I_SKILL_ID_POLYMOCK_DIVERSION
Func CanUse_PolymockDiversion()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockDiversion($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 2307 - $GC_I_SKILL_ID_POLYMOCK_ICY_BONDS
Func CanUse_PolymockIcyBonds()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PolymockIcyBonds($a_f_AggroRange)
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2329 - $GC_I_SKILL_ID_CRYSTAL_SNARE
Func CanUse_CrystalSnare()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CrystalSnare($a_f_AggroRange)
	; Description
	; Hex Spell. (10 seconds.) You move 50% slower. You take 100 damage if this hex ends before it is removed.
	; Concise description
	; Spell. (10 seconds.) You move 50% slower. You take 100 damage if this hex ends before it is removed.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 2330 - $GC_I_SKILL_ID_PARANOID_INDIGNATION
Func CanUse_ParanoidIndignation()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ParanoidIndignation($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) -2 from your non-zero Attributes.
	; Concise description
	; Spell. (20 seconds.) -2 from your non-zero Attributes.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 2357 - $GC_I_SKILL_ID_A_TOUCH_OF_GUILE
Func CanUse_ATouchOfGuile()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ATouchOfGuile($a_f_AggroRange)
	; Description
	; Hex Spell. Deals 44...80 damage. Target foe cannot attack (5...7...8 seconds) if it was knocked-down.
	; Concise description
	; Spell. Deals 44...80 damage. Target foe cannot attack (5...7...8 seconds) if it was knocked-down.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
EndFunc

; Skill ID: 2415 - $GC_I_SKILL_ID_ASURAN_SCAN
Func CanUse_AsuranScan()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_AsuranScan($a_f_AggroRange)
	; Description
	; Hex Spell. (9...12 seconds.) You cannot miss target foe. If you kill this foe, you lose 5% Death Penalty.
	; Concise description
	; Spell. (9...12 seconds.) You cannot miss target foe. If you kill this foe, you lose 5% Death Penalty.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2418 - $GC_I_SKILL_ID_PAIN_INVERTER
Func CanUse_PainInverter()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PainInverter($a_f_AggroRange)
	Return UAI_GetBestSingleTarget(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2501 - $GC_I_SKILL_ID_TONGUE_LASH
Func CanUse_TongueLash()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_TongueLash($a_f_AggroRange)
	; Description
	; Hex Spell. (4 seconds.) Causes -12 Health degeneration; 25% chance to miss.
	; Concise description
	; Spell. (4 seconds.) Causes -12 Health degeneration; 25% chance to miss.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2503 - $GC_I_SKILL_ID_UNRELIABLE
Func CanUse_Unreliable()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Unreliable($a_f_AggroRange)
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 2514 - $GC_I_SKILL_ID_THE_MASTERS_MARK
Func CanUse_TheMastersMark()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_TheMastersMark($a_f_AggroRange)
	; Description
	; Hex Spell. (24 seconds.) Causes -1 Health degeneration. This hex ends if target foe is hit with The Sniper's Spear.
	; Concise description
	; Spell. (24 seconds.) Causes -1 Health degeneration. This hex ends if target foe is hit with The Sniper's Spear.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2544 - $GC_I_SKILL_ID_TONGUE_WHIP
Func CanUse_TongueWhip()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_TongueWhip($a_f_AggroRange)
	; Description
	; Hex Spell. Causes knock-down (3 seconds); inflicts a Deep Wound (10 seconds).
	; Concise description
	; Spell. Causes knock-down (3 seconds); inflicts a Deep Wound (10 seconds).
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2546 - $GC_I_SKILL_ID_DISHONORABLE
Func CanUse_Dishonorable()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_Dishonorable($a_f_AggroRange)
	; Description
	; Hex Spell. You are considered Dishonorable because teammates repeatedly reported you for leeching, or because you abandoned your team in PvP matches. You may not participate in PvP until this effect expires.
	; Concise description
	; Spell. You are considered Dishonorable because teammates repeatedly reported you for leeching, or because you abandoned your team in PvP matches. You may not participate in PvP until this effect expires.
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 2627 - $GC_I_SKILL_ID_REAPERS_MARK2
Func CanUse_ReapersMark2()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_ReapersMark2($a_f_AggroRange)
	; Description
	; Elite Hex Spell. (30 seconds.) Causes -1...4...5 Health degeneration. You gain 5...13...15 Energy if target foe dies while suffering from this hex.
	; Concise description
	; Hex Spell. (30 seconds.) Causes -1...4...5 Health degeneration. You gain 5...13...15 Energy if target foe dies while suffering from this hex.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2631 - ;  $GC_I_SKILL_ID_UNKNOWN
; Skill ID: 2672 - $GC_I_SKILL_ID_SPECTRAL_AGONY_SAUL_DALESSIO
Func CanUse_SpectralAgonySaulDalessio()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpectralAgonySaulDalessio($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2681 - $GC_I_SKILL_ID_SHARED_BURDEN_GWEN
Func CanUse_SharedBurdenGwen()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SharedBurdenGwen($a_f_AggroRange)
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2682 - $GC_I_SKILL_ID_SUM_OF_ALL_FEARS_GWEN
Func CanUse_SumOfAllFearsGwen()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SumOfAllFearsGwen($a_f_AggroRange)
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsMoving")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2734 - $GC_I_SKILL_ID_MIND_WRACK_PVP
Func CanUse_MindWrackPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MindWrackPvp($a_f_AggroRange)
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 2756 - $GC_I_SKILL_ID_MAD_KINGS_FAN
Func CanUse_MadKingsFan()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MadKingsFan($a_f_AggroRange)
	; Description
	; Hex Spell. Mad King Thorn is pleased by your undying support. Survive his celebration for bonus treats!
	; Concise description
	; Spell. Mad King Thorn is pleased by your undying support. Survive his celebration for bonus treats!
	Return UAI_GetPlayerInfo($GC_UAI_AGENT_ID)
EndFunc

; Skill ID: 2803 - $GC_I_SKILL_ID_MIND_FREEZE_PVP
Func CanUse_MindFreezePvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MindFreezePvp($a_f_AggroRange)
	; PVP variant of MindFreeze
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 2906 - $GC_I_SKILL_ID_TARGET_ACQUISITION
Func CanUse_TargetAcquisition()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_TargetAcquisition($a_f_AggroRange)
	; Description
	; Hex Spell. Target foe is Marked and can no longer evade attacks.
	; Concise description
	; Spell. Target foe is Marked and can no longer evade attacks.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2916 - $GC_I_SKILL_ID_NOX_PHANTOM
Func CanUse_NoxPhantom()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_NoxPhantom($a_f_AggroRange)
	; Description
	; Hex Spell. Launches a net. If it hits, your target is knocked down, and their movement speed is -66% for 10 seconds.
	; Concise description
	; Spell. Launches a net. If it hits, your target is knocked down, and their movement speed is -66% for 10 seconds.
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 2937 - ;  $GC_I_SKILL_ID_UNKNOWN
; Skill ID: 2942 - ;  $GC_I_SKILL_ID_UNKNOWN
; Skill ID: 2944 - ;  $GC_I_SKILL_ID_UNKNOWN
; Skill ID: 2945 - ;  $GC_I_SKILL_ID_UNKNOWN
; Skill ID: 2947 - ;  $GC_I_SKILL_ID_UNKNOWN
; Skill ID: 2950 - ;  $GC_I_SKILL_ID_UNKNOWN
; Skill ID: 2998 - $GC_I_SKILL_ID_FRAGILITY_PVP
Func CanUse_FragilityPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_FragilityPvp($a_f_AggroRange)
	; PVP variant of Fragility
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_ADJACENT, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 3086 - $GC_I_SKILL_ID_WEIGHT_OF_DHUUM_HEX
Func CanUse_WeightOfDhuumHex()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WeightOfDhuumHex($a_f_AggroRange)
	; Hex Spell - target lowest HP enemy
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 3151 - $GC_I_SKILL_ID_EMPATHY_PVP
Func CanUse_EmpathyPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EmpathyPvp($a_f_AggroRange)
	; PVP variant of Empathy - target attacking enemies for maximum effect
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 3152 - $GC_I_SKILL_ID_CRIPPLING_ANGUISH_PVP
Func CanUse_CripplingAnguishPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CripplingAnguishPvp($a_f_AggroRange)
	; PVP variant of CripplingAnguish
	Local $l_i_Target = UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsAttacking")
	If $l_i_Target <> 0 Then Return $l_i_Target
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 3182 - $GC_I_SKILL_ID_PANIC_PVP
Func CanUse_PanicPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PanicPvp($a_f_AggroRange)
	; PVP variant of Panic
	Return UAI_GetBestAOETarget(-2, 1320, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 3183 - $GC_I_SKILL_ID_MIGRAINE_PVP
Func CanUse_MigrainePvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MigrainePvp($a_f_AggroRange)
	; PVP variant of Migraine
	Return UAI_GetAgentLowest(-2, $a_f_AggroRange, $GC_UAI_AGENT_HP, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsCaster")
EndFunc

; Skill ID: 3186 - $GC_I_SKILL_ID_SHARED_BURDEN_PVP
Func CanUse_SharedBurdenPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SharedBurdenPvp($a_f_AggroRange)
	; PVP variant of SharedBurden
	Return UAI_GetBestAOETarget(-2, $a_f_AggroRange, $GC_I_RANGE_NEARBY, "UAI_Filter_IsLivingEnemy")
EndFunc

; Skill ID: 3187 - $GC_I_SKILL_ID_STOLEN_SPEED_PVP
Func CanUse_StolenSpeedPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_StolenSpeedPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3190 - $GC_I_SKILL_ID_FRUSTRATION_PVP
Func CanUse_FrustrationPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_FrustrationPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3191 - $GC_I_SKILL_ID_MISTRUST_PVP
Func CanUse_MistrustPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_MistrustPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3192 - $GC_I_SKILL_ID_ENCHANTERS_CONUNDRUM_PVP
Func CanUse_EnchantersConundrumPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_EnchantersConundrumPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3195 - $GC_I_SKILL_ID_WANDERING_EYE_PVP
Func CanUse_WanderingEyePvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WanderingEyePvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3196 - $GC_I_SKILL_ID_CALCULATED_RISK_PVP
Func CanUse_CalculatedRiskPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_CalculatedRiskPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3200 - $GC_I_SKILL_ID_ISAIAHS_BALANCE
Func CanUse_IsaiahsBalance()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_IsaiahsBalance($a_f_AggroRange)
	; Description
	; Hex Spell. (20 seconds.) Also hexes nearby foes. The next skill used by target foes cost 25 Energy and recharges in 90 seconds.
	; Concise description
	; Spell. (20 seconds.) Also hexes nearby foes. The next skill used by target foes cost 25 Energy and recharges in 90 seconds.
	Return 0
EndFunc

; Skill ID: 3208 - $GC_I_SKILL_ID_WASTRELS_DEMISE_PVP
Func CanUse_WastrelsDemisePvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WastrelsDemisePvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3233 - $GC_I_SKILL_ID_SPOIL_VICTOR_PVP
Func CanUse_SpoilVictorPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SpoilVictorPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3234 - $GC_I_SKILL_ID_VISIONS_OF_REGRET_PVP
Func CanUse_VisionsOfRegretPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_VisionsOfRegretPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3243 - $GC_I_SKILL_ID_PROMISE_OF_DEATH
Func CanUse_PromiseOfDeath()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_PromiseOfDeath($a_f_AggroRange)
	; Description
	; Hex Spell. Target foe is Marked and can no longer evade attacks.
	; Concise description
	; Spell. Target foe is Marked and can no longer evade attacks.
	Return 0
EndFunc

; Skill ID: 3289 - $GC_I_SKILL_ID_FEVERED_DREAMS_PVP
Func CanUse_FeveredDreamsPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_FeveredDreamsPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3302 - $GC_I_SKILL_ID_SKY_NET
Func CanUse_SkyNet()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_SkyNet($a_f_AggroRange)
	; Description
	; Hex Spell. Launches a net. If it hits, your target is knocked down, and their movement speed is -66% for 10 seconds.
	; Concise description
	; Spell. Launches a net. If it hits, your target is knocked down, and their movement speed is -66% for 10 seconds.
	Return 0
EndFunc

; Skill ID: 3374 - $GC_I_SKILL_ID_ILLUSION_OF_PAIN_PVP
Func CanUse_IllusionOfPainPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_IllusionOfPainPvp($a_f_AggroRange)
	Return 0
EndFunc

; Skill ID: 3386 - $GC_I_SKILL_ID_WEB_OF_DISRUPTION_PVP
Func CanUse_WebOfDisruptionPvp()
	If Anti_Hex() Then Return False
	Return True
EndFunc

Func BestTarget_WebOfDisruptionPvp($a_f_AggroRange)
	Return 0
EndFunc

