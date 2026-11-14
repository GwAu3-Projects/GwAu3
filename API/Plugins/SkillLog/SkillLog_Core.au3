#include-once

; SkillLog — GwAu3 port of Logic SetEvent (caster / melee skill activate).
; Scan → ASM ring buffer → PostMessage(0x503) → callback(caster, target, skill, activation).

Global $g_s_SkillActivate = ""
Global $g_s_SkillMeleeActivate = ""
Global $g_p_CasterSkillLogStart = 0
Global $g_p_MeleeSkillLogStart = 0
Global $g_h_SkillLogGUI = 0
Global $g_i_SkillLogHits = 0
; Detours stay installed; $g_b_SkillLogLive gates callbacks (Fight on/off without re-patch).
Global $g_b_SkillLogLive = False
Global $g_b_SkillLogDetoursOn = False

Global $g_d_SkillLogStruct = DllStructCreate("dword;dword;dword;float")
Global $g_p_SkillLogStruct = DllStructGetPtr($g_d_SkillLogStruct)

Global Const $GC_I_SKILLLOG_WM = 0x00000503
Global Const $GC_I_SKILLLOG_SIZE = 0x10
; PostMessage lparam tags which GW site fired (Logic used 1 for both — we split so we can test).
Global Const $GC_I_SKILLLOG_LP_CASTER = 0x1
Global Const $GC_I_SKILLLOG_LP_MELEE = 0x2
Global $g_i_SkillLogHitsCaster = 0
Global $g_i_SkillLogHitsMelee = 0

; Probe: AOB-collect candidates, rotate hook on each cast of $g_i_SkillLogProbeSkillID until HIT.
; Full Logic patterns (assert IDs often break across builds):
; Soft-assert IDs moved +0x23 on this client (0x50E→0x531, 0x4D0→0x4F3); gap still 0x3E.
; Landmark is AvApi soft_push; hook is match-47 (= Logic GetScannedAddress -46) at 8BECFF7508.
Global Const $GC_S_SKILLLOG_PAT_CASTER = "558BEC568B750885F675146831050000"
Global Const $GC_S_SKILLLOG_PAT_MELEE = "558BEC568B750885F6751468F3040000"
; Softer (drop assert dword / push imm) — option 1 ladder:
Global Const $GC_S_SKILLLOG_PAT_SOFT_PUSH = "558BEC568B750885F6751468" ; prologue + push opcode
Global Const $GC_S_SKILLLOG_PAT_SOFT = "558BEC568B750885F67514" ; prologue only
Global Const $GC_S_SKILLLOG_PAT_SOFT_MIN = "558BEC568B7508" ; very short
Global $g_i_SkillLogProbeMaxCand = 48 ; tester may raise; soft AOB can yield more
Global $g_b_SkillLogProbe = False
Global $g_b_SkillLogProbeLocked = False
Global $g_i_SkillLogProbeSkillID = 0 ; 0 = any self Skill; else only that ID advances
Global $g_s_SkillLogProbeWhich = "caster" ; "caster" | "melee"
Global $g_ai_SkillLogProbeCandidates[1] = [0]
Global $g_i_SkillLogProbeIndex = 0
Global $g_i_SkillLogProbeHitsAtArm = 0
Global $g_b_SkillLogProbeWasCasting = False
Global $g_p_SkillLogProbeArmed = 0
Global $g_b_SkillLogProbePendingAdvance = False ; set on garbage/fail; ArmAt next only on Overload cast-end
Global $g_i_SkillLogProbeFalseHits = 0
; Persist failed/locked probe addrs across bot runs (same GW .text base only — ASLR invalidates).
Global Const $GC_S_SKILLLOG_PROBE_INI = "SkillLog_probe.ini"

Func SkillLog_ProbeIniPath()
	Return @ScriptDir & "\" & $GC_S_SKILLLOG_PROBE_INI
EndFunc   ;==>SkillLog_ProbeIniPath

Func SkillLog_ProbeAddrKey($a_p)
	Return "0x" & Hex(Number($a_p), 8)
EndFunc   ;==>SkillLog_ProbeAddrKey

Func SkillLog_ProbeTextStart()
	Local $pStart = 0, $pEnd = 0
	Scanner_GetSection($GC_I_SECTION_TEXT, $pStart, $pEnd)
	Return Number($pStart)
EndFunc   ;==>SkillLog_ProbeTextStart

Func SkillLog_ProbeLoadSection($a_s_Which)
	Local $sIni = SkillLog_ProbeIniPath()
	Local $sSec = StringLower($a_s_Which)
	Local $iText = SkillLog_ProbeTextStart()
	Local $iSaved = Number(IniRead($sIni, $sSec, "textStart", "0"))
	If $iSaved <> 0 And $iSaved <> $iText Then
		Out("SkillLog probe ini: .text base changed (" & Ptr($iSaved) & " → " & Ptr($iText) & ") — clearing " & $sSec & " progress")
		IniDelete($sIni, $sSec)
	EndIf
	Local $m[]
	$m["textStart"] = $iText
	$m["failed"] = IniRead($sIni, $sSec, "failed", "")
	$m["locked"] = IniRead($sIni, $sSec, "locked", "")
	Return $m
EndFunc   ;==>SkillLog_ProbeLoadSection

Func SkillLog_ProbeFailedMap($a_s_FailedCsv)
	Local $m[]
	Local $a = StringSplit(StringStripWS($a_s_FailedCsv, 8), ",", 1)
	If $a[0] = 1 And $a[1] = "" Then Return $m
	For $i = 1 To $a[0]
		Local $k = StringStripWS($a[$i], 8)
		If $k <> "" Then $m[SkillLog_ProbeAddrKey(Number($k))] = 1
	Next
	Return $m
EndFunc   ;==>SkillLog_ProbeFailedMap

; $a_s_Reason: "no_hit" = Overload cast ended with no lock (trusted skip).
; "garbage" = hot/wrong site fired junk — skip too, but only after it was armed.
Func SkillLog_ProbeMarkFailed($a_s_Which, $a_p_Addr, $a_s_Reason = "no_hit")
	If SkillLog_IsBadHookPtr($a_p_Addr) Then Return
	Local $sIni = SkillLog_ProbeIniPath()
	Local $sSec = StringLower($a_s_Which)
	Local $mState = SkillLog_ProbeLoadSection($a_s_Which)
	Local $mFail = SkillLog_ProbeFailedMap($mState["failed"])
	Local $k = SkillLog_ProbeAddrKey($a_p_Addr)
	If MapExists($mFail, $k) Then Return
	Local $sCsv = StringStripWS($mState["failed"], 8)
	If $sCsv = "" Then
		$sCsv = $k
	Else
		$sCsv &= "," & $k
	EndIf
	IniWrite($sIni, $sSec, "textStart", SkillLog_ProbeAddrKey(SkillLog_ProbeTextStart()))
	IniWrite($sIni, $sSec, "failed", $sCsv)
	Out("SkillLog probe saved FAIL " & $k & " (" & $a_s_Reason & ") → " & $sIni)
EndFunc   ;==>SkillLog_ProbeMarkFailed

Func SkillLog_ProbeMarkLocked($a_s_Which, $a_p_Addr)
	If SkillLog_IsBadHookPtr($a_p_Addr) Then Return
	Local $sIni = SkillLog_ProbeIniPath()
	Local $sSec = StringLower($a_s_Which)
	IniWrite($sIni, $sSec, "textStart", SkillLog_ProbeAddrKey(SkillLog_ProbeTextStart()))
	IniWrite($sIni, $sSec, "locked", SkillLog_ProbeAddrKey($a_p_Addr))
	Out("SkillLog probe saved LOCK " & SkillLog_ProbeAddrKey($a_p_Addr) & " → " & $sIni)
EndFunc   ;==>SkillLog_ProbeMarkLocked

; Drop addresses already marked failed; keep order.
Func SkillLog_ProbeFilterCandidates($a_ai_Cand, $a_s_Which)
	Local $mState = SkillLog_ProbeLoadSection($a_s_Which)
	Local $mFail = SkillLog_ProbeFailedMap($mState["failed"])
	Local $aOut[1] = [0]
	Local $iSkip = 0
	For $i = 1 To $a_ai_Cand[0]
		Local $k = SkillLog_ProbeAddrKey($a_ai_Cand[$i])
		If MapExists($mFail, $k) Then
			$iSkip += 1
			ContinueLoop
		EndIf
		$aOut[0] += 1
		ReDim $aOut[$aOut[0] + 1]
		$aOut[$aOut[0]] = $a_ai_Cand[$i]
	Next
	Out("SkillLog probe filter: " & $a_ai_Cand[0] & " candidates, skipped " & $iSkip & " known-fail, remain " & $aOut[0])
	If $mState["locked"] <> "" Then Out("SkillLog probe prior LOCK=" & $mState["locked"])
	Return $aOut
EndFunc   ;==>SkillLog_ProbeFilterCandidates

Func SkillLog_AddPattern()
	Scanner_AddPattern("CasterSkillLog", $GC_S_SKILLLOG_PAT_CASTER, -46, "Hook")
	Scanner_AddPattern("MeleeSkillLog", $GC_S_SKILLLOG_PAT_MELEE, -46, "Hook")
EndFunc   ;==>SkillLog_AddPattern

Func SkillLog_SetLabel($a_s_Key, $a_v_Value)
	For $l_i_Index = 1 To $g_amx2_Labels[0][0]
		If $g_amx2_Labels[$l_i_Index][0] = $a_s_Key Then
			$g_amx2_Labels[$l_i_Index][1] = $a_v_Value
			Return True
		EndIf
	Next
	Return Memory_SetValue($a_s_Key, $a_v_Value)
EndFunc   ;==>SkillLog_SetLabel

Func SkillLog_IsBadHookPtr($a_p)
	Local $n = Number($a_p)
	Return ($n = 0 Or $n = -1 Or $n = 0xFFFFFFC2 Or $n = 0xFFFFFFD2)
EndFunc   ;==>SkillLog_IsBadHookPtr

; RPM AOB over .text — returns 1-based array of match starts ([0]=count).
Func SkillLog_AobSearch($a_s_HexPattern)
	Local $aOut[1] = [0]
	Local $pStart, $pEnd
	If Not Scanner_GetSection($GC_I_SECTION_TEXT, $pStart, $pEnd) Then
		Out("SkillLog AOB: .text section unavailable")
		Return $aOut
	EndIf
	Local $iSize = Int($pEnd - $pStart)
	If $iSize <= 0 Then Return $aOut
	Out("SkillLog AOB scan .text " & $pStart & ".." & $pEnd & " size=" & $iSize & " pat=" & $a_s_HexPattern)

	Local $dBuf = DllStructCreate("byte[" & $iSize & "]")
	Local $av = DllCall($g_h_Kernel32, "int", "ReadProcessMemory", _
		"int", $g_h_GWProcess, "int", $pStart, "ptr", DllStructGetPtr($dBuf), "int", $iSize, "int", "")
	If @error Or Not IsArray($av) Or $av[0] = 0 Then
		Out("SkillLog AOB: ReadProcessMemory failed")
		Return $aOut
	EndIf

	Local $sMem = BinaryToString(DllStructGetData($dBuf, 1))
	Local $sPat = BinaryToString(Binary("0x" & $a_s_HexPattern))
	Local $iPos = 1
	While True
		$iPos = StringInStr($sMem, $sPat, 1, 1, $iPos)
		If $iPos = 0 Then ExitLoop
		$aOut[0] += 1
		ReDim $aOut[$aOut[0] + 1]
		$aOut[$aOut[0]] = Ptr($pStart + ($iPos - 1))
		$iPos += 1
		If $aOut[0] >= 200 Then
			Out("SkillLog AOB: capped at 200 matches")
			ExitLoop
		EndIf
	WEnd
	Return $aOut
EndFunc   ;==>SkillLog_AobSearch

; Build hook candidates.
; Soft patterns already start at 55 8B EC (function entry) → hook the match VA.
; Logic's -46 was for GetScannedAddress math / older layout; using it on soft matches
; left 0 candidates (match-46 is before the prologue).
Func SkillLog_BuildCandidates($a_s_HexPattern)
	Local $aMatches = SkillLog_AobSearch($a_s_HexPattern)
	Local $aOut[1] = [0]
	Local $mSeen[]
	Local $bPatIsPrologue = (StringLeft($a_s_HexPattern, 6) = "558BEC")
	Out("SkillLog AOB " & $a_s_HexPattern & " matches=" & $aMatches[0] & " prologuePat=" & $bPatIsPrologue)
	For $i = 1 To $aMatches[0]
		Local $pMatch = $aMatches[$i]
		If $i <= 12 Then
			Out("SkillLog AOB match[" & $i & "]=" & $pMatch & " bytes=" & SkillLog_ReadBytes($pMatch, 16))
		EndIf
		Local $aTry[3]
		If $bPatIsPrologue Then
			; Hook function entry (= match). Optionally also try -46/-47 if those are prologues too.
			$aTry[0] = $pMatch
			$aTry[1] = Ptr($pMatch - 46)
			$aTry[2] = Ptr($pMatch - 47)
		Else
			$aTry[0] = Ptr($pMatch - 46)
			$aTry[1] = Ptr($pMatch - 47)
			$aTry[2] = $pMatch
		EndIf
		For $t = 0 To 2
			Local $p = $aTry[$t]
			If SkillLog_IsBadHookPtr($p) Then ContinueLoop
			Local $k = SkillLog_ProbeAddrKey($p)
			If MapExists($mSeen, $k) Then ContinueLoop
			Local $sHead = SkillLog_ReadBytes($p, 3)
			If $sHead <> "558BEC" Then ContinueLoop
			; Skip the known crash site from the false lock.
			If $k = "0x009DF9E0" Then ContinueLoop
			$mSeen[$k] = 1
			$aOut[0] += 1
			ReDim $aOut[$aOut[0] + 1]
			$aOut[$aOut[0]] = $p
			If $aOut[0] >= $g_i_SkillLogProbeMaxCand Then
				Out("SkillLog candidates capped at " & $g_i_SkillLogProbeMaxCand)
				Out("SkillLog candidates=" & $aOut[0])
				Return $aOut
			EndIf
		Next
	Next
	Out("SkillLog candidates=" & $aOut[0] & " (558BEC sites only)")
	Return $aOut
EndFunc   ;==>SkillLog_BuildCandidates

; True if payload looks like a real skill activate (rejects crash/garbage false HITs).
Func SkillLog_HitLooksValid($a_i_Caster, $a_i_Target, $a_i_Skill)
	#forceref $a_i_Target
	If $a_i_Skill < 1 Or $a_i_Skill > 4000 Then Return False
	If $a_i_Caster < 1 Or $a_i_Caster > 100000 Then Return False
	Return True
EndFunc   ;==>SkillLog_HitLooksValid

; Option 1: try full Logic pattern, then softer ladders until we get candidates.
Func SkillLog_BuildCandidatesLadder($a_s_Which = "caster")
	Local $aPats[4]
	If $a_s_Which = "melee" Then
		$aPats[0] = $GC_S_SKILLLOG_PAT_MELEE
	Else
		$aPats[0] = $GC_S_SKILLLOG_PAT_CASTER
	EndIf
	$aPats[1] = $GC_S_SKILLLOG_PAT_SOFT_PUSH
	$aPats[2] = $GC_S_SKILLLOG_PAT_SOFT
	$aPats[3] = $GC_S_SKILLLOG_PAT_SOFT_MIN

	For $i = 0 To 3
		Out("SkillLog ladder step " & ($i + 1) & "/4 pattern=" & $aPats[$i])
		Local $aCand = SkillLog_BuildCandidates($aPats[$i])
		If $aCand[0] > 0 Then
			Out("SkillLog ladder HIT at step " & ($i + 1) & " with " & $aCand[0] & " candidates")
			Return $aCand
		EndIf
	Next
	Out("SkillLog ladder: all steps empty — signatures not in .text")
	Local $aEmpty[1] = [0]
	Return $aEmpty
EndFunc   ;==>SkillLog_BuildCandidatesLadder

Func SkillLog_Scanner()
	Local $l_p_Caster = Scanner_GetScanResult("CasterSkillLog", $g_ap_ScanResults, "Hook")
	Local $l_p_Melee = Scanner_GetScanResult("MeleeSkillLog", $g_ap_ScanResults, "Hook")

	$g_p_CasterSkillLogStart = Ptr($l_p_Caster)
	$g_p_MeleeSkillLogStart = Ptr($l_p_Melee)

	; If remote ScanProc missed, fall back to soft AOB ladder.
	If SkillLog_IsBadHookPtr($g_p_CasterSkillLogStart) Then
		Local $aC = SkillLog_BuildCandidatesLadder("caster")
		If $aC[0] > 0 Then $g_p_CasterSkillLogStart = $aC[1]
	EndIf
	If SkillLog_IsBadHookPtr($g_p_MeleeSkillLogStart) Then
		Local $aM = SkillLog_BuildCandidatesLadder("melee")
		If $aM[0] > 0 Then $g_p_MeleeSkillLogStart = $aM[1]
	EndIf

	SkillLog_SetLabel("CasterSkillLogStart", $g_p_CasterSkillLogStart)
	SkillLog_SetLabel("CasterSkillLogReturn", Ptr(Number($g_p_CasterSkillLogStart) + 5))
	SkillLog_SetLabel("MeleeSkillLogStart", $g_p_MeleeSkillLogStart)
	SkillLog_SetLabel("MeleeSkillLogReturn", Ptr(Number($g_p_MeleeSkillLogStart) + 5))
	Memory_SetValue("SkillLogSize", "0x" & Hex($GC_I_SKILLLOG_SIZE, 8))
	; Immediate for push (must be SetValue'd BEFORE any Label_ of same name).
	Memory_SetValue("SkillLogCallbackEvent", Number($GC_I_SKILLLOG_WM))

	Log_Info("SkillLog scan CasterStart=" & $g_p_CasterSkillLogStart & " MeleeStart=" & $g_p_MeleeSkillLogStart, "SkillLog_Scanner", $g_h_EditText)
EndFunc   ;==>SkillLog_Scanner

Func SkillLog_InitializeResult()
	$g_h_SkillLogGUI = GUICreate("GwAu3SkillLog")
	GUIRegisterMsg($GC_I_SKILLLOG_WM, "SkillLog_EventCallback")
	Local $pHandle = Memory_GetValue("SkillLogCallbackHandle")
	If $pHandle = -1 Or $pHandle = 0 Then
		Log_Info("SkillLogCallbackHandle missing — ASM data not present", "SkillLog_InitializeResult", $g_h_EditText)
		Return
	EndIf
	Memory_Write($pHandle, $g_h_SkillLogGUI)
	Log_Info("SkillLog GUI=" & $g_h_SkillLogGUI & " handleSlot=" & $pHandle, "SkillLog_InitializeResult", $g_h_EditText)
EndFunc   ;==>SkillLog_InitializeResult

Func Assembler_CreateSkillLogData()
	_("SkillLogCallbackHandle/4")
	_("SkillLogCounter/4")
	_("SkillLogBase/" & (16 * $GC_I_SKILLLOG_SIZE))
	; 7 stolen bytes (55 8B EC 56 8B 75 08) + E9 to hook+7. Stealing only 5 splits the MOV.
	_("SkillLogProbeTrampoline/16")
EndFunc   ;==>Assembler_CreateSkillLogData

Func Assembler_CreateCasterSkillLog()
	_("CasterSkillLogProc:")
	_("pushfd")
	_("pushad")

	_("mov eax,dword[SkillLogCounter]")
	_("push eax")
	_("shl eax,4")
	_("add eax,SkillLogBase")

	_("mov dword[eax],edi")
	_("mov dword[eax+4],ecx")
	_("mov dword[eax+8],ebx")

	_("push 1") ; $GC_I_SKILLLOG_LP_CASTER
	_("push eax")
	_("push SkillLogCallbackEvent")
	_("push dword[SkillLogCallbackHandle]")
	_("call dword[PostMessage]")

	_("pop eax")
	_("inc eax")
	_("cmp eax,10")
	_("jnz CasterSkillLogSkipReset")
	_("xor eax,eax")
	_("CasterSkillLogSkipReset:")
	_("mov dword[SkillLogCounter],eax")

	_("popad")
	_("popfd")
	_("mov ebp,esp")
	_("push dword[ebp+8]")
	_("ljmp CasterSkillLogReturn")
EndFunc   ;==>Assembler_CreateCasterSkillLog

Func Assembler_CreateMeleeSkillLog()
	_("MeleeSkillLogProc:")
	_("pushfd")
	_("pushad")

	_("mov eax,dword[SkillLogCounter]")
	_("push eax")
	_("shl eax,4")
	_("add eax,SkillLogBase")

	_("mov dword[eax],edi")
	_("mov dword[eax+4],ecx")
	_("mov dword[eax+8],ebx")

	_("push 2") ; $GC_I_SKILLLOG_LP_MELEE
	_("push eax")
	_("push SkillLogCallbackEvent")
	_("push dword[SkillLogCallbackHandle]")
	_("call dword[PostMessage]")

	_("pop eax")
	_("inc eax")
	_("cmp eax,10")
	_("jnz MeleeSkillLogSkipReset")
	_("xor eax,eax")
	_("MeleeSkillLogSkipReset:")
	_("mov dword[SkillLogCounter],eax")

	_("popad")
	_("popfd")
	_("mov ebp,esp")
	_("push dword[ebp+8]")
	_("ljmp MeleeSkillLogReturn")
EndFunc   ;==>Assembler_CreateMeleeSkillLog

; Probe-only: same capture/PostMessage, but exit via trampoline (stolen bytes + jmp hook+5).
; Avoids Logic's mov ebp,esp / push [ebp+8] which crashes on non-SkillLog sites.
Func Assembler_CreateProbeSkillLog()
	_("ProbeSkillLogProc:")
	_("pushfd")
	_("pushad")

	_("mov eax,dword[SkillLogCounter]")
	_("push eax")
	_("shl eax,4")
	_("add eax,SkillLogBase")

	_("mov dword[eax],edi")
	_("mov dword[eax+4],ecx")
	_("mov dword[eax+8],ebx")

	_("push 1")
	_("push eax")
	_("push SkillLogCallbackEvent")
	_("push dword[SkillLogCallbackHandle]")
	_("call dword[PostMessage]")

	_("pop eax")
	_("inc eax")
	_("cmp eax,10")
	_("jnz ProbeSkillLogSkipReset")
	_("xor eax,eax")
	_("ProbeSkillLogSkipReset:")
	_("mov dword[SkillLogCounter],eax")

	_("popad")
	_("popfd")
	_("ljmp SkillLogProbeTrampoline")
EndFunc   ;==>Assembler_CreateProbeSkillLog

Func SkillLog_ReadBytes($a_p_Addr, $a_i_Len = 5)
	If $a_p_Addr = 0 Or $a_p_Addr = -1 Then Return ""
	Local $l_s_Buffer = DllStructCreate("byte[" & $a_i_Len & "]")
	DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
		"handle", $g_h_GWProcess, _
		"ptr", $a_p_Addr, _
		"ptr", DllStructGetPtr($l_s_Buffer), _
		"ulong_ptr", $a_i_Len, _
		"ulong_ptr*", 0)
	Local $s = ""
	For $i = 1 To $a_i_Len
		$s &= Hex(DllStructGetData($l_s_Buffer, 1, $i), 2)
	Next
	Return $s
EndFunc   ;==>SkillLog_ReadBytes

; Gate callbacks without tearing down detours. Fight: SetLive(True/False); empty Respond still full-disarms.
Func SkillLog_SetLive($a_b_Live)
	$g_b_SkillLogLive = ($a_b_Live = True Or $a_b_Live = 1)
	Out("SkillLog live=" & ($g_b_SkillLogLive ? "yes" : "no") & " detours=" & ($g_b_SkillLogDetoursOn ? "on" : "off"))
	Return $g_b_SkillLogLive
EndFunc   ;==>SkillLog_SetLive

; Bind AutoIt responders for caster / melee skill activates.
; Name is SkillLog_Respond (not EventCallback — that is the WM handler below).
; Empty args = disarm detours. Prefer CacheSkillBar / bot init once; Fight uses SetLive.
Func SkillLog_Respond($a_s_OnSpell = "", $a_s_OnMelee = "")
	If $a_s_OnSpell = "" And $a_s_OnMelee = "" Then
		Memory_RevertDetour("CasterSkillLogStart")
		Memory_RevertDetour("MeleeSkillLogStart")
		$g_s_SkillActivate = ""
		$g_s_SkillMeleeActivate = ""
		$g_b_SkillLogLive = False
		$g_b_SkillLogDetoursOn = False
		Out("SkillLog detours disarmed")
		Return True
	EndIf

	If SkillLog_IsBadHookPtr($g_p_CasterSkillLogStart) And SkillLog_IsBadHookPtr($g_p_MeleeSkillLogStart) And Not $g_b_SkillLogProbe Then
		Out("SkillLog arm refused — scan addresses bad (use SkillLog_StartProbe)")
		Return False
	EndIf

	Local $pProc = Memory_GetValue("CasterSkillLogProc")
	Local $pMelee = Memory_GetValue("MeleeSkillLogProc")
	If $pProc = -1 Or $pMelee = -1 Then
		Out("SkillLog arm refused — ASM procs missing (restart GW so Cmd ASM reallocates)")
		Return False
	EndIf

	; Proc should start with pushfd (9C) if SkillLog ASM was actually written.
	Local $sProcHead = SkillLog_ReadBytes($pProc, 2)
	Local $sMeleeHead = SkillLog_ReadBytes($pMelee, 2)
	If $sProcHead <> "9C60" And $sProcHead <> "609C" Then
		Out("SkillLog WARN: CasterSkillLogProc bytes=" & $sProcHead & " (expected 9C60 pushfd/pushad) — ASM not injected")
	EndIf
	If $sMeleeHead <> "9C60" And $sMeleeHead <> "609C" Then
		Out("SkillLog WARN: MeleeSkillLogProc bytes=" & $sMeleeHead & " (expected 9C60) — ASM not injected")
	EndIf

	; Responder names can switch without re-patching if detours already on.
	$g_s_SkillActivate = $a_s_OnSpell
	$g_s_SkillMeleeActivate = $a_s_OnMelee

	If Not $g_b_SkillLogDetoursOn Then
		If $a_s_OnSpell <> "" And Not SkillLog_IsBadHookPtr($g_p_CasterSkillLogStart) Then
			Memory_WriteDetourEx("CasterSkillLogStart", "CasterSkillLogProc")
		EndIf
		If $a_s_OnMelee <> "" And Not SkillLog_IsBadHookPtr($g_p_MeleeSkillLogStart) Then
			Memory_WriteDetourEx("MeleeSkillLogStart", "MeleeSkillLogProc")
		EndIf
		$g_b_SkillLogDetoursOn = True
		Local $sHookC = SkillLog_ReadBytes($g_p_CasterSkillLogStart, 5)
		Local $sHookM = SkillLog_ReadBytes($g_p_MeleeSkillLogStart, 5)
		Out("SkillLog detours installed Caster→" & $a_s_OnSpell & " hook=" & $sHookC & " start=" & $g_p_CasterSkillLogStart)
		Out("SkillLog detours installed Melee→" & $a_s_OnMelee & " hook=" & $sHookM & " start=" & $g_p_MeleeSkillLogStart)
		Out("SkillLog procs caster=" & $pProc & " melee=" & $pMelee)
	Else
		Out("SkillLog responders → Caster=" & $a_s_OnSpell & " Melee=" & $a_s_OnMelee & " (detours kept)")
	EndIf

	$g_b_SkillLogLive = True
	Out("SkillLog live=yes hits C/M=" & $g_i_SkillLogHitsCaster & "/" & $g_i_SkillLogHitsMelee)
	Return True
EndFunc   ;==>SkillLog_Respond

; Compat alias — prefer SkillLog_Respond.
Func SkillLog_SetEventCallback($a_s_OnSpell = "", $a_s_OnMelee = "")
	Return SkillLog_Respond($a_s_OnSpell, $a_s_OnMelee)
EndFunc   ;==>SkillLog_SetEventCallback

; Soft-pattern sites start 55 8B EC 56 8B 75 08. Must steal all 7 bytes — a 5-byte
; steal leaves a truncated MOV (8B|) and turns hook+5 into JNE (75 08) → instant crash.
Func SkillLog_WriteProbeTrampoline($a_p_Hook)
	Local $pTramp = Memory_GetValue("SkillLogProbeTrampoline")
	If $pTramp = -1 Or $pTramp = 0 Then
		Out("SkillLog trampoline missing — restart GW so Cmd ASM includes ProbeSkillLog")
		Return False
	EndIf
	Local $sHead = SkillLog_ReadBytes($a_p_Hook, 7)
	If StringLeft($sHead, 14) <> "558BEC568B7508" Then
		Out("SkillLog trampoline refuse — expected 558BEC568B7508 at " & $a_p_Hook & " got " & $sHead)
		Return False
	EndIf
	; JMP (5) overlays the prologue; resume at hook+7 (past the 2 orphaned bytes).
	Local $iResume = Number($a_p_Hook) + 7
	Local $iRel = $iResume - (Number($pTramp) + 7) - 5
	Local $sJmp = "E9" & Utils_SwapEndian(Hex($iRel, 8))
	Memory_WriteBinary($sHead & $sJmp, $pTramp)
	Out("SkillLog trampoline @" & $pTramp & " stolen7=" & $sHead & " -> " & Ptr($iResume))
	Return True
EndFunc   ;==>SkillLog_WriteProbeTrampoline

; Arm one absolute hook site (probe / AOB fallback). $a_s_Which = "caster"|"melee"
; Probe uses ProbeSkillLogProc + trampoline (safe). Live SkillLog uses Logic epilogue procs.
Func SkillLog_ArmAt($a_p_Addr, $a_s_Which = "caster")
	If SkillLog_IsBadHookPtr($a_p_Addr) Then Return False
	Local $sStart = ($a_s_Which = "melee") ? "MeleeSkillLogStart" : "CasterSkillLogStart"
	Local $sRet = ($a_s_Which = "melee") ? "MeleeSkillLogReturn" : "CasterSkillLogReturn"
	; Probe/search always uses trampoline exit — Logic epilogue crashes on non-SkillLog sites.
	Local $sProc = "ProbeSkillLogProc"
	If Memory_GetValue($sProc) = -1 Then
		Out("SkillLog ArmAt aborted — ProbeSkillLogProc missing (restart GW so Cmd ASM rebuilds)")
		Return False
	EndIf

	Memory_RevertDetour($sStart)
	SkillLog_SetLabel($sStart, Ptr($a_p_Addr))
	SkillLog_SetLabel($sRet, Ptr(Number($a_p_Addr) + 5))
	If $a_s_Which = "melee" Then
		$g_p_MeleeSkillLogStart = Ptr($a_p_Addr)
	Else
		$g_p_CasterSkillLogStart = Ptr($a_p_Addr)
	EndIf

	If $sProc = "ProbeSkillLogProc" Then
		If Not SkillLog_WriteProbeTrampoline($a_p_Addr) Then Return False
	EndIf

	Memory_WriteDetourEx($sStart, $sProc)
	$g_p_SkillLogProbeArmed = Ptr($a_p_Addr)
	Local $sHook = SkillLog_ReadBytes($a_p_Addr, 5)
	Out("SkillLog ArmAt [" & $a_s_Which & "] " & $a_p_Addr & " via " & $sProc & " hook=" & $sHook)
	Return StringLeft($sHook, 2) = "E9"
EndFunc   ;==>SkillLog_ArmAt

; Build AOB candidates, skip known fails from SkillLog_probe.ini, arm #1 (or resume LOCK).
Func SkillLog_StartProbe($a_i_SkillID = 898, $a_s_Which = "caster")
	Local $mState = SkillLog_ProbeLoadSection($a_s_Which)

	$g_s_SkillActivate = "OnSpell"
	$g_s_SkillMeleeActivate = "OnMelee"
	$g_i_SkillLogProbeSkillID = Number($a_i_SkillID)
	$g_s_SkillLogProbeWhich = $a_s_Which
	$g_b_SkillLogProbeWasCasting = False
	$g_i_SkillLogProbeHitsAtArm = $g_i_SkillLogHits

	; Resume a previously locked address if .text base still matches.
	If $mState["locked"] <> "" Then
		Local $pLock = Ptr(Number($mState["locked"]))
		If Not SkillLog_IsBadHookPtr($pLock) And SkillLog_ArmAt($pLock, $a_s_Which) Then
			$g_b_SkillLogProbeLocked = True
			$g_b_SkillLogProbe = False
			$g_p_SkillLogProbeArmed = $pLock
			SkillLog_Alert("PROBE RESUME LOCK [" & $a_s_Which & "] " & $pLock & " (from ini)")
			Return True
		EndIf
		Out("SkillLog probe prior LOCK unusable — continuing search")
	EndIf

	Local $aRaw = SkillLog_BuildCandidatesLadder($a_s_Which)
	$g_ai_SkillLogProbeCandidates = SkillLog_ProbeFilterCandidates($aRaw, $a_s_Which)
	If $g_ai_SkillLogProbeCandidates[0] < 1 Then
		Out("SkillLog probe aborted — no remaining candidates for " & $a_s_Which & " (see " & SkillLog_ProbeIniPath() & ")")
		$g_b_SkillLogProbe = False
		Return False
	EndIf

	$g_i_SkillLogProbeIndex = 1
	$g_b_SkillLogProbeLocked = False
	$g_b_SkillLogProbe = True
	$g_b_SkillLogProbePendingAdvance = False
	$g_i_SkillLogProbeFalseHits = 0

	SkillLog_ArmAt($g_ai_SkillLogProbeCandidates[1], $a_s_Which)
	Out("SkillLog PROBE start which=" & $a_s_Which & " skillID=" & $g_i_SkillLogProbeSkillID & " remain=" & $g_ai_SkillLogProbeCandidates[0] & " ini=" & SkillLog_ProbeIniPath())
	Out("SkillLog PROBE: cast that skill once per candidate; fails are saved across sessions")
	Return True
EndFunc   ;==>SkillLog_StartProbe

Func SkillLog_Alert($a_s_Msg)
	Out($a_s_Msg)
	Beep(880, 120)
	Beep(1175, 180)
	; Local-only chat line (only you see it) — needs Core/Cmd ready.
	If IsDeclared("g_p_WriteChatPtr") And $g_p_WriteChatPtr <> 0 And $g_h_GWProcess Then
		Chat_WriteChat($a_s_Msg, "SkillLog")
	EndIf
EndFunc   ;==>SkillLog_Alert

Func SkillLog_ProbeLock()
	If Not $g_b_SkillLogProbe Or $g_b_SkillLogProbeLocked Then Return
	$g_b_SkillLogProbeLocked = True
	$g_b_SkillLogProbe = False
	SkillLog_ProbeMarkLocked($g_s_SkillLogProbeWhich, $g_p_SkillLogProbeArmed)
	SkillLog_Alert("PROBE LOCKED [" & $g_s_SkillLogProbeWhich & "] " & $g_p_SkillLogProbeArmed & " (" & $g_i_SkillLogProbeIndex & "/" & $g_ai_SkillLogProbeCandidates[0] & ")")
EndFunc   ;==>SkillLog_ProbeLock

; Disarm + mark failed. Do NOT arm the next site here — that caused a cascade when a
; hot function spammed FALSE HITs and burned the whole candidate list in one cast.
Func SkillLog_ProbeDisarmCurrent($a_s_Why)
	If Not $g_b_SkillLogProbe Or $g_b_SkillLogProbePendingAdvance Then Return
	Out("SkillLog PROBE disarm " & $g_p_SkillLogProbeArmed & " — " & $a_s_Why & " (wait for next Overload to advance)")
	Local $sReason = (StringInStr($a_s_Why, "garbage") Or StringInStr($a_s_Why, "FALSE")) ? "garbage" : "no_hit"
	SkillLog_ProbeMarkFailed($g_s_SkillLogProbeWhich, $g_p_SkillLogProbeArmed, $sReason)
	Memory_RevertDetour(($g_s_SkillLogProbeWhich = "melee") ? "MeleeSkillLogStart" : "CasterSkillLogStart")
	$g_b_SkillLogProbePendingAdvance = True
	$g_b_SkillLogProbeWasCasting = False
	$g_i_SkillLogProbeFalseHits = 0
EndFunc   ;==>SkillLog_ProbeDisarmCurrent

Func SkillLog_ProbeAdvance()
	If Not $g_b_SkillLogProbe Or $g_b_SkillLogProbeLocked Then Return
	$g_b_SkillLogProbePendingAdvance = False
	$g_i_SkillLogProbeIndex += 1
	If $g_i_SkillLogProbeIndex > $g_ai_SkillLogProbeCandidates[0] Then
		Out("SkillLog PROBE exhausted all " & $g_ai_SkillLogProbeCandidates[0] & " candidates")
		$g_b_SkillLogProbe = False
		Return
	EndIf
	$g_i_SkillLogProbeHitsAtArm = $g_i_SkillLogHits
	Out("SkillLog PROBE advance → " & $g_i_SkillLogProbeIndex & "/" & $g_ai_SkillLogProbeCandidates[0] & " addr=" & $g_ai_SkillLogProbeCandidates[$g_i_SkillLogProbeIndex])
	SkillLog_ArmAt($g_ai_SkillLogProbeCandidates[$g_i_SkillLogProbeIndex], $g_s_SkillLogProbeWhich)
EndFunc   ;==>SkillLog_ProbeAdvance

; Call from bot loop. Exactly one candidate per Overload cast.
Func SkillLog_ProbeTick()
	If Not $g_b_SkillLogProbe Or $g_b_SkillLogProbeLocked Then Return

	Local $iSkill = Number(Agent_GetAgentInfo(-2, "Skill"))
	Local $bCasting = ($iSkill <> 0)
	If $g_i_SkillLogProbeSkillID > 0 Then
		$bCasting = ($iSkill = $g_i_SkillLogProbeSkillID)
	EndIf

	; On cast end: lock already handled in callback; otherwise advance once.
	If Not $bCasting And $g_b_SkillLogProbeWasCasting Then
		If $g_b_SkillLogProbeLocked Then
			; ok
		ElseIf $g_b_SkillLogProbePendingAdvance Then
			SkillLog_ProbeAdvance()
		ElseIf $g_i_SkillLogHits > $g_i_SkillLogProbeHitsAtArm Then
			SkillLog_ProbeDisarmCurrent("cast ended with no valid Overload HIT")
			SkillLog_ProbeAdvance()
		Else
			SkillLog_ProbeDisarmCurrent("no HIT on Overload cast")
			SkillLog_ProbeAdvance()
		EndIf
	EndIf
	$g_b_SkillLogProbeWasCasting = $bCasting
EndFunc   ;==>SkillLog_ProbeTick

Func SkillLog_SkillName($a_i_SkillID)
	Local $av = Call("Skill_NameFromID", $a_i_SkillID)
	If Not @error And IsString($av) And $av <> "" Then Return $av
	Return "#" & Number($a_i_SkillID)
EndFunc   ;==>SkillLog_SkillName

Func SkillLog_AgentName($a_i_AgentID)
	Local $i = Number($a_i_AgentID)
	If $i <= 0 Then Return "-"
	Local $s = Agent_GetAgentInfo($i, "Name")
	If IsString($s) And $s <> "" Then Return $s
	Return "#" & $i
EndFunc   ;==>SkillLog_AgentName

Func SkillLog_EventCallback($hWnd, $msg, $wparam, $lparam)
	#forceref $hWnd, $msg
	Switch $lparam
		Case $GC_I_SKILLLOG_LP_CASTER, $GC_I_SKILLLOG_LP_MELEE
			; Outside Fight / bot live window: leave detours up but ignore activates (except probe).
			If Not $g_b_SkillLogLive And Not $g_b_SkillLogProbe Then Return 0

			DllCall($g_h_Kernel32, "int", "ReadProcessMemory", "int", $g_h_GWProcess, "int", $wparam, "ptr", $g_p_SkillLogStruct, "int", 16, "int", "")
			Local $iCaster = DllStructGetData($g_d_SkillLogStruct, 1)
			Local $iTarget = DllStructGetData($g_d_SkillLogStruct, 2)
			Local $iSkill = DllStructGetData($g_d_SkillLogStruct, 3)
			Local $fAct = DllStructGetData($g_d_SkillLogStruct, 4)
			Local $bMelee = ($lparam = $GC_I_SKILLLOG_LP_MELEE)
			Local $sSrc = $bMelee ? "MELEE" : "CASTER"
			Local $sSkill = SkillLog_SkillName($iSkill)
			Local $sCaster = SkillLog_AgentName($iCaster)
			Local $sTarget = SkillLog_AgentName($iTarget)

			If Not SkillLog_HitLooksValid($iCaster, $iTarget, $iSkill) Then
				If $g_b_SkillLogProbe Then
					$g_i_SkillLogProbeFalseHits += 1
					If Not $g_b_SkillLogProbePendingAdvance Then
						Out("SkillLog FALSE HIT @" & $g_p_SkillLogProbeArmed & " [" & $sSrc & "] " & $sSkill)
						SkillLog_ProbeDisarmCurrent("garbage payload")
					EndIf
				EndIf
				Return 0
			EndIf

			If $g_b_SkillLogProbe And $g_i_SkillLogProbeSkillID > 0 And $iSkill <> $g_i_SkillLogProbeSkillID Then
				Out("SkillLog HIT wrong skill during probe (want " & $g_i_SkillLogProbeSkillID & ")")
				Return 0
			EndIf

			$g_i_SkillLogHits += 1
			If $bMelee Then
				$g_i_SkillLogHitsMelee += 1
			Else
				$g_i_SkillLogHitsCaster += 1
			EndIf
			; Probe-only chatter; normal live hits stay quiet (interrupt logs live in the callback).
			If $g_b_SkillLogProbe Then
				Out("HIT #" & $g_i_SkillLogHits & " [" & $sSrc & "] " & $sSkill & " caster=" & $sCaster & " target=" & $sTarget)
				SkillLog_ProbeLock()
			EndIf

			Local $sCb = $bMelee ? $g_s_SkillMeleeActivate : $g_s_SkillActivate
			If $sCb = "" Then $sCb = $bMelee ? $g_s_SkillActivate : $g_s_SkillMeleeActivate
			If $sCb <> "" Then Call($sCb, $iCaster, $iTarget, $iSkill, $fAct)
	EndSwitch
	Return 0
EndFunc   ;==>SkillLog_EventCallback

Func SkillLog_DumpScan()
	Out("SkillLog CasterSkillLogStart=" & Memory_GetValue("CasterSkillLogStart"))
	Out("SkillLog MeleeSkillLogStart=" & Memory_GetValue("MeleeSkillLogStart"))
	Out("SkillLog CasterSkillLogProc=" & Memory_GetValue("CasterSkillLogProc"))
	Out("SkillLog MeleeSkillLogProc=" & Memory_GetValue("MeleeSkillLogProc"))
	Out("SkillLog patterns OK=" & ((Not SkillLog_IsBadHookPtr($g_p_CasterSkillLogStart) And Not SkillLog_IsBadHookPtr($g_p_MeleeSkillLogStart)) ? "yes" : "no"))
	Out("SkillLog armed=" & (($g_s_SkillActivate <> "" Or $g_s_SkillMeleeActivate <> "") ? "yes" : "no") & " live=" & ($g_b_SkillLogLive ? "yes" : "no") & " detours=" & ($g_b_SkillLogDetoursOn ? "on" : "off"))
	Out("SkillLog casterHook=" & SkillLog_ReadBytes($g_p_CasterSkillLogStart, 5) & " procHead=" & SkillLog_ReadBytes(Memory_GetValue("CasterSkillLogProc"), 2))
	Out("SkillLog meleeHook=" & SkillLog_ReadBytes($g_p_MeleeSkillLogStart, 5) & " procHead=" & SkillLog_ReadBytes(Memory_GetValue("MeleeSkillLogProc"), 2))
	Out("SkillLog hits total=" & $g_i_SkillLogHits & " caster=" & $g_i_SkillLogHitsCaster & " melee=" & $g_i_SkillLogHitsMelee)
	Out("SkillLog probe=" & ($g_b_SkillLogProbe ? "active" : ($g_b_SkillLogProbeLocked ? "locked" : "off")) & " armed=" & $g_p_SkillLogProbeArmed)
EndFunc   ;==>SkillLog_DumpScan
