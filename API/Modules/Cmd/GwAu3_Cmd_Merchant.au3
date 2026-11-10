#include-once

;~ Description: Internal use for BuyItem()
Func Merchant_GetMerchantItemsBase()
    Local $l_ai_Offset[4] = [0, 0x18, 0x2C, 0x24]
    Local $l_av_Return = Memory_ReadPtr($g_p_BasePointer, $l_ai_Offset)
    Return $l_av_Return[1]
EndFunc   ;==>GetMerchantItemsBase

;~ Description: Internal use for BuyItem()
Func Merchant_GetMerchantItemsSize()
    Local $l_ai_Offset[4] = [0, 0x18, 0x2C, 0x28]
    Local $l_av_Return = Memory_ReadPtr($g_p_BasePointer, $l_ai_Offset)
    Return $l_av_Return[1]
EndFunc   ;==>GetMerchantItemsSize

; Fetches ItemPtr of specified item, ModelID (Mode = 0) / ItemSlot (Mode = 1)
Func Merchant_GetMerchantItemPtr($a_i_Val, $a_i_Mode = 0)
	Local $l_p_MerchantBase = Merchant_GetMerchantItemsBase()
	Local $l_i_ItemID = 0, $l_p_ItemPtr = 0

	For $i = 0 To Merchant_GetMerchantItemsSize() -1
		$l_i_ItemID = Memory_Read($l_p_MerchantBase + 0x4 * $i)
		If $l_i_ItemID = 0 Then ContinueLoop

        $l_p_ItemPtr = Item_GetItemPtr($l_i_ItemID)
        If $l_p_ItemPtr = 0 Then ContinueLoop

        Switch $a_i_Mode
            Case 0
                If Memory_Read($l_p_ItemPtr + 0x2C) = $a_i_Val Then Return $l_p_ItemPtr
            Case 1
                If $i + 1 = $a_i_Val Then Return $l_p_ItemPtr
            Case Else
                Return 0
        EndSwitch
	Next
EndFunc   ;==>GetMerchantItemPtrByModelId

;~ Description: Internal use for buy an item, provide $a_s_ModString for runes and $a_i_ExtraID for dye
;~ Limited functionality when buying an item that was previously sold in the same map instance
Func Merchant_BuyItem($a_i_ModelID, $a_i_Quantity = 1, $a_b_Trader = False, $a_s_ModString = "", $a_i_ExtraID = -1)
	If $a_b_Trader Then
        ; Search for item with matching ModelID not in the players inventory
        Local $l_i_ItemArray = Item_GetItemArray()
        Local $l_p_Item, $l_i_ItemID, $l_i_ItemModelID
        Local $l_b_FoundItem = False

        For $i = 1 To $l_i_ItemArray[0]
            $l_p_Item = $l_i_ItemArray[$i]

            If Memory_Read($l_p_Item + 0x2C, 'dword') <> $a_i_ModelID Then ContinueLoop
            If Memory_Read($l_p_Item + 0xC, 'ptr') <> 0 Then ContinueLoop ; BagPtr (item in player inventory)
            If Memory_Read($l_p_Item + 0x4, 'dword') <> 0 Then ContinueLoop ; AgentID (item on the ground)

            If $a_s_ModString == "" And $a_i_ExtraID = -1 Then
                $l_b_FoundItem = True
                ExitLoop
            ElseIf $a_s_ModString <> "" And $a_i_ExtraID = -1 Then
                If StringInStr(Item_GetModStruct($l_p_Item), $a_s_ModString) > 0 Then
                    $l_b_FoundItem = True
                    ExitLoop
                EndIf
            ElseIf $a_s_ModString == "" And $a_i_ExtraID <> -1 Then
                If Memory_Read($l_p_Item + 0x22, 'short') = $a_i_ExtraID Then
                    $l_b_FoundItem = True
                    ExitLoop
                EndIf
            EndIf
        Next

        If Not $l_b_FoundItem Then Return False

        For $i = 1 To $a_i_Quantity
            ; Save current QuoteID for later reference
            Local $l_i_QuoteID = Memory_Read($g_i_TraderQuoteID)

            ; Request quote
            $l_i_ItemID = Item_ItemID($l_p_Item)
            DllStructSetData($g_d_RequestQuote, 2, $l_i_ItemID)
            Core_Enqueue($g_p_RequestQuote, 8)

            ; Wait for quote
            Local $l_i_Deadlock = TimerInit()
            Local $l_i_Timeout = 5000

            Do
                Sleep(36)
                Local $l_i_NewQuoteID = Memory_Read($g_i_TraderQuoteID)
            Until $l_i_NewQuoteID <> $l_i_QuoteID Or TimerDiff($l_i_Deadlock) > $l_i_Timeout

            If TimerDiff($l_i_Deadlock) > $l_i_Timeout Then Return False

            ; Check if we have valid trader cost data
            Local $l_i_CostID = Memory_Read($g_i_TraderCostID)
            Local $l_f_CostValue = Memory_Read($g_f_TraderCostValue)

            If $l_i_CostID = 0 Or $l_f_CostValue = 0 Then Return False
            If $l_f_CostValue > Item_GetInventoryInfo("GoldCharacter") Then Return False

            ; Execute trader buy
            Core_Enqueue($g_p_TraderBuy, 4)

            ; Wait for transaction
            Sleep(36)
        Next

        Log_Debug("Bought from merchant: Item " & $l_i_ItemID & " x" & $a_i_Quantity, "TradeMod", $g_h_EditText)
        Return True

    Else
        ; Standard merchant buy - search by ModelID
        Local $l_p_MerchantItemBase = Merchant_GetMerchantItemsBase()
        If $l_p_MerchantItemBase = 0 Then Return False

        Local $l_i_MerchantItemCount = Merchant_GetMerchantItemsSize()
        Local $l_p_Item, $l_i_ItemID, $l_i_ItemModelID, $l_i_ItemValue
        Local $l_b_FoundItem = False

        ; Search for ModelID in merchant's items
        For $i = 0 To $l_i_MerchantItemCount - 1
            $l_i_ItemID = Memory_Read($l_p_MerchantItemBase + 0x4 * $i)
            $l_p_Item = Item_GetItemPtr($l_i_ItemID)
            If $l_p_Item = 0 Then ContinueLoop

            $l_i_ItemModelID = Memory_Read($l_p_Item + 0x2C)
            If $l_i_ItemModelID <> $a_i_ModelID Then ContinueLoop

            If $a_i_ExtraID = -1 Then
                $l_i_ItemValue = Memory_Read($l_p_Item + 0x24, 'short')
                $l_b_FoundItem = True
                ExitLoop
            Else
                Local $l_i_ItemExtraID = Memory_Read($l_p_Item + 0x22, 'short')
                If $l_i_ItemExtraID = $a_i_ExtraID Then
                    $l_i_ItemValue = Memory_Read($l_p_Item + 0x24, 'short')
                    $l_b_FoundItem = True
                    ExitLoop
                EndIf
            EndIf
        Next

        If Not $l_b_FoundItem Then Return False

        Local $l_i_TotalCost = $a_i_Quantity * ($l_i_ItemValue * 2)
        If $l_i_TotalCost > Item_GetInventoryInfo("GoldCharacter") Then Return False

        DllStructSetData($g_d_BuyItem, 2, $a_i_Quantity)
        DllStructSetData($g_d_BuyItem, 3, $l_i_ItemID)
        DllStructSetData($g_d_BuyItem, 4, $l_i_TotalCost)
        DllStructSetData($g_d_BuyItem, 5, Memory_GetValue('BuyItemBase'))

        Core_Enqueue($g_p_BuyItem, 20)
        Log_Debug("Bought from merchant: Item " & $l_i_ItemID & " x" & $a_i_Quantity, "TradeMod", $g_h_EditText)

        Return True
    EndIf
EndFunc ;==>Merchant_BuyItem

;~ Description: Internal use for selling an item, provide
Func Merchant_SellItem($a_v_Item, $a_i_Quantity = 0, $a_b_Trader = False)
    Local $l_p_Item = Item_GetItemPtr($a_v_Item)
    Local $l_i_ItemID = Item_ItemID($a_v_Item)
    Local $l_i_ItemQuantity = Memory_Read($l_p_Item + 0x4C, 'short')

    If $l_i_ItemQuantity < 0 Then Return False

    ; "SellAll": Set quantity to stack count, but keep track if original was 0
    Local $l_b_SellAll = ($a_i_Quantity = 0)
    If $l_b_SellAll Or $a_i_Quantity > $l_i_ItemQuantity Then
        $a_i_Quantity = $l_i_ItemQuantity
    EndIf

    If $a_b_Trader Then
        ; Trader sell process - one by one
        Local $l_i_SoldCount = 0, $l_i_SellingThreshold = 1
        Local $l_b_IsCommonMaterial = Item_GetItemIsCommonMaterial($l_p_Item)
        Local $l_i_ItemModelID = Memory_Read($l_p_Item + 0x2C, "dword")

        If $l_b_IsCommonMaterial Then
            $l_i_SellingThreshold = 10
            $a_i_Quantity = Int($a_i_Quantity / 10)
        EndIf

        For $i = 1 To $a_i_Quantity
            ; Request quote
            DllStructSetData($g_d_RequestQuoteSell, 2, $l_i_ItemID)
            Core_Enqueue($g_p_RequestQuoteSell, 8)

            ; Wait for quote response
            Local $l_i_Timeout = TimerInit()
            Do
                Sleep(50)
                Local $l_i_CostID = Memory_Read($g_i_TraderCostID, 'dword')
            Until $l_i_CostID = $l_i_ItemID Or TimerDiff($l_i_Timeout) > 2000

			; Check if quote received
            If TimerDiff($l_i_Timeout) > 2000 Then
                Log_Warning("Trader quote timeout for item " & $l_i_ItemID & " (iteration " & $i & ")", "TradeMod", $g_h_EditText)
                ExitLoop
            EndIf

            ; Execute trader sell
            Local $l_i_CostValue = Memory_Read($g_f_TraderCostValue, 'dword')
            Core_Enqueue($g_p_TraderSell, 4)

            ; Wait a bit for transaction to complete
            Sleep(250)

            $l_i_SoldCount += 1

            ; Check if item still exists (stack might be depleted)
            Local $l_b_ItemInInventory = (Memory_Read($l_p_Item + 0xC, 'short') <> 0)
            If Not $l_b_ItemInInventory Then ExitLoop

            Local $l_i_CurrentQuantity = Memory_Read($l_p_Item + 0x4C, 'short')
            If $l_i_CurrentQuantity < $l_i_SellingThreshold Then ExitLoop
        Next

        Log_Debug("Sold to trader: Item " & $l_i_ItemID & " x" & $l_i_SoldCount & " (requested: " & $a_i_Quantity & ")", "TradeMod", $g_h_EditText)

    Else
        ; Standard merchant sell - can sell multiple at once
        Local $l_i_Value = Memory_Read($l_p_Item + 0x24, 'short')
        Local $l_i_TotalValue

        If $l_b_SellAll Then
            $l_i_TotalValue = $l_i_ItemQuantity * $l_i_Value
            DllStructSetData($g_d_SellItem, 2, 0)
        Else
            $l_i_TotalValue = $a_i_Quantity * $l_i_Value
            DllStructSetData($g_d_SellItem, 2, $a_i_Quantity)
        EndIf
        DllStructSetData($g_d_SellItem, 3, $l_i_ItemID)
        DllStructSetData($g_d_SellItem, 4, $l_i_TotalValue)

        Core_Enqueue($g_p_SellItem, 16)
        Log_Debug("Sold to merchant: Item " & $l_i_ItemID & " x" & $a_i_Quantity, "TradeMod", $g_h_EditText)
    EndIf

    Return True
EndFunc ;==>Merchant_SellItem

;~ Description: $a_ai2_ReqMaterials expects a 2D array with [[Material1, Count1],...,[MaterialN, CountN]]; materials need to be in the order shown in the recipe
Func Merchant_CraftItem($a_i_CraftedItemModelID, $a_i_Price, $a_ai2_ReqMaterials, $a_i_Quantity = 1)
    Local Const $LC_AI_BAG_LIST[4] = [$GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2]
    Local Const $LC_I_MAX_BAG_SLOTS = 60
    Local Const $LC_I_OFFSET_ITEMID = 0x0
    Local Const $LC_I_OFFSET_MODELID = 0x2C
    Local Const $LC_I_OFFSET_QUANTITY = 0x4C

    If $a_i_CraftedItemModelID <= 0 Then Return False
    If $a_i_Quantity <= 0 Or $a_i_Quantity > $GC_I_MERCHANT_MAX_ITEM_STACK Then Return False

    Local $l_i_Price_Total = $a_i_Price * $a_i_Quantity
    If $l_i_Price_Total > Item_GetInventoryInfo("GoldCharacter") Then Return False

    Static $s_i_LastMaterialItemIDCount = 0
    Static $s_d_CraftItemStruct, $s_p_CraftItemStructPtr

    Local $l_i_ReqMaterialCount = UBound($a_ai2_ReqMaterials)
    If $l_i_ReqMaterialCount <= 0 Then Return False

    Static $s_d_ItemStruct = DllStructCreate( _
        "dword ItemID;" & _
        "byte[" & ($LC_I_OFFSET_MODELID - ($LC_I_OFFSET_ITEMID + 4)) & "];" & _
        "dword ModelID;" & _
        "byte[" & ($LC_I_OFFSET_QUANTITY - ($LC_I_OFFSET_MODELID + 4)) & "];" & _
        "short Quantity" _
    )
    Static $s_i_ItemStructSize = DllStructGetSize($s_d_ItemStruct)

    Local $l_av2_Inventory[$LC_I_MAX_BAG_SLOTS][4]
    Local $l_i_InventoryIdx = 0

    For $bag In $LC_AI_BAG_LIST
        Local $l_p_BagPtr = Item_GetBagPtr($bag)
        If $l_p_BagPtr = 0 Then ContinueLoop

        Local $l_ap_ItemArray = Item_GetBagItemArray($bag)
        Local $l_i_ItemCount = $l_ap_ItemArray[0]

        For $item = 1 To $l_i_ItemCount
            Local $l_p_ItemPtr = $l_ap_ItemArray[$item]
            If $l_p_ItemPtr = 0 Then ContinueLoop

            DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                "handle", $g_h_GWProcess, _
                "ptr", $l_p_ItemPtr, _
                "struct*", $s_d_ItemStruct, _
                "ulong_ptr", $s_i_ItemStructSize, _
                "ulong_ptr*", 0 _
            )

            Local $l_b_IsReqMaterial = False
            Local $l_i_ModelID = DllStructGetData($s_d_ItemStruct, "ModelID")
            For $reqMaterial = 0 To $l_i_ReqMaterialCount - 1
                If $a_ai2_ReqMaterials[$reqMaterial][0] = $l_i_ModelID Then
                    $l_b_IsReqMaterial = True
                    ExitLoop
                EndIf
            Next

            If Not $l_b_IsReqMaterial Then ContinueLoop

            $l_av2_Inventory[$l_i_InventoryIdx][0] = $l_p_ItemPtr
            $l_av2_Inventory[$l_i_InventoryIdx][1] = DllStructGetData($s_d_ItemStruct, "ItemID")
            $l_av2_Inventory[$l_i_InventoryIdx][2] = $l_i_ModelID
            $l_av2_Inventory[$l_i_InventoryIdx][3] = DllStructGetData($s_d_ItemStruct, "Quantity")
            $l_i_InventoryIdx += 1
        Next
    Next

    ReDim $l_av2_Inventory[$l_i_InventoryIdx][4]

    Local $l_i_InvMaterialCount = UBound($l_av2_Inventory)
    Local $l_ai_InvMaterialItemIDs[$l_i_InvMaterialCount]
    Local $l_i_MaterialIdx = 0

    For $reqMaterial = 0 To $l_i_ReqMaterialCount - 1
        Local $l_i_MaterialModelID = $a_ai2_ReqMaterials[$reqMaterial][0]
        Local $l_i_MaterialQuantityReq = $a_ai2_ReqMaterials[$reqMaterial][1] * $a_i_Quantity
        Local $l_i_RemainingMaterialQuantityReq = $l_i_MaterialQuantityReq

        For $invMaterial = 0 To $l_i_InvMaterialCount - 1
            If $l_av2_Inventory[$invMaterial][0] = 0 Then ContinueLoop
            If $l_av2_Inventory[$invMaterial][2] <> $l_i_MaterialModelID Then ContinueLoop

            Local $l_i_Item_UseQuantity
            If $l_av2_Inventory[$invMaterial][3] < $l_i_RemainingMaterialQuantityReq Then
                $l_i_Item_UseQuantity = $l_av2_Inventory[$invMaterial][3]
            Else
                $l_i_Item_UseQuantity = $l_i_RemainingMaterialQuantityReq
            EndIf

            $l_ai_InvMaterialItemIDs[$l_i_MaterialIdx] = $l_av2_Inventory[$invMaterial][1]
            $l_i_MaterialIdx += 1

            $l_i_RemainingMaterialQuantityReq -= $l_i_Item_UseQuantity
            If $l_i_RemainingMaterialQuantityReq <= 0 Then ExitLoop
        Next

        If $l_i_RemainingMaterialQuantityReq > 0 Then Return False
    Next

    ReDim $l_ai_InvMaterialItemIDs[$l_i_MaterialIdx]

    If $s_i_LastMaterialItemIDCount <> $l_i_MaterialIdx Then
        $s_d_CraftItemStruct = DllStructCreate('ptr;dword;dword;dword;dword;dword[' & $l_i_MaterialIdx & ']')
        $s_p_CraftItemStructPtr = DllStructGetPtr($s_d_CraftItemStruct)
        $s_i_LastMaterialItemIDCount = $l_i_MaterialIdx
    EndIf

    Local $l_i_MerchantItemID = Memory_Read(Merchant_GetMerchantItemPtr($a_i_CraftedItemModelID))
    If $l_i_MerchantItemID = 0 Then Return False

    DllStructSetData($s_d_CraftItemStruct, 1, $g_p_CraftItem)
    DllStructSetData($s_d_CraftItemStruct, 2, $a_i_Quantity)
    DllStructSetData($s_d_CraftItemStruct, 3, $l_i_MerchantItemID)
    DllStructSetData($s_d_CraftItemStruct, 4, $a_i_Price * $a_i_Quantity)
    DllStructSetData($s_d_CraftItemStruct, 5, $l_i_MaterialIdx)

    For $dllArrayPos = 1 To $l_i_MaterialIdx
        DllStructSetData($s_d_CraftItemStruct, 6, $l_ai_InvMaterialItemIDs[$dllArrayPos - 1], $dllArrayPos)
    Next

    Core_Enqueue($s_p_CraftItemStructPtr, 20 + 4 * $l_i_MaterialIdx)
    Return True
EndFunc   ;==>Merchant_CraftItem

Func Merchant_CollectorExchange($a_i_ItemRecvModelID, $a_i_ExchangeReq, $a_i_ItemGiveModelID)
    Local Const $LC_AI_BAG_LIST[4] = [$GC_I_INVENTORY_BACKPACK, $GC_I_INVENTORY_BELT_POUCH, $GC_I_INVENTORY_BAG1, $GC_I_INVENTORY_BAG2]
    Local Const $LC_I_MAX_BAG_SLOTS = 60
    Local Const $LC_I_OFFSET_ITEMID = 0x0
    Local Const $LC_I_OFFSET_MODELID = 0x2C
    Local Const $LC_I_OFFSET_QUANTITY = 0x4C

    If $a_i_ItemRecvModelID <= 0 Or $a_i_ItemGiveModelID <= 0 Then Return SetError(1, 0, False)
    If $a_i_ExchangeReq <= 0 Or $a_i_ExchangeReq > $GC_I_MERCHANT_MAX_ITEM_STACK Then Return SetError(2, 0, False)

    Static $s_i_LastUsedItemIDCount = 0
    Static $s_d_CollectorExchangeStruct, $s_p_CollectorExchangeStructPtr

    Static $s_d_ItemStruct = DllStructCreate( _
        "dword ItemID;" & _
        "byte[" & ($LC_I_OFFSET_MODELID - ($LC_I_OFFSET_ITEMID + 4)) & "];" & _
        "dword ModelID;" & _
        "byte[" & ($LC_I_OFFSET_QUANTITY - ($LC_I_OFFSET_MODELID + 4)) & "];" & _
        "short Quantity" _
    )
    Static $s_i_ItemStructSize = DllStructGetSize($s_d_ItemStruct)

    Local $l_av2_Inventory[$LC_I_MAX_BAG_SLOTS][4]
    Local $l_i_InventoryIdx = 0

    For $bag In $LC_AI_BAG_LIST
        Local $l_p_BagPtr = Item_GetBagPtr($bag)
        If $l_p_BagPtr = 0 Then ContinueLoop

        Local $l_ap_ItemArray = Item_GetBagItemArray($bag)
        Local $l_i_ItemCount = $l_ap_ItemArray[0]

        For $item = 1 To $l_i_ItemCount
            Local $l_p_ItemPtr = $l_ap_ItemArray[$item]
            If $l_p_ItemPtr = 0 Then ContinueLoop

            DllCall($g_h_Kernel32, "bool", "ReadProcessMemory", _
                "handle", $g_h_GWProcess, _
                "ptr", $l_p_ItemPtr, _
                "struct*", $s_d_ItemStruct, _
                "ulong_ptr", $s_i_ItemStructSize, _
                "ulong_ptr*", 0 _
            )

            Local $l_i_ModelID = DllStructGetData($s_d_ItemStruct, "ModelID")
            If $a_i_ItemGiveModelID <> $l_i_ModelID Then ContinueLoop

            $l_av2_Inventory[$l_i_InventoryIdx][0] = $l_p_ItemPtr
            $l_av2_Inventory[$l_i_InventoryIdx][1] = DllStructGetData($s_d_ItemStruct, "ItemID")
            $l_av2_Inventory[$l_i_InventoryIdx][2] = $l_i_ModelID
            $l_av2_Inventory[$l_i_InventoryIdx][3] = DllStructGetData($s_d_ItemStruct, "Quantity")
            $l_i_InventoryIdx += 1
        Next
    Next

    ReDim $l_av2_Inventory[$l_i_InventoryIdx][4]

    Local $l_i_InvExchangeCount = UBound($l_av2_Inventory)
    Local $l_ai_ExchangeQuantities[$a_i_ExchangeReq]
    Local $l_ai_ExchangeItemIDs[$a_i_ExchangeReq]
    Local $l_i_RemainingExchangeReq = $a_i_ExchangeReq
    Local $l_i_ExchangeIdx = 0

    For $l_i_Idx = 0 To $l_i_InvExchangeCount - 1
        If $l_av2_Inventory[$l_i_Idx][0] = 0 Then ContinueLoop

        Local $l_i_ItemQuantity
        If $l_av2_Inventory[$l_i_Idx][3] < $l_i_RemainingExchangeReq Then
            $l_i_ItemQuantity = $l_av2_Inventory[$l_i_Idx][3]
        Else
            $l_i_ItemQuantity = $l_i_RemainingExchangeReq
        EndIf

        $l_ai_ExchangeQuantities[$l_i_ExchangeIdx] = $l_i_ItemQuantity
        $l_ai_ExchangeItemIDs[$l_i_ExchangeIdx] = $l_av2_Inventory[$l_i_Idx][1]
        $l_i_ExchangeIdx += 1

        $l_i_RemainingExchangeReq -= $l_i_ItemQuantity
        If $l_i_RemainingExchangeReq <= 0 Then ExitLoop
    Next

    If $l_i_RemainingExchangeReq > 0 Then Return SetError(3, 0, False)

    ReDim $l_ai_ExchangeQuantities[$l_i_ExchangeIdx]
    ReDim $l_ai_ExchangeItemIDs[$l_i_ExchangeIdx]

    If $s_i_LastUsedItemIDCount <> $l_i_ExchangeIdx Then
        $s_d_CollectorExchangeStruct = DllStructCreate("ptr;dword;dword;dword[" & $l_i_ExchangeIdx & "];dword[" & $l_i_ExchangeIdx & "]")
        $s_p_CollectorExchangeStructPtr = DllStructGetPtr($s_d_CollectorExchangeStruct)
        $s_i_LastUsedItemIDCount = $l_i_ExchangeIdx
    EndIf

    Local $l_i_ItemRecvItemID = Memory_Read(Merchant_GetMerchantItemPtr($a_i_ItemRecvModelID))
    If $l_i_ItemRecvItemID = 0 Then Return SetError(4, 0, False)

    DllStructSetData($s_d_CollectorExchangeStruct, 1, $g_p_CollectorExchange)
    DllStructSetData($s_d_CollectorExchangeStruct, 2, $l_i_ItemRecvItemID)
    DllStructSetData($s_d_CollectorExchangeStruct, 3, $l_i_ExchangeIdx)

    For $dllArrayPos = 1 To $l_i_ExchangeIdx
        DllStructSetData($s_d_CollectorExchangeStruct, 4, $l_ai_ExchangeQuantities[$dllArrayPos - 1], $dllArrayPos)
    Next
    For $dllArrayPos = 1 To $l_i_ExchangeIdx
        DllStructSetData($s_d_CollectorExchangeStruct, 5, $l_ai_ExchangeItemIDs[$dllArrayPos - 1], $dllArrayPos)
    Next

    Core_Enqueue($s_p_CollectorExchangeStructPtr, 12 + 8 * $l_i_ExchangeIdx)
    Return True
EndFunc