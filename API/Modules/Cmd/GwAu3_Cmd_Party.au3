#include-once

;~ Description: Adds a hero to the party.
Func Party_AddHero($a_i_HeroId)
    Return Core_SendPacket(0x8, $GC_I_HEADER_HERO_ADD, $a_i_HeroId)
EndFunc   ;==>Party_AddHero

;~ Description: Kicks a hero from the party.
Func Party_KickHero($a_i_HeroId)
    Return Core_SendPacket(0x8, $GC_I_HEADER_HERO_KICK, $a_i_HeroId)
EndFunc   ;==>Party_KickHero

;~ Description: Kicks all heroes from the party.
Func Party_KickAllHeroes()
    Return Core_SendPacket(0x8, $GC_I_HEADER_HERO_KICK, 0x28)
EndFunc   ;==>Party_KickAllHeroes

;~ Description: Add a henchman to the party.
Func Party_AddNpc($a_i_NpcId)
    Return Core_SendPacket(0x8, $GC_I_HEADER_PARTY_INVITE_NPC, $a_i_NpcId)
EndFunc   ;==>Party_AddNpc

;~ Description: Kick a henchman from the party.
Func Party_KickNpc($a_i_NpcId)
    Return Core_SendPacket(0x8, $GC_I_HEADER_PARTY_KICK_NPC, $a_i_NpcId)
EndFunc   ;==>Party_KickNpc

;~ Description: Tick on party group.
Func Party_Tick($a_b_Tick = True)
    Return Core_SendPacket(0x8, $GC_I_HEADER_PARTY_TICK, $a_b_Tick)
EndFunc   ;==>Party_KickNpc

;~ Description: Clear the position flag from a hero.
Func Party_CancelHero($a_i_HeroNumber)
    Local $l_i_AgentID = Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID")
    Return Core_SendPacket(0x14, $GC_I_HEADER_HERO_FLAG_SINGLE, $l_i_AgentID, 0x7F800000, 0x7F800000, 0)
EndFunc   ;==>Party_CancelHero

;~ Description: Clear the position flag from all heroes.
Func Party_CancelAll()
    Return Core_SendPacket(0x10, $GC_I_HEADER_HERO_FLAG_ALL, 0x7F800000, 0x7F800000, 0)
EndFunc   ;==>Party_CancelAll

;~ Description: Place a hero's position flag.
Func Party_CommandHero($a_i_HeroNumber, $a_f_X, $a_f_Y)
    Return Core_SendPacket(0x14, $GC_I_HEADER_HERO_FLAG_SINGLE, Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID"), Utils_FloatToInt($a_f_X), Utils_FloatToInt($a_f_Y), 0)
EndFunc   ;==>Party_CommandHero

;~ Description: Place the full-party position flag.
Func Party_CommandAll($a_f_X, $a_f_Y)
    Return Core_SendPacket(0x10, $GC_I_HEADER_HERO_FLAG_ALL, Utils_FloatToInt($a_f_X), Utils_FloatToInt($a_f_Y), 0)
EndFunc   ;==>Party_CommandAll

;~ Description: Lock a hero onto a target.
Func Party_LockHeroTarget($a_i_HeroNumber, $a_i_AgentID = 0) ;$a_i_AgentID=0 Cancels Lock
    Return Core_SendPacket(0xC, $GC_I_HEADER_HERO_LOCK_TARGET, Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID"), $a_i_AgentID)
EndFunc   ;==>Party_LockHeroTarget

;~ Description: Change a hero's aggression level.
Func Party_SetHeroAggression($a_i_HeroNumber, $a_i_Aggression) ;0=Fight, 1=Guard, 2=Avoid
    Return Core_SendPacket(0xC, $GC_I_HEADER_HERO_BEHAVIOR, Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID"), $a_i_Aggression)
EndFunc   ;==>Party_SetHeroAggression

;~ Description: Internal use for enabling or disabling hero skills
Func Party_ToggleHeroSkillState($a_i_HeroNumber, $a_i_SkillSlot)
    Return Core_SendPacket(0xC, $GC_I_HEADER_HERO_SKILL_TOGGLE, Party_GetMyPartyHeroInfo($a_i_HeroNumber, "AgentID"), $a_i_SkillSlot - 1)
EndFunc   ;==>Party_ToggleHeroSkillState

;~ Description: Tests if a hero's skill slot is disabled.
Func Party_GetIsHeroSkillDisabled($a_i_HeroNumber, $a_i_SkillSlot)
	Return BitAND(2 ^ ($a_i_SkillSlot - 1), Skill_GetSkillbarInfo($a_i_SkillSlot, "Disabled", $a_i_HeroNumber)) > 0
EndFunc   ;==>Party_GetIsHeroSkillDisabled

;~ Description: Enable a skill on a hero's skill bar.
Func Party_EnableHeroSkill($a_i_HeroNumber, $a_i_SkillSlot)
	If Party_GetIsHeroSkillDisabled($a_i_HeroNumber, $a_i_SkillSlot) Then Party_ToggleHeroSkillState($a_i_HeroNumber, $a_i_SkillSlot)
EndFunc   ;==>Party_EnableHeroSkillSlot

;~ Description: Disable a skill on a hero's skill bar.
Func Party_DisableHeroSkill($a_i_HeroNumber, $a_i_SkillSlot)
	If Not Party_GetIsHeroSkillDisabled($a_i_HeroNumber, $a_i_SkillSlot) Then Party_ToggleHeroSkillState($a_i_HeroNumber, $a_i_SkillSlot)
	Return True
EndFunc   ;==>Party_DisableHeroSkillSlot

;~ Description: Leave your party.
Func Party_LeaveGroup($a_b_KickHeroes = True)
    If $a_b_KickHeroes Then Party_KickAllHeroes()
    Return Core_SendPacket(0x4, $GC_I_HEADER_PARTY_LEAVE_GROUP)
EndFunc   ;==>Party_LeaveGroup

;~ Description: Add player via the Party Formation window.
Func Party_AddPlayer($a_i_PlayerNumber)
    DllStructSetData($g_d_AddPlayer, 2, $a_i_PlayerNumber)
    Core_Enqueue($g_p_AddPlayer, 8)
EndFunc   ;==>Party_AddPlayer

;~ Description: Kick player via the Party Formation window.
Func Party_KickPlayer($a_i_PlayerNumber)
    DllStructSetData($g_d_KickPlayer, 2, $a_i_PlayerNumber)
    Core_Enqueue($g_p_KickPlayer, 8)
EndFunc   ;==>Party_KickPlayer

;~ Description: Kick invited player via the Party Formation window.
Func Party_KickInvitedPlayer($a_i_PartyID)
    DllStructSetData($g_d_KickInvitedPlayer, 2, $a_i_PartyID)
    Core_Enqueue($g_p_KickInvitedPlayer, 8)
EndFunc   ;==>Party_KickInvitedPlayer

;~ Description: Reject party invitation via the Party Formation window.
Func Party_RejectInvitation($a_i_PartyID)
    DllStructSetData($g_d_RejectInvitation, 2, $a_i_PartyID)
    Core_Enqueue($g_p_RejectInvitation, 8)
EndFunc   ;==>Party_RejectInvitation

;~ Description: Accept party invitation via the Party Formation window.
Func Party_AcceptInvitation($a_i_PartyID)
    DllStructSetData($g_d_AcceptInvitation, 2, $a_i_PartyID)
    Core_Enqueue($g_p_AcceptInvitation, 8)
EndFunc   ;==>Party_AcceptInvitation
