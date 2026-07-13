/**
    Interface

    Author: Valdemar
    Version:

    Description:
    Central gateway for interface-related game feedback. UI libraries call the
    public notify functions when panels, map views, buttons, or similar
    interface actions happen. At this stage the library only plays configured
    sounds.

    Credits:

    How to install:
    Import this library before any UI library that calls it. Replace the null
    placeholders in IUI_InitDefaultSounds with the final gg_snd_* globals, or
    configure them during map init with Interface_SetEventSound.

    API:
    call Interface_SetEventSound(Interface_EVENT_UI_OPEN, gg_snd_Interface_UIOpen)
    call Interface_SetEventSound(Interface_EVENT_UI_CLOSE, gg_snd_Interface_UIClose)
    call Interface_ClearEventSound(Interface_EVENT_UI_OPEN)
    call Interface_PlayEventSound(Interface_EVENT_BUTTON_CLICK)
    call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, GetTriggerPlayer())
    call Interface_NotifyUnitSelected()
    call Interface_NotifyTargetSelected()
    call Interface_NotifyUIOpened()
    call Interface_NotifyUIClosed()
    call Interface_NotifyMapOpened()
    call Interface_NotifyMapClosed()
    call Interface_NotifyDialogButtonClicked()
    call Interface_NotifyDialogTradeButtonClicked()
    call Interface_NotifyDialogCloseButtonClicked()

**/
library Interface initializer AutoInit
    globals
        public constant integer EVENT_UNIT_SELECT = 1
        public constant integer EVENT_UI_OPEN = 2
        public constant integer EVENT_UI_CLOSE = 3
        public constant integer EVENT_MAP_OPEN = 4
        public constant integer EVENT_MAP_CLOSE = 5
        public constant integer EVENT_MENU_CLICK = 6
        public constant integer EVENT_BUTTON_CLICK = 7
        public constant integer EVENT_TAB_CHANGE = 8
        public constant integer EVENT_CONFIRM = 9
        public constant integer EVENT_CANCEL = 10
        public constant integer EVENT_ERROR = 11
        public constant integer EVENT_DIALOG_BUTTON_NORMAL = 12
        public constant integer EVENT_DIALOG_BUTTON_TRADE = 13
        public constant integer EVENT_DIALOG_BUTTON_CLOSE = 14
        public constant integer EVENT_SELECT_TARGET = 15

        private constant integer IUI_EVENT_MAX = 15

        private boolean IUI_Initialized = false
        private boolean IUI_SoundsEnabled = true
        private boolean IUI_UnitSelectSoundEnabled = true

        // Event sounds are intentionally null until the final gg_snd_* globals are assigned.
        private sound array IUI_EventSound
        private trigger IUI_UnitSelectTrigger = null
    endglobals

    private function IUI_IsValidEvent takes integer eventId returns boolean
        return eventId >= EVENT_UNIT_SELECT and eventId <= IUI_EVENT_MAX
    endfunction

    private function IUI_PlaySound takes sound whichSound returns nothing
        if IUI_SoundsEnabled and whichSound != null then
            call StopSound(whichSound, false, false)
            call StartSound(whichSound)
        endif
    endfunction

    private function IUI_PlayEvent takes integer eventId returns nothing
        if IUI_IsValidEvent(eventId) then
            call IUI_PlaySound(IUI_EventSound[eventId])
        endif
    endfunction

    private function IUI_UnitSelectAction takes nothing returns nothing
        local player triggerPlayer = GetTriggerPlayer()
        local unit selectedUnit = GetTriggerUnit()

        if IUI_UnitSelectSoundEnabled and triggerPlayer == GetLocalPlayer() then
            if selectedUnit != null and GetOwningPlayer(selectedUnit) != triggerPlayer then
                call IUI_PlayEvent(EVENT_SELECT_TARGET)
            else
                call IUI_PlayEvent(EVENT_UNIT_SELECT)
            endif
        endif

        set selectedUnit = null
        set triggerPlayer = null
    endfunction

    private function IUI_RegisterUnitSelectEvents takes nothing returns nothing
        local integer playerIndex = 0

        set IUI_UnitSelectTrigger = CreateTrigger()
        loop
            exitwhen playerIndex >= bj_MAX_PLAYERS
            call TriggerRegisterPlayerUnitEvent(IUI_UnitSelectTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_SELECTED, null)
            set playerIndex = playerIndex + 1
        endloop
        call TriggerAddAction(IUI_UnitSelectTrigger, function IUI_UnitSelectAction)
    endfunction

    private function IUI_InitDefaultSounds takes nothing returns nothing
        // Replace null with the final World Editor sound globals when they exist.
        set IUI_EventSound[EVENT_UNIT_SELECT] = null // gg_snd_Interface_UnitSelect
        set IUI_EventSound[EVENT_UI_OPEN] = null     // gg_snd_Interface_UIOpen
        set IUI_EventSound[EVENT_UI_CLOSE] = null    // gg_snd_Interface_UIClose
        set IUI_EventSound[EVENT_MAP_OPEN] = null    // gg_snd_Interface_MapOpen
        set IUI_EventSound[EVENT_MAP_CLOSE] = null   // gg_snd_Interface_MapClose
        set IUI_EventSound[EVENT_MENU_CLICK] = null  // gg_snd_Interface_MenuClick
        set IUI_EventSound[EVENT_BUTTON_CLICK] = null // gg_snd_Interface_ButtonClick
        set IUI_EventSound[EVENT_TAB_CHANGE] = null  // gg_snd_Interface_TabChange
        set IUI_EventSound[EVENT_CONFIRM] = null     // gg_snd_Interface_Confirm
        set IUI_EventSound[EVENT_CANCEL] = null      // gg_snd_Interface_Cancel
        set IUI_EventSound[EVENT_ERROR] = null       // gg_snd_Interface_Error
        set IUI_EventSound[EVENT_DIALOG_BUTTON_NORMAL] = gg_snd_Interface_MenuClick2            // gg_snd_Interface_MenuClick2
        set IUI_EventSound[EVENT_DIALOG_BUTTON_TRADE] = gg_snd_Interface_CharacterSheetOpen     // gg_snd_Interface_CharacterSheetOpen
        set IUI_EventSound[EVENT_DIALOG_BUTTON_CLOSE] = gg_snd_Interface_MenuClose              // gg_snd_Interface_MenuClose
        set IUI_EventSound[EVENT_SELECT_TARGET] = gg_snd_Interface_SelectTarget                 // gg_snd_Interface_SelectTarget
    endfunction

    public function SetSoundsEnabled takes boolean enabled returns nothing
        set IUI_SoundsEnabled = enabled
    endfunction

    public function AreSoundsEnabled takes nothing returns boolean
        return IUI_SoundsEnabled
    endfunction

    public function SetUnitSelectSoundEnabled takes boolean enabled returns nothing
        set IUI_UnitSelectSoundEnabled = enabled
    endfunction

    public function IsUnitSelectSoundEnabled takes nothing returns boolean
        return IUI_UnitSelectSoundEnabled
    endfunction

    public function SetEventSound takes integer eventId, sound whichSound returns nothing
        if IUI_IsValidEvent(eventId) then
            set IUI_EventSound[eventId] = whichSound
        endif
    endfunction

    public function ClearEventSound takes integer eventId returns nothing
        if IUI_IsValidEvent(eventId) then
            set IUI_EventSound[eventId] = null
        endif
    endfunction

    public function PlayEventSound takes integer eventId returns nothing
        call IUI_PlayEvent(eventId)
    endfunction

    public function PlayEventSoundForPlayer takes integer eventId, player whichPlayer returns nothing
        if whichPlayer != null and GetLocalPlayer() == whichPlayer then
            call IUI_PlayEvent(eventId)
        endif
    endfunction

    public function NotifyUnitSelected takes nothing returns nothing
        call IUI_PlayEvent(EVENT_UNIT_SELECT)
    endfunction

    public function NotifyTargetSelected takes nothing returns nothing
        call IUI_PlayEvent(EVENT_SELECT_TARGET)
    endfunction

    public function NotifyUIOpened takes nothing returns nothing
        call IUI_PlayEvent(EVENT_UI_OPEN)
    endfunction

    public function NotifyUIClosed takes nothing returns nothing
        call IUI_PlayEvent(EVENT_UI_CLOSE)
    endfunction

    public function NotifyMapOpened takes nothing returns nothing
        call IUI_PlayEvent(EVENT_MAP_OPEN)
    endfunction

    public function NotifyMapClosed takes nothing returns nothing
        call IUI_PlayEvent(EVENT_MAP_CLOSE)
    endfunction

    public function NotifyMenuClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_MENU_CLICK)
    endfunction

    public function NotifyButtonClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_BUTTON_CLICK)
    endfunction

    public function NotifyTabChanged takes nothing returns nothing
        call IUI_PlayEvent(EVENT_TAB_CHANGE)
    endfunction

    public function NotifyConfirmed takes nothing returns nothing
        call IUI_PlayEvent(EVENT_CONFIRM)
    endfunction

    public function NotifyCancelled takes nothing returns nothing
        call IUI_PlayEvent(EVENT_CANCEL)
    endfunction

    public function NotifyError takes nothing returns nothing
        call IUI_PlayEvent(EVENT_ERROR)
    endfunction

    public function NotifyDialogButtonClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_DIALOG_BUTTON_NORMAL)
    endfunction

    public function NotifyDialogTradeButtonClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_DIALOG_BUTTON_TRADE)
    endfunction

    public function NotifyDialogCloseButtonClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_DIALOG_BUTTON_CLOSE)
    endfunction

    public function Init takes nothing returns nothing
        if IUI_Initialized then
            return
        endif
        set IUI_Initialized = true

        call IUI_InitDefaultSounds()
        call IUI_RegisterUnitSelectEvents()
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
