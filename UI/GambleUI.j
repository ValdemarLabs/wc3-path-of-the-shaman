/**
    GambleUI

    Author: Valdemar
    Version: 1.1.0

    Description:
    Displays a focused mystery-item purchase panel. Callers configure a
    weighted reward pool, then receive purchase and return callbacks without
    sharing ShopUI vendor-session state.

    Credits:

    How to install:
    Import after Shop and Interface. Quest-giver libraries that use the panel
    should require GambleUI.

    API:
    - call GambleUI_ClearRewards()
    - call GambleUI_AddReward(itemTypeId, weight)
    - call GambleUI_RegisterPurchaseHandler(callback)
    - call GambleUI_RegisterReturnHandler(callback)
    - call GambleUI_Show(vendor, buyer, goldCost)
    - call GambleUI_Hide()
    - set vendor = GambleUI_GetVendorUnit()
    - set buyer = GambleUI_GetBuyerUnit()
    - set itemTypeId = GambleUI_GetLastRewardItemType()

**/
library GambleUI initializer AutoInit requires Shop, Interface
    globals
        // Reward-pool configuration.
        private constant integer GUI_MAX_REWARDS = 32
        private constant string GUI_MYSTERY_ICON = "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp"
        private constant string GUI_PANEL_TEXTURE = "UI\\Widgets\\EscMenu\\Human\\blank-background.blp"

        private boolean GUI_Initialized = false
        private integer GUI_RewardCount = 0
        private integer GUI_TotalRewardWeight = 0
        private integer array GUI_RewardItemType
        private integer array GUI_RewardWeight

        // Active purchase context; kept separate from ShopUI sessions.
        private unit GUI_Vendor = null
        private unit GUI_Buyer = null
        private integer GUI_GoldCost = 0
        private integer GUI_LastRewardItemType = 0

        // Frame and callback state.
        private framehandle GUI_Parent = null
        private framehandle GUI_MainBackdrop = null
        private framehandle GUI_Title = null
        private framehandle GUI_Subtitle = null
        private framehandle GUI_CloseButton = null
        private framehandle GUI_OfferPane = null
        private framehandle GUI_Icon = null
        private framehandle GUI_OfferTitle = null
        private framehandle GUI_PriceText = null
        private framehandle GUI_Body = null
        private framehandle GUI_StatusBackdrop = null
        private framehandle GUI_Status = null
        private framehandle GUI_GoldText = null
        private framehandle GUI_BuyButton = null
        private framehandle GUI_ReturnButton = null

        private trigger GUI_BuyTrigger = null
        private trigger GUI_ReturnButtonTrigger = null
        private trigger GUI_CloseTrigger = null
        private trigger GUI_ClearFocusTrigger = null
        private trigger GUI_EscapeTrigger = null
        private trigger GUI_PurchaseHandler = null
        private trigger GUI_ReturnHandler = null
    endglobals

    private function GUI_IsVisible takes nothing returns boolean
        return GUI_Parent != null and BlzFrameIsVisible(GUI_Parent)
    endfunction

    private function GUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function GUI_GetRewardIcon takes integer itemTypeId returns string
        local string iconPath = BlzGetAbilityIcon(itemTypeId)
        if iconPath == null or iconPath == "" then
            return GUI_MYSTERY_ICON
        endif
        return iconPath
    endfunction

    private function GUI_PickReward takes nothing returns integer
        local integer roll
        local integer index = 1

        if GUI_RewardCount <= 0 or GUI_TotalRewardWeight <= 0 then
            return 0
        endif

        set roll = GetRandomInt(1, GUI_TotalRewardWeight)
        loop
            set roll = roll - GUI_RewardWeight[index]
            exitwhen roll <= 0 or index >= GUI_RewardCount
            set index = index + 1
        endloop
        return GUI_RewardItemType[index]
    endfunction

    private function GUI_ResetSession takes nothing returns nothing
        set GUI_Vendor = null
        set GUI_Buyer = null
        set GUI_GoldCost = 0
    endfunction

    private function GUI_SetStatus takes player p, string text, boolean isError returns nothing
        if isError then
            call BlzFrameSetText(GUI_Status, "|cffff8080" + text + "|r")
            call DisplayTextToPlayer(p, 0.00, 0.00, "|cffff8080" + text + "|r")
        else
            call BlzFrameSetText(GUI_Status, text)
        endif
        if GUI_Buyer != null then
            call BlzFrameSetText(GUI_GoldText, "|cffffcc00Gold:|r " + I2S(GetPlayerState(GetOwningPlayer(GUI_Buyer), PLAYER_STATE_RESOURCE_GOLD)))
        endif
    endfunction

    private function GUI_HideInternal takes boolean playSound returns nothing
        local player p = Player(0)

        if GUI_Buyer != null then
            set p = GetOwningPlayer(GUI_Buyer)
        endif
        if GUI_Parent != null then
            if playSound and BlzFrameIsVisible(GUI_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, p)
            endif
            call BlzFrameSetVisible(GUI_Parent, false)
        endif
        call GUI_ResetSession()

        set p = null
    endfunction

    private function GUI_ReturnAction takes nothing returns nothing
        if GetTriggerPlayer() != Player(0) or not GUI_IsVisible() then
            return
        endif
        if GUI_Parent != null then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, GetTriggerPlayer())
            call BlzFrameSetVisible(GUI_Parent, false)
        endif
        if GUI_ReturnHandler != null then
            call TriggerExecute(GUI_ReturnHandler)
        endif
        call GUI_ResetSession()
    endfunction

    private function GUI_BuyAction takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local integer itemTypeId
        local item reward

        if p != Player(0) or not GUI_IsVisible() or GUI_Buyer == null or GetOwningPlayer(GUI_Buyer) != p then
            set p = null
            return
        endif
        if GUI_Vendor == null or GetWidgetLife(GUI_Vendor) <= 0.405 or GetWidgetLife(GUI_Buyer) <= 0.405 or not IsUnitInRange(GUI_Buyer, GUI_Vendor, 650.00) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call GUI_SetStatus(p, "The special deal was interrupted.", true)
            call GUI_ReturnAction()
            set p = null
            return
        endif
        if GUI_GoldCost <= 0 or GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) < GUI_GoldCost then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call GUI_SetStatus(p, "You don't have enough gold.", true)
            set p = null
            return
        endif

        set itemTypeId = GUI_PickReward()
        if itemTypeId == 0 then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call GUI_SetStatus(p, "Kribugs has no mystery goods available.", true)
            set p = null
            return
        endif

        set reward = CreateItem(itemTypeId, GetUnitX(GUI_Buyer), GetUnitY(GUI_Buyer))
        if reward == null or not Shop_GiveItemToUnit(GUI_Buyer, reward) then
            if reward != null then
                call RemoveItem(reward)
            endif
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call GUI_SetStatus(p, "Your inventories are full.", true)
            set reward = null
            set p = null
            return
        endif

        call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) - GUI_GoldCost)
        call Interface_NotifyLootCoin()
        set GUI_LastRewardItemType = itemTypeId
        call BlzFrameSetTexture(GUI_Icon, GUI_GetRewardIcon(itemTypeId), 0, true)
        call GUI_SetStatus(p, "|cff80ff80Item received: " + GetObjectName(itemTypeId) + "|r", false)
        call DisplayTextToPlayer(p, 0.00, 0.00, "|cff80ff80Item received: " + GetObjectName(itemTypeId) + "|r")
        call GUI_HideInternal(false)
        if GUI_PurchaseHandler != null then
            call TriggerExecute(GUI_PurchaseHandler)
        endif

        set reward = null
        set p = null
    endfunction

    private function GUI_EscapeAction takes nothing returns nothing
        if GUI_IsVisible() then
            call GUI_ReturnAction()
        endif
    endfunction

    private function GUI_CreateFrames takes nothing returns nothing
        set GUI_Parent = BlzCreateFrameByType("BACKDROP", "GambleUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetLevel(GUI_Parent, 4)
        call BlzFrameSetAbsPoint(GUI_Parent, FRAMEPOINT_TOPLEFT, 0.195, 0.535)
        call BlzFrameSetAbsPoint(GUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.605, 0.185)

        set GUI_MainBackdrop = BlzCreateFrameByType("BACKDROP", "GambleUIMainBackdrop", GUI_Parent, "", 0)
        call BlzFrameSetTexture(GUI_MainBackdrop, GUI_PANEL_TEXTURE, 0, false)
        call BlzFrameSetPoint(GUI_MainBackdrop, FRAMEPOINT_TOPLEFT, GUI_Parent, FRAMEPOINT_TOPLEFT, 0.010, -0.010)
        call BlzFrameSetPoint(GUI_MainBackdrop, FRAMEPOINT_BOTTOMRIGHT, GUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.010)
        call BlzFrameSetAlpha(GUI_MainBackdrop, 255)
        call BlzFrameSetVertexColor(GUI_MainBackdrop, BlzConvertColor(255, 0, 0, 0))
        call BlzFrameSetEnable(GUI_MainBackdrop, false)

        set GUI_Title = BlzCreateFrameByType("TEXT", "GambleUITitle", GUI_Parent, "", 0)
        call BlzFrameSetPoint(GUI_Title, FRAMEPOINT_TOPLEFT, GUI_Parent, FRAMEPOINT_TOPLEFT, 0.022, -0.020)
        call BlzFrameSetSize(GUI_Title, 0.310, 0.020)
        call BlzFrameSetTextAlignment(GUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GUI_Title, 1.12)
        call BlzFrameSetEnable(GUI_Title, false)

        set GUI_Subtitle = BlzCreateFrameByType("TEXT", "GambleUISubtitle", GUI_Parent, "", 0)
        call BlzFrameSetPoint(GUI_Subtitle, FRAMEPOINT_TOPLEFT, GUI_Title, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.006)
        call BlzFrameSetSize(GUI_Subtitle, 0.310, 0.016)
        call BlzFrameSetTextAlignment(GUI_Subtitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GUI_Subtitle, 0.86)
        call BlzFrameSetEnable(GUI_Subtitle, false)

        set GUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "GambleUIClose", GUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(GUI_CloseButton, 0.030, 0.030)
        call BlzFrameSetText(GUI_CloseButton, "X")
        call BlzFrameSetPoint(GUI_CloseButton, FRAMEPOINT_TOPRIGHT, GUI_Parent, FRAMEPOINT_TOPRIGHT, -0.012, -0.012)
        call BlzTriggerRegisterFrameEvent(GUI_CloseTrigger, GUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(GUI_ClearFocusTrigger, GUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

        set GUI_OfferPane = BlzCreateFrameByType("BACKDROP", "GambleUIOfferPane", GUI_Parent, "", 0)
        call BlzFrameSetTexture(GUI_OfferPane, GUI_PANEL_TEXTURE, 0, true)
        call BlzFrameSetPoint(GUI_OfferPane, FRAMEPOINT_TOPLEFT, GUI_Parent, FRAMEPOINT_TOPLEFT, 0.018, -0.074)
        call BlzFrameSetPoint(GUI_OfferPane, FRAMEPOINT_BOTTOMRIGHT, GUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.018, 0.076)

        set GUI_Icon = BlzCreateFrameByType("BACKDROP", "GambleUIIcon", GUI_OfferPane, "IconButtonTemplate", 0)
        call BlzFrameSetPoint(GUI_Icon, FRAMEPOINT_TOPLEFT, GUI_OfferPane, FRAMEPOINT_TOPLEFT, 0.020, -0.020)
        call BlzFrameSetSize(GUI_Icon, 0.060, 0.060)

        set GUI_OfferTitle = BlzCreateFrameByType("TEXT", "GambleUIOfferTitle", GUI_OfferPane, "", 0)
        call BlzFrameSetPoint(GUI_OfferTitle, FRAMEPOINT_TOPLEFT, GUI_Icon, FRAMEPOINT_TOPRIGHT, 0.018, -0.002)
        call BlzFrameSetSize(GUI_OfferTitle, 0.250, 0.020)
        call BlzFrameSetTextAlignment(GUI_OfferTitle, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GUI_OfferTitle, 1.06)
        call BlzFrameSetEnable(GUI_OfferTitle, false)

        set GUI_PriceText = BlzCreateFrameByType("TEXT", "GambleUIPrice", GUI_OfferPane, "", 0)
        call BlzFrameSetPoint(GUI_PriceText, FRAMEPOINT_TOPLEFT, GUI_OfferTitle, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.006)
        call BlzFrameSetSize(GUI_PriceText, 0.250, 0.016)
        call BlzFrameSetTextAlignment(GUI_PriceText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GUI_PriceText, 0.92)
        call BlzFrameSetEnable(GUI_PriceText, false)

        set GUI_Body = BlzCreateFrameByType("TEXT", "GambleUIBody", GUI_OfferPane, "", 0)
        call BlzFrameSetPoint(GUI_Body, FRAMEPOINT_TOPLEFT, GUI_Icon, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.014)
        call BlzFrameSetSize(GUI_Body, 0.338, 0.044)
        call BlzFrameSetTextAlignment(GUI_Body, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GUI_Body, 0.90)
        call BlzFrameSetEnable(GUI_Body, false)

        set GUI_StatusBackdrop = BlzCreateFrameByType("BACKDROP", "GambleUIStatusBackdrop", GUI_OfferPane, "", 0)
        call BlzFrameSetTexture(GUI_StatusBackdrop, GUI_PANEL_TEXTURE, 0, true)
        call BlzFrameSetPoint(GUI_StatusBackdrop, FRAMEPOINT_TOPLEFT, GUI_OfferPane, FRAMEPOINT_BOTTOMLEFT, 0.016, 0.048)
        call BlzFrameSetPoint(GUI_StatusBackdrop, FRAMEPOINT_BOTTOMRIGHT, GUI_OfferPane, FRAMEPOINT_BOTTOMRIGHT, -0.016, 0.016)

        set GUI_Status = BlzCreateFrameByType("TEXT", "GambleUIStatus", GUI_StatusBackdrop, "", 0)
        call BlzFrameSetPoint(GUI_Status, FRAMEPOINT_TOPLEFT, GUI_StatusBackdrop, FRAMEPOINT_TOPLEFT, 0.010, -0.004)
        call BlzFrameSetPoint(GUI_Status, FRAMEPOINT_BOTTOMRIGHT, GUI_StatusBackdrop, FRAMEPOINT_BOTTOMRIGHT, -0.010, 0.004)
        call BlzFrameSetTextAlignment(GUI_Status, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GUI_Status, 0.92)
        call BlzFrameSetEnable(GUI_Status, false)

        set GUI_GoldText = BlzCreateFrameByType("TEXT", "GambleUIGold", GUI_Parent, "", 0)
        call BlzFrameSetPoint(GUI_GoldText, FRAMEPOINT_BOTTOMLEFT, GUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.024, 0.030)
        call BlzFrameSetSize(GUI_GoldText, 0.100, 0.016)
        call BlzFrameSetTextAlignment(GUI_GoldText, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GUI_GoldText, 0.86)
        call BlzFrameSetEnable(GUI_GoldText, false)

        set GUI_BuyButton = BlzCreateFrameByType("GLUETEXTBUTTON", "GambleUIBuy", GUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(GUI_BuyButton, FRAMEPOINT_BOTTOMRIGHT, GUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.024, 0.022)
        call BlzFrameSetSize(GUI_BuyButton, 0.112, 0.034)
        call BlzTriggerRegisterFrameEvent(GUI_BuyTrigger, GUI_BuyButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(GUI_ClearFocusTrigger, GUI_BuyButton, FRAMEEVENT_CONTROL_CLICK)

        set GUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "GambleUIReturn", GUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(GUI_ReturnButton, FRAMEPOINT_RIGHT, GUI_BuyButton, FRAMEPOINT_LEFT, -0.010, 0.000)
        call BlzFrameSetSize(GUI_ReturnButton, 0.090, 0.034)
        call BlzFrameSetText(GUI_ReturnButton, "Previous")
        call BlzTriggerRegisterFrameEvent(GUI_ReturnButtonTrigger, GUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(GUI_ClearFocusTrigger, GUI_ReturnButton, FRAMEEVENT_CONTROL_CLICK)

        call BlzFrameSetVisible(GUI_Parent, false)
    endfunction

    public function ClearRewards takes nothing returns nothing
        local integer index = 1
        loop
            exitwhen index > GUI_RewardCount
            set GUI_RewardItemType[index] = 0
            set GUI_RewardWeight[index] = 0
            set index = index + 1
        endloop
        set GUI_RewardCount = 0
        set GUI_TotalRewardWeight = 0
    endfunction

    public function AddReward takes integer itemTypeId, integer weight returns boolean
        if itemTypeId == 0 or weight <= 0 or GUI_RewardCount >= GUI_MAX_REWARDS then
            return false
        endif
        set GUI_RewardCount = GUI_RewardCount + 1
        set GUI_RewardItemType[GUI_RewardCount] = itemTypeId
        set GUI_RewardWeight[GUI_RewardCount] = weight
        set GUI_TotalRewardWeight = GUI_TotalRewardWeight + weight
        return true
    endfunction

    public function RegisterPurchaseHandler takes code callback returns nothing
        if callback == null then
            return
        endif
        if GUI_PurchaseHandler == null then
            set GUI_PurchaseHandler = CreateTrigger()
        endif
        call TriggerAddAction(GUI_PurchaseHandler, callback)
    endfunction

    public function RegisterReturnHandler takes code callback returns nothing
        if callback == null then
            return
        endif
        if GUI_ReturnHandler == null then
            set GUI_ReturnHandler = CreateTrigger()
        endif
        call TriggerAddAction(GUI_ReturnHandler, callback)
    endfunction

    public function Show takes unit vendor, unit buyer, integer goldCost returns nothing
        local player p

        if vendor == null or buyer == null or goldCost <= 0 or GUI_RewardCount <= 0 then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
            set vendor = null
            set buyer = null
            return
        endif
        if not GUI_Initialized then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
            set vendor = null
            set buyer = null
            return
        endif

        set GUI_Vendor = vendor
        set GUI_Buyer = buyer
        set GUI_GoldCost = goldCost
        set GUI_LastRewardItemType = 0
        set p = GetOwningPlayer(buyer)
        call BlzFrameSetText(GUI_Title, "|cffffe4a3Special Deal|r")
        call BlzFrameSetText(GUI_Subtitle, "A private offer from " + GetUnitName(vendor))
        call BlzFrameSetTexture(GUI_Icon, GUI_MYSTERY_ICON, 0, true)
        call BlzFrameSetText(GUI_OfferTitle, "Mystery Package")
        call BlzFrameSetText(GUI_PriceText, "|cffffcc00Price:|r " + I2S(goldCost) + " gold")
        call BlzFrameSetText(GUI_Body, "One weighted random item from Kribugs' private stock. The package is revealed only after payment. All deals are final.")
        call BlzFrameSetText(GUI_GoldText, "|cffffcc00Gold:|r " + I2S(GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)))
        call BlzFrameSetText(GUI_Status, "Choose Buy to take the gamble.")
        call BlzFrameSetText(GUI_BuyButton, "Buy")
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, p)
        call BlzFrameSetVisible(GUI_Parent, true)

        set p = null
        set vendor = null
        set buyer = null
    endfunction

    public function Hide takes nothing returns nothing
        call GUI_HideInternal(true)
    endfunction

    public function GetLastRewardItemType takes nothing returns integer
        return GUI_LastRewardItemType
    endfunction

    public function GetVendorUnit takes nothing returns unit
        return GUI_Vendor
    endfunction

    public function GetBuyerUnit takes nothing returns unit
        return GUI_Buyer
    endfunction

    public function Init takes nothing returns nothing
        if GUI_Initialized then
            return
        endif
        set GUI_Initialized = true

        set GUI_BuyTrigger = CreateTrigger()
        call TriggerAddAction(GUI_BuyTrigger, function GUI_BuyAction)
        set GUI_ReturnButtonTrigger = CreateTrigger()
        call TriggerAddAction(GUI_ReturnButtonTrigger, function GUI_ReturnAction)
        set GUI_CloseTrigger = CreateTrigger()
        call TriggerAddAction(GUI_CloseTrigger, function GUI_ReturnAction)
        set GUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(GUI_ClearFocusTrigger, function GUI_ClearFocusAction)
        set GUI_EscapeTrigger = CreateTrigger()
        call BlzTriggerRegisterPlayerKeyEvent(GUI_EscapeTrigger, Player(0), OSKEY_ESCAPE, 0, true)
        call TriggerRegisterPlayerEvent(GUI_EscapeTrigger, Player(0), EVENT_PLAYER_END_CINEMATIC)
        call TriggerAddAction(GUI_EscapeTrigger, function GUI_EscapeAction)

        call GUI_CreateFrames()
    endfunction

    public function AutoInit takes nothing returns nothing
        call GambleUI_Init()
    endfunction
endlibrary
