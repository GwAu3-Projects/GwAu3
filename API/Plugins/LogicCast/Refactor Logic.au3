
; ==============================================================================
; EXHAUSTIVE REFACTORING UTILITY SCRIPT (INCLUDING MAP TRAVEL)
; ==============================================================================
; Targets: logicmove.au3, logiccast.au3, logicagents.au3, and main logic files
; Creates .bak backups before modifying.
; ==============================================================================

Local $aTargetFiles[4] = ["logicmove.au3", "logiccast.au3", "logicagents.au3", "logic.au3"]

For $i = 0 To UBound($aTargetFiles) - 1
    RefactorLogicFileWithMap($aTargetFiles[$i])
Next

MsgBox(64, "Refactoring Complete", "Files have been updated with native gwau3 map travel, movement, and casting functions.")

Func RefactorLogicFileWithMap($sFilePath)
    If Not FileExists($sFilePath) Then
        ConsoleWrite("[-] File not found: " & $sFilePath & " (Skipping)" & @CRLF)
        Return False
    EndIf

    ConsoleWrite("[+] Processing (with Map Travel): " & $sFilePath & "..." & @CRLF)

    ; 1. Create Backup (.bak)
    FileCopy($sFilePath, $sFilePath & ".bak", 1)

    ; 2. Read Content
    Local $hFile = FileOpen($sFilePath, 0)
    If $hFile = -1 Then Return False
    Local $sContent = FileRead($hFile)
    FileClose($hFile)

    ; ==========================================================================
    ; STEP A: STRIP OBSOLETE STRUCTS & LOW-LEVEL ALLOCATIONS
    ; ==========================================================================
    Local $aStructs[12] = [ _
        "$mMove", "$mMovePtr", _
        "$mUseSkill", "$mUseSkillPtr", _
        "$mUseHeroSkill", "$mUseHeroSkillPtr", _
        "$mChangeTarget", "$mChangeTargetPtr", _
        "$mMakeAgentArray", "$mMakeAgentArrayPtr", _
        "$mMapLoading", "$mMapIsLoaded" _
    ]

    For $sStruct In $aStructs
        $sContent = StringRegExpReplace($sContent, "(?i)Local\s+\\" & $sStruct & "\s*=\s*DllStructCreate\([^)]+\)\s*\r?\n?", "")
        $sContent = StringRegExpReplace($sContent, "(?i)Local\s+\\" & $sStruct & "\s*=\s*DllStructGetPtr\([^)]+\)\s*\r?\n?", "")
    Next

    ; ==========================================================================
    ; STEP B: MAP LEGACY WRAPPERS TO VERIFIED GWAU3 SIGNATURES
    ; ==========================================================================
    ; Map Travel & Zoning Replacements
    $sContent = StringRegExpReplace($sContent, "(?i)\bTravelTo\s*\(\s*([^)]+)\s*\)", "Map_TravelTo(\1)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bReturnToOutpost\s*\(\s*\)", "Map_ReturnToOutpost()")
    $sContent = StringRegExpReplace($sContent, "(?i)\bRndTravel\s*\(\s*([^)]+)\s*\)", "Map_RndTravel(\1)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bWaitMapLoading\s*\(\s*\)", "Map_WaitMapIsLoaded_Ping(30000)")

    ; Movement Replacements
    $sContent = StringRegExpReplace($sContent, "(?i)\bMoveTo\s*\(\s*([^,)]+)\s*,\s*([^)]+)\s*\)", "Move_ToCoord(\1, \2)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bWaypoint\s*\(\s*([^,)]+)\s*,\s*([^)]+)\s*\)", "Move_Waypoint(\1, \2)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bIsMoving\s*\(\s*\)", "Move_IsMoving()")

    ; Casting Replacements
    $sContent = StringRegExpReplace($sContent, "(?i)\bUseSkill\s*\(\s*([^,)]+)\s*,\s*([^)]+)\s*\)", "Skill_Use(\1, \2)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bUseHeroSkill\s*\(\s*([^,)]+)\s*,\s*([^,)]+)\s*,\s*([^)]+)\s*\)", "Skill_UseHero(\1, \2, \3)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bSkillIsReady\s*\(\s*([^)]+)\s*\)", "Skill_IsReady(\1)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bGetSkillRecharge\s*\(\s*([^)]+)\s*\)", "Skill_GetRecharge(\1)")

    ; Targeting & Agent Property Replacements
    $sContent = StringRegExpReplace($sContent, "(?i)\bChangeTarget\s*\(\s*([^)]+)\s*\)", "Agent_ChangeTarget(\1)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bGetAgentByID\s*\(\s*([^)]+)\s*\)", "Agent_GetByID(\1)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bGetDistance\s*\(\s*([^,)]+)\s*,\s*([^)]+)\s*\)", "Agent_GetDistanceToCoord(\1, \2)")
    $sContent = StringRegExpReplace($sContent, "(?i)\bGetMyID\s*\(\s*\)", "Agent_GetMyID()")
    $sContent = StringRegExpReplace($sContent, "(?i)\bGetTargetID\s*\(\s*\)", "Agent_GetTargetID()")

    ; 3. Write Updated Content
    $hFile = FileOpen($sFilePath, 2)
    If $hFile <> -1 Then
        FileWrite($hFile, $sContent)
        FileClose($hFile)
        ConsoleWrite("[✔] Refactored with Map Travel: " & $sFilePath & @CRLF)
        Return True
    EndIf

    Return False
EndFunc