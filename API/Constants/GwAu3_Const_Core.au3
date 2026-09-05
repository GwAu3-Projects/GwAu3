#include-once

#Region Global Variables
; Pattern types
Global Const $GC_S_PATTERN_TYPE_PTR  = 'Ptr'    ; Pointer to data
Global Const $GC_S_PATTERN_TYPE_FUNC = 'Func'  ; Function to call
Global Const $GC_S_PATTERN_TYPE_HOOK = 'Hook'  ; Hook/injection point

Global $g_d_InviteGuild = DllStructCreate('ptr;dword;dword header;dword counter;wchar name[32];dword type')
Global $g_p_InviteGuild = DllStructGetPtr($g_d_InviteGuild)

Global $g_d_SendChat = DllStructCreate('ptr;dword')
Global $g_p_SendChat = DllStructGetPtr($g_d_SendChat)

Global $g_d_Action = DllStructCreate('ptr;dword;dword;dword')
Global $g_p_Action = DllStructGetPtr($g_d_Action)

Global $g_d_Packet = DllStructCreate('ptr;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword;dword')
Global $g_p_Packet = DllStructGetPtr($g_d_Packet)

Global $g_d_SkillLog = DllStructCreate('dword;dword;dword');float')
Global $g_p_SkillLog = DllStructGetPtr($g_d_SkillLog)
Global $g_h_GUI = 0

Global $g_p_BasePointer
Global $g_p_PacketLocation
Global $g_p_SavedIndex
Global $g_i_QueueCounter
Global $g_i_QueueSize
Global $g_p_QueueBase
Global $g_p_PreGame
Global $g_p_Login
Global $g_p_InGame
Global $g_p_FrameArray
Global $g_p_AreaInfo
Global $g_p_StatusCode
Global $g_p_MapIsLoaded
Global $g_p_TradePartner
Global $g_p_SceneContext
Global $g_p_TimeOnMap

;Skill
Global $g_p_SkillBase
Global $g_p_SkillTimer
Global $g_d_UseSkill = DllStructCreate('ptr;dword;dword;dword;bool')
Global $g_p_UseSkill = DllStructGetPtr($g_d_UseSkill)
Global $g_d_UseHeroSkill = DllStructCreate('ptr;dword;dword;dword')
Global $g_p_UseHeroSkill = DllStructGetPtr($g_d_UseHeroSkill)
Global $g_d_CancelHeroSkill = DllStructCreate('ptr;dword;dword')
Global $g_p_CancelHeroSkill = DllStructGetPtr($g_d_CancelHeroSkill)
Global $g_i_LastSkillUsed = 0
Global $g_i_LastSkillTarget = 0

;Friend
Global $g_p_FriendList
Global $g_d_ChangeStatus = DllStructCreate('ptr;dword')
Global $g_p_ChangeStatus = DllStructGetPtr($g_d_ChangeStatus)
Global $g_d_AddFriend = DllStructCreate('ptr;ptr;ptr;dword')
Global $g_p_AddFriend = DllStructGetPtr($g_d_AddFriend)
Global $g_d_RemoveFriend = DllStructCreate('ptr;byte[16];ptr;dword')
Global $g_p_RemoveFriend = DllStructGetPtr($g_d_RemoveFriend)
Global $g_i_LastStatus = 0

;Attribute
Global $g_p_AttributeInfo
Global $g_d_IncreaseAttribute = DllStructCreate('ptr;dword;dword')
Global $g_p_IncreaseAttribute = DllStructGetPtr($g_d_IncreaseAttribute)
Global $g_d_DecreaseAttribute = DllStructCreate('ptr;dword;dword')
Global $g_p_DecreaseAttribute = DllStructGetPtr($g_d_DecreaseAttribute)
Global $g_i_LastAttributeModified = -1
Global $g_i_LastAttributeValue = -1

;Trader
Global $g_p_BuyItemBase      ; Pointer to buy item base
Global $g_i_TraderQuoteID    ; Current trader quote ID
Global $g_i_TraderCostID     ; Trader cost ID
Global $g_f_TraderCostValue  ; Trader cost value
Global $g_p_SalvageGlobal    ; Pointer to salvage global data
Global $g_d_SellItem = DllStructCreate('ptr;dword;dword;dword')
Global $g_p_SellItem = DllStructGetPtr($g_d_SellItem)
Global $g_d_BuyItem = DllStructCreate('ptr;dword;dword;dword;dword')
Global $g_p_BuyItem = DllStructGetPtr($g_d_BuyItem)
Global $g_d_RequestQuote = DllStructCreate('ptr;dword')
Global $g_p_RequestQuote = DllStructGetPtr($g_d_RequestQuote)
Global $g_d_RequestQuoteSell = DllStructCreate('ptr;dword')
Global $g_p_RequestQuoteSell = DllStructGetPtr($g_d_RequestQuoteSell)
Global $g_d_TraderBuy = DllStructCreate('ptr')
Global $g_p_TraderBuy = DllStructGetPtr($g_d_TraderBuy)
Global $g_d_TraderSell = DllStructCreate('ptr')
Global $g_p_TraderSell = DllStructGetPtr($g_d_TraderSell)
Global $g_d_Salvage = DllStructCreate('ptr;dword;dword;dword')
Global $g_p_Salvage = DllStructGetPtr($g_d_Salvage)

;Item
Global $g_i_InvCanIdentifyAllResult ; Result slot for InvCanIdentifyAll
Global $g_i_InvIdentifyAllResult    ; Result slot for InvIdentifyAll
Global $g_d_InvCanIdentifyAll = DllStructCreate('ptr')
Global $g_p_InvCanIdentifyAll = DllStructGetPtr($g_d_InvCanIdentifyAll)
Global $g_d_InvIdentifyAll = DllStructCreate('ptr')
Global $g_p_InvIdentifyAll = DllStructGetPtr($g_d_InvIdentifyAll)
Global $g_i_InvCanDepositAllMaterialsResult ; Result slot for InvCanDepositAllMaterials
Global $g_i_InvDepositAllMaterialsResult    ; Result slot for InvDepositAllMaterials
Global $g_d_InvCanDepositAllMaterials = DllStructCreate('ptr')
Global $g_p_InvCanDepositAllMaterials = DllStructGetPtr($g_d_InvCanDepositAllMaterials)
Global $g_d_InvDepositAllMaterials = DllStructCreate('ptr')
Global $g_p_InvDepositAllMaterials = DllStructGetPtr($g_d_InvDepositAllMaterials)
Global $g_d_DropBundle = DllStructCreate('ptr')
Global $g_p_DropBundle = DllStructGetPtr($g_d_DropBundle)
Global $g_i_LastTransactionType = -1
Global $g_i_LastItemID = 0
Global $g_i_LastQuantity = 0
Global $g_i_LastPrice = 0
Global $g_p_CraftItem
Global $g_p_CollectorExchange

;Agent
Global $g_p_AgentBase      ; Pointer to agent array
Global $g_i_MaxAgents      ; Maximum number of agents
Global $g_i_MyID           ; Player's agent ID
Global $g_i_CurrentTarget  ; Current target agent ID
Global $g_i_AgentCopyCount ; Count of copied agents
Global $g_p_AgentCopyBase  ; Base address of agent copy array
Global $g_d_ChangeTarget = DllStructCreate('ptr;dword')
Global $g_p_ChangeTarget = DllStructGetPtr($g_d_ChangeTarget)
Global $g_d_MakeAgentArray = DllStructCreate('ptr;dword')
Global $g_p_MakeAgentArray = DllStructGetPtr($g_d_MakeAgentArray)
Global $g_i_LastTargetID = 0

;Map
Global $g_p_InstanceInfo     ; Pointer to instance information
Global $g_p_WorldConst       ; Pointer to world constants
Global $g_p_Region
Global $g_d_Move = DllStructCreate('ptr;float;float;dword')
Global $g_p_Move = DllStructGetPtr($g_d_Move)
Global $g_f_LastMoveX = 0
Global $g_f_LastMoveY = 0
Global $g_f_ClickCoordsX = 0
Global $g_f_ClickCoordsY = 0
Global $g_d_RedirectMap = DllStructCreate('ptr;dword;dword;dword;dword;dword;dword') ; Slade
Global $g_p_RedirectMap = DllStructGetPtr($g_d_RedirectMap) ; Slade

;Trade
Global $g_d_TradeInitiate = DllStructCreate('ptr;dword;dword')
Global $g_p_TradeInitiate = DllStructGetPtr($g_d_TradeInitiate)
Global $g_d_TradeCancel = DllStructCreate('ptr')
Global $g_p_TradeCancel = DllStructGetPtr($g_d_TradeCancel)
Global $g_d_TradeAccept = DllStructCreate('ptr')
Global $g_p_TradeAccept = DllStructGetPtr($g_d_TradeAccept)
Global $g_d_TradeSubmitOffer = DllStructCreate('ptr;dword')
Global $g_p_TradeSubmitOffer = DllStructGetPtr($g_d_TradeSubmitOffer)
Global $g_d_TradeOfferItem = DllStructCreate('ptr;dword;dword')
Global $g_p_TradeOfferItem = DllStructGetPtr($g_d_TradeOfferItem)

;UI
Global $g_d_Dialog = DllStructCreate('ptr;dword')
Global $g_p_Dialog = DllStructGetPtr($g_d_Dialog)
Global $g_d_Interact = DllStructCreate('ptr;dword')
Global $g_p_Interact = DllStructGetPtr($g_d_Interact)
Global $g_d_Xunlai = DllStructCreate('ptr;dword')
Global $g_p_Xunlai = DllStructGetPtr($g_d_Xunlai)
Global $g_d_AddNPC = DllStructCreate('ptr;dword')
Global $g_p_AddNPC = DllStructGetPtr($g_d_AddNPC)
Global $g_d_AddHero = DllStructCreate('ptr;dword')
Global $g_p_AddHero = DllStructGetPtr($g_d_AddHero)
Global $g_d_KickNPC = DllStructCreate('ptr;dword')
Global $g_p_KickNPC = DllStructGetPtr($g_d_KickNPC)
Global $g_d_KickHero = DllStructCreate('ptr;dword')
Global $g_p_KickHero = DllStructGetPtr($g_d_KickHero)
Global $g_d_LeaveGroup = DllStructCreate('ptr;dword')
Global $g_p_LeaveGroup = DllStructGetPtr($g_d_LeaveGroup)
Global $g_d_SetDifficulty = DllStructCreate('ptr;dword')
Global $g_p_SetDifficulty = DllStructGetPtr($g_d_SetDifficulty)
Global $g_d_EnterMission = DllStructCreate('ptr;dword')
Global $g_p_EnterMission = DllStructGetPtr($g_d_EnterMission)
Global $g_d_FlagHero = DllStructCreate('ptr;dword;dword;dword;dword')
Global $g_p_FlagHero = DllStructGetPtr($g_d_FlagHero)
Global $g_d_FlagAll = DllStructCreate('ptr;dword;dword;dword')
Global $g_p_FlagAll = DllStructGetPtr($g_d_FlagAll)
Global $g_d_SetHeroBehavior = DllStructCreate('ptr;dword;dword')
Global $g_p_SetHeroBehavior = DllStructGetPtr($g_d_SetHeroBehavior)
Global $g_d_DropHeroBundle = DllStructCreate('ptr;dword')
Global $g_p_DropHeroBundle = DllStructGetPtr($g_d_DropHeroBundle)
Global $g_d_LockHeroTarget = DllStructCreate('ptr;dword;dword')
Global $g_p_LockHeroTarget = DllStructGetPtr($g_d_LockHeroTarget)
Global $g_d_ToggleHeroSkillState = DllStructCreate('ptr;dword;dword')
Global $g_p_ToggleHeroSkillState = DllStructGetPtr($g_d_ToggleHeroSkillState)
Global $g_d_ActiveQuest = DllStructCreate('ptr;dword')
Global $g_p_ActiveQuest = DllStructGetPtr($g_d_ActiveQuest)

;UIMsg
Global $g_d_MoveMap = DllStructCreate('ptr;dword;dword;dword;dword;dword')
Global $g_p_MoveMap = DllStructGetPtr($g_d_MoveMap)
Global $g_d_ApplyUpgrade = DllStructCreate('ptr;dword;dword;dword;dword;dword')
Global $g_p_ApplyUpgrade = DllStructGetPtr($g_d_ApplyUpgrade)
Global $g_d_EquipItem = DllStructCreate('ptr;dword;dword;dword')
Global $g_p_EquipItem = DllStructGetPtr($g_d_EquipItem)

;Party
Global $g_d_AddPlayer = DllStructCreate('ptr;dword')
Global $g_p_AddPlayer = DllStructGetPtr($g_d_AddPlayer)
Global $g_d_KickPlayer = DllStructCreate('ptr;dword')
Global $g_p_KickPlayer = DllStructGetPtr($g_d_KickPlayer)
Global $g_d_KickInvitedPlayer = DllStructCreate('ptr;dword')
Global $g_p_KickInvitedPlayer = DllStructGetPtr($g_d_KickInvitedPlayer)
Global $g_d_RejectInvitation = DllStructCreate('ptr;dword')
Global $g_p_RejectInvitation = DllStructGetPtr($g_d_RejectInvitation)
Global $g_d_AcceptInvitation = DllStructCreate('ptr;dword')
Global $g_p_AcceptInvitation = DllStructGetPtr($g_d_AcceptInvitation)

;Bot related
Global $g_bAutoStart = False  ; Flag for auto-start
Global $g_s_MainCharName  = ""

;Prop ray casting
Global Const $GC_I_PROPRAY_MAX = 8            ; Rays carried by a single command
Global Const $GC_I_PROPRAY_INPUT_SIZE = 28    ; Bytes per ray: origin[3] + dir[3] + dist
Global Const $GC_I_PROPRAY_RESULT_SIZE = 12   ; Bytes per result: hit + distance + prop index
Global Const $GC_I_PROPRAY_STATE_PENDING = 0  ; Command not processed yet
Global Const $GC_I_PROPRAY_STATE_DONE = 1     ; Results available
Global Const $GC_I_PROPRAY_STATE_SKIPPED = 2  ; No props loaded, native was never called
Global Const $GC_F_PROPRAY_MIN_RANGE = 0.1    ; Below this the engine rejects the ray itself
Global $g_p_PropRayResult       ; Pointer to the result block in GW memory
Global $g_p_PropRayReady        ; Pointer to the completion flag in GW memory
Global $g_d_PropRay = DllStructCreate('ptr;dword;float[56]')  ; Command struct: ptr + count + rays
Global $g_p_PropRay = DllStructGetPtr($g_d_PropRay)

;Trade session natives
Global Const $GC_I_TRADESESS_STATE_PENDING = 0   ; Command not processed yet
Global Const $GC_I_TRADESESS_STATE_DONE = 1      ; Return value available
Global Const $GC_I_TRADESESS_STATE_SKIPPED = 2   ; No trade context, native was never called
Global Const $GC_I_TRADESESS_OP_NONE = 0         ; Context is idle, a new call is accepted
Global Const $GC_I_TRADESESS_OP_ABORT = 1        ; Codes written while a call is in flight
Global Const $GC_I_TRADESESS_OP_CONFIRM = 2
Global Const $GC_I_TRADESESS_OP_OFFERITEM = 3
Global Const $GC_I_TRADESESS_OP_REVOKECONFIRM = 4
Global Const $GC_I_TRADESESS_OP_REVOKEITEM = 5
Global Const $GC_I_TRADESESS_OP_REVOKESUBMIT = 6
Global Const $GC_I_TRADESESS_OP_SUBMIT = 7
Global Const $GC_I_TRADE_FLAG_ACTIVE = 1         ; Trade context flags
Global Const $GC_I_TRADE_FLAG_SUBMITTED = 2
Global Const $GC_I_TRADE_FLAG_CONFIRMED = 4
Global $g_p_TradeSessResult      ; Pointer to the native return value in GW memory
Global $g_p_TradeSessReady       ; Pointer to the completion flag in GW memory
Global $g_d_TradeSession = DllStructCreate('ptr;ptr;dword;dword')  ; Command struct: ptr + native + 2 args
Global $g_p_TradeSession = DllStructGetPtr($g_d_TradeSession)

;EncString Decoding
Global $g_p_DecodeInputPtr      ; Pointer to encoded string input buffer in GW memory
Global $g_p_DecodeOutputPtr     ; Pointer to decoded string output buffer in GW memory
Global $g_p_DecodeReady         ; Pointer to ready flag in GW memory
Global $g_d_DecodeEncString = DllStructCreate('ptr;wchar[128]')  ; Command struct: ptr to command + encoded string
Global $g_p_DecodeEncString = DllStructGetPtr($g_d_DecodeEncString)
#EndRegion Global Variables
