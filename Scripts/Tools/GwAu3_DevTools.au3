#RequireAdmin
#include "../../API/_GwAu3.au3"
#include "../../Utilities/ImGui/ImGui.au3"
#include "../../Utilities/ImGui/ImGui_Utils.au3"

$g_b_DevMode = True

Global Const $doLoadLoggedChars = True

Opt("GUIOnEventMode", False)
Opt("GUICloseOnESC", False)
Opt("ExpandVarStrings", 1)

#Region Declarations
Global $s_GUI_Status = "Ready"
Global $b_GUI_CheckBox_GUI_DebugMode = True
Global $b_GUI_CheckBox_OnTop = True
Global $b_GUI_BotRunning = False
Global $i_Number_CharName = 0
Global $Selected_Char = ""
Global $s_GUI_Script_Name = "GwAu3 DevTools"

; Core state
Global $g_s_MainCharName = ""
Global $ProcessID = ""
Global $Bot_Core_Initialized = False

; Character list
Global $g_aCharNames[1] = ["Select Character..."]

; Tab selection
Global $g_iCurrentTab = 0
Global $g_aTabNames[3] = ["Queue Commands", "Header Commands", "Data Functions"]

; Event flags
Global $g_b_Event_StartBot = False
Global $g_b_Event_StopBot = False
Global $g_b_Event_RefreshChars = False
Global $g_b_Event_ClearConsole = False
Global $g_b_Event_CopyConsole = False
Global $g_b_Event_Exit = False
Global $g_b_Event_ToggleDebug = False
Global $g_b_Event_ToggleOnTop = False
Global $g_b_Event_CharacterSelected = False
Global $g_i_Event_SelectedCharIndex = 0

; Input fields for commands
Global $g_sInput_X = "0"
Global $g_sInput_Y = "0"
Global $g_sInput_SkillSlot = "1"
Global $g_sInput_TargetID = "-2"
Global $g_sInput_MapID = "148"
Global $g_sInput_Message = "Test message"
Global $g_sInput_Channel = "!"
Global $g_sInput_HeroIndex = "1"
Global $g_sInput_AgentID = "0"
Global $g_sInput_ItemID = "0"
Global $g_sInput_DialogID = "0"
Global $g_sInput_AttributeID = "0"
Global $g_sInput_AttributeAmount = "1"
Global $g_sInput_ProfessionID = "1"
Global $g_sInput_FriendName = ""
Global $g_sInput_FriendAlias = ""
Global $g_sInput_GuildName = ""
Global $g_sInput_QuestID = "0"
Global $g_sInput_TitleID = "0"
Global $g_sInput_GoldAmount = "0"
Global $g_sInput_BagNumber = "1"
Global $g_sInput_SlotNumber = "1"
Global $g_sInput_Quantity = "1"
Global $g_sInput_WeaponSet = "1"
Global $g_sInput_SkillID = "0"
Global $g_iInput_AccountSkillID = 1
Global $g_iInput_SkillID = 1
Global $g_sInput_BuffID = "0"
Global $g_sInput_District = "0"
Global $g_sInput_ControlAction = "0x80"
Global $g_sInput_SkillTemplate = ""

; Quick Test tab variables
Global $g_sQuickTest_Input1 = ""
Global $g_sQuickTest_Input2 = ""
Global $g_sQuickTest_Input3 = ""
Global $g_sQuickTest_Input4 = ""
Global $g_sQuickTest_Input5 = ""
Global $g_iQuickTest_Int1 = 0
Global $g_iQuickTest_Int2 = 0
Global $g_iQuickTest_Int3 = 0
Global $g_fQuickTest_Float1 = 0.0
Global $g_fQuickTest_Float2 = 0.0
Global $g_bQuickTest_Check1 = False
Global $g_bQuickTest_Check2 = False
Global $g_bQuickTest_Check3 = False
Global $g_bQuickTest_Check4 = False
Global $g_bQuickTest_Check5 = False
Global $g_bQuickTest_Check6 = False
Global $g_iQuickTest_Radio1 = 0
Global $g_iQuickTest_Radio2 = 0
Global $g_iQuickTest_Combo1 = 0
Global $g_iQuickTest_Combo2 = 0
Global $g_aQuickTest_ComboItems1[5] = ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"]
Global $g_aQuickTest_ComboItems2[5] = ["Item A", "Item B", "Item C", "Item D", "Item E"]
Global $g_iQuickTest_Slider1 = 50
Global $g_iQuickTest_Slider2 = 0
Global $g_fQuickTest_SliderF1 = 0.5
Global $g_sQuickTest_Color1 = 0xFF0000
Global $g_sQuickTest_Color2 = 0x00FF00

Log_SetCallback(_LogCallback)
#EndRegion Declarations

_ImGui_EnableViewports()
_ImGui_GUICreate($s_GUI_Script_Name, 100, 100)
_ImGui_StyleColorsDark()
_ImGui_SetWindowTitleAlign(0.5, 0.5)
_ImGui_EnableDocking()

TraySetToolTip($s_GUI_Script_Name)

RefreshCharacterList()

Log_Message("GwAu3 DevTools Started", $c_UTILS_Msg_Type_Info, "Init")
Log_Message("Tool for testing GwAu3 API commands", $c_UTILS_Msg_Type_Info, "Init")
Log_Message("GwAu3 v" & $GC_S_VERSION & " by " & $GC_S_UPDATOR, $c_UTILS_Msg_Type_Info, "Init")

AdlibRegister("_GUI_Handle", 30)
AdlibRegister("ProcessEvents", 30)

While 1
    Sleep(10)
    If $g_b_Event_Exit Then _GUI_ExitApp()
WEnd

_GUI_ExitApp()

Func ProcessEvents()
    If $g_b_Event_Exit Then _GUI_ExitApp()

    If $g_b_Event_StartBot Then
        $g_b_Event_StartBot = False
        StartBot()
    EndIf

    If $g_b_Event_StopBot Then
        $g_b_Event_StopBot = False
        StopBot()
    EndIf

    If $g_b_Event_RefreshChars Then
        $g_b_Event_RefreshChars = False
        RefreshCharacterList()
    EndIf

    If $g_b_Event_ClearConsole Then
        $g_b_Event_ClearConsole = False
        ReDim $a_UTILS_Log_Messages[0][8]
        Log_Message("Console cleared", $c_UTILS_Msg_Type_Info, "GUI")
    EndIf

    If $g_b_Event_CopyConsole Then
        $g_b_Event_CopyConsole = False
        _GUI_CopyConsoleToClipboard()
    EndIf

    If $g_b_Event_ToggleDebug Then
        $g_b_Event_ToggleDebug = False
        $b_GUI_CheckBox_GUI_DebugMode = Not $b_GUI_CheckBox_GUI_DebugMode
        Log_SetDebugMode($b_GUI_CheckBox_GUI_DebugMode)
        Log_Message("Debug mode: " & ($b_GUI_CheckBox_GUI_DebugMode ? "Enabled" : "Disabled"), $c_UTILS_Msg_Type_Info, "GUI")
    EndIf

    If $g_b_Event_ToggleOnTop Then
        $g_b_Event_ToggleOnTop = False
        $b_GUI_CheckBox_OnTop = Not $b_GUI_CheckBox_OnTop
        Log_Message("Always on top: " & ($b_GUI_CheckBox_OnTop ? "Enabled" : "Disabled"), $c_UTILS_Msg_Type_Info, "GUI")
    EndIf

    If $g_b_Event_CharacterSelected Then
        $g_b_Event_CharacterSelected = False
        If $g_i_Event_SelectedCharIndex > 0 And $g_i_Event_SelectedCharIndex <= UBound($g_aCharNames) - 1 Then
            $i_Number_CharName = $g_i_Event_SelectedCharIndex
            $Selected_Char = $g_aCharNames[$g_i_Event_SelectedCharIndex]
            $g_s_MainCharName = $Selected_Char
            Log_Message("Selected character: " & $Selected_Char, $c_UTILS_Msg_Type_Info, "GUI")
        EndIf
    EndIf
EndFunc

Func _GUI_Handle()
    If Not _ImGui_PeekMsg() Then
        $g_b_Event_Exit = True
        Return
    EndIf

    _ImGui_BeginFrame()

    ; Window is now resizable (removed AlwaysAutoResize flag)
    _ImGui_SetNextWindowSize(850, 550, $ImGuiCond_FirstUseEver)
    If Not _ImGui_Begin($s_GUI_Script_Name, True, $ImGuiWindowFlags_MenuBar) Then
        $g_b_Event_Exit = True
        Return
    EndIf

    _GUI_MenuBar()

    ; Get available content region size for dynamic layout
    Local $aWindowSize = _ImGui_GetContentRegionAvail()
    Local $fPanelHeight = $aWindowSize[1] - 50

    ; Use ImGui Columns for automatic splitter with proper cursor handling
    If $b_GUI_CheckBox_GUI_DebugMode Then
        _ImGui_Columns(2, "MainColumns", True)
    EndIf

    ; Left column - Commands
    _ImGui_BeginChild("LeftPanel", -1, $fPanelHeight, False)

    ; Connection status section
    If $Bot_Core_Initialized Then
        _ImGui_TextColored("Connected: " & player_GetCharname(), 0xFF00FF00)
        _ImGui_SameLine()
        If _ImGui_Button("Disconnect", 100, 25) Then
            $g_b_Event_StopBot = True
        EndIf
    Else
        _ImGui_TextColored("Not Connected", 0xFFFF0000)

        _ImGui_Text("Select Character:")
        _ImGui_Indent(1)
        _ImGui_BeginChild("CharList", -1, 150, True)
        For $i = 1 To UBound($g_aCharNames) - 1
            Local $selected = ($i_Number_CharName == $i)
            If _ImGui_Selectable($g_aCharNames[$i], $selected) Then
                $g_i_Event_SelectedCharIndex = $i
                $g_b_Event_CharacterSelected = True
            EndIf
        Next
        _ImGui_EndChild()
        _ImGui_Unindent(1)

        If _ImGui_Button("Connect", 100, 25) Then
            $g_b_Event_StartBot = True
        EndIf
		_ImGui_SameLine()
		If _ImGui_Button("Refresh", 100, 25) Then
            $g_b_Event_RefreshChars = True
        EndIf
    EndIf

    _ImGui_Separator()
    _ImGui_NewLine()

    ; Commands Section (only if connected)
    If $Bot_Core_Initialized Then
        ; Tab bar
        If _ImGui_BeginTabBar("CommandTabs") Then
            If _ImGui_BeginTabItem("Queue Commands") Then
                _GUI_Tab_QueueCommands()
                _ImGui_EndTabItem()
            EndIf
            If _ImGui_BeginTabItem("Header Commands") Then
                _GUI_Tab_HeaderCommands()
                _ImGui_EndTabItem()
            EndIf
            If _ImGui_BeginTabItem("ControlAction") Then
                _GUI_Tab_ControlAction()
                _ImGui_EndTabItem()
            EndIf
            If _ImGui_BeginTabItem("Data Functions") Then
                _GUI_Tab_DataFunctions()
                _ImGui_EndTabItem()
            EndIf
            If _ImGui_BeginTabItem("Quick Test") Then
                _GUI_Tab_QuickTest()
                _ImGui_EndTabItem()
            EndIf
            _ImGui_EndTabBar()
        EndIf
    Else
        _ImGui_TextColored("Connect to a character to access commands", 0xFFAAAAAA)
    EndIf

    _ImGui_EndChild()

    ; Right column - Debug Console
    If $b_GUI_CheckBox_GUI_DebugMode Then
        _ImGui_NextColumn()

        _GUI_AddOns_LogConsole()

        _ImGui_Columns(1) ; End columns
    EndIf

    _ImGui_End()
    _ImGui_EndFrame()
EndFunc

#Region Tab Functions
Func _GUI_Tab_QueueCommands()
    _ImGui_TextColored("Queue Commands (Core_Enqueue)", 0xFF00FFFF)
    _ImGui_Text("These functions use DLL structures and Core_Enqueue()")
	_ImGui_NewLine()
    _ImGui_Separator()

    ; === Account ===
    If _ImGui_CollapsingHeader("Account##q") Then
        _ImGui_TextColored("No Queue functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Agent ===
    If _ImGui_CollapsingHeader("Agent##q") Then
        _ImGui_Text("Agent_ChangeTarget - Change current target")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Usage: Agent_ChangeTarget($agentID)" & @CRLF & "Use -2 for self, -1 for current target")
        _ImGui_PushItemWidth(100)
        _ImGui_InputText("Agent ID##qtarget", $g_sInput_AgentID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Change Target##q") Then
            Agent_ChangeTarget(Number($g_sInput_AgentID))
            Log_Message("Agent_ChangeTarget(" & $g_sInput_AgentID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Nearest Enemy##q") Then
            Log_Message("Agent_TargetNearestEnemy() = " & Agent_TargetNearestEnemy(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Nearest Ally##q") Then
            Log_Message("Agent_TargetNearestAlly() = " & Agent_TargetNearestAlly(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Self##q") Then
            Agent_TargetSelf()
            Log_Message("Agent_TargetSelf()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Clear##q") Then
            Agent_ClearTarget()
            Log_Message("Agent_ClearTarget()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Attribute ===
    If _ImGui_CollapsingHeader("Attribute##q") Then
        _ImGui_Text("Attribute_IncreaseAttribute / DecreaseAttribute")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Attribute IDs: 0-44" & @CRLF & "Amount: 1-12 points")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Attr ID##qattr", $g_sInput_AttributeID)
        _ImGui_SameLine()
        _ImGui_InputText("Amount##qattr", $g_sInput_AttributeAmount)
        _ImGui_SameLine()
        _ImGui_InputText("Hero##qattr", $g_sInput_HeroIndex)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Increase##qattr") Then
            Attribute_IncreaseAttribute(Number($g_sInput_AttributeID), Number($g_sInput_AttributeAmount), Number($g_sInput_HeroIndex))
            Log_Message("Attribute_IncreaseAttribute(" & $g_sInput_AttributeID & ", " & $g_sInput_AttributeAmount & ", " & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Decrease##qattr") Then
            Attribute_DecreaseAttribute(Number($g_sInput_AttributeID), Number($g_sInput_AttributeAmount), Number($g_sInput_HeroIndex))
            Log_Message("Attribute_DecreaseAttribute(" & $g_sInput_AttributeID & ", " & $g_sInput_AttributeAmount & ", " & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_NewLine()
		_ImGui_PushItemWidth(160)
		_ImGui_InputText("Skill Template##qattr", $g_sInput_SkillTemplate)
		_ImGui_PopItemWidth()
		_ImGui_SameLine()
		_ImGui_PushItemWidth(80)
		_ImGui_InputText("Hero##qattr", $g_sInput_HeroIndex)
		_ImGui_PopItemWidth()
		If _ImGui_Button("Load##qattr") Then
            Attribute_LoadSkillTemplate($g_sInput_SkillTemplate, Number($g_sInput_HeroIndex))
            Log_Message("Attribute_LoadSkillTemplate(" & $g_sInput_SkillTemplate & ", " & Number($g_sInput_HeroIndex), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Camera ===
    If _ImGui_CollapsingHeader("Camera##q") Then
        _ImGui_TextColored("No Queue functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Chat ===
    If _ImGui_CollapsingHeader("Chat##q") Then
        _ImGui_Text("Chat_SendChat - Send message to chat")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Channels: ! = All, @ = Guild, # = Team, $ = Trade, % = Alliance")
        _ImGui_PushItemWidth(200)
        _ImGui_InputText("Message##qchat", $g_sInput_Message)
        _ImGui_PopItemWidth()
        _ImGui_PushItemWidth(50)
        _ImGui_InputText("Ch##qchat", $g_sInput_Channel)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Send##qchat") Then
            Chat_SendChat($g_sInput_Message, $g_sInput_Channel)
            Log_Message("Chat_SendChat('" & $g_sInput_Message & "', '" & $g_sInput_Channel & "')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_NewLine()
        _ImGui_Text("Quick Channels:")
        If _ImGui_Button("All (!)##qch") Then
            Chat_SendChat($g_sInput_Message, "!")
            Log_Message("Chat_SendChat('" & $g_sInput_Message & "', '!')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Guild (@)##qch") Then
            Chat_SendChat($g_sInput_Message, "@")
            Log_Message("Chat_SendChat('" & $g_sInput_Message & "', '@')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Team (#)##qch") Then
            Chat_SendChat($g_sInput_Message, "#")
            Log_Message("Chat_SendChat('" & $g_sInput_Message & "', '#')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Trade ($)##qch") Then
            Chat_SendChat($g_sInput_Message, "$")
            Log_Message("Chat_SendChat('" & $g_sInput_Message & "', '$')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Alliance (%)##qch") Then
            Chat_SendChat($g_sInput_Message, "%")
            Log_Message("Chat_SendChat('" & $g_sInput_Message & "', '%')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Chat_SendWhisper - Send whisper")
        _ImGui_PushItemWidth(120)
        _ImGui_InputText("Receiver##qwhisp", $g_sInput_FriendName)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Whisper##q") Then
            Chat_SendWhisper($g_sInput_FriendName, $g_sInput_Message)
            Log_Message("Chat_SendWhisper('" & $g_sInput_FriendName & "', '" & $g_sInput_Message & "')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Chat_WriteChat - Local message (bot only)")
        If _ImGui_Button("Write Local##q") Then
            Chat_WriteChat($g_sInput_Message, "DevTools")
            Log_Message("Chat_WriteChat('" & $g_sInput_Message & "', 'DevTools')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
    EndIf

    ; === Cinematic ===
    If _ImGui_CollapsingHeader("Cinematic##q") Then
        _ImGui_TextColored("No Queue functions (see Header)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Effect ===
    If _ImGui_CollapsingHeader("Effect##q") Then
        _ImGui_TextColored("No Queue functions (see Header)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Friend ===
    If _ImGui_CollapsingHeader("Friend##q") Then
        _ImGui_Text("Friend_SetPlayerStatus")
        If _ImGui_Button("Online##qfriend") Then
            Friend_SetPlayerStatus(1)
            Log_Message("Friend_SetPlayerStatus(1) ; Online", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("DND##qfriend") Then
            Friend_SetPlayerStatus(2)
            Log_Message("Friend_SetPlayerStatus(2) ; DND", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Away##qfriend") Then
            Friend_SetPlayerStatus(3)
            Log_Message("Friend_SetPlayerStatus(3) ; Away", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Offline##qfriend") Then
            Friend_SetPlayerStatus(0)
            Log_Message("Friend_SetPlayerStatus(0) ; Offline", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Friend_AddFriend / RemoveFriend")
        _ImGui_PushItemWidth(120)
        _ImGui_InputText("Name##qfriend", $g_sInput_FriendName)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Add Friend##q") Then
            Friend_AddFriend($g_sInput_FriendName, "", 1)
            Log_Message("Friend_AddFriend('" & $g_sInput_FriendName & "', '" & "', 1)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Ignore##qfriend") Then
            Log_Message("Friend_AddFriend('" & $g_sInput_FriendName & "', '" & "', 2)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Remove##qfriend") Then
            Friend_RemoveFriend($g_sInput_FriendName)
            Log_Message("Friend_RemoveFriend('" & $g_sInput_FriendName & "')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Game ===
    If _ImGui_CollapsingHeader("Game##q") Then
        _ImGui_TextColored("No Queue functions (see Header)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Guild ===
    If _ImGui_CollapsingHeader("Guild##q") Then
        _ImGui_Text("Guild_InviteGuild / Guild_InviteGuest")
        _ImGui_PushItemWidth(150)
        _ImGui_InputText("Character##qguild", $g_sInput_GuildName)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Invite to Guild##q") Then
            Guild_InviteGuild($g_sInput_GuildName)
            Log_Message("Guild_InviteGuild('" & $g_sInput_GuildName & "')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Invite as Guest##q") Then
            Guild_InviteGuest($g_sInput_GuildName)
            Log_Message("Guild_InviteGuest('" & $g_sInput_GuildName & "')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Item ===
    If _ImGui_CollapsingHeader("Item##q") Then
        _ImGui_Text("Item_SalvageItem")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Kit types: Standard, Superior, Expert, Perfect, Charr" & @CRLF & "Salvage types: Materials, Prefix, Suffix, Inscription")
        _ImGui_PushItemWidth(80)
        _ImGui_InputInt("Bag##qsalv", $g_sInput_BagNumber)
		_ImGui_SameLine()
		_ImGui_InputInt("Slot##qsalv", $g_sInput_SlotNumber)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Salvage Mats##q") Then
            Item_SalvageItem(Item_GetItemBySlot($g_sInput_BagNumber, $g_sInput_SlotNumber), "Expert", "Materials")
            Log_Message("Item_SalvageItem(Item_GetItemBySlot(" & $g_sInput_BagNumber & ", " & $g_sInput_SlotNumber & ", 'Expert', 'Materials')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Salvage Prefix##q") Then
            Item_SalvageItem(Item_GetItemBySlot($g_sInput_BagNumber, $g_sInput_SlotNumber), "Expert", "Prefix")
            Log_Message("Item_SalvageItem(Item_GetItemBySlot(" & $g_sInput_BagNumber & ", " & $g_sInput_SlotNumber & ", 'Expert', 'Prefix')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Salvage Suffix##q") Then
            Item_SalvageItem(Item_GetItemBySlot($g_sInput_BagNumber, $g_sInput_SlotNumber), "Expert", "Suffix")
            Log_Message("Item_SalvageItem(Item_GetItemBySlot(" & $g_sInput_BagNumber & ", " & $g_sInput_SlotNumber & ", 'Suffix')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Map ===
    If _ImGui_CollapsingHeader("Map##q") Then
        _ImGui_Text("Map_Move - Move to coordinates")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Usage: Map_Move($x, $y, $randomize=50)")
        _ImGui_PushItemWidth(100)
        _ImGui_InputText("X##qmove", $g_sInput_X)
        _ImGui_SameLine()
        _ImGui_InputText("Y##qmove", $g_sInput_Y)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Move##qbtn") Then
            Map_Move(Number($g_sInput_X), Number($g_sInput_Y), 0)
            Log_Message("Map_Move(" & $g_sInput_X & ", " & $g_sInput_Y & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Match ===
    If _ImGui_CollapsingHeader("Match##q") Then
        _ImGui_TextColored("No Queue functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Merchant ===
    If _ImGui_CollapsingHeader("Merchant##q") Then
        _ImGui_Text("Merchant_BuyItem / SellItem")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Requires merchant dialog open" & @CRLF & "For traders, use Trader mode")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Model##qmerch", $g_sInput_ItemID)
        _ImGui_SameLine()
        _ImGui_InputText("Qty##qmerch", $g_sInput_Quantity)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Buy##qmerch") Then
            Merchant_BuyItem(Number($g_sInput_ItemID), Number($g_sInput_Quantity))
            Log_Message("Merchant_BuyItem(" & $g_sInput_ItemID & ", " & $g_sInput_Quantity & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Buy (Trader)##qmerch") Then
            Merchant_BuyItem(Number($g_sInput_ItemID), Number($g_sInput_Quantity), True)
            Log_Message("Merchant_BuyItem(" & $g_sInput_ItemID & ", " & $g_sInput_Quantity & ", True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Sell##qmerch") Then
            Merchant_SellItem(Number($g_sInput_ItemID), Number($g_sInput_Quantity), False)
            Log_Message("Merchant_SellItem(" & $g_sInput_ItemID & ", " & $g_sInput_Quantity & ", False)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Sell (Trader)##qmerch") Then
            Merchant_SellItem(Number($g_sInput_ItemID), Number($g_sInput_Quantity), True)
            Log_Message("Merchant_SellItem(" & $g_sInput_ItemID & ", " & $g_sInput_Quantity & ", True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
        _ImGui_Text("Merchant_CollectorExchange")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Exchange items with collector NPC" & @CRLF & "Recv = Item to receive, Give = Item to give, Qty = Amount required")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("Recv##qcoll", $g_sInput_ItemID)
        _ImGui_SameLine()
        _ImGui_InputText("Give##qcoll", $g_sInput_SkillID)
        _ImGui_SameLine()
        _ImGui_InputText("Qty##qcoll", $g_sInput_Quantity)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Exchange##qcoll") Then
            Merchant_CollectorExchange(Number($g_sInput_ItemID), Number($g_sInput_Quantity), Number($g_sInput_SkillID))
            Log_Message("Merchant_CollectorExchange(" & $g_sInput_ItemID & ", " & $g_sInput_Quantity & ", " & $g_sInput_SkillID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_TextColored("Note: CraftItem requires material array - use code directly", 0xFF888888)
    EndIf

    ; === Other ===
    If _ImGui_CollapsingHeader("Other##q") Then
        _ImGui_TextColored("No Queue functions (utility only)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Party ===
    If _ImGui_CollapsingHeader("Party##q") Then
        _ImGui_TextColored("No Queue functions (see Header)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Path ===
    If _ImGui_CollapsingHeader("Path##q") Then
        _ImGui_TextColored("No Queue functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Player ===
    If _ImGui_CollapsingHeader("Player##q") Then
        _ImGui_TextColored("No Queue functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === PreGame ===
    If _ImGui_CollapsingHeader("PreGame##q") Then
        _ImGui_TextColored("No Queue functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Quest ===
    If _ImGui_CollapsingHeader("Quest##q") Then
        _ImGui_TextColored("No Queue functions (see Header)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Skill ===
    If _ImGui_CollapsingHeader("Skill##q") Then
        _ImGui_Text("Skill_UseSkill - Use a skill from skillbar")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Slot: 1-8, Target: -2=self, -1=current, or agent ID")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Slot##qskill", $g_sInput_SkillSlot)
        _ImGui_SameLine()
        _ImGui_InputText("Target##qskill", $g_sInput_TargetID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Use##qskill") Then
            Skill_UseSkill(Number($g_sInput_SkillSlot), Number($g_sInput_TargetID))
            Log_Message("Skill_UseSkill(" & $g_sInput_SkillSlot & ", " & $g_sInput_TargetID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Text("Quick Use (self):")
        For $i = 1 To 8
            If $i > 1 Then _ImGui_SameLine()
            If _ImGui_Button(String($i) & "##qqskill" & $i, 30, 25) Then
                Skill_UseSkill($i)
                Log_Message("Skill_UseSkill(" & $i & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            EndIf
        Next
        _ImGui_NewLine()
        _ImGui_Text("Skill_UseHeroSkill - Use hero skill")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("Hero##qhskill", $g_sInput_HeroIndex)
        _ImGui_SameLine()
        _ImGui_InputText("Slot##qhskill", $g_sInput_SkillSlot)
        _ImGui_SameLine()
        _ImGui_InputText("Target##qhskill", $g_sInput_TargetID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Use Hero##qhskill") Then
            Skill_UseHeroSkill(Number($g_sInput_HeroIndex), Number($g_sInput_SkillSlot), Number($g_sInput_TargetID))
            Log_Message("Skill_UseHeroSkill(" & $g_sInput_HeroIndex & ", " & $g_sInput_SkillSlot & ", " & $g_sInput_TargetID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Cancel Hero Skill##q") Then
            Skill_CancelHeroSkill(Number($g_sInput_HeroIndex), Number($g_sInput_SkillSlot))
            Log_Message("Skill_CancelHeroSkill(" & $g_sInput_HeroIndex & ", " & $g_sInput_SkillSlot & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Title ===
    If _ImGui_CollapsingHeader("Title##q") Then
        _ImGui_TextColored("No Queue functions (see Header)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Trade ===
    If _ImGui_CollapsingHeader("Trade##q") Then
        _ImGui_Text("Trade_InitiateTrade")
        _ImGui_PushItemWidth(100)
        _ImGui_InputText("Agent ID##qtrade", $g_sInput_AgentID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Initiate##qtrade") Then
            Trade_InitiateTrade(Number($g_sInput_AgentID))
            Log_Message("Trade_InitiateTrade(" & $g_sInput_AgentID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
        If _ImGui_Button("Cancel Trade##q") Then
            Trade_CancelTrade()
            Log_Message("Trade_CancelTrade()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Accept Trade##q") Then
            Trade_AcceptTrade()
            Log_Message("Trade_AcceptTrade()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
        _ImGui_Text("Trade_SubmitOffer / OfferItem")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Gold##qtradeoffer", $g_sInput_GoldAmount)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Submit Offer##q") Then
            Trade_SubmitOffer(Number($g_sInput_GoldAmount))
            Log_Message("Trade_SubmitOffer(" & $g_sInput_GoldAmount & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Item##qtradeitem", $g_sInput_ItemID)
        _ImGui_SameLine()
        _ImGui_InputText("Qty##qtradeitem", $g_sInput_Quantity)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Offer Item##q") Then
            Trade_OfferItem(Number($g_sInput_ItemID), Number($g_sInput_Quantity))
            Log_Message("Trade_OfferItem(" & $g_sInput_ItemID & ", " & $g_sInput_Quantity & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Ui ===
    If _ImGui_CollapsingHeader("Ui##q") Then
        _ImGui_Text("Ui_Dialog - Send dialog")
        _ImGui_PushItemWidth(100)
        _ImGui_InputText("Dialog ID##qdialog", $g_sInput_DialogID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Send##qdialog") Then
            Ui_Dialog(Number($g_sInput_DialogID))
            Log_Message("Ui_Dialog(" & $g_sInput_DialogID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_NewLine()
        _ImGui_Text("Ui_OpenChest")
        If _ImGui_Button("With Lockpick##q") Then
            Ui_OpenChest(True)
            Log_Message("Ui_OpenChest(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("With Key##q") Then
            Ui_OpenChest(False)
            Log_Message("Ui_OpenChest(False)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_NewLine()
        _ImGui_Text("Hero Flag Commands:")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("Hero##qhero", $g_sInput_HeroIndex)
        _ImGui_SameLine()
        _ImGui_InputText("X##qheroflag", $g_sInput_X)
        _ImGui_SameLine()
        _ImGui_InputText("Y##qheroflag", $g_sInput_Y)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Flag Hero##q") Then
            Ui_CommandHero(Number($g_sInput_HeroIndex), Number($g_sInput_X), Number($g_sInput_Y))
            Log_Message("Ui_CommandHero(" & $g_sInput_HeroIndex & ", " & $g_sInput_X & ", " & $g_sInput_Y & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Cancel Hero##q") Then
            Ui_CancelHero(Number($g_sInput_HeroIndex))
            Log_Message("Ui_CancelHero(" & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Flag All##q") Then
            Ui_CommandAll(Number($g_sInput_X), Number($g_sInput_Y))
            Log_Message("Ui_CommandAll(" & $g_sInput_X & ", " & $g_sInput_Y & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Cancel All##q") Then
            Ui_CancelAll()
            Log_Message("Ui_CancelAll()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_NewLine()
        _ImGui_Text("Ui_SetHeroBehavior (0=Fight, 1=Guard, 2=Avoid)")
        If _ImGui_Button("Fight##qbeh") Then
            Ui_SetHeroBehavior(Number($g_sInput_HeroIndex), 0)
            Log_Message("Ui_SetHeroBehavior(" & $g_sInput_HeroIndex & ", 0)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Guard##qbeh") Then
            Ui_SetHeroBehavior(Number($g_sInput_HeroIndex), 1)
            Log_Message("Ui_SetHeroBehavior(" & $g_sInput_HeroIndex & ", 1)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Avoid##qbeh") Then
            Ui_SetHeroBehavior(Number($g_sInput_HeroIndex), 2)
            Log_Message("Ui_SetHeroBehavior(" & $g_sInput_HeroIndex & ", 2)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_NewLine()
        _ImGui_Text("Hero Skill/Target Control:")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("Skill##quiskill", $g_sInput_SkillSlot)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Toggle Skill##q") Then
            Ui_ToggleHeroSkillState(Number($g_sInput_HeroIndex), Number($g_sInput_SkillSlot))
            Log_Message("Ui_ToggleHeroSkillState(" & $g_sInput_HeroIndex & ", " & $g_sInput_SkillSlot & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Enable##qskillstate") Then
            Ui_EnableHeroSkill(Number($g_sInput_HeroIndex), Number($g_sInput_SkillSlot))
            Log_Message("Ui_EnableHeroSkill(" & $g_sInput_HeroIndex & ", " & $g_sInput_SkillSlot & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Disable##qskillstate") Then
            Ui_DisableHeroSkill(Number($g_sInput_HeroIndex), Number($g_sInput_SkillSlot))
            Log_Message("Ui_DisableHeroSkill(" & $g_sInput_HeroIndex & ", " & $g_sInput_SkillSlot & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Target##quilock", $g_sInput_TargetID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Lock Target##q") Then
            Ui_LockHeroTarget(Number($g_sInput_HeroIndex), Number($g_sInput_TargetID))
            Log_Message("Ui_LockHeroTarget(" & $g_sInput_HeroIndex & ", " & $g_sInput_TargetID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Unlock##quilock") Then
            Ui_LockHeroTarget(Number($g_sInput_HeroIndex), 0)
            Log_Message("Ui_LockHeroTarget(" & $g_sInput_HeroIndex & ", 0)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Drop Bundle##q") Then
            Ui_DropHeroBundle(Number($g_sInput_HeroIndex))
            Log_Message("Ui_DropHeroBundle(" & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_NewLine()
        _ImGui_Text("Party Management:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Hero ID##quiparty", $g_sInput_HeroIndex)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Add Hero##qui") Then
            Ui_AddHero(Number($g_sInput_HeroIndex))
            Log_Message("Ui_AddHero(" & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Kick Hero##qui") Then
            Ui_KickHero(Number($g_sInput_HeroIndex))
            Log_Message("Ui_KickHero(" & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Kick All##qui") Then
            Ui_KickAllHeroes()
            Log_Message("Ui_KickAllHeroes()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("NPC ID##quinpc", $g_sInput_AgentID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Add NPC##qui") Then
            Ui_AddNPC(Number($g_sInput_AgentID))
            Log_Message("Ui_AddNPC(" & $g_sInput_AgentID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Kick NPC##qui") Then
            Ui_KickNPC(Number($g_sInput_AgentID))
            Log_Message("Ui_KickNPC(" & $g_sInput_AgentID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Leave Group##q") Then
            Ui_LeaveGroup(True)
            Log_Message("Ui_LeaveGroup(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_NewLine()
        _ImGui_Text("Difficulty / Challenge:")
        If _ImGui_Button("Normal Mode##q") Then
            Ui_SetDifficulty(False)
            Log_Message("Ui_SetDifficulty(False)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Hard Mode##q") Then
            Ui_SetDifficulty(True)
            Log_Message("Ui_SetDifficulty(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Enter Challenge##q") Then
            Ui_EnterChallenge(False, True)
            Log_Message("Ui_EnterChallenge(False, True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_NewLine()
        _ImGui_Text("Rendering:")
        If _ImGui_Button("Toggle Rendering##q") Then
            Ui_ToggleRendering()
            Log_Message("Ui_ToggleRendering()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Enable##qrender") Then
            Ui_EnableRendering()
            Log_Message("Ui_EnableRendering()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Disable##qrender") Then
            Ui_DisableRendering()
            Log_Message("Ui_DisableRendering()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Purge Hook (10s)##q") Then
            Ui_PurgeHook(10000)
            Log_Message("Ui_PurgeHook(10000)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === World ===
    If _ImGui_CollapsingHeader("World##q") Then
        _ImGui_TextColored("No Queue functions", 0xFF888888)
		_ImGui_Separator()
    EndIf
EndFunc

Func _GUI_Tab_HeaderCommands()
    _ImGui_TextColored("Header Commands (Core_SendPacket)", 0xFFFF00FF)
    _ImGui_Text("These functions use Core_SendPacket() with GC_I_HEADER_* constants")
	_ImGui_NewLine()
    _ImGui_Separator()

    ; === Account ===
    If _ImGui_CollapsingHeader("Account##h") Then
        _ImGui_TextColored("No Header functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Agent ===
    If _ImGui_CollapsingHeader("Agent##h") Then
        _ImGui_Text("Interaction Functions:")
;~         _ImGui_PushItemWidth(100)
;~         _ImGui_InputText("Agent ID##hinteract", $g_sInput_AgentID)
;~         _ImGui_PopItemWidth()
        If _ImGui_Button("Go NPC##h") Then
            Agent_GoNPC(Agent_GetCurrentTarget())
            Log_Message("Agent_GoNPC(" & Agent_GetCurrentTarget() & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Go Player##h") Then
            Agent_GoPlayer(Agent_GetCurrentTarget())
            Log_Message("Agent_GoPlayer(" & Agent_GetCurrentTarget() & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Signpost##h") Then
            Agent_GoSignpost(Agent_GetCurrentTarget())
            Log_Message("Agent_GoSignpost(" & Agent_GetCurrentTarget() & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Attack##h") Then
            Agent_Attack(Agent_GetCurrentTarget())
            Log_Message("Agent_Attack(" & Agent_GetCurrentTarget() & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Attack+Call##h") Then
            Agent_Attack(Agent_GetCurrentTarget(), True)
            Log_Message("Agent_Attack(" & Agent_GetCurrentTarget() & ", True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Call Target##h") Then
            Agent_CallTarget(Agent_GetCurrentTarget())
            Log_Message("Agent_CallTarget(" & Agent_GetCurrentTarget() & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Cancel Action##h") Then
            Agent_CancelAction()
            Log_Message("Agent_CancelAction()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Attribute ===
    If _ImGui_CollapsingHeader("Attribute##h") Then
        _ImGui_Text("Attribute_ChangeSecondProfession")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Profession IDs: 1=W, 2=R, 3=Mo, 4=N, 5=Me, 6=E, 7=A, 8=Rt, 9=P, 10=D")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Prof##hprof", $g_sInput_ProfessionID)
        _ImGui_SameLine()
        _ImGui_InputText("Hero##hprof", $g_sInput_HeroIndex)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Change##hprof") Then
            Attribute_ChangeSecondProfession(Number($g_sInput_ProfessionID), Number($g_sInput_HeroIndex))
            Log_Message("Attribute_ChangeSecondProfession(" & $g_sInput_ProfessionID & ", " & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_NewLine()
        _ImGui_Text("Quick (Player):")
        If _ImGui_Button("W##hprof") Then
            Attribute_ChangeSecondProfession(1, 0)
            Log_Message("Attribute_ChangeSecondProfession(1, 0) ; Warrior", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("R##hprof") Then
            Attribute_ChangeSecondProfession(2, 0)
            Log_Message("Attribute_ChangeSecondProfession(2, 0) ; Ranger", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Mo##hprof") Then
            Attribute_ChangeSecondProfession(3, 0)
            Log_Message("Attribute_ChangeSecondProfession(3, 0) ; Monk", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("N##hprof") Then
            Attribute_ChangeSecondProfession(4, 0)
            Log_Message("Attribute_ChangeSecondProfession(4, 0) ; Necro", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Me##hprof") Then
            Attribute_ChangeSecondProfession(5, 0)
            Log_Message("Attribute_ChangeSecondProfession(5, 0) ; Mesmer", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("E##hprof") Then
            Attribute_ChangeSecondProfession(6, 0)
            Log_Message("Attribute_ChangeSecondProfession(6, 0) ; Ele", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("A##hprof") Then
            Attribute_ChangeSecondProfession(7, 0)
            Log_Message("Attribute_ChangeSecondProfession(7, 0) ; Assassin", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Rt##hprof") Then
            Attribute_ChangeSecondProfession(8, 0)
            Log_Message("Attribute_ChangeSecondProfession(8, 0) ; Ritualist", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("P##hprof") Then
            Attribute_ChangeSecondProfession(9, 0)
            Log_Message("Attribute_ChangeSecondProfession(9, 0) ; Paragon", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("D##hprof") Then
            Attribute_ChangeSecondProfession(10, 0)
            Log_Message("Attribute_ChangeSecondProfession(10, 0) ; Dervish", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Camera ===
    If _ImGui_CollapsingHeader("Camera##h") Then
        _ImGui_TextColored("No Header functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Chat ===
    If _ImGui_CollapsingHeader("Chat##h") Then
        _ImGui_TextColored("No Header functions (uses direct memory)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Cinematic ===
    If _ImGui_CollapsingHeader("Cinematic##h") Then
        If _ImGui_Button("Skip Cinematic##h") Then
            Cinematic_SkipCinematic()
            Log_Message("Cinematic_SkipCinematic()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Effect ===
    If _ImGui_CollapsingHeader("Effect##h") Then
        _ImGui_Text("Effect_DropBond - Drop a buff by skill ID")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Skill##hbuff", $g_sInput_SkillID)
        _ImGui_SameLine()
        _ImGui_InputText("Agent##hbuff", $g_sInput_AgentID)
        _ImGui_SameLine()
        _ImGui_InputText("Hero##hbuff", $g_sInput_HeroIndex)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Drop Buff##h") Then
            Effect_DropBond(Number($g_sInput_SkillID), Number($g_sInput_AgentID), Number($g_sInput_HeroIndex))
            Log_Message("Effect_DropBond(" & $g_sInput_SkillID & ", " & $g_sInput_AgentID & ", " & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Friend ===
    If _ImGui_CollapsingHeader("Friend##h") Then
        _ImGui_TextColored("No Header functions (see Queue)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Game ===
    If _ImGui_CollapsingHeader("Game##h") Then
        _ImGui_Text("Game_Dialog - Send dialog")
        _ImGui_PushItemWidth(100)
        _ImGui_InputText("Dialog##hgame", $g_sInput_DialogID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Send Dialog##h") Then
            Game_Dialog(Number($g_sInput_DialogID))
            Log_Message("Game_Dialog(" & $g_sInput_DialogID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Game_SwitchMode - Hard Mode Toggle")
        If _ImGui_Button("Normal Mode##hgame") Then
            Game_SwitchMode(0)
            Log_Message("Game_SwitchMode(0)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Hard Mode##hgame") Then
            Game_SwitchMode(1)
            Log_Message("Game_SwitchMode(1)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Game_DonateFaction - Donate faction (5000)")
        If _ImGui_Button("Donate Kurzick##h") Then
            Game_DonateFaction("k")
            Log_Message("Game_DonateFaction('k')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Donate Luxon##h") Then
            Game_DonateFaction("l")
            Log_Message("Game_DonateFaction('l')", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Guild ===
    If _ImGui_CollapsingHeader("Guild##h") Then
        _ImGui_TextColored("No Header functions (see Queue)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Item ===
    If _ImGui_CollapsingHeader("Item##h") Then
        _ImGui_Text("Basic Item Operations:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Item##hitem", $g_sInput_ItemID)
        _ImGui_SameLine()
        _ImGui_InputText("Qty##hitem", $g_sInput_Quantity)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Use##hitem") Then
            Item_UseItem(Number($g_sInput_ItemID))
            Log_Message("Item_UseItem(" & $g_sInput_ItemID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Equip##hitem") Then
            Item_EquipItem(Number($g_sInput_ItemID))
            Log_Message("Item_EquipItem(" & $g_sInput_ItemID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Drop##hitem") Then
            Item_DropItem(Number($g_sInput_ItemID), Number($g_sInput_Quantity))
            Log_Message("Item_DropItem(" & $g_sInput_ItemID & ", " & $g_sInput_Quantity & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Destroy##hitem") Then
            Item_DestroyItem(Number($g_sInput_ItemID))
            Log_Message("Item_DestroyItem(" & $g_sInput_ItemID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Item_PickUpItem (uses Agent ID):")
        _ImGui_PushItemWidth(100)
        _ImGui_InputText("Agent##hpickup", $g_sInput_AgentID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("PickUp##hitem") Then
            Item_PickUpItem(Number($g_sInput_AgentID))
            Log_Message("Item_PickUpItem(" & $g_sInput_AgentID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Item_IdentifyItem:")
        If _ImGui_Button("Identify (auto kit)##h") Then
            Item_IdentifyItem(Number($g_sInput_ItemID))
            Log_Message("Item_IdentifyItem(" & $g_sInput_ItemID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Item_MoveItem:")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("Bag##hmove", $g_sInput_BagNumber)
        _ImGui_SameLine()
        _ImGui_InputText("Slot##hmove", $g_sInput_SlotNumber)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Move##hitem") Then
            Item_MoveItem(Number($g_sInput_ItemID), Number($g_sInput_BagNumber), Number($g_sInput_SlotNumber))
            Log_Message("Item_MoveItem(" & $g_sInput_ItemID & ", " & $g_sInput_BagNumber & ", " & $g_sInput_SlotNumber & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Gold / Chest / Weapon Set:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Gold##hdrop", $g_sInput_GoldAmount)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Drop Gold##h") Then
            Item_DropGold(Number($g_sInput_GoldAmount))
            Log_Message("Item_DropGold(" & $g_sInput_GoldAmount & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Accept Unclaimed##h") Then
            Item_AcceptAllItems()
            Log_Message("Item_AcceptAllItems()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Open Chest (LP)##h") Then
            Item_OpenChest(True)
            Log_Message("Item_OpenChest(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Open Chest (Key)##h") Then
            Item_OpenChest(False)
            Log_Message("Item_OpenChest(False)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Text("Weapon Sets:")
        For $i = 1 To 4
            If $i > 1 Then _ImGui_SameLine()
            If _ImGui_Button("Set " & $i & "##hweapon", 50, 25) Then
                Item_SwitchWeaponSet($i)
                Log_Message("Item_SwitchWeaponSet(" & $i & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            EndIf
        Next
		_ImGui_Separator()
    EndIf

    ; === Map ===
    If _ImGui_CollapsingHeader("Map##h") Then
        _ImGui_Text("Map_TravelTo:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Map##htravel", $g_sInput_MapID)
        _ImGui_SameLine()
        _ImGui_InputText("District##htravel", $g_sInput_District)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Travel##h") Then
            Map_TravelTo(Number($g_sInput_MapID), Number($g_sInput_District))
            Log_Message("Map_TravelTo(" & $g_sInput_MapID & ", " & $g_sInput_District & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Text("Quick Travel:")
        If _ImGui_Button("Kamadan##h") Then
            Map_TravelTo(449)
            Log_Message("Map_TravelTo(449)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("GToB##h") Then
            Map_TravelTo(248)
            Log_Message("Map_TravelTo(248)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("EotN##h") Then
            Map_TravelTo(642)
            Log_Message("Map_TravelTo(642)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("LA##h") Then
            Map_TravelTo(55)
            Log_Message("Map_TravelTo(55)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Kaineng##h") Then
            Map_TravelTo(194)
            Log_Message("Map_TravelTo(194)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Other Map Functions:")
        If _ImGui_Button("Return Outpost##h") Then
            Map_ReturnToOutpost(True)
            Log_Message("Map_ReturnToOutpost(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Enter Challenge##h") Then
            Map_EnterChallenge(True)
            Log_Message("Map_EnterChallenge(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Travel GH##h") Then
            Map_TravelGH()
            Log_Message("Map_TravelGH(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Leave GH##h") Then
            Map_LeaveGH()
            Log_Message("Map_LeaveGH(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Match ===
    If _ImGui_CollapsingHeader("Match##h") Then
        _ImGui_TextColored("No Header functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Merchant ===
    If _ImGui_CollapsingHeader("Merchant##h") Then
        _ImGui_TextColored("No Header functions (see Queue)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Other ===
    If _ImGui_CollapsingHeader("Other##h") Then
        _ImGui_TextColored("No Header functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Party ===
    If _ImGui_CollapsingHeader("Party##h") Then
        _ImGui_Text("Hero Management:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Hero ID##hparty", $g_sInput_HeroIndex)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Add Hero##h") Then
            Party_AddHero(Number($g_sInput_HeroIndex))
            Log_Message("Party_AddHero(" & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Kick Hero##h") Then
            Party_KickHero(Number($g_sInput_HeroIndex))
            Log_Message("Party_KickHero(" & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Kick All Heroes##h") Then
            Party_KickAllHeroes()
            Log_Message("Party_KickAllHeroes()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("NPC/Henchman Management:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("NPC ID##hpartynpc", $g_sInput_AgentID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Add NPC##h") Then
            Party_AddNpc(Number($g_sInput_AgentID))
            Log_Message("Party_AddNpc(" & $g_sInput_AgentID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Kick NPC##h") Then
            Party_KickNpc(Number($g_sInput_AgentID))
            Log_Message("Party_KickNpc(" & $g_sInput_AgentID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Hero Flag Commands:")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("X##hflag", $g_sInput_X)
        _ImGui_SameLine()
        _ImGui_InputText("Y##hflag", $g_sInput_Y)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Command Hero##h") Then
            Party_CommandHero(Number($g_sInput_HeroIndex), Number($g_sInput_X), Number($g_sInput_Y))
            Log_Message("Party_CommandHero(" & $g_sInput_HeroIndex & ", " & $g_sInput_X & ", " & $g_sInput_Y & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Cancel Hero##h") Then
            Party_CancelHero(Number($g_sInput_HeroIndex))
            Log_Message("Party_CancelHero(" & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Command All##h") Then
            Party_CommandAll(Number($g_sInput_X), Number($g_sInput_Y))
            Log_Message("Party_CommandAll(" & $g_sInput_X & ", " & $g_sInput_Y & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Cancel All##h") Then
            Party_CancelAll()
            Log_Message("Party_CancelAll()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Hero Behavior (0=Fight, 1=Guard, 2=Avoid):")
        If _ImGui_Button("Fight##hbeh") Then
            Party_SetHeroAggression(Number($g_sInput_HeroIndex), 0)
            Log_Message("Party_SetHeroAggression(" & $g_sInput_HeroIndex & ", 0)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Guard##hbeh") Then
            Party_SetHeroAggression(Number($g_sInput_HeroIndex), 1)
            Log_Message("Party_SetHeroAggression(" & $g_sInput_HeroIndex & ", 1)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Avoid##hbeh") Then
            Party_SetHeroAggression(Number($g_sInput_HeroIndex), 2)
            Log_Message("Party_SetHeroAggression(" & $g_sInput_HeroIndex & ", 2)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Hero Target Lock:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Target##hlock", $g_sInput_TargetID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Lock##hlock") Then
            Party_LockHeroTarget(Number($g_sInput_HeroIndex), Number($g_sInput_TargetID))
            Log_Message("Party_LockHeroTarget(" & $g_sInput_HeroIndex & ", " & $g_sInput_TargetID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Unlock##hlock") Then
            Party_LockHeroTarget(Number($g_sInput_HeroIndex), 0)
            Log_Message("Party_LockHeroTarget(" & $g_sInput_HeroIndex & ", 0)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_Text("Hero Skill Toggle:")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("Slot##htoggle", $g_sInput_SkillSlot)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Toggle##htoggle") Then
            Party_ToggleHeroSkillState(Number($g_sInput_HeroIndex), Number($g_sInput_SkillSlot))
            Log_Message("Party_ToggleHeroSkillState(" & $g_sInput_HeroIndex & ", " & $g_sInput_SkillSlot & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        If _ImGui_Button("Leave Group##h") Then
            Party_LeaveGroup(True)
            Log_Message("Party_LeaveGroup(True)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Path ===
    If _ImGui_CollapsingHeader("Path##h") Then
        _ImGui_TextColored("No Header functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Player ===
    If _ImGui_CollapsingHeader("Player##h") Then
        _ImGui_TextColored("No Header functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === PreGame ===
    If _ImGui_CollapsingHeader("PreGame##h") Then
        _ImGui_TextColored("No Header functions", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === Quest ===
    If _ImGui_CollapsingHeader("Quest##h") Then
        _ImGui_Text("Quest Functions:")
        _ImGui_PushItemWidth(100)
        _ImGui_InputText("Quest ID##hquest", $g_sInput_QuestID)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Accept##hquest") Then
            Quest_AcceptQuest(Number($g_sInput_QuestID))
            Log_Message("Quest_AcceptQuest(" & $g_sInput_QuestID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Reward##hquest") Then
            Quest_QuestReward(Number($g_sInput_QuestID))
            Log_Message("Quest_QuestReward(" & $g_sInput_QuestID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Abandon##hquest") Then
            Quest_AbandonQuest(Number($g_sInput_QuestID))
            Log_Message("Quest_AbandonQuest(" & $g_sInput_QuestID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Skill ===
    If _ImGui_CollapsingHeader("Skill##h") Then
        _ImGui_Text("Skill_SetSkillbarSkill:")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("Slot##hskillset", $g_sInput_SkillSlot)
        _ImGui_SameLine()
        _ImGui_InputText("Skill##hskillset", $g_sInput_SkillID)
        _ImGui_SameLine()
        _ImGui_InputText("Hero##hskillset", $g_sInput_HeroIndex)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Set##hskillset") Then
            Skill_SetSkillbarSkill(Number($g_sInput_SkillSlot), Number($g_sInput_SkillID), Number($g_sInput_HeroIndex))
            Log_Message("Skill_SetSkillbarSkill(" & $g_sInput_SkillSlot & ", " & $g_sInput_SkillID & ", " & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
        _ImGui_Text("Skill_LoadSkillBar - Load full skillbar:")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Loads all 8 skills at once. Use skill IDs (0 = empty slot)")
        If _ImGui_Button("Clear Skillbar##h") Then
            Skill_LoadSkillBar(0, 0, 0, 0, 0, 0, 0, 0, Number($g_sInput_HeroIndex))
            Log_Message("Skill_LoadSkillBar(0,0,0,0,0,0,0,0," & $g_sInput_HeroIndex & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
        _ImGui_Text("Skill_SkillForQuest - Replace skill slot for quest:")
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Select which skill slot to replace with quest skill" & @CRLF & "e.g. Disarm Trap for Venta Cemetery")
        _ImGui_PushItemWidth(60)
        _ImGui_InputText("Slot##hquest", $g_sInput_SkillSlot)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Set Quest Slot##h") Then
            Skill_SkillForQuest(Number($g_sInput_SkillSlot))
            Log_Message("Skill_SkillForQuest(" & $g_sInput_SkillSlot & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
        _ImGui_Text("Skill_BuySkillByID / UnlockSkillByID:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Skill ID##hbuy", $g_sInput_SkillID)
        _ImGui_PopItemWidth()
        If _ImGui_Button("Buy Skill##h") Then
            Skill_BuySkillByID(Number($g_sInput_SkillID))
            Log_Message("Skill_BuySkillByID(" & $g_sInput_SkillID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Unlock (Balthazar)##h") Then
            Skill_UnlockSkillByID(Number($g_sInput_SkillID))
            Log_Message("Skill_UnlockSkillByID(" & $g_sInput_SkillID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Unlock (Boss)##h") Then
            Skill_UnlockSkillBossByID(Number($g_sInput_SkillID))
            Log_Message("Skill_UnlockSkillBossByID(" & $g_sInput_SkillID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
        _ImGui_Text("Skill_UnlockTomeSkillByID:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Tome##htome", $g_sInput_ItemID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Unlock (Tome)##h") Then
            Skill_UnlockTomeSkillByID(Number($g_sInput_ItemID), Number($g_sInput_SkillID))
            Log_Message("Skill_UnlockTomeSkillByID(" & $g_sInput_ItemID & ", " & $g_sInput_SkillID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
    EndIf

    ; === Title ===
    If _ImGui_CollapsingHeader("Title##h") Then
        _ImGui_Text("Title_SetDisplayedTitle:")
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Title ID##htitle", $g_sInput_TitleID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Set Title##h") Then
            Title_SetDisplayedTitle(Number($g_sInput_TitleID))
            Log_Message("Title_SetDisplayedTitle(" & $g_sInput_TitleID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Hide Title##h") Then
            Title_SetDisplayedTitle(0)
            Log_Message("Title_SetDisplayedTitle(0)", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Trade ===
    If _ImGui_CollapsingHeader("Trade##h") Then
        _ImGui_Text("Trade Header Functions (alternative to Queue):")
        _ImGui_PushItemWidth(100)
        _ImGui_InputText("Agent##htrade", $g_sInput_AgentID)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Initiate##htrade") Then
            Trade_InitiateTrade_(Number($g_sInput_AgentID))
            Log_Message("Trade_InitiateTrade_(" & $g_sInput_AgentID & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_Button("Accept##htrade") Then
            Trade_AcceptTrade_()
            Log_Message("Trade_AcceptTrade_()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Cancel##htrade") Then
            Trade_CancelTrade_()
            Log_Message("Trade_CancelTrade_()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Change Offer##htrade") Then
            Trade_ChangeOffer_()
            Log_Message("Trade_ChangeOffer_()", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_NewLine()
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Gold##htradeoffer", $g_sInput_GoldAmount)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Submit##htradeoffer") Then
            Trade_SubmitOffer_(Number($g_sInput_GoldAmount))
            Log_Message("Trade_SubmitOffer_(" & $g_sInput_GoldAmount & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_PushItemWidth(80)
        _ImGui_InputText("Item##htradeitem", $g_sInput_ItemID)
        _ImGui_SameLine()
        _ImGui_InputText("Qty##htradeitem", $g_sInput_Quantity)
        _ImGui_PopItemWidth()
        _ImGui_SameLine()
        If _ImGui_Button("Offer Item##htrade") Then
            Trade_OfferItem_(Number($g_sInput_ItemID), Number($g_sInput_Quantity))
            Log_Message("Trade_OfferItem_(" & $g_sInput_ItemID & ", " & $g_sInput_Quantity & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
		_ImGui_Separator()
    EndIf

    ; === Ui ===
    If _ImGui_CollapsingHeader("Ui##h") Then
        _ImGui_TextColored("No Header functions (see Queue)", 0xFF888888)
		_ImGui_Separator()
    EndIf

    ; === World ===
    If _ImGui_CollapsingHeader("World##h") Then
        _ImGui_TextColored("No Header functions", 0xFF888888)
		_ImGui_Separator()
    EndIf
EndFunc

Func _GUI_Tab_ControlAction()
    _ImGui_TextColored("ControlAction Commands (Core_ControlAction)", 0xFFFF8800)
    _ImGui_Text("Simulate keyboard inputs via Core_ControlAction()")
    _ImGui_NewLine()
    _ImGui_Separator()

    ; Input for hex value with +/- buttons
    _ImGui_Text("Control Action Value (0x*):")
    _ImGui_SetNextItemWidth(100)
    _ImGui_InputText("##caInput", $g_sInput_ControlAction, 20)

    _ImGui_SameLine()
    If _ImGui_Button("-##ca", 25, 0) Then
        Local $l_iValue = Dec(StringReplace($g_sInput_ControlAction, "0x", ""))
        If $l_iValue > 0 Then $l_iValue -= 1
        $g_sInput_ControlAction = "0x" & Hex($l_iValue, 2)
    EndIf
    If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Decrement value")

    _ImGui_SameLine()
    If _ImGui_Button("+##ca", 25, 0) Then
        Local $l_iValue = Dec(StringReplace($g_sInput_ControlAction, "0x", ""))
        $l_iValue += 1
        $g_sInput_ControlAction = "0x" & Hex($l_iValue, 2)
    EndIf
    If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Increment value")

    _ImGui_SameLine()
    If _ImGui_Button("Activate##ca", 80, 0) Then
        Local $l_iValue = Dec(StringReplace($g_sInput_ControlAction, "0x", ""))
        Core_ControlAction($l_iValue, $GC_I_CONTROL_TYPE_ACTIVATE)
        Log_Message("Core_ControlAction(" & $g_sInput_ControlAction & ", $GC_I_CONTROL_TYPE_ACTIVATE)", $c_UTILS_Msg_Type_Info, "DevTools")
    EndIf
    If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Activate the control action (key down)")

    _ImGui_SameLine()
    If _ImGui_Button("Deactivate##ca", 80, 0) Then
        Local $l_iValue = Dec(StringReplace($g_sInput_ControlAction, "0x", ""))
        Core_ControlAction($l_iValue, $GC_I_CONTROL_TYPE_DEACTIVATE)
        Log_Message("Core_ControlAction(" & $g_sInput_ControlAction & ", $GC_I_CONTROL_TYPE_DEACTIVATE)", $c_UTILS_Msg_Type_Info, "DevTools")
    EndIf
    If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Deactivate the control action (key up)")

    _ImGui_NewLine()
    _ImGui_Separator()

    ; Display description based on input value
    Local $l_iValue = Dec(StringReplace($g_sInput_ControlAction, "0x", ""))
    Local $l_sDescription = _GetControlActionDescription($l_iValue)
    _ImGui_TextColored("Description:", 0xFF00FFFF)
    _ImGui_TextWrapped($l_sDescription)

    _ImGui_NewLine()
    _ImGui_Separator()

    ; Quick reference collapsing header
        _ImGui_TextColored("Actions:", 0xFFFFAA00)
        _ImGui_BulletText("0x80 - Attack/Interact")
        _ImGui_BulletText("0xAF - Cancel Action")
        _ImGui_BulletText("0xD0 - Suppress Action")
        _ImGui_BulletText("0xCD - Drop Item")
        _ImGui_BulletText("0xCC - Follow")

        _ImGui_TextColored("Skills:", 0xFFFFAA00)
        _ImGui_BulletText("0xA4-0xAB - Use Skill 1-8")

        _ImGui_TextColored("Movement:", 0xFFFFAA00)
        _ImGui_BulletText("0xB7 - Auto Run")
        _ImGui_BulletText("0xAC - Move Backward")
        _ImGui_BulletText("0xAD - Move Forward")
        _ImGui_BulletText("0x91/0x92 - Strafe Left/Right")
        _ImGui_BulletText("0xA2/0xA3 - Turn Left/Right")

        _ImGui_TextColored("Targeting:", 0xFFFFAA00)
        _ImGui_BulletText("0x93 - Nearest Foe")
        _ImGui_BulletText("0x95/0x9E - Next/Previous Foe")
        _ImGui_BulletText("0xBC - Nearest Ally")
        _ImGui_BulletText("0xA0 - Target Self")
        _ImGui_BulletText("0xE3 - Clear Target")
        _ImGui_BulletText("0x96-0x9D - Party Member 1-8")
        _ImGui_BulletText("0xC6-0xC9 - Party Member 9-12")

        _ImGui_TextColored("Hero Commands:", 0xFFFFAA00)
        _ImGui_BulletText("0xD6 - Command Party")
        _ImGui_BulletText("0xDB - Clear Party Commands")
        _ImGui_BulletText("0xD7-0xD9 - Command Hero 1-3")
        _ImGui_BulletText("0x102-0x105 - Command Hero 4-7")

        _ImGui_TextColored("Inventory:", 0xFFFFAA00)
        _ImGui_BulletText("0x81-0x84 - Weapon Set 1-4")
        _ImGui_BulletText("0x86 - Cycle Equipment")
        _ImGui_BulletText("0x8B - Open Inventory")
        _ImGui_BulletText("0xB8 - Toggle All Bags")

        _ImGui_TextColored("Panels:", 0xFFFFAA00)
        _ImGui_BulletText("0x8A - Hero Panel")
        _ImGui_BulletText("0x8C - World Map")
        _ImGui_BulletText("0x8D - Options")
        _ImGui_BulletText("0x8E - Quest Log")
        _ImGui_BulletText("0x8F - Skills & Attributes")
        _ImGui_BulletText("0xB6 - Mission Map")
        _ImGui_BulletText("0xB9 - Friends")
        _ImGui_BulletText("0xBA - Guild")
        _ImGui_BulletText("0xBF - Party")
        _ImGui_BulletText("0x85 - Close All Panels")

        _ImGui_TextColored("Camera:", 0xFFFFAA00)
        _ImGui_BulletText("0xB0 - Free Camera")
        _ImGui_BulletText("0x90 - Reverse Camera")
        _ImGui_BulletText("0xCE/0xCF - Zoom In/Out")

        _ImGui_TextColored("Chat:", 0xFFFFAA00)
        _ImGui_BulletText("0x88 - Open Chat")
        _ImGui_BulletText("0xA1 - Toggle Chat")
        _ImGui_BulletText("0xBE - Reply")
        _ImGui_BulletText("0xC0 - Start Chat Command")

        _ImGui_TextColored("Misc:", 0xFFFFAA00)
        _ImGui_BulletText("0xAE - Screenshot")
        _ImGui_BulletText("0x87 - Log Out")
EndFunc

Func _GetControlActionDescription($a_iValue)
    Switch $a_iValue
        ; Actions
        Case 0x00
            Return "NONE - No action"
        Case 0x80
            Return "ATTACK_INTERACT - Attack target or interact with object"
        Case 0xAF
            Return "CANCEL_ACTION - Cancel the current action"
        Case 0xDB
            Return "CLEAR_PARTY_COMMANDS - Clear all party/hero commands"
        Case 0xD7
            Return "COMMAND_HERO_1 - Command hero 1"
        Case 0xD8
            Return "COMMAND_HERO_2 - Command hero 2"
        Case 0xD9
            Return "COMMAND_HERO_3 - Command hero 3"
        Case 0x102
            Return "COMMAND_HERO_4 - Command hero 4"
        Case 0x103
            Return "COMMAND_HERO_5 - Command hero 5"
        Case 0x104
            Return "COMMAND_HERO_6 - Command hero 6"
        Case 0x105
            Return "COMMAND_HERO_7 - Command hero 7"
        Case 0xD6
            Return "COMMAND_PARTY - Command entire party"
        Case 0xCD
            Return "DROP_ITEM - Drop held item"
        Case 0xCC
            Return "FOLLOW - Follow target"
        Case 0xD0
            Return "SUPPRESS_ACTION - Suppress current action"

        ; Skills
        Case 0xA4
            Return "USE_SKILL_1 - Use skill in slot 1"
        Case 0xA5
            Return "USE_SKILL_2 - Use skill in slot 2"
        Case 0xA6
            Return "USE_SKILL_3 - Use skill in slot 3"
        Case 0xA7
            Return "USE_SKILL_4 - Use skill in slot 4"
        Case 0xA8
            Return "USE_SKILL_5 - Use skill in slot 5"
        Case 0xA9
            Return "USE_SKILL_6 - Use skill in slot 6"
        Case 0xAA
            Return "USE_SKILL_7 - Use skill in slot 7"
        Case 0xAB
            Return "USE_SKILL_8 - Use skill in slot 8"

        ; Camera
        Case 0xB0
            Return "FREE_CAMERA - Toggle free camera mode"
        Case 0x90
            Return "REVERSE_CAMERA - Reverse camera view"
        Case 0xCE
            Return "ZOOM_IN - Zoom camera in"
        Case 0xCF
            Return "ZOOM_OUT - Zoom camera out"

        ; Chat
        Case 0x88
            Return "OPEN_CHAT - Open chat input"
        Case 0xBE
            Return "REPLY - Reply to last whisper"
        Case 0xC0
            Return "START_CHAT_COMMAND - Start typing a chat command"
        Case 0xA1
            Return "TOGGLE_CHAT - Toggle chat window"

        ; Inventory
        Case 0x81
            Return "ACTIVATE_WEAPON_SET_1 - Switch to weapon set 1"
        Case 0x82
            Return "ACTIVATE_WEAPON_SET_2 - Switch to weapon set 2"
        Case 0x83
            Return "ACTIVATE_WEAPON_SET_3 - Switch to weapon set 3"
        Case 0x84
            Return "ACTIVATE_WEAPON_SET_4 - Switch to weapon set 4"
        Case 0x86
            Return "CYCLE_EQUIPMENT - Cycle through equipment sets"
        Case 0xB2
            Return "OPEN_BACKPACK - Open backpack"
        Case 0xB4
            Return "OPEN_BAG_1 - Open bag 1"
        Case 0xB5
            Return "OPEN_BAG_2 - Open bag 2"
        Case 0xB3
            Return "OPEN_BELT_POUCH - Open belt pouch"
        Case 0x8B
            Return "OPEN_INVENTORY - Open inventory panel"
        Case 0xB8
            Return "TOGGLE_ALL_BAGS - Toggle all bags open/closed"

        ; Miscellaneous
        Case 0xBB
            Return "LANGUAGE_QUICK_TOGGLE - Toggle language input"
        Case 0x87
            Return "LOG_OUT - Log out to character select"
        Case 0xAE
            Return "SCREENSHOT - Take a screenshot"

        ; Movement
        Case 0xB7
            Return "AUTOMATIC_RUN - Toggle auto-run"
        Case 0xAC
            Return "MOVE_BACKWARD - Move backward"
        Case 0xAD
            Return "MOVE_FORWARD - Move forward"
        Case 0xB1
            Return "REVERSE_DIRECTION - Reverse movement direction"
        Case 0x91
            Return "STRAFE_LEFT - Strafe left"
        Case 0x92
            Return "STRAFE_RIGHT - Strafe right"
        Case 0xA2
            Return "TURN_LEFT - Turn left"
        Case 0xA3
            Return "TURN_RIGHT - Turn right"

        ; Panels
        Case 0x85
            Return "CLOSE_ALL_PANELS - Close all open panels"
        Case 0xC1
            Return "OPEN_CUSTOMIZE_LAYOUT - Open UI customization"
        Case 0xB9
            Return "OPEN_FRIENDS - Open friends list"
        Case 0xBA
            Return "OPEN_GUILD - Open guild panel"
        Case 0xE4
            Return "OPEN_HELP - Open help panel"
        Case 0x8A
            Return "OPEN_HERO - Open hero panel"
        Case 0xE0
            Return "OPEN_HERO_1_PET_COMMANDER - Open hero 1 pet commander"
        Case 0xE1
            Return "OPEN_HERO_2_PET_COMMANDER - Open hero 2 pet commander"
        Case 0xE2
            Return "OPEN_HERO_3_PET_COMMANDER - Open hero 3 pet commander"
        Case 0xFE
            Return "OPEN_HERO_4_PET_COMMANDER - Open hero 4 pet commander"
        Case 0xFF
            Return "OPEN_HERO_5_PET_COMMANDER - Open hero 5 pet commander"
        Case 0x100
            Return "OPEN_HERO_6_PET_COMMANDER - Open hero 6 pet commander"
        Case 0x101
            Return "OPEN_HERO_7_PET_COMMANDER - Open hero 7 pet commander"
        Case 0xDC
            Return "OPEN_HERO_1_COMMANDER - Open hero 1 commander"
        Case 0xDD
            Return "OPEN_HERO_2_COMMANDER - Open hero 2 commander"
        Case 0xDE
            Return "OPEN_HERO_3_COMMANDER - Open hero 3 commander"
        Case 0x126
            Return "OPEN_HERO_4_COMMANDER - Open hero 4 commander"
        Case 0x127
            Return "OPEN_HERO_5_COMMANDER - Open hero 5 commander"
        Case 0x128
            Return "OPEN_HERO_6_COMMANDER - Open hero 6 commander"
        Case 0x129
            Return "OPEN_HERO_7_COMMANDER - Open hero 7 commander"
        Case 0xD1
            Return "OPEN_LOAD_FROM_EQUIPMENT_TEMPLATE - Load equipment template"
        Case 0xD2
            Return "OPEN_LOAD_FROM_SKILLS_TEMPLATE - Load skills template"
        Case 0xFD
            Return "OPEN_MINION_LIST - Open minion list"
        Case 0xB6
            Return "OPEN_MISSION_MAP - Open mission map"
        Case 0xC2
            Return "OPEN_OBSERVE - Open observer mode"
        Case 0x8D
            Return "OPEN_OPTIONS - Open options panel"
        Case 0xBF
            Return "OPEN_PARTY - Open party panel"
        Case 0xDF
            Return "OPEN_PET_COMMANDER - Open pet commander"
        Case 0xDA
            Return "OPEN_PVP_EQUIPMENT - Open PvP equipment"
        Case 0x8E
            Return "OPEN_QUEST - Open quest log"
        Case 0xD4
            Return "OPEN_SAVE_TO_EQUIPMENT_TEMPLATE - Save equipment template"
        Case 0xD5
            Return "OPEN_SAVE_TO_SKILLS_TEMPLATE - Save skills template"
        Case 0xBD
            Return "OPEN_SCORE_CHART - Open score chart"
        Case 0x8F
            Return "OPEN_SKILLS_AND_ATTRIBUTES - Open skills and attributes"
        Case 0xD3
            Return "OPEN_TEMPLATES_MANAGER - Open templates manager"
        Case 0x8C
            Return "OPEN_WORLD_MAP - Open world map"

        ; Targeting
        Case 0xBC
            Return "ALLY_NEAREST - Target nearest ally"
        Case 0xE3
            Return "CLEAR_TARGET - Clear current target"
        Case 0x93
            Return "FOE_NEAREST - Target nearest foe"
        Case 0x95
            Return "FOE_NEXT - Target next foe"
        Case 0x9E
            Return "FOE_PREVIOUS - Target previous foe"
        Case 0xC3
            Return "ITEM_NEAREST - Target nearest item"
        Case 0xC4
            Return "ITEM_NEXT - Target next item"
        Case 0xC5
            Return "ITEM_PREVIOUS - Target previous item"
        Case 0x96
            Return "PARTY_MEMBER_1 - Target party member 1"
        Case 0x97
            Return "PARTY_MEMBER_2 - Target party member 2"
        Case 0x98
            Return "PARTY_MEMBER_3 - Target party member 3"
        Case 0x99
            Return "PARTY_MEMBER_4 - Target party member 4"
        Case 0x9A
            Return "PARTY_MEMBER_5 - Target party member 5"
        Case 0x9B
            Return "PARTY_MEMBER_6 - Target party member 6"
        Case 0x9C
            Return "PARTY_MEMBER_7 - Target party member 7"
        Case 0x9D
            Return "PARTY_MEMBER_8 - Target party member 8"
        Case 0xC6
            Return "PARTY_MEMBER_9 - Target party member 9"
        Case 0xC7
            Return "PARTY_MEMBER_10 - Target party member 10"
        Case 0xC8
            Return "PARTY_MEMBER_11 - Target party member 11"
        Case 0xC9
            Return "PARTY_MEMBER_12 - Target party member 12"
        Case 0xCA
            Return "PARTY_MEMBER_NEXT - Target next party member"
        Case 0xCB
            Return "PARTY_MEMBER_PREVIOUS - Target previous party member"
        Case 0x9F
            Return "PRIORITY_TARGET - Priority target"
        Case 0xA0
            Return "SELF - Target yourself"
        Case 0x89
            Return "SHOW_OTHERS - Show other players"
        Case 0x94
            Return "SHOW_TARGETS - Show targets"

        ; Hero skill orders (0xE5-0xFC for heroes 1-3, 0x106-0x125 for heroes 4-7)
        Case 0xE5 To 0xEC
            Return "ORDER_HERO_1_SKILL_" & ($a_iValue - 0xE4) & " - Order hero 1 to use skill " & ($a_iValue - 0xE4)
        Case 0xED To 0xF4
            Return "ORDER_HERO_2_SKILL_" & ($a_iValue - 0xEC) & " - Order hero 2 to use skill " & ($a_iValue - 0xEC)
        Case 0xF5 To 0xFC
            Return "ORDER_HERO_3_SKILL_" & ($a_iValue - 0xF4) & " - Order hero 3 to use skill " & ($a_iValue - 0xF4)
        Case 0x106 To 0x10D
            Return "ORDER_HERO_4_SKILL_" & ($a_iValue - 0x105) & " - Order hero 4 to use skill " & ($a_iValue - 0x105)
        Case 0x10E To 0x115
            Return "ORDER_HERO_5_SKILL_" & ($a_iValue - 0x10D) & " - Order hero 5 to use skill " & ($a_iValue - 0x10D)
        Case 0x116 To 0x11D
            Return "ORDER_HERO_6_SKILL_" & ($a_iValue - 0x115) & " - Order hero 6 to use skill " & ($a_iValue - 0x115)
        Case 0x11E To 0x125
            Return "ORDER_HERO_7_SKILL_" & ($a_iValue - 0x11D) & " - Order hero 7 to use skill " & ($a_iValue - 0x11D)

        Case Else
            Return "Unknown control action value: 0x" & Hex($a_iValue, 2)
    EndSwitch
EndFunc

Func _GUI_Tab_DataFunctions()
    _ImGui_TextColored("Data Functions (Read-Only)", 0xFFFFFF00)
    _ImGui_Text("These functions read game state without sending commands")
    _ImGui_NewLine()
    _ImGui_Separator()

    ; === ACCOUNT ===
    If _ImGui_CollapsingHeader("Account##data") Then
        If _ImGui_Button("Get Context Ptr##acc") Then
            Log_Message("Account Context Ptr: " & Account_GetAccountContextPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All Info##acc") Then
            Log_Message("=== Account Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AccountName: " & Account_GetAccountInfo("AccountName"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Wins: " & Account_GetAccountInfo("Wins"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Losses: " & Account_GetAccountInfo("Losses"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Rating: " & Account_GetAccountInfo("Rating"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("QualifierPoints: " & Account_GetAccountInfo("QualifierPoints"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Rank: " & Account_GetAccountInfo("Rank"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("TournamentRewardPoints: " & Account_GetAccountInfo("TournamentRewardPoints"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Account_GetAccountInfo($Info)" & @CRLF & "Info: AccountName, Wins, Losses, Rating, QualifierPoints, Rank, TournamentRewardPoints")

		_ImGui_NewLine()

        _ImGui_SetNextItemWidth(120)
        _ImGui_InputInt("Skill ID##accskill", $g_iInput_AccountSkillID, 1, 10)
        If $g_iInput_AccountSkillID < 1 Then $g_iInput_AccountSkillID = 1
        If $g_iInput_AccountSkillID > 3431 Then $g_iInput_AccountSkillID = 3431
		_ImGui_Text("Skill Name: " & $GC_AMX2_SKILL_DATA[$g_iInput_AccountSkillID][1])
        If Account_IsSkillUnlocked($g_iInput_AccountSkillID) Then
            _ImGui_TextColored("Skill ID: " & $g_iInput_AccountSkillID & " is unlocked on this account", 0xFF00FF00)
        Else
            _ImGui_TextColored("Skill ID: " & $g_iInput_AccountSkillID & " is not unlocked on this account", 0xFFFF0000)
        EndIf
        _ImGui_Separator()
    EndIf

    ; === AGENT ===
    If _ImGui_CollapsingHeader("Agent##data") Then
        _ImGui_SetNextItemWidth(80)

        If _ImGui_Button("My ID##ag") Then
            Local $myID = Agent_GetMyID()
            $g_sInput_AgentID = String($myID)
            Log_Message("My Agent ID: " & $myID, $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Target##ag") Then
            Local $targetID = Agent_GetCurrentTarget()
            If $targetID > 0 Then
                $g_sInput_AgentID = String($targetID)
                Log_Message("Current Target: " & $targetID, $c_UTILS_Msg_Type_Info, "DevTools")
            Else
                Log_Message("No target selected", $c_UTILS_Msg_Type_Warning, "DevTools")
            EndIf
        EndIf

        _ImGui_InputText("Agent ID##dataagent", $g_sInput_AgentID)

        ; All infos (ordre des offsets)
        If _ImGui_Button("All Infos##ag") Then
            Local $id = Number($g_sInput_AgentID)
            Log_Message("=== Agent " & $id & " Infos ===", $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x00
            Log_Message("vtable: " & Agent_GetAgentInfo($id, "vtable"), $c_UTILS_Msg_Type_Info, "DevTools")
			Log_Message("h0004: " & Agent_GetAgentInfo($id, "h0004") & " | h0008: " & Agent_GetAgentInfo($id, "h0008") & " | h000C: " & Agent_GetAgentInfo($id, "h000C") & " | h0010: " & Agent_GetAgentInfo($id, "h0010"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Timer: " & Agent_GetAgentInfo($id, "Timer") & " | Timer2: " & Agent_GetAgentInfo($id, "Timer2"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h0018: " & Agent_GetAgentInfo($id, "h0018"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x2C - 0x48
            Log_Message("ID: " & Agent_GetAgentInfo($id, "ID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Z: " & Agent_GetAgentInfo($id, "Z"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Width1: " & Agent_GetAgentInfo($id, "Width1") & " | Height1: " & Agent_GetAgentInfo($id, "Height1"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Width2: " & Agent_GetAgentInfo($id, "Width2") & " | Height2: " & Agent_GetAgentInfo($id, "Height2"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Width3: " & Agent_GetAgentInfo($id, "Width3") & " | Height3: " & Agent_GetAgentInfo($id, "Height3"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x4C - 0x6C
            Log_Message("Rotation: " & Agent_GetAgentInfo($id, "Rotation") & " | RotationCos: " & Agent_GetAgentInfo($id, "RotationCos") & " | RotationSin: " & Agent_GetAgentInfo($id, "RotationSin"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NameProperties: " & Agent_GetAgentInfo($id, "NameProperties") & " | Ground: " & Agent_GetAgentInfo($id, "Ground"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h0060: " & Agent_GetAgentInfo($id, "h0060"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("TerrainNormalX: " & Agent_GetAgentInfo($id, "TerrainNormalX") & " | TerrainNormalY: " & Agent_GetAgentInfo($id, "TerrainNormalY") & " | TerrainNormalZ: " & Agent_GetAgentInfo($id, "TerrainNormalZ"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h0070: " & Agent_GetAgentInfo($id, "h0070"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x74 - 0x80
            Log_Message("X: " & Agent_GetAgentInfo($id, "X") & " | Y: " & Agent_GetAgentInfo($id, "Y") & " | Plane: " & Agent_GetAgentInfo($id, "Plane"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h0080: " & Agent_GetAgentInfo($id, "h0080"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x84 - 0x94
            Log_Message("NameTagX: " & Agent_GetAgentInfo($id, "NameTagX") & " | NameTagY: " & Agent_GetAgentInfo($id, "NameTagY") & " | NameTagZ: " & Agent_GetAgentInfo($id, "NameTagZ"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("VisualEffects: " & Agent_GetAgentInfo($id, "VisualEffects"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h0092: " & Agent_GetAgentInfo($id, "h0092") & " | h0094: " & Agent_GetAgentInfo($id, "h0094"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x9C - Type
            Log_Message("Type: " & Agent_GetAgentInfo($id, "Type") & " | IsItemType: " & Agent_GetAgentInfo($id, "IsItemType") & " | IsGadgetType: " & Agent_GetAgentInfo($id, "IsGadgetType") & " | IsLivingType: " & Agent_GetAgentInfo($id, "IsLivingType"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0xA0 - 0xB4
            Log_Message("MoveX: " & Agent_GetAgentInfo($id, "MoveX") & " | MoveY: " & Agent_GetAgentInfo($id, "MoveY"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h00A8: " & Agent_GetAgentInfo($id, "h00A8"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("RotationCos2: " & Agent_GetAgentInfo($id, "RotationCos2") & " | RotationSin2: " & Agent_GetAgentInfo($id, "RotationSin2"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h00B4: " & Agent_GetAgentInfo($id, "h00B4"), $c_UTILS_Msg_Type_Info, "DevTools")

			If Agent_GetAgentInfo($id, "IsItemType") Then
				Log_Message("=== ItemType Infos ===", $c_UTILS_Msg_Type_Info, "DevTools")
				; 0xC4 - 0xD4
				Log_Message("Owner: " & Agent_GetAgentInfo($id, "Owner") , $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("ItemID: " & Agent_GetAgentInfo($id, "ItemID"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("CanPickUp: " & Agent_GetAgentInfo($id, "CanPickUp"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("ExtraType: " & Agent_GetAgentInfo($id, "ExtraType"), $c_UTILS_Msg_Type_Info, "DevTools")
			EndIf

			If Agent_GetAgentInfo($id, "IsGadgetType") Then
				Log_Message("=== GadgetType Infos ===", $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("ExtraType: " & Agent_GetAgentInfo($id, "ExtraType"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("GadgetID: " & Agent_GetAgentInfo($id, "GadgetID"), $c_UTILS_Msg_Type_Info, "DevTools")
            EndIf

			If Agent_GetAgentInfo($id, "IsLivingType") Then
				Log_Message("=== LivingType Infos ===", $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("Owner: " & Agent_GetAgentInfo($id, "Owner"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h00D4: " & Agent_GetAgentInfo($id, "h00D4"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0xE0 - 0xFC
				Log_Message("AnimationType: " & Agent_GetAgentInfo($id, "AnimationType"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h00E4: " & Agent_GetAgentInfo($id, "h00E4"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("AttackSpeed: " & Agent_GetAgentInfo($id, "AttackSpeed") & " | AttackSpeedModifier: " & Agent_GetAgentInfo($id, "AttackSpeedModifier"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("PlayerNumber: " & Agent_GetAgentInfo($id, "PlayerNumber") & " | AgentModelType: " & Agent_GetAgentInfo($id, "AgentModelType") & " | TransmogNpcId: " & Agent_GetAgentInfo($id, "TransmogNpcId"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("Equipment: " & Agent_GetAgentInfo($id, "Equipment"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x100 - 0x10E
				Log_Message("h0100: " & Agent_GetAgentInfo($id, "h0100"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("Tags: " & Agent_GetAgentInfo($id, "Tags"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h0108: " & Agent_GetAgentInfo($id, "h0108"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("Primary: " & Agent_GetAgentInfo($id, "Primary") & " | Secondary: " & Agent_GetAgentInfo($id, "Secondary") & " | Level: " & Agent_GetAgentInfo($id, "Level") & " | Team: " & Agent_GetAgentInfo($id, "Team"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h010E: " & Agent_GetAgentInfo($id, "h010E") & " | h0110: " & Agent_GetAgentInfo($id, "h0110"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("EnergyRegen: " & Agent_GetAgentInfo($id, "EnergyRegen") & " | Overcast: " & Agent_GetAgentInfo($id, "Overcast") & " | EnergyPercent: " & Agent_GetAgentInfo($id, "EnergyPercent") & " | MaxEnergy: " & Agent_GetAgentInfo($id, "MaxEnergy") & " | CurrentEnergy: " & Agent_GetAgentInfo($id, "CurrentEnergy"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h0124: " & Agent_GetAgentInfo($id, "h0124"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("HPPips: " & Agent_GetAgentInfo($id, "HPPips"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h012C: " & Agent_GetAgentInfo($id, "h012C"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("HP: " & Agent_GetAgentInfo($id, "HP") & " | MaxHP: " & Agent_GetAgentInfo($id, "MaxHP") & " | CurrentHP: " & Agent_GetAgentInfo($id, "CurrentHP"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x138 - Effects
				Log_Message("Effects: " & Agent_GetAgentInfo($id, "Effects") & " | EffectCount: " & Agent_GetAgentInfo($id, "EffectCount") & " | BondCount: " & Agent_GetAgentInfo($id, "BondCount"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("IsBleeding: " & Agent_GetAgentInfo($id, "IsBleeding") & " | IsConditioned: " & Agent_GetAgentInfo($id, "IsConditioned") & " | IsCrippled: " & Agent_GetAgentInfo($id, "IsCrippled") & " | IsDead: " & Agent_GetAgentInfo($id, "IsDead") & " | IsDeepWounded: " & Agent_GetAgentInfo($id, "IsDeepWounded") & " | IsPoisoned: " & Agent_GetAgentInfo($id, "IsPoisoned") & " | IsEnchanted: " & Agent_GetAgentInfo($id, "IsEnchanted") & " | IsDegenHexed: " & Agent_GetAgentInfo($id, "IsDegenHexed") & " | IsHexed: " & Agent_GetAgentInfo($id, "IsHexed") & " | IsWeaponSpelled: " & Agent_GetAgentInfo($id, "IsWeaponSpelled"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x13C - 0x154
				Log_Message("h013C: " & Agent_GetAgentInfo($id, "h013C"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("Hex: " & Agent_GetAgentInfo($id, "Hex"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h0141: " & Agent_GetAgentInfo($id, "h0141"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x154 - ModelState
				Log_Message("ModelState: " & Agent_GetAgentInfo($id, "ModelState") & " | IsKnockedDown: " & Agent_GetAgentInfo($id, "IsKnockedDown") & " | IsMoving: " & Agent_GetAgentInfo($id, "IsMoving") & " | IsAttacking: " & Agent_GetAgentInfo($id, "IsAttacking") & " | IsCasting: " & Agent_GetAgentInfo($id, "IsCasting") & " | IsIdle: " & Agent_GetAgentInfo($id, "IsIdle"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x158 - TypeMap
				Log_Message("TypeMap: " & Agent_GetAgentInfo($id, "TypeMap") & " | InCombatStance: " & Agent_GetAgentInfo($id, "InCombatStance") & " | HasQuest: " & Agent_GetAgentInfo($id, "HasQuest") & " | IsDeadByTypeMap: " & Agent_GetAgentInfo($id, "IsDeadByTypeMap") & " | IsFemale: " & Agent_GetAgentInfo($id, "IsFemale") & " | HasBossGlow: " & Agent_GetAgentInfo($id, "HasBossGlow") & " | IsHidingCap: " & Agent_GetAgentInfo($id, "IsHidingCap") & " | CanBeViewedInPartyWindow: " & Agent_GetAgentInfo($id, "CanBeViewedInPartyWindow") & " | IsSpawned: " & Agent_GetAgentInfo($id, "IsSpawned") & " | IsBeingObserved: " & Agent_GetAgentInfo($id, "IsBeingObserved"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x15C - 0x16C
				Log_Message("h015C: " & Agent_GetAgentInfo($id, "h015C"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("InSpiritRange: " & Agent_GetAgentInfo($id, "InSpiritRange"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x174 - VisibleEffects
				Log_Message("VisibleEffectsPtr: " & Agent_GetAgentInfo($id, "VisibleEffectsPtr") & " | VisibleEffectsPrevLink: " & Agent_GetAgentInfo($id, "VisibleEffectsPrevLink") & " | VisibleEffectsNextNode: " & Agent_GetAgentInfo($id, "VisibleEffectsNextNode"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("VisibleEffectCount: " & Agent_GetAgentInfo($id, "VisibleEffectCount") & " | HasVisibleEffects: " & Agent_GetAgentInfo($id, "HasVisibleEffects"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h017C: " & Agent_GetAgentInfo($id, "h017C"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x180 - 0x190
				Log_Message("LoginNumber: " & Agent_GetAgentInfo($id, "LoginNumber") & " | IsPlayer: " & Agent_GetAgentInfo($id, "IsPlayer") & " | IsNPC: " & Agent_GetAgentInfo($id, "IsNPC"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("AnimationSpeed: " & Agent_GetAgentInfo($id, "AnimationSpeed") & " | AnimationCode: " & Agent_GetAgentInfo($id, "AnimationCode") & " | AnimationId: " & Agent_GetAgentInfo($id, "AnimationId"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h0190: " & Agent_GetAgentInfo($id, "h0190"), $c_UTILS_Msg_Type_Info, "DevTools")
				; 0x1B0 - 0x1BC
				Log_Message("LastStrike: " & Agent_GetAgentInfo($id, "LastStrike") & " | Allegiance: " & Agent_GetAgentInfo($id, "Allegiance") & " | WeaponType: " & Agent_GetAgentInfo($id, "WeaponType") & " | Skill: " & Agent_GetAgentInfo($id, "Skill"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("h01B6: " & Agent_GetAgentInfo($id, "h01B6"), $c_UTILS_Msg_Type_Info, "DevTools")
				Log_Message("WeaponItemType: " & Agent_GetAgentInfo($id, "WeaponItemType") & " | OffhandItemType: " & Agent_GetAgentInfo($id, "OffhandItemType") & " | WeaponItemId: " & Agent_GetAgentInfo($id, "WeaponItemId") & " | OffhandItemId: " & Agent_GetAgentInfo($id, "OffhandItemId"), $c_UTILS_Msg_Type_Info, "DevTools")
			EndIf
		EndIf

		_ImGui_NewLine()

        ; Effect/Buff Info
        _ImGui_SetNextItemWidth(60)
        _ImGui_InputText("Effect SkillID##ag", $g_sInput_SkillID)
        _ImGui_SameLine()
        If _ImGui_Button("Get Effect##ag") Then
            Local $id = Number($g_sInput_AgentID)
            Local $skillID = Number($g_sInput_SkillID)
            Log_Message("=== Effect " & $skillID & " on Agent " & $id & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HasEffect: " & Agent_GetAgentEffectInfo($id, $skillID, "HasEffect"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Duration: " & Agent_GetAgentEffectInfo($id, $skillID, "Duration") & ", TimeRemaining: " & Agent_GetAgentEffectInfo($id, $skillID, "TimeRemaining"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CasterID: " & Agent_GetAgentEffectInfo($id, $skillID, "CasterID") & ", AttributeLevel: " & Agent_GetAgentEffectInfo($id, $skillID, "AttributeLevel"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Buff##ag") Then
            Local $id = Number($g_sInput_AgentID)
            Local $skillID = Number($g_sInput_SkillID)
            Log_Message("=== Buff " & $skillID & " on Agent " & $id & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HasBuff: " & Agent_GetAgentBondInfo($id, $skillID, "HasBond"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BuffID: " & Agent_GetAgentBondInfo($id, $skillID, "BondID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("TargetAgentID: " & Agent_GetAgentBondInfo($id, $skillID, "TargetAgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

		_ImGui_NewLine()

        ; NPC Info
        If _ImGui_Button("NPC Info##ag") Then
            Local $id = Number($g_sInput_AgentID)
            Local $modelID = Agent_GetAgentInfo($id, "PlayerNumber")
            Log_Message("=== NPC ModelID " & $modelID & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Scale: " & Agent_GetNpcInfo($modelID, "Scale") & ", Sex: " & Agent_GetNpcInfo($modelID, "Sex"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Primary: " & Agent_GetNpcInfo($modelID, "Primary") & ", Level: " & Agent_GetNpcInfo($modelID, "Level"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsHenchman: " & Agent_GetNpcInfo($modelID, "IsHenchman") & ", IsHero: " & Agent_GetNpcInfo($modelID, "IsHero"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsSpirit: " & Agent_GetNpcInfo($modelID, "IsSpirit") & ", IsMinion: " & Agent_GetNpcInfo($modelID, "IsMinion") & ", IsPet: " & Party_IsPet($id), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Player Info##ag") Then
            Local $id = Number($g_sInput_AgentID)
            Log_Message("=== Player Agent " & $id & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Name: " & Agent_GetPlayerInfo($id, "Name"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Primary: " & Agent_GetPlayerInfo($id, "Primary") & ", Secondary: " & Agent_GetPlayerInfo($id, "Secondary"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerNumber: " & Agent_GetPlayerInfo($id, "PlayerNumber") & ", PartySize: " & Agent_GetPlayerInfo($id, "PartySize"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ActiveTitle: " & Agent_GetPlayerInfo($id, "ActiveTitle"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Best Target##ag") Then
            Local $best = Agent_GetBestTarget(1320)
            Log_Message("Best Target (1320 range): " & $best, $c_UTILS_Msg_Type_Info, "DevTools")
            If $best > 0 Then $g_sInput_AgentID = String($best)
        EndIf
        _ImGui_Separator()
    EndIf

    ; === ATTRIBUTE ===
    If _ImGui_CollapsingHeader("Attribute##data") Then
        _ImGui_SetNextItemWidth(60)
        _ImGui_InputText("Attr ID##attr", $g_sInput_AttributeID)

        _ImGui_SameLine()
        If _ImGui_Button("Get Name##attr") Then
            Local $attrID = Number($g_sInput_AttributeID)
            Log_Message("Attribute " & $attrID & ": " & Attribute_GetAttributeName($attrID), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All Info##attr") Then
            Local $attrID = Number($g_sInput_AttributeID)
            Log_Message("=== Attribute " & $attrID & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Name: " & Attribute_GetAttributeName($attrID), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ProfessionID: " & Attribute_GetAttributeInfo($attrID, "ProfessionID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AttributeID: " & Attribute_GetAttributeInfo($attrID, "AttributeID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NameID: " & Attribute_GetAttributeInfo($attrID, "NameID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("DescID: " & Attribute_GetAttributeInfo($attrID, "DescID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsPVE: " & Attribute_GetAttributeInfo($attrID, "IsPVE"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Last Modified##attr") Then
            Log_Message("Last Modified: " & Attribute_GetLastModified(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Hero##attr", $g_sInput_HeroIndex)
        _ImGui_SameLine()
        If _ImGui_Button("Get Party Attr##attr") Then
            Local $attrID = Number($g_sInput_AttributeID)
            Local $heroNum = Number($g_sInput_HeroIndex)
            Log_Message("=== Party Attribute " & $attrID & " (Hero " & $heroNum & ") ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HasAttribute: " & Attribute_GetPartyAttributeInfo($attrID, $heroNum, "HasAttribute"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Level: " & Attribute_GetPartyAttributeInfo($attrID, $heroNum, "Level") & ", BaseLevel: " & Attribute_GetPartyAttributeInfo($attrID, $heroNum, "BaseLevel"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BonusLevel: " & Attribute_GetPartyAttributeInfo($attrID, $heroNum, "BonusLevel"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsMaxed: " & Attribute_GetPartyAttributeInfo($attrID, $heroNum, "IsMaxed"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Prof Primary Attrs##attr") Then
            Log_Message("=== Primary Attributes by Profession ===", $c_UTILS_Msg_Type_Info, "DevTools")
            For $i = 1 To 10
                Log_Message("Prof " & $i & ": " & Attribute_GetProfPrimaryAttribute($i), $c_UTILS_Msg_Type_Info, "DevTools")
            Next
        EndIf
        _ImGui_Separator()
    EndIf

    ; === EFFECT ===
    If _ImGui_CollapsingHeader("Effect##data") Then
        _ImGui_SetNextItemWidth(60)
        _ImGui_InputText("Skill ID##eff", $g_sInput_SkillID)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Hero##eff", $g_sInput_HeroIndex)

        _ImGui_SameLine()
        If _ImGui_Button("Get All Args##eff") Then
            Local $skillID = Number($g_sInput_SkillID)
            Local $heroNum = Number($g_sInput_HeroIndex)
            Log_Message("=== Effect " & $skillID & " (Hero " & $heroNum & ") ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Duration: " & Effect_GetEffectArg($skillID, "Duration", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Scale: " & Effect_GetEffectArg($skillID, "Scale", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BonusScale: " & Effect_GetEffectArg($skillID, "BonusScale", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === FRIEND ===
    If _ImGui_CollapsingHeader("Friend##data") Then
        If _ImGui_Button("Get My Status##fr") Then
            Log_Message("My Friend Status: " & Friend_GetMyStatus(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get List Ptr##fr") Then
            Log_Message("Friend List Ptr: " & Friend_GetFriendListPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All List Info##fr") Then
            Log_Message("=== Friend List Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NumberOfFriend: " & Friend_GetFriendListInfo("NumberOfFriend"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NumberOfIgnore: " & Friend_GetFriendListInfo("NumberOfIgnore"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NumberOfPartner: " & Friend_GetFriendListInfo("NumberOfPartner"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NumberOfTrade: " & Friend_GetFriendListInfo("NumberOfTrade"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerStatus: " & Friend_GetFriendListInfo("PlayerStatus"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SetNextItemWidth(120)
        _ImGui_InputText("Name/Index##fr", $g_sInput_FriendName)
        _ImGui_SameLine()
        If _ImGui_Button("Get Friend Info##fr") Then
            Log_Message("=== Friend: " & $g_sInput_FriendName & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Name: " & Friend_GetFriendInfo($g_sInput_FriendName, "Name") & ", Alias: " & Friend_GetFriendInfo($g_sInput_FriendName, "Alias"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CharName: " & Friend_GetFriendInfo($g_sInput_FriendName, "CharName"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Type: " & Friend_GetFriendInfo($g_sInput_FriendName, "Type") & " (" & Friend_GetFriendInfo($g_sInput_FriendName, "TypeName") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Status: " & Friend_GetFriendInfo($g_sInput_FriendName, "Status") & " (" & Friend_GetFriendInfo($g_sInput_FriendName, "StatusName") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MapID: " & Friend_GetFriendInfo($g_sInput_FriendName, "MapID") & ", ZoneID: " & Friend_GetFriendInfo($g_sInput_FriendName, "ZoneID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsOnline: " & Friend_GetFriendInfo($g_sInput_FriendName, "IsOnline") & ", IsFriend: " & Friend_GetFriendInfo($g_sInput_FriendName, "IsFriend") & ", IsIgnored: " & Friend_GetFriendInfo($g_sInput_FriendName, "IsIgnored"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Check IsFriend##fr") Then
            Log_Message($g_sInput_FriendName & " IsFriend: " & Friend_IsFriend($g_sInput_FriendName), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Check IsIgnored##fr") Then
            Log_Message($g_sInput_FriendName & " IsIgnored: " & Friend_IsIgnored($g_sInput_FriendName), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === GAME ===
    If _ImGui_CollapsingHeader("Game##data") Then
        If _ImGui_Button("Get Context Ptr##game") Then
            Log_Message("Game Context Ptr: " & Game_GetGameContextPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All Info##game") Then
            Log_Message("=== Game Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("GameLanguage: " & Game_GetGameInfo("GameLanguage"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AgentContext: " & Game_GetGameInfo("AgentContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MapContext: " & Game_GetGameInfo("MapContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("WorldContext: " & Game_GetGameInfo("WorldContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AccountContext: " & Game_GetGameInfo("AccountContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PartyContext: " & Game_GetGameInfo("PartyContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ItemContext: " & Game_GetGameInfo("ItemContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("GuildContext: " & Game_GetGameInfo("GuildContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("TradeContext: " & Game_GetGameInfo("TradeContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsCinematic: " & Game_GetGameInfo("IsCinematic"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === GUILD ===
    If _ImGui_CollapsingHeader("Guild##data") Then
        If _ImGui_Button("Get Context Ptr##guild") Then
            Log_Message("Guild Context Ptr: " & Guild_GetGuildContextPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All My Guild Info##guild") Then
            Log_Message("=== My Guild Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerName: " & Guild_GetMyGuildInfo("PlayerName"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerGuildIndex: " & Guild_GetMyGuildInfo("PlayerGuildIndex"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerGuildRank: " & Guild_GetMyGuildInfo("PlayerGuildRank"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Announcement: " & Guild_GetMyGuildInfo("Announcement"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AnnouncementAuthor: " & Guild_GetMyGuildInfo("AnnouncementAuthor"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("TownAlliance: " & Guild_GetMyGuildInfo("TownAlliance"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("GuildRosterSize: " & Guild_GetMyGuildInfo("GuildRosterSize"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("GuildHistorySize: " & Guild_GetMyGuildInfo("GuildHistorySize"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Player##guild", $g_sInput_HeroIndex)
        _ImGui_SameLine()
        If _ImGui_Button("Get Player Info##guild") Then
            Local $idx = Number($g_sInput_HeroIndex)
            Log_Message("=== Guild Player " & $idx & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("InvitedName: " & Guild_GetGuildPlayerInfo($idx, "InvitedName"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CurrentName: " & Guild_GetGuildPlayerInfo($idx, "CurrentName"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MemberType: " & Guild_GetGuildPlayerInfo($idx, "MemberType") & ", Status: " & Guild_GetGuildPlayerInfo($idx, "Status"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === ITEM ===
    If _ImGui_CollapsingHeader("Item##data") Then
        If _ImGui_Button("Get Context Ptr##item") Then
            Log_Message("Item Context Ptr: " & Item_GetItemContextPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Inventory Ptr##item") Then
            Log_Message("Inventory Ptr: " & Item_GetInventoryPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Gold/WeaponSet##item") Then
            Log_Message("=== Inventory Quick Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("GoldCharacter: " & Item_GetInventoryInfo("GoldCharacter"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("GoldStorage: " & Item_GetInventoryInfo("GoldStorage"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ActiveWeaponSet: " & Item_GetInventoryInfo("ActiveWeaponSet"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get All Weapon Sets##item") Then
            Log_Message("=== Weapon Sets ===", $c_UTILS_Msg_Type_Info, "DevTools")
            For $i = 0 To 3
                Log_Message("Set " & $i & " Weapon: ModelID=" & Item_GetInventoryInfo("WeaponSet" & $i & "WeaponModelID") & ", ItemID=" & Item_GetInventoryInfo("WeaponSet" & $i & "WeaponItemID"), $c_UTILS_Msg_Type_Info, "DevTools")
                Log_Message("Set " & $i & " Offhand: ModelID=" & Item_GetInventoryInfo("WeaponSet" & $i & "OffhandModelID") & ", ItemID=" & Item_GetInventoryInfo("WeaponSet" & $i & "OffhandItemID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Next
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Bundle##item") Then
            Log_Message("=== Bundle Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BundlePtr: " & Item_GetInventoryInfo("BundlePtr"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BundleItemID: " & Item_GetInventoryInfo("BundleItemID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BundleAgentID: " & Item_GetInventoryInfo("BundleAgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BundleModelID: " & Item_GetInventoryInfo("BundleModelID"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Bag##item", $g_sInput_BagNumber)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Slot##item", $g_sInput_SlotNumber)
        _ImGui_SameLine()
        If _ImGui_Button("Get Item at Slot##item") Then
            Local $bag = Number($g_sInput_BagNumber)
            Local $slot = Number($g_sInput_SlotNumber)
            Local $itemID = Item_GetItemBySlot($bag, $slot)
            If $itemID > 0 Then
                $g_sInput_ItemID = String($itemID)
                Log_Message("Item at Bag " & $bag & " Slot " & $slot & ": ID=" & $itemID, $c_UTILS_Msg_Type_Info, "DevTools")
            Else
                Log_Message("No item at Bag " & $bag & " Slot " & $slot, $c_UTILS_Msg_Type_Warning, "DevTools")
            EndIf
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Bag Info##item") Then
            Local $bag = Number($g_sInput_BagNumber)
            Log_Message("=== Bag " & $bag & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BagType: " & Item_GetBagInfo($bag, "BagType"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ItemCount: " & Item_GetBagInfo($bag, "ItemCount") & ", Slots: " & Item_GetBagInfo($bag, "Slots"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("EmptySlots: " & Item_GetBagInfo($bag, "EmptySlots"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsInventoryBag: " & Item_GetBagInfo($bag, "IsInventoryBag") & ", IsStorage: " & Item_GetBagInfo($bag, "IsStorage"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SetNextItemWidth(60)
        _ImGui_InputText("Item ID##itemid", $g_sInput_ItemID)
        _ImGui_SameLine()
        If _ImGui_Button("Get Full Item Info##item") Then
            Local $itemID = Number($g_sInput_ItemID)
            Log_Message("=== Item " & $itemID & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ModelID: " & Item_GetItemInfoByItemID($itemID, "ModelID") & ", AgentID: " & Item_GetItemInfoByItemID($itemID, "AgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ItemType: " & Item_GetItemInfoByItemID($itemID, "ItemType") & ", Rarity: " & Item_GetItemInfoByItemID($itemID, "Rarity"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Quantity: " & Item_GetItemInfoByItemID($itemID, "Quantity") & ", Value: " & Item_GetItemInfoByItemID($itemID, "Value"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsIdentified: " & Item_GetItemInfoByItemID($itemID, "IsIdentified") & ", Customized: " & Item_GetItemInfoByItemID($itemID, "Customized"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsStackable: " & Item_GetItemInfoByItemID($itemID, "IsStackable") & ", IsInscribable: " & Item_GetItemInfoByItemID($itemID, "IsInscribable"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Bag: " & Item_GetItemInfoByItemID($itemID, "Bag") & ", Slot: " & Item_GetItemInfoByItemID($itemID, "Slot"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Dye1: " & Item_GetItemInfoByItemID($itemID, "Dye1") & ", Dye2: " & Item_GetItemInfoByItemID($itemID, "Dye2") & ", Dye3: " & Item_GetItemInfoByItemID($itemID, "Dye3"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Max Items##item") Then
            Log_Message("Max Items: " & Item_GetMaxItems(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Find by ModelID##item") Then
            Local $modelID = Number($g_sInput_ItemID)
            Local $found = Item_FindItemByModelID($modelID)
            Log_Message("Find ModelID " & $modelID & ": " & $found, $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === MAP ===
    If _ImGui_CollapsingHeader("Map##data") Then
        If _ImGui_Button("Get MapID##map") Then
            Log_Message("Map ID: " & Map_GetMapID(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Uptime##map") Then
            Log_Message("Instance Uptime: " & Round(Map_GetInstanceUpTime() / 1000, 1) & "s", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Region##map") Then
            Log_Message("Region: " & Map_GetRegion() & " (" & Map_GetCurrentRegionType() & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get All Instance Info##map") Then
            Log_Message("=== Instance Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Type: " & Map_GetInstanceInfo("Type"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsOutpost: " & Map_GetInstanceInfo("IsOutpost"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsExplorable: " & Map_GetInstanceInfo("IsExplorable"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsLoading: " & Map_GetInstanceInfo("IsLoading"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All Character Info##map") Then
            Log_Message("=== Character Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerName: " & Map_GetCharacterInfo("PlayerName"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MapID: " & Map_GetCharacterInfo("MapID") & ", CurrentMapID: " & Map_GetCharacterInfo("CurrentMapID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Region: " & Map_GetCharacterInfo("Region") & ", Language: " & Map_GetCharacterInfo("Language"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("DistrictNumber: " & Map_GetCharacterInfo("DistrictNumber"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsExplorable: " & Map_GetCharacterInfo("IsExplorable"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerNumber: " & Map_GetCharacterInfo("PlayerNumber"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Click/Move Coords##map") Then
            Log_Message("Click Coords: " & Map_GetClickCoords(), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Last Move Coords: " & Map_GetLastMoveCoords(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SetNextItemWidth(60)
        _ImGui_InputText("Map ID##mapid", $g_sInput_MapID)
        _ImGui_SameLine()
        If _ImGui_Button("Is Unlocked##map") Then
            Local $mapID = Number($g_sInput_MapID)
            Log_Message("Map " & $mapID & " unlocked: " & Map_IsMapUnlocked($mapID), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All Area Info##map") Then
            Local $mapID = Number($g_sInput_MapID)
            Log_Message("=== Area " & $mapID & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Campaign: " & Map_GetAreaInfo($mapID, "Campaign") & ", Continent: " & Map_GetAreaInfo($mapID, "Continent"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Region: " & Map_GetAreaInfo($mapID, "Region") & ", RegionType: " & Map_GetAreaInfo($mapID, "RegionType"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MinPartySize: " & Map_GetAreaInfo($mapID, "MinPartySize") & ", MaxPartySize: " & Map_GetAreaInfo($mapID, "MaxPartySize"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MinLevel: " & Map_GetAreaInfo($mapID, "MinLevel") & ", MaxLevel: " & Map_GetAreaInfo($mapID, "MaxLevel"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsOnWorldMap: " & Map_GetAreaInfo($mapID, "IsOnWorldMap") & ", IsPvP: " & Map_GetAreaInfo($mapID, "IsPvP"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsVanquishableArea: " & Map_GetAreaInfo($mapID, "IsVanquishableArea"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Current Area Info##map") Then
            Log_Message("=== Current Area ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Campaign: " & Map_GetCurrentAreaInfo("Campaign") & ", Continent: " & Map_GetCurrentAreaInfo("Continent"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Region: " & Map_GetCurrentAreaInfo("Region") & ", RegionType: " & Map_GetCurrentAreaInfo("RegionType"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("X: " & Map_GetCurrentAreaInfo("X") & ", Y: " & Map_GetCurrentAreaInfo("Y"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === MAP CONTEXT ===
    If _ImGui_CollapsingHeader("MapContext##data") Then
        If _ImGui_Button("Get Context Ptr##mapctx") Then
            Log_Message("Map Context Ptr: " & Map_GetMapContextPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All Context Info##mapctx") Then
            Log_Message("=== Map Context Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MapBoundaries: " & Map_GetMapContextInfo("MapBoundaries"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PropsContext: " & Map_GetMapContextInfo("PropsContext"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Terrain: " & Map_GetMapContextInfo("Terrain"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Zones: " & Map_GetMapContextInfo("Zones"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Pathing Info##mapctx") Then
            Log_Message("=== Pathing Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Total Trapezoid Count: " & Map_GetTotalTrapezoidCount(), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Pathing Map Array Size: " & Map_GetPathingMapArrayInfo("Size"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Props Context##mapctx") Then
            Log_Message("Props Context: " & Map_GetPropsContext(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === MATCH ===
    If _ImGui_CollapsingHeader("Match##data") Then
        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Match#", $g_sInput_HeroIndex)
        _ImGui_SameLine()
        If _ImGui_Button("Get All Match Info##match") Then
            Local $matchNum = Number($g_sInput_HeroIndex)
            Log_Message("=== Observer Match " & $matchNum & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MatchID: " & Match_GetObserverMatchInfo($matchNum, "MatchID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MapID: " & Match_GetObserverMatchInfo($matchNum, "MapID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Age: " & Match_GetObserverMatchInfo($matchNum, "Age"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Type: " & Match_GetObserverMatchInfo($matchNum, "Type") & ", State: " & Match_GetObserverMatchInfo($matchNum, "State"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Level: " & Match_GetObserverMatchInfo($matchNum, "Level"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Score1: " & Match_GetObserverMatchInfo($matchNum, "Score1") & ", Score2: " & Match_GetObserverMatchInfo($matchNum, "Score2"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Team1Name: " & Match_GetObserverMatchInfo($matchNum, "Team1Name"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Team2Name: " & Match_GetObserverMatchInfo($matchNum, "Team2Name"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === MERCHANT ===
    If _ImGui_CollapsingHeader("Merchant##data") Then
        If _ImGui_Button("Get Last Transaction##merch") Then
            Log_Message("Last Transaction: " & Merchant_GetLastTransaction(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All Trader Quote##merch") Then
            Log_Message("=== Trader Quote ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("QuoteID: " & Merchant_GetTraderQuoteID(), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CostID: " & Merchant_GetTraderCostID(), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CostValue: " & Merchant_GetTraderCostValue(), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("QuoteInfo: " & Merchant_GetTraderQuoteInfo(), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsValidQuote: " & Merchant_IsValidQuote(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Bases##merch") Then
            Log_Message("Buy Item Base: " & Merchant_GetBuyItemBase(), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Salvage Global: " & Merchant_GetSalvageGlobal(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Clear Quote##merch") Then
            Merchant_ClearTraderQuote()
            Log_Message("Trader Quote Cleared", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === PARTY ===
    If _ImGui_CollapsingHeader("Party##data") Then
        If _ImGui_Button("Get Context Ptr##party") Then
            Log_Message("Party Context Ptr: " & Party_GetPartyContextPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get All Context Info##party") Then
            Log_Message("=== Party Context ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Flags: " & Party_GetPartyContextInfo("Flags"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsHardMode: " & Party_GetPartyContextInfo("IsHardMode") & ", IsDefeated: " & Party_GetPartyContextInfo("IsDefeated"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsPartyLeader: " & Party_GetPartyContextInfo("IsPartyLeader"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerCount: " & Party_GetPartyContextInfo("PlayerCount") & ", HeroCount: " & Party_GetPartyContextInfo("HeroCount"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HenchmenCount: " & Party_GetPartyContextInfo("HenchmenCount") & ", TotalPartySize: " & Party_GetPartyContextInfo("TotalPartySize"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get My Party Info##party") Then
            Log_Message("=== My Party ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PartyID: " & Party_GetMyPartyInfo("PartyID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerMemberSize: " & Party_GetMyPartyInfo("ArrayPlayerPartyMemberSize"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HeroMemberSize: " & Party_GetMyPartyInfo("ArrayHeroPartyMemberSize"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HenchmanMemberSize: " & Party_GetMyPartyInfo("ArrayHenchmanPartyMemberSize"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Mem#", $g_sInput_HeroIndex)
        _ImGui_SameLine()
        If _ImGui_Button("Get Player Member##party") Then
            Local $num = Number($g_sInput_HeroIndex)
            Log_Message("=== Player Member " & $num & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("LoginNumber: " & Party_GetMyPartyPlayerMemberInfo($num, "LoginNumber"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CalledTargetID: " & Party_GetMyPartyPlayerMemberInfo($num, "CalledTargetID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("State: " & Party_GetMyPartyPlayerMemberInfo($num, "State"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsConnected: " & Party_GetMyPartyPlayerMemberInfo($num, "IsConnected") & ", IsTicked: " & Party_GetMyPartyPlayerMemberInfo($num, "IsTicked"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Hero##party") Then
            Local $num = Number($g_sInput_HeroIndex)
            Log_Message("=== Hero " & $num & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AgentID: " & Party_GetMyPartyHeroInfo($num, "AgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HeroID: " & Party_GetMyPartyHeroInfo($num, "HeroID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("OwnerPlayerNumber: " & Party_GetMyPartyHeroInfo($num, "OwnerPlayerNumber"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Level: " & Party_GetMyPartyHeroInfo($num, "Level"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Hench##party") Then
            Local $num = Number($g_sInput_HeroIndex)
            Log_Message("=== Henchman " & $num & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AgentID: " & Party_GetMyPartyHenchmanInfo($num, "AgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Profession: " & Party_GetMyPartyHenchmanInfo($num, "Profession"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Level: " & Party_GetMyPartyHenchmanInfo($num, "Level"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Morale (Me)##party") Then
            Log_Message("=== My Morale ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Morale: " & Party_GetMoraleInfo(-2, "Morale") & "%", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("RawMorale: " & Party_GetMoraleInfo(-2, "RawMorale"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsMaxMorale: " & Party_GetMoraleInfo(-2, "IsMaxMorale") & ", IsMinMorale: " & Party_GetMoraleInfo(-2, "IsMinMorale"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsMoraleBoost: " & Party_GetMoraleInfo(-2, "IsMoraleBoost") & ", IsMoralePenalty: " & Party_GetMoraleInfo(-2, "IsMoralePenalty"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Pet##party") Then
            Local $num = Number($g_sInput_HeroIndex)
            Log_Message("=== Pet " & $num & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AgentID: " & Party_GetPetInfo($num, "AgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("OwnerAgentID: " & Party_GetPetInfo($num, "OwnerAgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PetName: " & Party_GetPetInfo($num, "PetName"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Behavior: " & Party_GetPetInfo($num, "Behavior"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsFighting: " & Party_GetPetInfo($num, "IsFighting") & ", IsGuarding: " & Party_GetPetInfo($num, "IsGuarding"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Hero Flag##party") Then
            Local $num = Number($g_sInput_HeroIndex)
            Log_Message("=== Hero Flag " & $num & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AgentID: " & Party_GetHeroFlagInfo($num, "AgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Behavior: " & Party_GetHeroFlagInfo($num, "Behavior"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("FlagX: " & Party_GetHeroFlagInfo($num, "FlagX") & ", FlagY: " & Party_GetHeroFlagInfo($num, "FlagY"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("LockedTargetID: " & Party_GetHeroFlagInfo($num, "LockedTargetID"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Hero Full Info##party") Then
            Local $num = Number($g_sInput_HeroIndex)
            Log_Message("=== Hero Full " & $num & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HeroID: " & Party_GetHeroInfo($num, "HeroID") & ", AgentID: " & Party_GetHeroInfo($num, "AgentID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Primary: " & Party_GetHeroInfo($num, "Primary") & ", Secondary: " & Party_GetHeroInfo($num, "Secondary"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Level: " & Party_GetHeroInfo($num, "Level"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Name: " & Party_GetHeroInfo($num, "Name"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Minion Count##party") Then
            Local $agentID = Number($g_sInput_AgentID)
            Log_Message("Minion Count (Agent " & $agentID & "): " & Party_GetControlledMinionsInfo($agentID, "MinionCount"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === PLAYER ===
    If _ImGui_CollapsingHeader("Player##data") Then
        If _ImGui_Button("Get Character Name##player") Then
            Log_Message("Character Name: " & Player_GetCharname(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Player_GetCharname()")
        _ImGui_Separator()
    EndIf

    ; === PREGAME ===
    If _ImGui_CollapsingHeader("PreGame##data") Then
        If _ImGui_Button("Get Ptr##pregame") Then
            Log_Message("PreGame Ptr: " & PreGame_Ptr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get FrameID##pregame") Then
            Log_Message("PreGame FrameID: " & PreGame_FrameID(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Chosen Index##pregame") Then
            Log_Message("Chosen Character Index: " & PreGame_ChosenCharacterIndex(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Chosen Character##pregame") Then
            Log_Message("Chosen Character (Index1): " & PreGame_ChosenCharacter(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Index2##pregame") Then
            Log_Message("PreGame Index2: " & PreGame_Index2(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Login Array##pregame") Then
            Log_Message("Login Character Array: " & PreGame_LoginCharacterArray(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Char#", $g_sInput_HeroIndex)
        _ImGui_SameLine()
        If _ImGui_Button("Get Char Name##pregame") Then
            Local $charNum = Number($g_sInput_HeroIndex)
            Log_Message("Character " & $charNum & " Name: " & PreGame_CharName($charNum), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("List All Characters##pregame") Then
            Log_Message("=== All Characters ===", $c_UTILS_Msg_Type_Info, "DevTools")
            For $i = 0 To 7
                Local $name = PreGame_CharName($i)
                If $name <> "" Then
                    Log_Message("Slot " & $i & ": " & $name, $c_UTILS_Msg_Type_Info, "DevTools")
                EndIf
            Next
        EndIf
        _ImGui_Separator()
    EndIf

    ; === QUEST ===
    If _ImGui_CollapsingHeader("Quest##data") Then
        _ImGui_SetNextItemWidth(80)
        _ImGui_InputText("Quest ID##quest", $g_sInput_QuestID)

        _ImGui_SameLine()
        If _ImGui_Button("Get All Info##quest") Then
            Local $questID = Number($g_sInput_QuestID)
            Log_Message("=== Quest " & $questID & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("QuestID: " & Quest_GetQuestInfo($questID, "QuestID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("LogState: " & Quest_GetQuestInfo($questID, "LogState"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsCompleted: " & Quest_GetQuestInfo($questID, "IsCompleted") & ", CanReward: " & Quest_GetQuestInfo($questID, "CanReward"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsIncomplete: " & Quest_GetQuestInfo($questID, "IsIncomplete") & ", IsCurrentQuest: " & Quest_GetQuestInfo($questID, "IsCurrentQuest"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsAreaPrimary: " & Quest_GetQuestInfo($questID, "IsAreaPrimary") & ", IsPrimary: " & Quest_GetQuestInfo($questID, "IsPrimary"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Name: " & Quest_GetQuestInfo($questID, "Name"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NPC: " & Quest_GetQuestInfo($questID, "NPC"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Location: " & Quest_GetQuestInfo($questID, "Location"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Map Info##quest") Then
            Local $questID = Number($g_sInput_QuestID)
            Log_Message("=== Quest " & $questID & " Maps ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MapFrom: " & Quest_GetQuestInfo($questID, "MapFrom") & ", MapTo: " & Quest_GetQuestInfo($questID, "MapTo"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Marker X: " & Quest_GetQuestInfo($questID, "MarkerX") & ", Y: " & Quest_GetQuestInfo($questID, "MarkerY") & ", Z: " & Quest_GetQuestInfo($questID, "MarkerZ"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Description##quest") Then
            Local $questID = Number($g_sInput_QuestID)
            Log_Message("=== Quest " & $questID & " Text ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Description: " & Quest_GetQuestInfo($questID, "Description"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Objectives: " & Quest_GetQuestInfo($questID, "Objectives"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Active Quest##quest") Then
            Local $activeID = World_GetWorldInfo("ActiveQuestID")
            Log_Message("Active Quest ID: " & $activeID, $c_UTILS_Msg_Type_Info, "DevTools")
            If $activeID > 0 Then $g_sInput_QuestID = String($activeID)
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Quest Log Size##quest") Then
            Log_Message("Quest Log Size: " & World_GetWorldInfo("QuestLogSize"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === SKILL ===
    If _ImGui_CollapsingHeader("Skill##data") Then
        _ImGui_SetNextItemWidth(120)
        _ImGui_InputInt("Skill ID##skill", $g_iInput_SkillID, 1, 10)
        If $g_iInput_SkillID < 1 Then $g_iInput_SkillID = 1
        If $g_iInput_SkillID > 3431 Then $g_iInput_SkillID = 3431

        _ImGui_SameLine()
        If _ImGui_Button("All Infos##skill") Then
            Local $id = $g_iInput_SkillID
            Log_Message("=== Skill " & $id & " Infos ===", $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x00 - 0x08
            Log_Message("SkillID: " & Skill_GetSkillInfo($id, "SkillID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("GwVersion: " & Skill_GetSkillInfo($id, "GwVersion"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Campaign: " & Skill_GetSkillInfo($id, "Campaign"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x0C - 0x24
            Log_Message("SkillType: " & Skill_GetSkillInfo($id, "SkillType"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Special: " & Skill_GetSkillInfo($id, "Special"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ComboReq: " & Skill_GetSkillInfo($id, "ComboReq"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("InflictsCondition: " & Skill_GetSkillInfo($id, "InflictsCondition"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("RequireCondition: " & Skill_GetSkillInfo($id, "RequireCondition"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("EffectFlag: " & Skill_GetSkillInfo($id, "EffectFlag"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("WeaponReq: " & Skill_GetSkillInfo($id, "WeaponReq"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x28 - 0x33
            Log_Message("Profession: " & Skill_GetSkillInfo($id, "Profession"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Attribute: " & Skill_GetSkillInfo($id, "Attribute"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Title: " & Skill_GetSkillInfo($id, "Title"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("SkillIDPvP: " & Skill_GetSkillInfo($id, "SkillIDPvP"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Combo: " & Skill_GetSkillInfo($id, "Combo"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Target: " & Skill_GetSkillInfo($id, "Target"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h0032: " & Skill_GetSkillInfo($id, "h0032"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("SkillEquipType: " & Skill_GetSkillInfo($id, "SkillEquipType"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x34 - 0x4C
            Log_Message("Overcast: " & Skill_GetSkillInfo($id, "Overcast"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("EnergyCost: " & Skill_GetSkillInfo($id, "EnergyCost"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HealthCost: " & Skill_GetSkillInfo($id, "HealthCost"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("h0037: " & Skill_GetSkillInfo($id, "h0037"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Adrenaline: " & Skill_GetSkillInfo($id, "Adrenaline"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Activation: " & Skill_GetSkillInfo($id, "Activation"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Aftercast: " & Skill_GetSkillInfo($id, "Aftercast"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Duration0: " & Skill_GetSkillInfo($id, "Duration0") & " | Duration15: " & Skill_GetSkillInfo($id, "Duration15"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Recharge: " & Skill_GetSkillInfo($id, "Recharge"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x50 - 0x58
            Log_Message("h0050: " & Skill_GetSkillInfo($id, "h0050") & " | h0052: " & Skill_GetSkillInfo($id, "h0052") & " | h0054: " & Skill_GetSkillInfo($id, "h0054") & " | h0056: " & Skill_GetSkillInfo($id, "h0056"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("SkillArguments: " & Skill_GetSkillInfo($id, "SkillArguments"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x5C - 0x70
            Log_Message("Scale0: " & Skill_GetSkillInfo($id, "Scale0") & " | Scale15: " & Skill_GetSkillInfo($id, "Scale15"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("BonusScale0: " & Skill_GetSkillInfo($id, "BonusScale0") & " | BonusScale15: " & Skill_GetSkillInfo($id, "BonusScale15"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("EffectConstant1: " & Skill_GetSkillInfo($id, "EffectConstant1") & " | EffectConstant2: " & Skill_GetSkillInfo($id, "EffectConstant2"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x74 - 0x88
            Log_Message("CasterOverheadAnimationID: " & Skill_GetSkillInfo($id, "CasterOverheadAnimationID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CasterBodyAnimationID: " & Skill_GetSkillInfo($id, "CasterBodyAnimationID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("TargetBodyAnimationID: " & Skill_GetSkillInfo($id, "TargetBodyAnimationID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("TargetOverheadAnimationID: " & Skill_GetSkillInfo($id, "TargetOverheadAnimationID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ProjectileAnimation1ID: " & Skill_GetSkillInfo($id, "ProjectileAnimation1ID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ProjectileAnimation2ID: " & Skill_GetSkillInfo($id, "ProjectileAnimation2ID"), $c_UTILS_Msg_Type_Info, "DevTools")
            ; 0x8C - 0xA0
            Log_Message("IconFileID: " & Skill_GetSkillInfo($id, "IconFileID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IconFileID2: " & Skill_GetSkillInfo($id, "IconFileID2"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IconFileIDHD: " & Skill_GetSkillInfo($id, "IconFileIDHD"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Name: " & Skill_GetSkillInfo($id, "Name"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Concise: " & Skill_GetSkillInfo($id, "Concise"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Description: " & Skill_GetSkillInfo($id, "Description"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

		_ImGui_NewLine()

        ; Skillbar section
        _ImGui_Text("--- Skillbar ---")
        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Slot##skillbar", $g_sInput_SkillSlot)
		_ImGui_SameLine()
        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Hero##skill", $g_sInput_HeroIndex)

        If _ImGui_Button("Get Slot Info##skill") Then
            Local $slot = Number($g_sInput_SkillSlot)
            Local $heroNum = Number($g_sInput_HeroIndex)
            Log_Message("=== Skillbar Slot " & $slot & " (Hero " & $heroNum & ") ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("SkillID: " & Skill_GetSkillbarInfo($slot, "SkillID", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsRecharged: " & Skill_GetSkillbarInfo($slot, "IsRecharged", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("RechargeTime: " & Skill_GetSkillbarInfo($slot, "RechargeTime", $heroNum) & "ms", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Adrenaline: " & Skill_GetSkillbarInfo($slot, "Adrenaline", $heroNum) & ", AdrenalineB: " & Skill_GetSkillbarInfo($slot, "AdrenalineB", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Event: " & Skill_GetSkillbarInfo($slot, "Event", $heroNum) & ", HasSkill: " & Skill_GetSkillbarInfo($slot, "HasSkill", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Skillbar Status##skill") Then
            Local $heroNum = Number($g_sInput_HeroIndex)
            Log_Message("=== Skillbar Status (Hero " & $heroNum & ") ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AgentID: " & Skill_GetSkillbarInfo(1, "AgentID", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Disabled: " & Skill_GetSkillbarInfo(1, "Disabled", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Casting: " & Skill_GetSkillbarInfo(1, "Casting", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Queued: " & Skill_GetSkillbarInfo(1, "Queued", $heroNum), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("List All Skillbar##skill") Then
            Local $heroNum = Number($g_sInput_HeroIndex)
            Log_Message("=== Full Skillbar (Hero " & $heroNum & ") ===", $c_UTILS_Msg_Type_Info, "DevTools")
            For $i = 1 To 8
                Local $id = Skill_GetSkillbarInfo($i, "SkillID", $heroNum)
                Local $rech = Skill_GetSkillbarInfo($i, "IsRecharged", $heroNum)
                Log_Message("Slot " & $i & ": ID=" & $id & " Recharged=" & $rech, $c_UTILS_Msg_Type_Info, "DevTools")
            Next
        EndIf

		_ImGui_NewLine()
        _ImGui_InputText("SkillID##aery", $g_sInput_SkillID)
        If _ImGui_Button("Is Skill Learnt##skill") Then
            Local $skillID = Number($g_sInput_SkillID)
            Log_Message("Skill " & $skillID & " learnt: " & World_IsSkillLearnt($skillID), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Dupe Count##skill") Then
            Local $skillID = Number($g_sInput_SkillID)
            Log_Message("Skill " & $skillID & " Duplicate Count: " & World_GetSkillDuplicateCount($skillID), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === TITLE ===
    If _ImGui_CollapsingHeader("Title##data") Then
        _ImGui_SetNextItemWidth(60)
        _ImGui_InputText("Title ID##title", $g_sInput_TitleID)

        _ImGui_SameLine()
        If _ImGui_Button("Get All Info##title") Then
            Local $titleID = Number($g_sInput_TitleID)
            Log_Message("=== Title " & $titleID & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Props: " & Title_GetTitleInfo($titleID, "Props"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CurrentPoints: " & Title_GetTitleInfo($titleID, "CurrentPoints"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CurrentTitleTier: " & Title_GetTitleInfo($titleID, "CurrentTitleTier"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PointsNeededCurrentRank: " & Title_GetTitleInfo($titleID, "PointsNeededCurrentRank"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NextTitleTier: " & Title_GetTitleInfo($titleID, "NextTitleTier"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PointsNeededNextRank: " & Title_GetTitleInfo($titleID, "PointsNeededNextRank"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MaxTitleRank: " & Title_GetTitleInfo($titleID, "MaxTitleRank"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MaxTitleTier: " & Title_GetTitleInfo($titleID, "MaxTitleTier"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Title Array Info##title") Then
            Log_Message("Title Array Ptr: " & World_GetWorldInfo("TitleArray"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Title Array Size: " & World_GetWorldInfo("TitleArraySize"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("List Common Titles##title") Then
            Log_Message("=== Common Titles ===", $c_UTILS_Msg_Type_Info, "DevTools")
            ; Sunspear (0), Lightbringer (1), Kurzick (4), Luxon (5), Norn (7), Asura (6), Deldrimor (8), Ebon Vanguard (9)
            Local $titles[8][2] = [[0, "Sunspear"], [1, "Lightbringer"], [4, "Kurzick"], [5, "Luxon"], [6, "Asura"], [7, "Norn"], [8, "Deldrimor"], [9, "Ebon Vanguard"]]
            For $i = 0 To 7
                Local $pts = Title_GetTitleInfo($titles[$i][0], "CurrentPoints")
                Local $tier = Title_GetTitleInfo($titles[$i][0], "CurrentTitleTier")
                Log_Message($titles[$i][1] & " (ID " & $titles[$i][0] & "): Points=" & $pts & " Tier=" & $tier, $c_UTILS_Msg_Type_Info, "DevTools")
            Next
        EndIf
        _ImGui_Separator()
    EndIf

    ; === TRADE ===
    If _ImGui_CollapsingHeader("Trade##data") Then
        If _ImGui_Button("Get Trade Ptr##trade") Then
            Log_Message("Trade Ptr: " & Trade_GetTradePtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Trade State##trade") Then
            Log_Message("=== Trade State ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("State: " & Trade_GetTradeInfo("State"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsTradeClosed: " & Trade_GetTradeInfo("IsTradeClosed"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsTradeInitiated: " & Trade_GetTradeInfo("IsTradeInitiated"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsPlayerTradeOffered: " & Trade_GetTradeInfo("IsPlayerTradeOffered"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsPlayerTradeAccepted: " & Trade_GetTradeInfo("IsPlayerTradeAccepted"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Player Trade##trade") Then
            Log_Message("=== Player Trade Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerGold: " & Trade_GetTradeInfo("PlayerGold"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerItemsPtr: " & Trade_GetTradeInfo("PlayerItemsPtr"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerItemCount: " & Trade_GetTradeInfo("PlayerItemCount"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Partner Trade##trade") Then
            Log_Message("=== Partner Trade Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PartnerGold: " & Trade_GetTradeInfo("PartnerGold"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PartnerItemsPtr: " & Trade_GetTradeInfo("PartnerItemsPtr"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PartnerItemCount: " & Trade_GetTradeInfo("PartnerItemCount"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SetNextItemWidth(40)
        _ImGui_InputText("Slot##trade", $g_sInput_SlotNumber)
        _ImGui_SameLine()
        If _ImGui_Button("Get Player Item##trade") Then
            Local $slot = Number($g_sInput_SlotNumber)
            Log_Message("=== Player Trade Item " & $slot & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ItemID: " & Trade_GetPlayerTradeItemsInfo($slot, "ItemID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Quantity: " & Trade_GetPlayerTradeItemsInfo($slot, "Quantity"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ModelID: " & Trade_GetPlayerTradeItemsInfo($slot, "ModelID"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Partner Item##trade") Then
            Local $slot = Number($g_sInput_SlotNumber)
            Log_Message("=== Partner Trade Item " & $slot & " ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ItemID: " & Trade_GetPartnerTradeItemsInfo($slot, "ItemID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Quantity: " & Trade_GetPartnerTradeItemsInfo($slot, "Quantity"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ModelID: " & Trade_GetPartnerTradeItemsInfo($slot, "ModelID"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("List Player Items##trade") Then
            Local $items = Trade_GetArrayPlayerTradeItems()
            Log_Message("=== Player Trade Items ===", $c_UTILS_Msg_Type_Info, "DevTools")
            If IsArray($items) And $items[0][0] > 0 Then
                For $i = 1 To $items[0][0]
                    Log_Message("Item " & $i & ": ModelID=" & $items[$i][0] & " Qty=" & $items[$i][1], $c_UTILS_Msg_Type_Info, "DevTools")
                Next
            Else
                Log_Message("No items in trade", $c_UTILS_Msg_Type_Info, "DevTools")
            EndIf
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("List Partner Items##trade") Then
            Local $items = Trade_GetArrayPartnerTradeItems()
            Log_Message("=== Partner Trade Items ===", $c_UTILS_Msg_Type_Info, "DevTools")
            If IsArray($items) And $items[0][0] > 0 Then
                For $i = 1 To $items[0][0]
                    Log_Message("Item " & $i & ": ModelID=" & $items[$i][0] & " Qty=" & $items[$i][1], $c_UTILS_Msg_Type_Info, "DevTools")
                Next
            Else
                Log_Message("No items in trade", $c_UTILS_Msg_Type_Info, "DevTools")
            EndIf
        EndIf
        _ImGui_Separator()
    EndIf

    ; === UI ===
    If _ImGui_CollapsingHeader("UI##data") Then
        If _ImGui_Button("Get Render Disabled##ui") Then
            Log_Message("Render Disabled: " & Ui_GetRenderDisabled(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Render Enabled##ui") Then
            Log_Message("Render Enabled: " & Ui_GetRenderEnabled(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Both##ui") Then
            Log_Message("=== UI Render Status ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Render Disabled: " & Ui_GetRenderDisabled(), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Render Enabled: " & Ui_GetRenderEnabled(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === WORLD ===
    If _ImGui_CollapsingHeader("World##data") Then
        If _ImGui_Button("Get Context Ptr##world") Then
            Log_Message("World Context Ptr: " & World_GetWorldContextPtr(), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Basic Info##world") Then
            Log_Message("=== World Basic Info ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MyID: " & World_GetWorldInfo("MyID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerNumber: " & World_GetWorldInfo("PlayerNumber"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Level: " & World_GetWorldInfo("Level"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Experience: " & World_GetWorldInfo("Experience"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("Morale: " & World_GetWorldInfo("Morale"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("IsHmUnlocked: " & World_GetWorldInfo("IsHmUnlocked"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Points##world") Then
            Log_Message("=== Points ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CurrentBalth: " & World_GetWorldInfo("CurrentBalth") & " / " & World_GetWorldInfo("MaxBalthPoints") & ", TotalEarned: " & World_GetWorldInfo("TotalEarnedBalth"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CurrentKurzick: " & World_GetWorldInfo("CurrentKurzick") & " / " & World_GetWorldInfo("MaxKurzickPoints") & ", TotalEarned: " & World_GetWorldInfo("TotalEarnedKurzick"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CurrentLuxon: " & World_GetWorldInfo("CurrentLuxon") & " / " & World_GetWorldInfo("MaxLuxonPoints") & ", TotalEarned: " & World_GetWorldInfo("TotalEarnedLuxon"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CurrentImperial: " & World_GetWorldInfo("CurrentImperial") & " / " & World_GetWorldInfo("MaxImperialPoints") & ", TotalEarned: " & World_GetWorldInfo("TotalEarnedImperial"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("CurrentSkillPoints: " & World_GetWorldInfo("CurrentSkillPoints") & ", TotalEarned: " & World_GetWorldInfo("TotalEarnedSkillPoints"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Vanquish##world") Then
            Log_Message("=== Vanquish Status ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("FoesKilled: " & World_GetWorldInfo("FoesKilled") & " / " & World_GetWorldInfo("FoesToKill"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Context Ptrs##world") Then
            Log_Message("=== Context Pointers ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AccountInfo: " & World_GetWorldInfo("AccountInfo"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerTeamToken: " & World_GetWorldInfo("PlayerTeamToken"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("SalvageSessionID: " & World_GetWorldInfo("SalvageSessionID"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("EquipmentStatus: " & World_GetWorldInfo("EquipmentStatus"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ActiveQuestID: " & World_GetWorldInfo("ActiveQuestID"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Flag All##world") Then
            Local $flags = World_GetWorldInfo("FlagAll")
            If IsArray($flags) Then
                Log_Message("FlagAll: X=" & $flags[0] & " Y=" & $flags[1] & " Z=" & $flags[2], $c_UTILS_Msg_Type_Info, "DevTools")
            Else
                Log_Message("FlagAll: " & $flags, $c_UTILS_Msg_Type_Info, "DevTools")
            EndIf
        EndIf

        If _ImGui_Button("Get Array Ptrs##world") Then
            Log_Message("=== Array Pointers ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("QuestLog: " & World_GetWorldInfo("QuestLog") & " (Size: " & World_GetWorldInfo("QuestLogSize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HeroFlagArray: " & World_GetWorldInfo("HeroFlagArray") & " (Size: " & World_GetWorldInfo("HeroFlagArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("HeroInfoArray: " & World_GetWorldInfo("HeroInfoArray") & " (Size: " & World_GetWorldInfo("HeroInfoArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("SkillbarArray: " & World_GetWorldInfo("SkillbarArray") & " (Size: " & World_GetWorldInfo("SkillbarArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("TitleArray: " & World_GetWorldInfo("TitleArray") & " (Size: " & World_GetWorldInfo("TitleArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get More Arrays##world") Then
            Log_Message("=== More Arrays ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("NPCArray: " & World_GetWorldInfo("NPCArray") & " (Size: " & World_GetWorldInfo("NPCArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerArray: " & World_GetWorldInfo("PlayerArray") & " (Size: " & World_GetWorldInfo("PlayerArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PetInfoArray: " & World_GetWorldInfo("PetInfoArray") & " (Size: " & World_GetWorldInfo("PetInfoArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PartyAttributeArray: " & World_GetWorldInfo("PartyAttributeArray") & " (Size: " & World_GetWorldInfo("PartyAttributeArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("AgentEffectsArray: " & World_GetWorldInfo("AgentEffectsArray") & " (Size: " & World_GetWorldInfo("AgentEffectsArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Morale Arrays##world") Then
            Log_Message("=== Morale Arrays ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PlayerMoraleInfo: " & World_GetWorldInfo("PlayerMoraleInfo") & " (Size: " & World_GetWorldInfo("PlayerMoraleInfoSize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PartyMoraleInfo: " & World_GetWorldInfo("PartyMoraleInfo") & " (Size: " & World_GetWorldInfo("PartyMoraleInfoSize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("ControlledMinionsArray: " & World_GetWorldInfo("ControlledMinionsArray") & " (Size: " & World_GetWorldInfo("ControlledMinionsArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Get Special Arrays##world") Then
            Log_Message("=== Special Arrays ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MerchItemArray: " & World_GetWorldInfo("MerchItemArray") & " (Size: " & World_GetWorldInfo("MerchItemArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("VanquishedAreasArray: " & World_GetWorldInfo("VanquishedAreasArray") & " (Size: " & World_GetWorldInfo("VanquishedAreasArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MissionObjectiveArray: " & World_GetWorldInfo("MissionObjectiveArray") & " (Size: " & World_GetWorldInfo("MissionObjectiveArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("PartyProfessionArray: " & World_GetWorldInfo("PartyProfessionArray") & " (Size: " & World_GetWorldInfo("PartyProfessionArraySize") & ")", $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf

        If _ImGui_Button("Get Unlocked Arrays##world") Then
            Log_Message("=== Unlocked/Mission Arrays ===", $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("LearnableSkillsArray: " & World_GetWorldInfo("LearnableSkillsArray"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("UnlockedSkillsArray: " & World_GetWorldInfo("UnlockedSkillsArray"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("UnlockedMapArray: " & World_GetWorldInfo("UnlockedMapArray"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MissionsCompletedArray: " & World_GetWorldInfo("MissionsCompletedArray"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MissionsBonusArray: " & World_GetWorldInfo("MissionsBonusArray"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MissionsCompletedHMArray: " & World_GetWorldInfo("MissionsCompletedHMArray"), $c_UTILS_Msg_Type_Info, "DevTools")
            Log_Message("MissionsBonusHMArray: " & World_GetWorldInfo("MissionsBonusHMArray"), $c_UTILS_Msg_Type_Info, "DevTools")
        EndIf
        _ImGui_Separator()
    EndIf
EndFunc

Func _GUI_Tab_QuickTest()
    ; ========================================
    ; QUICK TEST TAB - Ready to use elements
    ; Add your test code in the button handlers
    ; ========================================

    _ImGui_Text("Quick Test - Empty elements ready to be configured")
    _ImGui_Separator()

    ; === BUTTONS SECTION ===
    If _ImGui_CollapsingHeader("Buttons##quicktest", $ImGuiTreeNodeFlags_DefaultOpen) Then
        ; Row 1 - Main action buttons
        If _ImGui_Button("Button 1##qt", 100, 25) Then
            ; TODO: Add your code here
            Log_Message("Button 1 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Button 2##qt", 100, 25) Then
            ; TODO: Add your code here
            Log_Message("Button 2 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Button 3##qt", 100, 25) Then
            ; TODO: Add your code here
            Log_Message("Button 3 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Button 4##qt", 100, 25) Then
            ; TODO: Add your code here
            Log_Message("Button 4 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf

        ; Row 2 - More buttons
        If _ImGui_Button("Button 5##qt", 100, 25) Then
            ; TODO: Add your code here
            Log_Message("Button 5 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Button 6##qt", 100, 25) Then
            ; TODO: Add your code here
            Log_Message("Button 6 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Button 7##qt", 100, 25) Then
            ; TODO: Add your code here
            Log_Message("Button 7 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Button 8##qt", 100, 25) Then
            ; TODO: Add your code here
            Log_Message("Button 8 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf

        ; Row 3 - Small buttons
        If _ImGui_SmallButton("Small 1##qt") Then
            Log_Message("Small 1 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_SmallButton("Small 2##qt") Then
            Log_Message("Small 2 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_SmallButton("Small 3##qt") Then
            Log_Message("Small 3 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_SmallButton("Small 4##qt") Then
            Log_Message("Small 4 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_SmallButton("Small 5##qt") Then
            Log_Message("Small 5 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_SameLine()
        If _ImGui_SmallButton("Small 6##qt") Then
            Log_Message("Small 6 clicked", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === INPUT FIELDS SECTION ===
    If _ImGui_CollapsingHeader("Input Fields##quicktest", $ImGuiTreeNodeFlags_DefaultOpen) Then
        ; Text inputs
        _ImGui_Text("Text Inputs:")
        _ImGui_SetNextItemWidth(150)
        _ImGui_InputText("Input 1##qt", $g_sQuickTest_Input1)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(150)
        _ImGui_InputText("Input 2##qt", $g_sQuickTest_Input2)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(150)
        _ImGui_InputText("Input 3##qt", $g_sQuickTest_Input3)

        _ImGui_SetNextItemWidth(150)
        _ImGui_InputText("Input 4##qt", $g_sQuickTest_Input4)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(150)
        _ImGui_InputText("Input 5##qt", $g_sQuickTest_Input5)

        ; Integer inputs
        _ImGui_Text("Integer Inputs:")
        _ImGui_SetNextItemWidth(100)
        _ImGui_InputInt("Int 1##qt", $g_iQuickTest_Int1)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(100)
        _ImGui_InputInt("Int 2##qt", $g_iQuickTest_Int2)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(100)
        _ImGui_InputInt("Int 3##qt", $g_iQuickTest_Int3)

        ; Float inputs
        _ImGui_Text("Float Inputs:")
        _ImGui_SetNextItemWidth(100)
        _ImGui_InputFloat("Float 1##qt", $g_fQuickTest_Float1, 0.1, 1.0)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(100)
        _ImGui_InputFloat("Float 2##qt", $g_fQuickTest_Float2, 0.1, 1.0)
        _ImGui_Separator()
    EndIf

    ; === CHECKBOXES SECTION ===
    If _ImGui_CollapsingHeader("Checkboxes##quicktest", $ImGuiTreeNodeFlags_DefaultOpen) Then
        _ImGui_Checkbox("Checkbox 1##qt", $g_bQuickTest_Check1)
        _ImGui_SameLine()
        _ImGui_Checkbox("Checkbox 2##qt", $g_bQuickTest_Check2)
        _ImGui_SameLine()
        _ImGui_Checkbox("Checkbox 3##qt", $g_bQuickTest_Check3)

        _ImGui_Checkbox("Checkbox 4##qt", $g_bQuickTest_Check4)
        _ImGui_SameLine()
        _ImGui_Checkbox("Checkbox 5##qt", $g_bQuickTest_Check5)
        _ImGui_SameLine()
        _ImGui_Checkbox("Checkbox 6##qt", $g_bQuickTest_Check6)
        _ImGui_Separator()
    EndIf

    ; === RADIO BUTTONS SECTION ===
    If _ImGui_CollapsingHeader("Radio Buttons##quicktest", $ImGuiTreeNodeFlags_DefaultOpen) Then
        _ImGui_Text("Radio Group 1:")
        _ImGui_RadioButton("Radio 1A##qt", $g_iQuickTest_Radio1, 0)
        _ImGui_SameLine()
        _ImGui_RadioButton("Radio 1B##qt", $g_iQuickTest_Radio1, 1)
        _ImGui_SameLine()
        _ImGui_RadioButton("Radio 1C##qt", $g_iQuickTest_Radio1, 2)
        _ImGui_SameLine()
        _ImGui_RadioButton("Radio 1D##qt", $g_iQuickTest_Radio1, 3)

        _ImGui_Text("Radio Group 2:")
        _ImGui_RadioButton("Radio 2A##qt", $g_iQuickTest_Radio2, 0)
        _ImGui_SameLine()
        _ImGui_RadioButton("Radio 2B##qt", $g_iQuickTest_Radio2, 1)
        _ImGui_SameLine()
        _ImGui_RadioButton("Radio 2C##qt", $g_iQuickTest_Radio2, 2)
        _ImGui_SameLine()
        _ImGui_RadioButton("Radio 2D##qt", $g_iQuickTest_Radio2, 3)
        _ImGui_Separator()
    EndIf

    ; === COMBO/DROPDOWN SECTION ===
    If _ImGui_CollapsingHeader("Dropdowns##quicktest", $ImGuiTreeNodeFlags_DefaultOpen) Then
        _ImGui_SetNextItemWidth(150)
        If _ImGui_BeginCombo("Combo 1##qt", $g_aQuickTest_ComboItems1[$g_iQuickTest_Combo1]) Then
            For $i = 0 To UBound($g_aQuickTest_ComboItems1) - 1
                Local $bSelected1 = ($g_iQuickTest_Combo1 = $i)
                If _ImGui_Selectable($g_aQuickTest_ComboItems1[$i], $bSelected1) Then
                    $g_iQuickTest_Combo1 = $i
                EndIf
            Next
            _ImGui_EndCombo()
        EndIf

        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(150)
        If _ImGui_BeginCombo("Combo 2##qt", $g_aQuickTest_ComboItems2[$g_iQuickTest_Combo2]) Then
            For $i = 0 To UBound($g_aQuickTest_ComboItems2) - 1
                Local $bSelected2 = ($g_iQuickTest_Combo2 = $i)
                If _ImGui_Selectable($g_aQuickTest_ComboItems2[$i], $bSelected2) Then
                    $g_iQuickTest_Combo2 = $i
                EndIf
            Next
            _ImGui_EndCombo()
        EndIf
        _ImGui_Separator()
    EndIf

    ; === SLIDERS SECTION ===
    If _ImGui_CollapsingHeader("Sliders##quicktest", $ImGuiTreeNodeFlags_DefaultOpen) Then
        _ImGui_SetNextItemWidth(200)
        _ImGui_SliderInt("Slider Int 1##qt", $g_iQuickTest_Slider1, 0, 100)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(200)
        _ImGui_SliderInt("Slider Int 2##qt", $g_iQuickTest_Slider2, -100, 100)

        _ImGui_SetNextItemWidth(200)
        _ImGui_SliderFloat("Slider Float##qt", $g_fQuickTest_SliderF1, 0.0, 1.0)
        _ImGui_Separator()
    EndIf

    ; === QUICK ACTION BUTTONS WITH INPUTS ===
    If _ImGui_CollapsingHeader("Quick Actions##quicktest", $ImGuiTreeNodeFlags_DefaultOpen) Then
        ; Action 1: Button with 2 inputs
        _ImGui_Text("Action 1:")
        _ImGui_SetNextItemWidth(80)
        _ImGui_InputText("##qa1_in1", $g_sQuickTest_Input1)
        _ImGui_SameLine()
        _ImGui_SetNextItemWidth(80)
        _ImGui_InputText("##qa1_in2", $g_sQuickTest_Input2)
        _ImGui_SameLine()
        If _ImGui_Button("Execute 1##qa", 80, 0) Then
            ; TODO: Add your code here
            Log_Message("Action 1: " & $g_sQuickTest_Input1 & ", " & $g_sQuickTest_Input2, $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf

        ; Action 2: Button with checkbox
        _ImGui_Text("Action 2:")
        _ImGui_Checkbox("Option##qa2", $g_bQuickTest_Check1)
        _ImGui_SameLine()
        If _ImGui_Button("Execute 2##qa", 80, 0) Then
            ; TODO: Add your code here
            Log_Message("Action 2: Option=" & $g_bQuickTest_Check1, $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf

        ; Action 3: Button with combo
        _ImGui_Text("Action 3:")
        _ImGui_SetNextItemWidth(120)
        If _ImGui_BeginCombo("##qa3_combo", $g_aQuickTest_ComboItems1[$g_iQuickTest_Combo1]) Then
            For $i = 0 To UBound($g_aQuickTest_ComboItems1) - 1
                Local $bSelected3 = ($g_iQuickTest_Combo1 = $i)
                If _ImGui_Selectable($g_aQuickTest_ComboItems1[$i] & "##qa3", $bSelected3) Then
                    $g_iQuickTest_Combo1 = $i
                EndIf
            Next
            _ImGui_EndCombo()
        EndIf
        _ImGui_SameLine()
        If _ImGui_Button("Execute 3##qa", 80, 0) Then
            ; TODO: Add your code here
            Log_Message("Action 3: Selected=" & $g_aQuickTest_ComboItems1[$g_iQuickTest_Combo1], $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_Separator()
    EndIf

    ; === LOG CURRENT VALUES ===
    If _ImGui_CollapsingHeader("Debug Values##quicktest") Then
        If _ImGui_Button("Log All Values##qt", 150, 0) Then
            Log_Message("=== Quick Test Values ===", $c_UTILS_Msg_Type_Info, "QuickTest")
            Log_Message("Inputs: " & $g_sQuickTest_Input1 & ", " & $g_sQuickTest_Input2 & ", " & $g_sQuickTest_Input3 & ", " & $g_sQuickTest_Input4 & ", " & $g_sQuickTest_Input5, $c_UTILS_Msg_Type_Info, "QuickTest")
            Log_Message("Ints: " & $g_iQuickTest_Int1 & ", " & $g_iQuickTest_Int2 & ", " & $g_iQuickTest_Int3, $c_UTILS_Msg_Type_Info, "QuickTest")
            Log_Message("Floats: " & $g_fQuickTest_Float1 & ", " & $g_fQuickTest_Float2, $c_UTILS_Msg_Type_Info, "QuickTest")
            Log_Message("Checks: " & $g_bQuickTest_Check1 & ", " & $g_bQuickTest_Check2 & ", " & $g_bQuickTest_Check3 & ", " & $g_bQuickTest_Check4 & ", " & $g_bQuickTest_Check5 & ", " & $g_bQuickTest_Check6, $c_UTILS_Msg_Type_Info, "QuickTest")
            Log_Message("Radio1: " & $g_iQuickTest_Radio1 & ", Radio2: " & $g_iQuickTest_Radio2, $c_UTILS_Msg_Type_Info, "QuickTest")
            Log_Message("Combo1: " & $g_iQuickTest_Combo1 & " (" & $g_aQuickTest_ComboItems1[$g_iQuickTest_Combo1] & ")", $c_UTILS_Msg_Type_Info, "QuickTest")
            Log_Message("Combo2: " & $g_iQuickTest_Combo2 & " (" & $g_aQuickTest_ComboItems2[$g_iQuickTest_Combo2] & ")", $c_UTILS_Msg_Type_Info, "QuickTest")
            Log_Message("Sliders: " & $g_iQuickTest_Slider1 & ", " & $g_iQuickTest_Slider2 & ", " & $g_fQuickTest_SliderF1, $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf

        _ImGui_SameLine()
        If _ImGui_Button("Reset All##qt", 100, 0) Then
            $g_sQuickTest_Input1 = ""
            $g_sQuickTest_Input2 = ""
            $g_sQuickTest_Input3 = ""
            $g_sQuickTest_Input4 = ""
            $g_sQuickTest_Input5 = ""
            $g_iQuickTest_Int1 = 0
            $g_iQuickTest_Int2 = 0
            $g_iQuickTest_Int3 = 0
            $g_fQuickTest_Float1 = 0.0
            $g_fQuickTest_Float2 = 0.0
            $g_bQuickTest_Check1 = False
            $g_bQuickTest_Check2 = False
            $g_bQuickTest_Check3 = False
            $g_bQuickTest_Check4 = False
            $g_bQuickTest_Check5 = False
            $g_bQuickTest_Check6 = False
            $g_iQuickTest_Radio1 = 0
            $g_iQuickTest_Radio2 = 0
            $g_iQuickTest_Combo1 = 0
            $g_iQuickTest_Combo2 = 0
            $g_iQuickTest_Slider1 = 50
            $g_iQuickTest_Slider2 = 0
            $g_fQuickTest_SliderF1 = 0.5
            Log_Message("All values reset", $c_UTILS_Msg_Type_Info, "QuickTest")
        EndIf
        _ImGui_Separator()
    EndIf
EndFunc
#EndRegion Tab Functions

#Region GUI Helper Functions
Func _GUI_MenuBar()
    If _ImGui_BeginMenuBar() Then
        If _ImGui_BeginMenu("Menu") Then
            If _ImGui_MenuItem("Debug Mode", "", $b_GUI_CheckBox_GUI_DebugMode) Then
                $g_b_Event_ToggleDebug = True
            EndIf

            If _ImGui_MenuItem("Always On Top", "", $b_GUI_CheckBox_OnTop) Then
                $g_b_Event_ToggleOnTop = True
            EndIf

            _ImGui_Separator()

            If _ImGui_MenuItem("Exit") Then
                $g_b_Event_Exit = True
            EndIf

            _ImGui_EndMenu()
        EndIf
        _ImGui_EndMenuBar()
    EndIf
EndFunc

Func _GUI_AddOns_LogConsole()
    Local Static $iLastMessageCount = 0
    Local $iCurrentMessageCount = UBound($a_UTILS_Log_Messages)

    _ImGui_Text("Debug Console:")
    ; Use -1 for height to fill available space, leave room for buttons
    _ImGui_BeginChild("DebugConsole", -1, -30, True, $ImGuiWindowFlags_HorizontalScrollbar)

    ; Check if user is at the bottom before rendering messages
    Local $fScrollY = _ImGui_GetScrollY()
    Local $fScrollMaxY = _ImGui_GetScrollMaxY()
    Local $bWasAtBottom = ($fScrollMaxY <= 0) Or ($fScrollY >= $fScrollMaxY - 10)

    For $i = 0 To $iCurrentMessageCount - 1
        ; Simplified format for right panel: [Type] [Author] Message
        _ImGui_Text("[")
        _ImGui_SameLine(0, 0)
        _ImGui_TextColored($a_UTILS_Log_Messages[$i][2], $a_UTILS_Log_Messages[$i][3])
        _ImGui_SameLine(0, 0)
        _ImGui_Text("] ")
        _ImGui_SameLine(0, 0)
        _ImGui_TextColored($a_UTILS_Log_Messages[$i][6], $a_UTILS_Log_Messages[$i][7])
    Next

    ; Auto-scroll only if there are new messages AND user was at the bottom
    If $iCurrentMessageCount > $iLastMessageCount And $bWasAtBottom Then
        _ImGui_SetScrollFromPosY("DebugConsole", -0.05)
    EndIf
    $iLastMessageCount = $iCurrentMessageCount

    _ImGui_EndChild()

    If _ImGui_Button("Clear##console") Then
        $g_b_Event_ClearConsole = True
    EndIf
    _ImGui_SameLine()
    If _ImGui_Button("Copy##console") Then
        $g_b_Event_CopyConsole = True
    EndIf
EndFunc

Func _GUI_CopyConsoleToClipboard()
    Local $sConsoleText = ""
    For $i = 0 To UBound($a_UTILS_Log_Messages) - 1
        Local $sLine = "[" & $a_UTILS_Log_Messages[$i][0] & "] - [" & $a_UTILS_Log_Messages[$i][2] & "] - [" & $a_UTILS_Log_Messages[$i][4] & "] " & $a_UTILS_Log_Messages[$i][6]
        $sConsoleText &= $sLine & @CRLF
    Next
    ClipPut($sConsoleText)
    Log_Message("Console copied to clipboard", $c_UTILS_Msg_Type_Info, "GUI")
EndFunc

Func _GUI_ExitApp()
    AdlibUnRegister("_GUI_Handle")
    AdlibUnRegister("ProcessEvents")
    Exit
EndFunc
#EndRegion GUI Helper Functions

#Region Bot Functions
Func StartBot()
    If $Selected_Char = "" Or $Selected_Char = "Select Character..." Then
        Log_Message("Please select a character first!", $c_UTILS_Msg_Type_Warning, "StartBot")
        $s_GUI_Status = "No character selected"
        Return
    EndIf

    Log_Message("Connecting to character: " & $Selected_Char, $c_UTILS_Msg_Type_Info, "StartBot")
    $s_GUI_Status = "Connecting..."

    $g_s_MainCharName = $Selected_Char

    Local $result = 0
    If $ProcessID Then
        $proc_id_int = Number($ProcessID, 2)
        $result = Core_Initialize($proc_id_int, True)
    Else
        $result = Core_Initialize($Selected_Char, True)
    EndIf

    If $result = 0 Then
        Log_Message("Failed to initialize GwAu3 Core!", $c_UTILS_Msg_Type_Error, "StartBot")
        $s_GUI_Status = "Failed to connect"
        Return
    EndIf

    $Bot_Core_Initialized = True
    $s_GUI_Status = "Connected"

    Log_Message("Connected to " & player_GetCharname(), $c_UTILS_Msg_Type_Info, "StartBot")
EndFunc

Func StopBot()
    Log_Message("Disconnecting...", $c_UTILS_Msg_Type_Info, "StopBot")

    $b_GUI_BotRunning = False
    $Bot_Core_Initialized = False
    $s_GUI_Status = "Disconnected"

    Log_Message("Disconnected", $c_UTILS_Msg_Type_Info, "StopBot")
EndFunc

Func RefreshCharacterList()
    Log_Message("Refreshing character list...", $c_UTILS_Msg_Type_Info, "Refresh")
    Local $sCharNames = Scanner_GetLoggedCharNames()

    ReDim $g_aCharNames[1]
    $g_aCharNames[0] = "Select Character..."

    If $sCharNames <> "" Then
        Local $aTempNames = StringSplit($sCharNames, "|", 2)
        For $i = 0 To UBound($aTempNames) - 1
            _ArrayAdd($g_aCharNames, $aTempNames[$i])
        Next
        Log_Message("Found " & (UBound($g_aCharNames) - 1) & " characters", $c_UTILS_Msg_Type_Info, "Refresh")
    Else
        Log_Message("No characters found", $c_UTILS_Msg_Type_Warning, "Refresh")
    EndIf

    If $Selected_Char <> "" And $Selected_Char <> "Select Character..." Then
        For $i = 1 To UBound($g_aCharNames) - 1
            If $g_aCharNames[$i] = $Selected_Char Then
                $i_Number_CharName = $i
                ExitLoop
            EndIf
        Next
    Else
        $i_Number_CharName = 0
        $Selected_Char = ""
    EndIf
EndFunc
#EndRegion Bot Functions

#Region Utility Functions
Func _LogCallback($a_s_Message, $a_e_MsgType, $a_s_Author)
    Local $l_i_UtilsMsgType
    Switch $a_e_MsgType
        Case $GC_I_LOG_MSGTYPE_DEBUG
            $l_i_UtilsMsgType = $c_UTILS_Msg_Type_Debug
        Case $GC_I_LOG_MSGTYPE_INFO
            $l_i_UtilsMsgType = $c_UTILS_Msg_Type_Info
        Case $GC_I_LOG_MSGTYPE_WARNING
            $l_i_UtilsMsgType = $c_UTILS_Msg_Type_Warning
        Case $GC_I_LOG_MSGTYPE_ERROR
            $l_i_UtilsMsgType = $c_UTILS_Msg_Type_Error
        Case $GC_I_LOG_MSGTYPE_CRITICAL
            $l_i_UtilsMsgType = $c_UTILS_Msg_Type_Critical
        Case Else
            $l_i_UtilsMsgType = $c_UTILS_Msg_Type_Info
    EndSwitch

    _Utils_LogMessage($a_s_Message, $l_i_UtilsMsgType, $a_s_Author)
EndFunc
#EndRegion Utility Functions
