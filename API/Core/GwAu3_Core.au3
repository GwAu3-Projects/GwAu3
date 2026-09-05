#include-once

If @AutoItX64 Then
    MsgBox(16, "GwAu3 - Invalid runtime architecture", "All bot scripts must be run in 32-bit (x86) mode.")
    Exit
EndIf

#Region Slade

Func MemoryRead($aAddress, $aType = 'DWORD')
    Local $lBuffer = DllStructCreate($aType)
    DllCall($g_h_Kernel32, 'int', 'ReadProcessMemory', 'int', $g_h_GWProcess, 'int', $aAddress, 'PTR', DllStructGetPtr($lBuffer), 'int', DllStructGetSize($lBuffer), 'int', '')
    Return DllStructGetData($lBuffer, 1)
EndFunc   ;==>MemoryRead

Func FindPattern(ByRef $aBuffer, $aPattern, $aOffset = 0)
    Local $lPattern = BinaryToString('0x' & $aPattern)
    Local $lAddr = StringInStr($aBuffer, $lPattern, 2)
    If @error Then Exit MsgBox(0, 'Error', 'FindPattern failed: ' & $aPattern)
    Return $lAddr - 1 + $aOffset
EndFunc

Func GetModuleInfo(ByRef $aModuleBase, ByRef $aModuleSize)
    Local $lProcName = _WinAPI_GetProcessName($g_i_GWProcessId)
    Local $lProcNameLength = StringLen($lProcName)

    Local $lModules = _WinAPI_EnumProcessModules($g_i_GWProcessId)
    For $i = 1 To $lModules[0][0]
        Local $lModuleName = StringRight($lModules[$i][1], $lProcNameLength)
        If StringCompare($lModuleName, $lProcName, $STR_NOCASESENSE) = 0 Then
            Local $lModuleInfo = _WinAPI_GetModuleInformation($g_h_GWProcess, $lModules[$i][0])
            $aModuleBase = DllStructGetData($lModuleInfo, 'BaseOfDll')
            $aModuleSize = DllStructGetData($lModuleInfo, 'SizeOfImage')
            Return True
        EndIf
    Next
    Exit MsgBox(0, 'Error', 'GetModuleInfo failed')
    Return False
EndFunc   ;==>GetModuleInfo

#EndRegion Slade

#Region Initialization
Func Core_Initialize($a_v_GW, $a_b_ChangeTitle = True)
	Log_Info("Checking for updates...", "GwAu3", $g_h_EditText)
	Local $l_i_UpdateStatus = Updater_CheckForGwAu3Updates()
	Switch $l_i_UpdateStatus
		Case 0
			Log_Info("Encountered an error while checking for updates", "GwAu3", $g_h_EditText)
		Case 1
			Log_Info("No updates available", "GwAu3", $g_h_EditText)
		Case 2
			Log_Info("Update has been cancelled", "GwAu3", $g_h_EditText)
		Case 3
			Log_Info("Updates disabled", "GwAu3", $g_h_EditText)
		Case 4
			Log_Info("Update complete", "GwAu3", $g_h_EditText)
	EndSwitch

	Log_Info("Initializing...", "GwAu3", $g_h_EditText)
    ; Character name provided for initializing
	If IsString($a_v_GW) Then
		Local $l_s_CharName = StringStripWS($a_v_GW, 3)
		Local $l_h_ProcessList = ProcessList("gw.exe")
		Local $l_b_Found = False
		For $i = 1 To $l_h_ProcessList[0][0]
			Local $l_i_ProcessID = $l_h_ProcessList[$i][1]
			Memory_Open($l_i_ProcessID)
			If $g_h_GWProcess <> 0 And Scanner_InitializeSections() Then
				Scanner_ScanForCharname()
				If StringCompare(StringStripWS(Player_GetCharName(), 3), $l_s_CharName) = 0 Then
					$g_i_GWProcessId = $l_i_ProcessID
					$g_h_GWWindow = Scanner_GetHwnd($l_i_ProcessID)
					$l_b_Found = True
					ExitLoop
				EndIf
			EndIf
			Memory_Close()
		Next
		If Not $l_b_Found Then Return SetError(1, 0, 0)
	; ProcessID provided for initializing
	Else
		$g_i_GWProcessId = $a_v_GW
		$g_h_GWWindow = Scanner_GetHwnd($a_v_GW)
		Memory_Open($a_v_GW)
		If $g_h_GWProcess <> 0 And Scanner_InitializeSections() Then
			Scanner_ScanForCharname()
		Else
			Memory_Close()
			Return SetError(1, 0, 0)
		EndIf
	EndIf

	Scanner_ClearPatterns()
    ; Core patterns
    Scanner_AddPattern('BasePointer', '506A0F6A00FF35', 0x8, 'Ptr')
    Scanner_AddPattern('Ping', '568B750889165E', -0x3, 'Ptr')
	Scanner_AddPattern('StatusCode', '8945088D45086A04', -0x10, 'Ptr')
	Scanner_AddPattern('Login', '83C420D955ECD955F0', 0x33, 'Ptr')
	Scanner_AddPattern('InGame', '8D7E388907', 0x4D, 'Ptr') 
    Scanner_AddPattern('PacketSend', 'C747540000000081E6', -0x4F, 'Func')
    Scanner_AddPattern('PacketLocation', '83C40433C08BE55DC3A1', 0xB, 'Ptr')
	Scanner_AddPattern('Action', '8B7508578BF983FE09750C6877', -0x3, 'Func')
    Scanner_AddPattern('ActionBase', '8D1C87899DF4', -0x3, 'Ptr')
	Scanner_AddPattern('Environment', '6BC67C5E05', 0x6, 'Ptr')
    Scanner_AddPattern('PreGame', "P:\Code\Gw\Ui\UiPregame.cpp", "!s_scene", 'Ptr')
    Scanner_AddPattern('FrameArray', "P:\Code\Engine\Frame\FrMsg.cpp", "frame", 'Ptr')
	Scanner_AddPattern('SceneContext', 'D9E0D95DFC8B01', 0x0, 'Ptr')
	; Skill patterns
	Scanner_AddPattern('SkillBase', '69C6A40000005E', 0x9, 'Ptr') ;/ Scanner_AddPattern('SkillBase', "P:\Code\Gw\Const\ConstSkill.cpp", "index < arrsize(s_skill)", 'Ptr', 0x16) ;or 0x15
    Scanner_AddPattern('SkillTimer', 'FFD68B4DF08BD88B4708', -0x3, 'Ptr')
    Scanner_AddPattern('UseSkill', '85F6745B83FE1174', -0x127, 'Func')
    Scanner_AddPattern('UseHeroSkill', 'BA02000000B954080000', -0x59, 'Func')
	; Friend patterns
	Scanner_AddPattern('FriendList', "P:\Code\Gw\Friend\FriendApi.cpp", "friendName && *friendName", 'Ptr')
    Scanner_AddPattern('PlayerStatus', '83FE037740FF24B50000000033C0', -0x25, 'Func')
    Scanner_AddPattern('AddFriend', '8B751083FE037465', -0x47, 'Func')
    Scanner_AddPattern('RemoveFriend', '83F803741D83F8047418', 0x0, 'Func')
    ; Attribute patterns
;~ 	Scanner_AddPattern('AttributeInfo', "P:\Code\Gw\Const\ConstAttrib.cpp", "index < arrsize(s_attrib)", 'Ptr', 0x12)
    Scanner_AddPattern('AttributeInfo', 'BA3300000089088d4004', -0x3, 'Ptr')
    Scanner_AddPattern('IncreaseAttribute', '8B7D088B702C8B1F3B9E00050000', -0x5A, 'Func')
    Scanner_AddPattern('DecreaseAttribute', '8B8AA800000089480C5DC3CC', 0x19, 'Func')
    ; Trade patterns
    Scanner_AddPattern('Transaction', '85FF741D8B4D14EB08', -0x7E, 'Func')
    Scanner_AddPattern('BuyItemBase', 'D9EED9580CC74004', 0xF, 'Ptr')
    Scanner_AddPattern('RequestQuote', '8B752083FE107614', -0x34, 'Func')
 	Scanner_AddPattern('Salvage','33C58945FC8B45088945F08B450C8945F48B45108945F88D45EC506A10C745EC77', -0xA, 'Func')
	;~ Scanner_AddPattern('Salvage','33C58945FC8B45088945F08B450C8945F48B45108945F88D45EC506A10C745EC76', -0xA, 'Func')
    Scanner_AddPattern('SalvageGlobal', '8B4A04538945F48B4208', 0x1, 'Ptr')
    ; Item patterns
    Scanner_AddPattern('InvCanIdentifyAll', '558BEC83EC??A1????????33C58945FC8D45??50E8????????8B45??83C40483F8FF????????000057', 0x1, 'Func')
    Scanner_AddPattern('InvIdentifyAll', '558BEC83EC??A1????????33C58945FC8D45??50E8????????8B45??83C40483F8FF????????000053', 0x1, 'Func')
    Scanner_AddPattern('InvCanDepositAllMaterials', '558BEC83EC??5733FF33C0538945FC568D4D??C745??000000005150', 0x1, 'Func')
    Scanner_AddPattern('InvDepositAllMaterials', '558BEC83EC??A1????????33C58945FC53565733FF897D??EB068D9B', 0x1, 'Func')
    Scanner_AddPattern('DropBundle', '8378480675058B4024EB0233C085C07405E8', 0x1, 'Ptr')
    ; Map patterns
    Scanner_AddPattern('QueryPropIntersect', '558BEC83EC??535657E8????????8B40148B587C', 0x1, 'Func')
    ; Trade patterns
    Scanner_AddPattern('TradeSessOfferItem', 'C74204030000', -0x17, 'Func')
    Scanner_AddPattern('TradeSessSubmit', 'C74104070000', -0x14, 'Func')
    Scanner_AddPattern('TradeSessConfirm', 'C74604020000005E', -0x1e, 'Func')
    Scanner_AddPattern('TradeSessAbort', 'C7460401000000B8', -0x16, 'Func')
    Scanner_AddPattern('TradeSessRevokeItem', 'C746040500000089', -0x1d, 'Func')
    Scanner_AddPattern('TradeSessRevokeSubmit', 'C74604060000', -0x16, 'Func')
    Scanner_AddPattern('TradeSessRevokeConfirm', 'C7460404000000B8', -0x16, 'Func')
    ; Agent patterns
    Scanner_AddPattern('AgentBase', '8B0C9085C97419', -0x3, 'Ptr')
    Scanner_AddPattern('ChangeTarget', '3BDF0F95', -0x89, 'Func')
	Scanner_AddPattern('CurrentTarget', '83C4085F8BE55DC3CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC55', -0xE, 'Ptr')
    Scanner_AddPattern('MyID', '83EC08568BF13B15', -0x3, 'Ptr')
    ; Map patterns
    Scanner_AddPattern('Move', '558BEC83EC208D45F0', 0x1, 'Func')
    Local $lModuleBase, $lModuleSize ; Slade
    GetModuleInfo($lModuleBase, $lModuleSize) ; Slade
    Local $lBuffer = BinaryToString(MemoryRead($lModuleBase, 'BYTE[' & $lModuleSize & ']')) ; Slade
    Local $lRedirectMapPattern = FindPattern($lBuffer, "FF76248B4DE88D45EC508D4164508D417450FF761CFF7620FF7608FF7604", -0x94) ; Slade
    Scanner_AddPattern('ClickCoords', '8B451C85C0741CD945F8', 0xD, 'Ptr')
    Scanner_AddPattern('InstanceInfo', '6A2C50E80000000083C408C7', 0xE, 'Ptr')
;~ 	Scanner_AddPattern('WorldConst', "P:\Code\Gw\Const\ConstWorld.cpp", "index < arrsize(s_worldData)", 'Ptr', 0x16)
    Scanner_AddPattern('WorldConst', '8D0476C1E00405', 0x8, 'Ptr')
    Scanner_AddPattern('Region', '6A548D46248908', -0x3, 'Ptr')
	Scanner_AddPattern('AreaInfo', '6BC67C5E05', 0x6, 'Ptr')
	; Trade patterns
	Scanner_AddPattern('TradeCancel', 'C745FC01000000506A04', -0x6, 'Func')
	; Ui patterns
	Scanner_AddPattern('UIMessage', 'B900000000E8000000005DC3894508', -0x14, 'Func')
	Scanner_AddPattern('CompassFlag', '8D451050566A5D57', 0x1, 'Func')
	Scanner_AddPattern('PartySearchButtonCallback', '8B450883EC08568BF18B480483F90E', -0x2, 'Func')
	Scanner_AddPattern('PartyWindowButtonCallback', '837d0800578bf97411', -0x2, 'Func')
	Scanner_AddPattern('EnterMission', '83C902890A5D', 0x24, 'Func')
	Scanner_AddPattern('SetDifficulty', '83C41C682A010010', 0x8C, 'Func')
	Scanner_AddPattern('Dialog', '894B248B4B2883E900', 0x16, 'Func')
	Scanner_AddPattern('Interact', '894B248B4B2883E900', 0x26, 'Func')
	Scanner_AddPattern('AiMode', '683A000010FF36', 0x1, 'Ptr')
	Scanner_AddPattern('HeroCommand', '33D268E0010000', 0x1, 'Ptr')
	Scanner_AddPattern('HeroSkills', '8B4E04505185FF', 0x1, 'Ptr')
	Scanner_AddPattern('PlayerAdd', "P:\Code\Gw\Ui\Game\Party\PtInvite.cpp", "m_invitePlayerId", 'Ptr')
	Scanner_AddPattern('PlayerKick', "P:\Code\Gw\Ui\Game\Party\PtUtil.cpp", "playerId == MissionCliGetPlayerId()", 'Ptr')
	Scanner_AddPattern('PartyInvitations', '8B7D0C8BF083C4048B4704', 0x1, 'Ptr')
	Scanner_AddPattern('ActiveQuest', '8B45083B46040F842D010000', 0x1, 'Ptr')
	; Hook patterns
	Scanner_AddPattern('Engine', '568B3085F67478EB038D4900D9460C', -0x22, 'Hook')
	Scanner_AddPattern('Render', 'F6C401741C68', -0x68, 'Hook')
	Scanner_AddPattern('LoadFinished', '2BD9C1E303', 0xA0, 'Hook')
	Scanner_AddPattern('Trader', '8D4DFC51576A5650', -0x3C, 'Hook')
	Scanner_AddPattern('TradePartner', '6A008D45F8C745F80100000050686501000089', -0xC, 'Hook')
	; EncString Decoding
	Scanner_AddPattern('ValidateAsyncDecodeStr', "P:\Code\Engine\Text\TextApi.cpp", "codedString", 'Func')
	
	If IsDeclared("g_b_AddPattern") Then Extend_AddPattern()

    $g_ap_ScanResults = Scanner_ScanAllPatterns()
	If @error Or Not IsArray($g_ap_ScanResults) Or $g_ap_ScanResults = 0 Then Return SetError(2, 0, 0)

	Local $l_p_Temp
    ;Core
    $g_p_BasePointer = Memory_Read(Scanner_GetScanResult('BasePointer', $g_ap_ScanResults, 'Ptr'))
    $g_p_PacketLocation = Memory_Read(Scanner_GetScanResult('PacketLocation', $g_ap_ScanResults, 'Ptr'))
    $g_p_Ping = Memory_Read(Scanner_GetScanResult('Ping', $g_ap_ScanResults, 'Ptr'))
	$g_p_StatusCode = Memory_Read(Scanner_GetScanResult('StatusCode', $g_ap_ScanResults, 'Ptr'))
	$g_p_Login = Memory_Read(Scanner_GetScanResult('Login', $g_ap_ScanResults, 'Ptr'))
	$g_p_InGame = Memory_Read(Scanner_GetScanResult('InGame', $g_ap_ScanResults, 'Ptr'))
    $g_p_PreGame = Memory_Read(Scanner_GetScanResult('PreGame', $g_ap_ScanResults, 'Ptr') + 0x33)
    $g_p_FrameArray = Memory_Read(Scanner_GetScanResult('FrameArray', $g_ap_ScanResults, 'Ptr') - 0x13)
	$g_p_SceneContext = Memory_Read(Scanner_GetScanResult('SceneContext', $g_ap_ScanResults, 'Ptr') + 0x1B)
	$g_p_TimeOnMap = $g_p_SceneContext + 0xC

	Memory_SetValue('BasePointer', Ptr($g_p_BasePointer))
	Memory_SetValue('PacketLocation', Ptr($g_p_PacketLocation))
	Memory_SetValue('Ping', Ptr($g_p_Ping))
	Memory_SetValue('StatusCode', Ptr($g_p_StatusCode))
	Memory_SetValue('Login', Ptr($g_p_Login))
	Memory_SetValue('InGame', Ptr($g_p_InGame))
	Memory_SetValue('PreGame', Ptr($g_p_PreGame))
	Memory_SetValue('FrameArray', Ptr($g_p_FrameArray))
	Memory_SetValue('SceneContext', Ptr($g_p_SceneContext))
	Memory_SetValue('TimeOnMap', Ptr($g_p_TimeOnMap))
	Memory_SetValue('PacketSend', Ptr(Scanner_GetScanResult('PacketSend', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('ActionBase', Ptr(Memory_Read(Scanner_GetScanResult('ActionBase', $g_ap_ScanResults, 'Ptr'))))
    Memory_SetValue('Action', Ptr(Scanner_GetScanResult('Action', $g_ap_ScanResults, 'Func')))
	Memory_SetValue('Environment', Ptr(Memory_GetScannedAddress('ScanEnvironmentPtr', 0x6)))
	;Core log
	Log_Debug("BasePointer: " & Memory_GetValue('BasePointer'), "Initialize", $g_h_EditText)
	Log_Debug("PacketLocation: " & Memory_GetValue('PacketLocation'), "Initialize", $g_h_EditText)
	Log_Debug("Ping: " & Memory_GetValue('Ping'), "Initialize", $g_h_EditText)
	Log_Debug("StatusCode: " & Memory_GetValue('StatusCode'), "Initialize", $g_h_EditText)
	Log_Debug("Login: " & Memory_GetValue('Login'), "Initialize", $g_h_EditText)
	Log_Debug("InGame: " & Memory_GetValue('InGame'), "Initialize", $g_h_EditText)
	Log_Debug("PreGame: " & Memory_GetValue('PreGame'), "Initialize", $g_h_EditText)
	Log_Debug("FrameArray: " & Memory_GetValue('FrameArray'), "Initialize", $g_h_EditText)
	Log_Debug("SceneContext: " & Memory_GetValue('SceneContext'), "Initialize", $g_h_EditText)
	Log_Debug("TimeOnMap: " & Memory_GetValue('TimeOnMap'), "Initialize", $g_h_EditText)
	Log_Debug("PacketSend: " & Memory_GetValue('PacketSend'), "Initialize", $g_h_EditText)
	Log_Debug("ActionBase: " & Memory_GetValue('ActionBase'), "Initialize", $g_h_EditText)
	Log_Debug("Action: " & Memory_GetValue('Action'), "Initialize", $g_h_EditText)
	Log_Debug("Environment: " & Memory_GetValue('Environment'), "Initialize", $g_h_EditText)

	;Skill
    $g_p_SkillBase = Memory_Read(Scanner_GetScanResult('SkillBase', $g_ap_ScanResults, 'Ptr'))
    $g_p_SkillTimer = Memory_Read(Scanner_GetScanResult('SkillTimer', $g_ap_ScanResults, 'Ptr'))
	$g_i_GWExeStart = Memory_Read($g_p_SkillTimer, 'dword')
	Memory_SetValue('SkillBase', Ptr($g_p_SkillBase))
    Memory_SetValue('SkillTimer', Ptr($g_p_SkillTimer))
    Memory_SetValue('UseSkill', Ptr(Scanner_GetScanResult('UseSkill', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('UseHeroSkill', Ptr(Scanner_GetScanResult('UseHeroSkill', $g_ap_ScanResults, 'Func')))
	;Skill log
	Log_Debug("SkillBase: " & Memory_GetValue('SkillBase'), "Initialize", $g_h_EditText)
	Log_Debug("SkillTimer: " & Memory_GetValue('SkillTimer'), "Initialize", $g_h_EditText)
	Log_Debug("UseSkill: " & Memory_GetValue('UseSkill'), "Initialize", $g_h_EditText)
	Log_Debug("UseHeroSkill: " & Memory_GetValue('UseHeroSkill'), "Initialize", $g_h_EditText)

	;Friend
	$g_p_FriendList = Scanner_GetScanResult('FriendList', $g_ap_ScanResults, 'Ptr')
	$g_p_FriendList = Memory_Read(Scanner_FindInRange("57B9", "xx", 2, $g_p_FriendList, $g_p_FriendList + 0xFF))
	$l_p_Temp = Scanner_GetScanResult("RemoveFriend", $g_ap_ScanResults, 'Func')
	$l_p_Temp = Scanner_FindInRange("50E8", "xx", 1, $l_p_Temp, $l_p_Temp + 0x32)
	$l_p_Temp = Scanner_FunctionFromNearCall($l_p_Temp)
    Memory_SetValue('FriendList', Ptr($g_p_FriendList))
	Memory_SetValue('PlayerStatus', Ptr(Scanner_GetScanResult("PlayerStatus", $g_ap_ScanResults, 'Func')))
    Memory_SetValue('AddFriend', Ptr(Scanner_GetScanResult("AddFriend", $g_ap_ScanResults, 'Func')))
	Memory_SetValue('RemoveFriend', Ptr($l_p_Temp))
	;Friend log
	Log_Debug("FriendList: " & Memory_GetValue('FriendList'), "Initialize", $g_h_EditText)
	Log_Debug("PlayerStatus: " & Memory_GetValue('PlayerStatus'), "Initialize", $g_h_EditText)
	Log_Debug("AddFriend: " & Memory_GetValue('AddFriend'), "Initialize", $g_h_EditText)
	Log_Debug("RemoveFriend: " & Memory_GetValue('RemoveFriend'), "Initialize", $g_h_EditText)

	;Attributes
    $g_p_AttributeInfo = Memory_Read(Scanner_GetScanResult('AttributeInfo', $g_ap_ScanResults, 'Ptr'))
    Memory_SetValue('AttributeInfo', Ptr($g_p_AttributeInfo))
    Memory_SetValue('IncreaseAttribute', Ptr(Scanner_GetScanResult('IncreaseAttribute', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('DecreaseAttribute', Ptr(Scanner_GetScanResult('DecreaseAttribute', $g_ap_ScanResults, 'Func')))
	;Attributes log
	Log_Debug("AttributeInfo: " & Memory_GetValue('AttributeInfo'), "Initialize", $g_h_EditText)
	Log_Debug("IncreaseAttribute: " & Memory_GetValue('IncreaseAttribute'), "Initialize", $g_h_EditText)
	Log_Debug("DecreaseAttribute: " & Memory_GetValue('DecreaseAttribute'), "Initialize", $g_h_EditText)

	;Trader
	$g_p_BuyItemBase = Memory_Read(Scanner_GetScanResult('BuyItemBase', $g_ap_ScanResults, 'Ptr'))
    $g_p_SalvageGlobal = Memory_Read(Scanner_GetScanResult('SalvageGlobal', $g_ap_ScanResults, 'Ptr') - 0x4)
	Memory_SetValue('BuyItemBase', Ptr($g_p_BuyItemBase))
    Memory_SetValue('SalvageGlobal', Ptr($g_p_SalvageGlobal))
    Memory_SetValue('Transaction', Ptr(Scanner_GetScanResult('Transaction', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('RequestQuote', Ptr(Scanner_GetScanResult('RequestQuote', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('Salvage', Ptr(Scanner_GetScanResult('Salvage', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('InvCanIdentifyAll', Ptr(Scanner_GetScanResult('InvCanIdentifyAll', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('InvIdentifyAll', Ptr(Scanner_GetScanResult('InvIdentifyAll', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('InvCanDepositAllMaterials', Ptr(Scanner_GetScanResult('InvCanDepositAllMaterials', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('InvDepositAllMaterials', Ptr(Scanner_GetScanResult('InvDepositAllMaterials', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('DropBundle', Ptr(Scanner_ToFunctionStart(Scanner_GetScanResult('DropBundle', $g_ap_ScanResults, 'Ptr'))))
    Memory_SetValue('QueryPropIntersect', Ptr(Scanner_GetScanResult('QueryPropIntersect', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('TradeSessOfferItem', Ptr(Scanner_GetScanResult('TradeSessOfferItem', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('TradeSessSubmit', Ptr(Scanner_GetScanResult('TradeSessSubmit', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('TradeSessConfirm', Ptr(Scanner_GetScanResult('TradeSessConfirm', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('TradeSessAbort', Ptr(Scanner_GetScanResult('TradeSessAbort', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('TradeSessRevokeItem', Ptr(Scanner_GetScanResult('TradeSessRevokeItem', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('TradeSessRevokeSubmit', Ptr(Scanner_GetScanResult('TradeSessRevokeSubmit', $g_ap_ScanResults, 'Func')))
    Memory_SetValue('TradeSessRevokeConfirm', Ptr(Scanner_GetScanResult('TradeSessRevokeConfirm', $g_ap_ScanResults, 'Func')))
	;Trader log
	Log_Debug("BuyItemBase: " & Memory_GetValue('BuyItemBase'), "Initialize", $g_h_EditText)
	Log_Debug("SalvageGlobal: " & Memory_GetValue('SalvageGlobal'), "Initialize", $g_h_EditText)
	Log_Debug("Transaction: " & Memory_GetValue('Transaction'), "Initialize", $g_h_EditText)
	Log_Debug("RequestQuote: " & Memory_GetValue('RequestQuote'), "Initialize", $g_h_EditText)
	Log_Debug("Salvage: " & Memory_GetValue('Salvage'), "Initialize", $g_h_EditText)
	Log_Debug("InvCanIdentifyAll: " & Memory_GetValue('InvCanIdentifyAll'), "Initialize", $g_h_EditText)
	Log_Debug("InvIdentifyAll: " & Memory_GetValue('InvIdentifyAll'), "Initialize", $g_h_EditText)
	Log_Debug("InvCanDepositAllMaterials: " & Memory_GetValue('InvCanDepositAllMaterials'), "Initialize", $g_h_EditText)
	Log_Debug("InvDepositAllMaterials: " & Memory_GetValue('InvDepositAllMaterials'), "Initialize", $g_h_EditText)
	Log_Debug("DropBundle: " & Memory_GetValue('DropBundle'), "Initialize", $g_h_EditText)
	Log_Debug("QueryPropIntersect: " & Memory_GetValue('QueryPropIntersect'), "Initialize", $g_h_EditText)

	;Agent
	$g_p_AgentBase = Memory_Read(Scanner_GetScanResult('AgentBase', $g_ap_ScanResults, 'Ptr'))
    $g_i_MaxAgents = $g_p_AgentBase + 0x8
    $g_i_MyID = Memory_Read(Scanner_GetScanResult('MyID', $g_ap_ScanResults, 'Ptr'))
    $g_i_CurrentTarget = Memory_Read(Scanner_GetScanResult('CurrentTarget', $g_ap_ScanResults, 'Ptr'))
	Memory_SetValue('AgentBase', Ptr($g_p_AgentBase))
	Memory_SetValue('MaxAgents', Ptr($g_i_MaxAgents))
	Memory_SetValue('MyID', Ptr($g_i_MyID))
	Memory_SetValue('CurrentTarget', Ptr($g_i_CurrentTarget))
    Memory_SetValue('ChangeTarget', Ptr(Scanner_GetScanResult('ChangeTarget', $g_ap_ScanResults, 'Func') + 1))
	;Agent log
	Log_Debug("AgentBase: " & Memory_GetValue('AgentBase'), "Initialize", $g_h_EditText)
	Log_Debug("MaxAgents: " & Memory_GetValue('MaxAgents'), "Initialize", $g_h_EditText)
	Log_Debug("MyID: " & Memory_GetValue('MyID'), "Initialize", $g_h_EditText)
	Log_Debug("ChangeTarget: " & Memory_GetValue('ChangeTarget'), "Initialize", $g_h_EditText)

	;Map
	$g_p_InstanceInfo = Memory_Read(Scanner_GetScanResult('InstanceInfo', $g_ap_ScanResults, 'Ptr'))
	$g_p_WorldConst = Memory_Read(Scanner_GetScanResult('WorldConst', $g_ap_ScanResults, 'Ptr'))
	$g_f_ClickCoordsX = Memory_Read(Scanner_GetScanResult('ClickCoords', $g_ap_ScanResults, 'Ptr'))
	$g_f_ClickCoordsY = Memory_Read(Scanner_GetScanResult('ClickCoords', $g_ap_ScanResults, 'Ptr') + 9)
	$g_p_Region = Memory_Read(Scanner_GetScanResult('Region', $g_ap_ScanResults, 'Ptr'))
	$g_p_AreaInfo = Memory_Read(Scanner_GetScanResult('AreaInfo', $g_ap_ScanResults, 'Ptr'))
	Memory_SetValue('InstanceInfo', Ptr($g_p_InstanceInfo))
	Memory_SetValue('WorldConst', Ptr($g_p_WorldConst))
	Memory_SetValue('ClickCoords', Ptr($g_f_ClickCoordsX))
	Memory_SetValue('ClickCoords', Ptr($g_f_ClickCoordsY))
	Memory_SetValue('Region', Ptr($g_p_Region))
    Memory_SetValue('Move', Ptr(Scanner_GetScanResult('Move', $g_ap_ScanResults, 'Func')))
	Memory_SetValue('AreaInfo', Ptr($g_p_AreaInfo))
	;Map log
	Log_Debug("InstanceInfo: " & Memory_GetValue('InstanceInfo'), "Initialize", $g_h_EditText)
	Log_Debug("WorldConst: " & Memory_GetValue('WorldConst'), "Initialize", $g_h_EditText)
	Log_Debug("ClickCoords: " & Memory_GetValue('ClickCoords'), "Initialize", $g_h_EditText)
	Log_Debug("Region: " & Memory_GetValue('Region'), "Initialize", $g_h_EditText)
	Log_Debug("Move: " & Memory_GetValue('Move'), "Initialize", $g_h_EditText)
	Log_Debug("AreaInfo: " & Memory_GetValue('AreaInfo'), "Initialize", $g_h_EditText)

	;Trade
	Memory_SetValue('TradeCancel', Ptr(Scanner_GetScanResult('TradeCancel', $g_ap_ScanResults, 'Func')))
	$l_p_Temp = Scanner_GetScanResult('TradeCancel', $g_ap_ScanResults, 'Func')
	Memory_SetValue('TradeAccept', Ptr($l_p_Temp + 0x60))
	Memory_SetValue('TradeOfferItem', Ptr($l_p_Temp + 0x90))
	Memory_SetValue('TradeSubmitOffer', Ptr($l_p_Temp + 0x190))
	;Trade log
	Log_Debug("TradeCancel: " & Memory_GetValue('TradeCancel'), "Initialize", $g_h_EditText)
	Log_Debug("TradeAccept: " & Memory_GetValue('TradeAccept'), "Initialize", $g_h_EditText)
	Log_Debug("TradeOfferItem: " & Memory_GetValue('TradeOfferItem'), "Initialize", $g_h_EditText)
	Log_Debug("TradeSubmitOffer: " & Memory_GetValue('TradeSubmitOffer'), "Initialize", $g_h_EditText)

	;Ui
	Memory_SetValue('UIMessage', Ptr(Scanner_GetScanResult('UIMessage', $g_ap_ScanResults, 'Func')))
	$l_p_Temp = Scanner_GetScanResult('Dialog', $g_ap_ScanResults, 'Func')
	Memory_SetValue('Dialog', Ptr(Scanner_GetCallTargetAddress($l_p_Temp)))
	$l_p_Temp = Scanner_GetScanResult('Interact', $g_ap_ScanResults, 'Func')
	Memory_SetValue('Interact', Ptr(Scanner_GetCallTargetAddress($l_p_Temp)))
	$l_p_Temp = Scanner_GetScanResult('PartySearchButtonCallback', $g_ap_ScanResults, 'Func')
	Memory_SetValue('AddNPC', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0xB0)))
	Memory_SetValue('AddHero', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x100)))
	Memory_SetValue('KickNPC', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x229)))
	Memory_SetValue('KickHero', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x23A)))
	$l_p_Temp = Scanner_GetScanResult('PartyWindowButtonCallback', $g_ap_ScanResults, 'Func')
	Memory_SetValue('LeaveGroup', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x58)))
	$l_p_Temp = Scanner_GetScanResult('SetDifficulty', $g_ap_ScanResults, 'Func')
	Memory_SetValue('SetDifficulty', Ptr(Scanner_GetCallTargetAddress($l_p_Temp)))
	$l_p_Temp = Scanner_GetScanResult('EnterMission', $g_ap_ScanResults, 'Func')
	Memory_SetValue('EnterMission', Ptr(Scanner_GetCallTargetAddress($l_p_Temp)))
	$l_p_Temp = Scanner_GetScanResult('CompassFlag', $g_ap_ScanResults, 'Func')
	Memory_SetValue('FlagHero', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x4B)))
	Memory_SetValue('FlagAll', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x83)))
	$l_p_Temp = Scanner_GetScanResult('AiMode', $g_ap_ScanResults, 'Ptr')
	Memory_SetValue('SetHeroBehavior', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x83)))
	$l_p_Temp = Scanner_GetScanResult('HeroCommand', $g_ap_ScanResults, 'Ptr')
	Memory_SetValue('DropHeroBundle', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0xF6)))
	Memory_SetValue('LockHeroTarget', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x13E)))
	$l_p_Temp = Scanner_GetScanResult('HeroSkills', $g_ap_ScanResults, 'Ptr')
	Memory_SetValue('ToggleHeroSkillState', Ptr(Scanner_GetCallTargetAddress($l_p_Temp - 0xB1)))
	Memory_SetValue('CancelHeroSkill', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x1B)))
	$l_p_Temp = Scanner_GetScanResult('PlayerAdd', $g_ap_ScanResults, 'Ptr')
	Memory_SetValue('AddPlayer', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x13)))
	$l_p_Temp = Scanner_GetScanResult('PlayerKick', $g_ap_ScanResults, 'Ptr')
	Memory_SetValue('KickPlayer', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x63)))
	Memory_SetValue('KickInvitedPlayer', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x90)))
	$l_p_Temp = Scanner_GetScanResult('PartyInvitations', $g_ap_ScanResults, 'Ptr')
	Memory_SetValue('RejectInvitation', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x34)))
	Memory_SetValue('AcceptInvitation', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0x4D)))
	$l_p_Temp = Scanner_GetScanResult('ActiveQuest', $g_ap_ScanResults, 'Ptr')
	Memory_SetValue('ActiveQuest', Ptr(Scanner_GetCallTargetAddress($l_p_Temp + 0xF)))

	;Ui log
	Log_Debug("UIMessage: " & Memory_GetValue('UIMessage'), "Initialize", $g_h_EditText)
	Log_Debug("Dialog: " & Memory_GetValue('Dialog'), "Initialize", $g_h_EditText)
	Log_Debug("Interact: " & Memory_GetValue('Interact'), "Initialize", $g_h_EditText)
	Log_Debug("AddNPC: " & Memory_GetValue('AddNPC'), "Initialize", $g_h_EditText)
	Log_Debug("AddHero: " & Memory_GetValue('AddHero'), "Initialize", $g_h_EditText)
	Log_Debug("KickNPC: " & Memory_GetValue('KickNPC'), "Initialize", $g_h_EditText)
	Log_Debug("KickHero: " & Memory_GetValue('KickHero'), "Initialize", $g_h_EditText)
	Log_Debug("LeaveGroup: " & Memory_GetValue('LeaveGroup'), "Initialize", $g_h_EditText)
	Log_Debug("SetDifficulty: " & Memory_GetValue('SetDifficulty'), "Initialize", $g_h_EditText)
	Log_Debug("EnterMission: " & Memory_GetValue('EnterMission'), "Initialize", $g_h_EditText)
	Log_Debug("FlagHero: " & Memory_GetValue('FlagHero'), "Initialize", $g_h_EditText)
	Log_Debug("FlagAll: " & Memory_GetValue('FlagAll'), "Initialize", $g_h_EditText)
	Log_Debug("SetHeroBehavior: " & Memory_GetValue('SetHeroBehavior'), "Initialize", $g_h_EditText)
	Log_Debug("DropHeroBundle: " & Memory_GetValue('DropHeroBundle'), "Initialize", $g_h_EditText)
	Log_Debug("LockHeroTarget: " & Memory_GetValue('LockHeroTarget'), "Initialize", $g_h_EditText)
	Log_Debug("ToggleHeroSkillState: " & Memory_GetValue('ToggleHeroSkillState'), "Initialize", $g_h_EditText)
	Log_Debug("CancelHeroSkill: " & Memory_GetValue('CancelHeroSkill'), "Initialize", $g_h_EditText)
	Log_Debug("DropHeroBundle: " & Memory_GetValue('DropHeroBundle'), "Initialize", $g_h_EditText)
	Log_Debug("AddPlayer: " & Memory_GetValue('AddPlayer'), "Initialize", $g_h_EditText)
	Log_Debug("KickPlayer: " & Memory_GetValue('KickPlayer'), "Initialize", $g_h_EditText)
	Log_Debug("KickInvitedPlayer: " & Memory_GetValue('KickInvitedPlayer'), "Initialize", $g_h_EditText)
	Log_Debug("RejectInvitation: " & Memory_GetValue('RejectInvitation'), "Initialize", $g_h_EditText)
	Log_Debug("AcceptInvitation: " & Memory_GetValue('AcceptInvitation'), "Initialize", $g_h_EditText)
	Log_Debug("ActiveQuest: " & Memory_GetValue('ActiveQuest'), "Initialize", $g_h_EditText)

	;EncString Decoding
	$l_p_Temp = Scanner_GetScanResult('ValidateAsyncDecodeStr', $g_ap_ScanResults, 'Func')
	$l_p_Temp = Scanner_ToFunctionStart($l_p_Temp)
	Memory_SetValue('ValidateAsyncDecodeStr', Ptr($l_p_Temp))
	;EncString log
	Log_Debug("ValidateAsyncDecodeStr: " & Memory_GetValue('ValidateAsyncDecodeStr'), "Initialize", $g_h_EditText)

    ;Hook
    $l_p_Temp = Scanner_GetScanResult('Engine', $g_ap_ScanResults, 'Hook')
    Memory_SetValue('MainStart', Ptr($l_p_Temp))
    Memory_SetValue('MainReturn', Ptr($l_p_Temp + 0x5))
    $l_p_Temp = Scanner_GetScanResult('Render', $g_ap_ScanResults, 'Hook')
    Memory_SetValue('RenderingMod', Ptr($l_p_Temp))
    Memory_SetValue('RenderingModReturn', Ptr($l_p_Temp + 0xA))
	$l_p_Temp = Scanner_GetScanResult('LoadFinished', $g_ap_ScanResults, 'Hook')
    Memory_SetValue('LoadFinishedStart', Ptr($l_p_Temp))
    Memory_SetValue('LoadFinishedReturn', Ptr($l_p_Temp + 0x5))
    $l_p_Temp = Scanner_GetScanResult('Trader', $g_ap_ScanResults, 'Hook')
    Memory_SetValue('TraderStart', Ptr($l_p_Temp))
    Memory_SetValue('TraderReturn', Ptr($l_p_Temp + 0x5))
	$l_p_Temp = Scanner_GetScanResult('TradePartner', $g_ap_ScanResults, 'Hook')
    Memory_SetValue('TradePartnerStart', Ptr($l_p_Temp))
    Memory_SetValue('TradePartnerReturn', Ptr($l_p_Temp + 0x5))
	;Hook log
	Log_Debug("MainStart: " & Memory_GetValue('MainStart'), "Initialize", $g_h_EditText)
	Log_Debug("MainReturn: " & Memory_GetValue('MainReturn'), "Initialize", $g_h_EditText)
	Log_Debug("RenderingMod: " & Memory_GetValue('RenderingMod'), "Initialize", $g_h_EditText)
	Log_Debug("RenderingModReturn: " & Memory_GetValue('RenderingModReturn'), "Initialize", $g_h_EditText)
	Log_Debug("LoadFinishedStart: " & Memory_GetValue('LoadFinishedStart'), "Initialize", $g_h_EditText)
	Log_Debug("LoadFinishedReturn: " & Memory_GetValue('LoadFinishedReturn'), "Initialize", $g_h_EditText)
	Log_Debug("TraderStart: " & Memory_GetValue('TraderStart'), "Initialize", $g_h_EditText)
	Log_Debug("TraderReturn: " & Memory_GetValue('TraderReturn'), "Initialize", $g_h_EditText)
	Log_Debug("TradePartnerStart: " & Memory_GetValue('TradePartnerStart'), "Initialize", $g_h_EditText)
	Log_Debug("TradePartnerReturn: " & Memory_GetValue('TradePartnerReturn'), "Initialize", $g_h_EditText)
	If IsDeclared("g_b_Scanner") Then Extend_Scanner()

	Memory_SetValue('QueueSize', '0x00000100')

    ; Modify memory
    Assembler_ModifyMemory()

	$g_i_AgentCopyCount = Memory_GetValue('AgentCopyCount')
    $g_p_AgentCopyBase = Memory_GetValue('AgentCopyBase')
    $g_i_TraderQuoteID = Memory_GetValue('TraderQuoteID')
    $g_i_TraderCostID = Memory_GetValue('TraderCostID')
    $g_f_TraderCostValue = Memory_GetValue('TraderCostValue')
    $g_i_InvCanIdentifyAllResult = Memory_GetValue('InvCanIdentifyAllResult')
    $g_i_InvIdentifyAllResult = Memory_GetValue('InvIdentifyAllResult')
    $g_i_InvCanDepositAllMaterialsResult = Memory_GetValue('InvCanDepositAllMaterialsResult')
    $g_i_InvDepositAllMaterialsResult = Memory_GetValue('InvDepositAllMaterialsResult')
	$g_p_SavedIndex = Memory_GetValue('SavedIndex')
	$g_i_QueueCounter = Memory_Read(Memory_GetValue('QueueCounter'))
    $g_i_QueueSize = Memory_GetValue('QueueSize') - 1
    $g_p_QueueBase = Memory_GetValue('QueueBase')
    $g_b_DisableRendering = Memory_GetValue('DisableRendering')
	$g_p_MapIsLoaded = Memory_GetValue('MapIsLoaded')
	$g_p_TradePartner = Memory_GetValue('TradePartner')

	If IsDeclared("g_b_InitializeResult") Then Extend_InitializeResult()

    ; Setup command structures
    DllStructSetData($g_d_InviteGuild, 1, Memory_GetValue('CommandPacketSend'))
    DllStructSetData($g_d_Packet, 1, Memory_GetValue('CommandPacketSend'))
    DllStructSetData($g_d_Action, 1, Memory_GetValue('CommandAction'))
    DllStructSetData($g_d_SendChat, 1, Memory_GetValue('CommandSendChat'))
    DllStructSetData($g_d_SendChat, 2, $GC_I_HEADER_SEND_CHAT)
	;Skill
	DllStructSetData($g_d_UseSkill, 1, Memory_GetValue('CommandUseSkill'))
    DllStructSetData($g_d_UseHeroSkill, 1, Memory_GetValue('CommandUseHeroSkill'))
	DllStructSetData($g_d_CancelHeroSkill, 1, Memory_GetValue('CommandCancelHeroSkill'))
	;Friend
	DllStructSetData($g_d_ChangeStatus, 1, Memory_GetValue('CommandPlayerStatus'))
    DllStructSetData($g_d_AddFriend, 1, Memory_GetValue('CommandAddFriend'))
    DllStructSetData($g_d_RemoveFriend, 1, Memory_GetValue('CommandRemoveFriend'))
	;Attribute
	DllStructSetData($g_d_IncreaseAttribute, 1, Memory_GetValue('CommandIncreaseAttribute'))
    DllStructSetData($g_d_DecreaseAttribute, 1, Memory_GetValue('CommandDecreaseAttribute'))
	;Trader
	DllStructSetData($g_d_SellItem, 1, Memory_GetValue('CommandSellItem'))
    DllStructSetData($g_d_BuyItem, 1, Memory_GetValue('CommandBuyItem'))
    DllStructSetData($g_d_RequestQuote, 1, Memory_GetValue('CommandRequestQuote'))
    DllStructSetData($g_d_RequestQuoteSell, 1, Memory_GetValue('CommandRequestQuoteSell'))
    DllStructSetData($g_d_TraderBuy, 1, Memory_GetValue('CommandTraderBuy'))
    DllStructSetData($g_d_TraderSell, 1, Memory_GetValue('CommandTraderSell'))
    DllStructSetData($g_d_Salvage, 1, Memory_GetValue('CommandSalvage'))
    DllStructSetData($g_d_InvCanIdentifyAll, 1, Memory_GetValue('CommandInvCanIdentifyAll'))
    DllStructSetData($g_d_InvIdentifyAll, 1, Memory_GetValue('CommandInvIdentifyAll'))
    DllStructSetData($g_d_InvCanDepositAllMaterials, 1, Memory_GetValue('CommandInvCanDepositAllMaterials'))
    DllStructSetData($g_d_InvDepositAllMaterials, 1, Memory_GetValue('CommandInvDepositAllMaterials'))
    DllStructSetData($g_d_DropBundle, 1, Memory_GetValue('CommandDropBundle'))
	$g_p_CraftItem = Memory_GetValue('CommandCraftItem')
	$g_p_CollectorExchange = Memory_GetValue('CommandCollectorExchange')
	;Agent
	DllStructSetData($g_d_ChangeTarget, 1, Memory_GetValue('CommandChangeTarget'))
    DllStructSetData($g_d_MakeAgentArray, 1, Memory_GetValue('CommandMakeAgentArray'))
	;Map
	DllStructSetData($g_d_Move, 1, Memory_GetValue('CommandMove'))
	;Trade
	DllStructSetData($g_d_TradeInitiate, 1, Memory_GetValue('CommandTradeInitiate'))
	DllStructSetData($g_d_TradeCancel, 1, Memory_GetValue('CommandTradeCancel'))
	DllStructSetData($g_d_TradeAccept, 1, Memory_GetValue('CommandTradeAccept'))
	DllStructSetData($g_d_TradeSubmitOffer, 1, Memory_GetValue('CommandTradeSubmitOffer'))
	DllStructSetData($g_d_TradeOfferItem, 1, Memory_GetValue('CommandTradeOfferItem'))
	;Ui
	DllStructSetData($g_d_Dialog, 1, Memory_GetValue('CommandDialog'))
	DllStructSetData($g_d_Interact, 1, Memory_GetValue('CommandInteract'))
	DllStructSetData($g_d_AddNPC, 1, Memory_GetValue('CommandAddNPC'))
	DllStructSetData($g_d_AddHero, 1, Memory_GetValue('CommandAddHero'))
	DllStructSetData($g_d_KickNPC, 1, Memory_GetValue('CommandKickNPC'))
	DllStructSetData($g_d_KickHero, 1, Memory_GetValue('CommandKickHero'))
	DllStructSetData($g_d_LeaveGroup, 1, Memory_GetValue('CommandLeaveGroup'))
	DllStructSetData($g_d_SetDifficulty, 1, Memory_GetValue('CommandSetDifficulty'))
	DllStructSetData($g_d_EnterMission, 1, Memory_GetValue('CommandEnterMission'))
	DllStructSetData($g_d_FlagHero, 1, Memory_GetValue('CommandFlagHero'))
	DllStructSetData($g_d_FlagAll, 1, Memory_GetValue('CommandFlagAll'))
	DllStructSetData($g_d_SetHeroBehavior, 1, Memory_GetValue('CommandSetHeroBehavior'))
	DllStructSetData($g_d_DropHeroBundle, 1, Memory_GetValue('CommandDropHeroBundle'))
	DllStructSetData($g_d_LockHeroTarget, 1, Memory_GetValue('CommandLockHeroTarget'))
	DllStructSetData($g_d_ToggleHeroSkillState, 1, Memory_GetValue('CommandToggleHeroSkillState'))
	DllStructSetData($g_d_ActiveQuest, 1, Memory_GetValue('CommandActiveQuest'))
	;UIMsg
	DllStructSetData($g_d_MoveMap, 1, Memory_GetValue('CommandUIMsg'))
	DllStructSetData($g_d_EquipItem, 1, Memory_GetValue('CommandUIMsg'))
	DllStructSetData($g_d_Xunlai, 1, Memory_GetValue('CommandUIMsg'))
	DllStructSetData($g_d_ApplyUpgrade, 1, Memory_GetValue('CommandUIMsg'))
	;Party
	DllStructSetData($g_d_AddPlayer, 1, Memory_GetValue('CommandAddPlayer'))
	DllStructSetData($g_d_KickPlayer, 1, Memory_GetValue('CommandKickPlayer'))
	DllStructSetData($g_d_KickInvitedPlayer, 1, Memory_GetValue('CommandKickInvitedPlayer'))
	DllStructSetData($g_d_RejectInvitation, 1, Memory_GetValue('CommandRejectInvitation'))
	DllStructSetData($g_d_AcceptInvitation, 1, Memory_GetValue('CommandAcceptInvitation'))
	;Prop ray casting
	DllStructSetData($g_d_PropRay, 1, Memory_GetValue('CommandPropRay'))
	$g_p_PropRayResult = Memory_GetValue('PropRayResult')
	$g_p_PropRayReady = Memory_GetValue('PropRayReady')
	;Trade session natives
	DllStructSetData($g_d_TradeSession, 1, Memory_GetValue('CommandTradeSession'))
	$g_p_TradeSessResult = Memory_GetValue('TradeSessResult')
	$g_p_TradeSessReady = Memory_GetValue('TradeSessReady')
	;EncString
	DllStructSetData($g_d_DecodeEncString, 1, Memory_GetValue('CommandDecodeEncString'))
	$g_p_DecodeInputPtr = Memory_GetValue('DecodeInputPtr')
	$g_p_DecodeOutputPtr = Memory_GetValue('DecodeOutputPtr')
	$g_p_DecodeReady = Memory_GetValue('DecodeReady')

    If $a_b_ChangeTitle Then WinSetTitle($g_h_GWWindow, '', 'Guild Wars - ' & Player_GetCharname())

    Log_Info("End of Initialization", "GwAu3", $g_h_EditText)
    Return $g_h_GWWindow
EndFunc
#EndRegion Initialization

Func Core_Enqueue_($a_p_Ptr, $a_i_Size)
    Local $l_i_Slot = $g_p_QueueBase + (256 * $g_i_QueueCounter)

    DllCall("kernel32.dll", "bool", "WriteProcessMemory", "handle", $g_h_GWProcess, "ptr", $l_i_Slot + 4, "ptr", $a_p_Ptr + 4, "ulong_ptr", $a_i_Size - 4,"ptr", 0)
    DllCall("kernel32.dll", "bool", "WriteProcessMemory", "handle", $g_h_GWProcess, "ptr", $l_i_Slot, "ptr", $a_p_Ptr, "ulong_ptr", 4, "ptr", 0)

    If $g_i_QueueCounter = $g_i_QueueSize Then
        $g_i_QueueCounter = 0
    Else
        $g_i_QueueCounter += 1
    EndIf
EndFunc

Func Core_Enqueue($a_p_Ptr, $a_i_Size)
	DllCall($g_h_Kernel32, 'int', 'WriteProcessMemory', 'int', $g_h_GWProcess, 'int', 256 * $g_i_QueueCounter + $g_p_QueueBase, 'ptr', $a_p_Ptr, 'int', $a_i_Size, 'int', '')
	If $g_i_QueueCounter = $g_i_QueueSize Then
		$g_i_QueueCounter = 0
	Else
		$g_i_QueueCounter = $g_i_QueueCounter + 1
	EndIf
EndFunc

Func Core_PerformAction($a_i_Action, $a_i_Flag, $a_i_Type = 0)
	DllStructSetData($g_d_Action, 2, $a_i_Action)
	DllStructSetData($g_d_Action, 3, $a_i_Flag)
	DllStructSetData($g_d_Action, 4, $a_i_Type)
	Core_Enqueue($g_p_Action, 16)
EndFunc

Func Core_SendPacket($a_i_Size, $a_i_Header, $a_i_Param1 = 0, $a_i_Param2 = 0, $a_i_Param3 = 0, $a_i_Param4 = 0, $a_i_Param5 = 0, $a_i_Param6 = 0, $a_i_Param7 = 0, $a_i_Param8 = 0, $a_i_Param9 = 0, $a_i_Param10 = 0)
	DllStructSetData($g_d_Packet, 2, $a_i_Size)
	DllStructSetData($g_d_Packet, 3, $a_i_Header)
	DllStructSetData($g_d_Packet, 4, $a_i_Param1)
	DllStructSetData($g_d_Packet, 5, $a_i_Param2)
	DllStructSetData($g_d_Packet, 6, $a_i_Param3)
	DllStructSetData($g_d_Packet, 7, $a_i_Param4)
	DllStructSetData($g_d_Packet, 8, $a_i_Param5)
	DllStructSetData($g_d_Packet, 9, $a_i_Param6)
	DllStructSetData($g_d_Packet, 10, $a_i_Param7)
	DllStructSetData($g_d_Packet, 11, $a_i_Param8)
	DllStructSetData($g_d_Packet, 12, $a_i_Param9)
	DllStructSetData($g_d_Packet, 13, $a_i_Param10)
	Core_Enqueue($g_p_Packet, 52)
EndFunc

Func Core_ControlAction($a_i_Action, $a_i_ActionType = $GC_I_CONTROL_TYPE_ACTIVATE)
	Return Core_PerformAction($a_i_Action, $a_i_ActionType)
EndFunc

Func Core_AutoStart()
	If $g_bAutoStart And $g_s_MainCharName <> "" Then
		Sleep(2000)
		StartBot()
		Local $l_h_GWWindow = Core_GetGuildWarsWindow()
		If $l_h_GWWindow = 0 Then
			_Exit()
		EndIf

		If PreGame_Ptr() <> 0 Then

			Local $l_i_currentIndex = PreGame_ChosenCharacter()
			Local $l_s_currentName = StringStripWS(PreGame_CharName($l_i_currentIndex), 3)

			If StringCompare($l_s_currentName, $g_s_MainCharName, 0) <> 0 Then
				Local $l_b_found = False
				Local $l_i_maxAttempts = 20
				Local $l_i_attempts = 0
				Local $l_i_initialIndex = $l_i_currentIndex

				While $l_i_attempts < $l_i_maxAttempts And Not $l_b_found
					ControlSend($l_h_GWWindow, "", "", "{RIGHT}")
					Sleep(250)

					$l_i_currentIndex = PreGame_ChosenCharacter()
					$l_s_currentName = StringStripWS(PreGame_CharName($l_i_currentIndex), 3)

					If StringCompare($l_s_currentName, $g_s_MainCharName, 0) = 0 Then
						$l_b_found = True
					EndIf

					$l_i_attempts += 1

					If $l_i_attempts > 1 And $l_i_currentIndex = $l_i_initialIndex Then
						ExitLoop
					EndIf
				WEnd

				If Not $l_b_found Then
					MsgBox(16, "Error", "Character '" & $g_s_MainCharName & "' not found on this account!")
					_Exit()
				EndIf
			EndIf

			ControlSend($l_h_GWWindow, "", "", "{ENTER}")

			While PreGame_Ptr() <> 0
				Sleep(500)
			WEnd
			Map_WaitMapLoading()
			Sleep(1000)
		EndIf
	EndIf
EndFunc

Func Core_GetGuildWarsWindow()
    Local $l_s_expectedTitle = "Guild Wars - " & $g_s_MainCharName

    Local $l_h_Wnd = WinGetHandle($l_s_expectedTitle)
    If $l_h_Wnd <> 0 Then Return $l_h_Wnd
EndFunc

Func Core_GetLoginStatus()
	Return Memory_Read($g_p_Login, "long")
EndFunc

Func Core_GetInGameStatus()
	Return Memory_Read($g_p_InGame, "long")
EndFunc

Func Core_GetStatusCode()
	Return Memory_Read($g_p_StatusCode, "long")
EndFunc

Func Core_IsLoginScreen()
	Local $l_i_Result = (Core_GetLoginStatus() = 1 And Core_GetInGameStatus() = 0)
	Return $l_i_Result
EndFunc

Func Core_IsCharacterSelection()
	Local $l_i_Result = (Core_GetLoginStatus() = 1 And Core_GetInGameStatus() = 1)
	Return $l_i_Result
EndFunc

Func Core_IsIngame()
	Local $l_i_Result = (Core_GetLoginStatus() = 0 And Core_GetInGameStatus() = 1)
	Return $l_i_Result
EndFunc

Func Core_GetStatusError()
	$l_i_StatusCode = Core_GetStatusCode()
	Return $l_i_StatusCode <> 0 And $l_i_StatusCode <> 1
EndFunc

Func Core_ResetRuntime()
	Global $g_amx_AssertionCache[0][3]
	Global $g_ai2_Sections[5][2]
	Global $g_amx2_Labels[1][2]

	$g_i_LastSkillUsed = 0
	$g_i_LastSkillTarget = 0
	$g_i_LastStatus = 0
	$g_i_LastAttributeModified = -1
	$g_i_LastAttributeValue = -1
	$g_i_LastTransactionType = -1
	$g_i_LastItemID = 0
	$g_i_LastQuantity = 0
	$g_i_LastPrice = 0
	$g_i_LastTargetID = 0
	$g_f_LastMoveX = 0
	$g_f_LastMoveY = 0
EndFunc