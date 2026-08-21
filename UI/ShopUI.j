/**
    ShopUI

    Author: Valdemar
    Version: 1.1.1

    Description:
    Frame UI for PotS merchant vendors. The panel can browse merchant stock or
    the buyer's combined DInventory, DEquipment, and vanilla inventory through a
    shared Merchant/You mode button.

    Credits:
    - Elprede, for RpgMerchantShop as feature inspiration:
      https://www.hiveworkshop.com/threads/custom-rpg-shop-system.372995/

    How to install:
    Import after Shop, VendorLines, DialogCamera, MasterUI, Interface, and Table. Vendor dialogs can open
    the panel with ShopUI_ShowForVendor(vendor, hero).

    API:
    - call ShopUI_ShowForVendor(vendor, buyer)
    - call ShopUI_ShowForVendorWithReturn(vendor, buyer)
    - call ShopUI_ShowForVendorEx(vendor, buyer, endOnCombat)
    - call ShopUI_ShowForVendorWithReturnEx(vendor, buyer, endOnCombat)
    - call ShopUI_ShowForVendorWithReturnAndInterrupt(vendor, buyer, endOnCombat, onInterrupt)
    - call ShopUI_RegisterVendorReturnHandler(vendor, callback)
    - call ShopUI_RegisterReturnHandler(callback)
    - set vendor = ShopUI_GetVendorUnit()
    - set buyer = ShopUI_GetBuyerUnit()
    - call ShopUI_Hide()
    - call ShopUI_HideForCinematic()
    - call ShopUI_Refresh()
    - Vendor trade sessions reject combat and end immediately when either
      participant attacks, is attacked, dies, or enters combat.

**/
library ShopUI initializer AutoInit requires Table, Shop, VendorLines, DialogCamera, MasterUI, Interface, DialogInteraction, DialogSystem
    globals
        private constant integer SUI_MAX_ROWS = 10
        private constant integer SUI_VISIBLE_ROWS = 7
        private constant integer SUI_MAX_CATEGORIES = 6
        private constant real SUI_CATEGORY_TEXT_SCALE = 0.68
        private constant real SUI_REFRESH_INTERVAL = 0.50
        private constant real SUI_CAMERA_RESET_TIME = 0.75
        private constant real SUI_CAMERA_CHANGE_MIN_INTERVAL = 16.00
        private constant real SUI_CAMERA_CHANGE_MAX_INTERVAL = 26.00
        private constant boolean SUI_USE_DIALOG_CAMERA = true
        private constant boolean SUI_CINEMATIC = true
        private constant boolean SUI_END_ON_COMBAT = true

        private boolean SUI_Initialized = false
        private boolean SUI_SyncingListScroll = false
        private boolean SUI_TradeSessionOpen = false
        private boolean SUI_ReturnToDialog = false
        private integer SUI_ViewMode = SHOP_VIEW_MERCHANT
        private integer SUI_SelectedIndex = 0
        private integer SUI_ListScrollValue = 0
        private integer SUI_ListScrollMaxCache = -1
        private integer SUI_ListScrollFrameValueCache = -1
        private string SUI_SelectedCategory = "All"
        private real SUI_RandomVendorLineRemaining = 0.00

        private unit SUI_VendorUnit = null
        private unit SUI_BuyerUnit = null
        private integer SUI_VendorId = 0

        private framehandle SUI_Parent = null
        private framehandle SUI_MainBackdrop = null
        private framehandle SUI_Title = null
        private framehandle SUI_ViewingText = null
        private framehandle SUI_CloseButton = null
        private framehandle SUI_ModeButton = null
        private framehandle array SUI_CategoryButton
        private framehandle array SUI_CategoryText
        private framehandle SUI_LeftPane = null
        private framehandle SUI_RightPane = null
        private framehandle SUI_ListScroll = null
        private framehandle SUI_ListWheelArea = null
        private framehandle SUI_DetailIcon = null
        private framehandle SUI_DetailCharges = null
        private framehandle SUI_DetailTitle = null
        private framehandle SUI_DetailInfoBackdrop = null
        private framehandle SUI_DetailInfoText = null
        private framehandle SUI_DetailBodyText = null
        private framehandle SUI_ActionButton = null
        private framehandle SUI_StatusText = null
        private framehandle SUI_GoldText = null
        private framehandle SUI_ArenaMarksText = null

        private framehandle array SUI_RowButton
        private framehandle array SUI_RowIcon
        private framehandle array SUI_RowCharges
        private framehandle array SUI_RowText
        private framehandle array SUI_RowPrice
        private framehandle array SUI_RowHighlight
        private integer array SUI_RowIndex
        private string array SUI_RowIconCache
        private string array SUI_RowTextCache
        private string array SUI_RowPriceCache
        private string array SUI_RowChargesCache
        private integer array SUI_RowVisibleState
        private integer array SUI_RowHighlightState

        private string array SUI_CategoryName
        private integer array SUI_CategoryVisibleState

        private string SUI_DetailIconCache = ""
        private string SUI_DetailChargesCache = ""
        private string SUI_DetailTitleCache = ""
        private string SUI_DetailInfoCache = ""
        private string SUI_DetailBodyCache = ""
        private string SUI_StatusCache = ""
        private string SUI_GoldCache = ""
        private string SUI_ArenaMarksCache = ""
        private string SUI_ActionTextCache = ""

        private Table SUI_ButtonRow = 0
        private Table SUI_CategoryButtonIndex = 0
        private Table SUI_ReturnHandlerByVendor = 0

        private trigger SUI_CloseTrigger = null
        private trigger SUI_ModeTrigger = null
        private trigger SUI_CategoryTrigger = null
        private trigger SUI_RowTrigger = null
        private trigger SUI_ActionTrigger = null
        private trigger SUI_ListScrollTrigger = null
        private trigger SUI_WheelTrigger = null
        private trigger SUI_ClearFocusTrigger = null
        private trigger SUI_EscapeTrigger = null
        private trigger SUI_ReturnTrigger = null
        private trigger SUI_ExternalInterruptHandler = null
        private timer SUI_RefreshTimer = null

        private string SUI_PanelTexture = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"
        private string SUI_DefaultIcon = "ReplaceableTextures\\CommandButtons\\BTNSelectHeroOn.blp"
        private string SUI_RowHighlightModel = "UI\\Feedback\\Autocast\\UI-ModalButtonOn.mdx"
    endglobals

    private function SUI_GetActivePlayer takes nothing returns player
        if SUI_BuyerUnit != null then
            return GetOwningPlayer(SUI_BuyerUnit)
        endif
        return Player(0)
    endfunction

    private function SUI_IsVisible takes nothing returns boolean
        return SUI_Parent != null and BlzFrameIsVisible(SUI_Parent)
    endfunction

    private function SUI_ClearExternalInterruptHandler takes nothing returns nothing
        if SUI_ExternalInterruptHandler != null then
            call DestroyTrigger(SUI_ExternalInterruptHandler)
            set SUI_ExternalInterruptHandler = null
        endif
    endfunction

    private function SUI_IsRecentCategory takes nothing returns boolean
        return SUI_ViewMode == SHOP_VIEW_MERCHANT and SUI_SelectedCategory == Shop_GetRecentlySoldCategoryName()
    endfunction

    private function SUI_IsCategoryAvailable takes string category returns boolean
        local integer index = 1
        local integer categoryCount

        if SUI_ViewMode != SHOP_VIEW_MERCHANT or category == null or category == "" then
            return false
        endif
        set categoryCount = Shop_GetVendorCategoryCount(SUI_VendorId, true)
        loop
            exitwhen index > categoryCount
            if Shop_GetVendorCategoryName(SUI_VendorId, index) == category then
                return true
            endif
            set index = index + 1
        endloop
        return false
    endfunction

    private function SUI_NormalizeCategory takes nothing returns nothing
        if SUI_ViewMode != SHOP_VIEW_MERCHANT then
            return
        endif
        if not SUI_IsCategoryAvailable(SUI_SelectedCategory) then
            set SUI_SelectedCategory = Shop_GetAllCategoryName()
        endif
    endfunction

    private function SUI_GetTotalCount takes nothing returns integer
        if SUI_ViewMode == SHOP_VIEW_YOU then
            return Shop_GetViewCount()
        endif
        if SUI_IsRecentCategory() then
            return Shop_GetSessionSoldCount()
        endif
        return Shop_GetVendorStockCountByCategory(SUI_VendorId, SUI_SelectedCategory)
    endfunction

    private function SUI_GetMaxStart takes integer totalCount returns integer
        local integer maxStart = totalCount - SUI_VISIBLE_ROWS

        if maxStart < 0 then
            return 0
        endif
        return maxStart
    endfunction

    private function SUI_GetVisibleIndex takes integer rowIndex returns integer
        return SUI_ListScrollValue + rowIndex
    endfunction

    private function SUI_GetSelectedStockEntry takes nothing returns integer
        if SUI_ViewMode == SHOP_VIEW_MERCHANT and SUI_SelectedIndex > 0 then
            return Shop_GetVendorStockEntryByCategory(SUI_VendorId, SUI_SelectedIndex, SUI_SelectedCategory)
        endif
        return 0
    endfunction

    private function SUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        endif
    endfunction

    private function SUI_SetRowVisible takes integer rowIndex, boolean visible returns nothing
        local integer visibleState = 0

        if visible then
            set visibleState = 1
        endif
        if SUI_RowVisibleState[rowIndex] != visibleState then
            set SUI_RowVisibleState[rowIndex] = visibleState
            call BlzFrameSetVisible(SUI_RowButton[rowIndex], visible)
        endif
    endfunction

    private function SUI_SetCategoryVisible takes integer categoryIndex, boolean visible returns nothing
        local integer visibleState = 0

        if visible then
            set visibleState = 1
        endif
        if SUI_CategoryVisibleState[categoryIndex] != visibleState then
            set SUI_CategoryVisibleState[categoryIndex] = visibleState
            call BlzFrameSetVisible(SUI_CategoryButton[categoryIndex], visible)
        endif
    endfunction

    private function SUI_SetRowHighlight takes integer rowIndex, boolean visible returns nothing
        local integer visibleState = 0

        if visible then
            set visibleState = 1
        endif
        if SUI_RowHighlightState[rowIndex] != visibleState then
            set SUI_RowHighlightState[rowIndex] = visibleState
            call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], visible)
        endif
    endfunction

    private function SUI_ClampState takes integer totalCount returns nothing
        local integer maxStart = SUI_GetMaxStart(totalCount)

        if SUI_ListScrollValue < 0 then
            set SUI_ListScrollValue = 0
        elseif SUI_ListScrollValue > maxStart then
            set SUI_ListScrollValue = maxStart
        endif

        if totalCount <= 0 then
            set SUI_SelectedIndex = 0
        elseif SUI_SelectedIndex <= 0 or SUI_SelectedIndex > totalCount then
            set SUI_SelectedIndex = SUI_ListScrollValue + 1
            if SUI_SelectedIndex > totalCount then
                set SUI_SelectedIndex = totalCount
            endif
        endif
    endfunction

    private function SUI_UpdateRows takes player whichPlayer, integer totalCount returns nothing
        local integer rowIndex = 1
        local integer viewIndex
        local integer stockEntry
        local string iconPath
        local string rowText
        local string rowPrice
        local string chargesText
        local integer charges
        local boolean available

        loop
            exitwhen rowIndex > SUI_MAX_ROWS
            set viewIndex = SUI_GetVisibleIndex(rowIndex)
            set SUI_RowIndex[rowIndex] = 0

            if rowIndex <= SUI_VISIBLE_ROWS and viewIndex <= totalCount then
                set SUI_RowIndex[rowIndex] = viewIndex
                set charges = 0
                set available = true
                if SUI_ViewMode == SHOP_VIEW_MERCHANT then
                    if SUI_IsRecentCategory() then
                        set iconPath = Shop_GetSessionSoldIconPath(viewIndex)
                        set rowText = "|cffffe4a3" + Shop_GetSessionSoldName(viewIndex) + "|r|n|cff808080" + Shop_GetSessionSoldCategory(viewIndex) + "|r"
                        set rowPrice = "|cffffcc00" + I2S(Shop_GetSessionSoldPrice(viewIndex)) + "g|r"
                        set charges = Shop_GetSessionSoldCharges(viewIndex)
                    else
                        set stockEntry = Shop_GetVendorStockEntryByCategory(SUI_VendorId, viewIndex, SUI_SelectedCategory)
                        set iconPath = Shop_GetStockIconPath(stockEntry)
                        set rowText = "|cffffe4a3" + Shop_GetStockName(stockEntry) + "|r|n|cff808080" + Shop_GetStockCategory(stockEntry) + "|r"
                        set charges = Shop_GetStockCharges(stockEntry)
                        set available = Shop_IsStockAvailable(stockEntry)
                        if available then
                            set rowPrice = "|cffffcc00" + I2S(Shop_GetStockPrice(stockEntry)) + "g|r"
                        else
                            set rowPrice = "|cff808080Sold out|r"
                        endif
                    endif
                else
                    set iconPath = Shop_GetViewIconPath(viewIndex)
                    set rowText = "|cffffe4a3" + Shop_GetViewName(viewIndex) + "|r|n" + Shop_GetViewSourceLabel(viewIndex)
                    set charges = Shop_GetViewCharges(viewIndex)
                    if Shop_IsViewItemSellable(viewIndex) then
                        set rowPrice = "|cffffcc00" + I2S(Shop_GetViewSaleValue(viewIndex)) + "g|r"
                    else
                        set rowPrice = "|cff808080No sale|r"
                    endif
                endif
                if charges > 0 then
                    set chargesText = I2S(charges)
                else
                    set chargesText = ""
                endif

                if GetLocalPlayer() == whichPlayer then
                    if iconPath == null or iconPath == "" then
                        set iconPath = SUI_DefaultIcon
                    endif
                    if SUI_RowIconCache[rowIndex] != iconPath then
                        set SUI_RowIconCache[rowIndex] = iconPath
                        call BlzFrameSetTexture(SUI_RowIcon[rowIndex], iconPath, 0, true)
                    endif
                    if available then
                        call BlzFrameSetVertexColor(SUI_RowIcon[rowIndex], BlzConvertColor(255, 255, 255, 255))
                    else
                        call BlzFrameSetVertexColor(SUI_RowIcon[rowIndex], BlzConvertColor(255, 96, 96, 96))
                    endif
                    if SUI_RowChargesCache[rowIndex] != chargesText then
                        set SUI_RowChargesCache[rowIndex] = chargesText
                        call BlzFrameSetText(SUI_RowCharges[rowIndex], chargesText)
                    endif
                    if SUI_RowTextCache[rowIndex] != rowText then
                        set SUI_RowTextCache[rowIndex] = rowText
                        call BlzFrameSetText(SUI_RowText[rowIndex], rowText)
                    endif
                    if SUI_RowPriceCache[rowIndex] != rowPrice then
                        set SUI_RowPriceCache[rowIndex] = rowPrice
                        call BlzFrameSetText(SUI_RowPrice[rowIndex], rowPrice)
                    endif
                    call SUI_SetRowHighlight(rowIndex, viewIndex == SUI_SelectedIndex)
                    call SUI_SetRowVisible(rowIndex, true)
                endif
            else
                if GetLocalPlayer() == whichPlayer then
                    set SUI_RowIconCache[rowIndex] = ""
                    set SUI_RowTextCache[rowIndex] = ""
                    set SUI_RowPriceCache[rowIndex] = ""
                    set SUI_RowChargesCache[rowIndex] = ""
                    call SUI_SetRowVisible(rowIndex, false)
                    call SUI_SetRowHighlight(rowIndex, false)
                endif
            endif

            set rowIndex = rowIndex + 1
        endloop
    endfunction

    private function SUI_SetDetail takes player whichPlayer, string iconPath, string titleText, string infoText, string bodyText, string actionText, string statusText, integer charges, boolean available returns nothing
        local string chargesText = ""

        if charges > 0 then
            set chargesText = I2S(charges)
        endif
        if GetLocalPlayer() == whichPlayer then
            if iconPath == null or iconPath == "" then
                set iconPath = SUI_DefaultIcon
            endif
            if SUI_DetailIconCache != iconPath then
                set SUI_DetailIconCache = iconPath
                call BlzFrameSetTexture(SUI_DetailIcon, iconPath, 0, true)
            endif
            if available then
                call BlzFrameSetVertexColor(SUI_DetailIcon, BlzConvertColor(255, 255, 255, 255))
            else
                call BlzFrameSetVertexColor(SUI_DetailIcon, BlzConvertColor(255, 96, 96, 96))
            endif
            if SUI_DetailChargesCache != chargesText then
                set SUI_DetailChargesCache = chargesText
                call BlzFrameSetText(SUI_DetailCharges, chargesText)
            endif
            if SUI_DetailTitleCache != titleText then
                set SUI_DetailTitleCache = titleText
                call BlzFrameSetText(SUI_DetailTitle, titleText)
            endif
            if SUI_DetailInfoCache != infoText then
                set SUI_DetailInfoCache = infoText
                call BlzFrameSetText(SUI_DetailInfoText, infoText)
            endif
            if SUI_DetailBodyCache != bodyText then
                set SUI_DetailBodyCache = bodyText
                call BlzFrameSetText(SUI_DetailBodyText, bodyText)
            endif
            if SUI_ActionTextCache != actionText then
                set SUI_ActionTextCache = actionText
                call BlzFrameSetText(SUI_ActionButton, actionText)
            endif
            call BlzFrameSetEnable(SUI_ActionButton, available)
            if SUI_StatusCache != statusText then
                set SUI_StatusCache = statusText
                call BlzFrameSetText(SUI_StatusText, statusText)
            endif
        endif
    endfunction

    private function SUI_UpdateResources takes player whichPlayer returns nothing
        local string goldText
        local string arenaMarksText

        if GetLocalPlayer() == whichPlayer then
            set goldText = "|cffffcc00Gold:|r |cffffffff" + I2S(GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD)) + "|r"
            set arenaMarksText = "|cffff3030Arena Marks:|r |cffffffff" + I2S(GetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER)) + "|r"
            if SUI_GoldCache != goldText then
                set SUI_GoldCache = goldText
                call BlzFrameSetText(SUI_GoldText, goldText)
            endif
            if SUI_ArenaMarksCache != arenaMarksText then
                set SUI_ArenaMarksCache = arenaMarksText
                call BlzFrameSetText(SUI_ArenaMarksText, arenaMarksText)
            endif
        endif
    endfunction

    private function SUI_UpdateDetail takes player whichPlayer, integer totalCount returns nothing
        local integer stockEntry
        local string titleText
        local string infoText
        local string bodyText
        local string iconPath
        local string actionText
        local integer charges = 0
        local integer currentSupply
        local integer maximumSupply
        local boolean available = true

        if totalCount <= 0 or SUI_SelectedIndex <= 0 then
            if SUI_ViewMode == SHOP_VIEW_MERCHANT then
                call SUI_SetDetail(whichPlayer, SUI_DefaultIcon, "No stock", "Merchant", "", "Buy", "", 0, false)
            else
                call SUI_SetDetail(whichPlayer, SUI_DefaultIcon, "No items", "You", "", "Sell", "", 0, false)
            endif
            return
        endif

        if SUI_ViewMode == SHOP_VIEW_MERCHANT then
            if SUI_IsRecentCategory() then
                set titleText = Shop_GetSessionSoldName(SUI_SelectedIndex)
                set infoText = Shop_GetSessionSoldCategory(SUI_SelectedIndex) + "  |  " + I2S(Shop_GetSessionSoldPrice(SUI_SelectedIndex)) + " gold"
                set bodyText = Shop_GetSessionSoldTooltip(SUI_SelectedIndex)
                set iconPath = Shop_GetSessionSoldIconPath(SUI_SelectedIndex)
                set charges = Shop_GetSessionSoldCharges(SUI_SelectedIndex)
            else
                set stockEntry = SUI_GetSelectedStockEntry()
                set titleText = Shop_GetStockName(stockEntry)
                set infoText = Shop_GetStockCategory(stockEntry) + "  |  " + I2S(Shop_GetStockPrice(stockEntry)) + " gold"
                set bodyText = Shop_GetStockTooltip(stockEntry)
                set iconPath = Shop_GetStockIconPath(stockEntry)
                set charges = Shop_GetStockCharges(stockEntry)
                set available = Shop_IsStockAvailable(stockEntry)
                set maximumSupply = Shop_GetStockMaximumSupply(stockEntry)
                if maximumSupply > 0 then
                    set currentSupply = Shop_GetStockCurrentSupply(stockEntry)
                    if available then
                        set infoText = infoText + "  |  Stock: " + I2S(currentSupply) + "/" + I2S(maximumSupply)
                    else
                        set infoText = infoText + "  |  Sold out"
                    endif
                endif
            endif
            set actionText = "Buy"
        else
            set titleText = Shop_GetViewName(SUI_SelectedIndex)
            if Shop_IsViewItemSellable(SUI_SelectedIndex) then
                set infoText = Shop_GetViewSourceLabel(SUI_SelectedIndex) + "  |  " + I2S(Shop_GetViewSaleValue(SUI_SelectedIndex)) + " gold"
            else
                set infoText = Shop_GetViewSourceLabel(SUI_SelectedIndex) + "  |  Cannot sell"
            endif
            set bodyText = Shop_GetViewTooltip(SUI_SelectedIndex)
            set iconPath = Shop_GetViewIconPath(SUI_SelectedIndex)
            set charges = Shop_GetViewCharges(SUI_SelectedIndex)
            set actionText = "Sell"
        endif

        call SUI_SetDetail(whichPlayer, iconPath, titleText, infoText, bodyText, actionText, Shop_GetLastMessage(), charges, available)
    endfunction

    private function SUI_SyncListScrollFrame takes player whichPlayer, integer totalCount returns nothing
        local integer maxStart = SUI_GetMaxStart(totalCount)

        if GetLocalPlayer() == whichPlayer then
            set SUI_SyncingListScroll = true
            if SUI_ListScrollMaxCache != maxStart then
                set SUI_ListScrollMaxCache = maxStart
                call BlzFrameSetMinMaxValue(SUI_ListScroll, 0.0, I2R(maxStart))
            endif
            if SUI_ListScrollFrameValueCache != maxStart - SUI_ListScrollValue then
                set SUI_ListScrollFrameValueCache = maxStart - SUI_ListScrollValue
                call BlzFrameSetValue(SUI_ListScroll, I2R(SUI_ListScrollFrameValueCache))
            endif
            set SUI_SyncingListScroll = false
            call BlzFrameSetVisible(SUI_ListScroll, maxStart > 0)
        endif
    endfunction

    private function SUI_UpdateCategories takes player whichPlayer returns nothing
        local integer buttonIndex = 1
        local integer categoryCount = 0
        local string categoryName = ""

        if SUI_ViewMode == SHOP_VIEW_MERCHANT then
            set categoryCount = Shop_GetVendorCategoryCount(SUI_VendorId, true)
        endif

        loop
            exitwhen buttonIndex > SUI_MAX_CATEGORIES
            set categoryName = ""
            if buttonIndex <= categoryCount then
                if buttonIndex == SUI_MAX_CATEGORIES and categoryCount > SUI_MAX_CATEGORIES and Shop_GetSessionSoldCount() > 0 then
                    set categoryName = Shop_GetRecentlySoldCategoryName()
                else
                    set categoryName = Shop_GetVendorCategoryName(SUI_VendorId, buttonIndex)
                endif
            endif

            set SUI_CategoryName[buttonIndex] = categoryName
            if GetLocalPlayer() == whichPlayer then
                if categoryName != "" then
                    if categoryName == SUI_SelectedCategory then
                        call BlzFrameSetText(SUI_CategoryText[buttonIndex], "|cffffe4a3" + categoryName + "|r")
                    else
                        call BlzFrameSetText(SUI_CategoryText[buttonIndex], "|cffffcc00" + categoryName + "|r")
                    endif
                    call SUI_SetCategoryVisible(buttonIndex, true)
                else
                    call BlzFrameSetText(SUI_CategoryText[buttonIndex], "")
                    call SUI_SetCategoryVisible(buttonIndex, false)
                endif
            endif
            set buttonIndex = buttonIndex + 1
        endloop
    endfunction

    private function SUI_UpdateHeader takes player whichPlayer returns nothing
        local string modeLabel = "Merchant"
        local string viewingText
        local string vendorType = Shop_GetVendorTypeLabel(SUI_VendorId)
        local integer capacity = 0
        local integer usedSlots = 0

        if SUI_ViewMode == SHOP_VIEW_YOU then
            set modeLabel = "You"
        endif
        if SUI_BuyerUnit != null then
            set viewingText = "Viewing: " + GetUnitName(SUI_BuyerUnit)
            set capacity = MaxDInvCapacityOfUnit(SUI_BuyerUnit)
            if capacity > 0 then
                set usedSlots = capacity - CountUnitDInventoryFreeSpace(SUI_BuyerUnit)
                set viewingText = viewingText + "  |  Bag: " + I2S(usedSlots) + "/" + I2S(capacity)
            endif
        else
            set viewingText = "Viewing: You"
        endif
        if SUI_ViewMode == SHOP_VIEW_MERCHANT and vendorType != "" then
            set viewingText = "|cffffcc00" + vendorType + "|r  |  " + viewingText
        endif

        if GetLocalPlayer() == whichPlayer then
            call BlzFrameSetText(SUI_Title, "|cffffe4a3" + Shop_GetVendorName(SUI_VendorId) + "|r")
            call BlzFrameSetText(SUI_ViewingText, viewingText)
            call BlzFrameSetText(SUI_ModeButton, modeLabel)
        endif
    endfunction

    private function SUI_Update takes player whichPlayer returns nothing
        local integer totalCount

        if SUI_ViewMode == SHOP_VIEW_YOU then
            call Shop_BuildUnitInventory(SUI_BuyerUnit)
        else
            call SUI_NormalizeCategory()
        endif

        set totalCount = SUI_GetTotalCount()
        call SUI_ClampState(totalCount)
        call SUI_UpdateHeader(whichPlayer)
        call SUI_UpdateCategories(whichPlayer)
        call SUI_UpdateRows(whichPlayer, totalCount)
        call SUI_UpdateDetail(whichPlayer, totalCount)
        call SUI_UpdateResources(whichPlayer)
        call SUI_SyncListScrollFrame(whichPlayer, totalCount)
    endfunction

    private function SUI_EndTradeSession takes boolean playOutcome, boolean returnToDialog, boolean restoreGameplay returns nothing
        local unit buyer = SUI_BuyerUnit
        local unit vendor = SUI_VendorUnit
        local trigger returnHandler = null
        local boolean returnHandled = false

        if not SUI_TradeSessionOpen then
            set buyer = null
            set vendor = null
            return
        endif

        call DialogInteraction_EndCombatSensitiveInteraction()
        set SUI_TradeSessionOpen = false
        if playOutcome and vendor != null and DialogInteraction_IsUnitAlive(vendor) then
            call VendorLines_PlayTradeOutcome(vendor, Shop_GetSessionBoughtTransactionCount(), Shop_GetSessionSoldTransactionCount())
        endif
        call Shop_EndTradeSession()
        call DialogSystem_ClearEscapeAction()
        if returnToDialog and vendor != null then
            set returnHandler = SUI_ReturnHandlerByVendor.trigger[GetHandleId(vendor)]
            if returnHandler != null then
                set returnHandled = TriggerEvaluate(returnHandler)
            endif
            if not returnHandled and SUI_ReturnTrigger != null then
                set returnHandled = TriggerEvaluate(SUI_ReturnTrigger)
                if returnHandled then
                    call TriggerExecute(SUI_ReturnTrigger)
                endif
            endif
        endif
        if not returnHandled then
            call DialogSystem_StopDialogCamera(Player(0), SUI_CAMERA_RESET_TIME, SUI_USE_DIALOG_CAMERA)
            if restoreGameplay then
                call DialogInteraction_EndCinematicSequence(SUI_CINEMATIC)
                if buyer != null and DialogInteraction_IsUnitAlive(buyer) then
                    call ShowUnit(buyer, true)
                    call PauseUnit(buyer, false)
                    call SelectUnitForPlayerSingle(buyer, Player(0))
                endif
            endif
        endif

        set buyer = null
        set vendor = null
        set returnHandler = null
    endfunction

    private function SUI_HideInternal takes boolean playSound, boolean playOutcome, boolean restoreGameplay returns nothing
        local boolean returnToDialog = SUI_ReturnToDialog and playOutcome

        if SUI_Parent != null then
            if playSound and BlzFrameIsVisible(SUI_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
            endif
            call BlzFrameSetVisible(SUI_Parent, false)
        endif
        call SUI_EndTradeSession(playOutcome, returnToDialog, restoreGameplay)
        set SUI_ReturnToDialog = false
        set SUI_VendorUnit = null
        set SUI_BuyerUnit = null
        set SUI_VendorId = 0
        set SUI_SelectedIndex = 0
        set SUI_ListScrollValue = 0
        set SUI_SelectedCategory = Shop_GetAllCategoryName()
        set SUI_RandomVendorLineRemaining = 0.00
        call SUI_ClearExternalInterruptHandler()
    endfunction

    public function Hide takes nothing returns nothing
        call SUI_HideInternal(true, true, true)
    endfunction

    // The incoming cinematic owns control and fullscreen restoration.
    public function HideForCinematic takes nothing returns nothing
        if SUI_IsVisible() then
            call SUI_HideInternal(false, false, false)
        endif
    endfunction

    public function Refresh takes nothing returns nothing
        if SUI_Parent == null or not BlzFrameIsVisible(SUI_Parent) then
            return
        endif
        call SUI_Update(SUI_GetActivePlayer())
    endfunction

    private function SUI_CloseAction takes nothing returns nothing
        call ShopUI_Hide()
    endfunction

    private function SUI_EscapeAction takes nothing returns nothing
        if SUI_IsVisible() then
            call ShopUI_Hide()
        endif
    endfunction

    private function SUI_InterruptTrade takes nothing returns nothing
        local player p = SUI_GetActivePlayer()
        local trigger interruptHandler = SUI_ExternalInterruptHandler

        if SUI_IsVisible() then
            set SUI_ExternalInterruptHandler = null
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call DisplayTextToPlayer(p, 0.00, 0.00, "|cffff8080Trade interrupted.|r")
            call SUI_HideInternal(false, false, true)
            if interruptHandler != null then
                call TriggerExecute(interruptHandler)
                call DestroyTrigger(interruptHandler)
            endif
        endif

        set p = null
        set interruptHandler = null
    endfunction

    private function SUI_ModeAction takes nothing returns nothing
        if SUI_ViewMode == SHOP_VIEW_MERCHANT then
            set SUI_ViewMode = SHOP_VIEW_YOU
        else
            set SUI_ViewMode = SHOP_VIEW_MERCHANT
        endif

        set SUI_SelectedIndex = 0
        set SUI_ListScrollValue = 0
        set SUI_SelectedCategory = Shop_GetAllCategoryName()
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_TAB_CHANGE, GetTriggerPlayer())
        call SUI_Update(GetTriggerPlayer())
    endfunction

    private function SUI_CategoryAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer categoryIndex
        local player p = GetTriggerPlayer()

        if SUI_CategoryButtonIndex.has(handleId) then
            set categoryIndex = SUI_CategoryButtonIndex.integer[handleId]
            if SUI_CategoryName[categoryIndex] != "" then
                set SUI_SelectedCategory = SUI_CategoryName[categoryIndex]
                set SUI_SelectedIndex = 0
                set SUI_ListScrollValue = 0
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_TAB_CHANGE, p)
                call SUI_Update(p)
            endif
        endif

        set p = null
    endfunction

    private function SUI_RowAction takes nothing returns nothing
        local integer handleId = GetHandleId(BlzGetTriggerFrame())
        local integer rowIndex

        if SUI_ButtonRow.has(handleId) then
            set rowIndex = SUI_ButtonRow.integer[handleId]
            if SUI_RowIndex[rowIndex] > 0 then
                set SUI_SelectedIndex = SUI_RowIndex[rowIndex]
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_MENU_CLICK, GetTriggerPlayer())
                call SUI_Update(GetTriggerPlayer())
            endif
        endif
    endfunction

    private function SUI_ActionAction takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local boolean success = false
        local integer stockEntry

        if SUI_BuyerUnit == null then
            set p = null
            return
        endif

        if SUI_ViewMode == SHOP_VIEW_MERCHANT then
            if SUI_IsRecentCategory() then
                set success = Shop_BuyRecentlySold(p, SUI_BuyerUnit, SUI_SelectedIndex)
            else
                set stockEntry = SUI_GetSelectedStockEntry()
                set success = Shop_BuyStock(p, SUI_BuyerUnit, stockEntry)
            endif
        else
            set success = Shop_SellViewItem(p, SUI_BuyerUnit, SUI_SelectedIndex)
        endif

        if success then
            if SUI_ViewMode == SHOP_VIEW_MERCHANT then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_SHOP_BUY, p)
            else
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_SHOP_SELL, p)
            endif
            set SUI_SelectedIndex = 0
        else
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
        endif
        call SUI_Update(p)
        set p = null
    endfunction

    private function SUI_ListScrollAction takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local integer maxStart = SUI_GetMaxStart(SUI_GetTotalCount())

        if SUI_SyncingListScroll then
            set p = null
            return
        endif

        set SUI_ListScrollFrameValueCache = R2I(BlzGetTriggerFrameValue() + 0.5)
        set SUI_ListScrollValue = maxStart - SUI_ListScrollFrameValueCache
        set SUI_SelectedIndex = SUI_ListScrollValue + 1
        call SUI_Update(p)
        set p = null
    endfunction

    private function SUI_WheelAction takes nothing returns nothing
        local real newValue

        if GetLocalPlayer() == GetTriggerPlayer() and SUI_ListScroll != null and BlzFrameIsVisible(SUI_ListScroll) then
            if BlzGetTriggerFrameValue() > 0 then
                set newValue = BlzFrameGetValue(SUI_ListScroll) + 1.0
            else
                set newValue = BlzFrameGetValue(SUI_ListScroll) - 1.0
            endif
            if newValue < 0.0 then
                set newValue = 0.0
            elseif newValue > I2R(SUI_ListScrollMaxCache) then
                set newValue = I2R(SUI_ListScrollMaxCache)
            endif
            call BlzFrameSetValue(SUI_ListScroll, newValue)
        endif
    endfunction

    private function SUI_CreateFrames takes nothing returns nothing
        local integer rowIndex = 1
        local integer categoryIndex = 1
        local real rowTopOffset = -0.012
        local real rowHeight = 0.033
        local real rowGap = 0.003

        set SUI_Parent = BlzCreateFrameByType("BACKDROP", "ShopUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(SUI_Parent, FRAMEPOINT_TOPLEFT, 0.105, 0.565)
        call BlzFrameSetAbsPoint(SUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.640, 0.165)

        set SUI_MainBackdrop = BlzCreateFrameByType("BACKDROP", "ShopUIMainBackdrop", SUI_Parent, "", 0)
        call BlzFrameSetTexture(SUI_MainBackdrop, SUI_PanelTexture, 0, false)
        call BlzFrameSetPoint(SUI_MainBackdrop, FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
        call BlzFrameSetPoint(SUI_MainBackdrop, FRAMEPOINT_BOTTOMRIGHT, SUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
        call BlzFrameSetAlpha(SUI_MainBackdrop, 255)
        call BlzFrameSetVertexColor(SUI_MainBackdrop, BlzConvertColor(255, 0, 0, 0))
        call BlzFrameSetEnable(SUI_MainBackdrop, false)

        set SUI_Title = BlzCreateFrameByType("TEXT", "ShopUITitle", SUI_Parent, "", 0)
        call BlzFrameSetPoint(SUI_Title, FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(SUI_Title, 0.300, 0.018)
        call BlzFrameSetTextAlignment(SUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_Title, 1.10)
        call BlzFrameSetEnable(SUI_Title, false)

        set SUI_ViewingText = BlzCreateFrameByType("TEXT", "ShopUIViewing", SUI_Parent, "", 0)
        call BlzFrameSetPoint(SUI_ViewingText, FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.048)
        call BlzFrameSetSize(SUI_ViewingText, 0.300, 0.016)
        call BlzFrameSetTextAlignment(SUI_ViewingText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_ViewingText, 0.96)
        call BlzFrameSetEnable(SUI_ViewingText, false)

        set SUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ShopUIClose", SUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SUI_CloseButton, 0.064, 0.030)
        call BlzFrameSetText(SUI_CloseButton, "Close")
        call BlzFrameSetPoint(SUI_CloseButton, FRAMEPOINT_TOPRIGHT, SUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
        call BlzTriggerRegisterFrameEvent(SUI_CloseTrigger, SUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

        set SUI_ModeButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ShopUIMode", SUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SUI_ModeButton, 0.080, 0.030)
        call BlzFrameSetText(SUI_ModeButton, "Merchant")
        call BlzFrameSetPoint(SUI_ModeButton, FRAMEPOINT_TOPRIGHT, SUI_CloseButton, FRAMEPOINT_TOPLEFT, -0.008, 0.0)
        call BlzTriggerRegisterFrameEvent(SUI_ModeTrigger, SUI_ModeButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_ModeButton, FRAMEEVENT_CONTROL_CLICK)

        loop
            exitwhen categoryIndex > SUI_MAX_CATEGORIES
            set SUI_CategoryButton[categoryIndex] = BlzCreateFrameByType("GLUETEXTBUTTON", "ShopUICategory" + I2S(categoryIndex), SUI_Parent, "ScriptDialogButton", 0)
            call BlzFrameSetSize(SUI_CategoryButton[categoryIndex], 0.079, 0.024)
            call BlzFrameSetText(SUI_CategoryButton[categoryIndex], "")
            if categoryIndex == 1 then
                call BlzFrameSetPoint(SUI_CategoryButton[categoryIndex], FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.074)
            else
                call BlzFrameSetPoint(SUI_CategoryButton[categoryIndex], FRAMEPOINT_LEFT, SUI_CategoryButton[categoryIndex - 1], FRAMEPOINT_RIGHT, 0.004, 0.0)
            endif

            set SUI_CategoryText[categoryIndex] = BlzCreateFrameByType("TEXT", "ShopUICategoryText" + I2S(categoryIndex), SUI_CategoryButton[categoryIndex], "", 0)
            call BlzFrameSetPoint(SUI_CategoryText[categoryIndex], FRAMEPOINT_TOPLEFT, SUI_CategoryButton[categoryIndex], FRAMEPOINT_TOPLEFT, 0.004, -0.001)
            call BlzFrameSetPoint(SUI_CategoryText[categoryIndex], FRAMEPOINT_BOTTOMRIGHT, SUI_CategoryButton[categoryIndex], FRAMEPOINT_BOTTOMRIGHT, -0.004, 0.001)
            call BlzFrameSetTextAlignment(SUI_CategoryText[categoryIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
            call BlzFrameSetScale(SUI_CategoryText[categoryIndex], SUI_CATEGORY_TEXT_SCALE)
            call BlzFrameSetEnable(SUI_CategoryText[categoryIndex], false)

            call BlzTriggerRegisterFrameEvent(SUI_CategoryTrigger, SUI_CategoryButton[categoryIndex], FRAMEEVENT_CONTROL_CLICK)
            call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_CategoryButton[categoryIndex], FRAMEEVENT_CONTROL_CLICK)
            set SUI_CategoryButtonIndex.integer[GetHandleId(SUI_CategoryButton[categoryIndex])] = categoryIndex
            set SUI_CategoryVisibleState[categoryIndex] = -1
            call BlzFrameSetVisible(SUI_CategoryButton[categoryIndex], false)
            set categoryIndex = categoryIndex + 1
        endloop

        set SUI_LeftPane = BlzCreateFrameByType("BACKDROP", "ShopUILeftPane", SUI_Parent, "", 0)
        call BlzFrameSetTexture(SUI_LeftPane, SUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(SUI_LeftPane, FRAMEPOINT_TOPLEFT, SUI_Parent, FRAMEPOINT_TOPLEFT, 0.014, -0.104)
        call BlzFrameSetPoint(SUI_LeftPane, FRAMEPOINT_BOTTOMRIGHT, SUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.215, 0.014)

        set SUI_ListScroll = BlzCreateFrameByType("SLIDER", "ShopUIListScroll", SUI_LeftPane, "QuestMainListScrollBar", 0)
        call BlzFrameSetPoint(SUI_ListScroll, FRAMEPOINT_TOPLEFT, SUI_LeftPane, FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
        call BlzFrameSetSize(SUI_ListScroll, BlzFrameGetWidth(SUI_ListScroll), BlzFrameGetHeight(SUI_LeftPane) - 0.004)
        call BlzFrameSetMinMaxValue(SUI_ListScroll, 0.0, 0.0)
        call BlzFrameSetStepSize(SUI_ListScroll, 1.0)
        call BlzFrameSetValue(SUI_ListScroll, 0.0)
        call BlzFrameSetVisible(SUI_ListScroll, false)
        call BlzTriggerRegisterFrameEvent(SUI_ListScrollTrigger, SUI_ListScroll, FRAMEEVENT_SLIDER_VALUE_CHANGED)
        call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_ListScroll, FRAMEEVENT_MOUSE_WHEEL)
        call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_LeftPane, FRAMEEVENT_MOUSE_WHEEL)

        set SUI_RightPane = BlzCreateFrameByType("BACKDROP", "ShopUIRightPane", SUI_Parent, "", 0)
        call BlzFrameSetTexture(SUI_RightPane, SUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(SUI_RightPane, FRAMEPOINT_TOPLEFT, SUI_ListScroll, FRAMEPOINT_TOPRIGHT, 0.010, 0.0)
        call BlzFrameSetPoint(SUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, SUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.014, 0.014)

        set SUI_DetailIcon = BlzCreateFrameByType("BACKDROP", "ShopUIDetailIcon", SUI_RightPane, "IconButtonTemplate", 0)
        call BlzFrameSetPoint(SUI_DetailIcon, FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.018)
        call BlzFrameSetSize(SUI_DetailIcon, 0.042, 0.042)

        set SUI_DetailCharges = BlzCreateFrameByType("TEXT", "ShopUIDetailCharges", SUI_DetailIcon, "", 0)
        call BlzFrameSetPoint(SUI_DetailCharges, FRAMEPOINT_BOTTOMRIGHT, SUI_DetailIcon, FRAMEPOINT_BOTTOMRIGHT, -0.002, 0.002)
        call BlzFrameSetSize(SUI_DetailCharges, 0.020, 0.012)
        call BlzFrameSetTextAlignment(SUI_DetailCharges, TEXT_JUSTIFY_BOTTOM, TEXT_JUSTIFY_RIGHT)
        call BlzFrameSetScale(SUI_DetailCharges, 0.82)
        call BlzFrameSetEnable(SUI_DetailCharges, false)

        set SUI_DetailTitle = BlzCreateFrameByType("TEXT", "ShopUIDetailTitle", SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_DetailTitle, FRAMEPOINT_TOPLEFT, SUI_DetailIcon, FRAMEPOINT_TOPRIGHT, 0.014, -0.002)
        call BlzFrameSetSize(SUI_DetailTitle, 0.250, 0.018)
        call BlzFrameSetTextAlignment(SUI_DetailTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_DetailTitle, 1.05)
        call BlzFrameSetEnable(SUI_DetailTitle, false)

        set SUI_DetailInfoBackdrop = BlzCreateFrameByType("BACKDROP", "ShopUIInfoBackdrop", SUI_RightPane, "", 0)
        call BlzFrameSetTexture(SUI_DetailInfoBackdrop, SUI_PanelTexture, 0, true)
        call BlzFrameSetPoint(SUI_DetailInfoBackdrop, FRAMEPOINT_TOPLEFT, SUI_DetailTitle, FRAMEPOINT_BOTTOMLEFT, -0.001, -0.008)
        call BlzFrameSetSize(SUI_DetailInfoBackdrop, 0.250, 0.018)

        set SUI_DetailInfoText = BlzCreateFrameByType("TEXT", "ShopUIInfoText", SUI_DetailInfoBackdrop, "", 0)
        call BlzFrameSetPoint(SUI_DetailInfoText, FRAMEPOINT_TOPLEFT, SUI_DetailInfoBackdrop, FRAMEPOINT_TOPLEFT, 0.006, -0.001)
        call BlzFrameSetSize(SUI_DetailInfoText, 0.238, 0.016)
        call BlzFrameSetTextAlignment(SUI_DetailInfoText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_DetailInfoText, 0.92)
        call BlzFrameSetEnable(SUI_DetailInfoText, false)

        set SUI_DetailBodyText = BlzCreateFrameByType("TEXT", "ShopUIDetailBody", SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_DetailBodyText, FRAMEPOINT_TOPLEFT, SUI_RightPane, FRAMEPOINT_TOPLEFT, 0.018, -0.095)
        call BlzFrameSetSize(SUI_DetailBodyText, 0.270, 0.128)
        call BlzFrameSetTextAlignment(SUI_DetailBodyText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_DetailBodyText, 0.90)
        call BlzFrameSetEnable(SUI_DetailBodyText, false)

        set SUI_StatusText = BlzCreateFrameByType("TEXT", "ShopUIStatus", SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_StatusText, FRAMEPOINT_BOTTOMLEFT, SUI_RightPane, FRAMEPOINT_BOTTOMLEFT, 0.018, 0.038)
        call BlzFrameSetSize(SUI_StatusText, 0.190, 0.018)
        call BlzFrameSetTextAlignment(SUI_StatusText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_StatusText, 0.92)
        call BlzFrameSetEnable(SUI_StatusText, false)

        set SUI_GoldText = BlzCreateFrameByType("TEXT", "ShopUIGoldText", SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_GoldText, FRAMEPOINT_BOTTOMLEFT, SUI_RightPane, FRAMEPOINT_BOTTOMLEFT, 0.018, 0.017)
        call BlzFrameSetSize(SUI_GoldText, 0.072, 0.016)
        call BlzFrameSetTextAlignment(SUI_GoldText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_GoldText, 0.82)
        call BlzFrameSetEnable(SUI_GoldText, false)

        set SUI_ArenaMarksText = BlzCreateFrameByType("TEXT", "ShopUIArenaMarksText", SUI_RightPane, "", 0)
        call BlzFrameSetPoint(SUI_ArenaMarksText, FRAMEPOINT_BOTTOMLEFT, SUI_RightPane, FRAMEPOINT_BOTTOMLEFT, 0.110, 0.017)
        call BlzFrameSetSize(SUI_ArenaMarksText, 0.096, 0.016)
        call BlzFrameSetTextAlignment(SUI_ArenaMarksText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(SUI_ArenaMarksText, 0.82)
        call BlzFrameSetEnable(SUI_ArenaMarksText, false)

        set SUI_ActionButton = BlzCreateFrameByType("GLUETEXTBUTTON", "ShopUIAction", SUI_RightPane, "ScriptDialogButton", 0)
        call BlzFrameSetSize(SUI_ActionButton, 0.070, 0.030)
        call BlzFrameSetText(SUI_ActionButton, "Buy")
        call BlzFrameSetPoint(SUI_ActionButton, FRAMEPOINT_BOTTOMRIGHT, SUI_RightPane, FRAMEPOINT_BOTTOMRIGHT, -0.018, 0.012)
        call BlzTriggerRegisterFrameEvent(SUI_ActionTrigger, SUI_ActionButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_ActionButton, FRAMEEVENT_CONTROL_CLICK)

        set SUI_ListWheelArea = BlzCreateFrameByType("SLIDER", "ShopUIWheelArea", SUI_Parent, "", 0)
        call BlzFrameSetPoint(SUI_ListWheelArea, FRAMEPOINT_TOPRIGHT, SUI_ListScroll, FRAMEPOINT_TOPLEFT, -0.006, 0.000)
        call BlzFrameSetPoint(SUI_ListWheelArea, FRAMEPOINT_BOTTOMLEFT, SUI_LeftPane, FRAMEPOINT_BOTTOMLEFT, 0.006, 0.006)
        call BlzFrameSetEnable(SUI_ListWheelArea, false)
        call BlzFrameSetVisible(SUI_ListWheelArea, false)

        loop
            exitwhen rowIndex > SUI_MAX_ROWS
            set SUI_RowButton[rowIndex] = BlzCreateFrameByType("GLUEBUTTON", "ShopUIRowButton" + I2S(rowIndex), SUI_LeftPane, "ScoreScreenTabButtonTemplate", 0)
            call BlzFrameSetPoint(SUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, SUI_LeftPane, FRAMEPOINT_TOPLEFT, 0.006, rowTopOffset)
            call BlzFrameSetSize(SUI_RowButton[rowIndex], 0.190, rowHeight)
            call BlzTriggerRegisterFrameEvent(SUI_RowTrigger, SUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
            call BlzTriggerRegisterFrameEvent(SUI_ClearFocusTrigger, SUI_RowButton[rowIndex], FRAMEEVENT_CONTROL_CLICK)
            call BlzTriggerRegisterFrameEvent(SUI_WheelTrigger, SUI_RowButton[rowIndex], FRAMEEVENT_MOUSE_WHEEL)
            set SUI_ButtonRow.integer[GetHandleId(SUI_RowButton[rowIndex])] = rowIndex
            set SUI_RowVisibleState[rowIndex] = -1

            set SUI_RowIcon[rowIndex] = BlzCreateFrameByType("BACKDROP", "ShopUIRowIcon" + I2S(rowIndex), SUI_RowButton[rowIndex], "IconButtonTemplate", 0)
            call BlzFrameSetPoint(SUI_RowIcon[rowIndex], FRAMEPOINT_LEFT, SUI_RowButton[rowIndex], FRAMEPOINT_LEFT, 0.006, 0.0)
            call BlzFrameSetSize(SUI_RowIcon[rowIndex], 0.020, 0.020)

            set SUI_RowCharges[rowIndex] = BlzCreateFrameByType("TEXT", "ShopUIRowCharges" + I2S(rowIndex), SUI_RowIcon[rowIndex], "", 0)
            call BlzFrameSetPoint(SUI_RowCharges[rowIndex], FRAMEPOINT_BOTTOMRIGHT, SUI_RowIcon[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.001, 0.001)
            call BlzFrameSetSize(SUI_RowCharges[rowIndex], 0.012, 0.009)
            call BlzFrameSetTextAlignment(SUI_RowCharges[rowIndex], TEXT_JUSTIFY_BOTTOM, TEXT_JUSTIFY_RIGHT)
            call BlzFrameSetScale(SUI_RowCharges[rowIndex], 0.72)
            call BlzFrameSetEnable(SUI_RowCharges[rowIndex], false)

            set SUI_RowText[rowIndex] = BlzCreateFrameByType("TEXT", "ShopUIRowText" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
            call BlzFrameSetPoint(SUI_RowText[rowIndex], FRAMEPOINT_TOPLEFT, SUI_RowButton[rowIndex], FRAMEPOINT_TOPLEFT, 0.032, -0.004)
            call BlzFrameSetPoint(SUI_RowText[rowIndex], FRAMEPOINT_BOTTOMRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.060, 0.004)
            call BlzFrameSetTextAlignment(SUI_RowText[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
            call BlzFrameSetScale(SUI_RowText[rowIndex], 0.90)
            call BlzFrameSetEnable(SUI_RowText[rowIndex], false)

            set SUI_RowPrice[rowIndex] = BlzCreateFrameByType("TEXT", "ShopUIRowPrice" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
            call BlzFrameSetPoint(SUI_RowPrice[rowIndex], FRAMEPOINT_TOPRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_TOPRIGHT, -0.008, -0.004)
            call BlzFrameSetPoint(SUI_RowPrice[rowIndex], FRAMEPOINT_BOTTOMRIGHT, SUI_RowButton[rowIndex], FRAMEPOINT_BOTTOMRIGHT, -0.008, 0.004)
            call BlzFrameSetTextAlignment(SUI_RowPrice[rowIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_RIGHT)
            call BlzFrameSetScale(SUI_RowPrice[rowIndex], 0.88)
            call BlzFrameSetEnable(SUI_RowPrice[rowIndex], false)

            set SUI_RowHighlight[rowIndex] = BlzCreateFrameByType("SPRITE", "ShopUIRowHighlight" + I2S(rowIndex), SUI_RowButton[rowIndex], "", 0)
            call BlzFrameSetAllPoints(SUI_RowHighlight[rowIndex], SUI_RowButton[rowIndex])
            call BlzFrameSetModel(SUI_RowHighlight[rowIndex], SUI_RowHighlightModel, 0)
            call BlzFrameSetScale(SUI_RowHighlight[rowIndex], 0.76)
            set SUI_RowHighlightState[rowIndex] = -1
            call BlzFrameSetVisible(SUI_RowHighlight[rowIndex], false)
            call BlzFrameSetEnable(SUI_RowHighlight[rowIndex], false)

            set rowTopOffset = rowTopOffset - rowHeight - rowGap
            set rowIndex = rowIndex + 1
        endloop

        call BlzFrameClearAllPoints(SUI_ListScroll)
        call BlzFrameSetPoint(SUI_ListScroll, FRAMEPOINT_TOPLEFT, SUI_RowButton[1], FRAMEPOINT_TOPRIGHT, 0.004, -0.002)
        call BlzFrameSetSize(SUI_ListScroll, BlzFrameGetWidth(SUI_ListScroll), (rowHeight * I2R(SUI_VISIBLE_ROWS)) + (rowGap * I2R(SUI_VISIBLE_ROWS - 1)) + 0.004)

        call BlzFrameClearAllPoints(SUI_ListWheelArea)
        call BlzFrameSetPoint(SUI_ListWheelArea, FRAMEPOINT_TOPRIGHT, SUI_ListScroll, FRAMEPOINT_TOPLEFT, -0.006, 0.000)
        call BlzFrameSetPoint(SUI_ListWheelArea, FRAMEPOINT_BOTTOMLEFT, SUI_RowButton[SUI_VISIBLE_ROWS], FRAMEPOINT_BOTTOMLEFT, 0.006, 0.002)

        call BlzFrameSetVisible(SUI_Parent, false)
    endfunction

    private function SUI_GetCameraRotationOffset takes unit vendor, unit buyer returns real
        local real dx
        local real dy

        if vendor == null or buyer == null then
            return 180.00
        endif
        set dx = GetUnitX(buyer) - GetUnitX(vendor)
        set dy = GetUnitY(buyer) - GetUnitY(vendor)
        if dx * dx + dy * dy < 1.00 then
            return 180.00
        endif
        return (Atan2(dy, dx) * bj_RADTODEG + 180.00) - GetUnitFacing(vendor)
    endfunction

    private function SUI_ShowForVendor takes unit vendor, unit buyer, boolean returnToDialog, boolean endOnCombat, code onInterrupt returns nothing
        local player p

        if vendor == null or buyer == null then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
            set vendor = null
            set buyer = null
            return
        endif

        set SUI_VendorId = Shop_GetVendorIdForUnit(vendor)
        if SUI_VendorId <= 0 then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, GetOwningPlayer(buyer))
            set vendor = null
            set buyer = null
            return
        endif
        if not Shop_CanPlayerTradeWithVendor(GetOwningPlayer(buyer), vendor) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, GetOwningPlayer(buyer))
            call DisplayTextToPlayer(GetOwningPlayer(buyer), 0.00, 0.00, "|cffff8040Your reputation with this vendor's faction is too low to trade.|r")
            set vendor = null
            set buyer = null
            return
        endif

        if SUI_IsVisible() then
            call SUI_HideInternal(false, false, true)
        endif
        if not DialogInteraction_BeginCombatSensitiveInteractionEx(vendor, buyer, function SUI_InterruptTrade, endOnCombat) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, GetOwningPlayer(buyer))
            call DisplayTextToPlayer(GetOwningPlayer(buyer), 0.00, 0.00, "|cffff8080You cannot trade while either participant is in combat.|r")
            set SUI_VendorId = 0
            set vendor = null
            set buyer = null
            return
        endif
        call SUI_ClearExternalInterruptHandler()
        if onInterrupt != null then
            set SUI_ExternalInterruptHandler = CreateTrigger()
            call TriggerAddAction(SUI_ExternalInterruptHandler, onInterrupt)
        endif

        set SUI_VendorUnit = vendor
        set SUI_BuyerUnit = buyer
        set SUI_ViewMode = SHOP_VIEW_MERCHANT
        set SUI_SelectedIndex = 0
        set SUI_ListScrollValue = 0
        set SUI_ListScrollMaxCache = -1
        set SUI_ListScrollFrameValueCache = -1
        set SUI_SelectedCategory = Shop_GetAllCategoryName()
        set SUI_TradeSessionOpen = true
        set SUI_ReturnToDialog = returnToDialog
        call Shop_BeginTradeSessionForUnits(SUI_VendorId, vendor, buyer)
        set SUI_RandomVendorLineRemaining = VendorLines_GetRandomLineInterval(SUI_VendorId)
        set p = GetOwningPlayer(buyer)
        if returnToDialog then
            call BlzFrameSetText(SUI_CloseButton, "Back")
        else
            call BlzFrameSetText(SUI_CloseButton, "Close")
        endif
        if SUI_USE_DIALOG_CAMERA then
            call DialogCameraStartRandomCycle(p, vendor, SUI_GetCameraRotationOffset(vendor, buyer), SUI_CAMERA_CHANGE_MIN_INTERVAL, SUI_CAMERA_CHANGE_MAX_INTERVAL, false)
        endif

        if SUI_Parent != null and not BlzFrameIsVisible(SUI_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, p)
        endif
        call BlzFrameSetVisible(SUI_Parent, true)
        call SUI_Update(p)

        set p = null
        set vendor = null
        set buyer = null
    endfunction

    public function ShowForVendor takes unit vendor, unit buyer returns nothing
        call SUI_ShowForVendor(vendor, buyer, false, SUI_END_ON_COMBAT, null)
    endfunction

    public function ShowForVendorWithReturn takes unit vendor, unit buyer returns nothing
        call SUI_ShowForVendor(vendor, buyer, true, SUI_END_ON_COMBAT, null)
    endfunction

    public function ShowForVendorEx takes unit vendor, unit buyer, boolean endOnCombat returns nothing
        call SUI_ShowForVendor(vendor, buyer, false, endOnCombat, null)
    endfunction

    public function ShowForVendorWithReturnEx takes unit vendor, unit buyer, boolean endOnCombat returns nothing
        call SUI_ShowForVendor(vendor, buyer, true, endOnCombat, null)
    endfunction

    public function ShowForVendorWithReturnAndInterrupt takes unit vendor, unit buyer, boolean endOnCombat, code onInterrupt returns nothing
        call SUI_ShowForVendor(vendor, buyer, true, endOnCombat, onInterrupt)
    endfunction

    public function RegisterReturnHandler takes code callback returns nothing
        if callback == null then
            return
        endif
        if SUI_ReturnTrigger == null then
            set SUI_ReturnTrigger = CreateTrigger()
        endif
        call TriggerAddCondition(SUI_ReturnTrigger, Filter(callback))
    endfunction

    public function RegisterVendorReturnHandler takes unit vendor, code callback returns nothing
        local integer handleId
        local trigger oldHandler
        local trigger newHandler

        if vendor == null or callback == null then
            set vendor = null
            set oldHandler = null
            set newHandler = null
            return
        endif
        set handleId = GetHandleId(vendor)
        set oldHandler = SUI_ReturnHandlerByVendor.trigger[handleId]
        if oldHandler != null then
            call DestroyTrigger(oldHandler)
        endif
        set newHandler = CreateTrigger()
        call TriggerAddCondition(newHandler, Filter(callback))
        set SUI_ReturnHandlerByVendor.trigger[handleId] = newHandler

        set vendor = null
        set oldHandler = null
        set newHandler = null
    endfunction

    public function GetVendorUnit takes nothing returns unit
        return SUI_VendorUnit
    endfunction

    public function GetBuyerUnit takes nothing returns unit
        return SUI_BuyerUnit
    endfunction

    private function SUI_RefreshAction takes nothing returns nothing
        if SUI_IsVisible() and SUI_BuyerUnit != null then
            if VendorLines_AreRandomLinesEnabled(SUI_VendorId) then
                set SUI_RandomVendorLineRemaining = SUI_RandomVendorLineRemaining - SUI_REFRESH_INTERVAL
                if SUI_RandomVendorLineRemaining <= 0.00 then
                    if SUI_VendorUnit != null and DialogInteraction_IsUnitAlive(SUI_VendorUnit) and not DialogSystem_IsFieldLineQueueActive() and not DialogSystem_IsSequenceActive() then
                        call VendorLines_PlayRandomTradeLine(SUI_VendorUnit)
                    endif
                    set SUI_RandomVendorLineRemaining = VendorLines_GetRandomLineInterval(SUI_VendorId)
                endif
            endif
            call SUI_Update(SUI_GetActivePlayer())
        endif
    endfunction

    public function Init takes nothing returns nothing
        if SUI_Initialized then
            return
        endif
        set SUI_Initialized = true

        set SUI_ButtonRow = Table.create()
        set SUI_CategoryButtonIndex = Table.create()
        set SUI_ReturnHandlerByVendor = Table.create()
        set SUI_RefreshTimer = CreateTimer()
        call TimerStart(SUI_RefreshTimer, SUI_REFRESH_INTERVAL, true, function SUI_RefreshAction)

        set SUI_CloseTrigger = CreateTrigger()
        call TriggerAddAction(SUI_CloseTrigger, function SUI_CloseAction)

        set SUI_ModeTrigger = CreateTrigger()
        call TriggerAddAction(SUI_ModeTrigger, function SUI_ModeAction)

        set SUI_CategoryTrigger = CreateTrigger()
        call TriggerAddAction(SUI_CategoryTrigger, function SUI_CategoryAction)

        set SUI_RowTrigger = CreateTrigger()
        call TriggerAddAction(SUI_RowTrigger, function SUI_RowAction)

        set SUI_ActionTrigger = CreateTrigger()
        call TriggerAddAction(SUI_ActionTrigger, function SUI_ActionAction)

        set SUI_ListScrollTrigger = CreateTrigger()
        call TriggerAddAction(SUI_ListScrollTrigger, function SUI_ListScrollAction)

        set SUI_WheelTrigger = CreateTrigger()
        call TriggerAddAction(SUI_WheelTrigger, function SUI_WheelAction)

        set SUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(SUI_ClearFocusTrigger, function SUI_ClearFocusAction)

        set SUI_EscapeTrigger = CreateTrigger()
        call BlzTriggerRegisterPlayerKeyEvent(SUI_EscapeTrigger, Player(0), OSKEY_ESCAPE, 0, true)
        call TriggerRegisterPlayerEvent(SUI_EscapeTrigger, Player(0), EVENT_PLAYER_END_CINEMATIC)
        call TriggerAddAction(SUI_EscapeTrigger, function SUI_EscapeAction)

        call SUI_CreateFrames()
    endfunction

    public function AutoInit takes nothing returns nothing
        call ShopUI_Init()
    endfunction
endlibrary
