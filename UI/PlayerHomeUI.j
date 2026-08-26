/**
    PlayerHomeUI

    Author: Valdemar
    Version: 1.0.0

    Description:
    Displays the Traveler's Journal dashboard and routes Return Home actions
    through the real Journal item so UI and inventory use share one spell path.

    Credits:
    - Tasyen for frame UI examples used throughout PotS

    How to install:
    Import after PlayerHome, MasterUI, Interface, and FallenHeroState.

    API:
    - PlayerHomeUI_Show()
    - PlayerHomeUI_Hide()
    - PlayerHomeUI_ForceUpdate()

**/
library PlayerHomeUI initializer AutoInit requires PlayerHome, MasterUI, Interface, FallenHeroState
    globals
        private constant string PHUI_JOURNAL_ICON = "ReplaceableTextures\\CommandButtons\\BTNBook_07.blp"
        private constant real PHUI_REFRESH_PERIOD = 0.25

        private boolean PHUI_Initialized = false
        private framehandle PHUI_Parent = null
        private framehandle PHUI_Title = null
        private framehandle PHUI_Icon = null
        private framehandle PHUI_HomeText = null
        private framehandle PHUI_OwnershipText = null
        private framehandle PHUI_RulesText = null
        private framehandle PHUI_CloseButton = null
        private framehandle PHUI_ReturnToMenuButton = null
        private framehandle PHUI_PingButton = null
        private framehandle array PHUI_HeroStatus
        private framehandle array PHUI_ReturnButton

        private trigger PHUI_CloseTrigger = null
        private trigger PHUI_ReturnToMenuTrigger = null
        private trigger PHUI_PingTrigger = null
        private trigger PHUI_ReturnTrigger = null
        private trigger PHUI_ClearFocusTrigger = null
        private trigger PHUI_InitTrigger = null
        private timer PHUI_RefreshTimer = null
    endglobals

    private function PHUI_GetHero takes integer heroIndex returns unit
        if heroIndex == 1 then
            return udg_Nazgrek
        elseif heroIndex == 2 then
            return udg_Zulkis
        endif
        return null
    endfunction

    private function PHUI_GetHeroName takes integer heroIndex returns string
        if heroIndex == 1 then
            return "Nazgrek"
        endif
        return "Zul'kis"
    endfunction

    private function PHUI_FormatTime takes real remaining returns string
        local integer totalSeconds = R2I(remaining + 0.99)
        local integer minutes = totalSeconds / 60
        local integer seconds = totalSeconds - minutes * 60

        if seconds < 10 then
            return I2S(minutes) + ":0" + I2S(seconds)
        endif
        return I2S(minutes) + ":" + I2S(seconds)
    endfunction

    private function PHUI_GetOwnershipText takes unit hero returns string
        if hero == null or not PlayerHome_HeroHasJournal(hero) then
            return "|cffff8080Missing|r"
        endif
        return "|cff80ff80Owned|r"
    endfunction

    private function PHUI_GetStatusText takes unit hero returns string
        local real remaining

        if hero == null then
            return "|cffaaaaaaNot available|r"
        elseif not FallenHeroState_IsAlive(hero) then
            return "|cffff8080Dead|r"
        elseif not PlayerHome_HeroHasJournal(hero) then
            return "|cffff8080Missing Journal|r"
        elseif PlayerHome_IsChanneling(hero) then
            return "|cffffcc00Channeling|r"
        endif

        set remaining = PlayerHome_GetCooldownRemaining(hero)
        if remaining > 0.00 then
            return "|cffffcc00Cooldown " + PHUI_FormatTime(remaining) + "|r"
        endif
        return "|cff80ff80Ready|r"
    endfunction

    private function PHUI_CanUse takes unit hero returns boolean
        return hero != null and GetOwningPlayer(hero) == Player(0) and PlayerHome_HasHome() and FallenHeroState_IsAlive(hero) and PlayerHome_HeroHasJournal(hero) and PlayerHome_GetCooldownRemaining(hero) <= 0.00 and not PlayerHome_IsChanneling(udg_Nazgrek) and not PlayerHome_IsChanneling(udg_Zulkis)
    endfunction

    private function PHUI_Update takes nothing returns nothing
        local unit nazgrek = null
        local unit zulkis = null

        if PHUI_Parent == null or not BlzFrameIsVisible(PHUI_Parent) then
            set nazgrek = null
            set zulkis = null
            return
        endif
        set nazgrek = udg_Nazgrek
        set zulkis = udg_Zulkis

        if PlayerHome_HasHome() then
            call BlzFrameSetText(PHUI_HomeText, "|cffffcc00Current home|r|n" + PlayerHome_GetHomeName() + "|n|cffaaaaaa" + PlayerHome_GetHomeZoneName() + "|r")
        else
            call BlzFrameSetText(PHUI_HomeText, "|cffffcc00Current home|r|n|cffff8080Not bound|r")
        endif
        call BlzFrameSetText(PHUI_OwnershipText, "|cffffcc00Journal ownership|r|nNazgrek: " + PHUI_GetOwnershipText(nazgrek) + "|nZul'kis: " + PHUI_GetOwnershipText(zulkis))
        call BlzFrameSetText(PHUI_HeroStatus[1], PHUI_GetStatusText(nazgrek))
        call BlzFrameSetText(PHUI_HeroStatus[2], PHUI_GetStatusText(zulkis))
        call BlzFrameSetEnable(PHUI_ReturnButton[1], PHUI_CanUse(nazgrek))
        call BlzFrameSetEnable(PHUI_ReturnButton[2], PHUI_CanUse(zulkis))
        call BlzFrameSetEnable(PHUI_PingButton, PlayerHome_HasHome())

        set nazgrek = null
        set zulkis = null
    endfunction

    public function ForceUpdate takes nothing returns nothing
        call PHUI_Update()
    endfunction

    public function Hide takes nothing returns nothing
        if PHUI_Parent != null then
            if BlzFrameIsVisible(PHUI_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
            endif
            call BlzFrameSetVisible(PHUI_Parent, false)
        endif
    endfunction

    public function Show takes nothing returns nothing
        if PHUI_Parent != null then
            if not BlzFrameIsVisible(PHUI_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
            endif
            call BlzFrameSetVisible(PHUI_Parent, true)
            call PHUI_Update()
        endif
    endfunction

    private function PHUI_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function PHUI_CloseAction takes nothing returns nothing
        call Hide()
    endfunction

    private function PHUI_ReturnToMenuAction takes nothing returns nothing
        call Hide()
        call MasterUI_Show()
    endfunction

    private function PHUI_PingAction takes nothing returns nothing
        call PlayerHome_PingHome()
    endfunction

    private function PHUI_ReturnAction takes nothing returns nothing
        local framehandle clickedFrame = BlzGetTriggerFrame()
        local unit hero = null

        if clickedFrame == PHUI_ReturnButton[1] then
            set hero = PHUI_GetHero(1)
        elseif clickedFrame == PHUI_ReturnButton[2] then
            set hero = PHUI_GetHero(2)
        endif
        if hero != null and PHUI_CanUse(hero) then
            call Hide()
            call PlayerHome_UseJournal(hero)
        endif

        set clickedFrame = null
        set hero = null
    endfunction

    private function PHUI_CreateText takes string frameName, real x, real y, real width, real height returns framehandle
        local framehandle textFrame = BlzCreateFrameByType("TEXT", frameName, PHUI_Parent, "", 0)

        call BlzFrameSetPoint(textFrame, FRAMEPOINT_TOPLEFT, PHUI_Parent, FRAMEPOINT_TOPLEFT, x, y)
        call BlzFrameSetSize(textFrame, width, height)
        call BlzFrameSetTextAlignment(textFrame, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(textFrame, false)
        return textFrame
    endfunction

    private function PHUI_CreateReturnButton takes integer heroIndex, real y returns nothing
        set PHUI_ReturnButton[heroIndex] = BlzCreateFrameByType("GLUETEXTBUTTON", "PlayerHomeUIReturnButton" + I2S(heroIndex), PHUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(PHUI_ReturnButton[heroIndex], FRAMEPOINT_TOPLEFT, PHUI_Parent, FRAMEPOINT_TOPLEFT, 0.045, y)
        call BlzFrameSetSize(PHUI_ReturnButton[heroIndex], 0.205, 0.036)
        call BlzFrameSetText(PHUI_ReturnButton[heroIndex], "Return Home (" + PHUI_GetHeroName(heroIndex) + ")")
        call BlzTriggerRegisterFrameEvent(PHUI_ReturnTrigger, PHUI_ReturnButton[heroIndex], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PHUI_ClearFocusTrigger, PHUI_ReturnButton[heroIndex], FRAMEEVENT_CONTROL_CLICK)

        set PHUI_HeroStatus[heroIndex] = PHUI_CreateText("PlayerHomeUIHeroStatus" + I2S(heroIndex), 0.265, y - 0.006, 0.135, 0.028)
        call BlzFrameSetTextAlignment(PHUI_HeroStatus[heroIndex], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
    endfunction

    private function PHUI_CreateFrames takes nothing returns nothing
        set PHUI_Parent = BlzCreateFrameByType("BACKDROP", "PlayerHomeUIPanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(PHUI_Parent, FRAMEPOINT_TOPLEFT, 0.110, 0.560)
        call BlzFrameSetAbsPoint(PHUI_Parent, FRAMEPOINT_BOTTOMRIGHT, 0.560, 0.175)

        set PHUI_Title = PHUI_CreateText("PlayerHomeUITitle", 0.080, -0.018, 0.290, 0.028)
        call BlzFrameSetTextAlignment(PHUI_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetScale(PHUI_Title, 1.20)
        call BlzFrameSetText(PHUI_Title, "|cffffffffTraveler's |r|cffffcc00Journal|r")

        set PHUI_Icon = BlzCreateFrameByType("BACKDROP", "PlayerHomeUIIcon", PHUI_Parent, "IconButtonTemplate", 0)
        call BlzFrameSetPoint(PHUI_Icon, FRAMEPOINT_TOPLEFT, PHUI_Parent, FRAMEPOINT_TOPLEFT, 0.025, -0.058)
        call BlzFrameSetSize(PHUI_Icon, 0.060, 0.060)
        call BlzFrameSetTexture(PHUI_Icon, PHUI_JOURNAL_ICON, 0, true)

        set PHUI_HomeText = PHUI_CreateText("PlayerHomeUIHomeText", 0.105, -0.055, 0.175, 0.070)
        set PHUI_OwnershipText = PHUI_CreateText("PlayerHomeUIOwnershipText", 0.290, -0.055, 0.135, 0.070)

        call PHUI_CreateReturnButton(1, -0.145)
        call PHUI_CreateReturnButton(2, -0.190)

        set PHUI_RulesText = PHUI_CreateText("PlayerHomeUIRulesText", 0.045, -0.240, 0.355, 0.070)
        call BlzFrameSetText(PHUI_RulesText, "|cffffcc00How it works|r|nChannel for 10 seconds; moving, issuing any order, taking or dealing damage, or dying interrupts the return. Cooldown is 30 minutes per hero. Nearby heroes, active companions, and the active pet within 900 range travel with the caster. Select a different world Journal nearby to bind a new home.")

        set PHUI_PingButton = BlzCreateFrameByType("GLUETEXTBUTTON", "PlayerHomeUIPingButton", PHUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(PHUI_PingButton, FRAMEPOINT_BOTTOMLEFT, PHUI_Parent, FRAMEPOINT_BOTTOMLEFT, 0.045, 0.025)
        call BlzFrameSetSize(PHUI_PingButton, 0.105, 0.032)
        call BlzFrameSetText(PHUI_PingButton, "Ping Home")
        call BlzTriggerRegisterFrameEvent(PHUI_PingTrigger, PHUI_PingButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PHUI_ClearFocusTrigger, PHUI_PingButton, FRAMEEVENT_CONTROL_CLICK)

        set PHUI_ReturnToMenuButton = BlzCreateFrameByType("GLUETEXTBUTTON", "PlayerHomeUIReturnToMenuButton", PHUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(PHUI_ReturnToMenuButton, FRAMEPOINT_BOTTOM, PHUI_Parent, FRAMEPOINT_BOTTOM, 0.000, 0.025)
        call BlzFrameSetSize(PHUI_ReturnToMenuButton, 0.105, 0.032)
        call BlzFrameSetText(PHUI_ReturnToMenuButton, "Return")
        call BlzTriggerRegisterFrameEvent(PHUI_ReturnToMenuTrigger, PHUI_ReturnToMenuButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PHUI_ClearFocusTrigger, PHUI_ReturnToMenuButton, FRAMEEVENT_CONTROL_CLICK)

        set PHUI_CloseButton = BlzCreateFrameByType("GLUETEXTBUTTON", "PlayerHomeUICloseButton", PHUI_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetPoint(PHUI_CloseButton, FRAMEPOINT_TOPRIGHT, PHUI_Parent, FRAMEPOINT_TOPRIGHT, -0.010, -0.010)
        call BlzFrameSetSize(PHUI_CloseButton, 0.030, 0.030)
        call BlzFrameSetText(PHUI_CloseButton, "X")
        call BlzTriggerRegisterFrameEvent(PHUI_CloseTrigger, PHUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(PHUI_ClearFocusTrigger, PHUI_CloseButton, FRAMEEVENT_CONTROL_CLICK)

        call BlzFrameSetVisible(PHUI_Parent, false)
    endfunction

    private function PHUI_RefreshAction takes nothing returns nothing
        call PHUI_Update()
    endfunction

    private function PHUI_DelayedInit takes nothing returns nothing
        call PHUI_CreateFrames()
        call TimerStart(PHUI_RefreshTimer, PHUI_REFRESH_PERIOD, true, function PHUI_RefreshAction)
    endfunction

    public function Init takes nothing returns nothing
        if PHUI_Initialized then
            return
        endif
        set PHUI_Initialized = true
        set PHUI_RefreshTimer = CreateTimer()

        set PHUI_CloseTrigger = CreateTrigger()
        call TriggerAddAction(PHUI_CloseTrigger, function PHUI_CloseAction)
        set PHUI_ReturnToMenuTrigger = CreateTrigger()
        call TriggerAddAction(PHUI_ReturnToMenuTrigger, function PHUI_ReturnToMenuAction)
        set PHUI_PingTrigger = CreateTrigger()
        call TriggerAddAction(PHUI_PingTrigger, function PHUI_PingAction)
        set PHUI_ReturnTrigger = CreateTrigger()
        call TriggerAddAction(PHUI_ReturnTrigger, function PHUI_ReturnAction)
        set PHUI_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(PHUI_ClearFocusTrigger, function PHUI_ClearFocusAction)

        set PHUI_InitTrigger = CreateTrigger()
        call TriggerRegisterTimerEvent(PHUI_InitTrigger, 0.20, false)
        call TriggerAddAction(PHUI_InitTrigger, function PHUI_DelayedInit)
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
