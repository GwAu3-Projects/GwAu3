#include-once

; The core calls a single set of Extend_* functions, and those are global names: without this
; dispatcher only one plugin at a time could ever define them. Each plugin exposes its own
; <Plugin>_<Stage>() instead, and they are called from here.

Global $g_b_AddPattern
Global $g_b_Scanner
Global $g_b_InitializeResult
Global $g_b_Assembler
Global $g_b_AssemblerData

Global $g_p_PostMessageA

;~ Description: Register the patterns of every plugin, plus the shared PostMessageA import.
Func Extend_AddPattern()
	Scanner_AddPattern("PostMessage", "6AFF6A00680180", 0x19, "Ptr")

	ChatLog_AddPattern()
	AssertLog_AddPattern()
	StoC_AddPattern()
	SkillLog_AddPattern()
EndFunc   ;==>Extend_AddPattern

;~ Description: Resolve the shared PostMessageA import, then let every plugin resolve its own.
Func Extend_Scanner()
	$g_p_PostMessageA = Scanner_GetScanResult("PostMessage", $g_ap_ScanResults, "Ptr")
	Memory_SetValue("PostMessage", Ptr(Memory_Read($g_p_PostMessageA, "dword")))
	Log_Debug("PostMessage: " & Memory_GetValue("PostMessage"), "Initialize", $g_h_EditText)

	ChatLog_Scanner()
	AssertLog_Scanner()
	StoC_Scanner()
	SkillLog_Scanner()
EndFunc   ;==>Extend_Scanner

;~ Description: Let every plugin finish its setup once the ASM block is written.
Func Extend_InitializeResult()
	ChatLog_InitializeResult()
	AssertLog_InitializeResult()
	StoC_InitializeResult()
	SkillLog_InitializeResult()
EndFunc   ;==>Extend_InitializeResult

;~ Description: Emit the ASM procedures of every plugin.
Func Extend_Assembler()
	Assembler_CreateChatLog()
	Assembler_CreateAssertLog()
	Assembler_CreateAssertLogProbe()
	Assembler_CreateStoC()
	Assembler_CreateCasterSkillLog()
	Assembler_CreateMeleeSkillLog()
	Assembler_CreateProbeSkillLog()
EndFunc   ;==>Extend_Assembler

;~ Description: Reserve the ASM data slots of every plugin.
Func Extend_AssemblerData()
	Assembler_CreateEventData()
	Assembler_CreateAssertLogData()
	Assembler_CreateStoCData()
	Assembler_CreateSkillLogData()
EndFunc   ;==>Extend_AssemblerData
