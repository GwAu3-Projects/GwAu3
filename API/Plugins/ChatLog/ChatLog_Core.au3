#include-once

Global $g_m_Detours[]

Global $g_s_ChatReceive
Global $g_s_ChatLogBase
Global $g_i_ChatLogCounter
Global $g_i_ChatMessageChannel
Global $g_d_ChatLogStruct = DllStructCreate("dword;wchar[256]")
Global $g_p_ChatLogStruct = DllStructGetPtr($g_d_ChatLogStruct)

Func ChatLog_AddPattern()
	Scanner_AddPattern("ChatLog", "8B4508837D0C07", -0x20, "Hook")
EndFunc

Func ChatLog_Scanner()
	Local $l_p_Temp = Scanner_GetScanResult("ChatLog", $g_ap_ScanResults, "Hook")
	Memory_SetValue("ChatLogStart", Ptr($l_p_Temp))
	Memory_SetValue("ChatLogReturn", Ptr($l_p_Temp + 0x5))

	Log_Debug("ChatLogStart: " & Memory_GetValue("ChatLogStart"), "Initialize", $g_h_EditText)
	Log_Debug("ChatLogReturn: " & Memory_GetValue("ChatLogReturn"), "Initialize", $g_h_EditText)

    Memory_SetValue("ChatLogCallbackEvent", "0x00000501")
	Memory_SetValue("ChatLogSize", "0x00000010")
EndFunc

Func ChatLog_InitializeResult()
	Local $l_h_GUI = GUICreate("GwAu3")
	GUIRegisterMsg(0x00000501, "ChatLog_EventCallback")
	DllCall("user32.dll", "bool", "ChangeWindowMessageFilterEx", "hwnd", $l_h_GUI, "uint", 0x00000501, "dword", 1, "ptr", 0)
	Memory_Write(Memory_GetValue("ChatLogCallbackHandle"), $l_h_GUI)
	Log_Debug("ChatLogCallbackHandle: " & Memory_GetValue("ChatLogCallbackHandle"), "Initialize", $g_h_EditText)

	$g_s_ChatLogBase = Memory_GetValue("ChatLogBase")
	$g_i_ChatLogCounter = Memory_GetValue("ChatMessageCounter")
	$g_i_ChatMessageChannel = Memory_GetValue("ChatMessageChannel")
EndFunc

Func Assembler_CreateEventData()
    _("ChatLogCallbackHandle/4")
	_("ChatLogCallbackEvent/4")

	_("ChatLogLastMsg/4")
	_("ChatLogCounter/4")
	_("ChatMessageCounter/4")
	_("ChatMessageChannel/4")

	_("ChatLogBase/" & 512)
EndFunc

Func Assembler_CreateChatLog()
    _("ChatLogProc:")
    _("pushfd")
    _("pushad")
    _("mov ecx,dword[esp+30]")
    _("add ecx,4")
    _("xor ebx,ebx")
    _("mov eax,ChatLogBase")

    _("ChatLogCopyLoop:")
    _("mov dx,word[ecx]")
    _("mov word[eax],dx")
    _("add ecx,2")
    _("add eax,2")
    _("inc ebx")
    _("cmp ebx,FF")
    _("jz ChatLogCopyExit")
    _("test dx,dx")
    _("jnz ChatLogCopyLoop")

    _("ChatLogCopyExit:")
    _("mov edx,dword[esp+34]")
    _("mov dword[ChatMessageChannel],edx")
    _("push eax")
    _("mov eax,ChatLogBase")
    _("sub eax,4")
    _("mov dword[eax],edx")
    _("pop eax")
    _("mov edx,dword[ChatMessageCounter]")
    _("inc edx")
    _("mov dword[ChatMessageCounter],edx")
    _("push 1")
    _("mov edx,ChatLogBase")
    _("sub edx,4")
    _("push edx")
    _("push ChatLogCallbackEvent")
    _("push dword[ChatLogCallbackHandle]")
    _("call dword[PostMessage]")

    _("popad")
    _("popfd")

    _("mov eax,dword[ebp+8]")
    _("test eax,eax")
    _("ljmp ChatLogReturn")
EndFunc

Func Memory_WriteDetourEx($a_s_FromLabel, $a_s_ToLabel)
    Local $l_p_LabelPtr = Memory_GetValue($a_s_FromLabel)
    Local $l_s_Buffer = DllStructCreate("byte[5]")

    DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
        "handle", $g_h_GWProcess, _
        "ptr", $l_p_LabelPtr, _
        "ptr", DllStructGetPtr($l_s_Buffer), _
        "ulong_ptr", 5, _
        "ulong_ptr*", 0)

    Local $l_s_OriginalOpcode = ""
    For $i = 1 To 5
        $l_s_OriginalOpcode &= Hex(DllStructGetData($l_s_Buffer, 1, $i), 2)
    Next
	$g_m_Detours[$a_s_FromLabel] = $l_s_OriginalOpcode

    Memory_WriteBinary("E9" & Utils_SwapEndian(Hex(Memory_GetValue($a_s_ToLabel) - Memory_GetValue($a_s_FromLabel) - 5)), Memory_GetValue($a_s_FromLabel))
EndFunc

Func Memory_RevertDetour($a_s_FromLabel)
	If Not MapExists($g_m_Detours, $a_s_FromLabel) Then Return 0

    Local $l_s_OriginalOpcode = $g_m_Detours[$a_s_FromLabel]
    Local $l_p_LabelPtr = Memory_GetValue($a_s_FromLabel)

    Memory_WriteBinary($l_s_OriginalOpcode, $l_p_LabelPtr)
	MapRemove($g_m_Detours, $a_s_FromLabel)

    Return True
EndFunc

Func ChatLog_SetEventCallback($a_s_ChatReceive = "")
	If $a_s_ChatReceive <> "" Then
		Memory_WriteDetourEx("ChatLogStart", "ChatLogProc")
	Else
		Memory_RevertDetour("ChatLogStart")
	EndIf

	$g_s_ChatReceive = $a_s_ChatReceive

    Log_Info("ChatLog event callbacks configured", "ChatLog_SetEventCallback", $g_h_EditText)
EndFunc

Func ChatLog_EventCallback($hWnd, $msg, $wparam, $lparam)
    Switch $lparam
		Case 0x1
			DllCall($g_h_Kernel32, "int", "ReadProcessMemory", "int", $g_h_GWProcess, "int", $wparam, "ptr", $g_p_ChatLogStruct, "int", 512, "int", "")
			Local $i_ChannelType = DllStructGetData($g_d_ChatLogStruct, 1)
			Local $l_s_Message = DllStructGetData($g_d_ChatLogStruct, 2)
			Local $l_s_Channel = ""
			Local $l_s_Sender = ""
			Local $l_s_GuildTag = "No"

			Switch $i_ChannelType
				Case 0
					$l_s_Channel = "Alliance"
					ChatLog_ParseAlliance($l_s_Message, $l_s_Sender, $l_s_GuildTag, $l_s_Message)
				Case 3
					$l_s_Channel = "All"
					ChatLog_ParseGeneral($l_s_Message, $l_s_Sender, $l_s_Message)
				Case 9
					$l_s_Channel = "Guild"
					ChatLog_ParseGuild($l_s_Message, $l_s_Sender, $l_s_Message)
				Case 11
					$l_s_Channel = "Team"
					ChatLog_ParseGeneral($l_s_Message, $l_s_Sender, $l_s_Message)
				Case 12
					$l_s_Channel = "Trade"
					ChatLog_ParseGeneral($l_s_Message, $l_s_Sender, $l_s_Message)
				Case 10
					$l_s_Channel = "Send Whisper"
					ChatLog_ParseWhisper($l_s_Message, $l_s_Sender, $l_s_Message)
				Case 13
					$l_s_Channel = "Advisory"
					$l_s_Sender = "Guild Wars"
					$l_s_Message = ""
				Case 14
					$l_s_Channel = "Received Whisper"
					ChatLog_ParseWhisper($l_s_Message, $l_s_Sender, $l_s_Message, 1)
				Case Else
					$l_s_Channel = "Other"
					$l_s_Sender = "Other"
			EndSwitch

			Call($g_s_ChatReceive, $l_s_Channel, $l_s_Sender, $l_s_Message, $l_s_GuildTag)
			Log_Debug("Channel: " & $l_s_Channel & " Sender: " & $l_s_Sender & " Guild: " & $l_s_GuildTag & " Message: " & $l_s_Message, "ChatCallback", $g_h_EditText)
	EndSwitch

    Return 0
EndFunc

Func ChatLog_ParseAlliance($msg, ByRef $sender, ByRef $tag, ByRef $text)
	Local $tagSep = "Ĉ", $textSep = "ċĈć"
	Local $tagSepPos = StringInStr($msg, $tagSep), $textSepPos = StringInStr($msg, $textSep)
	Local $tagStart = $tagSepPos + StringLen($tagSep), $textStart = $textSepPos + StringLen($textSep)

	$sender = StringMid($msg, 3, $tagSepPos - 3)
    $tag = StringMid($msg, $tagStart, $textSepPos - $tagStart)
    $text = StringMid($msg, $textStart, StringInStr($msg, "", 0, 1, $textStart) - $textStart)
EndFunc

Func ChatLog_ParseGuild($msg, ByRef $sender, ByRef $text, $sep = "ċĈć")
    Local $sepPos = StringInStr($msg, $sep)
	Local $textStart = $sepPos + StringLen($sep)

    $sender = StringLeft($msg, $sepPos - 1)
    $text = StringMid($msg, $textStart, StringInStr($msg, "", 0, 1, $textStart) - $textStart)
EndFunc

Func ChatLog_ParseGeneral($msg, ByRef $sender, ByRef $text, $sep = "ċĈć")
    Local $sepPos = StringInStr($msg, $sep)
	If $sepPos = 0 Then
		$sep = "ċ脂໾ć"
		$sepPos = StringInStr($msg, $sep)
	EndIf
	Local $textStart = $sepPos + StringLen($sep)

    $sender = StringMid($msg, 3, $sepPos - 3)
    $text = StringMid($msg, $textStart, StringInStr($msg, "", 0, 1, $textStart) - $textStart)
EndFunc

Func ChatLog_ParseWhisper($msg, ByRef $sender, ByRef $text, $sendrecv = 0)
    Local $sepPos = StringInStr($msg, "Ĉ")
	Local $textStart = $sepPos + 2

	$sender = ($sendrecv = 0 ? StringMid($msg, 3, $sepPos - 3) : StringLeft($msg, $sepPos - 1))
    $text = StringMid($msg, $textStart, StringInStr($msg, "", 0, 1, $textStart) - $textStart)
EndFunc

Func ChatLog_GetChatLogBase()
    Return $g_s_ChatLogBase
EndFunc

Func ChatLog_GetChatMessageCounter()
    Return Memory_Read($g_i_ChatLogCounter)
EndFunc

Func ChatLog_GetChatMessageChannel()
    Return Memory_Read($g_i_ChatMessageChannel)
EndFunc