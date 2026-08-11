/**
    GambleUI

    Author: Valdemar
    Version: 1.0.0

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
    - set itemTypeId = GambleUI_GetLastRewardItemType()

**/
library GambleUI initializer AutoInit requires Shop, Interface
    globals
        // Reward-pool configuration.
        private constant integer GUI_MAX_REWARDS = 32
        private constant string GUI_MYSTERY_ICON = "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp"

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
        private framehandle GUI_Title = null
        private framehandle GUI_Icon = null
        private framehandle GUI_Body = null
        private framehandle GUI_Status = null
        private framehandle GUI_BuyButton = null
        private framehandle GUI_ReturnButton = null

        private trigger GUI_BuyTrigger = null
        private trigger GUI_ReturnButtonTrigger = null
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
        call GUI_HideInternal(true)
        if GUI_ReturnHandler != null then
            call TriggerExecute(GUI_ReturnHandler)
        endif
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
            call DisplayTextToPlayer(p, 0.00, 0.00, "|cffff8080The special deal was interrupted.|r")
            call GUI_ReturnAction()
            set p = null
            return
        endif
        if GUI_GoldCost <= 0 or GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) < GUI_GoldCost then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call BlzFrameSetText(GUI_Status, "|cffff8080You don't have enough gold.|r")
            set p = null
            return
        endif

        set itemTypeId = GUI_PickReward()
        if itemTypeId == 0 then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call BlzFrameSetText(GUI_Status, "|cffff8080Kribugs has no mystery goods available.|r")
            set p = null
            return
        endif

        set reward = CreateItem(itemTypeId, GetUnitX(GUI_Buyer), GetUnitY(GUI_Buyer))
        if reward == null or not Shop_GiveItemToUnit(GUI_Buyer, reward) then
            if reward != null then
                call RemoveItem(reward)
            endif
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, p)
            call BlzFrameSetText(GUI_Status, "|cffff8080Your inventories are full.|r")
            set reward = null
            set p = null
            return
        endif

        call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) - GUI_GoldCost)
        call Interface_NotifyLootCoin()
        set GUI_LastRewardItemType = itemTypeId
        call BlzFrameSetTexture(GUI_Icon, GUI_GetRewardIcon(itemTypeId), 0, true)
        call BlzFrameSetText(GUI_Status, "|cff80ff80Item received: " + GetObjectName(itemTypeId) + "|r")
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
        call BlzFrameSetAbsPoint(GUI_Parent, FRAMEPOINT_TOPLEFT, 0.230, 0.465)
        call BlzFrameSetAbsPoint(GUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.570, 0.245)

        set GUI_Title = BlzCreateFrameByType("TEXT", "GambleUITitle", GUI_Parent, "", 0)
        call BlzFrameSetPoint(GUI_Title, FRAMEPOINT_TOPLEFT, GUI_Parent, FRAMEPOINT_TOPLEFT, 0.024, -0.022)
        call BlzFrameSetSize(GUI_Title, 0.292, 0.024)
        call BlzFrameSetTextAlignment(GUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(GUI_Title, 1.16)
        call BlzFrameSetEnable(GUI_Title, false)

        set GUI_Icon = BlzCreateFrameByType("BACKDROP", "GambleUIIcon", GUI_Parent, "IconButtonTemplate", 0)
        call BlzFrameSetPoint(GUI_Icon, FRAMEPOINT_TOP, GUI_Title, FRAMEPOINT_BOTTOM, 0.000, -0.014)
        call BlzFrameSetSize(GUI_Icon, 0.052, 0.052)

        set GUI_Body = BlzCreateFrameByType("TEXT", "GambleUIBody", GUI_Parent, "", 0)
        call BlzFrameSetPoint(GUI_Body, FRAMEPOINT_TOPLEFT, GUI_Icon, FRAMEPOINT_BOTTOMLEFT, -0.120, -0.010)
        call BlzFrameSetSize(GUI_Body, 0.292, 0.040)
        call BlzFrameSetTextAlignment(GUI_Body, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetEnable(GUI_Body, false)

        set GUI_Status = BlzCreateFrameByType("TEXT", "GambleUIStatus", GUI_Parent, "", 0)
        call BlzFrameSetPoint(GUI_Status, FRAMEPOINT_TOPLEFT, GUI_Body, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.004)
        call BlzFrameSetSize(GUI_Status, 0.292, 0.020)
        call BlzFrameSetTextAlignment(GUI_Status, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(GUI_Status, 0.90)
        call BlzFrameSetEnable(GUI_Status, false)

        set GUI_BuyButton = BlzCreateFrameByType("GLUETEXTBUTTON", "GambleUIBuy", GUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(GUI_BuyButton, FRAMEPOINT_BOTTOMLEFT, GUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.032, 0.022)
        call BlzFrameSetSize(GUI_BuyButton, 0.126, 0.036)
        call BlzTriggerRegisterFrameEvent(GUI_BuyTrigger, GUI_BuyButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(GUI_ClearFocusTrigger, GUI_BuyButton, FRAMEEVENT_CONTROL_CLICK)

        set GUI_ReturnButton = BlzCreateFrameByType("GLUETEXTBUTTON", "GambleUIReturn", GUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(GUI_ReturnButton, FRAMEPOINT_BOTTOMRIGHT, GUI_Parent, FRAMEPOINT_BOTTOMRIGHT, -0.032, 0.022)
        call BlzFrameSetSize(GUI_ReturnButton, 0.126, 0.036)
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
        call BlzFrameSetText(GUI_Title, "|cffffe4a3Special Deal - " + GetUnitName(vendor) + "|r")
        call BlzFrameSetTexture(GUI_Icon, GUI_MYSTERY_ICON, 0, true)
        call BlzFrameSetText(GUI_Body, "Pay " + I2S(goldCost) + " gold and receive one random item.")
        call BlzFrameSetText(GUI_Status, "Gold: " + I2S(GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)))
        call BlzFrameSetText(GUI_BuyButton, "Buy (" + I2S(goldCost) + " Gold)")
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

    public function Init takes nothing returns nothing
        if GUI_Initialized then
            return
        endif
        set GUI_Initialized = true

        set GUI_BuyTrigger = CreateTrigger()
        call TriggerAddAction(GUI_BuyTrigger, function GUI_BuyAction)
        set GUI_ReturnButtonTrigger = CreateTrigger()
        call TriggerAddAction(GUI_ReturnButtonTrigger, function GUI_ReturnAction)
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
