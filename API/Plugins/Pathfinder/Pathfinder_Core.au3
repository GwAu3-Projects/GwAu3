#include-once
#include <InetConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <ProgressConstants.au3>

Global $DLL_PATH = ""
Global $g_hPathfinderDLL = 0  ; Handle to loaded DLL
Global $g_bPathfinder_Debug = True  ; Debug logging (can be enabled from Pathfinder_Movements.au3)

; GitHub repository for maps releases (set this before calling Pathfinder_Initialize)
Global $g_sPathfinder_MapsRepo = "GwAu3-Projects/GwPathfinder-Maps"

Global Const $tagPathPoint = "float x;float y;int layer;int tp_type"
Global Const $tagPathResult = "ptr points;int point_count;float total_cost;int error_code;char error_message[256]"
Global Const $tagMapStats = "int trapezoid_count;int point_count;int teleport_count;int travel_portal_count;int npc_travel_count;int enter_travel_count;int error_code;char error_message[256]"
Global Const $tagObstacleZone = "float x;float y;float radius"


; Returns:
;   1 = OK (maps.rar or maps/ found)
;   2 = OK but no maps source found (maps.rar and maps/ missing)
;   0 = Failed (DLL error)
Func Pathfinder_Initialize()
    If $g_bPathfinder_Debug Then Out("[Pathfinder] Initialize - DLL_PATH=" & $DLL_PATH)

    Local $sDllDir = StringRegExpReplace($DLL_PATH, "\\[^\\]+$", "")
    Local $sMapsPath = $sDllDir & "\maps.rar"
    Local $sMapsDir = $sDllDir & "\maps"
    Local $sVersionFile = $sDllDir & "\maps.version"

    ; Check for map updates from GitHub releases
    Local $aUpdate = _Pathfinder_CheckForMapUpdate($sDllDir)

    If $aUpdate[0] Then
        ; Update available - clean up old files
        If $g_bPathfinder_Debug Then Out("[Pathfinder] Cleaning up old map files...")
        If FileExists($sMapsPath) Then FileDelete($sMapsPath)
        If FileExists($sDllDir & "\maps.zip") Then FileDelete($sDllDir & "\maps.zip")
        If FileExists($sMapsDir) Then DirRemove($sMapsDir, 1)

        ; Download new maps.rar
        If Pathfinder_DownloadMaps($sMapsPath, $aUpdate[1]) Then
            ; Write version file on successful download
            FileDelete($sVersionFile)
            FileWrite($sVersionFile, $aUpdate[2])
            If $g_bPathfinder_Debug Then Out("[Pathfinder] Version file updated to: " & $aUpdate[2])
        Else
            Out("[Pathfinder] ERROR: Download of updated maps failed!")
        EndIf
    Else
        ; No update - clean up legacy maps.zip if present
        If FileExists($sDllDir & "\maps.zip") Then
            If $g_bPathfinder_Debug Then Out("[Pathfinder] Deleting old maps.zip")
            FileDelete($sDllDir & "\maps.zip")
        EndIf

        ; If maps don't exist at all (first install, no network)
        If Not FileExists($sMapsPath) And Not FileExists($sMapsDir) Then
            If $g_bPathfinder_Debug Then Out("[Pathfinder] maps.rar not found and no update info available")
        EndIf
    EndIf

    ; Load DLL if not already loaded
    If $g_hPathfinderDLL = 0 Or $g_hPathfinderDLL = -1 Then
        $g_hPathfinderDLL = DllOpen($DLL_PATH)
        If $g_hPathfinderDLL = -1 Then
            If $g_bPathfinder_Debug Then Out("[Pathfinder] ERROR: DllOpen failed for " & $DLL_PATH)
            Return 0
        EndIf
        If $g_bPathfinder_Debug Then Out("[Pathfinder] DLL loaded OK, handle=" & $g_hPathfinderDLL)
    EndIf

    Local $result = DllCall($g_hPathfinderDLL, "int:cdecl", "Initialize")
    If @error Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder] ERROR: DllCall Initialize failed, @error=" & @error)
        Return 0
    EndIf

    If $g_bPathfinder_Debug Then Out("[Pathfinder] DLL Initialize returned: " & $result[0] & " (1=OK, 2=no maps, 0=error)")
    Return $result[0]
EndFunc

; Downloads maps.rar from the given URL with progress bar
; Returns: True on success, False on failure
Func Pathfinder_DownloadMaps($a_sDestPath, $a_sDownloadURL)
    If $a_sDownloadURL = "" Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder] DownloadMaps: No URL provided")
        Return False
    EndIf

    If $g_bPathfinder_Debug Then Out("[Pathfinder] DownloadMaps: URL = " & $a_sDownloadURL)
    If $g_bPathfinder_Debug Then Out("[Pathfinder] DownloadMaps: Dest = " & $a_sDestPath)

    ; Create progress GUI
    Local $hGUI = GUICreate("Pathfinder - Downloading maps.rar", 450, 100)
    Local $hLabel = GUICtrlCreateLabel("Downloading maps.rar... Connecting...", 20, 15, 410, 20)
    Local $hProgress = GUICtrlCreateProgress(20, 45, 410, 25)
    GUISetState(@SW_SHOW, $hGUI)

    ; Start background download
    Local $hDownload = InetGet($a_sDownloadURL, $a_sDestPath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
    If $g_bPathfinder_Debug Then Out("[Pathfinder] DownloadMaps: InetGet handle = " & $hDownload)

    ; Poll download progress until complete
    While Not InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
        Local $iBytesRead = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
        Local $iBytesTotal = InetGetInfo($hDownload, $INET_DOWNLOADSIZE)

        If $iBytesTotal > 0 Then
            Local $iPercent = Int($iBytesRead / $iBytesTotal * 100)
            GUICtrlSetData($hProgress, $iPercent)
            GUICtrlSetData($hLabel, "Downloading maps.rar... " & Round($iBytesRead / 1048576) & " / " & Round($iBytesTotal / 1048576) & " MB (" & $iPercent & "%)")
        Else
            GUICtrlSetData($hLabel, "Downloading maps.rar... " & Round($iBytesRead / 1048576) & " MB")
        EndIf

        Sleep(200)
    WEnd

    Local $bSuccess = InetGetInfo($hDownload, $INET_DOWNLOADSUCCESS)
    Local $iBytesRead = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
    InetClose($hDownload)
    GUIDelete($hGUI)

    If $g_bPathfinder_Debug Then Out("[Pathfinder] DownloadMaps: Complete. Success=" & $bSuccess & " BytesRead=" & $iBytesRead)

    If Not $bSuccess Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder] DownloadMaps: FAILED - cleaning up partial file")
        FileDelete($a_sDestPath)
        Return False
    EndIf

    ; Basic file size sanity check (maps.rar should be several MB)
    If $iBytesRead < 1048576 Then ; 1 MB minimum
        If $g_bPathfinder_Debug Then Out("[Pathfinder] DownloadMaps: FAILED - file too small (" & $iBytesRead & " bytes)")
        FileDelete($a_sDestPath)
        Return False
    EndIf

    If $g_bPathfinder_Debug Then Out("[Pathfinder] DownloadMaps: File saved OK (" & Round($iBytesRead / 1048576) & " MB)")
    Return True
EndFunc

; Checks if maps need updating from GitHub releases
; Returns: Array [needsUpdate (Bool), downloadURL (String), newVersion (String)]
Func _Pathfinder_CheckForMapUpdate($a_sDllDir)
    Local $aResult[3] = [False, "", ""]

    ; Read local version
    Local $sVersionFile = $a_sDllDir & "\maps.version"
    Local $sLocalVersion = ""
    If FileExists($sVersionFile) Then
        $sLocalVersion = StringStripWS(FileRead($sVersionFile), 3)
    EndIf
    If $g_bPathfinder_Debug Then Out("[Pathfinder] Local maps version: '" & $sLocalVersion & "'")

    ; Fetch latest release from GitHub API
    Local $sApiURL = "https://api.github.com/repos/" & $g_sPathfinder_MapsRepo & "/releases/latest"
    If $g_bPathfinder_Debug Then Out("[Pathfinder] Fetching: " & $sApiURL)

    Local $sJson = BinaryToString(InetRead($sApiURL, 1))
    If @error Or $sJson = "" Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder] ERROR: Failed to fetch release info from GitHub")
        Return $aResult
    EndIf

    ; Parse tag_name from JSON
    Local $aTagMatch = StringRegExp($sJson, '"tag_name"\s*:\s*"([^"]+)"', 1)
    If @error Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder] ERROR: Could not parse tag_name from API response")
        Return $aResult
    EndIf
    Local $sRemoteVersion = $aTagMatch[0]
    If $g_bPathfinder_Debug Then Out("[Pathfinder] Remote maps version: '" & $sRemoteVersion & "'")

    ; Parse browser_download_url for maps.rar asset
    Local $aUrlMatch = StringRegExp($sJson, '"browser_download_url"\s*:\s*"([^"]*maps\.rar[^"]*)"', 1)
    If @error Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder] ERROR: Could not find maps.rar asset in release")
        Return $aResult
    EndIf
    Local $sDownloadURL = $aUrlMatch[0]
    If $g_bPathfinder_Debug Then Out("[Pathfinder] Download URL: " & $sDownloadURL)

    ; Compare versions
    If $sLocalVersion = $sRemoteVersion Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder] Maps are up to date")
        Return $aResult
    EndIf

    If $g_bPathfinder_Debug Then Out("[Pathfinder] Map update available: '" & $sLocalVersion & "' -> '" & $sRemoteVersion & "'")
    $aResult[0] = True
    $aResult[1] = $sDownloadURL
    $aResult[2] = $sRemoteVersion
    Return $aResult
EndFunc

Func Pathfinder_Shutdown()
    If $g_hPathfinderDLL <> 0 And $g_hPathfinderDLL <> -1 Then
        DllCall($g_hPathfinderDLL, "none:cdecl", "Shutdown")
        DllClose($g_hPathfinderDLL)
        $g_hPathfinderDLL = 0
    EndIf
EndFunc

Func Pathfinder_FreePathResult($pResult)
    If $pResult = 0 Or $pResult = Null Then Return
    If $g_hPathfinderDLL = 0 Or $g_hPathfinderDLL = -1 Then Return
    DllCall($g_hPathfinderDLL, "none:cdecl", "FreePathResult", "ptr", $pResult)
EndFunc

; Find a path with obstacle avoidance (Raw version - returns pointer)
; $aObstacles = 2D array [[x, y, radius], [x, y, radius], ...]
; $startLayer = layer of the starting point (-1 = auto-detect)
Func Pathfinder_FindPathRaw($mapID, $instanceType, $startX, $startY, $startLayer, $destX, $destY, $destLayer = -1, $aObstacles = 0, $simplifyRange = 1250, $clearanceWeight = 0.0)
    ; Verify DLL is loaded
    If $g_hPathfinderDLL = 0 Or $g_hPathfinderDLL = -1 Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder DLL] ERROR: DLL not loaded" & @CRLF)
        Return SetError(1, 0, 0)
    EndIf

    Local $obstacleCount = 0
    Local $pObstacles = 0

    ; Check if obstacles are provided and have valid format (2D array with 3 columns)
    If IsArray($aObstacles) And UBound($aObstacles) > 0 Then
        ; Validate array format: must be 2D with at least 3 columns
        If UBound($aObstacles, 0) = 2 And UBound($aObstacles, 2) >= 3 Then
            $obstacleCount = UBound($aObstacles)

            ; Create a contiguous array of ObstacleZone structures in memory
            ; Each ObstacleZone is 12 bytes (3 floats: x, y, radius)
            Local $obstacleStructSize = 12
            Local $obstacleBuffer = DllStructCreate("byte[" & ($obstacleCount * $obstacleStructSize) & "]")
            $pObstacles = DllStructGetPtr($obstacleBuffer)

            ; Fill the obstacle buffer
            For $i = 0 To $obstacleCount - 1
                Local $obstacle = DllStructCreate($tagObstacleZone, $pObstacles + $i * $obstacleStructSize)
                DllStructSetData($obstacle, "x", $aObstacles[$i][0])
                DllStructSetData($obstacle, "y", $aObstacles[$i][1])
                DllStructSetData($obstacle, "radius", $aObstacles[$i][2])
            Next
        Else
            ; Invalid format - ignore obstacles to prevent crash
            If $g_bPathfinder_Debug Then Out("[Pathfinder DLL] WARNING: Invalid obstacle array format, ignoring obstacles" & @CRLF)
        EndIf
    EndIf

    ; Call FindPathWithObstacles
    Local $result = DllCall($g_hPathfinderDLL, "ptr:cdecl", "FindPathWithObstacles", _
        "int", $mapID, _
        "int", $instanceType, _
        "float", $startX, _
        "float", $startY, _
        "int", $startLayer, _
        "float", $destX, _
        "float", $destY, _
        "int", $destLayer, _
        "ptr", $pObstacles, _
        "int", $obstacleCount, _
        "float", $simplifyRange, _
        "float", $clearanceWeight)

    If @error Then
        Return SetError(1, 0, 0)
    EndIf

    Return $result[0]
EndFunc

; Find a path with obstacle avoidance (returns 2D array of coordinates)
; $aObstacles = 2D array [[x, y, radius], [x, y, radius], ...]
; $startLayer = layer of the starting point (-1 = auto-detect)
Func Pathfinder_FindPath($mapID, $instanceType, $startX, $startY, $startLayer, $destX, $destY, $destLayer = -1, $aObstacles = 0, $simplifyRange = 1250, $clearanceWeight = 0.0)
    Local $l_p_Result = Pathfinder_FindPathRaw($mapID, $instanceType, $startX, $startY, $startLayer, $destX, $destY, $destLayer, $aObstacles, $simplifyRange, $clearanceWeight)

    If $l_p_Result = 0 Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder DLL] ERROR: DllCall returned null pointer" & @CRLF)
        Return SetError(1, 0, 0)
    EndIf

    Local $l_t_Result = DllStructCreate($tagPathResult, $l_p_Result)
    Local $l_i_ErrorCode = DllStructGetData($l_t_Result, "error_code")

    If $l_i_ErrorCode <> 0 Then
        Local $l_s_ErrorMsg = DllStructGetData($l_t_Result, "error_message")
        If $g_bPathfinder_Debug Then Out("[Pathfinder DLL] ERROR code=" & $l_i_ErrorCode & " msg=" & $l_s_ErrorMsg & @CRLF)
        Pathfinder_FreePathResult($l_p_Result)
        Return SetError(2, $l_i_ErrorCode, 0)
    EndIf

    Local $l_i_PointCount = DllStructGetData($l_t_Result, "point_count")
    Local $l_p_Points = DllStructGetData($l_t_Result, "points")

    If $g_bPathfinder_Debug Then Out("[Pathfinder DLL] OK: point_count=" & $l_i_PointCount & @CRLF)

    ; Validate point count and pointer
    If $l_i_PointCount <= 0 Or $l_p_Points = 0 Or $l_p_Points = Null Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder DLL] ERROR: Invalid point data" & @CRLF)
        Pathfinder_FreePathResult($l_p_Result)
        Return SetError(3, 0, 0)
    EndIf

    ; Limit point count to prevent memory issues (max 10000 points)
    If $l_i_PointCount > 10000 Then
        If $g_bPathfinder_Debug Then Out("[Pathfinder DLL] WARNING: Point count too high, limiting to 10000" & @CRLF)
        $l_i_PointCount = 10000
    EndIf

    Local $a_Path[$l_i_PointCount][4]  ; x, y, layer, tp_type
    For $i = 0 To $l_i_PointCount - 1
        Local $l_t_Point = DllStructCreate($tagPathPoint, $l_p_Points + ($i * 16))  ; 16 bytes: float x (4) + float y (4) + int layer (4) + int tp_type (4)
        $a_Path[$i][0] = DllStructGetData($l_t_Point, "x")
        $a_Path[$i][1] = DllStructGetData($l_t_Point, "y")
        $a_Path[$i][2] = DllStructGetData($l_t_Point, "layer")
        $a_Path[$i][3] = DllStructGetData($l_t_Point, "tp_type")
    Next

    Pathfinder_FreePathResult($l_p_Result)

    Return $a_Path
EndFunc

Func Pathfinder_IsMapAvailable($mapID, $instanceType = -1)
    If $g_hPathfinderDLL = 0 Or $g_hPathfinderDLL = -1 Then Return False
    Local $result = DllCall($g_hPathfinderDLL, "int:cdecl", "IsMapAvailable", "int", $mapID, "int", $instanceType)
    If @error Then Return False
    Return $result[0] = 1
EndFunc

Func Pathfinder_GetAvailableMaps()
    If $g_hPathfinderDLL = 0 Or $g_hPathfinderDLL = -1 Then Return SetError(1, 0, 0)

    Local $count = 0
    Local $result = DllCall($g_hPathfinderDLL, "ptr:cdecl", "GetAvailableMaps", "int*", $count)
    If @error Or $result[0] = 0 Then
        Return SetError(1, 0, 0)
    EndIf

    Local $pMapList = $result[0]
    $count = $result[1]

    ; Validate count
    If $count <= 0 Or $count > 10000 Then
        DllCall($g_hPathfinderDLL, "none:cdecl", "FreeMapList", "ptr", $pMapList)
        Return SetError(2, 0, 0)
    EndIf

    Local $mapIds[$count]
    For $i = 0 To $count - 1
        $mapIds[$i] = DllStructGetData(DllStructCreate("int", $pMapList + $i * 4), 1)
    Next

    DllCall($g_hPathfinderDLL, "none:cdecl", "FreeMapList", "ptr", $pMapList)

    Return $mapIds
EndFunc

Func Pathfinder_GetMapStats($mapID, $instanceType = -1)
    If $g_hPathfinderDLL = 0 Or $g_hPathfinderDLL = -1 Then Return SetError(1, 0, 0)

    Local $result = DllCall($g_hPathfinderDLL, "ptr:cdecl", "GetMapStats", "int", $mapID, "int", $instanceType)
    If @error Or $result[0] = 0 Then
        Return SetError(1, 0, 0)
    EndIf

    Local $pStats = $result[0]
    Local $stats = DllStructCreate($tagMapStats, $pStats)

    Local $statsArray[7]
    $statsArray[0] = DllStructGetData($stats, "trapezoid_count")
    $statsArray[1] = DllStructGetData($stats, "point_count")
    $statsArray[2] = DllStructGetData($stats, "teleport_count")
    $statsArray[3] = DllStructGetData($stats, "travel_portal_count")
    $statsArray[4] = DllStructGetData($stats, "npc_travel_count")
    $statsArray[5] = DllStructGetData($stats, "enter_travel_count")
    $statsArray[6] = DllStructGetData($stats, "error_code")

    DllCall($g_hPathfinderDLL, "none:cdecl", "FreeMapStats", "ptr", $pStats)

    Return $statsArray
EndFunc
