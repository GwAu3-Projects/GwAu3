#include-once

Func Assembler_Reg32Code($a_s_Reg)
    Switch $a_s_Reg
        Case "eax"
			Return 0
        Case "ecx"
			Return 1
        Case "edx"
			Return 2
        Case "ebx"
			Return 3
        Case "esp"
			Return 4
        Case "ebp"
			Return 5
        Case "esi"
			Return 6
        Case "edi"
			Return 7
    EndSwitch
    Return SetError(1, 0, -1)
EndFunc

Func Assembler_Reg16Code($a_s_Reg)
    Switch $a_s_Reg
        Case "ax"
			Return 0
        Case "cx"
			Return 1
        Case "dx"
			Return 2
        Case "bx"
			Return 3
        Case "sp"
			Return 4
        Case "bp"
			Return 5
        Case "si"
			Return 6
        Case "di"
			Return 7
    EndSwitch
    Return SetError(1, 0, -1)
EndFunc

Func Assembler_Reg8Code($a_s_Reg)
    Switch $a_s_Reg
        Case "al"
			Return 0
        Case "cl"
			Return 1
        Case "dl"
			Return 2
        Case "bl"
			Return 3
        Case "ah"
			Return 4
        Case "ch"
			Return 5
        Case "dh"
			Return 6
        Case "bh"
			Return 7
    EndSwitch
    Return SetError(1, 0, -1)
EndFunc

Func _NormalizeHexValue($s_Value)
	$s_Value = StringRegExpReplace($s_Value, '^0x', '')
	$s_Value = StringRegExpReplace($s_Value, 'h$', '')
	Return $s_Value
EndFunc

Func _ParseValue($s_Value)
	Local $b_IsNegative = False
	Local $s_CleanValue = $s_Value

	If StringLeft($s_Value, 1) = "-" Then
		$b_IsNegative = True
		$s_CleanValue = StringMid($s_Value, 2)
	EndIf

	$s_CleanValue = _NormalizeHexValue($s_CleanValue)

	Local $i_Value = Dec($s_CleanValue)
	If $b_IsNegative Then
		$i_Value = -$i_Value
	EndIf

	Return $i_Value
EndFunc

Func _($a_s_ASM)
	Local $l_v_Buffer
	Local $l_s_OpCode

	Select
		Case StringLeft($a_s_ASM, 1) = ";"
            Return
		Case StringInStr($a_s_ASM, ' -> ')
			Local $l_s_Split = StringSplit($a_s_ASM, ' -> ', 1)
			$l_s_OpCode = StringReplace($l_s_Split[2], ' ', '')
			$g_i_ASMSize += 0.5 * StringLen($l_s_OpCode)
			$g_s_ASMCode &= $l_s_OpCode
		Case StringRight($a_s_ASM, 1) = ':'
			Memory_SetValue('Label_' & StringLeft($a_s_ASM, StringLen($a_s_ASM) - 1), $g_i_ASMSize)
		Case StringInStr($a_s_ASM, '/') > 0
			Memory_SetValue('Label_' & StringLeft($a_s_ASM, StringInStr($a_s_ASM, '/') - 1), $g_i_ASMSize)
			Local $l_i_Offset = StringRight($a_s_ASM, StringLen($a_s_ASM) - StringInStr($a_s_ASM, '/'))
			$g_i_ASMSize += $l_i_Offset
			$g_i_ASMCodeOffset+= $l_i_Offset
		Case StringLeft($a_s_ASM, 5) = 'nop x'
			$l_v_Buffer = Int(Number(StringTrimLeft($a_s_ASM, 5)))
			$g_i_ASMSize += $l_v_Buffer
			For $l_i_Idx = 1 To $l_v_Buffer
				$g_s_ASMCode &= '90'
			Next
		Case StringLeft($a_s_ASM, 3) = 'jb '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '72(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 3) & ')'
		Case StringLeft($a_s_ASM, 3) = 'je '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '74(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 3) & ')'
		Case StringLeft($a_s_ASM, 5) = 'ljmp '
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'E9{' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 5) & '}'
		Case StringLeft($a_s_ASM, 5) = 'ljne '
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '0F85{' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 5) & '}'
		Case StringLeft($a_s_ASM, 4) = 'jmp ' And StringLen($a_s_ASM) > 7
			$g_i_ASMSize += 2
			$g_s_ASMCode &= 'EB(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 4) & ')'
		Case StringLeft($a_s_ASM, 4) = 'jae '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '73(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 4) & ')'
		Case StringLeft($a_s_ASM, 3) = 'jz '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '74(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 3) & ')'
		Case StringLeft($a_s_ASM, 4) = 'jnz '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '75(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 4) & ')'
		Case StringLeft($a_s_ASM, 4) = 'jbe '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '76(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 4) & ')'
		Case StringLeft($a_s_ASM, 3) = 'ja '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '77(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 3) & ')'
		Case StringLeft($a_s_ASM, 3) = 'jl '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '7C(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 3) & ')'
		Case StringLeft($a_s_ASM, 4) = 'jge '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '7D(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 4) & ')'
		Case StringLeft($a_s_ASM, 4) = 'jle '
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '7E(' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 4) & ')'
		Case StringRegExp($a_s_ASM, 'call dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'FF15[' & StringMid($a_s_ASM, 12, StringLen($a_s_ASM) - 12) & ']'
		Case StringLeft($a_s_ASM, 5) = 'call ' And StringLen($a_s_ASM) > 8
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'E8{' & StringMid($a_s_ASM, 6, StringLen($a_s_ASM) - 5) & '}'
		Case StringRegExp($a_s_ASM, 'fstp dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'D91D[' & StringMid($a_s_ASM, 12, StringLen($a_s_ASM) - 12) & ']'
		Case StringRegExp($a_s_ASM, 'retn [0-9A-Fa-f]+')
			Local $l_i_Value = StringRegExpReplace($a_s_ASM, 'retn ([0-9A-Fa-f]+)h', '$1')
			$l_i_Value = Dec($l_i_Value)
			$g_i_ASMSize += 3
			$g_s_ASMCode &= 'C2' & Utils_SwapEndian(Hex($l_i_Value, 4))
		Case StringRegExp($a_s_ASM, 'retn [-[:xdigit:]]{1,4}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 6)
			$g_i_ASMSize += 3
			$g_s_ASMCode &= 'C2' & Utils_SwapEndian(Hex(Number($l_i_Value), 4))
		Case StringRegExp($a_s_ASM, 'cmp ebx,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '81FB[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'cmp edx,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '81FA[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'cmp eax,[0-9A-Fa-f]+\z')
			Local $l_i_Value = Dec(StringMid($a_s_ASM, 9))
			If $l_i_Value <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '83F8' & Hex($l_i_Value, 2)
			Else
				$g_i_ASMSize += 5
				$g_s_ASMCode &= '3D' & Utils_SwapEndian(Hex($l_i_Value, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'cmp eax,[-[:xdigit:]]{1,2}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 9)
			If StringLen($l_i_Value) <= 2 Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '83F8' & Hex(Number($l_i_Value), 2)
			Else
				$g_i_ASMSize += 5
				$g_s_ASMCode &= '3D' & Assembler_ASMNumber($l_i_Value)
			EndIf
		Case StringRegExp($a_s_ASM, 'cmp ebx,[0-9A-Fa-f]+\z')
			Local $l_i_Value = Dec(StringMid($a_s_ASM, 9))
			If $l_i_Value <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '83FB' & Hex($l_i_Value, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '81FB' & Utils_SwapEndian(Hex($l_i_Value, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'cmp ebx,[-[:xdigit:]]{1,2}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 9)
			$g_i_ASMSize += 3
			$g_s_ASMCode &= '83FB' & Hex(Number($l_i_Value), 2)
		Case StringRegExp($a_s_ASM, 'cmp ecx,[-[:xdigit:]]{1,2}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 9)
			$g_i_ASMSize += 3
			$g_s_ASMCode &= '83F9' & Hex(Number($l_i_Value), 2)
		Case StringRegExp($a_s_ASM, 'cmp edx,[-[:xdigit:]]{1,2}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 9)
			$g_i_ASMSize += 3
			$g_s_ASMCode &= '83FA' & Hex(Number($l_i_Value), 2)
		Case StringRegExp($a_s_ASM, 'cmp ebx,dword\[[a-z,A-Z]{4,}\]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '3B1D[' & StringMid($a_s_ASM, 15, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'cmp dword[[][a-z,A-Z]{4,}[]],[-[:xdigit:]]')
			$l_v_Buffer = StringInStr($a_s_ASM, ',')
			$l_v_Buffer = Assembler_ASMNumber(StringMid($a_s_ASM, $l_v_Buffer + 1), True)
			If @extended Then
				$g_i_ASMSize += 7
				$g_s_ASMCode &= '833D[' & StringMid($a_s_ASM, 11, StringInStr($a_s_ASM, ',') - 12) & ']' & $l_v_Buffer
			Else
				$g_i_ASMSize += 10
				$g_s_ASMCode &= '813D[' & StringMid($a_s_ASM, 11, StringInStr($a_s_ASM, ',') - 12) & ']' & $l_v_Buffer
			EndIf
		Case StringRegExp($a_s_ASM, 'cmp ecx,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '81F9[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'cmp eax,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 5
			$g_s_ASMCode &= '3D[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringLeft($a_s_ASM, 8) = 'cmp ecx,' And StringLen($a_s_ASM) > 10
			Local $l_s_OpCode = '81F9' & StringMid($a_s_ASM, 9)
			$g_i_ASMSize += 0.5 * StringLen($l_s_OpCode)
			$g_s_ASMCode &= $l_s_OpCode
		Case StringRegExp($a_s_ASM, 'add ebx,dword\[[a-zA-Z_][a-zA-Z0-9_]*\]')
		   Local $l_s_Label = StringRegExpReplace($a_s_ASM, 'add ebx,dword\[([a-zA-Z_][a-zA-Z0-9_]*)\]', '$1')
		   $g_i_ASMSize += 6
		   $g_s_ASMCode &= '031D[' & $l_s_Label & ']'
		Case StringRegExp($a_s_ASM, 'add eax,dword\[[a-zA-Z_][a-zA-Z0-9_]*\]')
		   Local $l_s_Label = StringRegExpReplace($a_s_ASM, 'add eax,dword\[([a-zA-Z_][a-zA-Z0-9_]*)\]', '$1')
		   $g_i_ASMSize += 5
		   $g_s_ASMCode &= '0305[' & $l_s_Label & ']'
		Case StringRegExp($a_s_ASM, 'add eax,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 5
			$g_s_ASMCode &= '05[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'inc dword\[eax\+[0-9A-Fa-f]+h\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[eax\+([0-9A-Fa-f]+)h\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF40' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF80' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[esi\+0x[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[esi\+0x([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF46' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF86' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[ebx\+[0-9A-Fa-f]+h\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[ebx\+([0-9A-Fa-f]+)h\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF43' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF83' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[ecx\+[0-9A-Fa-f]+h\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[ecx\+([0-9A-Fa-f]+)h\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF41' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF81' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[edx\+[0-9A-Fa-f]+h\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[edx\+([0-9A-Fa-f]+)h\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF42' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF82' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[esi\+[0-9A-Fa-f]+h\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[esi\+([0-9A-Fa-f]+)h\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF46' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF86' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[edi\+[0-9A-Fa-f]+h\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[edi\+([0-9A-Fa-f]+)h\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF47' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF87' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[ebp\+[0-9A-Fa-f]+h\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[ebp\+([0-9A-Fa-f]+)h\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF45' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF85' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[esp\+[0-9A-Fa-f]+h\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[esp\+([0-9A-Fa-f]+)h\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 4
				$g_s_ASMCode &= 'FF4424' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 7
				$g_s_ASMCode &= 'FF8424' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[esi\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'inc dword\[esi\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= 'FF46' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'FF86' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'inc dword\[[a-zA-Z_][a-zA-Z0-9_]*\]')
			Local $l_s_Label = StringRegExpReplace($a_s_ASM, 'inc dword\[([a-zA-Z_][a-zA-Z0-9_]*)\]', '$1')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'FF05[' & $l_s_Label & ']'
		Case StringRegExp($a_s_ASM, 'dec dword\[[a-zA-Z_][a-zA-Z0-9_]*\]')
			Local $l_s_Label = StringRegExpReplace($a_s_ASM, 'dec dword\[([a-zA-Z_][a-zA-Z0-9_]*)\]', '$1')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'FF0D[' & $l_s_Label & ']'
		Case StringRegExp($a_s_ASM, 'and ebx,[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 9)
			If StringLen($l_i_Value) <= 2 And Dec($l_i_Value) <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '83E3' & Hex(Dec($l_i_Value), 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '81E3' & Assembler_ASMNumber($l_i_Value)
			EndIf
		Case StringRegExp($a_s_ASM, 'and edx,[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 9)
			If StringLen($l_i_Value) <= 2 And Dec($l_i_Value) <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '83E2' & Hex(Dec($l_i_Value), 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '81E2' & Assembler_ASMNumber($l_i_Value)
			EndIf
		Case StringRegExp($a_s_ASM, 'and ecx,[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 9)
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '81E1' & Assembler_ASMNumber($l_i_Value)
		Case StringRegExp($a_s_ASM, 'and eax,[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 9)
			$g_i_ASMSize += 5
			$g_s_ASMCode &= '25' & Assembler_ASMNumber($l_i_Value)
		Case StringRegExp($a_s_ASM, 'or eax,[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 8)
			$g_i_ASMSize += 5
			$g_s_ASMCode &= '0D' & Assembler_ASMNumber($l_i_Value)
		Case StringRegExp($a_s_ASM, 'push dword\[eax\+[0-9A-Fa-f]+\]')
            Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'push dword\[eax\+([0-9A-Fa-f]+)\]', '$1')
            $l_i_Offset = Dec($l_i_Offset)
            If $l_i_Offset <= 0x7F Then
                $g_i_ASMSize += 3
                $g_s_ASMCode &= 'FF70' & Hex($l_i_Offset, 2)
            Else
                $g_i_ASMSize += 6
                $g_s_ASMCode &= 'FFB0' & Utils_SwapEndian(Hex($l_i_Offset, 8))
            EndIf
		Case StringRegExp($a_s_ASM, 'push dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'FF35[' & StringMid($a_s_ASM, 12, StringLen($a_s_ASM) - 12) & ']'
		Case StringRegExp($a_s_ASM, 'push [a-z,A-Z]{4,}\z')
			$g_i_ASMSize += 5
			$g_s_ASMCode &= '68[' & StringMid($a_s_ASM, 6, StringLen($a_s_ASM) - 5) & ']'
		Case StringRegExp($a_s_ASM, 'push [-[:xdigit:]]{1,8}\z')
			$l_v_Buffer = Assembler_ASMNumber(StringMid($a_s_ASM, 6), True)
			If @extended Then
				$g_i_ASMSize += 2
				$g_s_ASMCode &= '6A' & $l_v_Buffer
			Else
				$g_i_ASMSize += 5
				$g_s_ASMCode &= '68' & $l_v_Buffer
			EndIf
		Case StringRegExp($a_s_ASM, 'lea eax,dword[[]ecx[*]8[+][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 7
			$g_s_ASMCode &= '8D04CD[' & StringMid($a_s_ASM, 21, StringLen($a_s_ASM) - 21) & ']'
		Case StringRegExp($a_s_ASM, 'lea edi,dword\[edx\+[a-z,A-Z]{4,}\]')
			$g_i_ASMSize += 7
			$g_s_ASMCode &= '8D3C15[' & StringMid($a_s_ASM, 19, StringLen($a_s_ASM) - 19) & ']'
		Case StringRegExp($a_s_ASM, 'lea eax,dword[[]edx[*]4[+][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 7
			$g_s_ASMCode &= '8D0495[' & StringMid($a_s_ASM, 21, StringLen($a_s_ASM) - 21) & ']'
		Case StringRegExp($a_s_ASM, 'mov eax,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov eax,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$l_i_Offset = StringReplace($l_i_Offset, "h", "")
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 4
				$g_s_ASMCode &= '8B4424' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 7
				$g_s_ASMCode &= '8B8424' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov ebx,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov ebx,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$l_i_Offset = StringReplace($l_i_Offset, "h", "")
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 4
				$g_s_ASMCode &= '8B5C24' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 7
				$g_s_ASMCode &= '8B9C24' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov ecx,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov ecx,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$l_i_Offset = StringReplace($l_i_Offset, "h", "")
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 4
				$g_s_ASMCode &= '8B4C24' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 7
				$g_s_ASMCode &= '8B8C24' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov edx,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov edx,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$l_i_Offset = StringReplace($l_i_Offset, "h", "")
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 4
				$g_s_ASMCode &= '8B5424' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 7
				$g_s_ASMCode &= '8B9424' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov esi,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov esi,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$l_i_Offset = StringReplace($l_i_Offset, "h", "")
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 4
				$g_s_ASMCode &= '8B7424' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 7
				$g_s_ASMCode &= '8BB424' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov edi,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov edi,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$l_i_Offset = StringReplace($l_i_Offset, "h", "")
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 4
				$g_s_ASMCode &= '8B7C24' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 7
				$g_s_ASMCode &= '8BBC24' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov ebp,dword\[esp\+[0-9A-Fa-f]+h?\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov ebp,dword\[esp\+([0-9A-Fa-f]+)h?\]', '$1')
			$l_i_Offset = StringReplace($l_i_Offset, "h", "")
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 4
				$g_s_ASMCode &= '8B6C24' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 7
				$g_s_ASMCode &= '8BAC24' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\],0x[0-9A-Fa-f]+\z')
			Local $l_i_Value = StringMid($a_s_ASM, 15)
			$l_i_Value = StringReplace($l_i_Value, "0x", "")
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'C700' & Utils_SwapEndian(Hex(Dec("0x" & $l_i_Value), 8))
		Case StringLeft($a_s_ASM, 17) = 'mov edx,dword[esi]'
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '8B16'
		Case StringLeft($a_s_ASM, 17) = 'mov edx,dword[edi]'
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '8B17'
		Case StringLeft($a_s_ASM, 17) = 'mov eax,dword[esi]'
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '8B06'
		Case StringLeft($a_s_ASM, 17) = 'mov eax,dword[edi]'
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '8B07'
		Case StringLeft($a_s_ASM, 17) = 'mov ecx,dword[esi]'
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '8B0E'
		Case StringLeft($a_s_ASM, 17) = 'mov ecx,dword[edi]'
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '8B0F'
		Case StringLeft($a_s_ASM, 17) = 'mov ebx,dword[esi]'
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '8B1E'
		Case StringLeft($a_s_ASM, 17) = 'mov ebx,dword[edi]'
			$g_i_ASMSize += 2
			$g_s_ASMCode &= '8B1F'
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],esi')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],esi', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8970' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '89B0' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov eax,dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'A1[' & StringMid($a_s_ASM, 15, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov ebx,dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '8B1D[' & StringMid($a_s_ASM, 15, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov ecx,dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '8B0D[' & StringMid($a_s_ASM, 15, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov edx,dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '8B15[' & StringMid($a_s_ASM, 15, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov esi,dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '8B35[' & StringMid($a_s_ASM, 15, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov edi,dword[[][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '8B3D[' & StringMid($a_s_ASM, 15, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov edi,dword\[esi\+[0-9A-Fa-f]+\]')
            Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov edi,dword\[esi\+([0-9A-Fa-f]+)\]', '$1')
            $l_i_Offset = Dec($l_i_Offset)
            If $l_i_Offset <= 0x7F Then
                $g_i_ASMSize += 3
                $g_s_ASMCode &= '8B7E' & Hex($l_i_Offset, 2)
            Else
                $g_i_ASMSize += 6
                $g_s_ASMCode &= '8BBE' & Utils_SwapEndian(Hex($l_i_Offset, 8))
            EndIf
		Case StringRegExp($a_s_ASM, 'mov eax,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'B8[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'mov ebx,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'BB[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'mov ecx,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'B9[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'mov esi,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'BE[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'mov edi,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'BF[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'mov edx,[a-z,A-Z]{4,}') And StringInStr($a_s_ASM, ',dword') = 0
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'BA[' & StringRight($a_s_ASM, StringLen($a_s_ASM) - 8) & ']'
		Case StringRegExp($a_s_ASM, 'mov dword[[][a-z,A-Z]{4,}[]],ecx')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '890D[' & StringMid($a_s_ASM, 11, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov dword[[][a-z,A-Z]{4,}[]],edx')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '8915[' & StringMid($a_s_ASM, 11, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov dword[[][a-z,A-Z]{4,}[]],eax')
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'A3[' & StringMid($a_s_ASM, 11, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov dword[[][a-z,A-Z]{4,}[]],esi')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '8935[' & StringMid($a_s_ASM, 11, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov dword[[][a-z,A-Z]{4,}[]],ebx')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '891D[' & StringMid($a_s_ASM, 11, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov dword[[][a-z,A-Z]{4,}[]],edi')
			$g_i_ASMSize += 6
			$g_s_ASMCode &= '893D[' & StringMid($a_s_ASM, 11, StringLen($a_s_ASM) - 15) & ']'
		Case StringRegExp($a_s_ASM, 'mov eax,dword[[]ecx[*]4[+][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 7
			$g_s_ASMCode &= '8B048D[' & StringMid($a_s_ASM, 21, StringLen($a_s_ASM) - 21) & ']'
		Case StringRegExp($a_s_ASM, 'mov ecx,dword[[]ecx[*]4[+][a-z,A-Z]{4,}[]]')
			$g_i_ASMSize += 7
			$g_s_ASMCode &= '8B0C8D[' & StringMid($a_s_ASM, 21, StringLen($a_s_ASM) - 21) & ']'
		Case StringRegExp($a_s_ASM, 'mov word\[[a-z,A-Z]{4,}\],[-[:xdigit:]]{1,4}\z')
			$l_v_Buffer = StringInStr($a_s_ASM, ',')
			$g_i_ASMSize += 9
			$g_s_ASMCode &= '66C705[' & StringMid($a_s_ASM, 10, $l_v_Buffer - 11) & ']' & StringLeft(Assembler_ASMNumber(StringMid($a_s_ASM, $l_v_Buffer + 1)), 4)
		Case StringRegExp($a_s_ASM, 'mov dword\[[a-z,A-Z]{4,}\],[-[:xdigit:]]{1,8}\z')
			$l_v_Buffer = StringInStr($a_s_ASM, ',')
			$g_i_ASMSize += 10
			$g_s_ASMCode &= 'C705[' & StringMid($a_s_ASM, 11, $l_v_Buffer - 12) & ']' & Assembler_ASMNumber(StringMid($a_s_ASM, $l_v_Buffer + 1))
		Case StringRegExp($a_s_ASM, 'mov eax,[-[:xdigit:]]{1,8}\z')
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'B8' & Assembler_ASMNumber(StringMid($a_s_ASM, 9))
		Case StringRegExp($a_s_ASM, 'mov ebx,[-[:xdigit:]]{1,8}\z')
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'BB' & Assembler_ASMNumber(StringMid($a_s_ASM, 9))
		Case StringRegExp($a_s_ASM, 'mov ecx,[-[:xdigit:]]{1,8}\z')
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'B9' & Assembler_ASMNumber(StringMid($a_s_ASM, 9))
		Case StringRegExp($a_s_ASM, 'mov edx,[-[:xdigit:]]{1,8}\z')
			$g_i_ASMSize += 5
			$g_s_ASMCode &= 'BA' & Assembler_ASMNumber(StringMid($a_s_ASM, 9))
		Case StringRegExp($a_s_ASM, 'mov ecx,dword\[eax\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov ecx,dword\[eax\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B48' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8B88' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov ecx,dword\[ecx\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov ecx,dword\[ecx\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B49' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8B89' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov ecx,dword\[esi\+[0-9A-Fa-f]+\]')
            Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov ecx,dword\[esi\+([0-9A-Fa-f]+)\]', '$1')
            $l_i_Offset = Dec($l_i_Offset)
            If $l_i_Offset <= 0x7F Then
                $g_i_ASMSize += 3
                $g_s_ASMCode &= '8B4E' & Hex($l_i_Offset, 2)
            Else
                $g_i_ASMSize += 6
                $g_s_ASMCode &= '8B8E' & Utils_SwapEndian(Hex($l_i_Offset, 8))
            EndIf
		Case StringRegExp($a_s_ASM, 'mov edx,dword\[eax\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov edx,dword\[eax\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B50' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8B90' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov eax,dword\[ecx\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov eax,dword\[ecx\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B41' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8B81' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov edx,dword\[ecx\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov edx,dword\[ecx\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B51' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8B91' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov esi,dword\[ebp\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov esi,dword\[ebp\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B75' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8BB5' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov edi,dword\[ebp\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov edi,dword\[ebp\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B7D' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8BBD' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov ebx,dword\[ebp\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov ebx,dword\[ebp\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B5D' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8B9D' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov edx,dword\[ebp\+[0-9A-Fa-f]+\]')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov edx,dword\[ebp\+([0-9A-Fa-f]+)\]', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8B55' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8B95' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],0')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],0', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 7
				$g_s_ASMCode &= 'C740' & Hex($l_i_Offset, 2) & '00000000'
			Else
				$g_i_ASMSize += 10
				$g_s_ASMCode &= 'C780' & Utils_SwapEndian(Hex($l_i_Offset, 8)) & '00000000'
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[ebx\+[0-9A-Fa-f]+\],0')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[ebx\+([0-9A-Fa-f]+)\],0', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 7
				$g_s_ASMCode &= 'C743' & Hex($l_i_Offset, 2) & '00000000'
			Else
				$g_i_ASMSize += 10
				$g_s_ASMCode &= 'C783' & Utils_SwapEndian(Hex($l_i_Offset, 8)) & '00000000'
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[ecx\+[0-9A-Fa-f]+\],0')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[ecx\+([0-9A-Fa-f]+)\],0', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 7
				$g_s_ASMCode &= 'C741' & Hex($l_i_Offset, 2) & '00000000'
			Else
				$g_i_ASMSize += 10
				$g_s_ASMCode &= 'C781' & Utils_SwapEndian(Hex($l_i_Offset, 8)) & '00000000'
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[edx\+[0-9A-Fa-f]+\],0')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[edx\+([0-9A-Fa-f]+)\],0', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 7
				$g_s_ASMCode &= 'C742' & Hex($l_i_Offset, 2) & '00000000'
			Else
				$g_i_ASMSize += 10
				$g_s_ASMCode &= 'C782' & Utils_SwapEndian(Hex($l_i_Offset, 8)) & '00000000'
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\],[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 15)
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'C700' & Assembler_ASMNumber($l_i_Value)
		Case StringRegExp($a_s_ASM, 'mov dword\[ebx\],[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 15)
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'C703' & Assembler_ASMNumber($l_i_Value)
		Case StringRegExp($a_s_ASM, 'mov dword\[ecx\],[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 15)
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'C701' & Assembler_ASMNumber($l_i_Value)
		Case StringRegExp($a_s_ASM, 'mov dword\[edx\],[-[:xdigit:]]{1,8}\z')
			Local $l_i_Value = StringMid($a_s_ASM, 15)
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'C702' & Assembler_ASMNumber($l_i_Value)
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\],[0-9]\z')
			Local $l_i_Value = StringMid($a_s_ASM, 15)
			$g_i_ASMSize += 6
			$g_s_ASMCode &= 'C700' & Utils_SwapEndian(Hex(Number($l_i_Value), 8))
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\],\d+\z')
			Local $l_i_Value = Number(StringMid($a_s_ASM, 15))
			If $l_i_Value <= 127 Then
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'C700' & Utils_SwapEndian(Hex($l_i_Value, 8))
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= 'C700' & Assembler_ASMNumber($l_i_Value)
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],eax')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],eax', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8940' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8980' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],ebx')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],ebx', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8958' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8998' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],ecx')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],ecx', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8948' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8988' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],edx')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],edx', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8950' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '8990' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],esi')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],esi', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8970' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '89B0' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],edi')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],edi', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8978' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '89B8' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],ebp')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],ebp', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8968' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '89A8' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, 'mov dword\[eax\+[0-9A-Fa-f]+\],esp')
			Local $l_i_Offset = StringRegExpReplace($a_s_ASM, 'mov dword\[eax\+([0-9A-Fa-f]+)\],esp', '$1')
			$l_i_Offset = Dec($l_i_Offset)
			If $l_i_Offset <= 0x7F Then
				$g_i_ASMSize += 3
				$g_s_ASMCode &= '8960' & Hex($l_i_Offset, 2)
			Else
				$g_i_ASMSize += 6
				$g_s_ASMCode &= '89A0' & Utils_SwapEndian(Hex($l_i_Offset, 8))
			EndIf
		Case StringRegExp($a_s_ASM, '^add\s+(eax|ecx|edx|ebx|esp|ebp|esi|edi)\s*,\s*(eax|ecx|edx|ebx|esp|ebp|esi|edi)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^add\s+(eax|ecx|edx|ebx|esp|ebp|esi|edi)\s*,\s*(eax|ecx|edx|ebx|esp|ebp|esi|edi)$', 1)
            Local $l_i_Dst = Assembler_Reg32Code($l_as_M[0])
            Local $l_i_Src = Assembler_Reg32Code($l_as_M[1])
            Local $l_i_ModRM = 0xC0 + ($l_i_Src * 8) + $l_i_Dst
            $g_i_ASMSize += 2
            $g_s_ASMCode &= '01' & Hex($l_i_ModRM, 2)
		Case StringRegExp($a_s_ASM, '^add\s+(ax|cx|dx|bx|sp|bp|si|di)\s*,\s*(ax|cx|dx|bx|sp|bp|si|di)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^add\s+(ax|cx|dx|bx|sp|bp|si|di)\s*,\s*(ax|cx|dx|bx|sp|bp|si|di)$', 1)
            Local $l_i_Dst = Assembler_Reg16Code($l_as_M[0])
            Local $l_i_Src = Assembler_Reg16Code($l_as_M[1])
            Local $l_i_ModRM = 0xC0 + ($l_i_Src * 8) + $l_i_Dst
            $g_i_ASMSize += 3
            $g_s_ASMCode &= '66' & '01' & Hex($l_i_ModRM, 2)
		Case StringRegExp($a_s_ASM, '^add\s+(al|cl|dl|bl|ah|ch|dh|bh)\s*,\s*(al|cl|dl|bl|ah|ch|dh|bh)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^add\s+(al|cl|dl|bl|ah|ch|dh|bh)\s*,\s*(al|cl|dl|bl|ah|ch|dh|bh)$', 1)
            Local $l_i_Dst = Assembler_Reg8Code($l_as_M[0])
            Local $l_i_Src = Assembler_Reg8Code($l_as_M[1])
            Local $l_i_ModRM = 0xC0 + ($l_i_Src * 8) + $l_i_Dst
            $g_i_ASMSize += 2
            $g_s_ASMCode &= '00' & Hex($l_i_ModRM, 2)
		Case StringRegExp($a_s_ASM, '^add\s+(eax|ecx|edx|ebx|esp|ebp|esi|edi)\s*,\s*([0-9A-Fa-f]+)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^add\s+(eax|ecx|edx|ebx|esp|ebp|esi|edi)\s*,\s*([0-9A-Fa-f]+)$', 1)
            Local $l_i_Reg = Assembler_Reg32Code($l_as_M[0])
            Local $l_i_Imm = Dec($l_as_M[1])
            If $l_i_Imm <= 0x7F Then
                Local $l_i_ModRM = 0xC0 + $l_i_Reg
                $g_i_ASMSize += 3
                $g_s_ASMCode &= '83' & Hex($l_i_ModRM, 2) & Hex($l_i_Imm, 2)
            Else
                Local $l_i_ModRM = 0xC0 + $l_i_Reg
                $g_i_ASMSize += 6
                $g_s_ASMCode &= '81' & Hex($l_i_ModRM, 2) & Utils_SwapEndian(Hex($l_i_Imm, 8))
            EndIf
		Case StringRegExp($a_s_ASM, '^add\s+(ax|cx|dx|bx|sp|bp|si|di)\s*,\s*([0-9A-Fa-f]+)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^add\s+(ax|cx|dx|bx|sp|bp|si|di)\s*,\s*([0-9A-Fa-f]+)$', 1)
            Local $l_i_Reg = Assembler_Reg16Code($l_as_M[0])
            Local $l_i_Imm = Dec($l_as_M[1])
            If $l_i_Imm <= 0x7F Then
                Local $l_i_ModRM = 0xC0 + $l_i_Reg
                $g_i_ASMSize += 4
                $g_s_ASMCode &= '66' & '83' & Hex($l_i_ModRM, 2) & Hex($l_i_Imm, 2)
            Else
                Local $l_i_ModRM = 0xC0 + $l_i_Reg
                $g_i_ASMSize += 5
                $g_s_ASMCode &= '66' & '81' & Hex($l_i_ModRM, 2) & Utils_SwapEndian(Hex($l_i_Imm, 4))
            EndIf
		Case StringRegExp($a_s_ASM, '^add\s+(al|cl|dl|bl|ah|ch|dh|bh)\s*,\s*([0-9A-Fa-f]+)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^add\s+(al|cl|dl|bl|ah|ch|dh|bh)\s*,\s*([0-9A-Fa-f]+)$', 1)
            Local $l_i_Reg = Assembler_Reg8Code($l_as_M[0])
            Local $l_i_Imm = Dec($l_as_M[1])
            Local $l_i_ModRM = 0xC0 + $l_i_Reg
            $g_i_ASMSize += 3
            $g_s_ASMCode &= '80' & Hex($l_i_ModRM, 2) & Hex($l_i_Imm, 2)
        Case StringRegExp($a_s_ASM, '^sub\s+(eax|ecx|edx|ebx|esp|ebp|esi|edi)\s*,\s*(eax|ecx|edx|ebx|esp|ebp|esi|edi)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^sub\s+(eax|ecx|edx|ebx|esp|ebp|esi|edi)\s*,\s*(eax|ecx|edx|ebx|esp|ebp|esi|edi)$', 1)
            Local $l_i_Dst = Assembler_Reg32Code($l_as_M[0])
            Local $l_i_Src = Assembler_Reg32Code($l_as_M[1])
            Local $l_i_ModRM = 0xC0 + ($l_i_Src * 8) + $l_i_Dst
            $g_i_ASMSize += 2
            $g_s_ASMCode &= '29' & Hex($l_i_ModRM, 2)
        Case StringRegExp($a_s_ASM, '^sub\s+(ax|cx|dx|bx|sp|bp|si|di)\s*,\s*(ax|cx|dx|bx|sp|bp|si|di)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^sub\s+(ax|cx|dx|bx|sp|bp|si|di)\s*,\s*(ax|cx|dx|bx|sp|bp|si|di)$', 1)
            Local $l_i_Dst = Assembler_Reg16Code($l_as_M[0])
            Local $l_i_Src = Assembler_Reg16Code($l_as_M[1])
            Local $l_i_ModRM = 0xC0 + ($l_i_Src * 8) + $l_i_Dst
            $g_i_ASMSize += 3
            $g_s_ASMCode &= '66' & '29' & Hex($l_i_ModRM, 2)
        Case StringRegExp($a_s_ASM, '^sub\s+(al|cl|dl|bl|ah|ch|dh|bh)\s*,\s*(al|cl|dl|bl|ah|ch|dh|bh)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^sub\s+(al|cl|dl|bl|ah|ch|dh|bh)\s*,\s*(al|cl|dl|bl|ah|ch|dh|bh)$', 1)
            Local $l_i_Dst = Assembler_Reg8Code($l_as_M[0])
            Local $l_i_Src = Assembler_Reg8Code($l_as_M[1])
            Local $l_i_ModRM = 0xC0 + ($l_i_Src * 8) + $l_i_Dst
            $g_i_ASMSize += 2
            $g_s_ASMCode &= '28' & Hex($l_i_ModRM, 2)
        Case StringRegExp($a_s_ASM, '^sub\s+(eax|ecx|edx|ebx|esp|ebp|esi|edi)\s*,\s*([0-9A-Fa-f]+)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^sub\s+(eax|ecx|edx|ebx|esp|ebp|esi|edi)\s*,\s*([0-9A-Fa-f]+)$', 1)
            Local $l_i_Reg = Assembler_Reg32Code($l_as_M[0])
            Local $l_i_Imm = Dec($l_as_M[1])
            If $l_i_Imm <= 0x7F Then
                Local $l_i_ModRM = 0xC0 + (5 * 8) + $l_i_Reg
                $g_i_ASMSize += 3
                $g_s_ASMCode &= '83' & Hex($l_i_ModRM, 2) & Hex($l_i_Imm, 2)
            Else
                Local $l_i_ModRM = 0xC0 + (5 * 8) + $l_i_Reg
                $g_i_ASMSize += 6
                $g_s_ASMCode &= '81' & Hex($l_i_ModRM, 2) & Utils_SwapEndian(Hex($l_i_Imm, 8))
            EndIf
        Case StringRegExp($a_s_ASM, '^sub\s+(ax|cx|dx|bx|sp|bp|si|di)\s*,\s*([0-9A-Fa-f]+)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^sub\s+(ax|cx|dx|bx|sp|bp|si|di)\s*,\s*([0-9A-Fa-f]+)$', 1)
            Local $l_i_Reg = Assembler_Reg16Code($l_as_M[0])
            Local $l_i_Imm = Dec($l_as_M[1])
            If $l_i_Imm <= 0x7F Then
                Local $l_i_ModRM = 0xC0 + (5 * 8) + $l_i_Reg
                $g_i_ASMSize += 4
                $g_s_ASMCode &= '66' & '83' & Hex($l_i_ModRM, 2) & Hex($l_i_Imm, 2)
            Else
                Local $l_i_ModRM = 0xC0 + (5 * 8) + $l_i_Reg
                $g_i_ASMSize += 5
                $g_s_ASMCode &= '66' & '81' & Hex($l_i_ModRM, 2) & Utils_SwapEndian(Hex($l_i_Imm, 4))
            EndIf
        Case StringRegExp($a_s_ASM, '^sub\s+(al|cl|dl|bl|ah|ch|dh|bh)\s*,\s*([0-9A-Fa-f]+)$')
            Local $l_as_M = StringRegExp($a_s_ASM, '^sub\s+(al|cl|dl|bl|ah|ch|dh|bh)\s*,\s*([0-9A-Fa-f]+)$', 1)
            Local $l_i_Reg = Assembler_Reg8Code($l_as_M[0])
            Local $l_i_Imm = Dec($l_as_M[1])
            Local $l_i_ModRM = 0xC0 + (5 * 8) + $l_i_Reg
            $g_i_ASMSize += 3
            $g_s_ASMCode &= '80' & Hex($l_i_ModRM, 2) & Hex($l_i_Imm, 2)
		Case Else
			Local $l_s_OpCode
			Switch $a_s_ASM
				Case 'Flag_'
					$l_s_OpCode = '9090903434'
				Case 'clc'
					$l_s_OpCode = 'F8'
				Case 'retn'
					$l_s_OpCode = 'C3'
				Case 'nop'
					$l_s_OpCode = '90'
				Case 'pushad'
					$l_s_OpCode = '60'
				Case 'popad'
					$l_s_OpCode = '61'
				Case 'pushfd'
					$l_s_OpCode = '9C'
				Case 'popfd'
					$l_s_OpCode = '9D'
				Case 'pushf'
					$l_s_OpCode = '9C'
				Case 'popf'
					$l_s_OpCode = '9D'
				Case 'push eax'
					$l_s_OpCode = '50'
				Case 'push ebx'
					$l_s_OpCode = '53'
				Case 'push ecx'
					$l_s_OpCode = '51'
				Case 'push edx'
					$l_s_OpCode = '52'
				Case 'push ebp'
					$l_s_OpCode = '55'
				Case 'push esi'
					$l_s_OpCode = '56'
				Case 'push edi'
					$l_s_OpCode = '57'
				Case 'push dword[ebp+8]'
					$l_s_OpCode = 'FF7508'
				Case 'fld st(0),dword[ebp+8]'
					$l_s_OpCode = 'D94508'
				Case 'repe movsb'
					$l_s_OpCode = 'F3A4'
				Case 'jmp ebx'
					$l_s_OpCode = 'FFE3'
				Case 'pop eax'
					$l_s_OpCode = '58'
				Case 'pop ebx'
					$l_s_OpCode = '5B'
				Case 'pop edx'
					$l_s_OpCode = '5A'
				Case 'pop ecx'
					$l_s_OpCode = '59'
				Case 'pop esi'
					$l_s_OpCode = '5E'
				Case 'pop ebp'
					$l_s_OpCode = '5D'
				Case 'pop edi'
					$l_s_OpCode = '5F'
				Case 'inc eax'
					$l_s_OpCode = '40'
				Case 'inc ecx'
					$l_s_OpCode = '41'
				Case 'inc ebx'
					$l_s_OpCode = '43'
				Case 'inc edx'
					$l_s_OpCode = '42'
				Case 'dec edx'
					$l_s_OpCode = '4A'
				Case 'dec ecx'
					$l_s_OpCode = '49'
				Case 'test eax,eax'
					$l_s_OpCode = '85C0'
				Case 'test ax,ax'
					$l_s_OpCode = '6685C0'
				Case 'test ebx,ebx'
					$l_s_OpCode = '85DB'
				Case 'test ecx,ecx'
					$l_s_OpCode = '85C9'
				Case 'test dx,dx'
					$l_s_OpCode = '6685D2'
				Case 'test al,al'
					$l_s_OpCode = '84C0'
				Case 'test esi,esi'
					$l_s_OpCode = '85F6'
				Case 'test al,1'
					$l_s_OpCode = 'A801'
				Case 'test edx,edx'
					$l_s_OpCode = '85D2'
				Case 'test ebx,40001'
					$l_s_OpCode = 'F7C301000400'
				Case 'test ebx,1'
					$l_s_OpCode = 'F7C301000000'
				Case 'test ebx,40000'
				   $l_s_OpCode = 'F7C300000400'
				Case 'test ebx,40001'
				   $l_s_OpCode = 'F7C301000400'
				Case 'test eax,1DA'
					$l_s_OpCode = 'A9DA010000'
				Case 'xor eax,eax'
					$l_s_OpCode = '33C0'
				Case 'xor ecx,ecx'
					$l_s_OpCode = '33C9'
				Case 'xor edx,edx'
					$l_s_OpCode = '33D2'
				Case 'xor ebx,ebx'
					$l_s_OpCode = '33DB'
				Case 'lea eax,dword[eax+18]'
					$l_s_OpCode = '8D4018'
				Case 'lea ecx,dword[eax+4]'
					$l_s_OpCode = '8D4804'
				Case 'lea ecx,dword[eax+C]'
					$l_s_OpCode = '8D480C'
				Case 'lea ecx,dword[eax+10]'
					$l_s_OpCode = '8D4810'
				Case 'lea eax,dword[eax+4]'
					$l_s_OpCode = '8D4004'
				Case 'lea edx,dword[eax]'
					$l_s_OpCode = '8D10'
				Case 'lea edx,dword[eax+4]'
					$l_s_OpCode = '8D5004'
				Case 'lea edx,dword[eax+8]'
					$l_s_OpCode = '8D5008'
				Case 'lea ecx,dword[eax+180]'
					$l_s_OpCode = '8D8880010000'
				Case 'lea edi,dword[edx+ebx]'
					$l_s_OpCode = '8D3C1A'
				Case 'lea edi,dword[edx+8]'
					$l_s_OpCode = '8D7A08'
				Case 'lea esi,dword[esi+ebx*4]'
					$l_s_OpCode = '8D349E'
				Case 'lea ecx,dword[ecx+ecx*2]'
					$l_s_OpCode = '8D0C49'
				Case 'lea ecx,dword[ebx+ecx*4]'
					$l_s_OpCode = '8D0C8B'
				Case 'lea ecx,dword[ecx+18]'
					$l_s_OpCode = '8D4918'
				Case 'lea ecx,dword[ebx+18]'
					$l_s_OpCode = '8D4B18'
				Case 'lea esi,dword[eax+4]'
					$l_s_OpCode = '8D7004'
				Case 'lea esi,dword[eax+8]'
					$l_s_OpCode = '8D7008'
				Case 'shl eax,4'
					$l_s_OpCode = 'C1E004'
				Case 'shl eax,8'
					$l_s_OpCode = 'C1E008'
				Case 'shl eax,6'
					$l_s_OpCode = 'C1E006'
				Case 'shl eax,7'
					$l_s_OpCode = 'C1E007'
				Case 'shl eax,9'
					$l_s_OpCode = 'C1E009'
				Case 'shl ebx,8'
					$l_s_OpCode = 'C1E308'
				Case 'shl edx,16'
					$l_s_OpCode = 'C1E210'
				Case 'shl ebx,16'
					$l_s_OpCode = 'C1E310'
				Case 'shl esi,8'
					$l_s_OpCode = 'C1E608'
				Case 'or eax,esi'
					$l_s_OpCode = '0BC6'
				Case 'or eax,edi'
					$l_s_OpCode = '0BC7'
				Case 'or ecx,ebx'
					$l_s_OpCode = '0BCB'
				Case 'or eax,ebx'
					$l_s_OpCode = '0BC3'
				Case 'and ecx,0xFFFF'
					$l_s_OpCode = '81E1FFFF0000'
				Case 'and eax,0xFFFF'
					$l_s_OpCode = '25FFFF0000'
				Case 'and eax,0xF'
					$l_s_OpCode = '83E00F'
				Case 'and eax,0xFF'
					$l_s_OpCode = '25FF000000'
				Case 'and eax,0xFFFF'
					$l_s_OpCode = '25FFFF0000'
				Case 'and ebx,0xF'
					$l_s_OpCode = '83E30F'
				Case 'and ecx,0xF'
					$l_s_OpCode = '83E10F'
				Case 'and edx,0xF'
					$l_s_OpCode = '83E20F'
				Case 'imul ebx,ebx,7C'
					$l_s_OpCode = '6BDB7C'
				Case 'imul eax,eax,7C'
					$l_s_OpCode = '6BC07C'
				Case 'cmp ecx,4'
					$l_s_OpCode = '83F904'
				Case 'cmp ecx,32'
					$l_s_OpCode = '83F932'
				Case 'cmp ecx,3C'
					$l_s_OpCode = '83F93C'
				Case 'cmp eax,2'
					$l_s_OpCode = '83F802'
				Case 'cmp eax,0'
					$l_s_OpCode = '83F800'
				Case 'cmp eax,B'
					$l_s_OpCode = '83F80B'
				Case 'cmp eax,200'
					$l_s_OpCode = '3D00020000'
				Case 'cmp word[edx],0'
					$l_s_OpCode = '66833A00'
				Case 'cmp eax,ebx'
					$l_s_OpCode = '3BC3'
				Case 'cmp eax,ecx'
					$l_s_OpCode = '3BC1'
				Case 'cmp edx,esi'
					$l_s_OpCode = '3BD6'
				Case 'cmp ecx,1050000'
					$l_s_OpCode = '81F900000501'
				Case 'cmp eax,-1'
					$l_s_OpCode = '83F8FF'
				Case 'cmp al,ah'
					$l_s_OpCode = '3AC4'
				Case 'cmp eax,1'
					$l_s_OpCode = '83F801'
				Case 'cmp ebx,edi'
					$l_s_OpCode = '3BDF'
				Case 'cmp edx,ecx'
					$l_s_OpCode = '39CA'
				Case 'cmp eax,dword[esi+9C]'
					$l_s_OpCode = '3B869C000000'
				Case 'cmp al,f'
					$l_s_OpCode = '3C0F'
				Case 'cmp ah,00'
					$l_s_OpCode = '80FC00'
				Case 'cmp bl,AA'
					$l_s_OpCode = '80FBAA'
				Case 'cmp bl,B9'
					$l_s_OpCode = '80FBB9'
				Case 'cmp al,BA'
					$l_s_OpCode = '3CBA'
				Case 'cmp ebx,esi'
					$l_s_OpCode = '3BDE'
				Case 'cmp eax,1DA'
					$l_s_OpCode = '3DDA010000'
				Case 'mov ebx,dword[eax]'
					$l_s_OpCode = '8B18'
				Case 'mov ebx,dword[ecx]'
					$l_s_OpCode = '8B19'
				Case 'mov ecx,dword[ebx+ecx]'
					$l_s_OpCode = '8B0C0B'
				Case 'mov ecx,[ecx]'
					$l_s_OpCode = '8B09'
				Case 'mov ax,word[esi]'
					$l_s_OpCode = '668B06'
					Case 'mov word[edi],ax'
					$l_s_OpCode = '668907'
				Case 'mov word[esi],ax'
					$l_s_OpCode = '668906'
				Case 'mov dword[eax],0'
					$l_s_OpCode = 'C70000000000'
				Case 'mov edi,edx'
					$l_s_OpCode = '8BFA'
				Case 'mov ecx,esi'
					$l_s_OpCode = '8BCE'
				Case 'mov ecx,edi'
					$l_s_OpCode = '8BCF'
				Case 'mov ecx,esp'
					$l_s_OpCode = '8BCC'
				Case 'mov edx,eax'
					$l_s_OpCode = '8BD0'
				Case 'mov edx,ecx'
					$l_s_OpCode = '8BD1'
				Case 'mov ebp,esp'
					$l_s_OpCode = '8BEC'
				Case 'mov ecx,edx'
					$l_s_OpCode = '8BCA'
				Case 'mov eax,ecx'
					$l_s_OpCode = '8BC1'
				Case 'mov eax,esp'
					$l_s_OpCode = '8BC4'
				Case 'mov eax,[ebp+10]'
					$l_s_OpCode = '8B4510'
				Case 'mov eax,dword[ebp+10]'
					$l_s_OpCode = '8B4510'
				Case 'mov esi,[ebp+C]'
					$l_s_OpCode = '8B750C'
				Case 'mov esi,[ebp+0C]'
					$l_s_OpCode = '8B750C'
				Case 'mov esi,dword[ebp+C]'
					$l_s_OpCode = '8B750C'
				Case 'mov esi,dword[ebp+0C]'
					$l_s_OpCode = '8B750C'
				Case 'mov ecx,dword[ebp+8]'
					$l_s_OpCode = '8B4D08'
				Case 'mov ecx,dword[esp+1F4]'
					$l_s_OpCode = '8B8C24F4010000'
				Case 'mov esi,dword[esp+14]'
					$l_s_OpCode = '8B742414'
				Case 'mov ecx,dword[edi+4]'
					$l_s_OpCode = '8B4F04'
				Case 'mov ecx,dword[edi+8]'
					$l_s_OpCode = '8B4F08'
				Case 'mov eax,dword[edi+4]'
					$l_s_OpCode = '8B4704'
				Case 'mov dword[eax+4],ecx'
					$l_s_OpCode = '894804'
				Case 'mov dword[eax+8],ebx'
					$l_s_OpCode = '895808'
				Case 'mov dword[eax+8],ecx'
					$l_s_OpCode = '894808'
				Case 'mov dword[eax+C],ecx'
					$l_s_OpCode = '89480C'
				Case 'mov dword[esi+10],eax'
					$l_s_OpCode = '894610'
				Case 'mov ecx,dword[edi]'
					$l_s_OpCode = '8B0F'
				Case 'mov dword[eax],ecx'
					$l_s_OpCode = '8908'
				Case 'mov dword[eax],ebx'
					$l_s_OpCode = '8918'
				Case 'mov dword[edi],eax'
					$l_s_OpCode = '8907'
				Case 'mov edx,dword[eax+4]'
					$l_s_OpCode = '8B5004'
				Case 'mov edx,dword[eax+8]'
					$l_s_OpCode = '8B5008'
				Case 'mov edx,dword[eax+c]'
					$l_s_OpCode = '8B500C'
				Case 'mov edx,dword[esi+1c]'
					$l_s_OpCode = '8B561C'
				Case 'mov ecx,dword[eax+4]'
					$l_s_OpCode = '8B4804'
				Case 'mov esi,dword[eax+4]'
					$l_s_OpCode = '8B7004'
				Case 'mov esp,dword[eax+4]'
					$l_s_OpCode = '8B6004'
				Case 'mov ecx,dword[eax+8]'
					$l_s_OpCode = '8B4808'
				Case 'mov eax,dword[eax+8]'
					$l_s_OpCode = '8B4008'
				Case 'mov eax,dword[eax+C]'
					$l_s_OpCode = '8B400C'
				Case 'mov ebx,dword[eax+4]'
					$l_s_OpCode = '8B5804'
				Case 'mov ebx,dword[eax+8]'
					$l_s_OpCode = '8B5808'
				Case 'mov ebx,dword[eax+C]'
					$l_s_OpCode = '8B580C'
				Case 'mov ebx,dword[ecx+148]'
					$l_s_OpCode = '8B9948010000'
				Case 'mov ecx,dword[ebx+13C]'
					$l_s_OpCode = '8B9B3C010000'
				Case 'mov ebx,dword[ebx+F0]'
					$l_s_OpCode = '8B9BF0000000'
				Case 'mov ecx,dword[eax+C]'
					$l_s_OpCode = '8B480C'
				Case 'mov ecx,dword[eax+10]'
					$l_s_OpCode = '8B4810'
				Case 'mov eax,dword[eax+4]'
					$l_s_OpCode = '8B4004'
				Case 'mov esp,ebp'
					$l_s_OpCode = '8BE5'
				Case 'mov edi,eax'
					$l_s_OpCode = '8BF8'
				Case 'mov dx,word[ecx]'
					$l_s_OpCode = '668B11'
				Case 'mov dx,word[edx]'
					$l_s_OpCode = '668B12'
				Case 'mov word[eax],dx'
					$l_s_OpCode = '668910'
				Case 'mov eax,dword[esi+8]'
					$l_s_OpCode = '8B4608'
				Case 'mov ecx,dword[eax]'
					$l_s_OpCode = '8B08'
				Case 'mov ebx,edi'
					$l_s_OpCode = '8BDF'
				Case 'mov ebx,eax'
					$l_s_OpCode = '8BD8'
				Case 'mov eax,edi'
					$l_s_OpCode = '8BC7'
				Case 'mov al,byte[ebx]'
					$l_s_OpCode = '8A03'
				Case 'mov eax,dword[ecx]'
					$l_s_OpCode = '8B01'
				Case 'mov ebx,dword[ecx+14]'
					$l_s_OpCode = '8B5914'
				Case 'mov eax,dword[ebx+c]'
					$l_s_OpCode = '8B430C'
				Case 'mov ecx,eax'
					$l_s_OpCode = '8BC8'
				Case 'mov al,byte[ecx]'
					$l_s_OpCode = '8A01'
				Case 'mov ebx,dword[edx]'
					$l_s_OpCode = '8B1A'
				Case 'mov ah,byte[edi]'
					$l_s_OpCode = '8A27'
				Case 'mov dword[edx],0'
					$l_s_OpCode = 'C70200000000'
				Case 'mov dword[ebx],ecx'
					$l_s_OpCode = '890B'
				Case 'mov edi,dword[edx+4]'
					$l_s_OpCode = '8B7A04'
				Case 'mov edi,dword[eax+4]'
					$l_s_OpCode = '8B7804'
				Case 'mov ecx,dword[E1D684]'
					$l_s_OpCode = '8B0D84D6E100'
				Case 'mov dword[edx-0x70],ecx'
					$l_s_OpCode = '894A90'
				Case 'mov ecx,dword[edx+0x1C]'
					$l_s_OpCode = '8B4A1C'
				Case 'mov dword[edx+0x54],ecx'
					$l_s_OpCode = '894A54'
				Case 'mov ecx,dword[edx+4]'
					$l_s_OpCode = '8B4A04'
				Case 'mov dword[edx-0x14],ecx'
					$l_s_OpCode = '894AEC'
				Case 'mov dword[edx],ebx'
					$l_s_OpCode = '891A'
				Case 'mov dword[edi],ecx'
					$l_s_OpCode = '890F'
				Case 'mov dword[edx],-1'
					$l_s_OpCode = 'C702FFFFFFFF'
				Case 'mov eax,dword[ebp+37c]'
					$l_s_OpCode = '8B857C030000'
				Case 'mov eax,dword[ebp+338]'
					$l_s_OpCode = '8B8538030000'
				Case 'mov ecx,dword[ebx+250]'
					$l_s_OpCode = '8B8B50020000'
				Case 'mov ecx,dword[ebx+194]'
					$l_s_OpCode = '8B8B94010000'
				Case 'mov ecx,dword[ebx+18]'
					$l_s_OpCode = '8B5918'
				Case 'mov ecx,dword[ebx+40]'
					$l_s_OpCode = '8B5940'
				Case 'mov ebx,dword[ecx+10]'
					$l_s_OpCode = '8B5910'
				Case 'mov ebx,dword[ecx+18]'
					$l_s_OpCode = '8B5918'
				Case 'mov ebx,dword[ecx+4c]'
					$l_s_OpCode = '8B594C'
				Case 'mov ecx,dword[ebx]'
					$l_s_OpCode = '8B0B'
				Case 'mov edx,esp'
					$l_s_OpCode = '8BD4'
				Case 'mov ecx,dword[ebx+170]'
					$l_s_OpCode = '8B8B70010000'
				Case 'mov ebx,dword[ecx+20]'
					$l_s_OpCode = '8B5920'
				Case 'mov ecx,dword[ecx]'
					$l_s_OpCode = '8B09'
				Case 'mov eax,dword[ecx+40]'
					$l_s_OpCode = '8B4140'
				Case 'mov ecx,dword[ecx+4]'
					$l_s_OpCode = '8B4904'
				Case 'mov ecx,dword[ecx+8]'
					$l_s_OpCode = '8B4908'
				Case 'mov ecx,dword[ecx+34]'
					$l_s_OpCode = '8B4934'
				Case 'mov ecx,dword[ecx+C]'
					$l_s_OpCode = '8B490C'
				Case 'mov ecx,dword[ecx+10]'
					$l_s_OpCode = '8B4910'
				Case 'mov ecx,dword[ecx+18]'
					$l_s_OpCode = '8B4918'
				Case 'mov ecx,dword[ecx+20]'
					$l_s_OpCode = '8B4920'
				Case 'mov ecx,dword[ecx+4c]'
					$l_s_OpCode = '8B494C'
				Case 'mov ecx,dword[ecx+50]'
					$l_s_OpCode = '8B4950'
				Case 'mov ecx,dword[ecx+148]'
					$l_s_OpCode = '8B8948010000'
				Case 'mov ecx,dword[ecx+170]'
					$l_s_OpCode = '8B8970010000'
				Case 'mov ecx,dword[ecx+194]'
					$l_s_OpCode = '8B8994010000'
				Case 'mov ecx,dword[ecx+250]'
					$l_s_OpCode = '8B8950020000'
				Case 'mov ecx,dword[ecx+134]'
					$l_s_OpCode = '8B8934010000'
				Case 'mov ecx,dword[ecx+13C]'
					$l_s_OpCode = '8B893C010000'
				Case 'mov al,byte[ecx+4f]'
					$l_s_OpCode = '8A414F'
				Case 'mov al,byte[ecx+3f]'
					$l_s_OpCode = '8A413F'
				Case 'mov esi,dword[esi]'
					$l_s_OpCode = '8B36'
				Case 'mov eax,dword[ebp+8]'
					$l_s_OpCode = '8B4508'
				Case 'mov eax,dword[ecx+8]'
					$l_s_OpCode = '8B4108'
				Case 'mov eax,[eax+2C]'
					$l_s_OpCode = '8B402C'
				Case 'mov eax,[eax+680]'
					$l_s_OpCode = '8B8080060000'
				Case 'mov esi,eax'
					$l_s_OpCode = '8BF0'
				Case 'mov edx,dword[ecx]'
					$l_s_OpCode = '8B11'
				Case 'mov eax,dword[ecx]'
					$l_s_OpCode = '8B01'
				Case 'mov dword[eax],edx'
					$l_s_OpCode = '8910'
				Case 'mov dword[eax],F'
					$l_s_OpCode = 'C7000F000000'
				Case 'mov ebx,[ebx+0]'
					$l_s_OpCode = '8B1B'
				Case 'mov ebx,[ebx+AC]'
					$l_s_OpCode = '8B9BAC000000'
				Case 'mov ebx,[ebx+C]'
					$l_s_OpCode = '8B5B0C'
				Case 'mov eax,dword[ebx+28]'
					$l_s_OpCode = '8B4328'
				Case 'mov eax,[eax]'
					$l_s_OpCode = '8B00'
				Case 'mov eax,[eax+4]'
					$l_s_OpCode = '8B4004'
				Case 'mov ebx,dword[ebp+C]'
					$l_s_OpCode = '8B5D0C'
				Case 'mov ecx,dword[ecx+edx]'
					$l_s_OpCode = '8B0C11'
				Case 'mov dword[eax],edi'
					$l_s_OpCode = '8938'
				Case 'mov [eax+8],ecx'
					$l_s_OpCode = '894808'
				Case 'mov [eax+C],ecx'
					$l_s_OpCode = '89480C'
				Case 'mov ebx,dword[ecx-C]'
					$l_s_OpCode = '8B59F4'
				Case 'mov [eax+C],ebx'
					$l_s_OpCode = '89580C'
				Case 'mov ecx,[eax+8]'
					$l_s_OpCode = '8B4808'
				Case 'mov ebx,dword[ebx+18]'
					$l_s_OpCode = '8B5B18'
				Case 'mov ecx,dword[ecx+0xF4]'
					$l_s_OpCode = '8B89F4000000'
				Case 'mov eax,edx'
					$l_s_OpCode = '8BC2'
				Case 'mov esi,edx'
					$l_s_OpCode = '8BF2'
				Case 'mov bl,byte[eax]'
					$l_s_OpCode = '8A18'
				Case 'mov bl,byte[ecx+5]'
					$l_s_OpCode = '8A5905'
				Case 'mov ebx,dword[ecx+1]'
					$l_s_OpCode = '8B5901'
				Case 'mov ebx,dword[ecx+6]'
					$l_s_OpCode = '8B5906'
				Case 'mov edi,dword[esi]'
					$l_s_OpCode = '8B3E'
				Case 'mov ecx,dword[eax+14]'
					$l_s_OpCode = '8B4814'
				Case 'mov edx,dword[eax+14]'
					$l_s_OpCode = '8B5014'
				Case 'mov edx,dword[eax+18]'
					$l_s_OpCode = '8B5018'
				Case 'mov edi,ecx'
					$l_s_OpCode = '8BF9'
				Case 'mov edi,ebx'
					$l_s_OpCode = '8BFB'
				Case 'mov esi,ecx'
					$l_s_OpCode = '8BF1'
				Case 'mov esi,ebx'
					$l_s_OpCode = '8BF3'
				Case 'mov edi,esi'
					$l_s_OpCode = '8BFE'
				Case 'mov ebx,ecx'
					$l_s_OpCode = '8BD9'
				Case 'mov eax,ebx'
					$l_s_OpCode = '8BC3'
				Case 'mov eax,esi'
					$l_s_OpCode = '8BC6'
				Case 'mov ecx,ebx'
					$l_s_OpCode = '8BCB'
				Case 'mov ebx,edx'
					$l_s_OpCode = '8BDA'
				Case 'mov esi,edx'
					$l_s_OpCode = '8BF2'
				Case 'mov ebx,esi'
					$l_s_OpCode = '8BDE'
				Case 'mov edx,ebx'
					$l_s_OpCode = '8BD3'
				Case 'mov edx,esi'
					$l_s_OpCode = '8BD6'
				Case 'mov edx,edi'
					$l_s_OpCode = '8BD7'
				Case 'mov ecx,edx'
					$l_s_OpCode = '8BCA'
				Case 'mov esi,edi'
					$l_s_OpCode = '8BF7'
				Case 'mov ebp,eax'
					$l_s_OpCode = '8BE8'
				Case 'mov ebp,ebx'
					$l_s_OpCode = '8BEB'
				Case 'mov ebp,ecx'
					$l_s_OpCode = '8BE9'
				Case 'mov ebp,edx'
					$l_s_OpCode = '8BEA'
				Case 'mov esp,eax'
					$l_s_OpCode = '8BE0'
				Case 'mov esp,ecx'
					$l_s_OpCode = '8BE1'
				Case 'mov esp,edx'
					$l_s_OpCode = '8BE2'
				Case 'mov esp,ebx'
					$l_s_OpCode = '8BE3'
				Case 'mov esi,dword[ebp+8]'
					$l_s_OpCode = '8B7508'
				Case 'mov esi,dword[ebp+C]'
					$l_s_OpCode = '8B750C'
				Case 'mov esi,dword[ebp+10]'
					$l_s_OpCode = '8B7510'
				Case 'mov edi,dword[ebp+8]'
					$l_s_OpCode = '8B7D08'
				Case 'mov edi,dword[ebp+C]'
					$l_s_OpCode = '8B7D0C'
				Case 'mov ebx,dword[ebp+8]'
					$l_s_OpCode = '8B5D08'
				Case 'mov edx,dword[ebp+8]'
					$l_s_OpCode = '8B5508'
				Case 'mov edx,dword[ebp+C]'
					$l_s_OpCode = '8B550C'
				Case 'mov dword[eax+C],0'
					$l_s_OpCode = 'C7400C00000000'
				Case 'mov dword[eax+4],edx'
					$l_s_OpCode = '895004'
				Case 'mov dword[eax+4],ebx'
					$l_s_OpCode = '895804'
				Case 'mov dword[eax+8],edx'
					$l_s_OpCode = '895008'
				Case 'mov dword[eax+C],edx'
					$l_s_OpCode = '89500C'
				Case 'mov dword[eax+C],0'
					$l_s_OpCode = 'C7400C00000000'
				Case 'mov dword[eax+C],1'
					$l_s_OpCode = 'C7400C01000000'
				Case 'mov edx,dword[ebp+C]'
					$l_s_OpCode = '8B550C'
				Case 'mov ebx,dword[ebp+10]'
					$l_s_OpCode = '8B5D10'
				Case 'mov edx,dword[ebp+10]'
					$l_s_OpCode = '8B5510'
				Case 'mov esi,ebp'
					$l_s_OpCode = '8BF5'
				Case 'mov ecx,dword[esi]'
					$l_s_OpCode = '8B0E'
				Case 'mov ecx,dword[ebp+C]'
					$l_s_OpCode = '8B4D0C'
				Case 'mov ecx,dword[ebp+10]'
					$l_s_OpCode = '8B4D10'
				Case 'mov edx,dword[esi]'
					$l_s_OpCode = '8B16'
				Case 'mov edx,dword[edi]'
					$l_s_OpCode = '8B17'
				Case 'mov eax,dword[esi]'
					$l_s_OpCode = '8B06'
				Case 'mov eax,dword[edi]'
					$l_s_OpCode = '8B07'
				Case 'mov ebx,dword[esi]'
					$l_s_OpCode = '8B1E'
				Case 'mov ebx,dword[edi]'
					$l_s_OpCode = '8B1F'
				Case 'mov eax,dword[eax]'
					$l_s_OpCode = '8B00'
				Case 'mov eax,dword[eax+18]'
					$l_s_OpCode = '8B4018'
				Case 'mov eax,dword[eax+44]'
					$l_s_OpCode = '8B4044'
				Case 'mov eax,dword[eax+198]'
					$l_s_OpCode = '8B8098010000'
				Case 'mov ebx,dword[ebx+10]'
					$l_s_OpCode = '8B5B10'
				Case 'mov ebx,dword[eax+10]'
					$l_s_OpCode = '8B5810'
				Case 'mov ebx,dword[eax+19C]'
					$l_s_OpCode = '8B989C010000'
				Case 'movzx ecx,di'
					$l_s_OpCode = '0FB7CF'
				Case 'movzx eax,di'
					$l_s_OpCode = '0FB7C7'
				Case 'movzx ecx,cx'
					$l_s_OpCode = '0FB7C9'
				; SellItem
				Case 'mov ecx,[eax]'
					$l_s_OpCode = '8B08'
				; Crafting
				Case 'lea edi,[eax+C]'
					$l_s_OpCode = '8D780C'
				; Collector Exchange
				Case 'lea ecx,[edx+4]'
					$l_s_OpCode = '8D4A04'
				Case 'lea eax,[edx+C]'
					$l_s_OpCode = '8D420C'
				Case 'mov ebx,[edx+8]'
					$l_s_OpCode = '8B5A08'
				Case 'lea ecx,[edx+ebx*4+C]'
					$l_s_OpCode = '8D4C9A0C'
				; LoadFinished
				Case 'push dword[edi+1C]'
					$l_s_OpCode = 'FF771C'
				; Action
				Case 'cmp dword[eax+C],0'
					$l_s_OpCode = '83780C00'

				Case Else
					Log_Error('Could not assemble: ' & $a_s_ASM, 'ASM', $g_h_EditText)
					MsgBox(0x0, 'ASM', 'Could not assemble: ' & $a_s_ASM)
					Exit
			EndSwitch
			$g_i_ASMSize += 0.5 * StringLen($l_s_OpCode)
			$g_s_ASMCode &= $l_s_OpCode
	EndSelect
EndFunc

Func Assembler_CompleteASMCode()
	Local $l_b_InExpression = False
	Local $l_s_Expression
	Local $l_s_TempASM = $g_s_ASMCode
	Local $l_i_CurrentOffset = Dec(Hex($g_p_ASMMemory)) + $g_i_ASMCodeOffset
	Local $l_s_Token
	For $l_i_Idx = 1 To $g_amx2_Labels[0][0]
		If StringLeft($g_amx2_Labels[$l_i_Idx][0], 6) = 'Label_' Then
			$g_amx2_Labels[$l_i_Idx][0] = StringTrimLeft($g_amx2_Labels[$l_i_Idx][0], 6)
			$g_amx2_Labels[$l_i_Idx][1] = $g_p_ASMMemory + $g_amx2_Labels[$l_i_Idx][1]
		EndIf
	Next
	$g_s_ASMCode = ''
	For $l_i_Idx = 1 To StringLen($l_s_TempASM)
		$l_s_Token = StringMid($l_s_TempASM, $l_i_Idx, 1)
		Switch $l_s_Token
			Case '(', '[', '{'
				$l_b_InExpression = True
			Case ')'
				$g_s_ASMCode &= Hex(Memory_GetLabelInfo($l_s_Expression) - Int($l_i_CurrentOffset) - 1, 2)
				$l_i_CurrentOffset += 1
				$l_b_InExpression = False
				$l_s_Expression = ''
			Case ']'
				$g_s_ASMCode &= Utils_SwapEndian(Hex(Memory_GetLabelInfo($l_s_Expression), 8))
				$l_i_CurrentOffset += 4
				$l_b_InExpression = False
				$l_s_Expression = ''
			Case '}'
				$g_s_ASMCode &= Utils_SwapEndian(Hex(Memory_GetLabelInfo($l_s_Expression) - Int($l_i_CurrentOffset) - 4, 8))
				$l_i_CurrentOffset += 4
				$l_b_InExpression = False
				$l_s_Expression = ''
			Case Else
				If $l_b_InExpression Then
					$l_s_Expression &= $l_s_Token
				Else
					$g_s_ASMCode &= $l_s_Token
					$l_i_CurrentOffset += 0.5
				EndIf
		EndSwitch
	Next
EndFunc

;~ Func old_Assembler_ASMNumber($a_v_Number, $a_b_Small = False)
;~ 	If $a_v_Number >= 0 Then
;~ 		$a_v_Number = Dec($a_v_Number)
;~ 	EndIf
;~ 	If $a_b_Small And $a_v_Number <= 127 And $a_v_Number >= -128 Then
;~ 		Return SetExtended(1, Hex($a_v_Number, 2))
;~ 	Else
;~ 		Return SetExtended(0, Utils_SwapEndian(Hex($a_v_Number, 8)))
;~ 	EndIf
;~ EndFunc

Func Assembler_ASMNumber($a_v_Number, $a_b_Small = False)
    Local $l_i_Value

    If IsNumber($a_v_Number) Then
        $l_i_Value = $a_v_Number
    Else
        $l_i_Value = _ParseValue($a_v_Number)
    EndIf

    If $a_b_Small And $l_i_Value <= 127 And $l_i_Value >= -128 Then
        If $l_i_Value < 0 Then
            Return SetExtended(1, Hex(256 + $l_i_Value, 2))
        Else
            Return SetExtended(1, Hex($l_i_Value, 2))
        EndIf
    Else
        If $l_i_Value < 0 Then
            Return SetExtended(0, Utils_SwapEndian(Hex(0x100000000 + $l_i_Value, 8)))
        Else
            Return SetExtended(0, Utils_SwapEndian(Hex($l_i_Value, 8)))
        EndIf
    EndIf
EndFunc

Func Assembler_CreateScanProcedure($a_p_Start, $a_p_End)
    _('ScanProc:')
    _('pushad')
    _('mov ecx,' & Hex($a_p_Start, 8))
    _('mov esi,ScanProc')
    _('ScanLoop:')
    _('inc ecx')
    _('mov al,byte[ecx]')
    _('mov edx,' & $g_amx2_Patterns[1][0])

    _('ScanInnerLoop:')
    _('mov ebx,dword[edx]')
    _('cmp ebx,-1')
    _('jnz ScanContinue')
    _('add edx,50')
    _('cmp edx,esi')
    _('jnz ScanInnerLoop')
    _('cmp ecx,' & Utils_SwapEndian(Hex($a_p_End, 8)))
    _('jnz ScanLoop')
    _('jmp ScanExit')

    _('ScanContinue:')
    _('lea edi,dword[edx+ebx]')
    _('add edi,C')
    _('mov ah,byte[edi]')
    _('cmp al,ah')
    _('jz ScanMatched')
    _('cmp ah,00')
    _('jz ScanMatched')
    _('mov dword[edx],0')
    _('add edx,50')
    _('cmp edx,esi')
    _('jnz ScanInnerLoop')
    _('cmp ecx,' & Utils_SwapEndian(Hex($a_p_End, 8)))
    _('jnz ScanLoop')
    _('jmp ScanExit')

    _('ScanMatched:')
    _('inc ebx')
    _('mov edi,dword[edx+4]')
    _('cmp ebx,edi')
    _('jz ScanFound')
    _('mov dword[edx],ebx')
    _('add edx,50')
    _('cmp edx,esi')
    _('jnz ScanInnerLoop')
    _('cmp ecx,' & Utils_SwapEndian(Hex($a_p_End, 8)))
    _('jnz ScanLoop')
    _('jmp ScanExit')

    _('ScanFound:')
    _('lea edi,dword[edx+8]')
    _('mov dword[edi],ecx')
    _('mov dword[edx],-1')
    _('add edx,50')
    _('cmp edx,esi')
    _('jnz ScanInnerLoop')
    _('cmp ecx,' & Utils_SwapEndian(Hex($a_p_End, 8)))
    _('jnz ScanLoop')

    _('ScanExit:')
    _('popad')
    _('retn')
EndFunc

Func Assembler_ModifyMemory()
	$g_i_ASMSize = 0
	$g_i_ASMCodeOffset= 0
	$g_s_ASMCode = ""

	Assembler_CreateData()
	Assembler_CreateMain()
	Assembler_CreateRenderingMod()
	Assembler_CreateLoadFinished()
	Assembler_CreateTradePartner()
	Assembler_CreateCommands()
	Assembler_CreateSkillCommands()
	Assembler_CreateFriendCommands()
	Assembler_CreateAttributeCommands()
	Assembler_CreateTrader()
	Assembler_CreateSellItemCommand()
	Assembler_CreateBuyItemCommand()
	Assembler_CreateRequestQuoteCommand()
	Assembler_CreateRequestQuoteSellCommand()
	Assembler_CreateTraderBuyCommand()
	Assembler_CreateTraderSellCommand()
	Assembler_CreateCraftItemCommand()
	Assembler_CreateCollectorExchangeCommand()
	Assembler_CreateSalvageCommand()
	Assembler_CreateItemCommands()
	Assembler_CreateAgentCommands()
	Assembler_CreateMapCommands()
	Assembler_CreatePropRayCommand()
	Assembler_CreateTradeSessionCommand()
	Assembler_CreateTradeCommands()
	Assembler_CreateUICommands()
	Assembler_CreatePartyCommands()
	Assembler_CreateEncStringCommands()
	If IsDeclared("g_b_Assembler") Then Extend_Assembler()

	Local $l_b_AllocCmd = False
	$g_p_GwAu3Cmd = Memory_Read($g_p_GwAu3Header + $GC_I_GWAU3_OFFSET_CMDPTR, "ptr")
	If $g_p_GwAu3Cmd = 0 Then
        Local $l_av_CmdAlloc = DllCall($g_h_Kernel32, "ptr", "VirtualAllocEx", _
            "handle", $g_h_GWProcess, _
            "ptr", 0, _
            "ulong_ptr", $g_i_ASMSize, _
            "dword", 0x1000, _
            "dword", 0x40)

        $g_p_GwAu3Cmd = $l_av_CmdAlloc[0]

        Memory_Write($g_p_GwAu3Header + $GC_I_GWAU3_OFFSET_CMDPTR, $g_p_GwAu3Cmd)

		$l_b_AllocCmd = True
	EndIf

	$g_p_ASMMemory = $g_p_GwAu3Cmd
	Assembler_CompleteASMCode()

	If $l_b_AllocCmd Or $g_b_DevMode Then
		Memory_WriteBinary($g_s_ASMCode, $g_p_ASMMemory + $g_i_ASMCodeOffset)
		Memory_Write(Memory_GetValue('QueuePtr'), Memory_GetValue('QueueBase'))
		If IsDeclared("g_b_Write") Then Extend_Write()

		Memory_WriteDetour('MainStart', 'MainProc')
		Memory_WriteDetour('TraderStart', 'TraderProc')
		Memory_WriteDetour('RenderingMod', 'RenderingModProc')
		Memory_WriteDetour('LoadFinishedStart', 'LoadFinishedProc')
		Memory_WriteDetour('TradePartnerStart', 'TradePartnerProc')
		If IsDeclared("g_b_AssemblerWriteDetour") Then Extend_AssemblerWriteDetour()
    EndIf
EndFunc

Func Assembler_CreateData()
	_('SavedIndex/4')
    _('QueueCounter/4')
    _('TraderQuoteID/4')
    _('TraderCostID/4')
    _('TraderCostValue/4')
    _('DisableRendering/4')
	_('MapIsLoaded/4')
	_('TradePartner/4')
	_('AgentCopyCount/4')
	_('InvCanIdentifyAllResult/4')
	_('InvIdentifyAllResult/4')
	_('InvCanDepositAllMaterialsResult/4')
	_('InvDepositAllMaterialsResult/4')
	_('PropRayResult/96')        ; GC_I_PROPRAY_MAX results of 12 bytes
	_('PropRayReady/4')          ; 0 = pending, 1 = results ready, 2 = skipped, no props
	_('TradeSessResult/4')       ; Return value of the trade session native
	_('TradeSessReady/4')        ; 0 = pending, 1 = value ready, 2 = skipped, no trade context

	; EncString decoding buffers
	_('DecodeReady/4')           ; Flag: 1 when decode is complete
	_('DecodeInputPtr/256')      ; Input: encoded wchar string (max 128 wchars)
	_('DecodeOutputPtr/2048')    ; Output: decoded wchar string (max 1024 wchars)

	If IsDeclared("g_b_AssemblerData") Then Extend_AssemblerData()

    _('QueueBase/' & 256 * Memory_GetValue('QueueSize'))
    _('AgentCopyBase/' & 0x1C0 * 256)
EndFunc

Func Assembler_CreateMain()
    _('MainProc:')
    _('pushad')
    _('pushfd')

    _('mov eax,dword[BasePointer]')
    _('test eax,eax')
    _('jz RegularFlow')
    _('mov eax,dword[eax]')
    _('test eax,eax')
    _('jz RegularFlow')
    _('mov eax,dword[eax+18]')
    _('test eax,eax')
    _('jz RegularFlow')
    _('mov eax,dword[eax+44]')
    _('test eax,eax')
    _('jz RegularFlow')
    _('mov ebx,dword[eax+19C]')
    _('test ebx,ebx')
    _('jz RegularFlow')
    _('mov eax,dword[eax+198]')
    _('cmp eax,0')
    _('je HandleCase')
    _('mov ebx,eax')
    _('imul ebx,ebx,7C')
    _('add ebx,dword[Environment]')
    _('test ebx,ebx')
    _('jz RegularFlow')
    _('mov ebx,dword[ebx+10]')
    _('test ebx,40001')
    _('jz RegularFlow')

    _('HandleCase:')
    _('mov eax,dword[QueueCounter]')
    _('mov ecx,eax')
    _('shl eax,8')
    _('add eax,QueueBase')
    _('mov ebx,dword[eax]')
    _('test ebx,ebx')
    _('jz MainExit')
    _('mov dword[eax],0')
    _('mov eax,ecx')
    _('inc eax')
    _('cmp eax,QueueSize')
    _('jnz SubSkipReset')
    _('xor eax,eax')
    _('SubSkipReset:')
    _('mov dword[QueueCounter],eax')
    _('jmp MainExit')

	_('RegularFlow:')
	_('mov eax,dword[QueueCounter]')
	_('mov ecx,eax')
	_('shl eax,8')
	_('add eax,QueueBase')
	_('mov ebx,dword[eax]')
	_('test ebx,ebx')
	_('jz MainExit')
	_('mov dword[SavedIndex],ecx')
	_('mov dword[eax],0')
	_('jmp ebx')

	_('CommandReturn:')
	_('mov ecx,dword[SavedIndex]')
    _('mov edx,dword[QueueCounter]')
	_('cmp edx,ecx')
	_('jnz MainExit')
	_('mov eax,ecx')
	_('inc eax')
	_('cmp eax,QueueSize')
	_('jnz MainSkipReset')
	_('xor eax,eax')
	_('MainSkipReset:')
	_('mov dword[QueueCounter],eax')

    _('MainExit:')
	_('popfd')
    _('popad')
    _('mov ebp,esp')
    _('fld st(0),dword[ebp+8]')
    _('ljmp MainReturn')
EndFunc

Func Assembler_CreateTrader()
	_('TraderProc:')
	_('push eax')
	_('mov eax,dword[ebx+28] -> 8b 43 28')
	_('mov eax,[eax] -> 8b 00')
	_('mov dword[TraderCostID],eax')
	_('mov eax,dword[ebx+28] -> 8b 43 28')
	_('mov eax,[eax+4] -> 8b 40 04')
	_('mov dword[TraderCostValue],eax')
	_('pop eax')
	_('mov ebx,dword[ebp+C] -> 8B 5D 0C')
	_('mov esi,eax')
	_('push eax')
	_('mov eax,dword[TraderQuoteID]')
	_('inc eax')
	_('cmp eax,200')
	_('jnz TraderSkipReset')
	_('xor eax,eax')
	_('TraderSkipReset:')
	_('mov dword[TraderQuoteID],eax')
	_('pop eax')
	_('ljmp TraderReturn')
EndFunc

Func Assembler_CreateRenderingMod()
	_('RenderingModProc:')
	_('add esp,4')
	_('cmp dword[DisableRendering],1')
	_('ljmp RenderingModReturn')
EndFunc

;~ Func Assembler_CreateRenderingMod_new()
;~     _('RenderingModProc:')
;~     _('add esp,8')
;~     _('cmp dword[DisableRendering],1')
;~     _('ljmp RenderingModReturn')
;~ EndFunc

Func Assembler_CreateLoadFinished()
    _('LoadFinishedProc:')
    _('mov dword[MapIsLoaded],1')
	_('push dword[edi+1C]')
	_('mov ecx,esi')
	_('ljmp LoadFinishedReturn')
EndFunc

Func Assembler_CreateTradePartner()
    _('TradePartnerProc:')
	_('push esi')
	_('mov esi,dword[ebp+C]')
	_('push esi')
	_('mov dword[TradePartner],esi')
	_('ljmp TradePartnerReturn')
EndFunc

Func Assembler_CreateCommands()
	_('CommandPacketSend:')
	_('lea edx,dword[eax+8]')
	_('push edx')
	_('mov ebx,dword[eax+4]')
	_('push ebx')
	_('mov eax,dword[PacketLocation]')
	_('push eax')
	_('call PacketSend')
	_('pop eax')
	_('pop ebx')
	_('pop edx')
	_('ljmp CommandReturn')

	_('CommandAction:')
	_('mov ecx,dword[ActionBase]')
	_('cmp dword[eax+C],0')
	_('jnz ActionType2')
	_('ActionType1:')
	_('mov ecx,dword[ecx+C]')
	_('jmp ActionCommon')
	_('ActionType2:')
	_('mov ecx,dword[ecx+4]')
	_('ActionCommon:')
	_('add ecx,A8')
	_('push 0')
	_('add eax,4')
	_('push eax')
	_('push dword[eax+4]')
	_('mov edx,0')
	_('call Action')
	_('ljmp CommandReturn')

	_('CommandSendChat:')
	_('lea edx,dword[eax+4]')
	_('push edx')
	_('mov ebx,11c')
	_('push ebx')
	_('mov eax,dword[PacketLocation]')
	_('push eax')
	_('call PacketSend')
	_('pop eax')
	_('pop ebx')
	_('pop edx')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreateSkillCommands()
	_('CommandUseSkill:')
	_('mov ecx,dword[eax+10]')
	_('push ecx')
	_('mov ebx,dword[eax+C]')
	_('push ebx')
	_('mov edx,dword[eax+8]')
	_('push edx')
	_('mov ecx,dword[eax+4]')
	_('push ecx')
	_('call UseSkill')
	_('add esp,10')
	_('ljmp CommandReturn')

	_('CommandUseHeroSkill:')
    _('mov ecx,dword[eax+8]')
    _('push ecx')
    _('mov ecx,dword[eax+c]')
    _('push ecx')
    _('mov ecx,dword[eax+4]')
    _('push ecx')
    _('call UseHeroSkill')
    _('add esp,C')
    _('ljmp CommandReturn')

	_('CommandCancelHeroSkill:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call CancelHeroSkill')
	_('add esp,8')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreateFriendCommands()
    _('CommandPlayerStatus:')
    _('mov eax,dword[eax+4]')
    _('push eax')
    _('call PlayerStatus')
    _('pop eax')
    _('ljmp CommandReturn')

    _('CommandAddFriend:')
    _('mov ecx,dword[eax+C]')
    _('push ecx')
    _('mov edx,dword[eax+8]')
    _('push edx')
    _('mov ecx,dword[eax+4]')
    _('push ecx')
    _('call AddFriend')
    _('add esp,C')
    _('ljmp CommandReturn')

    _('CommandRemoveFriend:')
    _('mov ecx,dword[eax+18]')
    _('push ecx')
    _('mov edx,dword[eax+14]')
    _('push edx')
    _('lea ecx,dword[eax+4]')
    _('push ecx')
    _('call RemoveFriend')
    _('add esp,C')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateAttributeCommands()
    _('CommandIncreaseAttribute:')
    _('mov edx,dword[eax+4]')
    _('push edx')
    _('mov ecx,dword[eax+8]')
    _('push ecx')
    _('call IncreaseAttribute')
    _('add esp,8')
    _('ljmp CommandReturn')

	_('CommandDecreaseAttribute:')
    _('mov edx,dword[eax+4]')
    _('push edx')
    _('mov ecx,dword[eax+8]')
    _('push ecx')
    _('call DecreaseAttribute')
    _('add esp,8')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateSellItemCommand()
    _('CommandSellItem:')
    _('push 0')
    _('push 0')
    _('push 0')
    _('push dword[eax+C]')
    _('add eax,4')
    _('mov ecx,[eax]')
    _('test ecx,ecx')
    _('jz SellItemAll')
    _('push eax')
    _('jmp SellItemContinue')
	_('SellItemAll:')
    _('push 0')
	_('SellItemContinue:')
    _('add eax,4')
    _('push eax')
    _('push 1')
    _('push 0')
    _('push B')
    _('call Transaction')
    _('add esp,24')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateBuyItemCommand()
    _('CommandBuyItem:')
    _('mov esi,eax')
    _('add esi,10')
    _('mov ecx,eax')
    _('add ecx,4')
    _('push ecx')
    _('mov edx,eax')
    _('add edx,8')
    _('push edx')
    _('push 1')
    _('push 0')
    _('push 0')
    _('push 0')
    _('push 0')
    _('mov eax,dword[eax+C]')
    _('push eax')
    _('push 1')
    _('call Transaction')
    _('add esp,24')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateCraftItemCommand()
	_('CommandCraftItem:')
	_('add eax,4')
	_('push eax')
	_('add eax,4')
	_('push eax')
	_('push 1')
	_('push 0')
	_('push 0')
	_('lea edi,[eax+C]')
	_('push edi')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('push 3')
	_('call Transaction')
	_('add esp,24')
	_('mov dword[TraderCostID],0')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreateCollectorExchangeCommand()
	_('CommandCollectorExchange:')
	_('mov edx,eax')
	_('push 0')
	_('lea ecx,[edx+4]')
	_('push ecx')
	_('push 1')
	_('push 0')
	_('lea eax,[edx+C]')
	_('push eax')
	_('mov ebx,[edx+8]')
	_('lea ecx,[edx+ebx*4+C]')
	_('push ecx')
	_('push ebx')
	_('push 0')
	_('push 2')
	_('call Transaction')
	_('add esp,24')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreateRequestQuoteCommand()
    _('CommandRequestQuote:')
    _('mov dword[TraderCostID],0')
    _('mov dword[TraderCostValue],0')
    _('mov esi,eax')
    _('add esi,4')
    _('push esi')
    _('push 1')
    _('push 0')
    _('push 0')
    _('push 0')
    _('push 0')
    _('push 0')
    _('push C')
    _('mov ecx,0')
    _('mov edx,2')
    _('call RequestQuote')
    _('add esp,20')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateRequestQuoteSellCommand()
    _('CommandRequestQuoteSell:')
    _('mov dword[TraderCostID],0')
    _('mov dword[TraderCostValue],0')
    _('push 0')
    _('push 0')
    _('push 0')
    _('add eax,4')
    _('push eax')
    _('push 1')
    _('push 0')
    _('push 0')
    _('push D')
    _('xor edx,edx')
    _('call RequestQuote')
    _('add esp,20')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateTraderBuyCommand()
    _('CommandTraderBuy:')
    _('push 0')
    _('push TraderCostID')
    _('push 1')
    _('push 0')
    _('push 0')
    _('push 0')
    _('push 0')
    _('mov edx,dword[TraderCostValue]')
    _('push edx')
    _('push C')
    _('mov ecx,C')
    _('call Transaction')
    _('add esp,24')
    _('mov dword[TraderCostID],0')
    _('mov dword[TraderCostValue],0')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateTraderSellCommand()
    _('CommandTraderSell:')
    _('push 0')
    _('push 0')
    _('push 0')
    _('push dword[TraderCostValue]')
    _('push 0')
    _('push TraderCostID')
    _('push 1')
    _('push 0')
    _('push D')
    _('mov ecx,d')
    _('xor edx,edx')
    _('call Transaction')
    _('add esp,24')
    _('mov dword[TraderCostID],0')
    _('mov dword[TraderCostValue],0')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateSalvageCommand()
    _('CommandSalvage:')
    _('mov ebx,SalvageGlobal')
    _('mov ecx,dword[eax+4]')
    _('mov dword[ebx],ecx')
    _('add ebx,4')
    _('mov ecx,dword[eax+8]')
    _('mov dword[ebx],ecx')
    _('mov ebx,dword[eax+4]')
    _('push ebx')
    _('mov ebx,dword[eax+8]')
    _('push ebx')
    _('mov ebx,dword[eax+c]')
    _('push ebx')
    _('call Salvage')
    _('add esp,C')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateItemCommands()
	_('CommandInvCanIdentifyAll:')
	_('call InvCanIdentifyAll')
	_('mov dword[InvCanIdentifyAllResult],eax')
	_('ljmp CommandReturn')

	_('CommandInvIdentifyAll:')
	_('call InvIdentifyAll')
	_('mov dword[InvIdentifyAllResult],eax')
	_('ljmp CommandReturn')

	_('CommandInvCanDepositAllMaterials:')
	_('call InvCanDepositAllMaterials')
	_('mov dword[InvCanDepositAllMaterialsResult],eax')
	_('ljmp CommandReturn')

	_('CommandInvDepositAllMaterials:')
	_('call InvDepositAllMaterials')
	_('mov dword[InvDepositAllMaterialsResult],eax')
	_('ljmp CommandReturn')

	_('CommandDropBundle:')
	_('call DropBundle')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreateAgentCommands()
	_('CommandChangeTarget:')
	_('xor edx,edx')
	_('push edx')
	_('mov eax,dword[eax+4]')
	_('push eax')
	_('call ChangeTarget')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandMakeAgentArray:')
	_('mov eax,dword[eax+4]')
	_('xor ebx,ebx')
	_('xor edx,edx')
	_('mov edi,AgentCopyBase')
	_('AgentCopyLoopStart:')
	_('inc ebx')
	_('cmp ebx,dword[MaxAgents]')
	_('jge AgentCopyLoopExit')
	_('mov esi,dword[AgentBase]')
	_('lea esi,dword[esi+ebx*4]')
	_('mov esi,dword[esi]')
	_('test esi,esi')
	_('jz AgentCopyLoopStart')
	_('cmp eax,0')
	_('jz CopyAgent')
	_('cmp eax,dword[esi+9C]')
	_('jnz AgentCopyLoopStart')
	_('CopyAgent:')
	_('mov ecx,1C0')
	_('clc')
	_('repe movsb')
	_('inc edx')
	_('jmp AgentCopyLoopStart')
	_('AgentCopyLoopExit:')
	_('mov dword[AgentCopyCount],edx')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreateMapCommands()
	_('CommandMove:')
	_('lea eax,dword[eax+4]')
	_('push eax')
	_('call Move')
	_('pop eax')
	_('ljmp CommandReturn')

    _('CommandRedirectMap:') ; Slade
    _('mov ecx,dword[eax+4]')
    _('mov edx,dword[eax+8]')
    _('push dword[eax+18]')
    _('push dword[eax+14]')
    _('push dword[eax+10]')
    _('push dword[eax+C]')
    _('push edx')
    _('push ecx')
    _('call RedirectMap')
    _('add esp,18')
    _('ljmp CommandReturn')
EndFunc

; Ray cast against the map props: count at slot+4, then rays of 28 bytes from slot+8.
Func Assembler_CreatePropRayCommand()
	_('CommandPropRay:')
	_('jmp PropRayStart')

	; The map can unload between enqueue and execution, and the native asserts on null props
	_('PropRaySkip:')
	_('mov dword[PropRayReady],2')
	_('ljmp CommandReturn')

	_('PropRayStart:')
	_('mov esi,eax')
	_('mov eax,dword[BasePointer]')
	_('test eax,eax')
	_('jz PropRaySkip')
	_('mov eax,dword[eax]')
	_('test eax,eax')
	_('jz PropRaySkip')
	_('mov eax,dword[eax+18]')
	_('test eax,eax')
	_('jz PropRaySkip')
	_('mov eax,dword[eax+14] -> 8B 40 14')
	_('test eax,eax')
	_('jz PropRaySkip')
	_('mov eax,dword[eax+7C] -> 8B 40 7C')
	_('test eax,eax')
	_('jz PropRaySkip')
	_('mov ebx,dword[eax+19C]')
	_('test ebx,ebx')
	_('jz PropRaySkip')

	; ebx holds the loop counter: the native preserves ebx, esi and edi, but not ecx or edx
	_('mov ebx,dword[esi+4] -> 8B 5E 04')
	_('test ebx,ebx')
	_('jz PropRaySkip')
	_('cmp ebx,8')
	_('ja PropRaySkip')

	_('push PropRayResult')
	_('pop edi')
	_('add esi,8')

	_('PropRayLoop:')
	_('lea eax,dword[edi+8] -> 8D 47 08')
	_('push eax')
	_('lea eax,dword[esi+18] -> 8D 46 18')
	_('push eax')
	_('lea eax,dword[esi+C] -> 8D 46 0C')
	_('push eax')
	_('push esi')
	_('call QueryPropIntersect')
	_('add esp,10')
	_('mov dword[edi],eax')
	_('mov eax,dword[esi+18] -> 8B 46 18')
	_('mov dword[edi+4],eax -> 89 47 04')
	_('add esi,1C')
	_('add edi,C')
	_('dec ebx -> 4B')
	_('jnz PropRayLoop')

	_('mov dword[PropRayReady],1')
	_('ljmp CommandReturn')
EndFunc

; Calls one TradeClient::Session* native: native at slot+4, first argument at +8, second at +C.
; The context is resolved here, not in AutoIt: it can be freed between enqueue and execution.
Func Assembler_CreateTradeSessionCommand()
	_('CommandTradeSession:')
	_('jmp TradeSessStart')

	_('TradeSessSkip:')
	_('mov dword[TradeSessReady],2')
	_('ljmp CommandReturn')

	_('TradeSessStart:')
	_('mov esi,eax')
	_('mov eax,dword[BasePointer]')
	_('test eax,eax')
	_('jz TradeSessSkip')
	_('mov eax,dword[eax]')
	_('test eax,eax')
	_('jz TradeSessSkip')
	_('mov eax,dword[eax+18]')
	_('test eax,eax')
	_('jz TradeSessSkip')
	_('mov eax,dword[eax+58] -> 8B 40 58')
	_('test eax,eax')
	_('jz TradeSessSkip')

	_('mov ebx,dword[esi+4] -> 8B 5E 04')
	_('test ebx,ebx')
	_('jz TradeSessSkip')

	; cdecl with the context first: three dwords are always pushed, the callee ignores the extras
	_('push dword[esi+C] -> FF 76 0C')
	_('push dword[esi+8] -> FF 76 08')
	_('push eax')
	_('call ebx -> FF D3')
	_('add esp,C')

	_('push TradeSessResult')
	_('pop edi')
	_('mov dword[edi],eax')
	_('mov dword[TradeSessReady],1')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreateTradeCommands()
	_('CommandTradeInitiate:')
	_('push 0')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
    _('call UIMessage')
    _('add esp,C')
    _('ljmp CommandReturn')

	_('CommandTradeCancel:')
	_('call TradeCancel')
	_('ljmp CommandReturn')

	_('CommandTradeAccept:')
	_('call TradeAccept')
	_('ljmp CommandReturn')

	_('CommandTradeSubmitOffer:')
	_('push dword[eax+4]')
	_('call TradeSubmitOffer')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandTradeOfferItem:')
	_('push dword[eax+8]')
    _('push dword[eax+4]')
    _('call TradeOfferItem')
    _('add esp,8')
    _('ljmp CommandReturn')
EndFunc

Func Assembler_CreateUICommands()
	_('CommandUIMsg:')
	_('push 0')
	_('mov edx,eax')
	_('add edx,8')
	_('push edx')
    _('push dword[eax+4]')
    _('call UIMessage')
    _('add esp,C')
    _('ljmp CommandReturn')

	_('CommandDialog:')
	_('push dword[eax+4]')
	_('call Dialog')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandInteract:')
	_('push dword[eax+4]')
	_('call Interact')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandAddNPC:')
	_('push dword[eax+4]')
	_('call AddNPC')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandAddHero:')
	_('push dword[eax+4]')
	_('call AddHero')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandKickNPC:')
	_('push dword[eax+4]')
	_('call KickNPC')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandKickHero:')
	_('push dword[eax+4]')
	_('call KickHero')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandLeaveGroup:')
	_('push dword[eax+4]')
	_('call LeaveGroup')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandSetDifficulty:')
	_('push dword[eax+4]')
	_('call SetDifficulty')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandEnterMission:')
	_('push dword[eax+4]')
	_('call EnterMission')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandFlagHero:')
	_('mov ecx,eax')
	_('add ecx,8')
	_('push ecx')
	_('mov eax,dword[eax+4]')
	_('push eax')
	_('call FlagHero')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandFlagAll:')
	_('mov ecx,eax')
	_('add ecx,4')
	_('push ecx')
	_('call FlagAll')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandSetHeroBehavior:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call SetHeroBehavior')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandDropHeroBundle:')
	_('push dword[eax+4]')
	_('call DropHeroBundle')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandLockHeroTarget:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call LockHeroTarget')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandToggleHeroSkillState:')
	_('push dword[eax+8]')
	_('push dword[eax+4]')
	_('call ToggleHeroSkillState')
	_('add esp,8')
	_('ljmp CommandReturn')

	_('CommandActiveQuest:')
	_('push dword[eax+4]')
	_('call ActiveQuest')
	_('add esp,4')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreatePartyCommands()
	_('CommandAddPlayer:')
	_('push dword[eax+4]')
	_('call AddPlayer')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandKickPlayer:')
	_('push dword[eax+4]')
	_('call KickPlayer')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandKickInvitedPlayer:')
	_('push dword[eax+4]')
	_('call KickInvitedPlayer')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandRejectInvitation:')
	_('push dword[eax+4]')
	_('call RejectInvitation')
	_('add esp,4')
	_('ljmp CommandReturn')

	_('CommandAcceptInvitation:')
	_('push dword[eax+4]')
	_('call AcceptInvitation')
	_('add esp,4')
	_('ljmp CommandReturn')
EndFunc

Func Assembler_CreateEncStringCommands()
	; Callback function for ValidateAsyncDecodeStr
	; Called by GW with: void __cdecl callback(void* param, wchar_t* decodedString)
	; param is at [esp+4], decodedString is at [esp+8]
	_('DecodeCallback:')
	_('push esi')
	_('push edi')
	_('push ecx')
	; Get source string pointer (decodedString)
	_('mov esi,dword[esp+14]')  ; [esp+8] + 12 bytes for pushed regs = [esp+14]
	; Get destination buffer
	_('mov edi,DecodeOutputPtr')
	; Copy string (max 1023 wchars + null)
	_('mov ecx,400')  ; 1024 wchars max (0x400)
	_('DecodeLoop:')
	_('lodsw -> 66 AD')           ; Load word from [esi] into ax, esi += 2
	_('stosw -> 66 AB')           ; Store word from ax to [edi], edi += 2
	_('test ax,ax')               ; Check if null terminator
	_('jz DecodeDone')
	_('dec ecx')
	_('jnz DecodeLoop')
	_('DecodeDone:')
	; Set ready flag
	_('mov dword[DecodeReady],1')
	_('pop ecx')
	_('pop edi')
	_('pop esi')
	_('retn 8')  ; stdcall: callee cleans up 2 params (8 bytes)

	; Command to decode an encoded string
	; eax points to command struct: [ptr command][wchar encoded_string[64]]
	_('CommandDecodeEncString:')
	; Reset ready flag
	_('mov dword[DecodeReady],0')
	; Clear output buffer first word (to detect no result)
	_('mov word[DecodeOutputPtr],0')
	; Copy encoded string from command to input buffer
	_('push esi')
	_('push edi')
	_('push ecx')
	_('lea esi,dword[eax+4]')     ; Source: command struct + 4 (skip ptr)
	_('mov edi,DecodeInputPtr')   ; Destination: input buffer
	_('mov ecx,40')               ; 64 dwords = 128 wchars = 256 bytes
	_('rep movsd -> F3 A5')       ; Copy
	_('pop ecx')
	_('pop edi')
	_('pop esi')
	; Push callback param (not used, pass 0)
	_('push 0')
	; Push callback function pointer
	_('push DecodeCallback')
	; Push encoded string pointer
	_('push DecodeInputPtr')
	; Call ValidateAsyncDecodeStr
	_('call ValidateAsyncDecodeStr')
	_('add esp,C')  ; Clean up 3 params (12 bytes)
	_('ljmp CommandReturn')
EndFunc