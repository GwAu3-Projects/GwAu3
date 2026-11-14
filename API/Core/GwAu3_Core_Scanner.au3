#include-once

Func Scanner_GWModuleBase()
    If $g_h_GWProcess = 0 Then
        Log_Error("Invalid process handle", "Memory", $g_h_EditText)
        Return 0
    EndIf

    Local $l_d_Modules = DllStructCreate("ptr[1024]")
    Local $l_d_CbNeeded = DllStructCreate("dword")
    Local $l_h_PSAPI = DllOpen("psapi.dll")
    If $l_h_PSAPI = -1 Then
        Log_Error("Failed to open psapi.dll", "Memory", $g_h_EditText)
        Return 0
    EndIf

    Local $l_av_Success = DllCall($l_h_PSAPI, "bool", "EnumProcessModules", _
        "handle", $g_h_GWProcess, _
        "ptr", DllStructGetPtr($l_d_Modules), _
        "dword", DllStructGetSize($l_d_Modules), _
        "ptr", DllStructGetPtr($l_d_CbNeeded))
    DllClose($l_h_PSAPI)
    If @error Or Not IsArray($l_av_Success) Or Not $l_av_Success[0] Or DllStructGetData($l_d_CbNeeded, 1) = 0 Then
        Log_Error("EnumProcessModules failed", "Memory", $g_h_EditText)
        Return 0
    EndIf

    Local $l_p_ModuleBase = DllStructGetData($l_d_Modules, 1, 1)

    Return $l_p_ModuleBase
EndFunc   ;==>Scanner_GWModuleBase

Func Scanner_InitializeSections($a_p_BaseAddress = 0)
    If $g_b_SectionsInitialized Then Return True

    If $a_p_BaseAddress = 0 Then $a_p_BaseAddress = Scanner_GWModuleBase()
    If $a_p_BaseAddress = 0 Then
        Log_Error("Failed to get GW module base address", "Sections", $g_h_EditText)
        Return False
    EndIf

    Local $l_d_Page = DllStructCreate("byte[4096]")
    Local $l_p_Page = DllStructGetPtr($l_d_Page)
    Local $l_av_Ret = DllCall($g_h_Kernel32, "int", "ReadProcessMemory", _
        "int", $g_h_GWProcess, _
        "int", $a_p_BaseAddress, _
        "ptr", $l_p_Page, _
        "int", 4096, _
        "int", "")
    If @error Or Not IsArray($l_av_Ret) Or $l_av_Ret[0] = 0 Then
        Log_Error("Failed to read PE headers", "Sections", $g_h_EditText)
        Return False
    EndIf

    Local $l_d_Dos = DllStructCreate("word e_magic;byte[58];dword e_lfanew", $l_p_Page)
    If DllStructGetData($l_d_Dos, "e_magic") <> 0x5A4D Then ; 'MZ'
        Log_Error("Invalid DOS signature", "Sections", $g_h_EditText)
        Return False
    EndIf

    Local $l_i_ELfanew = DllStructGetData($l_d_Dos, "e_lfanew")
    If $l_i_ELfanew <= 0 Or $l_i_ELfanew > (4096 - 0x18) Then
        Log_Error("Invalid e_lfanew", "Sections", $g_h_EditText)
        Return False
    EndIf

    Local $l_d_Nt = DllStructCreate("dword Signature;word Machine;word NumberOfSections;" & _
        "dword TimeDateStamp;dword PointerToSymbolTable;dword NumberOfSymbols;" & _
        "word SizeOfOptionalHeader;word Characteristics", $l_p_Page + $l_i_ELfanew)
    If DllStructGetData($l_d_Nt, "Signature") <> 0x4550 Then ; 'PE\0\0'
        Log_Error("Invalid PE signature", "Sections", $g_h_EditText)
        Return False
    EndIf

    Local $l_i_NumberOfSections = DllStructGetData($l_d_Nt, "NumberOfSections")
    Local $l_i_SizeOfOptionalHeader = DllStructGetData($l_d_Nt, "SizeOfOptionalHeader")
    Local $l_i_SectionOffset = $l_i_ELfanew + 24 + $l_i_SizeOfOptionalHeader

    Global $g_ai2_Sections[5][2] ; (re)declare to zero before populating

    For $l_i_Idx = 0 To $l_i_NumberOfSections - 1
        Local $l_d_Sec = DllStructCreate("char Name[8];dword VirtualSize;dword VirtualAddress;" & _
            "dword SizeOfRawData;dword PointerToRawData;dword PointerToRelocations;" & _
            "dword PointerToLinenumbers;word NumberOfRelocations;word NumberOfLinenumbers;" & _
            "dword Characteristics", $l_p_Page + $l_i_SectionOffset + ($l_i_Idx * 40))

        Local $l_i_SecIdx = Scanner_SectionNameToIndex(StringStripWS(DllStructGetData($l_d_Sec, "Name"), 8))
        If $l_i_SecIdx < 0 Then ContinueLoop

        Local $l_i_VSize = DllStructGetData($l_d_Sec, "VirtualSize")
        Local $l_i_RawSize = DllStructGetData($l_d_Sec, "SizeOfRawData")
        Local $l_i_ActualSize = ($l_i_VSize > $l_i_RawSize) ? $l_i_VSize : $l_i_RawSize

        $g_ai2_Sections[$l_i_SecIdx][0] = $a_p_BaseAddress + DllStructGetData($l_d_Sec, "VirtualAddress")
        $g_ai2_Sections[$l_i_SecIdx][1] = $g_ai2_Sections[$l_i_SecIdx][0] + $l_i_ActualSize
    Next

    If $g_ai2_Sections[$GC_I_SECTION_TEXT][0] = 0 Then
        Log_Error("Failed to find .text section", "Sections", $g_h_EditText)
        Return False
    EndIf

    $g_b_SectionsInitialized = True

    Return True
EndFunc   ;==>Scanner_InitializeSections

Func Scanner_SectionNameToIndex($a_s_Name)
	Switch $a_s_Name
		Case ".text"
			Return $GC_I_SECTION_TEXT
		Case ".rdata"
			Return $GC_I_SECTION_RDATA
		Case ".data"
			Return $GC_I_SECTION_DATA
		Case ".rsrc"
			Return $GC_I_SECTION_RSRC
		Case ".reloc"
			Return $GC_I_SECTION_RELOC
	EndSwitch
    
	Return -1
EndFunc   ;==>Scanner_SectionNameToIndex

Func Scanner_GetSection($a_i_Section, ByRef $a_p_Start, ByRef $a_p_End)
	$a_p_Start = 0
	$a_p_End = 0

	If Not $g_b_SectionsInitialized Then Return False

	$a_p_Start = $g_ai2_Sections[$a_i_Section][0]
	$a_p_End = $g_ai2_Sections[$a_i_Section][1]

	Return ($a_p_Start <> 0)
EndFunc   ;==>Scanner_GetSection

Func Scanner_FindMultipleStrings($a_as_Strings, $a_i_Section = $GC_I_SECTION_RDATA)
    Local $l_i_StringCount = UBound($a_as_Strings)
    Local $l_ai_Results[$l_i_StringCount]
    Local $l_ab_Found[$l_i_StringCount]
    Local $l_ax_Patterns[$l_i_StringCount]
    Local $l_ai_Lengths[$l_i_StringCount]
    Local $l_ai2_SkipTables[$l_i_StringCount][256]

    If Not $g_b_SectionsInitialized Then Return $l_ai_Results

    For $l_i_Idx = 0 To $l_i_StringCount - 1
        $l_ai_Results[$l_i_Idx] = 0
        $l_ab_Found[$l_i_Idx] = False
        $l_ax_Patterns[$l_i_Idx] = Utils_StringToBytes($a_as_Strings[$l_i_Idx])
        $l_ai_Lengths[$l_i_Idx] = BinaryLen($l_ax_Patterns[$l_i_Idx])

        For $l_i_ByteIdx = 0 To 255
            $l_ai2_SkipTables[$l_i_Idx][$l_i_ByteIdx] = $l_ai_Lengths[$l_i_Idx]
        Next

        For $l_i_PatternIdx = 0 To $l_ai_Lengths[$l_i_Idx] - 2
            Local $l_i_Byte = Number(BinaryMid($l_ax_Patterns[$l_i_Idx], $l_i_PatternIdx + 1, 1))
            $l_ai2_SkipTables[$l_i_Idx][$l_i_Byte] = $l_ai_Lengths[$l_i_Idx] - $l_i_PatternIdx - 1
        Next
    Next

    Local $l_p_Start = $g_ai2_Sections[$a_i_Section][0]
    Local $l_p_End = $g_ai2_Sections[$a_i_Section][1]

    If $l_p_Start = 0 Or $l_p_End = 0 Or $l_p_Start >= $l_p_End Then
        Log_Warning("Invalid section bounds. Start: " & Hex($l_p_Start) & ", End: " & Hex($l_p_End), "Scanner_FindMultipleStrings", $g_h_EditText)
        Return Scanner_FindMultipleStringsFallback($a_as_Strings, $a_i_Section)
    EndIf

    Local $l_i_SectionSize = Number($l_p_End - $l_p_Start)
    Local $l_f_SectionSizeMB = Number($l_i_SectionSize) / Number(1048576)

    Local $l_i_MaxReadSize = 1 * 1024 * 1024
    Local $l_f_MaxReadSizeMB = 1.0

    If $l_i_SectionSize > $l_i_MaxReadSize Then
        Return Scanner_FindMultipleStringsFallback($a_as_Strings, $a_i_Section)
    EndIf

    Local $l_d_SectionBuffer = DllStructCreate("byte[" & $l_i_SectionSize & "]")
    If @error Then
        Return Scanner_FindMultipleStringsFallback($a_as_Strings, $a_i_Section)
    EndIf

    Local $l_i_BytesRead = 0
    Local $l_ab_Success = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
        "handle", $g_h_GWProcess, _
        "ptr", $l_p_Start, _
        "ptr", DllStructGetPtr($l_d_SectionBuffer), _
        "ulong_ptr", $l_i_SectionSize, _
        "ulong_ptr*", $l_i_BytesRead)
    If @error Or Not $l_ab_Success[0] Or $l_ab_Success[5] < $l_i_SectionSize Then
        Log_Warning("Failed to read section into memory. Read " & $l_ab_Success[5] & "/" & $l_i_SectionSize & " bytes. Using fallback method.", "Scanner_FindMultipleStrings", $g_h_EditText)
        Return Scanner_FindMultipleStringsFallback($a_as_Strings, $a_i_Section)
    EndIf

    Local $l_i_TotalFound = 0
    Local $l_i_StartTime = TimerInit()

    For $l_i_PatternIdx = 0 To $l_i_StringCount - 1
        If $l_ab_Found[$l_i_PatternIdx] Then ContinueLoop

        Local $l_i_PatternLen = $l_ai_Lengths[$l_i_PatternIdx]
        Local $l_i_Pos = $l_i_PatternLen - 1

        While $l_i_Pos < $l_i_SectionSize
            Local $l_b_Match = True
            Local $l_i_CheckIdx = $l_i_PatternLen - 1

            While $l_i_CheckIdx >= 0
                Local $l_i_MemByte = DllStructGetData($l_d_SectionBuffer, 1, $l_i_Pos - ($l_i_PatternLen - 1 - $l_i_CheckIdx) + 1)
                Local $l_i_PatByte = Number(BinaryMid($l_ax_Patterns[$l_i_PatternIdx], $l_i_CheckIdx + 1, 1))

                If $l_i_MemByte <> $l_i_PatByte Then
                    $l_b_Match = False
                    $l_i_Pos += $l_ai2_SkipTables[$l_i_PatternIdx][$l_i_MemByte]
                    ExitLoop
                EndIf
                $l_i_CheckIdx -= 1
            WEnd

            If $l_b_Match Then
                $l_ai_Results[$l_i_PatternIdx] = $l_p_Start + $l_i_Pos - ($l_i_PatternLen - 1)
                $l_ab_Found[$l_i_PatternIdx] = True
                $l_i_TotalFound += 1
                ExitLoop
            EndIf
        WEnd

        If $l_i_TotalFound = $l_i_StringCount Then ExitLoop
    Next

    Return $l_ai_Results
EndFunc   ;==>Scanner_FindMultipleStrings

Func Scanner_FindMultipleStringsFallback($a_as_Strings, $a_i_Section = $GC_I_SECTION_RDATA)
    Local $l_i_StringCount = UBound($a_as_Strings)
    Local $l_ai_Results[$l_i_StringCount]
    Local $l_ab_Found[$l_i_StringCount]
    Local $l_ax_Patterns[$l_i_StringCount]
    Local $l_ai_Lengths[$l_i_StringCount]
    Local $l_ai_FirstBytes[$l_i_StringCount]
    Local $l_as_HashTable[256]
    Local $l_i_MinLength = 999999
    Local $l_i_MaxLength = 0

    For $l_i_Idx = 0 To 255
        $l_as_HashTable[$l_i_Idx] = ""
    Next

    For $l_i_Idx = 0 To $l_i_StringCount - 1
        $l_ai_Results[$l_i_Idx] = 0
        $l_ab_Found[$l_i_Idx] = False
        $l_ax_Patterns[$l_i_Idx] = Utils_StringToBytes($a_as_Strings[$l_i_Idx])
        $l_ai_Lengths[$l_i_Idx] = BinaryLen($l_ax_Patterns[$l_i_Idx])
        $l_ai_FirstBytes[$l_i_Idx] = Number(BinaryMid($l_ax_Patterns[$l_i_Idx], 1, 1))

        If $l_ai_Lengths[$l_i_Idx] < $l_i_MinLength Then $l_i_MinLength = $l_ai_Lengths[$l_i_Idx]
        If $l_ai_Lengths[$l_i_Idx] > $l_i_MaxLength Then $l_i_MaxLength = $l_ai_Lengths[$l_i_Idx]

        If $l_as_HashTable[$l_ai_FirstBytes[$l_i_Idx]] = "" Then
            $l_as_HashTable[$l_ai_FirstBytes[$l_i_Idx]] = String($l_i_Idx)
        Else
            $l_as_HashTable[$l_ai_FirstBytes[$l_i_Idx]] &= "," & $l_i_Idx
        EndIf
    Next

    Local $l_p_Start = $g_ai2_Sections[$a_i_Section][0]
    Local $l_p_End = $g_ai2_Sections[$a_i_Section][1]
    Local $l_i_BufferSize = 2097152
    Local $l_d_Buffer = DllStructCreate("byte[" & $l_i_BufferSize & "]")
    Local $l_i_TotalFound = 0
    Local $l_i_StartTime = TimerInit()
    Local $l_i_Overlap = $l_i_MaxLength - 1

    Local $l_ai2_PatternData[$l_i_StringCount][$l_i_MaxLength]
    For $l_i_Idx = 0 To $l_i_StringCount - 1
        For $l_i_ByteIdx = 0 To $l_ai_Lengths[$l_i_Idx] - 1
            $l_ai2_PatternData[$l_i_Idx][$l_i_ByteIdx] = Number(BinaryMid($l_ax_Patterns[$l_i_Idx], $l_i_ByteIdx + 1, 1))
        Next
    Next

    For $l_p_CurrentAddr = $l_p_Start To $l_p_End Step $l_i_BufferSize - $l_i_Overlap
        If $l_i_TotalFound = $l_i_StringCount Then ExitLoop

        Local $l_i_ReadSize = $l_i_BufferSize
        If $l_p_CurrentAddr + $l_i_ReadSize > $l_p_End Then
            $l_i_ReadSize = $l_p_End - $l_p_CurrentAddr
        EndIf

        Local $l_i_BytesRead = 0
        Local $l_ab_Success = DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
            "handle", $g_h_GWProcess, _
            "ptr", $l_p_CurrentAddr, _
            "ptr", DllStructGetPtr($l_d_Buffer), _
            "ulong_ptr", $l_i_ReadSize, _
            "ulong_ptr*", $l_i_BytesRead)
        If @error Or Not $l_ab_Success[0] Or $l_ab_Success[5] = 0 Then ContinueLoop

        $l_i_ReadSize = $l_ab_Success[5]

        Local $l_i_SearchEnd = $l_i_ReadSize - $l_i_MinLength + 1
        For $l_i_SearchIdx = 0 To $l_i_SearchEnd - 1
            Local $l_i_Byte = DllStructGetData($l_d_Buffer, 1, $l_i_SearchIdx + 1)

            If $l_as_HashTable[$l_i_Byte] = "" Then ContinueLoop

            Local $l_as_Indices = StringSplit($l_as_HashTable[$l_i_Byte], ",", 2)

            For $l_i_IndexIdx = 0 To UBound($l_as_Indices) - 1
                Local $l_i_PatternIdx = Number($l_as_Indices[$l_i_IndexIdx])
                If $l_ab_Found[$l_i_PatternIdx] Then ContinueLoop

                Local $l_i_PatternLen = $l_ai_Lengths[$l_i_PatternIdx]

                If $l_i_SearchIdx + $l_i_PatternLen > $l_i_ReadSize Then ContinueLoop

                Local $l_b_Match = True

                Local $l_i_MidPoint = Int($l_i_PatternLen / 2)
                If DllStructGetData($l_d_Buffer, 1, $l_i_SearchIdx + $l_i_MidPoint + 1) <> $l_ai2_PatternData[$l_i_PatternIdx][$l_i_MidPoint] Then ContinueLoop
                If DllStructGetData($l_d_Buffer, 1, $l_i_SearchIdx + $l_i_PatternLen) <> $l_ai2_PatternData[$l_i_PatternIdx][$l_i_PatternLen - 1] Then ContinueLoop

                For $l_i_CompareIdx = 1 To $l_i_PatternLen - 2
                    If $l_i_CompareIdx = $l_i_MidPoint Then ContinueLoop
                    If DllStructGetData($l_d_Buffer, 1, $l_i_SearchIdx + $l_i_CompareIdx + 1) <> $l_ai2_PatternData[$l_i_PatternIdx][$l_i_CompareIdx] Then
                        $l_b_Match = False
                        ExitLoop
                    EndIf
                Next

                If $l_b_Match Then
                    $l_ai_Results[$l_i_PatternIdx] = $l_p_CurrentAddr + $l_i_SearchIdx
                    $l_ab_Found[$l_i_PatternIdx] = True
                    $l_i_TotalFound += 1

                    Local $l_s_NewIndices = ""
                    For $l_i_RemoveIdx = 0 To UBound($l_as_Indices) - 1
                        If Number($l_as_Indices[$l_i_RemoveIdx]) <> $l_i_PatternIdx Then
                            If $l_s_NewIndices = "" Then
                                $l_s_NewIndices = $l_as_Indices[$l_i_RemoveIdx]
                            Else
                                $l_s_NewIndices &= "," & $l_as_Indices[$l_i_RemoveIdx]
                            EndIf
                        EndIf
                    Next
                    $l_as_HashTable[$l_i_Byte] = $l_s_NewIndices

                    If $l_i_TotalFound = $l_i_StringCount Then ExitLoop 3
                EndIf
            Next
        Next
    Next

    Local $l_f_ElapsedTime = TimerDiff($l_i_StartTime)

    Return $l_ai_Results
EndFunc   ;==>Scanner_FindMultipleStringsFallback

Func Scanner_GetMultipleAssertionPatterns($a_amx_Assertions)
    Local $l_i_AssertionCount = UBound($a_amx_Assertions)
    Local $l_as_Patterns[$l_i_AssertionCount]

    Local $l_amx_UncachedAssertions[0][3]
    Local $l_as_AllStrings[0]

    For $l_i_Idx = 0 To $l_i_AssertionCount - 1
        Local $l_b_Cached = False
        For $l_i_CacheIdx = 0 To UBound($g_amx_AssertionCache) - 1
            If $g_amx_AssertionCache[$l_i_CacheIdx][0] = $a_amx_Assertions[$l_i_Idx][0] And $g_amx_AssertionCache[$l_i_CacheIdx][1] = $a_amx_Assertions[$l_i_Idx][1] Then
                $l_as_Patterns[$l_i_Idx] = $g_amx_AssertionCache[$l_i_CacheIdx][2]
                $l_b_Cached = True
                ExitLoop
            EndIf
        Next

        If Not $l_b_Cached Then
            Local $l_i_UncachedIdx = UBound($l_amx_UncachedAssertions)
            ReDim $l_amx_UncachedAssertions[$l_i_UncachedIdx + 1][3]
            $l_amx_UncachedAssertions[$l_i_UncachedIdx][0] = $l_i_Idx
            $l_amx_UncachedAssertions[$l_i_UncachedIdx][1] = $a_amx_Assertions[$l_i_Idx][0]
            $l_amx_UncachedAssertions[$l_i_UncachedIdx][2] = $a_amx_Assertions[$l_i_Idx][1]

            _ArrayAdd($l_as_AllStrings, $a_amx_Assertions[$l_i_Idx][0])
            _ArrayAdd($l_as_AllStrings, $a_amx_Assertions[$l_i_Idx][1])

            $l_as_Patterns[$l_i_Idx] = ""
        EndIf
    Next

    If UBound($l_amx_UncachedAssertions) = 0 Then
        Return $l_as_Patterns
    EndIf

    Local $l_ap_Addresses = Scanner_FindMultipleStrings($l_as_AllStrings)

    Local $l_amx_StringToAddress[0][2]
    For $l_i_Idx = 0 To UBound($l_as_AllStrings) - 1
        If $l_ap_Addresses[$l_i_Idx] > 0 Then
            Utils_ArrayAdd2D($l_amx_StringToAddress, $l_as_AllStrings[$l_i_Idx], $l_ap_Addresses[$l_i_Idx])
        EndIf
    Next

    For $l_i_Idx = 0 To UBound($l_amx_UncachedAssertions) - 1
        Local $l_i_AssertIdx = $l_amx_UncachedAssertions[$l_i_Idx][0]
        Local $l_p_FileAddr = 0
        Local $l_p_MsgAddr = 0

        For $l_i_LookupIdx = 0 To UBound($l_amx_StringToAddress) - 1
            If $l_amx_StringToAddress[$l_i_LookupIdx][0] = $l_amx_UncachedAssertions[$l_i_Idx][1] Then
                $l_p_FileAddr = $l_amx_StringToAddress[$l_i_LookupIdx][1]
            ElseIf $l_amx_StringToAddress[$l_i_LookupIdx][0] = $l_amx_UncachedAssertions[$l_i_Idx][2] Then
                $l_p_MsgAddr = $l_amx_StringToAddress[$l_i_LookupIdx][1]
            EndIf
        Next

        If $l_p_FileAddr > 0 And $l_p_MsgAddr > 0 Then
            $l_as_Patterns[$l_i_AssertIdx] = "BA" & Utils_SwapEndian(Hex($l_p_FileAddr, 8)) & "B9" & Utils_SwapEndian(Hex($l_p_MsgAddr, 8))

            Local $l_i_CacheIdx = UBound($g_amx_AssertionCache)
            ReDim $g_amx_AssertionCache[$l_i_CacheIdx + 1][3]
            $g_amx_AssertionCache[$l_i_CacheIdx][0] = $l_amx_UncachedAssertions[$l_i_Idx][1]
            $g_amx_AssertionCache[$l_i_CacheIdx][1] = $l_amx_UncachedAssertions[$l_i_Idx][2]
            $g_amx_AssertionCache[$l_i_CacheIdx][2] = $l_as_Patterns[$l_i_AssertIdx]
        EndIf
    Next

    Return $l_as_Patterns
EndFunc   ;==>Scanner_GetMultipleAssertionPatterns

Func Scanner_FunctionFromNearCall($a_p_CallInstructionAddress)
    Local $l_i_Opcode = Memory_Read($a_p_CallInstructionAddress, "byte")
    Local $l_p_FunctionAddress = 0

    Switch $l_i_Opcode
        Case 0xE8, 0xE9
            Local $l_i_NearAddress = Memory_Read($a_p_CallInstructionAddress + 1, "dword")
            If $l_i_NearAddress > 0x7FFFFFFF Then
                $l_i_NearAddress -= 0x100000000
            EndIf
            $l_p_FunctionAddress = $l_i_NearAddress + ($a_p_CallInstructionAddress + 5)

        Case 0xEB
            Local $l_i_NearAddress = Memory_Read($a_p_CallInstructionAddress + 1, "byte")
            If BitAND($l_i_NearAddress, 0x80) Then
                $l_i_NearAddress = -((BitNOT($l_i_NearAddress) + 1) And 0xFF)
            EndIf
            $l_p_FunctionAddress = $l_i_NearAddress + ($a_p_CallInstructionAddress + 2)

        Case Else
            Return 0
    EndSwitch

    Local $l_p_NestedCall = Scanner_FunctionFromNearCall($l_p_FunctionAddress)
    If $l_p_NestedCall <> 0 Then
        Return $l_p_NestedCall
    EndIf

    Return $l_p_FunctionAddress
EndFunc   ;==>Scanner_FunctionFromNearCall

Func Scanner_FindInRange($a_s_Pattern, $a_s_Mask, $a_i_Offset, $a_p_Start, $a_p_End)
    Local $l_ai_PatternBytes = Utils_StringToByteArray($a_s_Pattern)
    Local $l_i_PatternLength = UBound($l_ai_PatternBytes)
    Local $l_b_Found = False

    $a_p_Start = BitAND($a_p_Start, 0xFFFFFFFF)
    $a_p_End = BitAND($a_p_End, 0xFFFFFFFF)

    If $a_p_End > $a_p_Start Then
        $a_p_End = $a_p_End - $l_i_PatternLength + 1
    EndIf

    If $a_p_Start > $a_p_End Then
        Local $l_p_Idx = $a_p_Start
        While $l_p_Idx >= $a_p_End
            Local $l_i_FirstByte = Memory_Read($l_p_Idx, 'byte')
            If $l_i_FirstByte <> $l_ai_PatternBytes[0] Then
                $l_p_Idx -= 1
                ContinueLoop
            EndIf

            $l_b_Found = True
            For $l_i_ByteIdx = 0 To $l_i_PatternLength - 1
                If $a_s_Mask <> "" And StringMid($a_s_Mask, $l_i_ByteIdx + 1, 1) <> "x" Then
                    ContinueLoop
                EndIf

                Local $l_i_MemByte = Memory_Read($l_p_Idx + $l_i_ByteIdx, 'byte')
                If $l_i_MemByte <> $l_ai_PatternBytes[$l_i_ByteIdx] Then
                    $l_b_Found = False
                    ExitLoop
                EndIf
            Next

            If $l_b_Found Then
                Return $l_p_Idx + $a_i_Offset
            EndIf
            $l_p_Idx -= 1
        WEnd
    Else
        Local $l_p_Idx = $a_p_Start
        While $l_p_Idx < $a_p_End
            Local $l_i_FirstByte = Memory_Read($l_p_Idx, 'byte')
            If $l_i_FirstByte <> $l_ai_PatternBytes[0] Then
                $l_p_Idx += 1
                ContinueLoop
            EndIf

            $l_b_Found = True
            For $l_i_ByteIdx = 0 To $l_i_PatternLength - 1
                If $a_s_Mask <> "" And StringMid($a_s_Mask, $l_i_ByteIdx + 1, 1) <> "x" Then
                    ContinueLoop
                EndIf

                Local $l_i_MemByte = Memory_Read($l_p_Idx + $l_i_ByteIdx, 'byte')
                If $l_i_MemByte <> $l_ai_PatternBytes[$l_i_ByteIdx] Then
                    $l_b_Found = False
                    ExitLoop
                EndIf
            Next

            If $l_b_Found Then
                Return $l_p_Idx + $a_i_Offset
            EndIf
            $l_p_Idx += 1
        WEnd
    EndIf

    Return 0
EndFunc   ;==>Scanner_FindInRange

Func Scanner_ToFunctionStart($a_p_CallInstructionAddress, $a_i_ScanRange = 0x200)
    If $a_p_CallInstructionAddress = 0 Then Return 0

    Local $l_p_Start = $a_p_CallInstructionAddress
    Local $l_p_End = BitAND($a_p_CallInstructionAddress - $a_i_ScanRange, 0xFFFFFFFF)

    Return Scanner_FindInRange("558BEC", "xxx", 0, $l_p_Start, $l_p_End)
EndFunc   ;==>Scanner_ToFunctionStart

Func Scanner_GetCallTargetAddress($a_p_Address)
    Local $l_x_Offset = Memory_Read($a_p_Address + 1, "dword")

    If $l_x_Offset > 0x7FFFFFFF Then
        $l_x_Offset -= 0x100000000
    EndIf

    Local $l_p_TargetAddress = $a_p_Address + 5 + $l_x_Offset

    Return $l_p_TargetAddress
EndFunc   ;==>Scanner_GetCallTargetAddress

Func Scanner_GetHwnd($a_i_Proc)
    Local $l_as_Wins = WinList("[CLASS:" & $GC_S_CLASS_DX_WINDOW & "]")
    For $l_i_Idx = 1 To UBound($l_as_Wins) - 1
        If WinGetProcess($l_as_Wins[$l_i_Idx][1]) = $a_i_Proc Then Return $l_as_Wins[$l_i_Idx][1]
    Next
EndFunc   ;==>Scanner_GetHwnd

Func Scanner_GetWindowHandle()
    Return $g_h_GWWindow
EndFunc   ;==>Scanner_GetWindowHandle

Func Scanner_GetLoggedCharNames()
    Local $l_as_Array = Scanner_ScanGW()
    If $l_as_Array[0] = 0 Then Return ""
    Local $l_s_Ret = $l_as_Array[1]
    For $l_i_Idx = 2 To $l_as_Array[0]
        $l_s_Ret &= "|" & $l_as_Array[$l_i_Idx]
    Next
    Return $l_s_Ret
EndFunc   ;==>Scanner_GetLoggedCharNames

Func Scanner_ScanGW()
    Local $l_as_ProcessList = ProcessList("gw.exe")
    Local $l_i_ProcessCount = $l_as_ProcessList[0][0]
    Local $l_as_ReturnArray[$l_i_ProcessCount + 1]
    Local $l_i_CharCount = 0

    For $i = 1 To $l_i_ProcessCount
        Memory_Open($l_as_ProcessList[$i][1])
        If $g_h_GWProcess <> 0 And Scanner_InitializeSections() Then
			Scanner_ScanForCharname()
            $l_i_CharCount += 1
            $l_as_ReturnArray[$l_i_CharCount] = Player_GetCharName()
        EndIf
        Memory_Close()
    Next

    $l_as_ReturnArray[0] = $l_i_CharCount
    ReDim $l_as_ReturnArray[$l_i_CharCount + 1]

    Return $l_as_ReturnArray
EndFunc   ;==>Scanner_ScanGW

Func Scanner_ScanForGwAu3()
	Local $l_s_Header = Binary("0x" & $GC_S_GWAU3_HEADER_BIN)
	Local $l_i_HeaderLen = BinaryLen($l_s_Header)

	Local $l_d_MBIBuffer = DllStructCreate("dword;dword;dword;dword;dword;dword;dword")
	Local $l_p_MBI = DllStructGetPtr($l_d_MBIBuffer), $l_i_MBISize = DllStructGetSize($l_d_MBIBuffer)
	Local $l_d_Read = DllStructCreate("byte[" & $l_i_HeaderLen & "]")
	Local $l_p_Read = DllStructGetPtr($l_d_Read)

	Local $l_p_Addr = 0x00000000

	While True
		Local $l_av_VQERet = DllCall($g_h_Kernel32, "int", "VirtualQueryEx", _
			"int", $g_h_GWProcess, _
			"ptr", $l_p_Addr, _
			"ptr", DllStructGetPtr($l_d_MBIBuffer), _
			"int", DllStructGetSize($l_d_MBIBuffer))
		If @error Or Not IsArray($l_av_VQERet) Or $l_av_VQERet[0] = 0 Then ExitLoop

		Local $l_p_Base = DllStructGetData($l_d_MBIBuffer, 1)
		Local $l_i_Size = DllStructGetData($l_d_MBIBuffer, 4)
		Local $l_i_State = DllStructGetData($l_d_MBIBuffer, 5)
		Local $l_i_Protect = DllStructGetData($l_d_MBIBuffer, 6)
		Local $l_i_Type = DllStructGetData($l_d_MBIBuffer, 7)

		If $l_i_State = 0x1000 And $l_i_Protect = 0x40 And $l_i_Type = 0x20000 Then
			Local $l_av_RPMRet = DllCall($g_h_Kernel32, "int", "ReadProcessMemory", _
				"int", $g_h_GWProcess, _
				"ptr", $l_p_Base, _
				"ptr", DllStructGetPtr($l_d_Read), _
				"int", $l_i_HeaderLen, _
				"int", "")
			If Not @error And IsArray($l_av_RPMRet) And $l_av_RPMRet[0] <> 0 Then
				If DllStructGetData($l_d_Read, 1) = $l_s_Header Then Return $l_p_Base
			EndIf
		EndIf

		Local $l_p_Next = $l_p_Base + $l_i_Size
		If $l_p_Next <= $l_p_Addr Then ExitLoop
		$l_p_Addr = $l_p_Next
	WEnd

	Return 0
EndFunc   ;==>Scanner_ScanForGwAu3

Func Scanner_ScanForCharname()
    Local Const $l_s_NamePattern = BinaryToString(Binary("0x8B0383C410A3"))
    Local Const $l_i_NameLen = 6
    Local Const $l_i_NameOffset = -0xF
    
    $g_p_CharName = 0

    Local $l_p_Start, $l_p_End
    If Not Scanner_GetSection($GC_I_SECTION_TEXT, $l_p_Start, $l_p_End) Then Return False

    Local $l_i_Size = Int($l_p_End - $l_p_Start)
    If $l_i_Size <= 0 Then Return False

    Local $l_d_Buf = DllStructCreate("byte[" & $l_i_Size & "]")
    Local $l_av_RPMRet = DllCall($g_h_Kernel32, "int", "ReadProcessMemory", _
        "int", $g_h_GWProcess, _
        "int", $l_p_Start, _
        "ptr", DllStructGetPtr($l_d_Buf), _
        "int", $l_i_Size, _
        "int", "")
    If @error Or Not IsArray($l_av_RPMRet) Or $l_av_RPMRet[0] = 0 Then Return False

    Local $l_s_Mem = BinaryToString(DllStructGetData($l_d_Buf, 1))
    Local $l_i_Pos = StringInStr($l_s_Mem, $l_s_NamePattern, 1)
    If $l_i_Pos = 0 Then Return False

    Local $l_p_Match = $l_p_Start + ($l_i_Pos - 1)

    Local $l_d_Ptr = DllStructCreate("ptr")
    DllCall($g_h_Kernel32, "int", "ReadProcessMemory", _
        "int", $g_h_GWProcess, _
        "int", $l_p_Match + $l_i_NameLen + $l_i_NameOffset, _
        "ptr", DllStructGetPtr($l_d_Ptr), _
        "int", DllStructGetSize($l_d_Ptr), _
        "int", "")
		
    $g_p_CharName = DllStructGetData($l_d_Ptr, 1)

    Return True
EndFunc   ;==>Scanner_ScanForCharname

Func Scanner_ScanAllPatterns()  
    Local $l_ap_Results[$g_amx2_Patterns[0][0] + 1]
    $l_ap_Results[0] = $g_amx2_Patterns[0][0]

    If UBound($g_amx2_AssertionPatterns) > 0 Then
        Local $l_as_AssertionPatterns = Scanner_GetMultipleAssertionPatterns($g_amx2_AssertionPatterns)

        Local $l_i_AssertIdx = 0
        For $l_i_Idx = 1 To $g_amx2_Patterns[0][0]
            If $g_amx2_Patterns[$l_i_Idx][4] Then
                $g_amx2_Patterns[$l_i_Idx][1] = $l_as_AssertionPatterns[$l_i_AssertIdx]
                $l_i_AssertIdx += 1
            EndIf
        Next
    EndIf

    $g_i_ASMSize = 0
    $g_i_ASMCodeOffset = 0
    $g_s_ASMCode = ""

    For $l_i_Idx = 1 To $g_amx2_Patterns[0][0]
        _($g_amx2_Patterns[$l_i_Idx][0] & ":")
        Scanner_AddPatternToASM($g_amx2_Patterns[$l_i_Idx][1]) 
    Next

    Local $l_p_Start, $l_p_End
	If Not Scanner_GetSection($GC_I_SECTION_TEXT, $l_p_Start, $l_p_End) Then Return SetError(1, 0, 0)
    Assembler_CreateScanProcedure($l_p_Start, $l_p_End)

    $g_p_GwAu3Header = Scanner_ScanForGwAu3()
    If $g_p_GwAu3Header = 0 Then
        Local $l_av_Alloc = DllCall($g_h_Kernel32, "ptr", "VirtualAllocEx", _
            "handle", $g_h_GWProcess, _
            "ptr", 0, _
            "ulong_ptr", $GC_I_GWAU3_HEADER_SIZE, _
            "dword", 0x1000, _
            "dword", 0x40)

        $g_p_GwAu3Header = $l_av_Alloc[0]
        If $g_p_GwAu3Header = 0 Then Return SetError(2, 0, 0)

        Memory_WriteBinary($GC_S_GWAU3_HEADER_BIN, $g_p_GwAu3Header)
        Memory_Write($g_p_GwAu3Header + $GC_I_GWAU3_OFFSET_SCANPTR, 0)
        Memory_Write($g_p_GwAu3Header + $GC_I_GWAU3_OFFSET_CMDPTR, 0)
    EndIf

	; --- Review note (keep): always fresh ScanPtr + ScanProc ---
	; Bug: reusing Header.ScanPtr after the pattern list grows/changes (plugin Extend,
	; extra Scanner_AddPattern, etc.) leaves an undersized / stale ASM scan buffer.
	; GetScannedAddress then returns garbage (e.g. SkillLog Start 0xF04D9654 with
	; hookBytes=0000000000 while CasterSkillLogProc head looked fine).
	; Fix: allocate a new scan buffer sized to current $g_i_ASMSize and re-run ScanProc
	; every ScanAllPatterns. Not SkillLog-specific — any late-added pattern needs this.
	; Tradeoff: prior ScanPtr allocations are not freed here (small leak per rescan).
	Local $l_b_AllocScan = True
	Local $l_av_ScanAlloc = DllCall($g_h_Kernel32, "ptr", "VirtualAllocEx", _
		"handle", $g_h_GWProcess, _
		"ptr", 0, _
		"ulong_ptr", $g_i_ASMSize, _
		"dword", 0x1000, _
		"dword", 0x40)

	$g_p_GwAu3Scan = $l_av_ScanAlloc[0]
	If $g_p_GwAu3Scan = 0 Then Return SetError(3, 0, 0)

	Memory_Write($g_p_GwAu3Header + $GC_I_GWAU3_OFFSET_SCANPTR, $g_p_GwAu3Scan)

	$g_p_ASMMemory = $g_p_GwAu3Scan
	Assembler_CompleteASMCode()

	If $l_b_AllocScan Or $g_b_DevMode Then
		Memory_WriteBinary($g_s_ASMCode, $g_p_ASMMemory + $g_i_ASMCodeOffset)

		Local $l_h_Thread = DllCall($g_h_Kernel32, "int", "CreateRemoteThread", _
			"int", $g_h_GWProcess, _
			"ptr", 0, _
			"int", 0, _
			"int", Memory_GetLabelInfo("ScanProc"), _
			"ptr", 0, _
			"int", 0, _
			"int", 0)

		$l_h_Thread = $l_h_Thread[0]

		Local $l_av_Result
		Do
			$l_av_Result = DllCall($g_h_Kernel32, "int", "WaitForSingleObject", "int", $l_h_Thread, "int", 50)
		Until $l_av_Result[0] <> 258

		DllCall($g_h_Kernel32, "int", "CloseHandle", "int", $l_h_Thread)
	EndIf

    For $l_i_Idx = 1 To $g_amx2_Patterns[0][0]
        $l_ap_Results[$l_i_Idx] = Memory_GetScannedAddress($g_amx2_Patterns[$l_i_Idx][0], $g_amx2_Patterns[$l_i_Idx][2])
    Next

    Return $l_ap_Results
EndFunc   ;==>Scanner_ScanAllPatterns

Func Scanner_GetScanResult($a_s_Name, $a_ap_Results = 0, $a_s_Type = "")
    If Not IsArray($a_ap_Results) Then Return 0

    Local $l_s_SearchName = "Scan" & $a_s_Name & $a_s_Type

    For $l_i_Idx = 1 To $g_amx2_Patterns[0][0]
        If $g_amx2_Patterns[$l_i_Idx][0] = $l_s_SearchName Or _
           ($a_s_Type = "" And StringInStr($g_amx2_Patterns[$l_i_Idx][0], "Scan" & $a_s_Name)) Then
            Return $a_ap_Results[$l_i_Idx]
        EndIf
    Next

    Return 0
EndFunc   ;==>Scanner_GetScanResult

Func Scanner_ClearPatterns()
    ReDim $g_amx2_Patterns[1][6]
    $g_amx2_Patterns[0][0] = 0
    ReDim $g_amx2_AssertionPatterns[0][2]
EndFunc   ;==>Scanner_ClearPatterns

Func Scanner_AddPattern($a_s_Name, $a_s_Pattern, $a_v_OffsetOrMsg = 0, $a_s_Type = "Ptr")
    Local $l_i_Index = $g_amx2_Patterns[0][0] + 1
    ReDim $g_amx2_Patterns[$l_i_Index + 1][6]
    $g_amx2_Patterns[0][0] = $l_i_Index

    Local $l_s_FullName = "Scan" & $a_s_Name & $a_s_Type

    Local $l_b_IsAssertion = False
    Local $l_s_AssertionMsg = ""

    If StringInStr($a_s_Pattern, ":\") Or StringInStr($a_s_Pattern, ":/") Then
        $l_b_IsAssertion = True
        $l_s_AssertionMsg = $a_v_OffsetOrMsg

        Local $l_i_AssertIndex = UBound($g_amx2_AssertionPatterns)
        ReDim $g_amx2_AssertionPatterns[$l_i_AssertIndex + 1][2]
        $g_amx2_AssertionPatterns[$l_i_AssertIndex][0] = $a_s_Pattern
        $g_amx2_AssertionPatterns[$l_i_AssertIndex][1] = $l_s_AssertionMsg
    EndIf

    $g_amx2_Patterns[$l_i_Index][0] = $l_s_FullName
    $g_amx2_Patterns[$l_i_Index][1] = $a_s_Pattern
    $g_amx2_Patterns[$l_i_Index][2] = $l_b_IsAssertion ? 0 : $a_v_OffsetOrMsg
    $g_amx2_Patterns[$l_i_Index][3] = $a_s_Type
    $g_amx2_Patterns[$l_i_Index][4] = $l_b_IsAssertion
    $g_amx2_Patterns[$l_i_Index][5] = $l_s_AssertionMsg
EndFunc   ;==>Scanner_AddPattern

Func Scanner_AddPatternToASM($a_s_Pattern)

	$a_s_Pattern = StringReplace($a_s_Pattern, "??", "00")

    Local $l_i_Size = Int(0.5 * StringLen($a_s_Pattern))
    Local $l_s_PatternHeader = "00000000" & Utils_SwapEndian(Hex($l_i_Size, 8)) & "00000000"

    $g_s_ASMCode &= $l_s_PatternHeader & $a_s_Pattern
    $g_i_ASMSize += $l_i_Size + 12

    Local $l_i_PaddingCount = 68 - $l_i_Size
    For $l_i_Idx = 1 To $l_i_PaddingCount
        $g_i_ASMSize += 1
        $g_s_ASMCode &= "00"
    Next
EndFunc   ;==>Scanner_AddPatternToASM

Func Scanner_GetPatternInfo($a_s_Name, $a_s_Type = "")
    Local $l_s_SearchName = "Scan" & $a_s_Name & $a_s_Type
    For $l_i_Idx = 1 To $g_amx2_Patterns[0][0]
        If $g_amx2_Patterns[$l_i_Idx][0] = $l_s_SearchName Or _
           ($a_s_Type = "" And StringInStr($g_amx2_Patterns[$l_i_Idx][0], "Scan" & $a_s_Name)) Then
            Local $l_av_Info[6]
            For $l_i_InfoIdx = 0 To 5
                $l_av_Info[$l_i_InfoIdx] = $g_amx2_Patterns[$l_i_Idx][$l_i_InfoIdx]
            Next
            Return $l_av_Info
        EndIf
    Next
    Return 0
EndFunc   ;==>Scanner_GetPatternInfo