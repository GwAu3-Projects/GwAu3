#include-once

Global $g_s_AssertLogCallback = ""
Global $g_p_AssertLogPayload

; Three dwords, never "ptr": the payload is written by a 32-bit client, while "ptr" would be
; 8 bytes under an x64 AutoIt and shift every field.
Global $g_d_AssertLogPayload = DllStructCreate("dword;dword;dword")
Global $g_p_AssertLogStruct = DllStructGetPtr($g_d_AssertLogPayload)

; ErrorAssertion prologue: push ebp / mov ebp,esp / sub esp,20. That is six bytes, one more
; than the detour, so the proc returns to start + 0x6.
Global Const $GC_S_ASSERTLOG_PROLOGUE = "558BEC83EC20"
Global Const $GC_I_ASSERTLOG_STOLEN = 0x6

Global $g_d_AssertLogProbe = DllStructCreate("ptr")
Global $g_p_AssertLogProbe = DllStructGetPtr($g_d_AssertLogProbe)

;~ Description: Register the hook site and the self-test probe.
Func AssertLog_AddPattern()
	Scanner_AddPattern("AssertLog", "558BEC83EC20A10000000033C58945FC8955EC894DE0", 0x1, "Hook")
	Scanner_AddPattern("AssertLogProbe", "558BEC57E800000000837D08088B782C7C14", 0x1, "Func")
EndFunc   ;==>AssertLog_AddPattern

;~ Description: Resolve the hook site, its return address and the probe.
Func AssertLog_Scanner()
	Local Const $l_p_Start = Scanner_GetScanResult("AssertLog", $g_ap_ScanResults, "Hook")

	Memory_SetValue("AssertLogStart", Ptr($l_p_Start))
	Memory_SetValue("AssertLogReturn", Ptr($l_p_Start + $GC_I_ASSERTLOG_STOLEN))
	Memory_SetValue("AssertLogEvent", "0x00000502")
	Memory_SetValue("AssertLogProbe", _
		Ptr(Scanner_GetScanResult("AssertLogProbe", $g_ap_ScanResults, "Func")))

	Log_Debug("AssertLogStart: " & Memory_GetValue("AssertLogStart"), "Initialize", $g_h_EditText)
	Log_Debug("AssertLogReturn: " & Memory_GetValue("AssertLogReturn"), "Initialize", $g_h_EditText)
EndFunc   ;==>AssertLog_Scanner

;~ Description: Create the receiving window and publish the command address.
Func AssertLog_InitializeResult()
	Local Const $l_h_GUI = GUICreate("GwAu3AssertLog")
	GUIRegisterMsg(0x00000502, "AssertLog_EventCallback")
	DllCall("user32.dll", "bool", "ChangeWindowMessageFilterEx", "hwnd", $l_h_GUI, "uint", 0x00000502, "dword", 1, "ptr", 0)
	Memory_Write(Memory_GetValue("AssertLogHandle"), $l_h_GUI)

	$g_p_AssertLogPayload = Memory_GetValue("AssertLogPayload")
	DllStructSetData($g_d_AssertLogProbe, 1, Memory_GetValue("CommandAssertLogProbe"))

	Log_Debug("AssertLogHandle: " & Memory_GetValue("AssertLogHandle"), "Initialize", $g_h_EditText)
EndFunc   ;==>AssertLog_InitializeResult

;~ Description: Reserve the window handle slot and the three-dword payload.
Func Assembler_CreateAssertLogData()
	_("AssertLogHandle/4")
	_("AssertLogPayload/12")
EndFunc   ;==>Assembler_CreateAssertLogData

;~ Description: Detour proc placed at the ErrorAssertion entry point.
; Convention read from the call sites: ecx = expression, edx = source file, line pushed last.
; After pushfd + pushad the line sits at [esp+28h].
Func Assembler_CreateAssertLog()
	_("AssertLogProc:")
	_("pushfd")
	_("pushad")

	_("mov eax,dword[esp+28]")
	_("mov ebx,eax")
	_("mov eax,AssertLogPayload")
	_("mov dword[eax],ecx")
	_("mov dword[eax+4],edx")
	_("mov dword[eax+8],ebx")

	_("push 1")
	_("push eax")
	_("push AssertLogEvent")
	_("push dword[AssertLogHandle]")
	_("call dword[PostMessage]")

	_("popad")
	_("popfd")

	; Stolen prologue, replayed before handing control back.
	_("push ebp")
	_("mov ebp,esp")
	_("sub esp,20 -> 83 EC 20")
	_("ljmp AssertLogReturn")
EndFunc   ;==>Assembler_CreateAssertLog

;~ Description: Queue command calling the probe with an out-of-range argument.
; It goes through the queue because the probe reads the char client context, so it has to run
; on the game thread like any other native GwAu3 calls.
Func Assembler_CreateAssertLogProbe()
	_("CommandAssertLogProbe:")
	_("push 8")
	_("call AssertLogProbe")
	_("add esp,4")
	_("ljmp CommandReturn")
EndFunc   ;==>Assembler_CreateAssertLogProbe

;~ Description: Arm or disarm assertion reporting to the named function.
; The detour is only written after reading the prologue back: in game there is no symbol to
; compare against, so the bytes are the only proof that the resolved address is the right one.
Func AssertLog_SetEventCallback($a_s_Callback = "")
	If $a_s_Callback = "" Then
		$g_s_AssertLogCallback = ""
		Return SetError(0, 0, True)
	EndIf

	Local Const $l_p_Start = Memory_GetValue("AssertLogStart")
	If $l_p_Start = -1 Or $l_p_Start = 0 Then Return SetError(1, 0, False)

	Local Const $l_s_Found = AssertLog_ReadBytes($l_p_Start, 6)
	If $l_s_Found = $GC_S_ASSERTLOG_PROLOGUE Then
		Memory_WriteDetour("AssertLogStart", "AssertLogProc")
	ElseIf Not AssertLog_IsHooked($l_p_Start) Then
		Log_Error("Unexpected prologue at " & Ptr($l_p_Start) & ": read " & $l_s_Found & _
			", expected " & $GC_S_ASSERTLOG_PROLOGUE & " or a detour to AssertLogProc", _
			"AssertLog_SetEventCallback", $g_h_EditText)
		Return SetError(2, 0, False)
	EndIf

	$g_s_AssertLogCallback = $a_s_Callback

	Log_Info("AssertLog armed at " & Ptr($l_p_Start), "AssertLog_SetEventCallback", $g_h_EditText)
	Return SetError(0, 0, True)
EndFunc   ;==>AssertLog_SetEventCallback

;~ Description: Raise a fatal assertion on purpose to prove the hook works. The client dies.
; ErrorAssertion never returns, it tail-calls EdAssertDumpAndExit. Expected output is
; vis < CHAR_STATS_VIS in ChCliApi.cpp, line 4975 up to build 2026-06-18 and 5076 after it.
Func AssertLog_RaiseTestAssertion()
	If $g_s_AssertLogCallback = "" Then Return SetError(1, 0, False)

	Local Const $l_p_Probe = Memory_GetValue("AssertLogProbe")
	If $l_p_Probe = -1 Or $l_p_Probe = 0 Then Return SetError(2, 0, False)

	Log_Info("Test assertion queued through " & Ptr($l_p_Probe), "AssertLog", $g_h_EditText)
	Core_Enqueue($g_p_AssertLogProbe, 4)
	Return SetError(0, 0, True)
EndFunc   ;==>AssertLog_RaiseTestAssertion

;~ Description: Tell whether the site already carries our own detour instead of a clean prologue.
; GwAu3 routinely re-attaches to an already instrumented client, so without this the hook could
; only be armed once per game launch. The test is on the jump TARGET, not on the mere presence
; of an E9: a foreign detour must not pass for ours.
Func AssertLog_IsHooked($a_p_Start)
	If AssertLog_ReadBytes($a_p_Start, 1) <> "E9" Then Return False

	Local Const $l_i_Rel = Memory_Read($a_p_Start + 1, "int")
	Return ($a_p_Start + 5 + $l_i_Rel) = Memory_GetValue("AssertLogProc")
EndFunc   ;==>AssertLog_IsHooked

;~ Description: Receive one assertion, read its strings and forward it to the callback.
Func AssertLog_EventCallback($hWnd, $msg, $wparam, $lparam)
	If $lparam <> 0x1 Then Return 0

	DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $wparam, _
		"ptr", $g_p_AssertLogStruct, _
		"ulong_ptr", 12, _
		"ulong_ptr*", 0)
	If @error Then Return 0

	Local Const $l_s_Expression = AssertLog_ReadString(DllStructGetData($g_d_AssertLogPayload, 1))
	Local Const $l_s_File = AssertLog_ReadString(DllStructGetData($g_d_AssertLogPayload, 2))
	Local Const $l_i_Line = DllStructGetData($g_d_AssertLogPayload, 3)

	Log_Error("Assertion: " & $l_s_Expression & " (" & $l_s_File & ":" & $l_i_Line & ")", _
		"AssertLog", $g_h_EditText)

	If $g_s_AssertLogCallback <> "" Then _
		Call($g_s_AssertLogCallback, $l_s_Expression, $l_s_File, $l_i_Line)

	Return 0
EndFunc   ;==>AssertLog_EventCallback

;~ Description: Read a NUL-terminated ASCII string from the client, empty on failure.
Func AssertLog_ReadString($a_p_Address, $a_i_Max = 256)
	If $a_p_Address = 0 Then Return ""

	Local $l_d_Buffer = DllStructCreate("char[" & $a_i_Max & "]")
	Local Const $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $a_p_Address, _
		"ptr", DllStructGetPtr($l_d_Buffer), _
		"ulong_ptr", $a_i_Max, _
		"ulong_ptr*", 0)
	If @error Or Not IsArray($l_av_Call) Or Not $l_av_Call[0] Then Return ""

	Return DllStructGetData($l_d_Buffer, 1)
EndFunc   ;==>AssertLog_ReadString

;~ Description: Read raw bytes from the client as an uppercase hex string, empty on failure.
Func AssertLog_ReadBytes($a_p_Address, $a_i_Count)
	Local $l_d_Buffer = DllStructCreate("byte[" & $a_i_Count & "]")
	Local Const $l_av_Call = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $a_p_Address, _
		"ptr", DllStructGetPtr($l_d_Buffer), _
		"ulong_ptr", $a_i_Count, _
		"ulong_ptr*", 0)
	If @error Or Not IsArray($l_av_Call) Or Not $l_av_Call[0] Then Return ""

	Local $l_s_Bytes = ""
	For $l_i_Idx = 1 To $a_i_Count
		$l_s_Bytes &= Hex(DllStructGetData($l_d_Buffer, 1, $l_i_Idx), 2)
	Next
	Return $l_s_Bytes
EndFunc   ;==>AssertLog_ReadBytes
