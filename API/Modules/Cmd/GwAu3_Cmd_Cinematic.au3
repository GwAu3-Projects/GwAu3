#include-once

;~ Description: Skip a cinematic.
Func Cinematic_SkipCinematic()
    Return Core_SendPacket(0x4, $GC_I_HEADER_CINEMATIC_SKIP)
EndFunc   ;==>SkipCinematic

;~ Description: Waits for cinemtaic and attempts to skip it, can be used to skip back to back cutscene
Func Cinematic_WaitCinematic($a_i_Timeout = 15000, $a_i_SkipAttempts = 5, $a_b_CutsceneOnMap = False, $a_i_CutsceneCount = 1)
    For $i = 1 To $a_i_CutsceneCount
        Local $l_h_Timeout = TimerInit()
        While Not Game_GetGameInfo("IsCinematic")
            If TimerDiff($l_h_Timeout) > $a_i_Timeout Then Return SetError(1, 0, False)
            Sleep(50)
        WEnd 

        Other_PingSleep(1500)

        $l_h_Timeout = TimerInit()
        While True
            If TimerDiff($l_h_Timeout) > $a_i_Timeout Then Return SetError(1, 0, False)
            Cinematic_SkipCinematic()
            If $a_b_CutsceneOnMap Then
                While True
                    If TimerDiff($l_h_Timeout) > ($a_i_Timeout / $a_i_SkipAttempts) Then ExitLoop
                    If Not Game_GetGameInfo("IsCinematic") Then ExitLoop 2
                    Sleep(50)
                WEnd
            Else
                If Map_WaitMapIsLoaded($a_i_Timeout / $a_i_SkipAttempts) Then ExitLoop
            EndIf
        WEnd
    Next

    Return True
EndFunc