#include-once

;~ Description: Accept a quest from an NPC.
Func Quest_AcceptQuest($a_i_QuestID)
    Return Core_SendPacket(0x8, $GC_I_HEADER_DIALOG_SEND, '0x008' & Hex($a_i_QuestID, 3) & '01')
EndFunc   ;==>AcceptQuest

;~ Description: Accept the reward for a quest.
Func Quest_QuestReward($a_i_QuestID)
    Return Core_SendPacket(0x8, $GC_I_HEADER_DIALOG_SEND, '0x008' & Hex($a_i_QuestID, 3) & '07')
EndFunc   ;==>QuestReward

;~ Description: Abandon a quest.
Func Quest_AbandonQuest($a_i_QuestID)
    Return Core_SendPacket(0x8, $GC_I_HEADER_QUEST_ABANDON, $a_i_QuestID)
EndFunc   ;==>AbandonQuest